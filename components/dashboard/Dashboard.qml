pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../primitives"

Rectangle {
    id: root

    property bool monitoringActive: false
    property bool choosingAvatar: false

    readonly property var avatarPresets: [
        { icon: "person", label: "Classic" },
        { icon: "face", label: "Smile" },
        { icon: "smart_toy", label: "Robot" },
        { icon: "terminal", label: "Coder" },
        { icon: "rocket_launch", label: "Rocket" },
        { icon: "sports_esports", label: "Gamer" },
        { icon: "bolt", label: "Energy" },
        { icon: "coffee", label: "Coffee" },
        { icon: "palette", label: "Artist" },
        { icon: "pets", label: "Cat" },
        { icon: "headphones", label: "Music" },
        { icon: "local_fire_department", label: "Fire" }
    ]

    implicitWidth: Metrics.dashboardWidth
    implicitHeight: Metrics.dashboardHeight

    onMonitoringActiveChanged: {
        if (monitoringActive)
            SystemStatusService.acquireMonitoring();
        else
            SystemStatusService.releaseMonitoring();
    }

    Component.onDestruction: {
        if (monitoringActive)
            SystemStatusService.releaseMonitoring();
    }

    radius: Metrics.innerRadius
    color: Theme.surfaceColour

    component ThemeButton: Rectangle {
        id: themeBtn
        required property string iconName
        required property bool active
        signal triggered()

        width: 28
        height: 28
        radius: 14
        color: themeBtn.active ? Theme.accentColour : (btnMouse.containsMouse ? Theme.surfaceHover : "transparent")

        MaterialIcon {
            anchors.centerIn: parent
            iconName: themeBtn.iconName
            iconSize: 15
            iconColour: themeBtn.active ? (Theme.themeName === "light" ? "#ffffff" : Theme.surfaceColour) : Theme.textSecondary
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: themeBtn.triggered()
        }
    }

    component InfoRow: RowLayout {
        id: infoRowRoot
        required property string iconName
        required property color iconColour
        required property string label
        required property string value

        Layout.fillWidth: true
        spacing: Metrics.spacingSm

        MaterialIcon {
            iconName: infoRowRoot.iconName
            iconSize: 16
            iconColour: infoRowRoot.iconColour
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: infoRowRoot.label
            color: Theme.textSecondary
            font.family: Typography.fontFamily
            font.pixelSize: Typography.sizeCaption
            font.weight: Typography.weightMedium
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Text {
            text: infoRowRoot.value
            color: Theme.textPrimary
            font.family: Typography.fontFamily
            font.pixelSize: Typography.sizeCaption
            font.weight: Typography.weightBold
            elide: Text.ElideRight
            Layout.maximumWidth: 300
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Theme toggle — top-right corner
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 12
        anchors.rightMargin: 16
        spacing: 4
        z: 2

        ThemeButton {
            iconName: "light_mode"
            active: Theme.themeName === "light"
            onTriggered: Theme.themeName = "light"
        }

        ThemeButton {
            iconName: "dark_mode"
            active: Theme.themeName === "dark"
            onTriggered: Theme.themeName = "dark"
        }
    }

    // Settings Button — bottom-right corner
    Rectangle {
        id: settingsBtn
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 14
        anchors.rightMargin: 16
        width: 32
        height: 32
        radius: 16
        color: settingMouse.containsMouse ? Theme.surfaceHover : "transparent"
        z: 2

        Behavior on color { ColorAnimation { duration: 150 } }

        MaterialIcon {
            anchors.centerIn: parent
            iconName: "settings"
            iconSize: 18
            iconColour: settingMouse.containsMouse ? Theme.accentColour : Theme.textSecondary

            Behavior on iconColour { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: settingMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Quickshell.execDetached(["notify-send", "Titonium Settings", "Coming soon!"]);
            }
        }
    }

    // Centered Unified Block
    ColumnLayout {
        anchors.centerIn: parent
        width: 440
        spacing: 12

        // 1. Header Section (Avatar + User Info)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 5

            // Circular Avatar Container with Hover Edit (x1.5 Enlarge)
            Rectangle {
                id: avatarContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 120
                radius: 60
                color: Qt.alpha(Theme.accentColour, 0.14)
                border.width: 3
                border.color: avatarMouse.containsMouse || root.choosingAvatar ? Theme.accentColour : Theme.borderDefault
                clip: true

                Behavior on border.color { ColorAnimation { duration: Metrics.animFast } }

                // Avatar Icon (x1.5 Enlarge)
                MaterialIcon {
                    anchors.centerIn: parent
                    iconName: SettingsService.avatarIcon
                    iconSize: 74
                    iconColour: Theme.accentColour
                }

                // Hover Edit Overlay
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Qt.alpha("#000000", 0.60)
                    opacity: avatarMouse.containsMouse || root.choosingAvatar ? 1.0 : 0.0

                    Behavior on opacity { NumberAnimation { duration: Metrics.animFast } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            iconName: root.choosingAvatar ? "close" : "edit"
                            iconSize: 32
                            iconColour: "white"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.choosingAvatar ? "Close" : "Edit"
                            color: "white"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeBody
                            font.weight: Typography.weightBold
                        }
                    }
                }

                MouseArea {
                    id: avatarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.choosingAvatar = !root.choosingAvatar;
                    }
                }
            }

            // User@Hostname Heading
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: (SystemInfoService.user ? SystemInfoService.user : "cole") + "@" + (SystemInfoService.hostname ? SystemInfoService.hostname : "TitoX")
                color: Theme.textPrimary
                font.family: Typography.fontFamily
                font.pixelSize: Typography.sizeBody
                font.weight: Typography.weightBold
            }
        }

        // Horizontal Divider below user@domain
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.borderSubtle
        }

        // 2. Enclosed Grouped Inset Panel (System Monitoring Style)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.choosingAvatar ? avatarGridContainer.implicitHeight + 24 : 260
            radius: Metrics.radiusCard
            color: Theme.surfaceContainerColour
            border.width: 1
            border.color: Theme.borderSubtle

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: Metrics.animFast; easing.type: Easing.OutQuad }
            }

            // 2A. System Spec Info Rows Group
            ColumnLayout {
                id: systemInfoColumn
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                spacing: 5
                visible: !root.choosingAvatar

                InfoRow {
                    iconName: "memory"
                    iconColour: Theme.cpuIconColour
                    label: "CPU"
                    value: SystemInfoService.cpuModel || "Intel / AMD Processor"
                }

                InfoRow {
                    iconName: "speed"
                    iconColour: Theme.gpuIconColour
                    label: "GPU"
                    value: SystemInfoService.gpuModel || "Integrated / Discrete GPU"
                }

                InfoRow {
                    iconName: "memory_alt"
                    iconColour: Theme.memoryIconColour
                    label: "Memory"
                    value: SystemInfoService.memoryTotalText || "System Memory"
                }

                InfoRow {
                    iconName: "terminal"
                    iconColour: Theme.uploadIconColour
                    label: "Shell"
                    value: SystemInfoService.shell || "zsh"
                }

                InfoRow {
                    iconName: "developer_board"
                    iconColour: Theme.accentColour
                    label: "Kernel"
                    value: SystemInfoService.kernel || "Linux"
                }

                InfoRow {
                    iconName: "desktop_windows"
                    iconColour: Theme.downloadIconColour
                    label: "Resolution"
                    value: SystemInfoService.resolution || "1920x1080"
                }

                InfoRow {
                    iconName: "schedule"
                    iconColour: Theme.textSecondary
                    label: "Uptime"
                    value: SystemStatusService.formatUptime(SystemStatusService.uptimeSeconds)
                }

                InfoRow {
                    iconName: "inventory_2"
                    iconColour: Theme.textSecondary
                    label: "Packages"
                    value: SystemInfoService.packageCount > 0 ? (SystemInfoService.packageCount + " (pacman)") : "Arch Linux"
                }
            }

            // 2B. Avatar Preset Grid Picker (inside the same panel)
            ColumnLayout {
                id: avatarGridContainer
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8
                visible: root.choosingAvatar

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Select an avatar icon"
                    color: Theme.textSecondary
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.sizeCaption
                    font.weight: Typography.weightMedium
                }

                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 8

                    Repeater {
                        model: root.avatarPresets

                        delegate: Rectangle {
                            id: presetBtn
                            required property var modelData
                            required property int index

                            width: 96
                            height: 52
                            radius: Metrics.radiusMd
                            color: isSelected
                                ? Qt.alpha(Theme.accentColour, 0.22)
                                : (presetMouse.containsMouse ? Theme.surfaceHover : Qt.alpha(Theme.contentColour, 0.05))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Theme.accentColour : Theme.borderSubtle

                            readonly property bool isSelected: SettingsService.avatarIcon === modelData.icon

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    iconName: presetBtn.modelData.icon
                                    iconSize: 22
                                    iconColour: presetBtn.isSelected ? Theme.accentColour : Theme.textPrimary
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: presetBtn.modelData.label
                                    color: presetBtn.isSelected ? Theme.accentColour : Theme.textSecondary
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeMicro
                                    font.weight: presetBtn.isSelected ? Typography.weightBold : Typography.weightMedium
                                }
                            }

                            MouseArea {
                                id: presetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SettingsService.setAvatarIcon(presetBtn.modelData.icon);
                                    root.choosingAvatar = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
