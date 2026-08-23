pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../config"
import "../../services"
import "../primitives"
import "../popups"

Item {
    id: root

    property bool expanded: false
    readonly property Item inputRegion: dropdown.inputRegion
    implicitWidth: dropdown.implicitWidth
    implicitHeight: dropdown.implicitHeight

    BarDropdown {
        id: dropdown

        expanded: root.expanded
        collapsedWidth: Theme.widgetHeight
        surfaceWidth: 340
        surfaceHeight: content.implicitHeight + 24

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 8

            SectionTitle { text: "Output device" }

            Repeater {
                model: AudioService.sinks

                DeviceButton {
                    id: sinkBtn
                    required property PwNode modelData
                    readonly property bool hasNode: sinkBtn.modelData !== null && sinkBtn.modelData !== undefined
                    Layout.fillWidth: true
                    label: sinkBtn.hasNode ? (sinkBtn.modelData.description || sinkBtn.modelData.name || "Default Output") : "Default Output"
                    checked: sinkBtn.hasNode && AudioService.sink !== null && AudioService.sink.id === sinkBtn.modelData.id
                    onTriggered: {
                        if (sinkBtn.hasNode)
                            AudioService.setSink(sinkBtn.modelData);
                    }
                }
            }

            SectionTitle {
                Layout.topMargin: 6
                text: "Input device"
            }

            Repeater {
                model: AudioService.sources

                DeviceButton {
                    id: srcBtn
                    required property PwNode modelData
                    readonly property bool hasNode: srcBtn.modelData !== null && srcBtn.modelData !== undefined
                    Layout.fillWidth: true
                    label: srcBtn.hasNode ? (srcBtn.modelData.description || srcBtn.modelData.name || "Default Input") : "Default Input"
                    checked: srcBtn.hasNode && AudioService.source !== null && AudioService.source.id === srcBtn.modelData.id
                    onTriggered: {
                        if (srcBtn.hasNode)
                            AudioService.setSource(srcBtn.modelData);
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6

                SectionTitle {
                    Layout.fillWidth: true
                    text: AudioService.muted ? "Volume (Muted)"
                        : "Volume (" + Math.round(AudioService.volume * 100) + "%)"
                }

                IconButton {
                    iconName: AudioService.muted ? "volume_off" : "volume_up"
                    onTriggered: AudioService.toggleMuted()
                }
            }

            Rectangle {
                id: volumeSlider

                Layout.fillWidth: true
                Layout.preferredHeight: 20
                color: "transparent"

                readonly property real trackX: 8
                readonly property real trackWidth: width - 16

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: volumeSlider.trackX
                    width: volumeSlider.trackWidth
                    height: 6
                    radius: 3
                    color: Theme.surfaceContainerColour
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: volumeSlider.trackX
                    width: volumeSlider.trackWidth * AudioService.volume
                    height: 6
                    radius: 3
                    color: Theme.accentColour
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: volumeSlider.trackX + volumeSlider.trackWidth * AudioService.volume
                        - width / 2
                    width: 16
                    height: 16
                    radius: 8
                    color: Theme.accentColour
                    border.width: 2
                    border.color: Theme.surfaceColour
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function setFromX(x: real): void {
                        const t = (x - volumeSlider.trackX) / volumeSlider.trackWidth;
                        AudioService.setVolume(Math.max(0, Math.min(1, t)));
                    }
                    onPressed: setFromX(mouseX)
                    onPositionChanged: if (pressed) setFromX(mouseX)
                }
            }
        }
    }

    IconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        iconName: (!AudioService.sink || AudioService.muted) ? "volume_off"
            : AudioService.volume < 0.34 ? "volume_down" : "volume_up"
        accessibleName: "Audio"
        onTriggered: root.expanded = !root.expanded
    }

    component SectionTitle: Text {
        color: Theme.contentColour
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.Medium
    }

    component DeviceButton: Rectangle {
        id: device

        required property string label
        property bool checked: false
        signal triggered

        implicitHeight: 34
        radius: 17
        color: checked
            ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour,
                pointer.containsMouse ? 0.18 : 0.12))
            : pointer.containsMouse
                ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.10))
                : "transparent"
        border.width: pointer.containsMouse ? 1 : 0
        border.color: Qt.alpha(Theme.contentColour, 0.25)

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                iconName: device.checked ? "radio_button_checked" : "radio_button_unchecked"
                iconSize: 17
                iconColour: Theme.contentColour
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 35
                elide: Text.ElideRight
                text: device.label
                color: Theme.contentColour
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: device.triggered()
        }
    }
}
