import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string pacificTime: "PT …"
    property var zones: []

    function refresh() {
        if (!clockProcess.running)
            clockProcess.running = true;
    }

    function consume(output) {
        const rows = output.trim().split("\n").filter(row => row.length > 0);
        const parsed = [];
        for (let index = 0; index < rows.length; index++) {
            const columns = rows[index].split("|");
            if (columns.length >= 3)
                parsed.push({ "city": columns[0], "time": columns[1], "date": columns[2] });
        }
        if (parsed.length > 0) {
            zones = parsed;
            pacificTime = "PT " + parsed[0].time;
        }
    }

    Process {
        id: clockProcess
        command: [
            "bash", "-c",
            "for row in 'Pacific|America/Los_Angeles' 'New York|America/New_York' 'London|Europe/London' 'Berlin|Europe/Berlin' 'Tokyo|Asia/Tokyo'; do city=${row%%|*}; zone=${row#*|}; printf '%s|' \"$city\"; TZ=\"$zone\" date '+%I:%M %p|%a, %b %d'; done"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.consume(text)
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    pillRightClickAction: () => root.refresh()

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DankIcon {
                name: "public"
                color: Theme.primary
                font.pixelSize: Theme.iconSize - 6
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: root.pacificTime
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "public"
            color: Theme.primary
            font.pixelSize: Theme.iconSize - 4
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: clockPopout
            headerText: "World clock"
            detailsText: "Right click the bar pill to refresh"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                Repeater {
                    model: root.zones
                    Row {
                        width: parent.width
                        spacing: Theme.spacingM
                        StyledText {
                            width: parent.width * 0.35
                            text: modelData.city
                            color: Theme.primary
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        StyledText {
                            width: parent.width * 0.30
                            text: modelData.time
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        StyledText {
                            width: parent.width * 0.30
                            text: modelData.date
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 440
    popoutHeight: 290
}
