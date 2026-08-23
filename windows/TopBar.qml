pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components/bar"
import "../config"
import "../services"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property ShellScreen modelData

        function closePopups(except: Item): void {
            if (except !== launcherWidget)
                launcherWidget.expanded = false;
            if (except !== mediaWidget)
                mediaWidget.expanded = false;
            if (except !== wifiWidget)
                wifiWidget.expanded = false;
            if (except !== bluetoothWidget)
                bluetoothWidget.expanded = false;
            if (except !== audioWidget)
                audioWidget.expanded = false;
            if (except !== monitorWidget)
                monitorWidget.expanded = false;
            if (except !== clockWidget)
                clockWidget.expanded = false;
            if (except !== notificationWidget)
                NotificationService.close();
        }

        screen: modelData

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        color: "transparent"

        WlrLayershell.namespace: "titonium-topbar"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top

        mask: Region {
            Region { item: launcherWidget.inputRegion }
            Region { item: workspaceWidget.inputRegion }
            Region { item: activeWindowWidget.inputRegion }
            Region { item: mediaWidget.inputRegion }
            Region { item: statusWidget }
            Region { item: notificationWidget.inputRegion }
            Region { item: wifiWidget.inputRegion }
            Region { item: bluetoothWidget.inputRegion }
            Region { item: audioWidget.inputRegion }
            Region { item: monitorWidget.inputRegion }
            Region { item: clockWidget.inputRegion }
        }



        LauncherWidget {
            id: launcherWidget

            anchors.left: parent.left
            anchors.leftMargin: Theme.barContentMargin
            y: (Theme.barHeight - Theme.widgetHeight) / 2
            onExpandedChanged: {
                if (expanded)
                    window.closePopups(launcherWidget);
            }
        }

        WorkspaceWidget {
            id: workspaceWidget

            screen: window.modelData
            anchors.left: parent.left
            anchors.leftMargin: Theme.barContentMargin + Theme.widgetHeight + Theme.widgetSpacing
            y: (Theme.barHeight - height) / 2
        }

        ActiveWindowWidget {
            id: activeWindowWidget

            anchors.left: workspaceWidget.right
            anchors.leftMargin: Theme.widgetSpacing
            anchors.right: mediaWidget.visible ? mediaWidget.left : statusWidget.left
            anchors.rightMargin: Theme.widgetSpacing
            y: (Theme.barHeight - Theme.widgetHeight) / 2
            height: Theme.widgetHeight
        }

        MediaWidget {
            id: mediaWidget

            anchors.horizontalCenter: parent.horizontalCenter
            y: (Theme.barHeight - Theme.widgetHeight) / 2
            onExpandedChanged: {
                if (expanded)
                    window.closePopups(mediaWidget);
            }
        }

        StatusWidget {
            id: statusWidget

            anchors.right: quickSettingsGroup.left
            anchors.rightMargin: Theme.widgetHeight + 2 * Theme.widgetSpacing
            y: (Theme.barHeight - height) / 2
        }

        MonitorWidget {
            id: monitorWidget

            anchors.right: quickSettingsGroup.left
            anchors.rightMargin: Theme.widgetSpacing
            y: (Theme.barHeight - Theme.widgetHeight) / 2
            onExpandedChanged: {
                if (expanded)
                    window.closePopups(monitorWidget);
            }
        }

        Rectangle {
            id: quickSettingsGroup

            anchors.right: notificationWidget.left
            anchors.rightMargin: Theme.widgetSpacing
            y: (Theme.barHeight - Theme.widgetHeight) / 2
            width: 3 * Theme.widgetHeight + 8
            height: Theme.widgetHeight
            radius: height / 2
            color: Theme.surfaceContainerColour

            WifiWidget {
                id: wifiWidget

                anchors.right: parent.right
                anchors.rightMargin: 2 * Theme.widgetHeight + 4
                anchors.top: parent.top
                onExpandedChanged: {
                    if (expanded)
                        window.closePopups(wifiWidget);
                }
            }

            BluetoothWidget {
                id: bluetoothWidget

                anchors.right: parent.right
                anchors.rightMargin: Theme.widgetHeight + 4
                anchors.top: parent.top
                onExpandedChanged: {
                    if (expanded)
                        window.closePopups(bluetoothWidget);
                }
            }

            AudioWidget {
                id: audioWidget

                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.top: parent.top
                onExpandedChanged: {
                    if (expanded)
                        window.closePopups(audioWidget);
                }
            }
        }

        NotificationWidget {
            id: notificationWidget

            screen: modelData
            anchors.right: clockWidget.left
            anchors.rightMargin: Theme.widgetSpacing
            y: (Theme.barHeight - Theme.widgetHeight) / 2
            onToggleRequested: {
                window.closePopups(notificationWidget);
                NotificationService.toggle(modelData);
            }
        }

        ClockWidget {
            id: clockWidget

            anchors.right: parent.right
            anchors.rightMargin: Theme.barContentMargin
            y: (Theme.barHeight - Theme.widgetHeight) / 2
            onExpandedChanged: {
                if (expanded)
                    window.closePopups(clockWidget);
            }
        }

        HyprlandFocusGrab {
            active: launcherWidget.expanded
            windows: [window]
            onCleared: launcherWidget.expanded = false
        }

        HyprlandFocusGrab {
            active: mediaWidget.expanded
            windows: [window]
            onCleared: mediaWidget.expanded = false
        }

        HyprlandFocusGrab {
            active: wifiWidget.expanded
            windows: [window]
            onCleared: wifiWidget.expanded = false
        }

        HyprlandFocusGrab {
            active: bluetoothWidget.expanded
            windows: [window]
            onCleared: bluetoothWidget.expanded = false
        }

        HyprlandFocusGrab {
            active: audioWidget.expanded
            windows: [window]
            onCleared: audioWidget.expanded = false
        }

        HyprlandFocusGrab {
            active: monitorWidget.expanded
            windows: [window]
            onCleared: monitorWidget.expanded = false
        }

        HyprlandFocusGrab {
            active: clockWidget.expanded
            windows: [window]
            onCleared: clockWidget.expanded = false
        }
    }
}
