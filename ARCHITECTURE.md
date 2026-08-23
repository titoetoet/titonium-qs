# Technical Architecture Specification — titonium

`titonium` is a high-performance, modular desktop shell environment engineered for **Wayland + Hyprland**, built upon the **Quickshell (Qt 6 / QML)** declarative engine.

---

## 1. System Architecture & Data Flow

```mermaid
graph TD
    subgraph OS_Layer ["Operating System & Hardware"]
        HW["Linux Kernel /sys, /proc"]
        DBUS["D-Bus (org.freedesktop.Notifications, MPRIS)"]
        HYPR["Hyprland IPC (hyprctl, sockets)"]
        PW["PipeWire / WirePlumber"]
        NM["NetworkManager (nmcli)"]
        CLIP["Wayland Clipboard (wl-paste, wl-copy)"]
    end

    subgraph Service_Layer ["Reactive Singleton Services (services/)"]
        ActiveWindowService
        AudioService
        ClipboardService
        NotificationService
        SettingsService
        SpotlightService
        SystemInfoService
        SystemStatusService
        WeatherService
        WindowSwitcherService
    end

    subgraph UI_Layer ["Windows & Components (windows/ & components/)"]
        ScreenFrame["ScreenFrame (WlrLayer.Bottom)"]
        BarExclusion["BarExclusionZone (WlrLayer.Top)"]
        TopBar["TopBar (WlrLayer.Top)"]
        Spotlight["Spotlight Launcher (WlrLayer.Overlay)"]
        NotificationCenter["NotificationCenter (WlrLayer.Overlay)"]
        NotificationPopup["NotificationPopup (WlrLayer.Overlay)"]
        WindowSwitcher["WindowSwitcher (WlrLayer.Overlay)"]
    end

    OS_Layer --> Service_Layer
    Service_Layer --> UI_Layer
```

### Architectural Principles:
1. **Unidirectional Data Flow**: Operating system state is polled or listened to via event-driven singletons in `services/`. UI components purely bind to exposed reactive properties; components never directly poll CLI commands.
2. **Dynamic Region Masking (`mask: Region`)**: Fullscreen overlay windows catch input clicks exclusively on interactive cards or dropdowns. Unfocused areas allow click-through transparency to underlying Hyprland tiled windows.
3. **Per-Screen Context Isolation**: Overlays (such as `NotificationCenter.qml` and `Spotlight.qml`) dynamically resolve `Hyprland.focusedMonitor` to render and capture keyboard focus exclusively on the active monitor.
4. **Zero Idle Overhead (Ref-Counted Polling)**: Hardware monitoring (CPU/GPU temperatures, memory deltas) and visualizer animations automatically pause when popups/dashboards are closed.

---

## 2. Windows & Layer-Shell Hierarchy

All top-level windows instantiate per monitor via `Variants { model: Quickshell.screens }`.

| Window | File | Layer | Namespace | Keyboard Focus | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Screen Frame** | `ScreenFrame.qml` | `Bottom` | `titonium-frame` | `None` | 2D Canvas rendering 5px rounded screen borders and top bar base |
| **Bar Exclusion**| `BarExclusionZone.qml` | `Top` | `titonium-bar-exclusion` | `None` | Reserves 40px exclusive zone for Hyprland window tiling |
| **TopBar** | `TopBar.qml` | `Top` | `titonium-topbar` | `None` | Primary status bar containing widgets and interactive dropdowns |
| **Spotlight** | `Spotlight.qml` | `Overlay` | `titonium-spotlight` | `Exclusive` (when open) | Universal floating search bar, Raycast Split-View clipboard, math calculator |
| **Notification Center** | `NotificationCenter.qml` | `Overlay` | `titonium-nc` | `None` | Slide-in drawer with Today tab, Calendar, and live Notification queue |
| **Notification Popup** | `NotificationPopup.qml` | `Overlay` | `titonium-notification-popup` | `None` | Toast notification overlay with auto-dismiss timeout |
| **Window Switcher** | `WindowSwitcher.qml` | `Overlay` | `titonium-window-switcher` | `Exclusive` (when open) | Alt+Tab visual multitasking window switcher |

---

## 3. Core Services Inventory (`services/`)

All services are declared as singletons via `pragma Singleton` and registered in `services/qmldir`.

### 1. `SpotlightService.qml`
- **Search Modes**:
  - `0 (All)`: 49+ system desktop applications (`DesktopEntries`), safe instant math evaluation, and system control actions.
  - `1 (Clipboard)`: Reactive clipboard search with Raycast-style 2-column Split-View.
  - `2 (Files)`: Quick directory shortcuts and document search.
- **Mode Cycling**: `Keys.onTabPressed` or chip click triggers `cycleMode()`.
- **IPC Interface**: `qs -c titonium ipc call spotlight toggle|open|close|clipboard`.

### 2. `ClipboardService.qml`
- **Capture Engine**: Background `Process` using `wl-paste --no-newline` with null-byte splitting (`splitMarker: "\0"`) preserving multiline paragraphs and code snippets intact.
- **Smart Content Classifier**: Automatically tags items as `url`, `color` (with live hex swatch preview), `code`, or `text`.
- **Metadata**: Tracks line count, word count, character count, and human-readable relative timestamps.
- **Capacity**: Maintains a rolling queue of up to 60 items.

### 3. `ActiveWindowService.qml`
- Tracks Hyprland's focused window via `hyprctl -j activewindow` (debounced 120ms).
- Heuristic icon resolution: StartupWMClass map ➔ `DesktopEntries.heuristicLookup` ➔ system theme icon fallback.

### 4. `AudioService.qml`
- Native PipeWire / WirePlumber node integration via Quickshell audio bindings.
- Exposes volume controls, mute toggling, and audio sink/source switching.

### 5. `SystemStatusService.qml`
- High-efficiency system resource monitor (`/proc/stat`, `/proc/meminfo`, sysfs GPU, `sensors -j`).
- Reference-counted lifecycle: Heavy polling only runs while consumers (`Dashboard`, `MonitorWidget`) hold an active lease (`acquireMonitoring()`).

### 6. `NotificationService.qml`
- Implements the `org.freedesktop.Notifications` D-Bus interface.
- Manages persistent notification retention in `server.trackedNotifications`, per-screen activations, and synchronized dismissal.

### 7. `SettingsService.qml`
- Persists user preferences and personalization settings (e.g. `avatarIcon`) to `~/.config/titonium/settings.json`.
- Event-driven two-way binding using `FileView` and atomic file serialization.

### 8. `SystemInfoService.qml`
- Hardware & environment specification retriever (`/proc/cpuinfo`, sysfs GPU devices, `hostname`, shell, pacman packages, Wayland compositor name).

### 9. `WindowSwitcherService.qml`
- Uses `ToplevelManager` to inspect, cycle, and activate running Wayland toplevel windows with fail-safe Hyprland submap resets.

---

## 4. UI Components Specification (`components/`)

### Bar Widgets (`components/bar/`):
- `LauncherWidget.qml`: Arch Linux icon button opening the Neofetch Dashboard and session control strip.
- `WorkspaceWidget.qml`: 5-cell workspace switcher synchronized with `Hyprland.monitorFor(screen)`.
- `ActiveWindowWidget.qml`: Running application badge with truncated window title and hover info panel.
- `MediaWidget.qml`: Audiophile media pill with real-time marquee and popup card featuring **48-bar dynamic spectrum visualizer** and seekbar.
- `StatusWidget.qml`: Input method badge (EN / VI).
- `MonitorWidget.qml`: System metrics dropdown (CPU, GPU, RAM, Load Average).
- `AudioWidget.qml`: Audio volume level, mute toggle, and device output switcher.
- `BluetoothWidget.qml`: Bluetooth adapter status, discovery, and paired device manager.
- `WifiWidget.qml`: NetworkManager Wi-Fi scanner and connection list.
- `ClockWidget.qml`: Digital clock and luxury **164px Analog Clock face** with Ho Chi Minh City timezone card.
- `NotificationWidget.qml`: Notification bell badge with unread counter.

### Primitives & Popups (`components/primitives/` & `components/popups/`):
- `AudioVisualizer.qml`: Harmonic 48-bar spectrum equalizer synthesizing rhythmic bass pulses and theme gradient transitions.
- `MaterialIcon.qml`: Material Symbols Rounded icon component with variable font axis scaling.
- `PopupPanel.qml`: Dropdown base with `MultiEffect` shadow and cubic opacity/scale animations.

---

## 5. Design Tokens, Theming & Localization (`config/`)

The design system and localization layer are strictly modularized into specialized singletons registered in `config/qmldir`:

### 1. `config/Metrics.qml` (Layout & Sizing Tokens)
- **Window & Card Dimensions**: `barHeight (40)`, `widgetHeight (30)`, `widgetSpacing (4)`, `innerRadius (16)`, `spotlightWidth (620)`, `spotlightSplitWidth (720)`, `spotlightSearchHeight (56)`, `spotlightItemHeight (52)`, `clockDialSize (164)`.
- **Spacings & Margins Scale**: `spacingXs (4)`, `spacingSm (8)`, `spacingMd (12)`, `spacingLg (16)`, `spacingXl (24)`.
- **Corner Radii Scale**: `radiusXs (4)`, `radiusSm (6)`, `radiusMd (8)`, `radiusLg (10)`, `radiusXl (14)`, `radiusCard (16)`, `radiusPill (20)`.
- **Animation Durations**: `animFast (120ms)`, `animNormal (180ms)`, `animSlow (260ms)`.

### 2. `config/Typography.qml` (Type Scale & Weights)
- **Font Families**: `fontFamily ("SF Pro Display")`, `monoFontFamily ("JetBrains Mono, SF Mono, monospace")`.
- **Type Scale**: `sizeMicro (10)`, `sizeCaption (11)`, `sizeBodySm (12)`, `sizeBody (13)`, `sizeBodyLg (14)`, `sizeTitleSm (16)`, `sizeTitle (18)`, `sizeTitleLg (22)`, `sizeDisplay (32)`.
- **Font Weights**: `weightNormal (400)`, `weightMedium (500)`, `weightDemiBold (600)`, `weightBold (700)`.

### 3. `config/I18n.qml` (Multilanguage Localization Prototype)
- Centralized string translation engine: `I18n.t(key, params)`.
- Default active locale: `"en"` with full dictionary namespace (`spotlight.*`, `action.*`, `time.*`, `clipboard.*`, `clock.*`).
- Prototype dictionary ready for instant locale switching (`"vi"`, `"en"`).

### 4. `config/Theme.qml` & `themes/` (Semantic Color Palettes)
- **Semantic Colors**: `borderSubtle`, `borderDefault`, `surfaceHover`, `surfaceHoverStrong`, `surfaceActive`, `badgeBackground`, `textPrimary`, `textSecondary`.
- **Dark Theme (`themes/dark.qml`)**: Material 3 deep warm tone (`surface: #191114`, `container: #261d20`, `accent: #ffb4ab`).
- **Light Theme (`themes/light.qml`)**: macOS-inspired clean minimalist palette (`surface: #f5f5f7`, `container: #ffffff`, `accent: #0a84ff`).

---

## 6. IPC Commands & Keybindings Reference

### Hyprland Keybindings:
- `SUPER + SPACE`: Toggle Spotlight Search (Mode: All)
- `SUPER + V`: Open Spotlight directly in **Clipboard History (Split-View)**
- `SUPER + R`: Toggle Spotlight Search (Application Launcher)
- `SUPER + L`: Lock Screen (`hyprlock`)
- `SUPER + TAB`: Open Alt+Tab Window Switcher

### CLI IPC Endpoints:
```bash
# Spotlight
qs -c titonium ipc call spotlight toggle
qs -c titonium ipc call spotlight clipboard
qs -c titonium ipc call spotlight close

# Window Switcher
qs -c titonium ipc call window-switcher next
qs -c titonium ipc call window-switcher previous
qs -c titonium ipc call window-switcher accept
qs -c titonium ipc call window-switcher close
```

---

## 7. Performance & Quality Standards

1. **Linting**: Every `.qml` file must pass `/usr/lib/qt6/bin/qmllint` with 0 errors.
2. **Animation Lifecycles**: All timers and animated properties must be gated on `visible` to prevent background CPU cycles.
3. **Layout Discipline**: All items placed within `RowLayout`, `ColumnLayout`, or `GridLayout` must use `Layout.preferredWidth` and `Layout.preferredHeight` rather than fixed `width`/`height` properties.
4. **Memory Hygiene**: Clipboard and notification arrays enforce upper bound limits (60 items) to prevent unbounded memory growth over extended uptimes.
