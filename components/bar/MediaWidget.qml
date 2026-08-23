pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../../config"
import "../primitives"
import "../popups"

Item {
    id: root

    property bool expanded: false
    readonly property Item inputRegion: inputArea

    readonly property MprisPlayer activePlayer: {
        const list = Mpris.players.values;
        if (!list || list.length === 0) return null;
        for (let i = 0; i < list.length; i++) {
            if (list[i].playbackState === MprisPlaybackState.Playing)
                return list[i];
        }
        return list[0];
    }

    readonly property string trackTitle: activePlayer?.trackTitle ?? ""
    readonly property string trackArtist: {
        if (!activePlayer) return "";
        try {
            if (Array.isArray(activePlayer.trackArtists) && activePlayer.trackArtists.length > 0)
                return activePlayer.trackArtists.join(", ");
            if (activePlayer.trackArtist)
                return activePlayer.trackArtist;
            if (activePlayer.trackArtists)
                return String(activePlayer.trackArtists);
        } catch (e) {
            return activePlayer.trackArtist || "";
        }
        return "";
    }
    readonly property string trackAlbum: activePlayer?.trackAlbum ?? ""
    readonly property var playbackState: activePlayer?.playbackState ?? MprisPlaybackState.Stopped
    readonly property bool isPlaying: playbackState === MprisPlaybackState.Playing

    readonly property bool hasMedia: activePlayer !== null && (trackTitle.length > 0 || isPlaying)

    readonly property string displayText: {
        if (!trackTitle && !trackArtist) return "Media";
        if (trackTitle && trackArtist) return trackTitle + " • " + trackArtist;
        return trackTitle || trackArtist;
    }

    readonly property int popupWidth: 330
    readonly property int popupHeight: 235
    readonly property int joinDepth: Metrics.innerRadius
    readonly property int panelTop: Metrics.barHeight
        - (Metrics.barHeight - Metrics.widgetHeight) / 2
        + Metrics.borderThickness

    // In Quickshell MprisPlayer, length and position are already in SECONDS
    readonly property real trackLengthSec: activePlayer?.length ?? 0
    property real trackPositionSec: activePlayer?.position ?? 0
    property real lastSyncWallTimeMs: Date.now()

    function syncPosition(): void {
        lastSyncWallTimeMs = Date.now();
        if (activePlayer) {
            trackPositionSec = activePlayer.position;
        }
    }

    Timer {
        id: posTimer
        interval: 1000
        running: root.hasMedia && root.isPlaying && root.expanded
        repeat: true
        onTriggered: {
            if (root.activePlayer && root.isPlaying) {
                const dBusPos = root.activePlayer.position;
                if (Math.abs(dBusPos - root.trackPositionSec) > 2.5) {
                    root.trackPositionSec = dBusPos;
                } else {
                    const nextPos = root.trackPositionSec + 1;
                    root.trackPositionSec = (root.trackLengthSec > 0)
                        ? Math.min(root.trackLengthSec, nextPos)
                        : nextPos;
                }
                root.lastSyncWallTimeMs = Date.now();
            }
        }
    }

    Connections {
        target: root.activePlayer

        function onPositionChanged(): void {
            root.syncPosition();
        }
        function onPlaybackStateChanged(): void {
            root.syncPosition();
        }
        function onTrackTitleChanged(): void {
            root.syncPosition();
        }
    }

    onActivePlayerChanged: syncPosition()
    onPlaybackStateChanged: syncPosition()
    onTrackTitleChanged: syncPosition()

    onExpandedChanged: {
        if (expanded) {
            if (isPlaying) {
                const elapsedSec = (Date.now() - lastSyncWallTimeMs) / 1000;
                const nextPos = trackPositionSec + elapsedSec;
                trackPositionSec = (trackLengthSec > 0) ? Math.min(trackLengthSec, nextPos) : nextPos;
            }
            lastSyncWallTimeMs = Date.now();
        } else {
            lastSyncWallTimeMs = Date.now();
        }
    }

    function togglePlay(): void {
        if (activePlayer && typeof activePlayer.togglePlaying === "function") {
            activePlayer.togglePlaying();
        } else {
            sendMediaDbus("PlayPause");
        }
    }

    function playNext(): void {
        if (activePlayer && activePlayer.canGoNext && typeof activePlayer.next === "function") {
            activePlayer.next();
        } else {
            sendMediaDbus("Next");
        }
    }

    function playPrevious(): void {
        if (activePlayer && activePlayer.canGoPrevious && typeof activePlayer.previous === "function") {
            activePlayer.previous();
        } else {
            sendMediaDbus("Previous");
        }
    }

    function seekRelative(seconds: real): void {
        if (!activePlayer || trackLengthSec <= 0) return;
        const target = Math.max(0, Math.min(trackLengthSec, trackPositionSec + seconds));
        seekToSec(target);
    }

    function seekToRatio(ratio: real): void {
        if (!activePlayer || trackLengthSec <= 0) return;
        const target = Math.max(0, Math.min(1, ratio)) * trackLengthSec;
        seekToSec(target);
    }

    function seekToSec(targetSec: real): void {
        if (!activePlayer) return;
        const trackId = activePlayer.trackId || "/";
        const targetMicro = Math.floor(targetSec * 1000000);
        
        if (typeof activePlayer.setPosition === "function") {
            try {
                activePlayer.setPosition(targetSec);
            } catch (e) {}
        }
        
        Quickshell.execDetached([
            "sh", "-c",
            `for bus in $(busctl --user list | awk '/org.mpris.MediaPlayer2/{print $1}'); do dbus-send --session --type=method_call --dest=$bus /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.SetPosition objpath:"${trackId}" int64:${targetMicro} 2>/dev/null; done`
        ]);

        root.trackPositionSec = targetSec;
    }

    function sendMediaDbus(action: string): void {
        Quickshell.execDetached([
            "sh", "-c",
            `for bus in $(busctl --user list | awk '/org.mpris.MediaPlayer2/{print $1}'); do dbus-send --session --type=method_call --dest=$bus /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.${action} 2>/dev/null; done`
        ]);
    }

    function formatTime(seconds: real): string {
        if (!seconds || isNaN(seconds) || seconds < 0) return "0:00";
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    visible: root.hasMedia
    implicitWidth: root.hasMedia ? (panel.visible ? popupWidth : trigger.implicitWidth) : 0
    implicitHeight: root.hasMedia ? (panel.visible ? panelTop + panel.height : Metrics.widgetHeight) : 0

    Item {
        id: inputArea

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.expanded ? root.popupWidth : trigger.implicitWidth
        height: root.expanded ? root.panelTop + panel.height : Metrics.widgetHeight
    }

    PopupPanel {
        id: panel

        open: root.expanded
        closedTransformOrigin: Item.Top
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.panelTop
        width: root.popupWidth
        height: root.joinDepth + root.popupHeight

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Metrics.marginMd
            spacing: Metrics.spacingSm

            // 1. Header Row (Music Icon Badge + Track Info)
            RowLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacingMd

                // Universal Music Badge / Album Art
                Rectangle {
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 46
                    Layout.alignment: Qt.AlignVCenter
                    radius: Metrics.radiusMd
                    color: Qt.alpha(Theme.accentColour, 0.16)
                    border.width: 1
                    border.color: Qt.alpha(Theme.accentColour, 0.28)
                    clip: true

                    Image {
                        id: albumArtImg
                        anchors.fill: parent
                        source: root.activePlayer?.trackArtUrl || ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: albumArtImg.status !== Image.Ready
                        iconName: "music_note"
                        iconSize: Metrics.iconLg
                        iconColour: Theme.accentColour
                    }
                }

                // Track Title, Artist, and Source Badge
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // Source Tag Badge
                    RowLayout {
                        spacing: Metrics.spacingXs

                        MaterialIcon {
                            iconName: "music_note"
                            iconSize: 13
                            iconColour: Theme.accentColour
                        }

                        Text {
                            text: root.activePlayer?.identity || root.activePlayer?.desktopEntry || "Media Player"
                            color: Theme.accentColour
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.sizeMicro
                            font.weight: Typography.weightBold
                            elide: Text.ElideRight
                        }
                    }

                    // Track Title
                    Text {
                        Layout.fillWidth: true
                        text: root.trackTitle || "No title"
                        color: Theme.textPrimary
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeBody
                        font.weight: Typography.weightBold
                        elide: Text.ElideRight
                    }

                    // Artist
                    Text {
                        Layout.fillWidth: true
                        text: root.trackArtist || ""
                        color: Theme.textSecondary
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeCaption
                        font.weight: Typography.weightMedium
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }
                }
            }

            // 2. Interactive Audio Visualizer (Bars / Wave / Dots)
            AudioVisualizer {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: 26
                active: root.isPlaying
                barCount: 40
                barWidth: 3
                barSpacing: 3
                maxHeight: 26
            }

            // 3. Interactive Progress / Seek Bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    id: progressBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Theme.surfaceContainerColour

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: root.trackLengthSec > 0
                            ? Math.max(0, Math.min(progressBar.width, (root.trackPositionSec / root.trackLengthSec) * progressBar.width))
                            : 0
                        radius: 3
                        color: Theme.accentColour

                        Behavior on width {
                            enabled: !seekMouse.pressed
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
                    }

                    MouseArea {
                        id: seekMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            const ratio = Math.max(0, Math.min(1, mouse.x / width));
                            root.seekToRatio(ratio);
                        }
                    }
                }

                // Time Duration Counters
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.formatTime(root.trackPositionSec)
                        color: Theme.textSecondary
                        font.family: Typography.monoFontFamily
                        font.pixelSize: Typography.sizeMicro
                        font.weight: Typography.weightMedium
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.trackLengthSec > 0 ? root.formatTime(root.trackLengthSec) : "--:--"
                        color: Theme.textSecondary
                        font.family: Typography.monoFontFamily
                        font.pixelSize: Typography.sizeMicro
                        font.weight: Typography.weightMedium
                    }
                }
            }

            // 4. Normalized 3-Button Playback Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Metrics.spacingXl

                Item { Layout.fillWidth: true }

                // Previous Track
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: prevMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.10) : "transparent"

                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        iconName: "skip_previous"
                        iconSize: 22
                        iconColour: Theme.textPrimary
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.playPrevious()
                    }
                }

                // Play / Pause Main Button (Action Button)
                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 21
                    color: Theme.accentColour

                    Behavior on scale { NumberAnimation { duration: Metrics.animFast } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        iconName: root.isPlaying ? "pause" : "play_arrow"
                        iconSize: 24
                        iconColour: Theme.themeName === "light" ? "#ffffff" : Theme.surfaceColour
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePlay()
                    }
                }

                // Next Track
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: nextMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.10) : "transparent"

                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        iconName: "skip_next"
                        iconSize: 22
                        iconColour: Theme.textPrimary
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.playNext()
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    // TopBar Dynamic Pill (Collapsed State)
    Rectangle {
        id: trigger

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        implicitHeight: Metrics.widgetHeight
        implicitWidth: 340
        radius: height / 2

        color: pillHover.containsMouse
            ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.10))
            : Theme.surfaceContainerColour
        border.width: 0

        RowLayout {
            id: pillContent

            anchors.fill: parent
            anchors.leftMargin: Metrics.marginSm
            anchors.rightMargin: Metrics.marginMd
            spacing: Metrics.spacingSm

            // 1. Universal Music Icon Badge (Left)
            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                radius: 11
                color: Qt.alpha(Theme.accentColour, 0.20)

                MaterialIcon {
                    anchors.centerIn: parent
                    iconName: "music_note"
                    iconSize: 13
                    iconColour: Theme.accentColour
                }
            }

            // 2. Song Title & Artist Marquee (Center)
            Item {
                id: marqueeContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                readonly property real overflow: Math.max(0, songText.implicitWidth - width + 8)

                Text {
                    id: songText
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    x: 0
                    text: root.displayText
                    color: Theme.textPrimary
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.sizeCaption
                    font.weight: Typography.weightMedium
                }

                SequentialAnimation {
                    id: marqueeAnim
                    loops: Animation.Infinite
                    alwaysRunToEnd: true

                    PauseAnimation { duration: 2500 }
                    NumberAnimation {
                        target: songText
                        property: "x"
                        to: -marqueeContainer.overflow
                        duration: Math.max(1500, marqueeContainer.overflow * 35)
                        easing.type: Easing.InOutSine
                    }
                    PauseAnimation { duration: 2500 }
                    NumberAnimation {
                        target: songText
                        property: "x"
                        to: 0
                        duration: Math.max(1500, marqueeContainer.overflow * 35)
                        easing.type: Easing.InOutSine
                    }
                }

                function checkAndStart(): void {
                    marqueeAnim.stop();
                    songText.x = 0;
                    if (marqueeContainer.overflow > 0 && root.isPlaying) {
                        marqueeAnim.start();
                    }
                }

                Connections {
                    target: root
                    function onDisplayTextChanged(): void {
                        marqueeContainer.checkAndStart();
                    }
                    function onIsPlayingChanged(): void {
                        marqueeContainer.checkAndStart();
                    }
                }

                Component.onCompleted: checkAndStart()
            }

            // 3. Mini Play/Pause Button on TopBar (Right)
            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                radius: 11
                color: miniPlayHover.containsMouse ? Qt.alpha(Theme.contentColour, 0.12) : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    iconName: root.isPlaying ? "pause" : "play_arrow"
                    iconSize: 15
                    iconColour: Theme.accentColour
                }

                MouseArea {
                    id: miniPlayHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        mouse.accepted = true;
                        root.togglePlay();
                    }
                }
            }
        }

        MouseArea {
            id: pillHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }
}
