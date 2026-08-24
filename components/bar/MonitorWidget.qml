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

    property ListModel processes: ListModel {}

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
            const rows = processOutput.text.trim().split("\n").filter(line => line.trim()).slice(0, 7);
            for (let i = 0; i < rows.length; i++) {
                const fields = rows[i].trim().split(/\s+/);
                const item = {
                    pid: fields[0] || "",
                    name: fields[1] || "",
                    cpu: fields[2] || "0",
                    memory: fields[3] || "0"
                };
                if (i < root.processes.count) {
                    root.processes.set(i, item);
                } else {
                    root.processes.append(item);
                }
            }
            while (root.processes.count > rows.length) {
                root.processes.remove(root.processes.count - 1);
            }
        }
    }

    Timer {
        id: processTimer

        interval: 2000
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
        surfaceWidth: 600
        surfaceHeight: 465

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ── 1. Modern Header: System Identity & Live Pulse ───────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // Avatar / OS Icon (Enlarged 48x48 with dual-ring glow)
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: Qt.alpha(Theme.accentColour, 0.16)
                    border.width: 1.5
                    border.color: Qt.alpha(Theme.accentColour, 0.45)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 22
                        color: Qt.alpha("#000000", 0.20)
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        iconName: SettingsService.avatarIcon || "terminal"
                        iconSize: 26
                        iconColour: Theme.accentColour
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    RowLayout {
                        spacing: 8

                        // Prominent Dual-tone User@Hostname Highlight
                        RowLayout {
                            spacing: 0
                            Text {
                                text: (SystemInfoService.user || "cole")
                                color: "#8be9fd" // Dracula Cyan
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeTitle
                                font.weight: Typography.weightBold
                            }
                            Text {
                                text: "@" + (SystemInfoService.hostname || "TitoX")
                                color: "#ff79c6" // Dracula Pink
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeTitle
                                font.weight: Typography.weightBold
                            }
                        }

                        // Arch / OS Badge
                        Rectangle {
                            implicitHeight: 22
                            implicitWidth: osText.implicitWidth + 14
                            radius: 6
                            color: Qt.alpha("#50fa7b", 0.15)
                            border.width: 1
                            border.color: Qt.alpha("#50fa7b", 0.35)

                            Text {
                                id: osText
                                anchors.centerIn: parent
                                text: SystemInfoService.osName || "Arch Linux"
                                color: "#50fa7b" // Dracula Green
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeMicro
                                font.weight: Typography.weightBold
                            }
                        }
                    }

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "Linux " + (SystemInfoService.kernel || "Kernel")
                            color: Qt.alpha(Theme.contentColour, 0.60)
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeCaption
                            font.weight: Typography.weightMedium
                        }
                        Text {
                            text: "·"
                            color: Qt.alpha(Theme.contentColour, 0.30)
                            font.pixelSize: Typography.sizeCaption
                        }
                        Text {
                            text: "Uptime " + SystemStatusService.formatUptime(SystemStatusService.uptimeSeconds)
                            color: Qt.alpha(Theme.contentColour, 0.60)
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeCaption
                            font.weight: Typography.weightMedium
                        }
                    }
                }

                // Live Monitoring Beacon
                Rectangle {
                    implicitHeight: 26
                    implicitWidth: liveRow.implicitWidth + 16
                    radius: 13
                    color: Qt.alpha("#50fa7b", 0.12)
                    border.width: 1
                    border.color: Qt.alpha("#50fa7b", 0.30)

                    RowLayout {
                        id: liveRow
                        anchors.centerIn: parent
                        spacing: 6
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: "#50fa7b" // Dracula Green pulse
                        }
                        Text {
                            text: "LIVE"
                            color: "#50fa7b"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeMicro
                            font.weight: Typography.weightBold
                        }
                    }
                }
            }

            // ── 2. Live Performance Gauges (3 Cards) ─────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // ── CPU Card ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 106
                    radius: 10
                    color: Qt.alpha(Theme.contentColour, 0.04)
                    border.width: 1
                    border.color: Qt.alpha(Theme.contentColour, 0.08)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialIcon {
                                 iconName: "memory"
                                 iconSize: 16
                                 iconColour: "#8be9fd" // Dracula Cyan
                            }
                            Text {
                                 text: "CPU"
                                 color: Qt.alpha(Theme.contentColour, 0.75)
                                 font.family: Typography.fontFamily
                                 font.pixelSize: Typography.sizeBody
                                 font.weight: Typography.weightDemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                 text: Math.round(SystemStatusService.cpuUsage) + "%"
                                 color: "#8be9fd"
                                 font.family: Typography.fontFamily
                                 font.pixelSize: Typography.sizeTitleSm
                                 font.weight: Typography.weightBold
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: SystemInfoService.cpuModel || "Processor"
                            color: Qt.alpha(Theme.contentColour, 0.55)
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeCaption
                            elide: Text.ElideRight
                        }

                        Item { Layout.fillHeight: true }

                        // Progress Bar
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 5
                            radius: 2.5
                            color: Qt.alpha(Theme.contentColour, 0.10)

                            Rectangle {
                                width: Math.max(4, parent.width * (Math.min(100, SystemStatusService.cpuUsage) / 100))
                                height: parent.height
                                radius: 2.5
                                color: "#8be9fd"
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: SystemStatusService.cpuTemperature > 0 ? (Math.round(SystemStatusService.cpuTemperature) + "°C") : "Normal"
                                color: Qt.alpha(Theme.contentColour, 0.50)
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeMicro
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "Load: " + SystemStatusService.loadAverage.toFixed(2)
                                color: Qt.alpha(Theme.contentColour, 0.50)
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeMicro
                            }
                        }
                    }
                }

                // ── RAM / Memory Card ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 106
                    radius: 10
                    color: Qt.alpha(Theme.contentColour, 0.04)
                    border.width: 1
                    border.color: Qt.alpha(Theme.contentColour, 0.08)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialIcon {
                                iconName: "memory_alt"
                                iconSize: 16
                                iconColour: "#bd93f9" // Dracula Purple
                            }
                            Text {
                                text: "RAM"
                                color: Qt.alpha(Theme.contentColour, 0.75)
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeBody
                                font.weight: Typography.weightDemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: Math.round(SystemStatusService.memoryUsage) + "%"
                                color: "#bd93f9"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeTitleSm
                                font.weight: Typography.weightBold
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Total " + (SystemInfoService.memoryTotalText || "System Memory")
                            color: Qt.alpha(Theme.contentColour, 0.55)
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeCaption
                            elide: Text.ElideRight
                        }

                        Item { Layout.fillHeight: true }

                        // Progress Bar
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 5
                            radius: 2.5
                            color: Qt.alpha(Theme.contentColour, 0.10)

                            Rectangle {
                                width: Math.max(4, parent.width * (Math.min(100, SystemStatusService.memoryUsage) / 100))
                                height: parent.height
                                radius: 2.5
                                color: "#bd93f9"
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Available: " + Math.round(100 - SystemStatusService.memoryUsage) + "%"
                                color: Qt.alpha(Theme.contentColour, 0.50)
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeMicro
                            }
                        }
                    }
                }

                // ── GPU Card ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 106
                    radius: 10
                    color: Qt.alpha(Theme.contentColour, 0.04)
                    border.width: 1
                    border.color: Qt.alpha(Theme.contentColour, 0.08)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialIcon {
                                iconName: "developer_board"
                                iconSize: 16
                                iconColour: "#ffb86c" // Dracula Orange
                            }
                            Text {
                                text: "GPU"
                                color: Qt.alpha(Theme.contentColour, 0.75)
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeBody
                                font.weight: Typography.weightDemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: Math.round(SystemStatusService.gpuUsage) + "%"
                                color: "#ffb86c"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeTitleSm
                                font.weight: Typography.weightBold
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: SystemInfoService.gpuModel || "Graphics Device"
                            color: Qt.alpha(Theme.contentColour, 0.55)
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeCaption
                            elide: Text.ElideRight
                        }

                        Item { Layout.fillHeight: true }

                        // Progress Bar
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 5
                            radius: 2.5
                            color: Qt.alpha(Theme.contentColour, 0.10)

                            Rectangle {
                                width: Math.max(4, parent.width * (Math.min(100, SystemStatusService.gpuUsage) / 100))
                                height: parent.height
                                radius: 2.5
                                color: "#ffb86c"
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: SystemStatusService.gpuTemperature > 0 ? (Math.round(SystemStatusService.gpuTemperature) + "°C") : "Direct"
                                color: Qt.alpha(Theme.contentColour, 0.50)
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeMicro
                            }
                        }
                    }
                }
            }

            // ── 3. Environment & Specs Quick Badges ──────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                SpecBadge {
                    iconName: "desktop_windows"
                    label: "Display"
                    value: SystemInfoService.resolution || "1920x1080"
                    badgeColor: "#50fa7b"
                }

                SpecBadge {
                    iconName: "terminal"
                    label: "Shell"
                    value: SystemInfoService.shell || "zsh"
                    badgeColor: "#ff79c6"
                }

                SpecBadge {
                    iconName: "widgets"
                    label: "WM"
                    value: "Hyprland (Wayland)"
                    badgeColor: "#bd93f9"
                }

                SpecBadge {
                    iconName: "inventory_2"
                    label: "Packages"
                    value: SystemInfoService.packageCount > 0 ? (SystemInfoService.packageCount + " pkgs") : "pacman"
                    badgeColor: "#f1fa8c"
                }
            }

            // Soft Hairline Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.alpha(Theme.contentColour, 0.08)
            }

            // ── 4. Modern Task Manager / Top Processes Table ─────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                // Table Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    spacing: 12

                    Text {
                        text: "TOP PROCESSES"
                        color: Qt.alpha(Theme.contentColour, 0.50)
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeMicro
                        font.weight: Typography.weightDemiBold
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "PID"
                        color: Qt.alpha(Theme.contentColour, 0.50)
                        font.family: Typography.monoFontFamily
                        font.pixelSize: Typography.sizeMicro
                        font.weight: Typography.weightDemiBold
                        Layout.preferredWidth: 60
                        Layout.minimumWidth: 60
                        Layout.maximumWidth: 60
                        horizontalAlignment: Text.AlignRight
                    }

                    Text {
                        text: "CPU"
                        color: Qt.alpha(Theme.contentColour, 0.50)
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeMicro
                        font.weight: Typography.weightDemiBold
                        Layout.preferredWidth: 55
                        Layout.minimumWidth: 55
                        Layout.maximumWidth: 55
                        horizontalAlignment: Text.AlignRight
                    }

                    Text {
                        text: "MEM"
                        color: Qt.alpha(Theme.contentColour, 0.50)
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeMicro
                        font.weight: Typography.weightDemiBold
                        Layout.preferredWidth: 55
                        Layout.minimumWidth: 55
                        Layout.maximumWidth: 55
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Process Rows
                Repeater {
                    model: root.processes

                    Rectangle {
                        id: pRow
                        required property string pid
                        required property string name
                        required property string cpu
                        required property string memory
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: 5
                        color: pMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.07) : "transparent"

                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 12

                            // Process dot & Name
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: Theme.accentColour
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: pRow.name
                                    color: Theme.contentColour
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeBodySm
                                    font.weight: Typography.weightMedium
                                    elide: Text.ElideRight
                                }
                            }

                            // PID (Căn phải thẳng đứng tuyệt đối dưới chữ PID)
                            Text {
                                text: pRow.pid
                                color: Qt.alpha(Theme.contentColour, 0.50)
                                font.family: Typography.monoFontFamily
                                font.pixelSize: Typography.sizeMicro
                                Layout.preferredWidth: 60
                                Layout.minimumWidth: 60
                                Layout.maximumWidth: 60
                                horizontalAlignment: Text.AlignRight
                            }

                            // CPU % Badge
                            Text {
                                text: (pRow.cpu || "0") + "%"
                                color: "#8be9fd"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeBodySm
                                font.weight: Typography.weightDemiBold
                                Layout.preferredWidth: 55
                                Layout.minimumWidth: 55
                                Layout.maximumWidth: 55
                                horizontalAlignment: Text.AlignRight
                            }

                            // MEM % Badge
                            Text {
                                text: (pRow.memory || "0") + "%"
                                color: "#bd93f9"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeBodySm
                                font.weight: Typography.weightDemiBold
                                Layout.preferredWidth: 55
                                Layout.minimumWidth: 55
                                Layout.maximumWidth: 55
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        MouseArea {
                            id: pMouse
                            anchors.fill: parent
                            hoverEnabled: true
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
        color: root.expanded
            ? Qt.alpha(Theme.contentColour, 0.14)
            : triggerPointer.containsMouse
                ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.08))
                : "transparent"

        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

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

    component SpecBadge: Rectangle {
        id: badgeRoot
        required property string iconName
        required property string label
        required property string value
        required property color badgeColor

        Layout.fillWidth: true
        implicitHeight: 26
        radius: 6
        color: Qt.alpha(Theme.contentColour, 0.03)
        border.width: 1
        border.color: Qt.alpha(Theme.contentColour, 0.06)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 5

            MaterialIcon {
                iconName: badgeRoot.iconName
                iconSize: 13
                iconColour: badgeRoot.badgeColor
            }

            Text {
                text: badgeRoot.label + ":"
                color: Qt.alpha(Theme.contentColour, 0.40)
                font.family: Typography.fontFamily
                font.pixelSize: 10
            }

            Text {
                Layout.fillWidth: true
                text: badgeRoot.value
                color: Theme.contentColour
                font.family: Typography.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }
}
