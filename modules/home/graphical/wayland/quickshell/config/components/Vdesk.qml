pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string vdesk

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;

            if (n === "vdesk") {
                getdesk.running = true;
            }
        }

        target: Hyprland
    }

    Process {
        id: getdesk

        command: ["zsh", "-c", "hyprctl printdesk -j | jq -r .virtualdesk.name"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim();
                root.vdesk = text.charAt(0).toUpperCase() + text.slice(1);
            }
        }
    }
}
