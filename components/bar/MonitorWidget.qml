pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"
import "../../services"
import "../primitives"
import "../popups"

Item {
    id: root

    property bool expanded: false
    readonly property Item inputRegion: dropdown.inputRegion

    property var processes: []

    onExpandedChanged: {
        if (expanded)
            SystemStatusService.acquireMonitoring();
        else
            SystemStatusService.releaseMonitoring();
    }

    Component.onDestruction: {
        if (expanded)
            SystemStatusService.releaseMonitoring();
    }

    implicitWidth: dropdown.implicitWidth
    implicitHeight: dropdown.implicitHeight

    Process {
        id: processQuery

        command: ["ps", "-eo", "pid=,comm=,%cpu=,%mem=", "--sort=-%cpu"]

        stdout: StdioCollector {
            id: processOutput
        }

        onExited: {
            const rows = processOutput.text.trim().split("\n").filter(line => line.trim()).slice(0, 10);
            root.processes = rows.map(line => {
                const fields = line.trim().split(/\s+/);
                return {
                    pid: fields[0],
                    name: fields[1],
                    cpu: fields[2],
                    memory: fields[3]
                };
            });
        }
    }

    Timer {
        id: processTimer

        interval: 3000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!processQuery.running)
                processQuery.running = true;
        }
    }

    BarDropdown {
        id: dropdown

        expanded: root.expanded
        collapsedWidth: Theme.widgetHeight
        surfaceWidth: 540
        surfaceHeight: 204

        Rectangle {
            anchors.fill: parent
            anchors.margins: 12
            radius: 16
            color: Theme.surfaceContainerColour

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 18

                Column {
                    Layout.preferredWidth: 190
                    Layout.fillHeight: true
                    spacing: 7

                    Text {
                        text: "System monitor"
                        color: Theme.contentColour
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    StatLine {
                        iconName: "memory"
                        iconColour: Theme.cpuIconColour
                        label: "CPU"
                        value: Math.round(SystemStatusService.cpuUsage) + "%  "
                            + Math.round(SystemStatusService.cpuTemperature) + "°C"
                    }

                    StatLine {
                        iconName: "developer_board"
                        iconColour: Theme.gpuIconColour
                        label: "GPU"
                        value: Math.round(SystemStatusService.gpuUsage) + "%  "
                            + Math.round(SystemStatusService.gpuTemperature) + "°C"
                    }

                    StatLine {
                        iconName: "memory_alt"
                        iconColour: Theme.downloadIconColour
                        label: "RAM"
                        value: Math.round(SystemStatusService.memoryUsage) + "%"
                    }

                    StatLine {
                        iconName: "speed"
                        iconColour: Theme.uploadIconColour
                        label: "Load"
                        value: SystemStatusService.loadAverage.toFixed(2)
                    }

                    StatLine {
                        iconName: "schedule"
                        iconColour: Theme.onSurfaceVariantColour
                        label: "Uptime"
                        value: SystemStatusService.formatUptime(SystemStatusService.uptimeSeconds)
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Qt.alpha(Theme.onSurfaceVariantColour, 0.16)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        ProcessHeader { text: "PID"; Layout.preferredWidth: 46 }
                        ProcessHeader { text: "Process"; Layout.fillWidth: true }
                        ProcessHeader { text: "CPU"; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                        ProcessHeader { text: "MEM"; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                    }

                    Repeater {
                        model: root.processes

                        RowLayout {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 13
                            spacing: 6

                            ProcessValue { text: modelData.pid; Layout.preferredWidth: 46 }
                            ProcessValue {
                                text: modelData.name
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            ProcessValue {
                                text: modelData.cpu + "%"
                                Layout.preferredWidth: 42
                                horizontalAlignment: Text.AlignRight
                            }
                            ProcessValue {
                                text: modelData.memory + "%"
                                Layout.preferredWidth: 42
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: trigger

        anchors.top: parent.top
        anchors.right: parent.right
        implicitWidth: Theme.widgetHeight
        implicitHeight: Theme.widgetHeight
        radius: height / 2
        color: triggerPointer.containsMouse
            ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.08))
            : "transparent"

        MaterialIcon {
            anchors.centerIn: parent
            iconName: "monitor_heart"
            iconSize: 19
            iconColour: Theme.contentColour
        }

        MouseArea {
            id: triggerPointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

        Accessible.role: Accessible.Button
        Accessible.name: "System monitor"
    }

    component StatLine: Row {
        required property string iconName
        required property color iconColour
        required property string label
        required property string value

        spacing: 6

        MaterialIcon {
            iconName: parent.iconName
            iconSize: 15
            iconColour: parent.iconColour
        }

        Text {
            width: 48
            text: parent.label
            color: Theme.onSurfaceVariantColour
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        Text {
            width: 78
            text: parent.value
            color: Theme.contentColour
            font.family: Theme.fontFamily
            font.pixelSize: 11
            horizontalAlignment: Text.AlignRight
        }
    }

    component ProcessHeader: Text {
        color: Theme.onSurfaceVariantColour
        font.family: Theme.fontFamily
        font.pixelSize: 9
        font.weight: Font.DemiBold
    }

    component ProcessValue: Text {
        color: Theme.contentColour
        font.family: Theme.fontFamily
        font.pixelSize: 9
    }
}
