import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    property bool dnd: false

    Process {
        id: watcher
        command: ["hokum", "dnd", "--json", "--watch"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try { root.dnd = JSON.parse(data).dnd; } catch (error) {}
            }
        }
        onExited: retry.restart()
    }
    Timer {
        id: retry
        interval: 5000
        onTriggered: watcher.running = true
    }

    pillClickAction: () => Quickshell.execDetached(["hokum"])
    pillRightClickAction: () => Quickshell.execDetached(["hokum", "dnd", "toggle"])

    horizontalBarPill: Component {
        DankIcon {
            name: root.dnd ? "notifications_off" : "notifications"
            color: root.dnd ? Theme.primary : Theme.surfaceText
            size: Theme.iconSize
        }
    }
    verticalBarPill: Component {
        DankIcon {
            name: root.dnd ? "notifications_off" : "notifications"
            color: root.dnd ? Theme.primary : Theme.surfaceText
            size: Theme.iconSize
        }
    }
}
