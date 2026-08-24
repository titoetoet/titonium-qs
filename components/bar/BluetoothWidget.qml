pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQml.Models
import Quickshell
import Quickshell.Bluetooth
import "../../config"
import "../primitives"
import "../popups"

Item {
    id: root

    property bool expanded: false
    readonly property Item inputRegion: dropdown.inputRegion
    readonly property var adapter: Bluetooth.defaultAdapter
    property ListModel devices: ListModel {}

    readonly property bool hasConnectedDevice: {
        try {
            if (!Bluetooth || !Bluetooth.devices || !Bluetooth.devices.values) return false;
            const vals = Bluetooth.devices.values;
            for (let i = 0; i < vals.length; i++) {
                if (vals[i] && vals[i].connected) return true;
            }
        } catch (e) {}
        return false;
    }

    function refreshDevices(): void {
        if (!Bluetooth || !Bluetooth.devices || !Bluetooth.devices.values) return;
        let next;
        try {
            const vals = Bluetooth.devices.values;
            const arr = [];
            for (let i = 0; i < vals.length; i++) {
                if (vals[i] !== null && vals[i] !== undefined)
                    arr.push(vals[i]);
            }
            next = arr
                .sort((a, b) => ((b.connected ?? 0) - (a.connected ?? 0))
                    || ((b.paired ?? 0) - (a.paired ?? 0))
                    || String(a.name || "").localeCompare(String(b.name || "")))
                .slice(0, 5);
        } catch (e) {
            return;
        }

        // Drop rows whose device left the list.
        for (let i = root.devices.count - 1; i >= 0; i--) {
            const dev = root.devices.get(i).device;
            if (!next.some(d => d === dev))
                root.devices.remove(i);
        }

        // Align order and append new devices. insert/remove/move mutate
        // ListModel rows without recreating delegates, so hover on existing
        // rows survives a scan.
        let pos = 0;
        for (let ni = 0; ni < next.length; ni++) {
            const nd = next[ni];
            let found = -1;
            for (let ci = pos; ci < root.devices.count; ci++) {
                if (root.devices.get(ci).device === nd) {
                    found = ci;
                    break;
                }
            }
            if (found >= 0) {
                if (found !== pos)
                    root.devices.move(found, pos, 1);
                pos++;
            } else {
                root.devices.insert(pos, { device: nd });
                pos++;
            }
        }
    }

    // Update the model only when the device set changes. Sorting inside a
    // binding would also capture connected/paired/name and rebuild the Repeater
    // on every property update, resetting hover state.
    Connections {
        target: Bluetooth.devices
        function onValuesChanged(): void {
            root.refreshDevices();
        }
    }

    Component.onCompleted: refreshDevices()

    implicitWidth: dropdown.implicitWidth
    implicitHeight: dropdown.implicitHeight

    BarDropdown {
        id: dropdown

        expanded: root.expanded
        collapsedWidth: Theme.widgetHeight
        surfaceWidth: 320
        surfaceHeight: content.implicitHeight + 24

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 12

            // ── 1. Master Control Row (Clean Single Surface) ─────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialIcon {
                    iconName: !(root.adapter?.enabled ?? false) ? "bluetooth_disabled"
                        : root.hasConnectedDevice ? "bluetooth_connected" : "bluetooth"
                    iconSize: 19
                    iconColour: (root.adapter?.enabled ?? false)
                        ? (root.hasConnectedDevice ? Theme.contentColour : Theme.onSurfaceVariantColour)
                        : Theme.onSurfaceVariantColour
                }

                // Label & Status
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Bluetooth"
                        color: Theme.contentColour
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeTitleSm
                        font.weight: Typography.weightBold
                    }

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: !(root.adapter?.enabled ?? false) ? "Off"
                            : root.hasConnectedDevice ? "Connected" : "On"
                        color: Qt.alpha(Theme.contentColour, 0.65)
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.sizeCaption
                    }
                }

                // Master Cupertino Toggle Pill
                Rectangle {
                    width: 38
                    height: 22
                    radius: 11
                    color: (root.adapter?.enabled ?? false) ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.20)

                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                    Rectangle {
                        id: btKnob
                        x: (root.adapter?.enabled ?? false) ? parent.width - width - 3 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: btMouse.pressed ? 19 : 16
                        height: 16
                        radius: 8
                        color: "#ffffff"

                        Behavior on x {
                            NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
                        }
                        Behavior on width {
                            NumberAnimation { duration: Metrics.animFast; easing.type: Easing.OutQuad }
                        }
                    }

                    MouseArea {
                        id: btMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.adapter)
                                root.adapter.enabled = !root.adapter.enabled;
                        }
                    }
                }
            }

            // Discovering Sub-row (when enabled)
            Rectangle {
                Layout.fillWidth: true
                visible: root.adapter?.enabled ?? false
                implicitHeight: 28
                radius: 8
                color: Qt.alpha(Theme.contentColour, 0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    MaterialIcon {
                        iconName: "radar"
                        iconSize: 15
                        iconColour: (root.adapter?.discovering ?? false) ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.55)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Discovering"
                        color: Theme.contentColour
                        font.family: Typography.fontFamily
                        font.pixelSize: 11
                    }

                    Rectangle {
                        width: 28
                        height: 16
                        radius: 8
                        color: (root.adapter?.discovering ?? false) ? Theme.accentColour : Qt.alpha(Theme.contentColour, 0.20)

                        Rectangle {
                            x: (root.adapter?.discovering ?? false) ? parent.width - width - 2 : 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12
                            height: 12
                            radius: 6
                            color: "#ffffff"

                            Behavior on x {
                                NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.adapter)
                                    root.adapter.discovering = !root.adapter.discovering;
                            }
                        }
                    }
                }
            }

            // Soft Refractive Divider Line
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                height: 1
                visible: root.adapter?.enabled ?? false
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.alpha(Theme.contentColour, 0.08) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // ── 2. Devices List (Fluid Pills) ──────────────
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.adapter?.enabled ?? false
                spacing: 3

                // Header row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    Layout.bottomMargin: 2

                    Text {
                        Layout.fillWidth: true
                        text: "Devices"
                        color: Qt.alpha(Theme.contentColour, 0.50)
                        font.family: Typography.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: root.devices.count + (root.devices.count === 1 ? " device" : " devices")
                        color: Qt.alpha(Theme.contentColour, 0.45)
                        font.family: Typography.fontFamily
                        font.pixelSize: 10
                    }
                }

                // Empty state
                Text {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    visible: root.devices.count === 0
                    text: "No paired or nearby devices"
                    color: Theme.onSurfaceVariantColour
                    font.family: Typography.fontFamily
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }

                // Device rows
                Repeater {
                    model: root.devices

                    delegate: Rectangle {
                        id: deviceRow

                        required property var device

                        readonly property bool hasDev: deviceRow.device !== null && deviceRow.device !== undefined
                        readonly property bool isConn: hasDev && (deviceRow.device.connected ?? false)
                        readonly property string devIcon: hasDev && deviceRow.device.icon ? deviceRow.device.icon : ""
                        readonly property string devName: hasDev ? (deviceRow.device.name || "Unknown device") : ""
                        readonly property var devState: hasDev ? deviceRow.device.state : null

                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 10
                        color: isConn
                            ? Qt.alpha(Theme.contentColour, 0.14)
                            : (pointer.containsMouse ? Qt.alpha(Theme.contentColour, 0.07) : "transparent")

                        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            MaterialIcon {
                                iconName: deviceRow.devIcon.indexOf("head") >= 0
                                    ? "headphones" : "bluetooth"
                                iconSize: 17
                                iconColour: deviceRow.isConn ? Theme.contentColour : Qt.alpha(Theme.contentColour, 0.55)
                            }

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: deviceRow.devName
                                color: Theme.contentColour
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeBody
                                font.weight: deviceRow.isConn ? Typography.weightMedium : Typography.weightNormal
                            }

                            Text {
                                visible: deviceRow.devState === BluetoothDeviceState.Connecting
                                    || deviceRow.devState === BluetoothDeviceState.Disconnecting
                                text: deviceRow.devState === BluetoothDeviceState.Connecting
                                    ? "Connecting…" : "Disconnecting…"
                                color: Qt.alpha(Theme.contentColour, 0.50)
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.sizeMicro
                            }

                            MaterialIcon {
                                visible: deviceRow.isConn
                                iconName: "check"
                                iconSize: 16
                                iconColour: Theme.contentColour
                            }
                        }

                        MouseArea {
                            id: pointer
                            anchors.fill: parent
                            enabled: deviceRow.hasDev
                                && deviceRow.devState !== BluetoothDeviceState.Connecting
                                && deviceRow.devState !== BluetoothDeviceState.Disconnecting
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!deviceRow.hasDev) return;
                                if (deviceRow.isConn)
                                    deviceRow.device.disconnect();
                                else
                                    deviceRow.device.connect();
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: triggerButton

        anchors.top: parent.top
        anchors.right: parent.right
        implicitWidth: Theme.widgetHeight
        implicitHeight: Theme.widgetHeight
        radius: height / 2
        color: root.expanded
            ? Qt.alpha(Theme.contentColour, 0.14)
            : triggerPointer.containsMouse
                ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.08))
                : "transparent"

        Behavior on color { ColorAnimation { duration: Metrics.animFast } }

        MaterialIcon {
            anchors.centerIn: parent
            iconName: !root.adapter?.enabled ? "bluetooth_disabled"
                : root.hasConnectedDevice
                    ? "bluetooth_connected" : "bluetooth"
            iconSize: 19
            iconColour: root.adapter?.enabled ? Theme.contentColour : Theme.onSurfaceVariantColour
        }

        MouseArea {
            id: triggerPointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

        Accessible.role: Accessible.Button
        Accessible.name: "Bluetooth"
    }
}
