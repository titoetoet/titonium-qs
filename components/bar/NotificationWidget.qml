pragma ComponentBehavior: Bound

import QtQuick
import "../../config"
import "../../services"
import "../primitives"

Item {
    id: root

    property var screen: null
    readonly property bool isScreenOpen: root.screen ? (NotificationService.activeScreen === root.screen) : NotificationService.open
    readonly property Item inputRegion: root

    // Emitted when user clicks the button so TopBar can close other popups
    signal toggleRequested()

    implicitWidth: Theme.widgetHeight
    implicitHeight: Theme.widgetHeight
    width: implicitWidth
    height: implicitHeight

    Accessible.role: Accessible.Button
    Accessible.name: "Notification Center"

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.isScreenOpen
            ? Qt.alpha(Theme.accentColour, 0.14)
            : pointer.containsMouse
                ? Qt.alpha(Theme.contentColour, 0.08)
                : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }

        // macOS-style list icon ≡
        MaterialIcon {
            anchors.centerIn: parent
            iconName: "format_list_bulleted"
            iconSize: 18
            iconColour: root.isScreenOpen
                ? Theme.accentColour
                : Theme.contentColour

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Unread Notification Indicator Dot
        Rectangle {
            id: unreadDot
            visible: NotificationService.hasNotifications
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 4
            anchors.rightMargin: 4
            width: 7
            height: 7
            radius: 3.5
            color: Theme.accentColour
            border.width: 1.5
            border.color: Theme.barSurfaceColour

            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleRequested()
    }
}
