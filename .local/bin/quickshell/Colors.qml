import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: colors_root

    property var theme_palette: ["#1e1e2e", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#cba6f7", "#94e2d5", "#cdd6f4", "#6c7086", "#fab387", "#a6e3a1", "#f9e2af", "#89b4fa", "#cba6f7", "#94e2d5", "#bac2de"]
    property color background: "#181825"
    property color text: "#cdd6f4"

    Process {
        id: config_reader

        command: ["cat", Quickshell.env("HOME") + "/.config/wallust/colorscheme.json"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!this.text) {
                        return;
                    }
                    
                    let colorscheme = JSON.parse(this.text);
                    
                    if (colorscheme.colors) {
                        colors_root.theme_palette = colorscheme.colors;
                    }

                    if (colorscheme.background) {
                        colors_root.background = colorscheme.background;
                    }

                    if (colorscheme.foreground) {
                        colors_root.text = colorscheme.foreground;
                    }

                } catch (e) {
                    console.error(e);
                }
            }
        }

    }

}
