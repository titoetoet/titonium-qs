pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    id: root

    // Current active locale: "en" by default (prototype ready for "vi" expansion)
    property string locale: "en"

    readonly property var _dict: ({
        "en": {
            // Spotlight & Search
            "spotlight.search_all": "Spotlight Search (Tab to switch)...",
            "spotlight.search_clipboard": "Search Clipboard History (Tab to switch)...",
            "spotlight.search_files": "Search Files & Folders (Tab to switch)...",
            "spotlight.mode_all": "All",
            "spotlight.mode_clipboard": "Clipboard",
            "spotlight.mode_files": "Files",
            "spotlight.esc_badge": "esc",
            "spotlight.footer_spotlight": "Spotlight",
            "spotlight.footer_clipboard": "Clipboard History",
            "spotlight.footer_files": "Files",
            "spotlight.hint_tab": "Tab Mode",
            "spotlight.hint_navigate": "↑ ↓ Navigate",
            "spotlight.hint_open": "↵ Open",
            "spotlight.hint_paste": "↵ Paste",
            "spotlight.hint_close": "esc Close",
            "spotlight.no_results_title": "No results found",
            "spotlight.no_results_desc": "No applications, calculations, or commands match '{q}'",

            // System actions
            "action.lock": "Lock Screen",
            "action.lock_desc": "Lock your session with hyprlock",
            "action.shutdown": "Shut Down",
            "action.shutdown_desc": "Power off the system",
            "action.restart": "Restart",
            "action.restart_desc": "Reboot the system",
            "action.suspend": "Suspend",
            "action.suspend_desc": "Suspend system to RAM",
            "action.logout": "Log Out",
            "action.logout_desc": "Exit Hyprland compositor",
            "action.terminal": "Terminal",
            "action.terminal_desc": "Launch default terminal emulator",

            // Time & Relative formatting
            "time.just_now": "Just now",
            "time.mins_ago": "{n}m ago",
            "time.hours_ago": "{n}h ago",
            "time.days_ago": "{n}d ago",

            // Clipboard preview
            "clipboard.chars": "Chars: {n}",
            "clipboard.words": "Words: {n}",
            "clipboard.lines": "Lines: {n}",
            "clipboard.empty": "No item selected",
            "clipboard.type_url": "URL",
            "clipboard.type_code": "CODE",
            "clipboard.type_color": "COLOR",
            "clipboard.type_text": "TEXT",

            // Media & Clock
            "media.player": "Media",
            "clock.timezone_title": "Da Nang",
            "clock.timezone_subtitle": "Indochina Time (ICT) • UTC+07:00",
            "notification.title": "NOTIFICATION",

            // News & Wisdom
            "news.header": "Headlines",
            "news.loading": "Loading latest headlines...",
            "news.cat_tech": "Tech",
            "news.cat_nation": "Nation",
            "news.cat_sports": "Sports",
            "news.cat_world": "World",
            "wisdom.header": "Daily Wisdom",

            // Launcher (macOS Style)
            "launcher.search_placeholder": "Search applications...",
            "launcher.category_all": "All",
            "launcher.category_internet": "Internet",
            "launcher.category_dev": "Developer",
            "launcher.category_media": "Media",
            "launcher.category_system": "System",
            "launcher.category_utilities": "Utilities",
            "launcher.no_apps": "No applications found",
            "launcher.avatar_picker_title": "Choose an Avatar",
            "launcher.close": "Close",
            "launcher.edit_avatar": "Edit Avatar"
        },
        "vi": {
            // Spotlight & Search
            "spotlight.search_all": "Tìm kiếm Spotlight (Bấm Tab để chuyển)...",
            "spotlight.search_clipboard": "Tìm kiếm Lịch sử Clipboard (Bấm Tab)...",
            "spotlight.search_files": "Tìm kiếm Tệp tin & Thư mục (Bấm Tab)...",
            "spotlight.mode_all": "Tất cả",
            "spotlight.mode_clipboard": "Clipboard",
            "spotlight.mode_files": "Tệp tin",
            "spotlight.esc_badge": "esc",
            "spotlight.footer_spotlight": "Spotlight",
            "spotlight.footer_clipboard": "Lịch sử Clipboard",
            "spotlight.footer_files": "Tệp tin",
            "spotlight.hint_tab": "Tab Chuyển",
            "spotlight.hint_navigate": "↑ ↓ Chọn",
            "spotlight.hint_open": "↵ Mở",
            "spotlight.hint_paste": "↵ Dán",
            "spotlight.hint_close": "esc Đóng",
            "spotlight.no_results_title": "Không tìm thấy kết quả",
            "spotlight.no_results_desc": "Không có ứng dụng, phép tính hoặc lệnh nào khớp với '{q}'",

            // System actions
            "action.lock": "Khóa màn hình",
            "action.lock_desc": "Khóa phiên làm việc với hyprlock",
            "action.shutdown": "Tắt máy",
            "action.shutdown_desc": "Tắt nguồn hệ thống",
            "action.restart": "Khởi động lại",
            "action.restart_desc": "Khởi động lại máy",
            "action.suspend": "Tạm dừng (Sleep)",
            "action.suspend_desc": "Đưa hệ thống vào trạng thái ngủ",
            "action.logout": "Đăng xuất",
            "action.logout_desc": "Thoát khỏi Hyprland",
            "action.terminal": "Terminal",
            "action.terminal_desc": "Mở trình dòng lệnh",

            // Time & Relative formatting
            "time.just_now": "Vừa xong",
            "time.mins_ago": "{n} phút trước",
            "time.hours_ago": "{n} giờ trước",
            "time.days_ago": "{n} ngày trước",

            // Clipboard preview
            "clipboard.chars": "Ký tự: {n}",
            "clipboard.words": "Từ: {n}",
            "clipboard.lines": "Dòng: {n}",
            "clipboard.empty": "Chưa chọn mục nào",
            "clipboard.type_url": "ĐƯỜNG DẪN",
            "clipboard.type_code": "MÃ NGUỒN",
            "clipboard.type_color": "MÃ MÀU",
            "clipboard.type_text": "VĂN BẢN",

            // Media & Clock
            "media.player": "Trình phát nhạc",
            "clock.timezone_title": "Đà Nẵng",
            "clock.timezone_subtitle": "Giờ Đông Dương (ICT) • UTC+07:00",
            "notification.title": "THÔNG BÁO",

            // News & Wisdom
            "news.header": "Tin tức",
            "news.loading": "Đang tải tin tức mới nhất...",
            "news.cat_tech": "Công nghệ",
            "news.cat_nation": "Xã hội",
            "news.cat_sports": "Thể thao",
            "news.cat_world": "Thế giới",
            "wisdom.header": "Lời hay ý đẹp",

            // Launcher (macOS Style)
            "launcher.search_placeholder": "Tìm kiếm ứng dụng...",
            "launcher.category_all": "Tất cả",
            "launcher.category_internet": "Internet",
            "launcher.category_dev": "Phát triển",
            "launcher.category_media": "Media",
            "launcher.category_system": "Hệ thống",
            "launcher.category_utilities": "Tiện ích",
            "launcher.no_apps": "Không tìm thấy ứng dụng",
            "launcher.avatar_picker_title": "Chọn biểu tượng Avatar",
            "launcher.close": "Đóng",
            "launcher.edit_avatar": "Đổi Avatar"
        }
    })

    function t(key: string, params: var): string {
        const langDict = _dict[locale] || _dict["en"];
        let str = langDict[key] || _dict["en"][key] || key;

        if (params !== undefined && typeof params === "object") {
            for (const paramKey of Object.keys(params)) {
                str = str.replace(new RegExp("\\{" + paramKey + "\\}", "g"), String(params[paramKey]));
            }
        }
        return str;
    }
}
