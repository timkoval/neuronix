import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Variants {
    model: Quickshell.screens
    
    delegate: Component {
        PanelWindow {
        id: barWindow

        required property var modelData
            
            // Bind this specific bar instance to the dynamically assigned screen
            screen: modelData
            
            anchors {
                top: true
                left: true
                right: true
            }
            
            // --- Responsive Scaling Logic ---
            Scaler {
                id: scaler
                currentWidth: barWindow.width
            }

            property real baseScale: scaler.baseScale
            
            // Helper function mapped to the external scaler
            function s(val) { 
                return scaler.s(val); 
            }

            property int barHeight: s(40)

            // THICKER BAR, MINIMAL MARGINS (Scaled)
            height: barHeight
            margins { top: s(8); bottom: 0; left: s(4); right: s(4) }
            
            // exclusiveZone = height + top margin
            exclusiveZone: barHeight + s(4)
            color: "transparent"

            // Dynamic Matugen Palette
            MatugenColors {
                id: mocha
            }

            // --- State Variables ---
            
            // Desktop Chassis Detection
            property bool isDesktop: false
            property string ethStatus: "Ethernet"

            Process {
                id: chassisDetector
                running: true
                command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        barWindow.isDesktop = (this.text.trim() === "desktop");
                    }
                }
            }

            Process {
                id: ethStatusPoller
                running: barWindow.isDesktop
                command: ["bash", "-c", "nmcli -t -f TYPE,STATE dev | grep 'ethernet' | grep -q 'connected' && echo 'Connected' || echo 'Disconnected'"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let status = this.text.trim();
                        if (status !== "") barWindow.ethStatus = status;
                    }
                }
            }
            Timer {
                interval: 3000; running: barWindow.isDesktop; repeat: true
                onTriggered: ethStatusPoller.running = true
            }

            // Triggers layout animations immediately to feel fast
            property bool isStartupReady: false
            Timer { interval: 10; running: true; onTriggered: barWindow.isStartupReady = true }
            
            // Prevents repeaters (Workspaces/Tray) from flickering on data updates
            property bool startupCascadeFinished: false
            Timer { interval: 1000; running: true; onTriggered: barWindow.startupCascadeFinished = true }
            
            // Data gating to prevent startup layout jumping
            property bool sysPollerLoaded: false
            property bool fastPollerLoaded: false
            
            // FIXED: Only wait for the instant data to load the UI. 
            // The slow network scripts will populate smoothly when they finish.
            property bool isDataReady: fastPollerLoaded
            // Failsafe: Force the layout to show after 600ms even if fast poller hangs
            Timer { interval: 600; running: true; onTriggered: barWindow.isDataReady = true }
            
            property string timeStr: ""
            property string fullDateStr: ""
            property int typeInIndex: 0
            property string dateStr: fullDateStr.substring(0, typeInIndex)

            property string weatherIcon: ""
            property string weatherTemp: "--°"
            property string weatherHex: mocha.yellow
            
            property string wifiStatus: "Off"
            property string wifiIcon: "󰤮"
            property string wifiSsid: ""
            
            property string btStatus: "Off"
            property string btIcon: "󰂲"
            property string btDevice: ""
            
            property string volPercent: "0%"
            property string volIcon: "󰕾"
            property bool isMuted: false
            
            property string batPercent: "100%"
            property string batIcon: "󰁹"
            property string batStatus: "Unknown"
            
            property string kbLayout: "us"
            
            ListModel { id: workspacesModel }
            
            property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }

            // Derived properties for UI logic
            property bool isMediaActive: barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
            property bool isWifiOn: barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
            property bool isBtOn: barWindow.btStatus.toLowerCase() === "enabled" || barWindow.btStatus.toLowerCase() === "on"
            
            property bool isSoundActive: !barWindow.isMuted && parseInt(barWindow.volPercent) > 0
            property int batCap: parseInt(barWindow.batPercent) || 0
            property bool isCharging: barWindow.batStatus === "Charging" || barWindow.batStatus === "Full"
            property color batDynamicColor: {
                if (isCharging) return mocha.green;
                if (batCap >= 70) return mocha.blue;
                if (batCap >= 30) return mocha.yellow;
                return mocha.red;
            }

            // CPU/RAM inline monitor
            property int cpuPercent: 0
            property int ramPercent: 0
            property var prevCpuJiffies: [0, 0, 0, 0]

            Process {
                id: sysMonPoller
                command: ["bash", "-c",
                    "head -1 /proc/stat; " +
                    "awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{printf \"%d\\n\", 100*(t-a)/t}' /proc/meminfo"
                ]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        let lines = this.text.trim().split("\n");
                        if (lines.length >= 2) {
                            let parts = lines[0].split(/\s+/);
                            let user = parseInt(parts[1]) || 0;
                            let nice = parseInt(parts[2]) || 0;
                            let sys  = parseInt(parts[3]) || 0;
                            let idle = parseInt(parts[4]) || 0;
                            let prev = barWindow.prevCpuJiffies;
                            let dWork = (user + nice + sys) - (prev[0] + prev[1] + prev[2]);
                            let dTotal = dWork + (idle - prev[3]);
                            if (dTotal > 0 && prev[0] > 0) {
                                barWindow.cpuPercent = Math.round(100 * dWork / dTotal);
                            }
                            barWindow.prevCpuJiffies = [user, nice, sys, idle];
                            barWindow.ramPercent = parseInt(lines[1]) || 0;
                        }
                    }
                }
            }
            Timer {
                interval: 2000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: sysMonPoller.running = true
            }

                        // ==========================================
            // DATA FETCHING 
            // ==========================================

            // Workspaces --------------------------------
            // 1. The continuous background daemon
            Process {
                id: wsDaemon
                command: ["bash", "-c", "~/.config/niri/scripts/quickshell/workspaces.sh " + barWindow.screen.name]
                running: true
            }

            // 2. The lightweight reader
            Process {
                id: wsReader
                command: ["cat", "/tmp/qs_workspaces_" + barWindow.screen.name + ".json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try { 
                                let newData = JSON.parse(txt);
                                if (workspacesModel.count !== newData.length) {
                                    workspacesModel.clear();
                                    for (let i = 0; i < newData.length; i++) {
                                        workspacesModel.append({ "wsId": newData[i].id.toString(), "wsState": newData[i].state });
                                    }
                                } else {
                                    for (let i = 0; i < newData.length; i++) {
                                        if (workspacesModel.get(i).wsState !== newData[i].state) {
                                            workspacesModel.setProperty(i, "wsState", newData[i].state);
                                        }
                                        if (workspacesModel.get(i).wsId !== newData[i].id.toString()) {
                                            workspacesModel.setProperty(i, "wsId", newData[i].id.toString());
                                        }
                                    }
                                }
                            } catch(e) {}
                        }
                    }
                }
            }

            // 3. ZERO-CPU Event Watcher (Replaces the brutal 50ms timer)
            Process {
                id: wsWatcher
                running: true
                command: ["bash", "-c", "inotifywait -qq -e close_write,modify /tmp/qs_workspaces_" + barWindow.screen.name + ".json"]
                onExited: {
                    wsReader.running = true;
                    running = true;
                }
            }

            // Music -------------------------------------
            // 1. Fast cache reader to smoothly update the UI 
            Process {
                id: musicPoller
                command: ["cat", "/tmp/music_info.json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try { barWindow.musicData = JSON.parse(txt); } catch(e) {}
                        }
                    }
                }
            }

            // 2. Direct executor for zero-latency UI state changes (play/pause skips)
            Process {
                id: musicForceRefresh
                running: true
                command: ["bash", "-c", "bash ~/.config/niri/scripts/quickshell/music/music_info.sh | tee /tmp/music_info.json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try { barWindow.musicData = JSON.parse(txt); } catch(e) {}
                        }
                    }
                }
            }

            // 3. Lightweight timer to update the progress clock without freezing
            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: musicPoller.running = true
            }

            // Unified System Info ------------------------
            Process {
                id: sysPoller
                running: true
                command: ["bash", "-c", "~/.config/niri/scripts/quickshell/sys_info.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                
                                // Targeted Updates
                                if (barWindow.wifiStatus !== data.wifi.status) barWindow.wifiStatus = data.wifi.status;
                                if (barWindow.wifiIcon !== data.wifi.icon) barWindow.wifiIcon = data.wifi.icon;
                                if (barWindow.wifiSsid !== data.wifi.ssid) barWindow.wifiSsid = data.wifi.ssid;

                                if (barWindow.btStatus !== data.bt.status) barWindow.btStatus = data.bt.status;
                                if (barWindow.btIcon !== data.bt.icon) barWindow.btIcon = data.bt.icon;
                                if (barWindow.btDevice !== data.bt.connected) barWindow.btDevice = data.bt.connected;

                                let newVol = data.audio.volume.toString() + "%";
                                if (barWindow.volPercent !== newVol) barWindow.volPercent = newVol;
                                if (barWindow.volIcon !== data.audio.icon) barWindow.volIcon = data.audio.icon;
                                
                                let newMuted = (data.audio.is_muted === "true");
                                if (barWindow.isMuted !== newMuted) barWindow.isMuted = newMuted;

                                let newBat = data.battery.percent.toString() + "%";
                                if (barWindow.batPercent !== newBat) barWindow.batPercent = newBat;
                                if (barWindow.batIcon !== data.battery.icon) barWindow.batIcon = data.battery.icon;
                                if (barWindow.batStatus !== data.battery.status) barWindow.batStatus = data.battery.status;

                                if (barWindow.kbLayout !== data.keyboard.layout) barWindow.kbLayout = data.keyboard.layout;

                                barWindow.sysPollerLoaded = true;
                                barWindow.fastPollerLoaded = true;
                            } catch(e) {}
                        }
                        // When the system/music waiter finishes, instantly refresh the music state
                        musicForceRefresh.running = true; 
                        sysWaiter.running = true;
                    }
                }
            }
            
            Process {
                id: sysWaiter
                command: ["bash", "-c", "~/.config/niri/scripts/quickshell/sys_waiter.sh"]
                // Strictly use onExited. Quickshell will no longer hook into stdout, preventing pipe deadlocks.
                onExited: sysPoller.running = true 
            }

            // Weather remains a slow poll since it fetches from web
            Process {
                id: weatherPoller
                command: ["bash", "-c", `
                    echo "$(~/.config/niri/scripts/quickshell/calendar/weather.sh --current-icon)"
                    echo "$(~/.config/niri/scripts/quickshell/calendar/weather.sh --current-temp)"
                    echo "$(~/.config/niri/scripts/quickshell/calendar/weather.sh --current-hex)"
                `]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let lines = this.text.trim().split("\n");
                        if (lines.length >= 3) {
                            barWindow.weatherIcon = lines[0];
                            barWindow.weatherTemp = lines[1];
                            barWindow.weatherHex = lines[2] || mocha.yellow;
                        }
                    }
                }
            }
            Timer { interval: 150000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherPoller.running = true }

            // Native Qt Time Formatting
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: {
                    let d = new Date();
                    barWindow.timeStr = Qt.formatDateTime(d, "hh:mm:ss AP");
                    barWindow.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
                    if (barWindow.typeInIndex >= barWindow.fullDateStr.length) {
                        barWindow.typeInIndex = barWindow.fullDateStr.length;
                    }
                }
            }

            // Typewriter effect timer for the date
            Timer {
                id: typewriterTimer
                interval: 40
                running: barWindow.isStartupReady && barWindow.typeInIndex < barWindow.fullDateStr.length
                repeat: true
                onTriggered: barWindow.typeInIndex += 1
            }

            // ==========================================
            // UI LAYOUT
            // ==========================================
            Item {
                anchors.fill: parent

                // ---------------- CENTER (MUST BE DECLARED FIRST OR Z-INDEXED FOR PROPER ANCHORING BORDERS) ----------------
                Rectangle {
                    id: centerBox
                    anchors.centerIn: parent
                    property bool isHovered: centerMouse.containsMouse
                    color: isHovered ? mocha.surface1 : mocha.base
                    radius: barWindow.s(4); border.width: 1; border.color: isHovered ? mocha.surface2 : mocha.surface1
                    height: barWindow.barHeight
                    
                    width: centerLayout.implicitWidth + barWindow.s(36)
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                    
                    // Staggered Center Transition
                    property bool showLayout: false
                    opacity: showLayout ? 1 : 0
                    transform: Translate {
                        y: centerBox.showLayout ? 0 : barWindow.s(-30)
                        Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutQuart } }
                    }

                    Timer {
                        running: barWindow.isStartupReady
                        interval: 150
                        onTriggered: centerBox.showLayout = true
                    }

                    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

                    // Hover Scaling
                    Behavior on color { ColorAnimation { duration: 250 } }
                    
                    MouseArea {
                        id: centerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/niri/scripts/qs_manager.sh toggle calendar --screen " + barWindow.screen.name])
                    }

                    // Using RowLayout to perfectly align children to vertical center naturally
                    RowLayout {
                        id: centerLayout
                        anchors.centerIn: parent
                        spacing: barWindow.s(24)

                        // Clockbox
                        ColumnLayout {
                            spacing: -2
                            Text { text: barWindow.timeStr; Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(16); font.weight: Font.Bold; color: mocha.blue }
                            Text { text: barWindow.dateStr; Layout.alignment: Qt.AlignHCenter; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(11); font.weight: Font.Bold; color: mocha.subtext0 }
                        }

                        // Weatherbox
                        RowLayout {
                            spacing: barWindow.s(8)
                            Text { 
                                text: barWindow.weatherIcon; 
                                Layout.alignment: Qt.AlignVCenter;
                                font.family: "Iosevka Nerd Font"; 
                                font.pixelSize: barWindow.s(24); 
                                color: barWindow.weatherHex 
                            }
                            Text { 
                                text: barWindow.weatherTemp; 
                                Layout.alignment: Qt.AlignVCenter;
                                font.family: "JetBrains Mono"; 
                                font.pixelSize: barWindow.s(17); 
                                font.weight: Font.Bold; 
                                color: mocha.peach 
                            }
                        }
                    }
                }

                // ---------------- LEFT ----------------
                RowLayout {
                    id: leftLayout
                    anchors.left: parent.left
                    anchors.right: centerBox.left  // Hard boundary to prevent overlaps
                    anchors.rightMargin: barWindow.s(12)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: barWindow.s(4) 

                    // Staggered Main Transition
                    property bool showLayout: false
                    opacity: showLayout ? 1 : 0
                    transform: Translate {
                        x: leftLayout.showLayout ? 0 : barWindow.s(-30)
                        Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutQuart } }
                    }
                    
                    Timer {
                        running: barWindow.isStartupReady
                        interval: 10
                        onTriggered: leftLayout.showLayout = true
                    }

                    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

                    property int moduleHeight: barWindow.barHeight

                    // Search 
                    Rectangle {
                        property bool isHovered: searchMouse.containsMouse
                        color: isHovered ? mocha.surface1 : mocha.base
                        radius: barWindow.s(4); border.width: 1; border.color: isHovered ? mocha.surface2 : mocha.surface1
                        Layout.preferredHeight: parent.moduleHeight; Layout.preferredWidth: barWindow.barHeight
                        Behavior on color { ColorAnimation { duration: 200 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰍉"
                            font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(24)
                            color: parent.isHovered ? mocha.blue : mocha.text
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        MouseArea {
                            id: searchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["walker"])
                        }
                    }

                    // Inline CPU/RAM Monitor
                    Rectangle {
                        property bool isHovered: sysMonMouse.containsMouse
                        color: isHovered ? mocha.surface1 : mocha.base
                        radius: barWindow.s(4); border.width: 1; border.color: isHovered ? mocha.surface2 : mocha.surface1
                        Layout.preferredHeight: parent.moduleHeight
                        Layout.preferredWidth: sysMonRow.width + barWindow.s(20)
                        clip: true

                        Behavior on color { ColorAnimation { duration: 200 } }

                        Row {
                            id: sysMonRow
                            anchors.centerIn: parent
                            spacing: barWindow.s(8)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰍹"
                                font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16)
                                color: barWindow.cpuPercent >= 80 ? mocha.red : mocha.blue
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: barWindow.cpuPercent + "%"
                                font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(12); font.weight: Font.Bold
                                color: barWindow.cpuPercent >= 80 ? mocha.red : mocha.text
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ""
                                font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16)
                                color: barWindow.ramPercent >= 80 ? mocha.red : mocha.green
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: barWindow.ramPercent + "%"
                                font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(12); font.weight: Font.Bold
                                color: barWindow.ramPercent >= 80 ? mocha.red : mocha.text
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                        MouseArea {
                            id: sysMonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/niri/scripts/qs_manager.sh toggle dashboard --screen " + barWindow.screen.name])
                        }
                    }

                    // Workspaces 
                    Rectangle {
                        color: mocha.base
                        radius: barWindow.s(4); border.width: 1; border.color: mocha.surface1
                        Layout.preferredHeight: parent.moduleHeight
                        clip: true
                        
                        property real targetWidth: workspacesModel.count > 0 ? wsLayout.width + barWindow.s(20) : 0
                        Layout.preferredWidth: targetWidth
                        visible: targetWidth > 0
                        opacity: workspacesModel.count > 0 ? 1 : 0
                        
                        Behavior on opacity { NumberAnimation { duration: 300 } }

                        // Using standard Row completely removes internal width sizing bugs
                        Row {
                            id: wsLayout
                            anchors.centerIn: parent
                            spacing: barWindow.s(6)
                            
                            Repeater {
                                model: workspacesModel
                                delegate: Rectangle {
                                    id: wsPill
                                    property bool isHovered: wsPillMouse.containsMouse
                                    
                                    // Mapped dynamically from the ListModel
                                    property string stateLabel: model.wsState
                                    property string wsName: model.wsId
                                    
                                    property real targetWidth: barWindow.s(32)
                                    width: targetWidth
                                    Behavior on targetWidth { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                                    
                                    height: barWindow.s(32); radius: barWindow.s(4)
                                    
                                    color: stateLabel === "active" 
                                            ? mocha.mauve 
                                            : (isHovered 
                                                ? mocha.overlay0 
                                                : (stateLabel === "occupied" 
                                                    ? mocha.surface2 
                                                    : "transparent"))

                                    scale: isHovered && stateLabel !== "active" ? 1.08 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                                    
                                    property bool initAnimTrigger: false
                                    opacity: initAnimTrigger ? 1 : 0
                                    transform: Translate {
                                        y: wsPill.initAnimTrigger ? 0 : barWindow.s(15)
                                        Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
                                    }

                                    Component.onCompleted: {
                                        if (!barWindow.startupCascadeFinished) {
                                            animTimer.interval = index * 60;
                                            animTimer.start();
                                        } else {
                                            initAnimTrigger = true;
                                        }
                                    }

                                    Timer {
                                        id: animTimer
                                        running: false
                                        repeat: false
                                        onTriggered: wsPill.initAnimTrigger = true
                                    }
                                    
                                    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 250 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: wsName
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: barWindow.s(14)
                                        font.weight: stateLabel === "active" ? Font.Bold : (stateLabel === "occupied" ? Font.Bold : Font.Medium)
                                        
                                        color: stateLabel === "active" 
                                                ? mocha.base 
                                                : (isHovered 
                                                    ? mocha.base 
                                                    : (stateLabel === "occupied" ? mocha.text : mocha.overlay0))
                                        
                                        Behavior on color { ColorAnimation { duration: 250 } }
                                    }
                                    MouseArea {
                                        id: wsPillMouse
                                        hoverEnabled: true
                                        anchors.fill: parent
                                        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/niri/scripts/qs_manager.sh " + wsName + " --screen " + barWindow.screen.name])
                                    }
                                }
                            }
                        }
                    }            

                    // Media Player 
                    Rectangle {
                        id: mediaBox
                        color: mocha.base
                        radius: barWindow.s(4); border.width: 1; border.color: mocha.surface1
                        Layout.preferredHeight: parent.moduleHeight
                        clip: true 
                        
                        property real targetWidth: barWindow.isMediaActive ? mediaLayoutContainer.width + barWindow.s(24) : 0
                        Layout.maximumWidth: targetWidth
                        Layout.preferredWidth: targetWidth
                        
                        visible: targetWidth > 0 || opacity > 0
                        opacity: barWindow.isMediaActive ? 1.0 : 0.0

                        Behavior on targetWidth { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                        
                        Item {
                            id: mediaLayoutContainer
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: barWindow.s(12)
                            height: parent.height
                            width: innerMediaLayout.width
                            
                            opacity: barWindow.isMediaActive ? 1.0 : 0.0
                            transform: Translate { 
                                x: barWindow.isMediaActive ? 0 : barWindow.s(-20) 
                                Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
                            }
                            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

                            Row {
                                id: innerMediaLayout
                                anchors.verticalCenter: parent.verticalCenter
                                // Dynamically reduce spacing between song info and controls on smaller screens
                                spacing: barWindow.width < 1920 ? barWindow.s(8) : barWindow.s(16)
                                
                                MouseArea {
                                    id: mediaInfoMouse
                                    width: infoLayout.width
                                    height: innerMediaLayout.height
                                    hoverEnabled: true
                                    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/niri/scripts/qs_manager.sh toggle music --screen " + barWindow.screen.name])
                                    
                                    Row {
                                        id: infoLayout
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: barWindow.s(10)

                                        Rectangle {
                                            width: barWindow.s(32); height: barWindow.s(32); radius: barWindow.s(4); color: mocha.surface1
                                            border.width: barWindow.musicData.status === "Playing" ? 1 : 0
                                            border.color: mocha.mauve
                                            clip: true
                                            Image { 
                                                anchors.fill: parent; 
                                                source: barWindow.musicData.artUrl || ""; 
                                                fillMode: Image.PreserveAspectCrop 
                                            }
                                        }
                                        Column {
                                            spacing: -2
                                            anchors.verticalCenter: parent.verticalCenter
                                            // Make column explicitly sized to enforce elide truncating on text
                                            property real maxColWidth: barWindow.width < 1920 ? barWindow.s(120) : barWindow.s(180)
                                            width: maxColWidth 
                                            
                                            Text { 
                                                text: barWindow.musicData.title; 
                                                font.family: "JetBrains Mono"; 
                                                font.weight: Font.Bold; 
                                                font.pixelSize: barWindow.s(13); 
                                                color: mocha.text;
                                                width: parent.width
                                                elide: Text.ElideRight; 
                                            }
                                            Text { 
                                                text: barWindow.musicData.timeStr; 
                                                font.family: "JetBrains Mono"; 
                                                font.weight: Font.Bold; 
                                                font.pixelSize: barWindow.s(10); 
                                                color: mocha.subtext0;
                                                width: parent.width
                                                elide: Text.ElideRight;
                                            }
                                        }
                                    }
                                }

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: barWindow.width < 1920 ? barWindow.s(4) : barWindow.s(8)
                                    Item { 
                                        width: barWindow.s(24); height: barWindow.s(24); 
                                        Text { 
                                            anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(26); 
                                            color: prevMouse.containsMouse ? mocha.text : mocha.overlay2; 
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        MouseArea { id: prevMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "previous"]); musicForceRefresh.running = true; } } 
                                    }
                                    Item { 
                                        width: barWindow.s(28); height: barWindow.s(28); 
                                        Text { 
                                            anchors.centerIn: parent; text: barWindow.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(30); 
                                            color: playMouse.containsMouse ? mocha.green : mocha.text; 
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        MouseArea { id: playMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "play-pause"]); musicForceRefresh.running = true; } } 
                                    }
                                    Item { 
                                        width: barWindow.s(24); height: barWindow.s(24); 
                                        Text { 
                                            anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(26); 
                                            color: nextMouse.containsMouse ? mocha.text : mocha.overlay2; 
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        MouseArea { id: nextMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "next"]); musicForceRefresh.running = true; } } 
                                    }
                                }
                            }
                        }
                    }
                    
                    // DYNAMIC SPACER: Pushes everything tightly to the left side
                    Item { Layout.fillWidth: true } 
                }

                // ---------------- RIGHT ----------------
                RowLayout {
                    id: rightLayout
                    anchors.right: parent.right
                    anchors.left: centerBox.right // Hard boundary to prevent overlaps
                    anchors.leftMargin: barWindow.s(12)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: barWindow.s(4)

                    // Staggered Right Transition
                    property bool showLayout: false
                    opacity: showLayout ? 1 : 0
                    transform: Translate {
                        x: rightLayout.showLayout ? 0 : barWindow.s(30)
                        Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutQuart } }
                    }
                    
                    Timer {
                        running: barWindow.isStartupReady && barWindow.isDataReady
                        interval: 250
                        onTriggered: rightLayout.showLayout = true
                    }

                    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

                    // Dynamic Spacer to gently push the tray and system pills completely to the right edge
                    Item { Layout.fillWidth: true } 

                    // Next Calendar Event
                    Rectangle {
                        property bool isHovered: eventMouse.containsMouse
                        Layout.preferredHeight: barWindow.barHeight
                        radius: barWindow.s(4)
                        border.color: isHovered ? mocha.surface2 : mocha.surface1
                        border.width: 1
                        color: isHovered ? mocha.surface1 : mocha.base
                        clip: true

                        property string nextEventSubject: ""
                        property string nextEventTime: ""
                        property bool eventActive: false

                        property real targetWidth: nextEventSubject !== "" ? eventRow.width + barWindow.s(24) : 0
                        Layout.preferredWidth: targetWidth
                        Layout.maximumWidth: targetWidth
                        visible: targetWidth > 0
                        opacity: nextEventSubject !== "" ? 1 : 0

                        Behavior on targetWidth { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Process {
                            id: eventPoller
                            command: ["bash", "-c", "cat ~/.cache/quickshell/schedule/schedule.json 2>/dev/null"]
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    let txt = this.text.trim();
                                    if (txt === "") return;
                                    try {
                                        let data = JSON.parse(txt);
                                        let now = Math.floor(Date.now() / 1000);
                                        let found = false;
                                        for (let i = 0; i < data.lessons.length; i++) {
                                            let ev = data.lessons[i];
                                            if (ev.type !== "class") continue;
                                            if (ev.end > now) {
                                                parent.nextEventSubject = ev.subject || "";
                                                parent.nextEventTime = ev.time ? ev.time.split(" - ")[0] : "";
                                                parent.eventActive = (ev.start <= now && ev.end > now);
                                                found = true;
                                                break;
                                            }
                                        }
                                        if (!found) {
                                            parent.nextEventSubject = "";
                                            parent.nextEventTime = "";
                                            parent.eventActive = false;
                                        }
                                    } catch(e) {}
                                }
                            }
                        }
                        Timer {
                            interval: 60000; running: true; repeat: true; triggeredOnStart: true
                            onTriggered: eventPoller.running = true
                        }

                        Row {
                            id: eventRow
                            anchors.centerIn: parent
                            spacing: barWindow.s(8)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰌳"
                                font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16)
                                color: parent.parent.eventActive ? mocha.green : mocha.blue
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.nextEventTime
                                font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(12); font.weight: Font.Bold
                                color: parent.parent.eventActive ? mocha.green : mocha.text
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.nextEventSubject
                                font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(12); font.weight: Font.Bold
                                color: mocha.subtext0
                                width: Math.min(implicitWidth, barWindow.s(180))
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: eventMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/niri/scripts/qs_manager.sh toggle calendar --screen " + barWindow.screen.name])
                        }
                    }

                    // System Elements Pill
                    Rectangle {
                        Layout.preferredHeight: barWindow.barHeight // THE FIX: Replaced basic "height"
                        radius: barWindow.s(4)
                        border.color: mocha.surface1
                        border.width: 1
                        color: mocha.base
                        clip: true
                        
                        property real targetWidth: sysLayout.width + barWindow.s(20)
                        Layout.preferredWidth: targetWidth
                        Layout.maximumWidth: targetWidth

                        Row {
                            id: sysLayout
                            anchors.centerIn: parent
                            spacing: barWindow.s(8) 

                            property int pillHeight: barWindow.s(34)

                            // KB
                            Rectangle {
                                property bool isHovered: kbMouse.containsMouse
                                color: isHovered ? mocha.surface1 : mocha.surface0
                                radius: barWindow.s(4); height: sysLayout.pillHeight;
                                clip: true
                                
                                property real targetWidth: kbLayoutRow.width + barWindow.s(24)
                                width: targetWidth
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                property bool initAnimTrigger: false
                                Timer { running: rightLayout.showLayout && !parent.initAnimTrigger; interval: 0; onTriggered: parent.initAnimTrigger = true }
                                opacity: initAnimTrigger ? 1 : 0
                                transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } } }
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                                Row { 
                                    id: kbLayoutRow; anchors.centerIn: parent; spacing: barWindow.s(8)
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16); color: parent.parent.isHovered ? mocha.text : mocha.overlay2 }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: barWindow.kbLayout; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Bold; color: mocha.text }
                                }
                                MouseArea { id: kbMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["niri", "msg", "action", "switch-layout", "next"]) }
                            }

                            // WiFi / Ethernet (Desktop Mode)
                            Rectangle {
                                id: wifiPill
                                property bool isHovered: wifiMouse.containsMouse
                                radius: barWindow.s(4); height: sysLayout.pillHeight; 
                                color: isHovered ? mocha.surface1 : mocha.surface0
                                clip: true
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: barWindow.s(4)
                                    opacity: barWindow.isDesktop ? (barWindow.ethStatus === "Connected" ? 1.0 : 0.0) : (barWindow.isWifiOn ? 1.0 : 0.0)
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    color: mocha.blue
                                }

                                property real targetWidth: wifiLayoutRow.width + barWindow.s(24)
                                width: targetWidth
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                property bool initAnimTrigger: false
                                Timer { running: rightLayout.showLayout && !parent.initAnimTrigger; interval: 50; onTriggered: parent.initAnimTrigger = true }
                                opacity: initAnimTrigger ? 1 : 0
                                transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } } }
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                                Row { 
                                    id: wifiLayoutRow; anchors.centerIn: parent; spacing: barWindow.s(8)
                                    Text { 
                                        anchors.verticalCenter: parent.verticalCenter; 
                                        text: barWindow.isDesktop ? "󰈀" : barWindow.wifiIcon; 
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16); 
                                        color: barWindow.isDesktop ? (barWindow.ethStatus === "Connected" ? mocha.base : mocha.subtext0) : (barWindow.isWifiOn ? mocha.base : mocha.subtext0) 
                                    }
                                    Text { 
                                        id: wifiText
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barWindow.isDesktop ? barWindow.ethStatus : (barWindow.sysPollerLoaded ? (barWindow.isWifiOn ? (barWindow.wifiSsid !== "" ? barWindow.wifiSsid : "On") : "Off") : "")
                                        visible: text !== ""
                                        font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Bold; 
                                        color: barWindow.isDesktop ? (barWindow.ethStatus === "Connected" ? mocha.base : mocha.text) : (barWindow.isWifiOn ? mocha.base : mocha.text); 
                                        width: Math.min(implicitWidth, barWindow.s(100)); elide: Text.ElideRight 
                                    }
                                }
                                MouseArea { id: wifiMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/niri/scripts/qs_manager.sh toggle network wifi --screen " + barWindow.screen.name]) }
                            }

                            // Bluetooth (Collapsed on Desktop)
                            Rectangle {
                                id: btPill
                                property bool isHovered: btMouse.containsMouse
                                radius: barWindow.s(4); height: sysLayout.pillHeight
                                clip: true
                                color: isHovered ? mocha.surface1 : mocha.surface0
                                
                                Rectangle {
                                    anchors.fill: parent
                                    radius: barWindow.s(4)
                                    opacity: barWindow.isBtOn ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    color: mocha.mauve
                                }

                                property real targetWidth: barWindow.isDesktop ? 0 : btLayoutRow.width + barWindow.s(24)
                                width: targetWidth
                                visible: targetWidth > 0
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                property bool initAnimTrigger: false
                                Timer { running: rightLayout.showLayout && !parent.initAnimTrigger; interval: 100; onTriggered: parent.initAnimTrigger = true }
                                opacity: initAnimTrigger ? 1 : 0
                                transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } } }
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                                Row { 
                                    id: btLayoutRow; anchors.centerIn: parent; spacing: barWindow.s(8)
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: barWindow.btIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16); color: barWindow.isBtOn ? mocha.base : mocha.subtext0 }
                                    Text { 
                                        id: btText
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barWindow.sysPollerLoaded ? barWindow.btDevice : ""
                                        visible: text !== ""; 
                                        font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Bold; 
                                        color: barWindow.isBtOn ? mocha.base : mocha.text; 
                                        width: Math.min(implicitWidth, barWindow.s(100)); elide: Text.ElideRight 
                                    }
                                }
                                MouseArea { id: btMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/niri/scripts/qs_manager.sh toggle network bt --screen " + barWindow.screen.name]) }
                            }

                            // Volume
                            Rectangle {
                                property bool isHovered: volMouse.containsMouse
                                color: isHovered ? mocha.surface1 : mocha.surface0
                                radius: barWindow.s(4); height: sysLayout.pillHeight;
                                clip: true

                                Rectangle {
                                    anchors.fill: parent
                                    radius: barWindow.s(4)
                                    opacity: barWindow.isSoundActive ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    color: mocha.peach
                                }
                                
                                property real targetWidth: volLayoutRow.width + barWindow.s(24)
                                width: targetWidth
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                property bool initAnimTrigger: false
                                Timer { running: rightLayout.showLayout && !parent.initAnimTrigger; interval: 150; onTriggered: parent.initAnimTrigger = true }
                                opacity: initAnimTrigger ? 1 : 0
                                transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } } }
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                                Row { 
                                    id: volLayoutRow; anchors.centerIn: parent; spacing: barWindow.s(8)
                                    Text { 
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barWindow.volIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.s(16); 
                                        color: barWindow.isSoundActive ? mocha.base : mocha.subtext0 
                                    }
                                    Text { 
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barWindow.volPercent; 
                                        font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Bold; 
                                        color: barWindow.isSoundActive ? mocha.base : mocha.text; 
                                    }
                                }
                                MouseArea { id: volMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/niri/scripts/qs_manager.sh toggle volume --screen " + barWindow.screen.name]) }
                            }

                            // Battery (or Power button for Desktop)
                            Rectangle {
                                property bool isHovered: batMouse.containsMouse
                                color: barWindow.isDesktop 
                                        ? (isHovered ? mocha.surface1 : mocha.surface0) 
                                        : (isHovered ? mocha.surface1 : mocha.surface0); 
                                radius: barWindow.s(4); height: sysLayout.pillHeight;
                                clip: true

                                Rectangle {
                                    anchors.fill: parent
                                    radius: barWindow.s(4)
                                    opacity: barWindow.isDesktop ? 1.0 : ((barWindow.isCharging || barWindow.batCap <= 20) ? 1.0 : 0.0)
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                    color: barWindow.isDesktop ? mocha.red : barWindow.batDynamicColor

                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                                
                                property real targetWidth: barWindow.isDesktop ? barWindow.s(34) : batLayoutRow.width + barWindow.s(24)
                                width: targetWidth
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                property bool initAnimTrigger: false
                                Timer { running: rightLayout.showLayout && !parent.initAnimTrigger; interval: 200; onTriggered: parent.initAnimTrigger = true }
                                opacity: initAnimTrigger ? 1 : 0
                                transform: Translate { y: parent.initAnimTrigger ? 0 : barWindow.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } } }
                                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                                Row { 
                                    id: batLayoutRow; anchors.centerIn: parent; spacing: barWindow.s(8)
                                    Text { 
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: barWindow.isDesktop ? "" : barWindow.batIcon; 
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: barWindow.isDesktop ? barWindow.s(18) : barWindow.s(16); 
                                        color: barWindow.isDesktop ? mocha.base : ((barWindow.isCharging || barWindow.batCap <= 20) ? mocha.base : barWindow.batDynamicColor)
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                    Text { 
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !barWindow.isDesktop
                                        text: barWindow.batPercent; font.family: "JetBrains Mono"; font.pixelSize: barWindow.s(13); font.weight: Font.Bold; 
                                        color: (barWindow.isCharging || barWindow.batCap <= 20) ? mocha.base : barWindow.batDynamicColor
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                }
                                MouseArea { id: batMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/niri/scripts/qs_manager.sh toggle battery --screen " + barWindow.screen.name]) }
                            }
                        }
                    }
                }
            }
        }
    }
}
