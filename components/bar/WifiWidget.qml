pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    color: Theme.contentColour
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                Rectangle {
                    id: refreshButton

                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: refreshPointer.containsMouse
                        ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.12))
                        : "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent
                        iconName: "refresh"
                        iconSize: 18
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
            }

            ToggleSwitch {
                Layout.fillWidth: true
                label: "Wi-Fi"
                checked: NetworkService.enabled
                onTriggered: NetworkService.toggleEnabled()
            }

            Text {
                Layout.fillWidth: true
                visible: NetworkService.enabled && NetworkService.activeSsid.length > 0
                text: "Connected: " + NetworkService.activeSsid
                elide: Text.ElideRight
                color: Theme.onSurfaceVariantColour
                font.pixelSize: 11
            }

            // Loading indicator — fixed height so it never shifts the rows
            // below when it appears/disappears after each scan.
            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                verticalAlignment: Text.AlignVCenter
                text: NetworkService.enabled && NetworkService.loading
                    ? "Scanning…" : ""
                color: Theme.onSurfaceVariantColour
                font.pixelSize: 11
            }

            // Empty state — only after scan completes
            Text {
                visible: NetworkService.enabled
                    && !NetworkService.loading
                    && NetworkService.networks.count === 0
                text: "No networks found"
                color: Theme.onSurfaceVariantColour
                font.pixelSize: 11
            }

            Repeater {
                model: NetworkService.networks
                Rectangle {
                    id: networkRow

                    required property string ssid
                    required property int strength
                    required property bool active
                    required property string security
                    required property int index

                    visible: index < root.visibleCount
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 12
                    color: active
                        ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.accentColour, 0.16))
                        : pointer.containsMouse
                            ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.12))
                            : "transparent"
                    border.width: !active && pointer.containsMouse ? 1 : 0
                    border.color: Qt.alpha(Theme.contentColour, 0.25)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        MaterialIcon {
                            iconName: networkRow.strength >= 75 ? "wifi"
                                : networkRow.strength >= 45 ? "network_wifi_2_bar"
                                : "network_wifi_1_bar"
                            iconSize: 18
                            iconColour: networkRow.active
                                ? Theme.accentColour : Theme.contentColour
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: networkRow.ssid
                            color: Theme.contentColour
                            font.pixelSize: 11
                        }

                        Text {
                            text: networkRow.strength + "%"
                            color: Theme.onSurfaceVariantColour
                            font.pixelSize: 10
                        }

                        MaterialIcon {
                            visible: networkRow.security !== undefined && networkRow.security !== null && networkRow.security.length > 0
                            iconName: "lock"
                            iconSize: 14
                            iconColour: Theme.onSurfaceVariantColour
                        }

                        Text {
                            visible: networkRow.active ?? false
                            text: "Connected"
                            color: Theme.accentColour
                            font.pixelSize: 10
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: pointer

                        anchors.fill: parent
                        enabled: NetworkService.enabled && !networkRow.active
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (networkRow.ssid)
                                NetworkService.connect(networkRow.ssid);
                        }
                    }
                }
            }

            // Expand/collapse long network list
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 12
                visible: NetworkService.networks.count > 8
                color: showAllPointer.containsMouse
                    ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.12))
                    : "transparent"
                border.width: showAllPointer.containsMouse ? 1 : 0
                border.color: Qt.alpha(Theme.contentColour, 0.25)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialIcon {
                        iconName: root.visibleCount > 8 ? "expand_less" : "expand_more"
                        iconSize: 18
                        iconColour: Theme.contentColour
                    }

                    Text {
                        text: root.visibleCount > 8
                            ? "Show less"
                            : "Show all (" + (NetworkService.networks.count - 8) + " more)"
                        color: Theme.contentColour
                        font.pixelSize: 11
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

    Rectangle {
        id: triggerButton

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
