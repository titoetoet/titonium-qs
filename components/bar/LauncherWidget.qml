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
    readonly property int panelTop: Theme.barHeight
        - (Theme.barHeight - Theme.widgetHeight) / 2
        + Theme.borderThickness
    readonly property int panelWidth: 960
    readonly property int panelHeight: joinDepth + 540

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

        Loader {
            anchors.fill: parent
            anchors.topMargin: root.joinDepth
            active: panel.visible
            sourceComponent: Dashboard {
                monitoringActive: root.expanded
                onCloseRequested: root.expanded = false
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
        color: root.expanded
            ? Qt.alpha(Theme.contentColour, 0.14)
            : pointer.containsMouse
                ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.08))
                : "transparent"

        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

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
        Accessible.name: "Applications Launcher"
    }
}
