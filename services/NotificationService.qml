pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
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

    // Persistent storage list: Notifications remain in panel
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

    // ── Focus window & Event Source Routing ─────────────────────────────────
    function activateAppWindow(appName, desktopEntry, appIcon): void {
        const candidates = [
            (desktopEntry || "").toLowerCase().trim(),
            (appName || "").toLowerCase().trim(),
            (appIcon || "").toLowerCase().trim()
        ].filter(s => s.length > 0);

        if (candidates.length === 0) return;

        // 1. Check running Wayland toplevels via ToplevelManager
        try {
            const toplevels = ToplevelManager.toplevels?.values ?? [];
            for (let i = 0; i < toplevels.length; i++) {
                const tl = toplevels[i];
                if (!tl) continue;
                const appId = (tl.appId || "").toLowerCase();
                const title = (tl.title || "").toLowerCase();

                for (const cand of candidates) {
                    if ((appId && (appId === cand || appId.includes(cand) || cand.includes(appId)))
                        || (title && title.includes(cand))) {
                        tl.activate();
                        return;
                    }
                }
            }
        } catch (e) {
            console.warn("ToplevelManager activation error:", e);
        }

        // 2. Hyprland IPC fallback: dispatch focuswindow
        for (const cand of candidates) {
            const clean = cand.split(".")[0].replace(/[^a-zA-Z0-9_-]/g, "");
            if (clean) {
                Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", clean]);
                return;
            }
        }
    }

    function invokeAction(notification, action): void {
        if (!notification) return;

        // 1. Invoke the D-Bus action callback if provided
        try {
            if (action && typeof action.invoke === "function") {
                action.invoke();
            } else if (notification.defaultAction && typeof notification.defaultAction.invoke === "function") {
                notification.defaultAction.invoke();
            }
        } catch (e) {
            console.warn("Notification action invoke error:", e);
        }

        // 2. Bring the originating application window to focus
        const appName = notification.appName || "";
        const desktopEntry = notification.desktopEntry || "";
        const appIcon = notification.appIcon || "";
        activateAppWindow(appName, desktopEntry, appIcon);

        // 3. Dismiss from active toasts
        dismiss(notification);
    }

    Connections {
        target: server

        function onNotification(notification): void {
            root.track(notification);
        }
    }
}
