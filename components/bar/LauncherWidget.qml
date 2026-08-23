pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../config"
import "../popups"
import "../primitives"
import "../dashboard"

Item {
    id: root

    property bool expanded: false
    readonly property alias inputRegion: inputArea

    readonly property int joinDepth: Theme.innerRadius
    readonly property int sessionStripWidth: 48
    readonly property int panelTop: Theme.barHeight
        - (Theme.barHeight - Theme.widgetHeight) / 2
        + Theme.borderThickness
    readonly property int panelWidth: Theme.dashboardWidth + sessionStripWidth
    readonly property int panelHeight: joinDepth + Theme.dashboardHeight

    implicitWidth: panel.visible ? panelWidth : trigger.implicitWidth
    implicitHeight: panel.visible ? panelTop + panel.height : Theme.widgetHeight

    z: 1

    Item {
        id: inputArea

        anchors.top: parent.top
        anchors.left: parent.left
        width: root.expanded ? root.panelWidth : trigger.implicitWidth
        height: root.expanded ? root.panelTop + root.panelHeight : Theme.widgetHeight
    }

    PopupPanel {
        id: panel

        open: root.expanded
        closedTransformOrigin: Item.TopLeft
        anchors.left: parent.left
        y: root.panelTop
        width: root.panelWidth
        height: root.panelHeight

        Item {
            id: sessionArea

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.sessionStripWidth

            Column {
                anchors.centerIn: parent
                spacing: 8

                SessionAction {
                    iconName: "power_settings_new"
                    label: "Shutdown"
                    accent: true
                    onTriggered: Quickshell.execDetached(["systemctl", "poweroff"])
                }
                SessionAction {
                    iconName: "restart_alt"
                    label: "Restart"
                    onTriggered: Quickshell.execDetached(["systemctl", "reboot"])
                }
                SessionAction {
                    iconName: "bedtime"
                    label: "Sleep"
                    onTriggered: Quickshell.execDetached(["systemctl", "suspend"])
                }
                SessionAction {
                    iconName: "downloading"
                    label: "Hibernate"
                    onTriggered: Quickshell.execDetached(["systemctl", "hibernate"])
                }
                SessionAction {
                    iconName: "logout"
                    label: "Logout"
                    onTriggered: Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                }
            }
        }

        // Vertical Divider separating Session Actions from Dashboard
        Rectangle {
            id: sessionDivider
            anchors.left: sessionArea.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 16
            anchors.bottomMargin: 16
            width: 1
            color: Theme.borderSubtle
        }

        Loader {
            anchors.left: sessionDivider.right
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            active: panel.visible
            sourceComponent: Dashboard {
                monitoringActive: root.expanded
            }
        }
    }

    Rectangle {
        id: trigger

        anchors.top: parent.top
        anchors.left: parent.left
        implicitWidth: Theme.widgetHeight
        implicitHeight: Theme.widgetHeight
        radius: height / 2
        color: pointer.containsMouse
            ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.08))
            : "transparent"

        Image {
            anchors.centerIn: parent
            width: 20
            height: 20
            source: "/usr/share/pixmaps/archlinux-logo.svg"
            sourceSize.width: 20
            sourceSize.height: 20
            fillMode: Image.PreserveAspectFit
        }

        MouseArea {
            id: pointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

        Accessible.role: Accessible.Button
        Accessible.name: "Dashboard"
    }

    component SessionAction: Rectangle {
        id: action

        required property string iconName
        required property string label
        property bool accent: false
        signal triggered

        implicitWidth: 40
        implicitHeight: 40
        radius: 20
        color: actionPointer.containsMouse
            ? Qt.tint(Theme.surfaceContainerColour,
                Qt.alpha(action.accent ? Theme.accentColour : Theme.contentColour, 0.16))
            : "transparent"

        MaterialIcon {
            anchors.centerIn: parent
            iconName: action.iconName
            iconSize: 20
            iconColour: action.accent ? Theme.accentColour : Theme.contentColour
        }

        MouseArea {
            id: actionPointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }

        Accessible.role: Accessible.Button
        Accessible.name: action.label
    }
}
