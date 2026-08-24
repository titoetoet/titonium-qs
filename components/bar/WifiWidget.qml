pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../config"
import "../../services"
import "../primitives"
import "../popups"

Item {
    id: root

    property bool expanded: false
    property int visibleCount: 8
    readonly property Item inputRegion: dropdown.inputRegion

    onExpandedChanged: NetworkService.polling = expanded

    implicitWidth: dropdown.implicitWidth
    implicitHeight: dropdown.implicitHeight

    Accessible.role: Accessible.Button
    Accessible.name: "Wi-Fi"

    BarDropdown {
        id: dropdown

        expanded: root.expanded
        collapsedWidth: Theme.widgetHeight
        surfaceWidth: 320
        surfaceHeight: content.implicitHeight + 24

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 12

            // ── 1. Master Control Row (Clean Single Surface) ─────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialIcon {
                    iconName: !NetworkService.enabled ? "wifi_off"
                        : NetworkService.activeSsid ? "wifi" : "wifi_find"
                    iconSize: 19
                    iconColour: NetworkService.enabled
                        ? (NetworkService.activeSsid ? Theme.contentColour : Theme.onSurfaceVariantColour)
                        : Theme.onSurfaceVariantColour
                }

                // Label & Subtitle
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Wi-Fi"
                        color: Theme.contentColour
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeTitleSm
                        font.weight: Typography.weightBold
                    }

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: !NetworkService.enabled ? "Off"
                            : NetworkService.activeSsid ? NetworkService.activeSsid : "Not connected"
                        color: Qt.alpha(Theme.contentColour, 0.65)
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeCaption
                    }
                }

                // Refresh Scan Button
                Rectangle {
                    id: refreshButton
                    visible: NetworkService.enabled
                    width: 26
                    height: 26
                    radius: 13
                    color: refreshPointer.containsMouse ? Qt.alpha(Theme.contentColour, 0.14) : "transparent"

                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        iconName: "refresh"
                        iconSize: 15
                        iconColour: Theme.onSurfaceVariantColour

                        RotationAnimator on rotation {
                            running: NetworkService.loading
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }

                    MouseArea {
                        id: refreshPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.refresh(true)
                    }
                }

                // Master Cupertino Toggle Pill
                Rectangle {
                    id: togglePill
                    width: 38
                    height: 22
                    radius: 11
                    color: NetworkService.enabled ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.20)

                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                    Rectangle {
                        id: toggleKnob
                        x: NetworkService.enabled ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: toggleMouse.pressed ? 19 : 16
                        height: 16
                        radius: 8
                        color: "#ffffff"

                        Behavior on x {
                            NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
                        }
                        Behavior on width {
                            NumberAnimation { duration: Metrics.animFast; easing.type: Easing.OutQuad }
                        }
                    }

                    MouseArea {
                        id: toggleMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.toggleEnabled()
                    }
                }
            }

            // Soft Refractive Divider Line
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                height: 1
                visible: NetworkService.enabled
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.alpha(Theme.contentColour, 0.08) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // ── 2. Available Networks List (Fluid Pills) ───
            ColumnLayout {
                Layout.fillWidth: true
                visible: NetworkService.enabled
                spacing: 3

                // Header row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    Layout.bottomMargin: 2

                    Text {
                        Layout.fillWidth: true
                        text: "Known Networks"
                        color: Qt.alpha(Theme.contentColour, 0.50)
                        font.family: Typography.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Text {
                        visible: NetworkService.loading
                        text: "Scanning…"
                        color: Theme.accentColour
                        font.family: Typography.fontFamily
                        font.pixelSize: 10
                    }
                }

                // Empty state
                Text {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    visible: !NetworkService.loading && NetworkService.networks.count === 0
                    text: "No networks found"
                    color: Theme.onSurfaceVariantColour
                    font.family: Typography.fontFamily
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }

                // Network rows
                Repeater {
                    model: NetworkService.networks

                    delegate: Rectangle {
                        id: networkRow

                        required property string ssid
                        required property int strength
                        required property bool active
                        required property string security
                        required property int index

                        visible: index < root.visibleCount
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 10
                        color: active
                            ? Qt.alpha(Theme.contentColour, 0.14)
                            : (pointer.containsMouse ? Qt.alpha(Theme.contentColour, 0.07) : "transparent")

                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            MaterialIcon {
                                iconName: networkRow.strength >= 75 ? "wifi"
                                    : networkRow.strength >= 45 ? "network_wifi_2_bar"
                                    : "network_wifi_1_bar"
                                iconSize: 17
                                iconColour: networkRow.active ? Theme.contentColour : Qt.alpha(Theme.contentColour, 0.55)
                            }

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: networkRow.ssid
                                color: Theme.contentColour
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeBody
                                font.weight: networkRow.active ? Typography.weightMedium : Typography.weightNormal
                            }

                            MaterialIcon {
                                visible: networkRow.security !== undefined && networkRow.security !== null && networkRow.security.length > 0
                                iconName: "lock"
                                iconSize: 13
                                iconColour: Qt.alpha(Theme.contentColour, 0.40)
                            }

                            Text {
                                text: networkRow.strength + "%"
                                color: Qt.alpha(Theme.contentColour, 0.50)
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeMicro
                            }

                            MaterialIcon {
                                visible: networkRow.active ?? false
                                iconName: "check"
                                iconSize: 16
                                iconColour: Theme.contentColour
                            }
                        }

                        MouseArea {
                            id: pointer
                            anchors.fill: parent
                            enabled: !networkRow.active
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (networkRow.ssid)
                                    NetworkService.connect(networkRow.ssid);
                            }
                        }
                    }
                }

                // Show all / Show less button
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 8
                    visible: NetworkService.networks.count > 8
                    color: showAllPointer.containsMouse
                        ? Qt.alpha(Theme.contentColour, 0.10)
                        : "transparent"

                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialIcon {
                            iconName: root.visibleCount > 8 ? "expand_less" : "expand_more"
                            iconSize: 16
                            iconColour: Theme.onSurfaceVariantColour
                        }

                        Text {
                            text: root.visibleCount > 8
                                ? "Show less"
                                : "Show all (" + (NetworkService.networks.count - 8) + " more)"
                            color: Theme.onSurfaceVariantColour
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeCaption
                        }
                    }

                    MouseArea {
                        id: showAllPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visibleCount = root.visibleCount > 8
                            ? 8 : NetworkService.networks.count
                    }
                }
            }
        }
    }

    Rectangle {
        id: triggerButton

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
            iconName: !NetworkService.enabled ? "wifi_off"
                : NetworkService.activeSsid ? "wifi" : "wifi_find"
            iconSize: 19
            iconColour: NetworkService.enabled ? Theme.contentColour : Theme.onSurfaceVariantColour
        }

        MouseArea {
            id: triggerPointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                // Only refresh when opening the dropdown (not on close)
                if (!root.expanded)
                    NetworkService.refresh(true);
                root.expanded = !root.expanded;
            }
        }
    }
}
