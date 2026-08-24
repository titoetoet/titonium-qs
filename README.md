# 🌸 titonium

> A modern, modular desktop shell for **Wayland + Hyprland**, built with **Quickshell (Qt 6 / QML)**.

---

## 📸 Preview & Screenshots

| Dark Mode (Default) | Light Mode |
| :---: | :---: |
| <img src="assets/screenshots/overview.png" alt="titonium Dark Mode" width="100%" /> | <img src="assets/screenshots/overview_light.png" alt="titonium Light Mode" width="100%" /> |

<br/>

| Spotlight Launcher (`SUPER + SPACE`) | Alt+Tab Window Switcher (`SUPER + TAB`) |
| :---: | :---: |
| <img src="assets/screenshots/spotlight_launcher.png" alt="Spotlight Launcher" width="100%" /> | <img src="assets/screenshots/window_switcher.png" alt="Window Switcher" width="100%" /> |

| System Dashboard & Controls | Media Player & 3-Mode Visualizer |
| :---: | :---: |
| <img src="assets/screenshots/dashboard_control_center.png" alt="Hardware Dashboard" width="100%" /> | <img src="assets/screenshots/media_player_visualizer.png" alt="Media Player & Visualizer" width="100%" /> |

| Notification Center & Calendar |
| :---: |
| <img src="assets/screenshots/notification_center.png" alt="Notification Center" width="100%" /> |

| Wi-Fi Network Menu | Bluetooth Devices | System Resource Monitor |
| :---: | :---: | :---: |
| <img src="assets/screenshots/wifi_menu.png" alt="WiFi Menu" width="100%" /> | <img src="assets/screenshots/bluetooth_menu.png" alt="Bluetooth Menu" width="100%" /> | <img src="assets/screenshots/system_monitor.png" alt="System Resource Monitor" width="100%" /> |

> 💡 **Tip:** Place demonstration videos into `assets/videos/` or drag-and-drop your video into GitHub release notes / issues to embed it directly.

---

## ✨ Key Features

### 🖥️ 1. Screen Frame & TopBar
- **Screen Frame (`ScreenFrame.qml`)**: 5px system border with smooth rounded display corners.
- **TopBar (`TopBar.qml`)**: Floating bar with blur effect, drop shadows, and responsive widget layout.
- **Single Unified Hyprland Focus Grab**: Eliminates exclusive seat grab lockups, ensuring windows (terminals, browsers, editors) maintain mouse responsiveness.
- **Workspace Switcher (`WorkspaceWidget.qml`)**: 5-cell workspace indicator synchronized across Hyprland outputs.
- **Active Window Badge (`ActiveWindowWidget.qml`)**: Truncated active application title with hover inspection card.
- **System Monitoring Dropdown (`MonitorWidget.qml`)**: Real-time CPU, GPU, RAM, Temperature, and Load Average.
- **Input Method Indicator (`StatusWidget.qml`)**: Fcitx5 layout switcher badge (EN / VI).
- **Quick Settings Dropdowns**:
  - 🔊 **PipeWire Audio Control (`AudioWidget.qml`)**: Volume sliders, mute toggle, and audio sink/source switcher.
  - 📶 **NetworkManager Scanner (`WifiWidget.qml`)**: Wi-Fi access point discovery, signal strength, and network list.
  - 🛜 **Bluetooth Manager (`BluetoothWidget.qml`)**: Adapter status, device discovery, and paired device switcher.

---

### 🔔 2. Notification System (D-Bus `org.freedesktop.Notifications`)

#### 🗂️ Dynamic Slide-Push Toast Stack (`NotificationPopup.qml`):
- **Top-Right Default Position**: Floating toast cards docked cleanly at the top-right corner.
- **Dynamic Slide-Push Effect**: When the Notification Center drawer opens, floating toasts **automatically glide 375px to the left** with a smooth `250ms Easing.OutCubic` curve, avoiding any visual overlap, and slide back when the drawer closes.
- **Multi-Monitor Overlay**: Independent notification layer per display output (`WlrLayershell.Overlay`).
- **Decluttered Layout**: Removed heavy thumbnail images for a streamlined, compact card aesthetic.
- **Toast Stack**: Stack up to 4 concurrent cards with individual 5-second auto-hide countdown timers.
- **Independent Dismissal**: Click **`✕`** to dismiss individual toasts immediately.

#### 📋 Notification Center & Live Hub (`NotificationCenter.qml`):
- **Slide-in Notification Drawer**: Multi-screen side drawer with tabbed interface (`Today` and `Notifications`).
- **Live Google News Section (`NewsService.qml`)**: Real-time headlines across multiple topics (*Tech*, *Nation*, *Sports*, *World*) with auto-locale feed URL switching and relative timestamps.
- **Daily Lunar Wisdom (`LunarService.qml`)**: Dual-language philosophical quotes integrated with astronomical solar-to-lunar date conversion and lunar phase detection.
- **Permanent Retention**: Notifications remain stored in the panel until explicitly cleared.
- **Auto-Tab Switch**: Automatically opens directly into the `Notifications` tab when unread items exist.
- **TopBar Unread Indicator Dot**: Amber/Rose accent dot on the bell icon for unread notifications.
- **Action Buttons & Inline Reply**: Support for interactive notification actions and inline text replies.

---

### 🎵 3. Media Player & Audio Visualizer

#### 🎶 Media Player (`MediaWidget.qml`):
- **TopBar Marquee Pill**: Dynamic pill with smooth scrolling title/artist marquee and mini Play/Pause toggle.
- **Universal MPRIS Architecture**: Supports Spotify, Chromium, Brave, Firefox, MPV, VLC, Apple Music, and Cider.
- **Automatic Artwork Extraction**: Displays high-resolution album art with fallback vector badges.
- **Interactive Seek Bar**: Click anywhere on the progress bar to seek.
- **Efficient Timestamp Engine**: Zero CPU overhead when collapsed, millisecond precision upon opening.

#### 🌊 3-Mode Audio Visualizer (`AudioVisualizer.qml`):
- **Mode 1: Equalizer Bars (📊)**: 40 spectrum bars responding to frequency changes.
- **Mode 2: Fluid Sine Waveform (🌊)**: Dual neon Canvas waveforms oscillating in real-time.
- **Mode 3: Floating Pulsing Dots (✨)**: 40 particle dots modulated by audio size and alpha.
- **1-Touch Cyclic Switch**: Click directly on the visualizer to cycle modes (`Bars ➔ Wave ➔ Dots ➔ Bars`).
- **Persistent State**: Preferred mode is saved to `~/.config/titonium/settings.json`.

---

### 🚀 4. Launchpad & Dashboard (`LauncherWidget.qml` / `Dashboard.qml`)

- **16:9 Widescreen Proportions**: 960px × 540px canvas engineered with golden ratio proportions.
- **Expanded Sidebar**: 260px wide category selector with 40px row heights and intuitive icons.
- **Apple-Style Fluid Page Carousel**: Smooth multi-page horizontal scrolling (`420ms Easing.OutQuint`), 3D depth zoom transitions, and mouse wheel debounce.
- **Sequential Category Crossfade**: 2-phase animation (`140ms` fade-out ➔ filter ➔ `260ms` fade-in) eliminating item overlap.
- **Custom Profile Avatar**: Live hover edit overlay with 12 preset icons persisted via `SettingsService.qml`.
- **System Specs & Controls**: CPU/GPU specs, memory, kernel, uptime, and dedicated power management actions.

---

### 🔍 5. Spotlight Launcher & Split-View Clipboard (`Spotlight.qml`)

- **Universal Search (`SUPER + SPACE`)**:
  - High-contrast selection pills with bold white typography.
  - Fuzzy application search with desktop entry execution.
  - **Instant Math Evaluator**: Type `25 * 4 + 10`, `sqrt(144)`, or `sin(pi/2)` for instant calculations.
  - **System Quick Actions**: Type `lock`, `shutdown`, `reboot`, `suspend`, `terminal` for immediate execution.
  - **Tab-cycling modes**: `Tab` cycles between `All` ➔ `Clipboard` ➔ `Files` ➔ `All`.
- **2-Column Clipboard History (`SUPER + V`)**:
  - Inset split-view layout with item list on the left and live preview on the right.
  - Smart classification tags: **URLs 🌐**, **Code snippets 💻**, **Color swatches 🎨**, and **Text 📄**.
  - Real-time statistics: Character count, word count, line count, and relative timestamps.

---

### 🕒 6. Swiss Luxury Analog Clock (`ClockWidget.qml`)

- **Haute Horlogerie Clock Dial**: Borderless 204px diameter dial floating directly on the glass popup backdrop.
- **Obsidian Sunburst Finish**: Concentric chapter rings with 60 precision minute/hour ticks.
- **Applied Faceted Batons**: 12, 3, 6, 9 double luminous batons with single polished markers for remaining hours.
- **Faceted Sword Hands**: Luminous inlay core on hour and minute hands, with a sweeping needle second hand and circular counterweight.
- **Timezone**: Configured for **Đà Nẵng** (`Asia/Ho_Chi_Minh • UTC+07:00 (ICT)`).

---

### 🔄 7. Window Switcher (`WindowSwitcher.qml`)

- Visual multitasking overlay for cycling between running Wayland applications with `SUPER + TAB`.
- Built-in fail-safe compositor submap release.

---

### 🎨 8. Liquid Glass & Theming Engine (`Theme.qml` / `PopupPanel.qml`)

- **macOS Sequoia / Sonoma Drop Shadows**: Soft, natural 0.38 alpha Gaussian shadows (`blurMax: 32`, `shadowBlur: 0.65`, `shadowVerticalOffset: 8px`).
- **Liquid Glass Caustic Glow**: Top ambient diffused glow on all popups.
- **Specular Rim Sheen**: 1.5px horizontal focal light reflection simulating beveled glass edges.
- **Dracula & Light Modes**: Reactive design tokens for surfaces, containers, borders, typography, and accents.

---

## 🛠️ System Requirements & Dependencies

Before running `titonium`, ensure the following packages and fonts are installed on your system (e.g. on **Arch Linux**):

### 1. 🖥️ Core Shell Engine & Compositor
```bash
yay -S hyprland quickshell-git qt6-declarative qt6-quick-effects qt6-svg
```

### 2. ⚙️ System Utilities & Audio Services
```bash
sudo pacman -S --needed \
    pipewire \
    wireplumber \
    networkmanager \
    bluez \
    bluez-utils \
    brightnessctl \
    playerctl \
    wl-clipboard \
    libnotify \
    lm_sensors
```

### 3. 🔤 Curated Typography & Icons
```bash
sudo pacman -S --needed \
    ttf-font-awesome \
    ttf-jetbrains-mono \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji

# Install SF Pro Display and Material Symbols Rounded for pixel-perfect UI rendering
```

---

## ⚡ Quick Start & Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/titoetoet/titonium-qs.git ~/.config/quickshell/titonium
   ```

2. **Launch titonium shell**:
   ```bash
   qs -n -d -c titonium
   ```

3. **Autostart with Hyprland (`~/.config/hypr/hyprland.conf` or `hyprland.lua`)**:
   ```ini
   exec-once = qs -n -d -c titonium
   ```

---

## ⌨️ Hyprland Keybindings

Add the following shortcuts to your Hyprland configuration for seamless navigation:

```ini
# Spotlight Launcher
bind = SUPER, SPACE, exec, qs -c titonium ipc call spotlight toggle
bind = SUPER, R, exec, qs -c titonium ipc call spotlight toggle

# Clipboard History (Split-View with live preview)
bind = SUPER, V, exec, qs -c titonium ipc call spotlight clipboard

# Alt+Tab Window Switcher
bind = SUPER, TAB, exec, qs -c titonium ipc call window-switcher next
```

---

## 📄 License

Distributed under the [MIT License](LICENSE).
