# 🌸 titonium

> A luxurious, ultra-responsive desktop shell environment for **Wayland + Hyprland**, crafted with **Quickshell (Qt 6 / QML)**.

---

## ✨ Features Overview

### 🖥️ 1. Integrated Screen Frame & Glassmorphism TopBar
- **Screen Frame (`ScreenFrame.qml`)**: Continuous 5px system border with smooth rounded screen corners.
- **TopBar (`Bar.qml`)**: Floating pill bar with adaptive surface blur, drop shadows, and responsive widget layout.
- **Workspace Switcher (`WorkspaceWidget.qml`)**: 5-cell workspace indicator synchronized with Hyprland multi-monitor outputs.
- **Active Window Badge (`ActiveWindowWidget.qml`)**: Truncated active application title with hover inspection card.
- **System Monitoring Dropdown (`MonitorWidget.qml`)**: Real-time CPU, GPU, RAM, Temperature, and Load Average.
- **Input Method Indicator (`StatusWidget.qml`)**: Fcitx5 layout switcher badge (EN / VI).
- **Quick Settings Dropdowns**:
  - 🔊 **PipeWire Audio Control (`AudioWidget.qml`)**: Real-time volume sliders, mute toggle, and audio sink/source switcher.
  - 📶 **NetworkManager Scanner (`WifiWidget.qml`)**: Wi-Fi access point discovery, signal strength, and network connection list.
  - 🛜 **Bluetooth Manager (`BluetoothWidget.qml`)**: Adapter status, device discovery, and paired peripheral switcher.

---

### 🔔 2. Native Notification System (D-Bus `org.freedesktop.Notifications`)

#### 🗂️ Vertical Multi-Card Toast Stack (`NotificationPopup.qml`):
- **Multi-Monitor Overlay**: Independent notification layer per display output (`WlrLayershell.Overlay`).
- **Toast Stack**: Stack up to 4 concurrent cards with individual 5-second auto-hide countdown timers.
- **Clean Single-Line Snippet**: Formats title and body into clean single-line previews without cluttering the screen.
- **Independent Dismissal**: Click **`✕`** on any toast to dismiss it both from the screen and from the Notification Center.

#### 📋 Notification Center & Calendar Drawer (`NotificationCenter.qml`):
- **Slide-in Notification Drawer**: Multi-screen isolated side drawer with tabbed interface (`Today` and `Notifications`).
- **Permanent Retention**: Notifications remain safely stored in the Notification Panel indefinitely until explicitly cleared or closed by the user.
- **Zero-Flash Auto-Tab Switch**: Automatically opens directly into the `Notifications` tab when unread notifications exist.
- **TopBar Unread Indicator Dot**: Amber/Rose accent dot on the TopBar bell icon alerting to unread notifications.
- **Action Buttons & Inline Reply**: Full support for interactive actions (`actionsSupported`) and inline text replies (`inlineReplySupported`).
- **One-Click Clear All**: Mass-dismiss all notifications at once.

---

### 🎵 3. Audiophile Music Pill, Player & 3-Mode Visualizer

#### 🎶 Media Player (`MediaWidget.qml`):
- **TopBar Marquee Pill**: Center-aligned dynamic pill with smooth scrolling title/artist marquee and mini Play/Pause toggle.
- **Universal MPRIS Architecture**: Native integration with Spotify, Chromium, Brave, Firefox, MPV, VLC, Apple Music, and Cider.
- **Automatic Artwork Extraction**: Displays high-resolution album art / thumbnails (`trackArtUrl`) with graceful fallback to vector note badges.
- **Interactive Seek Bar**: Click anywhere on the progress bar to seek with millisecond accuracy.
- **Hybrid Timestamp Engine**: Employs mathematical timestamp-offset interpolation—**0% CPU when collapsed**, instant sub-second precision upon opening.

#### 🌊 Interactive 3-Mode Audio Visualizer (`AudioVisualizer.qml`):
- **Mode 1: Equalizer Bars (📊)**: 40 rounded spectrum bars bouncing to the rhythmic bass, mid, and treble frequencies.
- **Mode 2: Fluid Sine Waveform (🌊)**: Dual intertwined neon Canvas waveforms oscillating with smooth analog flow.
- **Mode 3: Floating Pulsing Dots (✨)**: 40 particle dots dancing vertically with size and alpha modulation.
- **1-Touch Cyclic Switch**: Click directly on the visualizer to cycle between modes (`Bars ➔ Wave ➔ Dots ➔ Bars`).
- **Persistent State**: Preferred visualizer mode is saved automatically to `~/.config/titonium/settings.json`.

---

### 🚀 4. Luxury Launcher & Hardware Dashboard (`Dashboard.qml`)

- **Expanded Balanced Dimensions**: 570px × 540px popup bounds with centered 440px content card.
- **Grand 120px Circular Avatar**:
  - Live hover edit overlay.
  - **12-Icon Persistent Preset Picker** (Arch Linux, Tux, Robot, Code, Terminal, Palette, Rocket, etc.).
  - Persisted across shell reloads and reboots via `SettingsService.qml`.
- **macOS System Info / btop Inset Spec Panel**:
  - Consolidated specifications: CPU Model, GPU Device, Memory Used/Total, Shell, Kernel, Display Resolution, Uptime, and Pacman Packages count.
- **System Actions Bar**:
  - Dedicated power controls: Shutdown, Restart, Sleep, Hibernate, and Logout.
  - Sleek vertical dividing line separating the session controls from system specs.
- **Settings Button (⚙️)**: Interactive bottom-right settings trigger with custom notification feedback.

---

### 🔍 5. macOS Spotlight Launcher & Split-View Clipboard (`Spotlight.qml`)

- **Universal Search (`SUPER + SPACE`)**:
  - Fuzzy application search with icons and `.desktop` entry execution.
  - **Instant Math Evaluator**: Type `25 * 4 + 10`, `sqrt(144)`, or `sin(pi/2)` for instant calculations.
  - **System Quick Actions**: Type `lock`, `shutdown`, `reboot`, `suspend`, `terminal` for immediate execution.
  - **Tab-cycling modes**: `Tab` cycles between `All` ➔ `Clipboard` ➔ `Files` ➔ `All`.
- **Raycast 2-Column Clipboard History (`SUPER + V`)**:
  - Inset split-view layout with left list and right live preview.
  - Smart classification tags: **URLs 🌐**, **Code snippets 💻**, **Color swatches 🎨** (with live hex color card), and **Text 📄**.
  - Real-time statistics: Character count, word count, line count, and relative timestamps (`2m ago`, `1h ago`).

---

### 🕒 6. Luxury Analog Clock & Timezone Card (`ClockWidget.qml`)

- **164px Analog Clock Dial**: Precision mechanical clock face with smooth ticking hands.
- **Ho Chi Minh City Timezone Card**: Local Indochina Time display (`Asia/Ho_Chi_Minh • UTC+07:00 (ICT)`).

---

### 🔄 7. Alt+Tab Window Switcher (`WindowSwitcher.qml`)

- Visual multitasking overlay for cycling between running Wayland applications with `SUPER + TAB`.
- Built-in fail-safe compositor submap release.

---

### 🎨 8. Dynamic Theming Engine (`Theme.qml`)

- **Dark Theme**: Material 3 rose-tinted dark palette.
- **Light Theme**: macOS clean crisp white palette.
- Reactive tokens: Surfaces, containers, borders, typography, and accent colors.

---

## 📦 Prerequisites & Dependencies

Before installing `titonium`, ensure the following packages and fonts are installed on your system (e.g. on **Arch Linux**):

### 1. Core Shell Engine & Compositor
```bash
# Install Hyprland and Quickshell (from AUR)
yay -S hyprland quickshell-git qt6-declarative qt6-quick-effects qt6-svg
```

### 2. Required System Tools & Services
```bash
sudo pacman -S --needed \
    pipewire \
    wireplumber \
    playerctl \
    networkmanager \
    bluez \
    bluez-utils \
    wl-clipboard \
    lm_sensors \
    libnotify \
    curl \
    jq \
    xdg-utils
```

### 3. Recommended Applications & Helpers
```bash
sudo pacman -S --needed kitty thunar hyprlock fcitx5 fcitx5-unikey
```

### 4. Typography & Fonts
For authentic Apple & luxury typography, install:
```bash
yay -S ttf-sf-pro ttf-jetbrains-mono ttf-material-symbols-variable-git
```
*(Or place `SF-Pro-Display-*.otf` into `~/.local/share/fonts/` and run `fc-cache -fv`)*

---

## 🚀 Installation & Setup

### Step 1: Clone or Place into Quickshell Config
```bash
mkdir -p ~/.config/quickshell
git clone <repo-url> ~/.config/quickshell/titonium
```

### Step 2: Configure Hyprland Keybindings

Add the following keybindings to your Hyprland configuration (`~/.config/hypr/hyprland.lua` or `~/.config/hypr/hyprland.conf`):

#### 🔹 In `~/.config/hypr/hyprland.lua` (Lua format):
```lua
-- Spotlight Launcher
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd("qs -c titonium ipc call spotlight toggle"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("qs -c titonium ipc call spotlight toggle"))

-- Clipboard History Split-View
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs -c titonium ipc call spotlight clipboard"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))

-- Window Switcher
hl.bind(mainMod .. " + TAB", function()
    hl.dispatch(hl.dsp.exec_cmd("qs -c titonium ipc call window-switcher next"))
    hl.dispatch(hl.dsp.submap("switcher"))
end)
```

#### 🔹 In `~/.config/hypr/hyprland.conf` (Conf format):
```ini
# Spotlight Launcher
bind = SUPER, SPACE, exec, qs -c titonium ipc call spotlight toggle
bind = SUPER, R, exec, qs -c titonium ipc call spotlight toggle

# Clipboard History Split-View
bind = SUPER, V, exec, qs -c titonium ipc call spotlight clipboard
bind = SUPER_SHIFT, V, togglefloating,

# Window Switcher
bind = SUPER, TAB, exec, qs -c titonium ipc call window-switcher next
```

### Step 3: Autostart with Hyprland
Add this line to your Hyprland startup config:
```ini
exec-once = qs -c titonium
```

---

## 🎮 Usage & Keyboard Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`SUPER + SPACE`** | **Spotlight Launcher** | Opens floating universal search bar |
| **`SUPER + V`** | **Clipboard History** | Opens Spotlight directly in 2-Column Split-View |
| **`SUPER + L`** | **Lock Screen** | Locks session with hyprlock (blur & aesthetic clock) |
| **`Tab`** | **Cycle Modes** | Inside Spotlight: Switch between `All` ➔ `Clipboard` ➔ `Files` |
| **`↑` / `↓`** | **Navigate** | Move highlight selection in Spotlight, Switcher, or Menus |
| **`Enter`** | **Execute / Paste** | Launch selected app, execute calculation, or copy clipboard item |
| **`Esc`** | **Dismiss** | Close active popup, Spotlight, or Notification Center |
| **`SUPER + TAB`** | **Window Switcher** | Alt+Tab multitasking overlay |

---

## 🛠️ CLI & IPC Commands

You can control `titonium` remotely or script actions using Quickshell IPC:

```bash
# Toggle Spotlight
qs -c titonium ipc call spotlight toggle

# Open Clipboard History directly
qs -c titonium ipc call spotlight clipboard

# Close Spotlight
qs -c titonium ipc call spotlight close

# Window Switcher controls
qs -c titonium ipc call window-switcher next
qs -c titonium ipc call window-switcher previous
qs -c titonium ipc call window-switcher accept
qs -c titonium ipc call window-switcher close
```

---

## 📚 Technical Documentation

For in-depth architecture diagrams, Singleton service specifications, and layer-shell design standards, see:
👉 **[ARCHITECTURE.md](file:///home/cole/.config/quickshell/titonium/ARCHITECTURE.md)**

---

## 📄 License

MIT License © 2026 cole
