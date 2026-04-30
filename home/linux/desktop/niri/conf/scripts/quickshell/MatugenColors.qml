import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Defaults: Stylix base16 (gruvbox-light-medium) mapped to Catppuccin names
    property color base: "#fbf1c7"
    property color mantle: "#ebdbb2"
    property color crust: "#ebdbb2"
    property color text: "#504945"
    property color subtext0: "#665c54"
    property color subtext1: "#665c54"
    property color surface0: "#ebdbb2"
    property color surface1: "#d5c4a1"
    property color surface2: "#bdae93"
    property color overlay0: "#665c54"
    property color overlay1: "#3c3836"
    property color overlay2: "#282828"
    property color blue: "#076678"
    property color sapphire: "#427b58"
    property color peach: "#af3a03"
    property color green: "#79740e"
    property color red: "#9d0006"
    property color mauve: "#8f3f71"
    property color pink: "#8f3f71"
    property color yellow: "#b57614"
    property color maroon: "#d65d0e"
    property color teal: "#427b58"

    property string rawJson: ""

    Process {
        id: themeReader
        command: ["cat", "/tmp/qs_colors.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "" && txt !== root.rawJson) {
                    root.rawJson = txt;
                    try {
                        let c = JSON.parse(txt);
                        if (c.base) root.base = c.base;
                        if (c.mantle) root.mantle = c.mantle;
                        if (c.crust) root.crust = c.crust;
                        if (c.text) root.text = c.text;
                        if (c.subtext0) root.subtext0 = c.subtext0;
                        if (c.subtext1) root.subtext1 = c.subtext1;
                        if (c.surface0) root.surface0 = c.surface0;
                        if (c.surface1) root.surface1 = c.surface1;
                        if (c.surface2) root.surface2 = c.surface2;
                        if (c.overlay0) root.overlay0 = c.overlay0;
                        if (c.overlay1) root.overlay1 = c.overlay1;
                        if (c.overlay2) root.overlay2 = c.overlay2;
                        if (c.blue) root.blue = c.blue;
                        if (c.sapphire) root.sapphire = c.sapphire;
                        if (c.peach) root.peach = c.peach;
                        if (c.green) root.green = c.green;
                        if (c.red) root.red = c.red;
                        if (c.mauve) root.mauve = c.mauve;
                        if (c.pink) root.pink = c.pink;
                        if (c.yellow) root.yellow = c.yellow;
                        if (c.maroon) root.maroon = c.maroon;
                        if (c.teal) root.teal = c.teal;
                    } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 1000 
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: themeReader.running = true
    }
}
