pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

    function refreshDevices(): void {
        const next = [...Bluetooth.devices.values]
            .sort((a, b) => (b.connected - a.connected)
                || (b.paired - a.paired) || a.name.localeCompare(b.name))
            .slice(0, 5);

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
            anchors.margins: 12
            spacing: 8

            Text {
                text: "Bluetooth"
                color: Theme.contentColour
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            ToggleSwitch {
                id: enabledToggle
                Layout.fillWidth: true
                label: "Enabled"
                checked: root.adapter?.enabled ?? false
                onTriggered: {
                    if (root.adapter)
                        root.adapter.enabled = !root.adapter.enabled;
                }
            }

            ToggleSwitch {
                id: discoveringToggle
                Layout.fillWidth: true
                label: "Discovering"
                checked: root.adapter?.discovering ?? false
                enabled: root.adapter?.enabled ?? false
                onTriggered: {
                    if (root.adapter)
                        root.adapter.discovering = !root.adapter.discovering;
                }
            }

            Text {
                Layout.topMargin: 4
                text: root.devices.count + (root.devices.count === 1 ? " device" : " devices") + " available"
                color: Theme.onSurfaceVariantColour
                font.pixelSize: 11
            }

            Repeater {
                model: root.devices

                Rectangle {
                    id: deviceRow

                    required property var device

                    readonly property bool hasDev: deviceRow.device !== null && deviceRow.device !== undefined
                    readonly property bool isConn: hasDev && (deviceRow.device.connected ?? false)
                    readonly property string devIcon: hasDev && deviceRow.device.icon ? deviceRow.device.icon : ""
                    readonly property string devName: hasDev ? (deviceRow.device.name || "Unknown device") : ""
                    readonly property var devState: hasDev ? deviceRow.device.state : null

                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 16
                    color: isConn
                        ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.12))
                        : pointer.containsMouse
                            ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.12))
                            : "transparent"
                    border.width: pointer.containsMouse ? 1 : 0
                    border.color: Qt.alpha(Theme.contentColour, 0.25)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        MaterialIcon {
                            iconName: deviceRow.devIcon.indexOf("head") >= 0
                                ? "headphones" : "bluetooth"
                            iconSize: 18
                            iconColour: Theme.contentColour
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: deviceRow.devName
                            color: Theme.contentColour
                            font.pixelSize: 11
                        }

                        MaterialIcon {
                            iconName: deviceRow.isConn ? "link_off" : "link"
                            iconSize: 17
                            iconColour: deviceRow.isConn
                                ? Theme.accentColour : Theme.contentColour
                        }

                        Text {
                            visible: deviceRow.devState === BluetoothDeviceState.Connecting
                                || deviceRow.devState === BluetoothDeviceState.Disconnecting
                            text: deviceRow.devState === BluetoothDeviceState.Connecting
                                ? "Connecting…" : "Disconnecting…"
                            color: Theme.onSurfaceVariantColour
                            font.pixelSize: 10
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
                            if (deviceRow.hasDev)
                                deviceRow.device.connected = !deviceRow.device.connected;
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
        color: triggerPointer.containsMouse
            ? Qt.tint(Theme.surfaceContainerColour, Qt.alpha(Theme.contentColour, 0.08))
            : "transparent"

        MaterialIcon {
            anchors.centerIn: parent
            iconName: !root.adapter?.enabled ? "bluetooth_disabled"
                : Bluetooth.devices.values.some(device => device.connected)
                    ? "bluetooth_connected" : "bluetooth"
            iconSize: 19
            iconColour: Theme.contentColour
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
