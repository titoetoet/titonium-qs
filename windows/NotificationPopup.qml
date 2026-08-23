pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../config"
import "../services"
import "../components/primitives"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: popupWindow

        required property ShellScreen modelData

        readonly property int shadowPad: Metrics.popupShadowRange

        screen: modelData
        anchors.top: true
        anchors.right: true
        margins.top: Metrics.barHeight + Metrics.borderThickness + 8 - shadowPad
        margins.right: Metrics.borderThickness + 8 - shadowPad
        implicitWidth: 350 + 2 * shadowPad
        implicitHeight: toastColumn.implicitHeight + 2 * shadowPad
        color: "transparent"
        visible: activeToasts.length > 0

        WlrLayershell.namespace: "titonium-notification-popup"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        mask: Region { item: toastColumn }

        property var activeToasts: []
        readonly property int maxVisibleToasts: 4
        readonly property int toastTimeout: 5000

        Connections {
            target: NotificationService

            function onNotificationReceived(notification) {
                const list = [...popupWindow.activeToasts];
                const exists = list.some(n => n && n.id === notification.id);
                if (!exists) {
                    list.unshift(notification);
                    if (list.length > popupWindow.maxVisibleToasts) {
                        list.pop();
                    }
                    popupWindow.activeToasts = list;
                }
            }
        }

        function removeToast(notifId, dismissNotif) {
            const list = [...popupWindow.activeToasts];
            const idx = list.findIndex(n => n && n.id === notifId);
            if (idx !== -1) {
                const notif = list[idx];
                if (dismissNotif && notif) {
                    NotificationService.dismiss(notif);
                }
                list.splice(idx, 1);
                popupWindow.activeToasts = list;
            }
        }

        Column {
            id: toastColumn
            x: popupWindow.shadowPad
            y: popupWindow.shadowPad
            width: 350
            spacing: 8

            Repeater {
                model: popupWindow.activeToasts

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    required property int index

                    width: 350
                    height: content.implicitHeight + 20
                    radius: Metrics.radiusCard
                    color: Theme.surfaceColour
                    border.width: 1
                    border.color: Theme.borderSubtle
                    clip: true
                    antialiasing: true

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        blurMax: Metrics.popupShadowRange
                        shadowBlur: 3
                        shadowVerticalOffset: 0
                        shadowColor: Theme.popupShadowColour
                    }

                    Timer {
                        interval: popupWindow.toastTimeout
                        running: true
                        onTriggered: {
                            if (card.modelData)
                                popupWindow.removeToast(card.modelData.id, false);
                        }
                    }

                    ColumnLayout {
                        id: content
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        anchors.topMargin: 10
                        spacing: 4

                        // Header: App Icon + App Name + Dismiss Button
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Image {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                source: card.modelData && card.modelData.appIcon
                                    ? Quickshell.iconPath(card.modelData.appIcon, "application-x-executable")
                                    : Quickshell.iconPath("application-x-executable")
                                sourceSize.width: 20
                                sourceSize.height: 20
                                fillMode: Image.PreserveAspectFit

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    visible: parent.status !== Image.Ready
                                    iconName: "notifications"
                                    iconSize: 16
                                    iconColour: Theme.accentColour
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: card.modelData && card.modelData.appName
                                    ? card.modelData.appName.toUpperCase()
                                    : "NOTIFICATION"
                                color: Theme.textSecondary
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeMicro
                                font.weight: Typography.weightBold
                                font.letterSpacing: 0.5
                                elide: Text.ElideRight
                            }

                            // Close / Dismiss button
                            Rectangle {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                radius: 9
                                color: dismissMa.containsMouse ? Qt.alpha(Theme.contentColour, 0.12) : "transparent"

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    iconName: "close"
                                    iconSize: 13
                                    iconColour: Theme.textSecondary
                                }

                                MouseArea {
                                    id: dismissMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (card.modelData)
                                            popupWindow.removeToast(card.modelData.id, true);
                                    }
                                }
                            }
                        }

                        // Summary (Title) — strictly single line
                        Text {
                            Layout.fillWidth: true
                            text: card.modelData ? card.modelData.summary : ""
                            color: Theme.textPrimary
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeBody
                            font.weight: Typography.weightBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            visible: text.length > 0
                        }

                        // Body (Message preview) — first line snippet only
                        Text {
                            Layout.fillWidth: true
                            text: {
                                if (!card.modelData || !card.modelData.body) return "";
                                return card.modelData.body.replace(/\n+/g, " ").trim();
                            }
                            color: Theme.textSecondary
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeCaption
                            font.weight: Typography.weightMedium
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            visible: text.length > 0
                        }
                    }
                }
            }
        }
    }
}
