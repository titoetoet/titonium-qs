pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../services"
import "../config"
import "../components/primitives"
import "../components/news"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: ncWindow

        required property ShellScreen modelData

        readonly property int panelWidth: 360
        readonly property int topOffset: Theme.barHeight + Theme.borderThickness
        readonly property int panelHeight: Math.round(modelData.height * 0.6)
        property int currentTab: NotificationService.hasNotifications ? 1 : 0

        screen: modelData
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        color: "transparent"

        // Overlay renders above Top layer (TopBar window)
        WlrLayershell.namespace: "titonium-nc"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        readonly property bool isThisScreenOpen: NotificationService.activeScreen === modelData

        onIsThisScreenOpenChanged: {
            if (isThisScreenOpen) {
                currentTab = NotificationService.hasNotifications ? 1 : 0;
            }
        }

        Connections {
            target: NotificationService

            function onNotificationReceived(notification) {
                if (ncWindow.isThisScreenOpen) {
                    ncWindow.currentTab = 1;
                }
            }
        }

        // Full-screen input mask. 0×0 when closed so clicks pass through.
        // When open, catches clicks anywhere; outside the panel dismisses it.
        mask: Region { item: inputTarget }

        Item {
            id: inputTarget
            x: 0
            y: 0
            width: ncWindow.isThisScreenOpen ? ncWindow.width : 0
            height: ncWindow.isThisScreenOpen ? ncWindow.height : 0

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    const point = mapToItem(panelRoot, mouse.x, mouse.y);
                    const insidePanel = point.x >= 0
                        && point.x <= panelRoot.width
                        && point.y >= 0
                        && point.y <= panelRoot.height;

                    if (!insidePanel)
                        NotificationService.close();
                }
            }
        }

        // ── Panel content ────────────────────────────────────────────────────
        Item {
            id: panelRoot

            x: ncWindow.width - panelWidth - Theme.borderThickness
            y: topOffset
            height: panelHeight
            width: panelWidth

            opacity: ncWindow.isThisScreenOpen ? 1.0 : 0.0
            scale:   ncWindow.isThisScreenOpen ? 1.0 : 0.96
            transformOrigin: Item.TopRight

            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            // Background
            Rectangle {
                anchors.fill: parent
                color: Theme.surfaceColour
                radius: Theme.innerRadius
                border.width: 0
                clip: true
                antialiasing: true

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: Theme.popupShadowRange
                    shadowBlur: 1
                    shadowVerticalOffset: 2
                    shadowColor: Theme.popupShadowColour
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ── Tab bar ──────────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 52

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 24
                        height: 32
                        radius: 10
                        color: Theme.surfaceContainerColour

                        // Sliding indicator
                        Rectangle {
                            x: ncWindow.currentTab === 0 ? 2 : parent.width / 2
                            y: 2
                            width: parent.width / 2 - 2
                            height: parent.height - 4
                            radius: 8
                            color: Qt.alpha(Theme.contentColour, 0.12)
                            Behavior on x {
                                enabled: ncWindow.isThisScreenOpen
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        Row {
                            anchors.fill: parent

                            Repeater {
                                model: ["Today", "Notifications"]

                                Item {
                                    id: tabItem
                                    required property string modelData
                                    required property int index
                                    property bool isActive: ncWindow.currentTab === index
                                    width: parent.width / 2
                                    height: parent.height

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Text {
                                            text: tabItem.modelData
                                            color: tabItem.isActive ? Theme.contentColour : Theme.onSurfaceVariantColour
                                            font.pixelSize: 13
                                            font.weight: tabItem.isActive ? Font.DemiBold : Font.Normal
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        Rectangle {
                                            visible: tabItem.index === 1 && NotificationService.hasNotifications
                                            Layout.preferredWidth: 6
                                            Layout.preferredHeight: 6
                                            radius: 3
                                            color: Theme.accentColour
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ncWindow.currentTab = tabItem.index
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Tab content ──────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TodayView {
                        anchors.fill: parent
                        visible: opacity > 0
                        opacity: ncWindow.currentTab === 0 ? 1 : 0
                        Behavior on opacity {
                            enabled: ncWindow.isThisScreenOpen
                            NumberAnimation { duration: 180 }
                        }
                    }

                    NotificationsView {
                        anchors.fill: parent
                        visible: opacity > 0
                        opacity: ncWindow.currentTab === 1 ? 1 : 0
                        Behavior on opacity {
                            enabled: ncWindow.isThisScreenOpen
                            NumberAnimation { duration: 180 }
                        }
                    }
                }
            }
        }

        // ── TODAY view ───────────────────────────────────────────────────────
        component TodayView: Item {
            readonly property var now: new Date()
            property date displayedMonth: new Date(now.getFullYear(), now.getMonth(), 1)
            readonly property int todayDay: now.getDate()
            readonly property int todayMonth: now.getMonth()
            readonly property int todayYear: now.getFullYear()
            readonly property var monthNames: [
                "January","February","March","April","May","June",
                "July","August","September","October","November","December"
            ]
            readonly property var weekDayNames: [
                "Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"
            ]


            Flickable {
                anchors.fill: parent
                contentHeight: col.implicitHeight
                clip: true

                ColumnLayout {
                    id: col
                    width: parent.width
                    spacing: 0

                    Item { Layout.fillWidth: true; implicitHeight: 10 }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16; Layout.rightMargin: 16
                        implicitHeight: 64
                        radius: 14
                        color: Theme.surfaceContainerColour

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            MaterialIcon {
                                iconName: WeatherService.iconName
                                iconSize: 30
                                iconColour: Theme.onSurfaceVariantColour
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: WeatherService.temperatureText
                                    color: Theme.contentColour
                                    font.pixelSize: 20
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: WeatherService.description
                                    color: Theme.onSurfaceVariantColour
                                    font.pixelSize: 11
                                }
                            }

                            Text {
                                text: WeatherService.location
                                color: Theme.onSurfaceVariantColour
                                font.pixelSize: 10
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 12 }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16; Layout.rightMargin: 16
                        spacing: 2
                        Text {
                            text: weekDayNames[now.getDay()]
                            color: Theme.onSurfaceVariantColour
                            font.pixelSize: 11; font.weight: Font.Medium
                        }
                        Text {
                            text: monthNames[todayMonth] + " " + todayDay + ", " + todayYear
                            color: Theme.contentColour
                            font.pixelSize: 22; font.weight: Font.Light
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 14 }
                    Rectangle {
                        Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16
                        implicitHeight: 1; color: Qt.alpha(Theme.contentColour, 0.08)
                    }
                    Item { Layout.fillWidth: true; implicitHeight: 12 }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16; Layout.rightMargin: 16
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            IconButton {
                                iconName: "chevron_left"; buttonSize: 28; accessibleName: "Previous month"
                                onTriggered: displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() - 1, 1)
                            }

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: Qt.formatDate(displayedMonth, "MMMM yyyy")
                                color: Theme.contentColour; font.pixelSize: 13; font.weight: Font.DemiBold
                            }

                            IconButton {
                                iconName: "chevron_right"; buttonSize: 28; accessibleName: "Next month"
                                onTriggered: displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + 1, 1)
                            }
                        }

                        DayOfWeekRow {
                            Layout.fillWidth: true
                            locale: Qt.locale()
                            delegate: Text {
                                required property var model
                                horizontalAlignment: Text.AlignHCenter
                                text: model.shortName
                                color: Theme.onSurfaceVariantColour; font.pixelSize: 10; font.weight: Font.Medium
                            }
                        }

                        MonthGrid {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 196
                            month: displayedMonth.getMonth()
                            year: displayedMonth.getFullYear()
                            locale: Qt.locale()
                            spacing: 1

                            delegate: Rectangle {
                                id: dayCell
                                required property var model
                                color: model.today ? Theme.accentColour : "transparent"
                                radius: height / 2

                                Text {
                                    anchors.centerIn: parent
                                    text: dayCell.model.day
                                    color: dayCell.model.today ? Theme.surfaceColour
                                        : dayCell.model.month === displayedMonth.getMonth()
                                            ? Theme.contentColour : Theme.onSurfaceVariantColour
                                    opacity: dayCell.model.month === displayedMonth.getMonth() || dayCell.model.today ? 1 : 0.35
                                    font.pixelSize: 10
                                    font.weight: dayCell.model.today ? Font.Bold : Font.Normal
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 14 }
                    Rectangle {
                        Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16
                        implicitHeight: 1; color: Qt.alpha(Theme.contentColour, 0.08)
                    }
                    Item { Layout.fillWidth: true; implicitHeight: 12 }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16; Layout.rightMargin: 16
                        spacing: 8
                        Text {
                            text: "UPCOMING"
                            color: Theme.onSurfaceVariantColour
                            font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.8
                        }
                        Repeater {
                            model: [
                                { time: "10:00 AM", title: "Team Standup",       color: "#ffb4ab" },
                                { time: "2:00 PM",  title: "Design Review",      color: "#8bd5ca" },
                                { time: "7:00 PM",  title: "Dinner reservation", color: "#c6a0f6" }
                            ]
                            Rectangle {
                                id: ev
                                required property var modelData
                                Layout.fillWidth: true; implicitHeight: 48; radius: 10
                                color: Theme.surfaceContainerColour
                                Rectangle {
                                    width: 3; height: parent.height - 12
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                    radius: 2; color: ev.modelData.color
                                }
                                ColumnLayout {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.leftMargin: 14; anchors.rightMargin: 12
                                    spacing: 2
                                    Text { text: ev.modelData.title; color: Theme.contentColour; font.pixelSize: 12; font.weight: Font.Medium }
                                    Text { text: ev.modelData.time; color: Theme.onSurfaceVariantColour; font.pixelSize: 10 }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 14 }
                    Rectangle {
                        Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16
                        implicitHeight: 1; color: Qt.alpha(Theme.contentColour, 0.08)
                    }
                    Item { Layout.fillWidth: true; implicitHeight: 12 }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16; Layout.rightMargin: 16
                        spacing: 8

                        Text {
                            text: "NEWS"
                            color: Theme.onSurfaceVariantColour
                            font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.8
                        }

                        Repeater {
                            model: [
                                { headline: "KDE Plasma 6.5 released with HDR improvements", source: "Phoronix", time: "2h ago", accent: "#8bd5ca", snippet: "HDR, fractional scaling, and new defaults land in the latest desktop release." },
                                { headline: "Hyprland 0.47 ships grouped windows", source: "Hyprland Blog", time: "5h ago", accent: "#c6a0f6", snippet: "Grouped windows and better multi-monitor handling headline this Wayland compositor update." },
                                { headline: "Linux 6.14 LTS kernel released", source: "Kernel.org", time: "1d ago", accent: "#eed49f", snippet: "Long-term support kernel adds new hardware enablement and scheduler improvements." }
                            ]

                            NewsCard {
                                required property var modelData
                                headline: modelData.headline
                                source: modelData.source
                                time: modelData.time
                                accent: modelData.accent
                                snippet: modelData.snippet
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 20 }
                }
            }
        }

        // ── NOTIFICATIONS view ───────────────────────────────────────────────
        component NotificationsView: Item {
            SystemClock {
                id: viewClock
                precision: SystemClock.Minutes
            }

            function formatRelative(ts, now): string {
                if (!ts)
                    return "";

                const diff = Math.max(0, now.getTime() - ts.getTime());
                const sec = Math.floor(diff / 1000);

                if (sec < 60)
                    return "now";

                const min = Math.floor(sec / 60);
                if (min < 60)
                    return min + "m ago";

                const hr = Math.floor(min / 60);
                if (hr < 24)
                    return hr + "h ago";

                return Math.floor(hr / 24) + "d ago";
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16; Layout.rightMargin: 12
                    Layout.topMargin: 4; Layout.bottomMargin: 4

                    Text {
                        Layout.fillWidth: true
                        text: NotificationService.count > 0
                            ? NotificationService.count + " Notification" + (NotificationService.count !== 1 ? "s" : "")
                            : "No Notifications"
                        color: Theme.onSurfaceVariantColour
                        font.pixelSize: 11; font.weight: Font.DemiBold
                    }

                    Rectangle {
                        visible: NotificationService.count > 0
                        implicitHeight: 24; implicitWidth: clrTxt.implicitWidth + 16
                        radius: 12
                        color: clrMa.containsMouse ? Qt.alpha(Theme.contentColour, 0.1) : "transparent"
                        Text { id: clrTxt; anchors.centerIn: parent; text: "Clear All"; color: Theme.accentColour; font.pixelSize: 11 }
                        MouseArea { id: clrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: NotificationService.clearAll() }
                    }
                }

                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: nCol.implicitHeight; clip: true

                    ColumnLayout {
                        id: nCol
                        width: parent.width; spacing: 8

                        Item { Layout.fillWidth: true; implicitHeight: 4 }

                        Item {
                            Layout.fillWidth: true; implicitHeight: 120
                            visible: NotificationService.count === 0
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 8
                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    iconName: "notifications_off"; iconSize: 36
                                    iconColour: Qt.alpha(Theme.onSurfaceVariantColour, 0.35); fill: 0
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "No notifications"
                                    color: Qt.alpha(Theme.onSurfaceVariantColour, 0.45); font.pixelSize: 12
                                }
                            }
                        }

                        Repeater {
                            model: NotificationService.notifications

                            delegate: Rectangle {
                                id: card

                                required property Notification modelData
                                required property int index

                                readonly property Notification notification: card.modelData
                                readonly property bool hasNotif: card.notification !== null && card.notification !== undefined
                                readonly property bool critical: card.hasNotif && (card.notification.urgency === NotificationUrgency.Critical)
                                readonly property string appLabel: card.hasNotif && card.notification.appName ? card.notification.appName : "Unknown application"
                                readonly property string iconSource: card.hasNotif && card.notification.appIcon
                                    ? Quickshell.iconPath(card.notification.appIcon, "dialog-information-symbolic")
                                    : Quickshell.iconPath("dialog-information-symbolic")
                                readonly property string notifSummary: card.hasNotif && card.notification.summary ? card.notification.summary : ""
                                readonly property string notifBody: card.hasNotif && card.notification.body ? card.notification.body : ""
                                readonly property string notifImage: card.hasNotif && card.notification.image ? card.notification.image : ""
                                readonly property var notifActions: card.hasNotif && card.notification.actions ? card.notification.actions : []
                                readonly property bool notifHasInlineReply: card.hasNotif && (card.notification.hasInlineReply ?? false)

                                Layout.fillWidth: true
                                Layout.leftMargin: 12; Layout.rightMargin: 12
                                implicitHeight: content.implicitHeight + 24
                                radius: 14
                                color: Theme.surfaceContainerColour

                                // Urgency accent bar
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 3
                                    radius: 2
                                    color: card.critical ? Theme.accentColour
                                        : (card.hasNotif && card.notification.urgency === NotificationUrgency.Low)
                                            ? Qt.alpha(Theme.onSurfaceVariantColour, 0.35)
                                            : Theme.downloadIconColour
                                }

                                ColumnLayout {
                                    id: content
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 12
                                    anchors.topMargin: 12
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Image {
                                            width: 20; height: 20
                                            source: card.iconSource
                                            sourceSize.width: 20; sourceSize.height: 20
                                            fillMode: Image.PreserveAspectFit

                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                visible: parent.status !== Image.Ready
                                                iconName: "apps"; iconSize: 18
                                                iconColour: Theme.onSurfaceVariantColour
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: card.appLabel.toUpperCase()
                                            color: Theme.onSurfaceVariantColour
                                            font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.5
                                        }

                                        Text {
                                            text: card.hasNotif ? formatRelative(NotificationService.receivedTime(card.notification.id), viewClock.date) : ""
                                            color: Theme.onSurfaceVariantColour
                                            font.pixelSize: 10
                                        }

                                        Item {
                                            width: 18; height: 18
                                            Rectangle {
                                                anchors.fill: parent; radius: height / 2
                                                color: cardDismiss.containsMouse ? Qt.alpha(Theme.contentColour, 0.12) : Qt.alpha(Theme.contentColour, 0.06)
                                            }
                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                iconName: "close"; iconSize: 11
                                                iconColour: Theme.onSurfaceVariantColour
                                            }
                                            MouseArea {
                                                id: cardDismiss
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (card.hasNotif && typeof card.notification.dismiss === "function")
                                                        card.notification.dismiss();
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: card.notifSummary
                                        color: Theme.contentColour
                                        font.pixelSize: 12; font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        visible: text.length > 0
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: card.notifBody
                                        color: Theme.onSurfaceVariantColour
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 4
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                        visible: text.length > 0
                                    }

                                    Image {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 120
                                        fillMode: Image.PreserveAspectFit
                                        source: card.notifImage
                                        visible: card.notifImage.length > 0
                                    }

                                    // Action buttons
                                    Flow {
                                        Layout.fillWidth: true
                                        visible: card.notifActions.length > 0
                                        spacing: 6

                                        Repeater {
                                            model: card.notifActions

                                            delegate: Rectangle {
                                                id: actionBtn

                                                required property NotificationAction modelData

                                                readonly property bool hasAction: actionBtn.modelData !== null && actionBtn.modelData !== undefined

                                                implicitHeight: 28
                                                implicitWidth: actionLabel.implicitWidth + 20
                                                radius: 14
                                                color: actionPointer.containsMouse
                                                    ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.12))
                                                    : Qt.alpha(Theme.contentColour, 0.06)

                                                Text {
                                                    id: actionLabel
                                                    anchors.centerIn: parent
                                                    text: actionBtn.hasAction ? (actionBtn.modelData.text || "") : ""
                                                    color: Theme.contentColour
                                                    font.pixelSize: 11
                                                }

                                                MouseArea {
                                                    id: actionPointer
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (actionBtn.hasAction && typeof actionBtn.modelData.invoke === "function")
                                                            actionBtn.modelData.invoke();
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Inline reply
                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: card.notifHasInlineReply
                                        spacing: 6

                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 30
                                            radius: 15
                                            color: Qt.alpha(Theme.surfaceColour, 0.5)
                                            border.width: 1
                                            border.color: Qt.alpha(Theme.contentColour, 0.08)

                                            TextInput {
                                                id: replyInput
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 12
                                                verticalAlignment: TextInput.AlignVCenter
                                                color: Theme.contentColour
                                                font.pixelSize: 11
                                                clip: true

                                                Keys.onReturnPressed: send()
                                                Keys.onEnterPressed: send()

                                                function send(): void {
                                                    if (card.hasNotif && typeof card.notification.sendInlineReply === "function")
                                                        card.notification.sendInlineReply(replyInput.text);
                                                    replyInput.text = "";
                                                }
                                            }
                                        }

                                        IconButton {
                                            iconName: "send"
                                            buttonSize: 30
                                            accessibleName: "Send reply"
                                            onTriggered: replyInput.send()
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true; implicitHeight: 16 }
                    }
                }
            }
        }
    }
}
