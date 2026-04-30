import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        // Uses the physical screen width so the popup scales synchronously with the TopBar
        currentWidth: Screen.width
    }
    
    // Helper function scoped to the root Item for easy access in deeply nested elements and Canvases
    function s(val) { 
        return scaler.s(val); 
    }

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay1: _theme.overlay1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color maroon: _theme.maroon
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color green: _theme.green
    readonly property color teal: _theme.teal
    readonly property color sapphire: _theme.sapphire
    readonly property color blue: _theme.blue

    // -------------------------------------------------------------------------
    // STATE & POLLING
    // -------------------------------------------------------------------------
    property int batCapacity: 0
    property string batStatus: "Unknown"
    property string powerProfile: "balanced"
    
    property int upHours: 0
    property int upMins: 0

    property real sysVolume: 0
    property bool sysMuted: false
    property real sysBrightness: 0
    
    property string currentUserName: ""

    // Anti-Jitter Sync States
    property bool isDraggingVol: false
    property bool isDraggingBri: false

    Timer { id: volSyncDelay; interval: 800; onTriggered: window.isDraggingVol = false; triggeredOnStart: true; }
    Timer { id: briSyncDelay; interval: 800; onTriggered: window.isDraggingBri = false; triggeredOnStart: true; }

    readonly property bool isCharging: batStatus === "Charging"

    // Unified hue for Battery
    readonly property color batColorStart: {
        if (isCharging) return window.green;
        if (batCapacity >= 70) return window.blue;
        if (batCapacity >= 30) return window.yellow;
        return window.red;
    }

    // Unified hue for Performance Profile
    readonly property color profileStart: {
        if (powerProfile === "performance") return window.red;
        if (powerProfile === "power-saver") return window.green;
        return window.blue;
    }

    property real animCapacity: 0
    Behavior on animCapacity { NumberAnimation { duration: 1200; easing.type: Easing.OutQuint } }
    
    onAnimCapacityChanged: batCanvas.requestPaint()
    onBatColorStartChanged: batCanvas.requestPaint()

    Process {
        id: userPoller
        command: ["bash", "-c", "echo $USER"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                window.currentUserName = this.text.trim();
            }
        }
    }

    Process {
        id: sysPoller
        command: ["bash", "-c", 
            "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '0'; " +
            "cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo 'Unknown'; " +
            "powerprofilesctl get 2>/dev/null || echo 'balanced'; " +
            "awk '{print int($1/3600)\"h \"int(($1%3600)/60)\"m\"}' /proc/uptime 2>/dev/null || echo '0h 0m'; " +
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100), ($3==\"[MUTED]\"?\"off\":\"on\")}' || echo '0 on'; " +
            "brightnessctl -m 2>/dev/null | awk -F, '{print substr($4, 1, length($4)-1)}' || echo '0'"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 6) {
                    if (window.batCapacity !== parseInt(lines[0])) {
                        window.batCapacity = parseInt(lines[0]);
                        window.animCapacity = window.batCapacity;
                    }
                    window.batStatus = lines[1];
                    window.powerProfile = lines[2];
                    
                    let upParts = lines[3].split("h ");
                    if (upParts.length === 2) {
                        window.upHours = parseInt(upParts[0]) || 0;
                        window.upMins = parseInt(upParts[1].replace("m", "")) || 0;
                    }

                    if (!window.isDraggingVol) {
                        let volParts = (lines[4] || "0 on").trim().split(" ");
                        window.sysVolume = parseInt(volParts[0]) || 0;
                        window.sysMuted = (volParts[1] === "off");
                    }
                    
                    if (!window.isDraggingBri) {
                        window.sysBrightness = parseInt(lines[5]) || 0;
                    }
                }
            }
        }
    }
    Timer {
        interval: 1500; running: true; repeat: true; triggeredOnStart: true;
        onTriggered: sysPoller.running = true
    }

    // --- STARTUP ANIMATION STATES ---
    property real introMain: 0
    property real introTop: 0
    property real introCore: 0
    property real introSliders: 0
    property real introActions: 0
    property real introProfiles: 0

    ParallelAnimation {
        running: true

        NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuart }

        SequentialAnimation {
            PauseAnimation { duration: 50 }
            NumberAnimation { target: window; property: "introTop"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuart }
        }

        SequentialAnimation {
            PauseAnimation { duration: 100 }
            NumberAnimation { target: window; property: "introCore"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuart }
        }

        SequentialAnimation {
            PauseAnimation { duration: 150 }
            NumberAnimation { target: window; property: "introSliders"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuart }
        }

        SequentialAnimation {
            PauseAnimation { duration: 200 }
            NumberAnimation { target: window; property: "introActions"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuart }
        }

        SequentialAnimation {
            PauseAnimation { duration: 250 }
            NumberAnimation { target: window; property: "introProfiles"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutQuart }
        }
    }

    // Clean, unified exit animation for when an action is clicked
    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: window; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introTop"; to: 0; duration: 300; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introCore"; to: 0; duration: 350; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introSliders"; to: 0; duration: 250; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introActions"; to: 0; duration: 200; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introProfiles"; to: 0; duration: 150; easing.type: Easing.InQuart }
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        opacity: introMain

        // Outer Border
        Rectangle {
            anchors.fill: parent
            radius: window.s(4)
            color: window.base
            border.color: window.surface1
            border.width: 2
            clip: true

            // ==========================================
            // TOP: UPTIME COMPONENT
            // ==========================================
            Row {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: window.s(25)
                spacing: window.s(6)
                
                transform: Translate { y: window.s(-20) * (1.0 - introTop) }
                opacity: introTop
                
                // Hours Box
                Rectangle {
                    width: window.s(44); height: window.s(48); radius: window.s(4)
                    color: window.mantle; border.color: window.surface1; border.width: 2
                    Column {
                        anchors.centerIn: parent
                        Text {
                            text: window.upHours.toString().padStart(2, '0')
                            font.pixelSize: window.s(18); font.family: "JetBrains Mono"; font.weight: Font.Bold
                            color: window.text
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text { 
                            text: "HR"; font.pixelSize: window.s(8); font.family: "JetBrains Mono"; font.weight: Font.Bold
                            color: window.subtext0; anchors.horizontalCenter: parent.horizontalCenter 
                        }
                    }
                }

                // Colon
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ":"
                    font.pixelSize: window.s(22); font.family: "JetBrains Mono"; font.weight: Font.Bold
                    color: window.text
                }

                // Mins Box
                Rectangle {
                    width: window.s(44); height: window.s(48); radius: window.s(4)
                    color: window.mantle; border.color: window.surface1; border.width: 2
                    Column {
                        anchors.centerIn: parent
                        Text {
                            text: window.upMins.toString().padStart(2, '0')
                            font.pixelSize: window.s(18); font.family: "JetBrains Mono"; font.weight: Font.Bold
                            color: window.text
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "MIN"; font.pixelSize: window.s(8); font.family: "JetBrains Mono"; font.weight: Font.Bold
                            color: window.subtext0; anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // Expanding top-right logout icon
            Rectangle {
                id: logoutBtn
                anchors.top: parent.top; anchors.right: parent.right
                anchors.margins: window.s(25)
                width: logoutMa.containsMouse ? window.s(44) + usernameText.implicitWidth + window.s(12) : window.s(44)
                height: window.s(44); radius: window.s(4)
                color: logoutMa.containsMouse ? window.surface1 : "transparent"
                border.color: logoutMa.containsMouse ? window.surface2 : "transparent"
                clip: true
                
                transform: Translate { y: window.s(-20) * (1.0 - introTop) }
                opacity: introTop

                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: window.s(13)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: window.s(12)

                    Text {
                        id: usernameText
                        text: window.currentUserName
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        font.pixelSize: window.s(14)
                        color: window.text
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: logoutMa.containsMouse ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    Text {
                        font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18)
                        color: logoutMa.containsMouse ? window.red : window.overlay0
                        text: "󰍃"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: logoutMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { 
                        exitAnim.start(); // Trigger graceful UI exit
                        Quickshell.execDetached(["niri", "msg", "action", "quit"]); 
                        Quickshell.execDetached(["sh", "-c", "echo 'close' > /tmp/qs_widget_state"]); 
                    }
                }
            }

            // ==========================================
            // CENTRAL CORE & BATTERY RING 
            // ==========================================
            Item {
                anchors.fill: parent
                z: 1
                
                opacity: introCore
                transform: Translate { y: window.s(25) * (1 - introCore) }

                Rectangle {
                    id: centralCore
                    width: window.s(260)
                    height: width
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: window.s(-70)
                    radius: width / 2
                    z: 1

                    property bool isDangerState: !window.isCharging && window.batCapacity < 15

                    color: window.mantle
                    border.color: centralCore.isDangerState ? window.red : window.surface1
                    border.width: 2

                    Item {
                        anchors.fill: parent

                        Canvas {
                            id: batCanvas
                            anchors.fill: parent
                            rotation: 180

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);

                                var centerX = width / 2;
                                var centerY = height / 2;
                                var radius = (width / 2) - window.s(18);
                                var endAngle = (window.animCapacity / 100) * 2 * Math.PI;

                                ctx.lineCap = "butt";

                                // Background track
                                ctx.lineWidth = window.s(8);
                                ctx.beginPath();
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                ctx.strokeStyle = window.surface1.toString();
                                ctx.stroke();

                                // Battery fill arc — flat color
                                ctx.globalAlpha = 1.0;
                                ctx.lineWidth = window.s(12);
                                ctx.beginPath();
                                ctx.arc(centerX, centerY, radius, 0, endAngle);
                                ctx.strokeStyle = window.batColorStart.toString();
                                ctx.stroke();
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: window.s(-2)
                        
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: window.s(8)
                            
                            Text {
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: window.s(28)
                                color: window.batColorStart
                                text: window.isCharging ? "󰂄" : (window.batCapacity > 20 ? "󰁹" : "󰂃")
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }
                            
                            Text {
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(54)
                                color: window.text
                                text: Math.round(window.animCapacity) + "%"
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: window.s(13)
                            color: window.isCharging ? window.green
                                    : (centralCore.isDangerState ? window.red : window.subtext0)
                            text: window.batStatus.toUpperCase()
                        }
                    }
                }

                MouseArea {
                    id: heroMa
                    anchors.fill: centralCore 
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: batCanvas.requestPaint()
                    onExited: batCanvas.requestPaint()
                }
            }

            // ==========================================
            // BOTTOM DOCKS
            // ==========================================
            ColumnLayout {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: window.s(25)
                spacing: window.s(15)

                // 1. HARDWARE CONTROLS DOCK (Sliders)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(96)
                    radius: window.s(4)
                    color: window.mantle
                    border.color: window.surface1
                    border.width: 2

                    opacity: introSliders
                    transform: Translate { y: window.s(20) * (1.0 - introSliders) }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: window.s(14)
                        spacing: window.s(12)

                        // Brightness Slider
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: window.s(15)

                            Item {
                                Layout.preferredWidth: window.s(32)
                                Layout.preferredHeight: window.s(32)
                                Text {
                                    anchors.centerIn: parent
                                    text: window.sysBrightness > 66 ? "󰃠" : (window.sysBrightness > 33 ? "󰃟" : "󰃞")
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: window.s(22)
                                    color: window.blue
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                height: window.s(18)
                                
                                Timer {
                                    id: briCmdThrottle
                                    interval: 50
                                    property int targetPct: -1
                                    onTriggered: {
                                        if (targetPct >= 0) {
                                            Quickshell.execDetached(["brightnessctl", "set", targetPct + "%"]);
                                            targetPct = -1;
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: window.s(4)
                                    color: window.surface1
                                    border.color: window.surface2
                                    border.width: 1
                                    clip: true

                                    Rectangle {
                                        height: parent.height
                                        width: parent.width * (window.sysBrightness / 100)
                                        radius: window.s(4)
                                        color: window.batColorStart
                                        Behavior on width { enabled: !window.isDraggingBri; NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                                    }
                                }
                                MouseArea {
                                    id: briMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (mouse) => { briSyncDelay.stop(); window.isDraggingBri = true; updateBri(mouse.x); }
                                    onPositionChanged: (mouse) => { if (pressed) updateBri(mouse.x); }
                                    onReleased: { briSyncDelay.restart(); }
                                    
                                    function updateBri(mx) {
                                        let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                        window.sysBrightness = pct; 
                                        briCmdThrottle.targetPct = pct;
                                        if (!briCmdThrottle.running) briCmdThrottle.start();
                                    }
                                }
                            }
                        }

                        // Volume Slider
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: window.s(15)

                            Rectangle {
                                Layout.preferredWidth: window.s(32)
                                Layout.preferredHeight: window.s(32)
                                radius: window.s(4)
                                color: volIconMa.containsMouse ? window.surface1 : "transparent"
                                border.color: volIconMa.containsMouse ? window.surface2 : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: window.sysMuted || window.sysVolume === 0 ? "󰖁" : (window.sysVolume > 50 ? "󰕾" : "󰖀")
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: window.s(22)
                                    color: window.sysMuted ? window.overlay0 : window.profileStart
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                                MouseArea {
                                    id: volIconMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        volSyncDelay.stop();
                                        window.isDraggingVol = true; 
                                        window.sysMuted = !window.sysMuted;
                                        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                                        volSyncDelay.restart();
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                height: window.s(18)
                                
                                Timer {
                                    id: volCmdThrottle
                                    interval: 50
                                    property int targetPct: -1
                                    onTriggered: {
                                        if (targetPct >= 0) {
                                            if (targetPct > 0 && window.sysMuted) {
                                                window.sysMuted = false;
                                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]);
                                            }
                                            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", targetPct + "%"]);
                                            targetPct = -1;
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: window.s(4)
                                    color: window.surface1
                                    border.color: window.surface2
                                    border.width: 1
                                    clip: true

                                    Rectangle {
                                        height: parent.height
                                        width: parent.width * (window.sysVolume / 100)
                                        radius: window.s(4)
                                        color: window.sysMuted ? window.surface2 : window.profileStart
                                        opacity: window.sysMuted ? 0.5 : 1.0
                                        Behavior on width { enabled: !window.isDraggingVol; NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
                                    }
                                }
                                MouseArea {
                                    id: volMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (mouse) => { volSyncDelay.stop(); window.isDraggingVol = true; updateVol(mouse.x); }
                                    onPositionChanged: (mouse) => { if (pressed) updateVol(mouse.x); }
                                    onReleased: { volSyncDelay.restart(); }
                                    
                                    function updateVol(mx) {
                                        let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                        window.sysVolume = pct;
                                        volCmdThrottle.targetPct = pct;
                                        if (!volCmdThrottle.running) volCmdThrottle.start();
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. SYSTEM ACTIONS DOCK - No Text, Monochromatic Waves, Big Icons
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(75)
                    spacing: window.s(12)
                    
                    Repeater {
                        model: ListModel {
                            ListElement { cmd: "bash ~/.config/niri/scripts/lockscreen"; icon: ""; baseColor: "mauve"; weight: 1.0 }
                            ListElement { cmd: "bash ~/.config/niri/scripts/lockscreen & systemctl suspend"; icon: "ᶻ 𝗓 𐰁"; baseColor: "blue"; weight: 1.0 }
                            ListElement { cmd: "systemctl reboot"; icon: "󰑓"; baseColor: "yellow"; weight: 2.5 }
                            ListElement { cmd: "systemctl poweroff -i"; icon: ""; baseColor: "red"; weight: 3.5 }
                        }
                        
                        delegate: Rectangle {
                            id: actionCapsule
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: window.s(4)

                            opacity: introActions
                            transform: Translate { y: window.s(30) * (1.0 - introActions) }

                            property color c1: window[baseColor] || window.surface1

                            color: actionMa.containsMouse ? window.surface1 : window.mantle
                            border.color: actionMa.containsMouse ? c1 : window.surface1
                            border.width: 2
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            property real fillLevel: 0.0
                            property bool triggered: false

                            // Simple flat fill rectangle (replaces wave Canvas)
                            Rectangle {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                height: actionCapsule.height * actionCapsule.fillLevel
                                color: actionCapsule.c1
                            }

                            // Centered Big Icon (Idle State)
                            Text {
                                anchors.centerIn: parent
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: window.s(24)
                                color: actionMa.containsMouse ? window.text : window.subtext0
                                text: icon
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Item {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                height: actionCapsule.height * actionCapsule.fillLevel
                                clip: true

                                // Centered Big Icon (Filled State)
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: (actionCapsule.height / 2) - (height / 2) - (actionCapsule.height - parent.height)
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: window.s(24)
                                    color: window.base
                                    text: icon
                                }
                            }

                            MouseArea {
                                id: actionMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: actionCapsule.triggered ? Qt.ArrowCursor : Qt.PointingHandCursor

                                onPressed: {
                                    if (!actionCapsule.triggered) {
                                        drainAnim.stop();
                                        fillAnim.start();
                                    }
                                }
                                onReleased: {
                                    if (!actionCapsule.triggered && actionCapsule.fillLevel < 1.0) {
                                        fillAnim.stop();
                                        drainAnim.start();
                                    }
                                }
                            }

                            NumberAnimation {
                                id: fillAnim; target: actionCapsule; property: "fillLevel"; to: 1.0
                                duration: (550 * weight) * (1.0 - actionCapsule.fillLevel); easing.type: Easing.InSine
                                onFinished: {
                                    actionCapsule.triggered = true;
                                    exitAnim.start(); exitTimer.start();
                                }
                            }

                            NumberAnimation {
                                id: drainAnim; target: actionCapsule; property: "fillLevel"; to: 0.0
                                duration: 1500 * actionCapsule.fillLevel; easing.type: Easing.OutQuad
                            }

                            Timer {
                                id: exitTimer; interval: 500
                                onTriggered: { Quickshell.execDetached(["sh", "-c", cmd]); Quickshell.execDetached(["sh", "-c", "echo 'close' > /tmp/qs_widget_state"]); }
                            }
                        }
                    }
                }

                // 3. POWER PROFILES DOCK
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(54)
                    radius: window.s(4)
                    color: window.mantle
                    border.color: window.surface1
                    border.width: 2

                    opacity: introProfiles
                    transform: Translate { y: window.s(20) * (1.0 - introProfiles) }

                    Rectangle {
                        id: sliderPill
                        width: (parent.width - window.s(4)) / 3
                        height: parent.height - window.s(4)
                        y: window.s(2)
                        radius: window.s(4)
                        x: {
                            if (window.powerProfile === "performance") return window.s(2);
                            if (window.powerProfile === "balanced") return width + window.s(2);
                            return (width * 2) + window.s(2);
                        }

                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

                        color: window.profileStart
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0
                        
                        Repeater {
                            model: ListModel {
                                ListElement { name: "performance"; icon: "󰓅"; label: "Perform" } 
                                ListElement { name: "balanced"; icon: "󰗑"; label: "Balance" }   
                                ListElement { name: "power-saver"; icon: "󰌪"; label: "Saver" } 
                            }
                            
                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: window.s(8)
                                    Text {
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: window.s(18)
                                        color: window.powerProfile === name ? window.base : (profileMa.containsMouse ? window.text : window.subtext0)
                                        text: icon
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text {
                                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: window.s(13)
                                        color: window.powerProfile === name ? window.base : (profileMa.containsMouse ? window.text : window.subtext0)
                                        text: label
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }
                                
                                MouseArea {
                                    id: profileMa
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { Quickshell.execDetached(["powerprofilesctl", "set", name]); sysPoller.running = true; }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
