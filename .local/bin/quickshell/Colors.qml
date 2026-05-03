import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var palette: [
        "#1e1e2e", "#f38ba8", "#a6e3a1", "#f9e2af", 
        "#89b4fa", "#cba6f7", "#94e2d5", "#cdd6f4",
        "#6c7086", "#fab387", "#a6e3a1", "#f9e2af", 
        "#89b4fa", "#cba6f7", "#94e2d5", "#bac2de"
    ]
    property color base: "#181825"
    property color text: "#cdd6f4"

    Process {
        id: reader
        command: ["cat", Quickshell.env("HOME") + "/.config/wallust/colorscheme.json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let w = JSON.parse(this.text);
                    if (w.colors) {
                        root.palette = w.colors;
                    }

                    if (w.background) {
                        root.background = w.background;
                    }

                    if (w.foreground) {
                        root.text = w.foreground;
                    }
                } catch(e) {
                    console.error(e);
                }
            }
        }
    }
}