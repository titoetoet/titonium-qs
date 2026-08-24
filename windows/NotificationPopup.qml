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
        implicitWidth: 360 + 380 + 2 * shadowPad
        implicitHeight: toastColumn.implicitHeight + 2 * shadowPad
        color: "transparent"
        visible: activeToasts.length > 0

        WlrLayershell.namespace: "titonium-notification-popup"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        mask: Region { item: toastColumn }

        property var activeToasts: []
        property bool _removing: false
        readonly property int maxVisibleToasts: 4
        readonly property int toastTimeout: 5000
        readonly property bool ncOpen: NotificationService.activeScreen === modelData

        Connections {
            target: NotificationService

            function onNotificationReceived(notification) {
                if (!notification || !notification.id) return;
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

            function onClearAllToastsRequested() {
                popupWindow.activeToasts = [];
            }
        }

        function removeToast(notifId, dismissNotif) {
            if (popupWindow._removing) return;
            popupWindow._removing = true;
            try {
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
            } finally {
                popupWindow._removing = false;
            }
        }

        Column {
            id: toastColumn
            anchors.top: parent.top
            anchors.topMargin: popupWindow.shadowPad
            anchors.right: parent.right
            anchors.rightMargin: popupWindow.shadowPad + (popupWindow.ncOpen ? 375 : 0)
            width: 360
            spacing: 8

            Behavior on anchors.rightMargin {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: popupWindow.activeToasts

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    required property int index

                    readonly property var notif: card.modelData
                    readonly property bool hasNotif: card.notif !== null && card.notif !== undefined
                    readonly property bool isCritical: card.hasNotif && (card.notif.urgency === NotificationUrgency.Critical)
                    readonly property string appIconSrc: (card.hasNotif && card.notif.appIcon)
                        ? Quickshell.iconPath(card.notif.appIcon, "application-x-executable")
                        : Quickshell.iconPath("application-x-executable")
                    readonly property string appNameText: (card.hasNotif && card.notif.appName)
                        ? card.notif.appName.toUpperCase()
                        : "NOTIFICATION"
                    readonly property string notifSummary: (card.hasNotif && card.notif.summary) ? card.notif.summary : ""
                    readonly property string notifBody: {
                        if (!card.hasNotif || !card.notif.body) return "";
                        return String(card.notif.body).replace(/\n+/g, " ").trim();
                    }

                    width: 360
                    height: content.implicitHeight + 24
                    color: "transparent"

                    // ── 1. Isolated Background & Theme Shadow ──
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.innerRadius
                        antialiasing: true

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Theme.surfaceColour }
                            GradientStop { position: 1.0; color: Theme.surfaceColourBottom }
                        }

                        border.width: 1
                        border.color: card.isCritical ? Qt.alpha(Theme.inputMethodIconColour, 0.40) : Theme.popupBorder

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            blurMax: 24
                            shadowBlur: 0.60
                            shadowVerticalOffset: 6
                            shadowColor: Theme.popupShadowColour
                        }

                        // Layer 1: Top Ambient Diffuse Glow
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 1
                            height: 24
                            radius: Theme.innerRadius - 1
                            clip: true
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.25 : 0.08) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // Layer 2: Thanh đèn giả lập (Specular Rim Sheen)
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 1
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            height: 1.5
                            radius: 1
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.2; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.35 : 0.20) }
                                GradientStop { position: 0.5; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.75 : 0.60) }
                                GradientStop { position: 0.8; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.35 : 0.20) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // Left Urgency Accent Indicator Bar
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 4
                            width: 3
                            radius: 1.5
                            visible: card.isCritical
                            color: Theme.inputMethodIconColour
                        }
                    }

                    Timer {
                        interval: popupWindow.toastTimeout
                        running: true
                        onTriggered: {
                            if (card && card.hasNotif && card.notif && card.notif.id)
                                Qt.callLater(function() {
                                    popupWindow.removeToast(card.notif.id, false);
                                });
                        }
                    }

                    // ── 2. Toast Content ──
                    ColumnLayout {
                        id: content
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: card.isCritical ? 18 : 14
                        anchors.rightMargin: 12
                        anchors.topMargin: 12
                        spacing: 6

                        // Header: App Icon + App Name + Dismiss Button
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                radius: 5
                                color: Qt.alpha(Theme.contentColour, 0.06)

                                Image {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: card.appIconSrc
                                    sourceSize.width: 16
                                    sourceSize.height: 16
                                    fillMode: Image.PreserveAspectFit
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    visible: card.appIconSrc.length === 0
                                    iconName: "notifications"
                                    iconSize: 14
                                    iconColour: card.isCritical ? Theme.inputMethodIconColour : Theme.accentColour
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: card.appNameText
                                color: card.isCritical ? Theme.inputMethodIconColour : Theme.textSecondary
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeMicro
                                font.weight: Typography.weightBold
                                font.letterSpacing: 0.6
                                elide: Text.ElideRight
                            }

                            // Close / Dismiss button
                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                radius: 10
                                color: dismissMa.containsMouse ? Theme.surfaceHoverStrong : "transparent"

                                Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    iconName: "close"
                                    iconSize: 13
                                    iconColour: dismissMa.containsMouse ? Theme.textPrimary : Theme.textSecondary
                                }

                                MouseArea {
                                    id: dismissMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (card.hasNotif && card.notif.id)
                                            popupWindow.removeToast(card.notif.id, true);
                                    }
                                }
                            }
                        }

                        // Summary (Title)
                        Text {
                            Layout.fillWidth: true
                            text: card.notifSummary
                            color: Theme.textPrimary
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeBodySm
                            font.weight: Typography.weightBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            visible: text.length > 0
                        }

                        // Body (Message preview)
                        Text {
                            Layout.fillWidth: true
                            text: card.notifBody
                            color: Theme.textSecondary
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeCaption
                            font.weight: Typography.weightNormal
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            lineHeight: 1.25
                            visible: text.length > 0
                        }

                        // Action Buttons
                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: card.hasNotif && card.notif.actions && card.notif.actions.length > 0

                            Repeater {
                                model: (card.hasNotif && card.notif.actions) ? card.notif.actions : []

                                delegate: Rectangle {
                                    id: actBtn
                                    required property var modelData
                                    implicitHeight: 26
                                    implicitWidth: actLabel.implicitWidth + 18
                                    radius: 13
                                    color: actMouse.containsMouse ? Theme.surfaceHoverStrong : Theme.surfaceContainerColour
                                    border.width: 1
                                    border.color: Theme.borderSubtle

                                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                                    Text {
                                        id: actLabel
                                        anchors.centerIn: parent
                                        text: actBtn.modelData ? (actBtn.modelData.text || "") : ""
                                        color: Theme.textPrimary
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.sizeCaption
                                        font.weight: Typography.weightMedium
                                    }

                                    MouseArea {
                                        id: actMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (actBtn.modelData && typeof actBtn.modelData.invoke === "function") {
                                                actBtn.modelData.invoke();
                                                popupWindow.removeToast(card.notif.id, true);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
