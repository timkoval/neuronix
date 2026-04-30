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
        currentWidth: Screen.width
    }

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
    property real cpuPercent: 0
    property real ramPercent: 0
    property string ramUsed: "0"
    property string ramTotal: "0"
    property string diskUsed: "0"
    property string diskTotal: "0"
    property string diskPercent: "0%"
    property string loadAvg1: "0.00"
    property string loadAvg5: "0.00"
    property string loadAvg15: "0.00"
    property real cpuTemp: 0
    property real nvmeTemp: 0
    property var prevCpuJiffies: [0, 0, 0, 0]

    function tempColor(temp) {
        if (temp >= 80) return window.red;
        if (temp >= 60) return window.yellow;
        return window.green;
    }

    function formatMem(kbStr) {
        let kb = parseFloat(kbStr);
        if (kb >= 1048576) return (kb / 1048576).toFixed(1) + "G";
        return (kb / 1024).toFixed(0) + "M";
    }

    Process {
        id: sysPoller
        command: ["bash", "-c",
            "head -1 /proc/stat; " +
            "awk '/^MemTotal/{print $2} /^MemAvailable/{print $2}' /proc/meminfo; " +
            "df -h / | awk 'NR==2{print $3, $2, $5}'; " +
            "cat /proc/loadavg; " +
            "sensors | awk '/Package id 0:/{gsub(/\\+/,\"\",$4); print $4}'; " +
            "sensors | awk '/Composite:/{gsub(/\\+/,\"\",$2); print $2}'"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 5) {
                    // CPU delta calculation
                    let cpuParts = lines[0].split(/\s+/);
                    if (cpuParts.length >= 5) {
                        let user = parseInt(cpuParts[1]) || 0;
                        let nice = parseInt(cpuParts[2]) || 0;
                        let system = parseInt(cpuParts[3]) || 0;
                        let idle = parseInt(cpuParts[4]) || 0;

                        let prevUser = window.prevCpuJiffies[0];
                        let prevNice = window.prevCpuJiffies[1];
                        let prevSystem = window.prevCpuJiffies[2];
                        let prevIdle = window.prevCpuJiffies[3];

                        let totalDelta = (user + nice + system + idle) - (prevUser + prevNice + prevSystem + prevIdle);
                        let idleDelta = idle - prevIdle;

                        if (totalDelta > 0 && prevUser > 0) {
                            window.cpuPercent = Math.round(((totalDelta - idleDelta) / totalDelta) * 100);
                        }

                        window.prevCpuJiffies = [user, nice, system, idle];
                    }

                    // RAM
                    let memTotal = parseFloat(lines[1]) || 1;
                    let memAvail = parseFloat(lines[2]) || 0;
                    let memUsed = memTotal - memAvail;
                    window.ramPercent = Math.round((memUsed / memTotal) * 100);
                    window.ramUsed = window.formatMem(memUsed.toString());
                    window.ramTotal = window.formatMem(memTotal.toString());

                    // Disk
                    let diskParts = lines[3].split(/\s+/);
                    if (diskParts.length >= 3) {
                        window.diskUsed = diskParts[0];
                        window.diskTotal = diskParts[1];
                        window.diskPercent = diskParts[2];
                    }

                    // Load averages
                    let loadParts = lines[4].split(/\s+/);
                    if (loadParts.length >= 3) {
                        window.loadAvg1 = loadParts[0];
                        window.loadAvg5 = loadParts[1];
                        window.loadAvg15 = loadParts[2];
                    }

                    // Temperatures
                    if (lines.length >= 6 && lines[5].length > 0) {
                        window.cpuTemp = parseFloat(lines[5]) || 0;
                    }
                    if (lines.length >= 7 && lines[6].length > 0) {
                        window.nvmeTemp = parseFloat(lines[6]) || 0;
                    }
                }
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: sysPoller.running = true
    }

    // --- ENTRY ANIMATION ---
    property real introOpacity: 0
    NumberAnimation {
        running: true
        target: window; property: "introOpacity"
        from: 0; to: 1.0; duration: 400
        easing.type: Easing.OutQuart
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        opacity: window.introOpacity

        Rectangle {
            anchors.fill: parent
            radius: window.s(4)
            color: window.base
            border.color: window.surface1
            border.width: 2
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: window.s(25)
                spacing: window.s(18)

                // ==========================================
                // TITLE
                // ==========================================
                Text {
                    text: "SYSTEM"
                    font.family: "JetBrains Mono"
                    font.weight: Font.Bold
                    font.pixelSize: window.s(18)
                    color: window.text
                }

                // ==========================================
                // USAGE BARS SECTION
                // ==========================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(160)
                    radius: window.s(4)
                    color: window.mantle
                    border.color: window.surface1
                    border.width: 2

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: window.s(16)
                        spacing: window.s(14)

                        // CPU Bar
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: window.s(12)

                            Text {
                                Layout.preferredWidth: window.s(48)
                                text: "CPU"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(13)
                                color: window.subtext0
                            }

                            Item {
                                Layout.fillWidth: true
                                height: window.s(18)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: window.s(4)
                                    color: window.surface1

                                    Rectangle {
                                        height: parent.height
                                        width: parent.width * (window.cpuPercent / 100)
                                        radius: window.s(4)
                                        color: window.blue
                                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                                    }
                                }
                            }

                            Text {
                                Layout.preferredWidth: window.s(48)
                                text: Math.round(window.cpuPercent) + "%"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(13)
                                color: window.text
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        // RAM Bar
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: window.s(12)

                            Text {
                                Layout.preferredWidth: window.s(48)
                                text: "RAM"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(13)
                                color: window.subtext0
                            }

                            Item {
                                Layout.fillWidth: true
                                height: window.s(18)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: window.s(4)
                                    color: window.surface1

                                    Rectangle {
                                        height: parent.height
                                        width: parent.width * (window.ramPercent / 100)
                                        radius: window.s(4)
                                        color: window.green
                                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                                    }
                                }
                            }

                            Text {
                                Layout.preferredWidth: window.s(48)
                                text: Math.round(window.ramPercent) + "%"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(13)
                                color: window.text
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        // DISK Bar
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: window.s(12)

                            Text {
                                Layout.preferredWidth: window.s(48)
                                text: "DISK"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(13)
                                color: window.subtext0
                            }

                            Item {
                                Layout.fillWidth: true
                                height: window.s(18)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: window.s(4)
                                    color: window.surface1

                                    Rectangle {
                                        height: parent.height
                                        width: parent.width * (parseInt(window.diskPercent) / 100)
                                        radius: window.s(4)
                                        color: window.yellow
                                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                                    }
                                }
                            }

                            Text {
                                Layout.preferredWidth: window.s(48)
                                text: window.diskPercent
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(13)
                                color: window.text
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                // ==========================================
                // USAGE DETAILS (RAM / DISK)
                // ==========================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(56)
                    radius: window.s(4)
                    color: window.mantle
                    border.color: window.surface1
                    border.width: 2

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: window.s(16)
                        spacing: window.s(20)

                        ColumnLayout {
                            spacing: window.s(2)
                            Text {
                                text: "RAM  " + window.ramUsed + " / " + window.ramTotal
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(12)
                                color: window.text
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ColumnLayout {
                            spacing: window.s(2)
                            Text {
                                text: "DISK  " + window.diskUsed + " / " + window.diskTotal
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(12)
                                color: window.text
                            }
                        }
                    }
                }

                // ==========================================
                // LOAD AVERAGES SECTION
                // ==========================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(72)
                    radius: window.s(4)
                    color: window.mantle
                    border.color: window.surface1
                    border.width: 2

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: window.s(16)
                        spacing: window.s(4)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: window.s(12)

                            Text {
                                text: "Load"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(13)
                                color: window.subtext0
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: window.loadAvg1
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(16)
                                color: window.text
                            }
                            Text {
                                text: window.loadAvg5
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(16)
                                color: window.text
                            }
                            Text {
                                text: window.loadAvg15
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(16)
                                color: window.text
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: window.s(12)

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "1min"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(10)
                                color: window.subtext0
                                Layout.preferredWidth: window.s(40)
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                text: "5min"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(10)
                                color: window.subtext0
                                Layout.preferredWidth: window.s(40)
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                text: "15min"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(10)
                                color: window.subtext0
                                Layout.preferredWidth: window.s(40)
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                // ==========================================
                // TEMPERATURES SECTION
                // ==========================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(72)
                    radius: window.s(4)
                    color: window.mantle
                    border.color: window.surface1
                    border.width: 2

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: window.s(16)
                        spacing: window.s(8)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: window.s(12)

                            Text {
                                text: "CPU"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(13)
                                color: window.subtext0
                                Layout.preferredWidth: window.s(48)
                            }

                            Text {
                                text: "󰔏"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: window.s(16)
                                color: window.tempColor(window.cpuTemp)
                            }

                            Text {
                                text: Math.round(window.cpuTemp) + "\u00B0C"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(14)
                                color: window.tempColor(window.cpuTemp)
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: window.s(12)

                            Text {
                                text: "NVMe"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(13)
                                color: window.subtext0
                                Layout.preferredWidth: window.s(48)
                            }

                            Text {
                                text: "󰔏"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: window.s(16)
                                color: window.tempColor(window.nvmeTemp)
                            }

                            Text {
                                text: Math.round(window.nvmeTemp) + "\u00B0C"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(14)
                                color: window.tempColor(window.nvmeTemp)
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
