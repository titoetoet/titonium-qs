pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"
import "../primitives"

Item {
    id: root

    property bool monitoringActive: false
    signal closeRequested()

    property bool choosingAvatar: false
    property string searchQuery: ""
    property string activeCategory: "all"
    property var allApps: []
    property var filteredApps: []
    property var pages: [[]]
    property bool wheelBusy: false

    Timer {
        id: wheelDebounce
        interval: 380
        repeat: false
        onTriggered: root.wheelBusy = false
    }

    // Absorb clicks so they don't fall through to the background scrim
    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: {} // Intentionally swallow unhandled clicks
    }

    readonly property var avatarPresets: [
        { icon: "terminal", label: "Arch / Coder" },
        { icon: "person", label: "Classic" },
        { icon: "face", label: "Smile" },
        { icon: "smart_toy", label: "Robot" },
        { icon: "rocket_launch", label: "Rocket" },
        { icon: "sports_esports", label: "Gamer" },
        { icon: "bolt", label: "Energy" },
        { icon: "coffee", label: "Coffee" },
        { icon: "palette", label: "Artist" },
        { icon: "pets", label: "Cat" },
        { icon: "headphones", label: "Music" },
        { icon: "local_fire_department", label: "Fire" }
    ]

    readonly property var categoriesList: [
        { id: "all",       name: I18n.t("launcher.category_all"),      icon: "apps" },
        { id: "fav",       name: "Favorites",                          icon: "star" },
        { id: "internet",  name: I18n.t("launcher.category_internet"), icon: "public" },
        { id: "dev",       name: I18n.t("launcher.category_dev"),      icon: "code" },
        { id: "media",     name: I18n.t("launcher.category_media"),    icon: "movie" },
        { id: "system",    name: I18n.t("launcher.category_system"),   icon: "tune" }
    ]

    function resolveAppIcon(iconName) {
        if (!iconName || iconName.length === 0) return "";
        if (iconName.startsWith("/")) return "file://" + iconName;
        const resolved = Quickshell.iconPath(iconName, "");
        if (resolved && resolved.length > 0) return resolved;
        return "";
    }

    function getFallbackCategoryInfo(name, categories, iconName) {
        const s = ((name || "") + " " + (categories ? categories.join(" ") : "") + " " + (iconName || "")).toLowerCase();
        if (/terminal|ghostty|kitty|alacritty|xterm|yazi|console/.test(s))
            return { icon: "terminal", color: "#8be9fd", bg: Qt.alpha("#8be9fd", 0.16) };
        if (/code|develop|ide|editor|git|zed|nvim|antigravity|programming/.test(s))
            return { icon: "code", color: "#bd93f9", bg: Qt.alpha("#bd93f9", 0.16) };
        if (/browser|firefox|chrome|internet|chat|discord|web|network|avahi|ssh|vnc|zeroconf/.test(s))
            return { icon: "public", color: "#50fa7b", bg: Qt.alpha("#50fa7b", 0.16) };
        if (/media|audio|video|music|player|mpv|spotify|gimp|camera|video capture|v4l2|qv4l2|qvidcap/.test(s))
            return { icon: "play_circle", color: "#ff79c6", bg: Qt.alpha("#ff79c6", 0.16) };
        if (/keyboard|fcitx|input|layout|kbd/.test(s))
            return { icon: "keyboard", color: "#f1fa8c", bg: Qt.alpha("#f1fa8c", 0.16) };
        if (/hwloc|hardware|lstopo|monitor|system|cpu|memory|qemu|process/.test(s))
            return { icon: "memory", color: "#ffb86c", bg: Qt.alpha("#ffb86c", 0.16) };
        if (/office|wps|writer|document|pdf|spreadsheet|presentation|calc|word/.test(s))
            return { icon: "description", color: "#8be9fd", bg: Qt.alpha("#8be9fd", 0.16) };
        if (/setting|config|control|kcm|preferences/.test(s))
            return { icon: "settings", color: "#bd93f9", bg: Qt.alpha("#bd93f9", 0.16) };
        return { icon: "apps", color: "#8be9fd", bg: Qt.alpha("#8be9fd", 0.16) };
    }

    function categoryMatch(app, targetCat) {
        if (targetCat === "all") return true;
        if (targetCat === "fav") {
            const recents = SettingsService.recentApps || [];
            if (recents.length > 0) {
                return recents.includes(app.name);
            }
            const nl = app.nameLower;
            return /firefox|chrome|code|visual studio|kitty|alacritty|thunar|spotify|discord|vlc|gimp|telegram|chatgpt|claude|zed/.test(nl);
        }
        if (!app.categories || app.categories.length === 0) return targetCat === "system";
        const catStr = app.categories.join(" ").toLowerCase();
        if (targetCat === "internet") return /network|webbrowser|email|chat|feed|internet|remote|messaging/.test(catStr);
        if (targetCat === "dev") return /development|ide|editor|programming|debugger|git|utility/.test(catStr);
        if (targetCat === "media") return /audio|video|graphics|player|recorder|music|image|photography|art/.test(catStr);
        if (targetCat === "system") return /system|settings|terminal|monitor|package|hardware|core|utility|accessories|archiving/.test(catStr);
        return true;
    }

    function getCategoryCount(catId) {
        let count = 0;
        for (let i = 0; i < root.allApps.length; i++) {
            if (categoryMatch(root.allApps[i], catId)) count++;
        }
        return count;
    }

    function getActiveCategoryTitle() {
        for (let i = 0; i < root.categoriesList.length; i++) {
            if (root.categoriesList[i].id === root.activeCategory) {
                return root.categoriesList[i].name;
            }
        }
        return "Applications";
    }

    function loadApplications() {
        const raw = DesktopEntries.applications.values || [];
        const list = [];
        const seen = {};

        for (let i = 0; i < raw.length; i++) {
            const app = raw[i];
            if (!app || !app.name || app.noDisplay) continue;
            if (seen[app.name]) continue;
            seen[app.name] = true;

            list.push({
                name: app.name,
                nameLower: (app.name || "").toLowerCase(),
                genericName: app.genericName || "",
                comment: app.comment || "",
                subtitle: app.genericName || app.comment || "Application",
                icon: app.icon || "",
                categories: app.categories || [],
                entry: app
            });
        }

        list.sort((a, b) => a.name.localeCompare(b.name));
        root.allApps = list;
        filterApps();
    }

    function filterApps() {
        const q = root.searchQuery.trim().toLowerCase();
        const cat = root.activeCategory;
        const res = [];

        for (let i = 0; i < root.allApps.length; i++) {
            const a = root.allApps[i];
            if (cat !== "all" && !categoryMatch(a, cat)) continue;
            if (q.length > 0) {
                const matchName = a.nameLower.includes(q);
                const matchGen = (a.genericName || "").toLowerCase().includes(q);
                const matchCom = (a.comment || "").toLowerCase().includes(q);
                if (!matchName && !matchGen && !matchCom) continue;
            }
            res.push(a);
        }

        // For Favorites: Sort by recent launch order (most recent first)
        if (cat === "fav" && (SettingsService.recentApps || []).length > 0) {
            const recents = SettingsService.recentApps;
            res.sort((a, b) => {
                const idxA = recents.indexOf(a.name);
                const idxB = recents.indexOf(b.name);
                if (idxA === -1 && idxB === -1) return a.name.localeCompare(b.name);
                if (idxA === -1) return 1;
                if (idxB === -1) return -1;
                return idxA - idxB;
            });
        }

        root.filteredApps = res;

        // Chunk into pages of 24 (6 columns x 4 rows)
        const pageSize = 24;
        const p = [];
        for (let j = 0; j < res.length; j += pageSize) {
            p.push(res.slice(j, j + pageSize));
        }
        root.pages = p.length > 0 ? p : [[]];
        if (pageView) {
            pageView.currentIndex = 0;
        }
    }

    function switchCategory(catId) {
        if (root.activeCategory === catId) return;
        root.activeCategory = catId;
        tabCrossFade.restart();
    }

    function launchApp(app) {
        if (!app || !app.entry) return;

        // Record to Favorites / Recent Apps list
        SettingsService.recordRecentApp(app.name);

        let executed = false;
        try {
            if (typeof app.entry.execute === "function") {
                app.entry.execute();
                executed = true;
            } else if (typeof app.entry.launch === "function") {
                app.entry.launch();
                executed = true;
            }
        } catch (e) {
            executed = false;
        }

        if (!executed) {
            const rawCmd = app.entry.execString || app.entry.exec || "";
            if (rawCmd.length > 0) {
                const cleanCmd = rawCmd.replace(/%[fFuUdDnNickvm]/g, "").trim();
                Quickshell.execDetached(["sh", "-c", cleanCmd]);
            } else if (Array.isArray(app.entry.command) && app.entry.command.length > 0) {
                Quickshell.execDetached(app.entry.command);
            }
        }
        root.closeRequested();
    }

    Component.onCompleted: {
        loadApplications();
    }

    onSearchQueryChanged: {
        if (tabCrossFade.running) tabCrossFade.stop();
        filterApps();
    }

    // ── MAIN SPLIT-VIEW LAYOUT: Left Sidebar + Right Launchpad ──────────────
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // ═════════════════════════════════════════════════════════════════════
        // LEFT SIDEBAR: User Identity, Category Navigation & System Controls
        // ═════════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            radius: 12
            color: Qt.alpha(Theme.contentColour, 0.03)
            border.width: 1
            border.color: Qt.alpha(Theme.contentColour, 0.06)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // ── 1. User Header & Preferences (Theme + Option/Settings) ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // User Profile (Click to change Avatar)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 42
                        radius: 8
                        color: userMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.08) : "transparent"

                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            Rectangle {
                                width: 30
                                height: 30
                                radius: 15
                                color: Qt.alpha(Theme.accentColour, 0.18)
                                border.width: 1
                                border.color: Qt.alpha(Theme.accentColour, 0.40)

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    iconName: SettingsService.avatarIcon || "terminal"
                                    iconSize: 17
                                    iconColour: Theme.accentColour
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: SystemInfoService.user || "cole"
                                color: Theme.contentColour
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeBody
                                font.weight: Typography.weightBold
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: userMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.choosingAvatar = !root.choosingAvatar
                        }
                    }

                    // Theme Toggle Quick Button
                    SidebarHeaderBtn {
                        iconName: Theme.themeName === "dark" ? "light_mode" : "dark_mode"
                        iconColor: Theme.themeName === "dark" ? "#f1fa8c" : "#ffb86c"
                        tooltip: "Toggle Light/Dark Theme"
                        onTriggered: Theme.themeName = (Theme.themeName === "dark" ? "light" : "dark")
                    }

                    // Option / Settings Quick Button (Triggers Notification Coming Soon)
                    SidebarHeaderBtn {
                        iconName: "settings"
                        tooltip: "Options & Settings"
                        onTriggered: {
                            Quickshell.execDetached(["notify-send", "-a", "Titonium", "-i", "preferences-system", "Options & Settings", "Coming Soon!"]);
                        }
                    }
                }

                // Hairline Divider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Qt.alpha(Theme.contentColour, 0.06)
                }

                // ── 2. Category Navigation List with Counts ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: root.categoriesList

                        Rectangle {
                            id: catItem
                            required property var modelData
                            readonly property bool isSelected: root.activeCategory === catItem.modelData.id && !root.choosingAvatar
                            readonly property int appCount: root.getCategoryCount(catItem.modelData.id)

                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: 8
                            color: isSelected
                                ? Qt.alpha(Theme.accentColour, 0.20)
                                : (catMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.08) : "transparent")

                            Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                MaterialIcon {
                                    iconName: catItem.modelData.icon
                                    iconSize: 20
                                    iconColour: catItem.isSelected ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.60)
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: catItem.modelData.name
                                    color: catItem.isSelected ? Theme.accentColour : Theme.contentColour
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeBody
                                    font.weight: catItem.isSelected ? Typography.weightDemiBold : Typography.weightNormal
                                }

                                // Count Badge
                                Rectangle {
                                    implicitHeight: 20
                                    implicitWidth: countText.implicitWidth + 12
                                    radius: 10
                                    color: catItem.isSelected ? Qt.alpha(Theme.accentColour, 0.30) : Qt.alpha(Theme.contentColour, 0.08)

                                    Text {
                                        id: countText
                                        anchors.centerIn: parent
                                        text: String(catItem.appCount)
                                        color: catItem.isSelected ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.50)
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.sizeMicro
                                        font.weight: Typography.weightDemiBold
                                    }
                                }
                            }

                            MouseArea {
                                id: catMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.choosingAvatar = false;
                                    root.switchCategory(catItem.modelData.id);
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Hairline Divider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Qt.alpha(Theme.contentColour, 0.06)
                }

                // ── 3. Bottom Power & Session Bar ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    SidebarPowerBtn {
                        iconName: "lock"
                        tooltip: I18n.t("action.lock")
                        onTriggered: {
                            Quickshell.execDetached(["sh", "-c", "command -v hyprlock >/dev/null && hyprlock || swaylock"]);
                            root.closeRequested();
                        }
                    }

                    SidebarPowerBtn {
                        iconName: "bedtime"
                        tooltip: I18n.t("action.suspend")
                        onTriggered: {
                            Quickshell.execDetached(["systemctl", "suspend"]);
                            root.closeRequested();
                        }
                    }

                    SidebarPowerBtn {
                        iconName: "restart_alt"
                        tooltip: I18n.t("action.restart")
                        onTriggered: {
                            Quickshell.execDetached(["systemctl", "reboot"]);
                            root.closeRequested();
                        }
                    }

                    SidebarPowerBtn {
                        iconName: "power_settings_new"
                        tooltip: I18n.t("action.shutdown")
                        accent: true
                        onTriggered: {
                            Quickshell.execDetached(["systemctl", "poweroff"]);
                            root.closeRequested();
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        // RIGHT MAIN CONTENT: Launchpad with Clean Fade-Out/In Crossfade Motion
        // ═════════════════════════════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // ── 1. Full-width Clean Search Bar ──
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: 10
                color: Qt.alpha(Theme.contentColour, 0.05)
                border.width: searchInput.activeFocus ? 1.5 : 1
                border.color: searchInput.activeFocus ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.08)

                Behavior on border.color { ColorAnimation { duration: Metrics.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 8

                    MaterialIcon {
                        iconName: "search"
                        iconSize: 18
                        iconColour: searchInput.activeFocus ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.40)
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Theme.contentColour
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeBody
                        clip: true
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.searchQuery
                        onTextChanged: root.searchQuery = text

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !searchInput.text && !searchInput.activeFocus
                            text: I18n.t("launcher.search_placeholder")
                            color: Qt.alpha(Theme.contentColour, 0.35)
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeBody
                        }
                    }

                    // Clear button
                    Rectangle {
                        visible: root.searchQuery.length > 0
                        width: 20
                        height: 20
                        radius: 10
                        color: clearMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.15) : "transparent"

                        MaterialIcon {
                            anchors.centerIn: parent
                            iconName: "close"
                            iconSize: 14
                            iconColour: Qt.alpha(Theme.contentColour, 0.60)
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                root.searchQuery = "";
                            }
                        }
                    }
                }
            }

            // ── 2A. Category Breadcrumb & Count ──
            RowLayout {
                Layout.fillWidth: true
                visible: !root.choosingAvatar
                spacing: 8

                Text {
                    text: root.getActiveCategoryTitle()
                    color: Theme.contentColour
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.sizeTitleSm
                    font.weight: Typography.weightBold
                }

                Text {
                    text: "·  " + root.filteredApps.length + (root.activeCategory === "fav" ? " recent apps" : " apps")
                    color: Qt.alpha(Theme.contentColour, 0.45)
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.sizeCaption
                }

                Item { Layout.fillWidth: true }
            }

            // ── 2B. macOS Launchpad 6-Column with Smooth Fade-Out/In ──
            Item {
                id: launchpadContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.choosingAvatar

                property real gridOpacity: 1.0

                // Sequential Crossfade Animation (Fade out -> Swap Data -> Fade in)
                SequentialAnimation {
                    id: tabCrossFade
                    NumberAnimation {
                        target: launchpadContainer
                        property: "gridOpacity"
                        to: 0.0
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                    ScriptAction {
                        script: root.filterApps()
                    }
                    NumberAnimation {
                        target: launchpadContainer
                        property: "gridOpacity"
                        to: 1.0
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }

                ListView {
                    id: pageView
                    anchors.fill: parent
                    opacity: launchpadContainer.gridOpacity
                    clip: true
                    orientation: ListView.Horizontal
                    snapMode: ListView.SnapOneItem
                    boundsBehavior: Flickable.StopAtBounds
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: width
                    highlightMoveDuration: 380
                    model: root.pages

                    delegate: Item {
                        id: pageItem
                        required property var modelData
                        required property int index

                        width: pageView.width
                        height: pageView.height

                        // Smooth page depth zoom
                        readonly property bool isCurrent: pageView.currentIndex === pageItem.index
                        opacity: isCurrent ? 1.0 : 0.20
                        scale: isCurrent ? 1.0 : 0.90

                        Behavior on opacity {
                            NumberAnimation { duration: 340; easing.type: Easing.OutQuint }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
                        }

                        // 6-Column Layout with fixed-size squircle tiles (No coordinate overriding)
                        Flow {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 8

                            Repeater {
                                model: pageItem.modelData

                                Rectangle {
                                    id: appTile
                                    required property var modelData
                                    required property int index

                                    width: Math.floor((pageItem.width - 40) / 6)
                                    height: 98
                                    radius: 12
                                    color: tileMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.08) : "transparent"

                                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        spacing: 4

                                        // Icon Container (Stable, Hardware-accelerated scale on hover - zero jitter!)
                                        Item {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.preferredWidth: 44
                                            Layout.preferredHeight: 44
                                            scale: tileMouse.containsMouse ? 1.10 : 1.0

                                            Behavior on scale {
                                                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                                            }

                                            // 1. Real Icon from Icon Theme or Pixmaps
                                            Image {
                                                id: appIconImg
                                                anchors.centerIn: parent
                                                width: 40
                                                height: 40
                                                source: root.resolveAppIcon(appTile.modelData.icon)
                                                sourceSize.width: 48
                                                sourceSize.height: 48
                                                fillMode: Image.PreserveAspectFit
                                                visible: status === Image.Ready && source.toString().length > 0
                                            }

                                            // 2. Smart Category Squircle Fallback (when Real Icon has no match)
                                            Rectangle {
                                                id: fallbackIcon
                                                anchors.centerIn: parent
                                                width: 40
                                                height: 40
                                                radius: 11
                                                visible: !appIconImg.visible
                                                readonly property var info: root.getFallbackCategoryInfo(appTile.modelData.name, appTile.modelData.categories, appTile.modelData.icon)
                                                color: info.bg
                                                border.width: 1
                                                border.color: Qt.alpha(info.color, 0.40)

                                                MaterialIcon {
                                                    anchors.centerIn: parent
                                                    iconName: fallbackIcon.info.icon
                                                    iconSize: 20
                                                    iconColour: fallbackIcon.info.color
                                                }
                                            }
                                        }

                                        // App Name: Strictly 1 Line (No 2nd line wrapping)
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 2
                                            Layout.rightMargin: 2
                                            Layout.alignment: Qt.AlignHCenter
                                            horizontalAlignment: Text.AlignHCenter
                                            text: appTile.modelData.name
                                            color: tileMouse.containsMouse ? Theme.accentColour : Theme.contentColour
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.sizeBodySm
                                            font.weight: Typography.weightMedium
                                            wrapMode: Text.NoWrap
                                            maximumLineCount: 1
                                            elide: Text.ElideRight

                                            Behavior on color { ColorAnimation { duration: Metrics.animFast } }
                                        }
                                    }

                                    MouseArea {
                                        id: tileMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.launchApp(appTile.modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                // Mouse Wheel Handler: Captures vertical mouse scroll & flips horizontal pages reliably!
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton // Allows app clicks to pass through to delegates
                    propagateComposedEvents: true

                    onWheel: function(wheel) {
                        if (root.wheelBusy) return;
                        const dy = wheel.angleDelta.y;
                        const dx = wheel.angleDelta.x;
                        if (dy < 0 || dx < 0) {
                            if (pageView.currentIndex < root.pages.length - 1) {
                                root.wheelBusy = true;
                                wheelDebounce.restart();
                                pageView.currentIndex++;
                            }
                        } else if (dy > 0 || dx > 0) {
                            if (pageView.currentIndex > 0) {
                                root.wheelBusy = true;
                                wheelDebounce.restart();
                                pageView.currentIndex--;
                            }
                        }
                    }
                }

                // Empty State Fallback
                Item {
                    anchors.centerIn: parent
                    visible: root.filteredApps.length === 0
                    width: 200
                    height: 80

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            iconName: "search_off"
                            iconSize: 28
                            iconColour: Qt.alpha(Theme.contentColour, 0.30)
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.t("launcher.no_apps")
                            color: Qt.alpha(Theme.contentColour, 0.45)
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeBody
                        }
                    }
                }
            }

            // ── 2C. Interactive Page Indicator Dots (macOS Launchpad style) ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                visible: !root.choosingAvatar && root.pages.length > 1

                Repeater {
                    model: root.pages.length

                    Rectangle {
                        id: pageDot
                        required property int index
                        readonly property bool isCurrent: pageView.currentIndex === pageDot.index

                        width: isCurrent ? 18 : 6
                        height: 6
                        radius: 3
                        color: isCurrent ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.20)

                        Behavior on width { NumberAnimation { duration: Metrics.animFast } }
                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pageView.currentIndex = pageDot.index
                        }
                    }
                }
            }

            // ── 2D. Interactive Avatar Picker Mode ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.choosingAvatar
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: I18n.t("launcher.avatar_picker_title")
                        color: Qt.alpha(Theme.contentColour, 0.60)
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeBodyLg
                        font.weight: Typography.weightDemiBold
                    }
                    Item { Layout.fillWidth: true }
                    IconButton {
                        iconName: "close"
                        buttonSize: 26
                        onTriggered: root.choosingAvatar = false
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 6
                    rowSpacing: 8
                    columnSpacing: 8

                    Repeater {
                        model: root.avatarPresets

                        Rectangle {
                            id: avBtn
                            required property var modelData
                            readonly property bool isSelected: SettingsService.avatarIcon === avBtn.modelData.icon

                            Layout.fillWidth: true
                            implicitHeight: 64
                            radius: 8
                            color: isSelected
                                ? Qt.alpha(Theme.accentColour, 0.22)
                                : (avMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.08) : Qt.alpha(Theme.contentColour, 0.03))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.06)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 3

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    iconName: avBtn.modelData.icon
                                    iconSize: 22
                                    iconColour: avBtn.isSelected ? Theme.accentColour : Theme.contentColour
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: avBtn.modelData.label
                                    color: avBtn.isSelected ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.50)
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.sizeMicro
                                    font.weight: avBtn.isSelected ? Typography.weightBold : Typography.weightNormal
                                }
                            }

                            MouseArea {
                                id: avMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SettingsService.setAvatarIcon(avBtn.modelData.icon);
                                    root.choosingAvatar = false;
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    component SidebarHeaderBtn: Rectangle {
        id: shBtn
        required property string iconName
        required property string tooltip
        property color iconColor: Theme.contentColour
        signal triggered()

        implicitWidth: 28
        implicitHeight: 28
        radius: 6
        color: shMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.12) : Qt.alpha(Theme.contentColour, 0.03)

        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

        MaterialIcon {
            anchors.centerIn: parent
            iconName: shBtn.iconName
            iconSize: 15
            iconColour: shMouse.containsMouse ? Theme.accentColour : shBtn.iconColor
        }

        MouseArea {
            id: shMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: shBtn.triggered()
        }
    }

    component SidebarPowerBtn: Rectangle {
        id: spBtn
        required property string iconName
        required property string tooltip
        property bool accent: false
        signal triggered()

        Layout.fillWidth: true
        implicitHeight: 32
        radius: 7
        color: spBtn.accent
            ? (spMouse.containsMouse ? Qt.alpha("#ff5555", 0.25) : Qt.alpha("#ff5555", 0.12))
            : (spMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.12) : Qt.alpha(Theme.contentColour, 0.03))

        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

        MaterialIcon {
            anchors.centerIn: parent
            iconName: spBtn.iconName
            iconSize: 16
            iconColour: spBtn.accent ? "#ff5555" : (spMouse.containsMouse ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.60))
        }

        MouseArea {
            id: spMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: spBtn.triggered()
        }
    }
}
