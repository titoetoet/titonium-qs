pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../config"

Rectangle {
    id: root

    required property ShellScreen screen
    readonly property alias inputRegion: root

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int activeWorkspace: monitor?.activeWorkspace?.id ?? 1
    readonly property int shown: 5
    readonly property int cellWidth: 32
    readonly property int groupOffset: Math.floor((activeWorkspace - 1) / shown) * shown
    readonly property int activeIndex: Math.max(0, Math.min(shown - 1, activeWorkspace - groupOffset - 1))

    function workspaceId(index: int): int {
        return groupOffset + index + 1;
    }

    function occupied(workspace: int): bool {
        try {
            const vals = Hyprland.workspaces.values;
            for (let i = 0; i < vals.length; i++) {
                const item = vals[i];
                if (item && item.id === workspace && (item.lastIpcObject?.windows ?? 0) > 0)
                    return true;
            }
        } catch (e) {}
        return false;
    }

    function focusWorkspace(workspace: int): void {
        if (activeWorkspace === workspace) {
            Hyprland.dispatch(Hyprland.usingLua
                ? 'hl.dsp.workspace.toggle_special("special")'
                : "togglespecialworkspace special");
            return;
        }

        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = "${workspace}" })`
            : `workspace ${workspace}`);
    }

    implicitWidth: shown * cellWidth
    implicitHeight: Theme.widgetHeight
    radius: height / 2
    color: Theme.surfaceContainerColour

    Rectangle {
        id: activeIndicator

        x: 3 + root.activeIndex * root.cellWidth
        anchors.verticalCenter: parent.verticalCenter
        width: root.cellWidth - 6
        height: Theme.widgetHeight - 4
        radius: height / 2
        color: Theme.accentColour

        Behavior on x {
            NumberAnimation {
                duration: Theme.popupAnimationDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.shown

            Item {
                id: workspaceItem

                required property int index
                readonly property int workspace: root.workspaceId(index)
                readonly property bool isActive: root.activeWorkspace === workspace
                readonly property bool isOccupied: root.occupied(workspace)

                width: root.cellWidth
                height: root.height

                Text {
                    anchors.centerIn: parent
                    text: workspaceItem.workspace
                    color: workspaceItem.isActive
                        ? "#ffffff"
                        : workspaceItem.isOccupied
                            ? Theme.contentColour
                            : Theme.onSurfaceVariantColour
                    opacity: workspaceItem.isActive || workspaceItem.isOccupied ? 1 : 0.55
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: workspaceItem.isActive ? Font.Bold : Font.Medium
                    renderType: Theme.renderType
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(workspaceItem.workspace)
                    onWheel: event => {
                        event.accepted = true;
                        const direction = event.angleDelta.y > 0 ? "r-1" : "r+1";
                        Hyprland.dispatch(Hyprland.usingLua
                            ? `hl.dsp.focus({ workspace = "${direction}" })`
                            : `workspace ${direction}`);
                    }
                }
            }
        }
    }
}
