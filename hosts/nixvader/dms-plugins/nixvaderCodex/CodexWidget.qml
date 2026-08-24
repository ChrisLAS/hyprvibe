import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string usageText: "Codex …"
    property string details: "Waiting for codexbar"
    property color usageColor: Theme.primary

    function refresh() {
        if (!usageProcess.running)
            usageProcess.running = true;
    }

    function plainText(value) {
        return String(value || "").replace(/<[^>]*>/g, "");
    }

    function consume(output) {
        const trimmed = output.trim();
        if (!trimmed) {
            usageText = "Codex ?";
            details = "codexbar returned no data";
            usageColor = Theme.error;
            return;
        }

        try {
            const result = JSON.parse(trimmed);
            usageText = plainText(result.text) || trimmed;
            details = plainText(result.tooltip) || "Open Codex usage";
            const state = result.class || "";
            usageColor = state.indexOf("critical") >= 0 ? Theme.error
                : state.indexOf("warning") >= 0 ? Theme.warning
                : Theme.primary;
        } catch (error) {
            usageText = trimmed;
            details = "Open Codex usage";
            usageColor = Theme.primary;
        }
    }

    Process {
        id: usageProcess
        command: ["codexbar", "--format", "{session_pct}% {session_pace}"]
        stdout: StdioCollector {
            onStreamFinished: root.consume(text)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.usageText = "Codex !";
                root.details = "codexbar exited with status " + exitCode;
                root.usageColor = Theme.error;
            }
        }
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    pillClickAction: () => Quickshell.execDetached(["xdg-open", "https://chatgpt.com/codex/settings/usage"])
    pillRightClickAction: () => root.refresh()

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DankIcon {
                name: "terminal"
                color: root.usageColor
                font.pixelSize: Theme.iconSize - 6
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: root.usageText
                color: root.usageColor
                font.pixelSize: Theme.fontSizeMedium
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "terminal"
            color: root.usageColor
            font.pixelSize: Theme.iconSize - 4
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: "Codex usage"
            detailsText: root.details
            showCloseButton: true
            StyledText {
                width: parent.width
                text: "Left click opens the usage dashboard. Right click refreshes."
                color: Theme.surfaceTextMedium
                wrapMode: Text.WordWrap
            }
        }
    }
    popoutWidth: 360
    popoutHeight: 150
}
