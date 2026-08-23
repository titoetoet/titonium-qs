pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../primitives"
import "../popups"

Item {
    id: root

    property bool expanded: false
    readonly property Item inputRegion: inputArea

    readonly property int popupWidth: Metrics.clockPopupWidth
    readonly property int popupHeight: Math.min(Metrics.clockPopupHeight, Math.max(300, Math.floor((Quickshell.screens[0]?.height || 1080) * 0.40)))
    readonly property int joinDepth: Metrics.innerRadius
    readonly property int panelTop: Metrics.barHeight
        - (Metrics.barHeight - Metrics.widgetHeight) / 2
        + Metrics.borderThickness

    implicitWidth: trigger.implicitWidth
    implicitHeight: Metrics.widgetHeight

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property var now: clock.date
    readonly property int hours: now.getHours()
    readonly property int minutes: now.getMinutes()
    readonly property int seconds: now.getSeconds()

    readonly property real hourAngle: ((hours % 12) + minutes / 60.0 + seconds / 3600.0) * 30.0
    readonly property real minuteAngle: (minutes + seconds / 60.0) * 6.0
    readonly property real secondAngle: seconds * 6.0

    readonly property string timezoneName: {
        try {
            return Intl.DateTimeFormat().resolvedOptions().timeZone || "Asia/Ho_Chi_Minh";
        } catch (e) {
            return "Asia/Ho_Chi_Minh";
        }
    }

    readonly property string timezoneOffset: {
        const off = -now.getTimezoneOffset() / 60;
        const sign = off >= 0 ? "+" : "-";
        const absOff = Math.abs(off);
        const h = Math.floor(absOff);
        const m = Math.floor((absOff - h) * 60);
        return "UTC" + sign + (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
    }

    Item {
        id: inputArea

        anchors.top: parent.top
        anchors.right: parent.right
        width: root.expanded ? root.popupWidth : trigger.implicitWidth
        height: root.expanded ? root.panelTop + panel.height : Theme.widgetHeight
    }

    PopupPanel {
        id: panel

        open: root.expanded
        closedTransformOrigin: Item.TopRight
        anchors.right: parent.right
        y: root.panelTop
        width: root.popupWidth
        height: root.joinDepth + root.popupHeight

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // 1. Luxury Minimalist Analog Clock Face
            Item {
                id: clockFaceContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 164
                Layout.preferredHeight: 164

                Rectangle {
                    id: dial
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.surfaceContainerColour
                    border.width: 0

                    // 12 Hour Markers
                    Repeater {
                        model: 12

                        delegate: Item {
                            id: markerItem
                            required property int index

                            anchors.fill: parent
                            rotation: markerItem.index * 30

                            Rectangle {
                                anchors.top: parent.top
                                anchors.topMargin: (markerItem.index % 3 === 0) ? 6 : 8
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: (markerItem.index % 3 === 0) ? 2.5 : 1.5
                                height: (markerItem.index % 3 === 0) ? 8 : 4
                                radius: width / 2
                                color: (markerItem.index % 3 === 0)
                                    ? Theme.contentColour
                                    : Theme.onSurfaceVariantColour
                                opacity: (markerItem.index % 3 === 0) ? 0.7 : 0.35
                            }
                        }
                    }

                    // Hour Hand
                    Item {
                        anchors.centerIn: parent
                        width: 4
                        height: 48
                        rotation: root.hourAngle
                        transformOrigin: Item.Center

                        Rectangle {
                            anchors.bottom: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 3.5
                            height: 38
                            radius: 1.75
                            color: Theme.contentColour
                        }
                    }

                    // Minute Hand
                    Item {
                        anchors.centerIn: parent
                        width: 3
                        height: 68
                        rotation: root.minuteAngle
                        transformOrigin: Item.Center

                        Rectangle {
                            anchors.bottom: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 2.5
                            height: 56
                            radius: 1.25
                            color: Theme.onSurfaceVariantColour
                        }
                    }

                    // Second Hand (Accent Color)
                    Item {
                        anchors.centerIn: parent
                        width: 2
                        height: 82
                        rotation: root.secondAngle
                        transformOrigin: Item.Center

                        Rectangle {
                            anchors.bottom: parent.verticalCenter
                            anchors.bottomMargin: -12
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 1.5
                            height: 74
                            radius: 0.75
                            color: Theme.accentColour
                        }

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    // Center Cap
                    Rectangle {
                        anchors.centerIn: parent
                        width: 7
                        height: 7
                        radius: 3.5
                        color: Theme.accentColour

                        Rectangle {
                            anchors.centerIn: parent
                            width: 2.5
                            height: 2.5
                            radius: 1.25
                            color: Theme.surfaceColour
                        }
                    }
                }
            }

            // 2. Digital Time & Date Information
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Text {
                        text: Qt.formatDateTime(clock.date, "hh:mm:ss")
                        color: Theme.contentColour
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "AP")
                        color: Theme.onSurfaceVariantColour
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM, yyyy")
                    color: Theme.onSurfaceVariantColour
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Normal
                }
            }

            // 3. Local Timezone & Region Information Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 12
                color: Theme.surfaceContainerColour
                border.width: 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        radius: 16
                        color: Qt.alpha(Theme.contentColour, 0.08)

                        MaterialIcon {
                            anchors.centerIn: parent
                            iconName: "schedule"
                            iconSize: 18
                            iconColour: Theme.onSurfaceVariantColour
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("clock.timezone_title")
                            color: Theme.textPrimary
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeBodySm
                            font.weight: Typography.weightMedium
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.timezoneOffset + " • " + I18n.t("clock.timezone_subtitle")
                            color: Theme.textSecondary
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeMicro
                            font.weight: Typography.weightNormal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // TopBar Clock Button
    Rectangle {
        id: trigger

        anchors.top: parent.top
        anchors.right: parent.right
        implicitHeight: Theme.widgetHeight
        implicitWidth: timeLabel.implicitWidth + 16
        radius: height / 2

        color: pointer.containsMouse
            ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.10))
            : "transparent"

        Text {
            id: timeLabel
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "h:mm AP")
            color: Theme.contentColour
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            renderType: Theme.renderType
        }

        MouseArea {
            id: pointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

        Accessible.role: Accessible.Button
        Accessible.name: "Clock & Timezone"
    }
}
