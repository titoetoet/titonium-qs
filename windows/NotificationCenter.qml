pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
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

        // Input mask only covers the drawer itself when open.
        // Clicks outside seamlessly hit TopBar widgets or TopBar scrim!
        mask: Region {
            item: ncWindow.isThisScreenOpen ? panelRoot : null
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
                radius: Theme.innerRadius
                antialiasing: true

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.surfaceColour }
                    GradientStop { position: 1.0; color: Theme.surfaceColourBottom }
                }

                border.width: 1
                border.color: Theme.popupBorder

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 32
                    shadowBlur: 0.65
                    shadowVerticalOffset: 8
                    shadowColor: Theme.popupShadowColour
                }

                // Layer 1: Top Ambient Caustic Glow (Soft liquid glass diffusion)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: 36
                    radius: Theme.innerRadius - 1
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.30 : 0.12) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // Layer 2: Thanh đèn giả lập (Specular Rim Sheen)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 1
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    height: 1.5
                    radius: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.2; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.40 : 0.25) }
                        GradientStop { position: 0.5; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.85 : 0.70) }
                        GradientStop { position: 0.8; color: Qt.alpha("#ffffff", Theme.themeName === "light" ? 0.40 : 0.25) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
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
                        height: 34
                        radius: 12
                        color: Qt.alpha(Theme.contentColour, 0.06)

                        // Sliding indicator
                        Rectangle {
                            x: ncWindow.currentTab === 0 ? 2 : parent.width / 2
                            y: 2
                            width: parent.width / 2 - 2
                            height: parent.height - 4
                            radius: 10
                            color: Qt.alpha(Theme.contentColour, 0.14)
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
                                        spacing: 6

                                        Text {
                                            text: tabItem.modelData
                                            color: tabItem.isActive ? Theme.contentColour : Qt.alpha(Theme.contentColour, 0.55)
                                            font.family: Typography.fontFamily
                                            font.pixelSize: 12
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

                    Item { Layout.fillWidth: true; implicitHeight: 12 }

                    // ── 1. Naked Weather Section (Single Seamless Surface) ─────
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 18; Layout.rightMargin: 18
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            MaterialIcon {
                                iconName: WeatherService.iconName
                                iconSize: 34
                                iconColour: WeatherService.iconColour

                                Behavior on iconColour { ColorAnimation { duration: Metrics.animFast } }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: WeatherService.temperatureText
                                    color: Theme.contentColour
                                    font.family: Typography.fontFamily
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: WeatherService.description
                                    color: Qt.alpha(Theme.contentColour, 0.55)
                                    font.family: Typography.fontFamily
                                    font.pixelSize: 11
                                }
                            }

                            Text {
                                text: WeatherService.location
                                color: Qt.alpha(Theme.contentColour, 0.45)
                                font.family: Typography.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }

                        // Weather Sub-metrics (Humidity, Feels like, Wind)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            RowLayout {
                                spacing: 4
                                MaterialIcon {
                                    iconName: "water_drop"
                                    iconSize: 14
                                    iconColour: "#8be9fd" // Dracula Cyan
                                }
                                Text {
                                    text: WeatherService.humidity + "%"
                                    color: Qt.alpha(Theme.contentColour, 0.50)
                                    font.family: Typography.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }
                            }

                            RowLayout {
                                spacing: 4
                                MaterialIcon {
                                    iconName: "thermostat"
                                    iconSize: 14
                                    iconColour: "#ffb86c" // Dracula Orange
                                }
                                Text {
                                    text: "Feels " + (Number.isFinite(WeatherService.feelsLike) ? Math.round(WeatherService.feelsLike) + "°" : "--°")
                                    color: Qt.alpha(Theme.contentColour, 0.50)
                                    font.family: Typography.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }
                            }

                            RowLayout {
                                spacing: 4
                                MaterialIcon {
                                    iconName: "air"
                                    iconSize: 14
                                    iconColour: "#6272a4" // Dracula Comment Blue
                                }
                                Text {
                                    text: Math.round(WeatherService.windSpeed) + " km/h"
                                    color: Qt.alpha(Theme.contentColour, 0.50)
                                    font.family: Typography.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 12 }

                    // Soft Refractive Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20; Layout.rightMargin: 20
                        implicitHeight: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: Qt.alpha(Theme.contentColour, 0.08) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 12 }

                    // ── 2. Naked Calendar Section with Lunar Calendar (Âm Lịch) ────
                    ColumnLayout {
                        id: calCol
                        Layout.fillWidth: true
                        Layout.leftMargin: 18; Layout.rightMargin: 18
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: weekDayNames[now.getDay()]
                                color: Qt.alpha(Theme.contentColour, 0.50)
                                font.family: Typography.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }

                            RowLayout {
                                spacing: 8

                                Text {
                                    text: monthNames[todayMonth] + " " + todayDay + ", " + todayYear
                                    color: Theme.contentColour
                                    font.family: Typography.fontFamily
                                    font.pixelSize: 19
                                    font.weight: Font.Light
                                }

                                Text {
                                    readonly property var curLunar: LunarService.convertSolar2Lunar(todayDay, todayMonth + 1, todayYear)
                                    text: "·  " + curLunar.day + "/" + curLunar.month + " Âm (" + curLunar.yearName + ")"
                                    color: "#8be9fd" // Dracula Cyan
                                    font.family: Typography.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            IconButton {
                                iconName: "chevron_left"
                                buttonSize: 26
                                accessibleName: "Previous month"
                                onTriggered: displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() - 1, 1)
                            }

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: Qt.formatDate(displayedMonth, "MMMM yyyy")
                                color: Theme.contentColour
                                font.family: Typography.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            IconButton {
                                iconName: "chevron_right"
                                buttonSize: 26
                                accessibleName: "Next month"
                                onTriggered: displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + 1, 1)
                            }
                        }

                        DayOfWeekRow {
                            Layout.fillWidth: true
                            locale: Qt.locale()
                            spacing: 2
                            delegate: Text {
                                required property var model
                                horizontalAlignment: Text.AlignHCenter
                                text: model.shortName
                                color: Qt.alpha(Theme.contentColour, 0.40)
                                font.family: Typography.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                        }

                        MonthGrid {
                            id: monthGrid
                            Layout.fillWidth: true
                            Layout.preferredHeight: 210
                            month: displayedMonth.getMonth()
                            year: displayedMonth.getFullYear()
                            locale: Qt.locale()
                            spacing: 2

                            delegate: Item {
                                id: dayCell
                                required property var model

                                readonly property var lunarData: LunarService.convertSolar2Lunar(dayCell.model.day, dayCell.model.month + 1, dayCell.model.year)
                                readonly property bool isCurrentMonth: dayCell.model.month === displayedMonth.getMonth()
                                readonly property bool isToday: dayCell.model.today

                                // Background pill (Today highlight or hover pill) - Symmetrically centered
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width - 2, 44)
                                    height: parent.height - 2
                                    radius: 7
                                    color: dayCell.isToday
                                        ? Theme.accentColour
                                        : (cellMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.08) : "transparent")

                                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }
                                }

                                // Solar Day (Lịch Dương - Số to rõ ràng, nằm ở tâm ô)
                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -3
                                    text: dayCell.model.day
                                    color: dayCell.isToday ? "#ffffff"
                                        : dayCell.isCurrentMonth ? Theme.contentColour : Qt.alpha(Theme.contentColour, 0.22)
                                    font.family: Typography.fontFamily
                                    font.pixelSize: 13
                                    font.weight: dayCell.isToday ? Font.Bold : (dayCell.isCurrentMonth ? Font.DemiBold : Font.Normal)
                                }

                                // Lunar Day (Lịch Âm - Số nhỏ gọn, nằm phía dưới và lệch nhẹ sang phải 6px)
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.horizontalCenterOffset: 6
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2
                                    text: dayCell.lunarData.displayText
                                    color: dayCell.isToday
                                        ? Qt.alpha("#ffffff", 0.95)
                                        : dayCell.lunarData.isSpecial
                                            ? "#ff79c6" // Dracula Pink rực rỡ cho Mùng 1 & Rằm 15
                                            : (dayCell.isCurrentMonth ? "#f1fa8c" : Qt.alpha("#f1fa8c", 0.30)) // Dracula Gold (#f1fa8c)
                                    font.family: Typography.fontFamily
                                    font.pixelSize: 8
                                    font.weight: (dayCell.lunarData.isSpecial || dayCell.isToday) ? Font.Bold : Font.Medium
                                }

                                MouseArea {
                                    id: cellMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 10 }

                    // Soft Refractive Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20; Layout.rightMargin: 20
                        implicitHeight: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: Qt.alpha(Theme.contentColour, 0.08) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 10 }

                    // ── 3. Daily Lunar Wisdom Quote (Song ngữ Anh - Việt) ────
                    ColumnLayout {
                        id: quoteBox
                        Layout.fillWidth: true
                        Layout.leftMargin: 18; Layout.rightMargin: 18
                        spacing: 4

                        readonly property var dailyQuote: LunarService.getDailyQuote(todayDay, todayMonth + 1, todayYear)

                        RowLayout {
                            spacing: 6
                            MaterialIcon {
                                iconName: "auto_awesome"
                                iconSize: 13
                                iconColour: "#bd93f9" // Dracula Purple
                            }
                            Text {
                                text: I18n.t("wisdom.header")
                                color: Qt.alpha(Theme.contentColour, 0.45)
                                font.family: Typography.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }

                        // Primary Quote (follows I18n locale)
                        Text {
                            Layout.fillWidth: true
                            text: "“" + (I18n.locale === "vi" ? quoteBox.dailyQuote.vi : quoteBox.dailyQuote.en) + "”"
                            color: Qt.alpha(Theme.contentColour, 0.90)
                            font.family: Typography.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            wrapMode: Text.WordWrap
                            lineHeight: 1.25
                        }

                        // Secondary Translation (bilingual subtitle)
                        Text {
                            Layout.fillWidth: true
                            text: I18n.locale === "vi" ? quoteBox.dailyQuote.en : quoteBox.dailyQuote.vi
                            color: Qt.alpha(Theme.contentColour, 0.50)
                            font.family: Typography.fontFamily
                            font.pixelSize: 10
                            font.italic: true
                            wrapMode: Text.WordWrap
                            lineHeight: 1.2
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 10 }

                    // ── 4. Naked Upcoming Events (Single Seamless Surface) ─────
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 18; Layout.rightMargin: 18
                        spacing: 6

                        Text {
                            text: "Upcoming"
                            color: Qt.alpha(Theme.contentColour, 0.50)
                            font.family: Typography.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Repeater {
                            model: [
                                { time: "10:00 AM", title: "Team Standup",       color: "#ffb86c" },
                                { time: "2:00 PM",  title: "Design Review",      color: "#8be9fd" },
                                { time: "7:00 PM",  title: "Dinner reservation", color: "#bd93f9" }
                            ]
                            Rectangle {
                                id: ev
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 40
                                radius: 8
                                color: evMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.08) : "transparent"

                                Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 10

                                    // Minimal Accent Bead
                                    Rectangle {
                                        width: 4
                                        height: 18
                                        radius: 2
                                        color: ev.modelData.color
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: ev.modelData.title
                                        color: Theme.contentColour
                                        font.family: Typography.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        text: ev.modelData.time
                                        color: Qt.alpha(Theme.contentColour, 0.55)
                                        font.family: Typography.fontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: evMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 10 }

                    // Soft Refractive Divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20; Layout.rightMargin: 20
                        implicitHeight: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: Qt.alpha(Theme.contentColour, 0.08) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    Item { Layout.fillWidth: true; implicitHeight: 10 }

                    // ── 5. Live Google News Section ────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 18; Layout.rightMargin: 18
                        spacing: 8

                        // News Header Row with Category Selector & Refresh Button
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: I18n.t("news.header")
                                color: Qt.alpha(Theme.contentColour, 0.50)
                                font.family: Typography.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            // Category Switcher Pills
                            RowLayout {
                                spacing: 4

                                Repeater {
                                    model: NewsService.categories

                                    Rectangle {
                                        id: catBtn
                                        required property var modelData
                                        readonly property bool isSelected: NewsService.currentCategory === catBtn.modelData.id

                                        implicitHeight: 22
                                        implicitWidth: catTxt.implicitWidth + 12
                                        radius: 6
                                        color: isSelected
                                            ? Qt.alpha(catBtn.modelData.color, 0.22)
                                            : (catMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.08) : "transparent")
                                        border.width: isSelected ? 1 : 0
                                        border.color: isSelected ? Qt.alpha(catBtn.modelData.color, 0.50) : "transparent"

                                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                                        Text {
                                            id: catTxt
                                            anchors.centerIn: parent
                                            text: (catBtn.modelData && catBtn.modelData.nameKey) ? I18n.t(catBtn.modelData.nameKey) : ""
                                            color: catBtn.isSelected
                                                ? (catBtn.modelData?.color || Theme.accentColour)
                                                : Qt.alpha(Theme.contentColour, catMouse.containsMouse ? 0.85 : 0.45)
                                            font.family: Typography.fontFamily
                                            font.pixelSize: 10
                                            font.weight: catBtn.isSelected ? Font.DemiBold : Font.Normal

                                            Behavior on color { ColorAnimation { duration: Metrics.animFast } }
                                        }

                                        MouseArea {
                                            id: catMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NewsService.fetchNews(catBtn.modelData.id)
                                        }
                                    }
                                }
                            }

                            // Refresh Button
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 11
                                color: refMouse.containsMouse ? Qt.alpha(Theme.contentColour, 0.12) : "transparent"

                                Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                                MaterialIcon {
                                    id: refIcon
                                    anchors.centerIn: parent
                                    iconName: "refresh"
                                    iconSize: 13
                                    iconColour: NewsService.loading ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.50)

                                    NumberAnimation on rotation {
                                        running: NewsService.loading
                                        from: 0
                                        to: 360
                                        duration: 800
                                        loops: Animation.Infinite
                                    }
                                }

                                MouseArea {
                                    id: refMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NewsService.fetchNews(NewsService.currentCategory, true)
                                }
                            }
                        }

                        // Loading / Error / Article List
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            // Loading state
                            Item {
                                Layout.fillWidth: true
                                implicitHeight: 40
                                visible: NewsService.loading && NewsService.articles.length === 0

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    MaterialIcon {
                                        iconName: "sync"
                                        iconSize: 16
                                        iconColour: Theme.accentColour
                                    }
                                    Text {
                                        text: I18n.t("news.loading")
                                        color: Qt.alpha(Theme.contentColour, 0.55)
                                        font.family: Typography.fontFamily
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            // Articles Repeater
                            Repeater {
                                model: NewsService.articles

                                NewsCard {
                                    required property var modelData
                                    headline: modelData.headline
                                    source: modelData.source
                                    time: modelData.time
                                    accent: modelData.accent
                                    link: modelData.link
                                }
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
                    Layout.leftMargin: 16; Layout.rightMargin: 16
                    Layout.topMargin: 6; Layout.bottomMargin: 6

                    Text {
                        Layout.fillWidth: true
                        text: NotificationService.count > 0
                            ? NotificationService.count + " Notification" + (NotificationService.count !== 1 ? "s" : "")
                            : "Notifications"
                        color: Qt.alpha(Theme.contentColour, 0.50)
                        font.family: Typography.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        visible: NotificationService.count > 0
                        implicitHeight: 24
                        implicitWidth: clrTxt.implicitWidth + 16
                        radius: 8
                        color: clrMa.containsMouse ? Qt.alpha(Theme.contentColour, 0.12) : "transparent"

                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                        Text {
                            id: clrTxt
                            anchors.centerIn: parent
                            text: "Clear All"
                            color: Theme.accentColour
                            font.family: Typography.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: clrMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.clearAll()
                        }
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
                                    iconColour: Qt.alpha(Theme.contentColour, 0.25); fill: 0
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "No notifications"
                                    color: Qt.alpha(Theme.contentColour, 0.40)
                                    font.family: Typography.fontFamily
                                    font.pixelSize: 12
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
                                radius: 12
                                color: Qt.alpha(Theme.contentColour, 0.05)
                                border.width: 1
                                border.color: Qt.alpha(Theme.contentColour, 0.06)

                                // Urgency accent bar
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 4
                                    width: 3
                                    radius: 1.5
                                    color: card.critical ? "#ff5555"
                                        : (card.hasNotif && card.notification.urgency === NotificationUrgency.Low)
                                            ? Qt.alpha(Theme.contentColour, 0.20)
                                            : Theme.accentColour
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
                                            text: card.appLabel
                                            color: Qt.alpha(Theme.contentColour, 0.55)
                                            font.family: Typography.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: card.hasNotif ? formatRelative(NotificationService.receivedTime(card.notification.id), viewClock.date) : ""
                                            color: Qt.alpha(Theme.contentColour, 0.45)
                                            font.family: Typography.fontFamily
                                            font.pixelSize: 10
                                        }

                                        Item {
                                            width: 20; height: 20
                                            Rectangle {
                                                anchors.fill: parent; radius: 10
                                                color: cardDismiss.containsMouse ? Qt.alpha(Theme.contentColour, 0.14) : "transparent"
                                                Behavior on color { ColorAnimation { duration: Metrics.animFast } }
                                            }
                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                iconName: "close"; iconSize: 13
                                                iconColour: Qt.alpha(Theme.contentColour, 0.60)
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
                                        font.family: Typography.fontFamily
                                        font.pixelSize: 12; font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        visible: text.length > 0
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: card.notifBody
                                        color: Qt.alpha(Theme.contentColour, 0.65)
                                        font.family: Typography.fontFamily
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 4
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                        visible: text.length > 0
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

                                                required property var modelData

                                                readonly property bool hasAction: actionBtn.modelData !== null && actionBtn.modelData !== undefined

                                                implicitHeight: 26
                                                implicitWidth: actionLabel.implicitWidth + 18
                                                radius: 8
                                                color: actionPointer.containsMouse
                                                    ? Qt.alpha(Theme.contentColour, 0.14)
                                                    : Qt.alpha(Theme.contentColour, 0.07)

                                                Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                                                Text {
                                                    id: actionLabel
                                                    anchors.centerIn: parent
                                                    text: actionBtn.hasAction ? (actionBtn.modelData.text || "") : ""
                                                    color: Theme.contentColour
                                                    font.family: Typography.fontFamily
                                                    font.pixelSize: 11
                                                    font.weight: Font.Medium
                                                }

                                                MouseArea {
                                                    id: actionPointer
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (actionBtn.hasAction && card.hasNotif) {
                                                            NotificationService.invokeAction(card.notification, actionBtn.modelData);
                                                            NotificationService.close();
                                                        }
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

                                // Card Body Click Handler (Click card to focus app)
                                MouseArea {
                                    anchors.fill: parent
                                    z: -1
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (card.hasNotif) {
                                            NotificationService.invokeAction(card.notification, card.notification.defaultAction);
                                            NotificationService.close();
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

        HyprlandFocusGrab {
            active: ncWindow.isThisScreenOpen
            windows: [ncWindow]
            onCleared: NotificationService.close()
        }
    }
}
