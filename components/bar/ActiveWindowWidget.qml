pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../primitives"

Item {
    id: root

    readonly property Item inputRegion: root
    // Keep natural stable order without reordering
    readonly property var toplevels: (ToplevelManager.toplevels?.values ?? []).filter(t => t && !t.minimized)

    implicitHeight: Metrics.widgetHeight
    implicitWidth: taskListView.contentWidth

    function getAppIcon(appId: string): string {
        if (!appId || appId.length === 0)
            return Quickshell.iconPath("application-x-executable");

        const lower = appId.toLowerCase().trim();

        // 1. Direct heuristic lookup from DesktopEntries
        const entry = DesktopEntries.heuristicLookup(appId) || DesktopEntries.heuristicLookup(lower);
        if (entry && entry.icon) {
            if (entry.icon.startsWith("/")) {
                return "file://" + entry.icon;
            }
            const p = Quickshell.iconPath(entry.icon, "");
            if (p && p.length > 0) return p;
            if (entry.icon === "chatgpt" || lower.includes("chatgpt")) {
                return "file:///usr/share/pixmaps/chatgpt.png";
            }
        }

        // 2. Direct Quickshell icon lookup
        let path = Quickshell.iconPath(appId, "");
        if (path && path.length > 0) return path;

        path = Quickshell.iconPath(lower, "");
        if (path && path.length > 0) return path;

        // 3. Explicit pixmap matching for specialized apps
        if (lower.includes("chatgpt")) {
            return "file:///usr/share/pixmaps/chatgpt.png";
        }

        // 4. Common aliases mapping
        const aliases = {
            "code": "vscode",
            "code-oss": "vscode",
            "google-chrome": "google-chrome",
            "chrome": "google-chrome",
            "kitty": "kitty",
            "alacritty": "alacritty",
            "thunar": "thunar",
            "wezterm": "wezterm",
            "org.wezfurlong.wezterm": "wezterm",
            "org.gnome.nautilus": "org.gnome.Nautilus",
            "antigravity-ide": "code"
        };
        if (aliases[lower]) {
            path = Quickshell.iconPath(aliases[lower], "");
            if (path && path.length > 0) return path;
        }

        // 5. Reverse-DNS fallback (last segment)
        if (lower.includes(".")) {
            const parts = lower.split(".");
            const last = parts[parts.length - 1];
            path = Quickshell.iconPath(last, "");
            if (path && path.length > 0) return path;
        }

        return Quickshell.iconPath(appId, "application-x-executable");
    }

    ListView {
        id: taskListView

        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: Metrics.spacingXs
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: root.toplevels

        delegate: Rectangle {
            id: taskItem

            required property Toplevel modelData

            readonly property bool hasModel: taskItem.modelData !== null && taskItem.modelData !== undefined
            readonly property string appClass: hasModel ? (taskItem.modelData.appId || "") : ""
            readonly property string appTitleText: hasModel ? (taskItem.modelData.title || taskItem.modelData.appId || "Untitled") : "Untitled"

            // Resilient active check combining ToplevelManager and ActiveWindowService (Hyprland IPC)
            readonly property bool isActive: hasModel && (
                taskItem.modelData.active
                || ToplevelManager.activeToplevel === taskItem.modelData
                || (ActiveWindowService.valid && (
                    (taskItem.appClass && ActiveWindowService.appClass && taskItem.appClass.toLowerCase() === ActiveWindowService.appClass.toLowerCase())
                    || (taskItem.modelData.title && ActiveWindowService.title && taskItem.modelData.title === ActiveWindowService.title)
                ))
            )

            // Dynamic width: Active window expands with title, others remain compact circle pill
            implicitWidth: taskItem.isActive
                ? Math.min(rowContent.implicitWidth + Metrics.marginLg, 260)
                : Metrics.widgetHeight
            implicitHeight: Metrics.widgetHeight
            radius: height / 2 // Rounded pill/circular highlight capsule

            color: {
                if (taskItem.isActive) {
                    return Qt.alpha(Theme.accentColour, 0.18);
                }
                if (itemMouseArea.containsMouse) {
                    return Qt.alpha(Theme.contentColour, 0.08);
                }
                return "transparent";
            }

            border.width: taskItem.isActive ? 1 : 0
            border.color: taskItem.isActive ? Qt.alpha(Theme.accentColour, 0.40) : "transparent"

            Behavior on implicitWidth {
                NumberAnimation { duration: Metrics.animNormal; easing.type: Easing.OutCubic }
            }

            Behavior on color {
                ColorAnimation { duration: Metrics.animFast }
            }

            RowLayout {
                id: rowContent

                anchors.fill: parent
                anchors.leftMargin: taskItem.isActive ? Metrics.marginSm : 0
                anchors.rightMargin: taskItem.isActive ? Metrics.marginSm : 0
                spacing: Metrics.spacingSm

                // Crisp Hi-DPI App Icon
                Item {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    Layout.alignment: Qt.AlignVCenter | (taskItem.isActive ? Qt.AlignLeft : Qt.AlignHCenter)

                    Image {
                        id: appIcon
                        anchors.fill: parent
                        source: root.getAppIcon(taskItem.appClass)
                        sourceSize.width: 48
                        sourceSize.height: 48
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: appIcon.status !== Image.Ready
                        iconName: "apps"
                        iconSize: Metrics.iconMd
                        iconColour: taskItem.isActive ? Theme.accentColour : Theme.textSecondary
                    }
                }

                // Active App Title (Visible when active)
                Text {
                    id: appTitle

                    visible: taskItem.isActive
                    Layout.fillWidth: true
                    Layout.maximumWidth: 210
                    Layout.alignment: Qt.AlignVCenter
                    elide: Text.ElideRight
                    text: taskItem.appTitleText
                    color: Theme.textPrimary
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.sizeBodySm
                    font.weight: Typography.weightDemiBold
                    renderType: Theme.renderType
                }
            }

            MouseArea {
                id: itemMouseArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (taskItem.hasModel && typeof taskItem.modelData.activate === "function")
                        taskItem.modelData.activate();
                }
            }

            Accessible.role: Accessible.Button
            Accessible.name: taskItem.appTitleText
        }
    }
}
