# Neuronix Plan: Hyprland Critical Backend Switching (Quickshell + Hypridle)

## Goal

Switch the target host to Quickshell and Hypridle with minimal-risk, critical backend toggles only.

This revision intentionally avoids adding broad per-app feature flags. Optional apps are host-level package choices.

## Locked Decisions

- Notifications remain `mako`
- Screen lock remains `swaylock`
- Idle backend can switch between `swayidle` and `hypridle`
- Screenshot backend remains `hyprshot`
- Annotation uses separate `satty` bind
- Waybar/classic assets stay in repo, but classic shell is disabled on target host
- Stylix remains the primary theming path

## Critical Option Surface

Under `modules.desktop.hyprland`:

- `shell.backend = "classic" | "quickshell"` (default: `classic`)
- `idle.backend = "swayidle" | "hypridle"` (default: `swayidle`)
- `screenshot.backend = "hyprshot"` (default: `hyprshot`)
- `screenshot.annotator = "none" | "satty"` (default: `none`)
- `wallpaper.backend = "swaybg" | "swww"` (default: `swaybg`)
- `wallpaper.video.enable = bool` (default: `false`, for `mpvpaper`)

No new global `modules.desktop.apps.*` option tree is introduced.

## Implementation Status

### Phase A: Runtime Wiring

Implemented:

- Added critical backend options in Hyprland HM module
- Added conditional package wiring for:
  - shell backend (`waybar` vs `quickshell`)
  - idle backend (`swayidle` vs `hypridle`)
  - wallpaper backend (`swaybg` vs `swww`)
  - optional video wallpaper (`mpvpaper`)
  - screenshot annotator (`satty`)
- Added `quickshell` config deployment at `~/.config/quickshell/shell.qml`
- Added startup script backend switch:
  - `classic` -> launch waybar
  - `quickshell` -> launch Quickshell
- Kept `mako` startup path intact

### Phase B: Idle + Lock Path

Implemented:

- Added `services.hypridle` config when `idle.backend = "hypridle"`
- Lock command remains `swaylock`
- Updated lock script to stay compatible with both idle backends

### Phase C: Screenshot Mode 3

Implemented:

- Updated keybind model in `hyprland.conf`:
  - `Print`: output capture
  - `SUPER+Print`: window capture
  - `CTRL+Print`: region capture
  - `SUPER+SHIFT+Print`: annotate flow
- Added `~/.config/hypr/scripts/screenshot-annotate` wrapper using `hyprshot` + `satty`

### Phase D: Target Host Switch

Implemented for `hosts/books/hp_450/home.nix`:

- `shell.backend = "quickshell"`
- `idle.backend = "hypridle"`
- `screenshot.annotator = "satty"`
- `wallpaper.backend = "swww"`
- Host-level package enablement for optional apps:
  - `papers`
  - `easyeffects`
  - `cava`

## Files Changed

- `home/linux/desktop/hyprland/default.nix`
- `home/linux/desktop/hyprland/values/packages.nix`
- `home/linux/desktop/hyprland/values/hyprland.nix`
- `home/linux/desktop/hyprland/conf/hyprland.conf`
- `home/linux/desktop/hyprland/conf/scripts/startup`
- `home/linux/desktop/hyprland/conf/scripts/statusbar`
- `home/linux/desktop/hyprland/conf/scripts/lockscreen`
- `home/linux/desktop/hyprland/conf/scripts/screenshot-annotate`
- `home/linux/desktop/hyprland/conf/quickshell/shell.qml`
- `hosts/books/hp_450/home.nix`

## Verification Checklist

- [ ] `nix flake check`
- [ ] Evaluate/build target host (`tk-elitebook-hyprland`)
- [ ] Relogin and confirm Quickshell launches
- [ ] Confirm no Waybar process on target host
- [ ] Validate lock flow (`CTRL+ALT+L` -> `swaylock`)
- [ ] Validate idle flow (`hypridle` lock + suspend listeners)
- [ ] Validate screenshot binds (normal + annotate)
- [ ] Validate `notify-send` and volume/brightness OSD scripts under `mako`

## Rollback

If Quickshell path fails:

1. Set `modules.desktop.hyprland.shell.backend = "classic"`
2. Set `modules.desktop.hyprland.idle.backend = "swayidle"`
3. Rebuild and relogin

Classic configuration files and scripts remain in-repo, so rollback is immediate.
