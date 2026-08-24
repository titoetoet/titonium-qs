pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var activeScreen: null
    property bool open: activeScreen !== null

    function toggle(targetScreen): void {
        if (activeScreen === targetScreen) {
            activeScreen = null;
        } else {
            activeScreen = targetScreen;
        }
    }

    function close(): void {
        activeScreen = null;
    }

    // Emitted whenever a new notification arrives (used by the popup toast layer).
    signal notificationReceived(var notification)

    // Emitted when Notification Center opens, clearing floating toasts
    signal clearAllToastsRequested()

    // ── Notification daemon ─────────────────────────────────────────────────
    NotificationServer {
        id: server

        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true
    }

    // Persistent storage list: Notifications remain FOREVER in panel
    // until explicitly dismissed by the user (or Clear All).
    property var list: []
    readonly property var notifications: list
    readonly property int count: list.length
    readonly property bool hasNotifications: count > 0

    // Per-notification timestamp bookkeeping (id -> timestamp).
    property var receivedAt: ({})

    function track(notification): void {
        if (!notification || !notification.id) return;
        notification.tracked = true;
        receivedAt[notification.id] = Date.now();

        const current = [...root.list];
        const exists = current.some(n => n && n.id === notification.id);
        if (!exists) {
            current.unshift(notification);
            root.list = current;
        }

        notificationReceived(notification);
    }

    function receivedTime(id: int): date {
        const t = receivedAt[id];
        return t !== undefined ? new Date(t) : new Date();
    }

    function dismiss(notification): void {
        if (!notification) return;
        try {
            notification.dismiss();
        } catch (e) {}
        dismissById(notification.id);
    }

    function dismissById(id: int): void {
        const current = [...root.list];
        const idx = current.findIndex(n => n && n.id === id);
        if (idx !== -1) {
            current.splice(idx, 1);
            root.list = current;
        }
    }

    function clearAll(): void {
        const snapshot = [...root.list];
        root.list = [];
        for (const n of snapshot) {
            try {
                if (n && typeof n.dismiss === "function") {
                    n.dismiss();
                }
            } catch (e) {}
        }
    }

    Connections {
        target: server

        function onNotification(notification): void {
            root.track(notification);
        }
    }
}
