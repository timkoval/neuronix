#!/usr/bin/env python3
"""
Outlook Calendar integration for QuickShell via ICS feed.

Setup:
    1. Open Outlook Web → Settings → Calendar → Shared calendars → Publish a calendar
    2. Copy the ICS link
    3. Add to ~/.config/niri/scripts/quickshell/calendar/.env:
       OUTLOOK_ICS_URL=https://outlook.office365.com/owa/calendar/...

Normal usage (called by schedule_manager.sh):
    python3 outlook_calendar.py
"""

import json
import os
import sys
import re
from datetime import datetime, timedelta, timezone

try:
    import requests
except ImportError:
    print(json.dumps({"header": "Missing dep (requests)", "lessons": [], "link": ""}))
    sys.exit(0)

# --- CONFIGURATION ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_FILE = os.path.join(SCRIPT_DIR, ".env")
CACHE_DIR = os.path.expanduser("~/.cache/quickshell/calendar")
SCHEDULE_CACHE_FILE = os.path.join(CACHE_DIR, "schedule.json")

# Workday range for timeline layout
WORKDAY_START_HOUR = 8
WORKDAY_START_MIN = 0
WORKDAY_END_HOUR = 18
WORKDAY_END_MIN = 0
TOTAL_MINUTES = (WORKDAY_END_HOUR * 60 + WORKDAY_END_MIN) - (WORKDAY_START_HOUR * 60 + WORKDAY_START_MIN)

TOTAL_AVAILABLE_WIDTH_PX = 750
PIXELS_PER_MINUTE = TOTAL_AVAILABLE_WIDTH_PX / TOTAL_MINUTES


def load_env():
    env = {}
    if os.path.exists(ENV_FILE):
        with open(ENV_FILE) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, val = line.split('=', 1)
                    env[key.strip()] = val.strip()
    return env


def parse_ics_datetime(dtstr):
    """Parse ICS datetime string to a datetime object."""
    dtstr = dtstr.strip()

    # Handle TZID format: DTSTART;TZID=Asia/Dubai:20260414T090000
    if ';' in dtstr:
        parts = dtstr.split(':')
        if len(parts) >= 2:
            dtstr = parts[-1]

    # Remove VALUE=DATE: prefix
    dtstr = dtstr.replace("VALUE=DATE:", "").replace("VALUE=DATE-TIME:", "")

    if dtstr.endswith('Z'):
        # UTC time
        dt = datetime.strptime(dtstr, "%Y%m%dT%H%M%SZ")
        return dt.replace(tzinfo=timezone.utc).astimezone().replace(tzinfo=None)
    elif 'T' in dtstr:
        # Local time (no timezone)
        return datetime.strptime(dtstr, "%Y%m%dT%H%M%S")
    else:
        # All-day event (date only)
        return datetime.strptime(dtstr, "%Y%m%d")


def parse_ics(ics_text):
    """Parse ICS text into a list of events for today."""
    today = datetime.now().date()
    events = []

    in_event = False
    event = {}

    # Unfold long lines (ICS continuation lines start with space/tab)
    unfolded = []
    for line in ics_text.splitlines():
        if line.startswith((' ', '\t')) and unfolded:
            unfolded[-1] += line[1:]
        else:
            unfolded.append(line)

    for line in unfolded:
        if line.strip() == "BEGIN:VEVENT":
            in_event = True
            event = {}
        elif line.strip() == "END:VEVENT":
            in_event = False
            if event.get("start") and event.get("end"):
                start_date = event["start"].date()
                end_date = event["end"].date()
                # Include events that overlap with today
                if start_date <= today <= end_date:
                    events.append(event)
        elif in_event:
            if line.startswith("SUMMARY"):
                event["subject"] = line.split(":", 1)[-1].strip()
            elif line.startswith("LOCATION"):
                event["room"] = line.split(":", 1)[-1].strip()
            elif line.startswith("DTSTART"):
                try:
                    val = line.split(":", 1)[-1] if ":" in line else line
                    # Check for all-day
                    if "VALUE=DATE" in line and "DATE-TIME" not in line:
                        event["all_day"] = True
                        event["start"] = parse_ics_datetime(val)
                    else:
                        event["start"] = parse_ics_datetime(line.split(":", 1)[-1] if "TZID" not in line else line[line.index(":") + 1:] if ":" in line else val)
                        # Re-parse with full line for TZID handling
                        if "TZID" in line:
                            event["start"] = parse_ics_datetime(line[len("DTSTART"):])
                        event["all_day"] = False
                except Exception:
                    pass
            elif line.startswith("DTEND"):
                try:
                    val = line.split(":", 1)[-1] if ":" in line else line
                    if "TZID" in line:
                        event["end"] = parse_ics_datetime(line[len("DTEND"):])
                    else:
                        event["end"] = parse_ics_datetime(val)
                except Exception:
                    pass

    return events


def format_header(now):
    day_name = now.strftime("%A, %d %b")
    return f"{day_name} (Today)"


def get_layout_props(duration_seconds):
    duration_seconds = max(0, duration_seconds)
    minutes = duration_seconds / 60
    width = minutes * PIXELS_PER_MINUTE
    char_limit = int(width / 5)
    return int(width), char_limit


def events_to_schedule(events):
    """Convert parsed ICS events to the QuickShell schedule format."""
    now = datetime.now()
    today = now.date()

    workday_start = datetime(today.year, today.month, today.day, WORKDAY_START_HOUR, WORKDAY_START_MIN)
    workday_end = datetime(today.year, today.month, today.day, WORKDAY_END_HOUR, WORKDAY_END_MIN)
    workday_start_epoch = int(workday_start.timestamp())
    workday_end_epoch = int(workday_end.timestamp())

    parsed = []
    for ev in events:
        if ev.get("all_day"):
            continue

        start_epoch = max(int(ev["start"].timestamp()), workday_start_epoch)
        end_epoch = min(int(ev["end"].timestamp()), workday_end_epoch)

        if end_epoch <= start_epoch:
            continue

        time_str = f"{ev['start'].strftime('%H:%M')} - {ev['end'].strftime('%H:%M')}"

        parsed.append({
            "type": "class",
            "subject": ev.get("subject", "No Title"),
            "time": time_str,
            "room": ev.get("room", ""),
            "start": start_epoch,
            "end": end_epoch,
        })

    parsed.sort(key=lambda x: x["start"])

    # Build timeline with gaps
    processed = []
    current_cursor = workday_start_epoch

    for lesson in parsed:
        if lesson["start"] > current_cursor:
            gap_duration = lesson["start"] - current_cursor
            if gap_duration > 60:
                width, _ = get_layout_props(gap_duration)
                gap_minutes = int(gap_duration / 60)
                processed.append({
                    "type": "gap",
                    "width": width,
                    "desc": f"{gap_minutes}m",
                    "start": current_cursor,
                    "end": lesson["start"],
                })
            current_cursor = lesson["start"]

        duration = lesson["end"] - current_cursor
        width, char_limit = get_layout_props(duration)
        lesson["width"] = width
        lesson["char_limit"] = char_limit
        lesson["is_compact"] = width < 70
        processed.append(lesson)
        current_cursor = lesson["end"]

    if current_cursor < workday_end_epoch:
        gap_duration = workday_end_epoch - current_cursor
        if gap_duration > 60:
            width, _ = get_layout_props(gap_duration)
            processed.append({
                "type": "gap",
                "width": width,
                "desc": "End of Day",
                "start": current_cursor,
                "end": workday_end_epoch,
            })

    return processed


def main():
    env = load_env()
    ics_url = env.get("OUTLOOK_ICS_URL", "")

    if not ics_url:
        print(json.dumps({
            "header": "No OUTLOOK_ICS_URL in .env",
            "lessons": [],
            "link": "",
        }))
        return

    try:
        resp = requests.get(ics_url, timeout=15)
        resp.raise_for_status()
        ics_text = resp.text
    except Exception as e:
        print(json.dumps({
            "header": f"Fetch error: {str(e)[:40]}",
            "lessons": [],
            "link": "https://outlook.office.com/calendar",
        }))
        return

    events = parse_ics(ics_text)
    now = datetime.now()
    schedule = events_to_schedule(events)

    output = {
        "header": format_header(now),
        "lessons": schedule,
        "link": "https://outlook.office.com/calendar",
    }

    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(SCHEDULE_CACHE_FILE, 'w') as f:
        json.dump(output, f)

    print(json.dumps(output))


if __name__ == "__main__":
    main()
