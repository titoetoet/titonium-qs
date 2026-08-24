pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property string currentCategory: "technology" // Default to technology
    property bool loading: false
    property string error: ""
    property var articles: []
    property date lastUpdated

    readonly property var categories: [
        { id: "technology", nameKey: "news.cat_tech",   topic: "TECHNOLOGY", color: "#8be9fd" }, // Dracula Cyan
        { id: "society",    nameKey: "news.cat_nation", topic: "NATION",     color: "#50fa7b" }, // Dracula Green
        { id: "sports",     nameKey: "news.cat_sports", topic: "SPORTS",     color: "#ffb86c" }, // Dracula Orange
        { id: "world",      nameKey: "news.cat_world",  topic: "WORLD",      color: "#bd93f9" }  // Dracula Purple
    ]

    readonly property var categoryColorMap: ({
        "technology": "#8be9fd",
        "society": "#50fa7b",
        "sports": "#ffb86c",
        "world": "#bd93f9"
    })

    function getFeedUrl(category) {
        let topic = "TECHNOLOGY";
        for (let i = 0; i < categories.length; i++) {
            if (categories[i].id === category) {
                topic = categories[i].topic;
                break;
            }
        }
        if (I18n.locale === "vi") {
            return "https://news.google.com/rss/headlines/section/topic/" + topic + "?hl=vi&gl=VN&ceid=VN:vi";
        }
        return "https://news.google.com/rss/headlines/section/topic/" + topic + "?hl=en-US&gl=US&ceid=US:en";
    }

    function formatTimeAgo(pubDateStr) {
        if (!pubDateStr) return "";
        try {
            const date = new Date(pubDateStr);
            const now = new Date();
            const diffMs = now.getTime() - date.getTime();
            const diffMin = Math.floor(diffMs / 60000);
            if (diffMin < 60) {
                return diffMin <= 1 ? I18n.t("time.just_now") : I18n.t("time.mins_ago", { n: diffMin });
            }
            const diffHr = Math.floor(diffMin / 60);
            if (diffHr < 24) {
                return I18n.t("time.hours_ago", { n: diffHr });
            }
            const diffDay = Math.floor(diffHr / 24);
            return I18n.t("time.days_ago", { n: diffDay });
        } catch (e) {
            return "";
        }
    }

    function parseXmlRss(xmlText, category) {
        const items = [];
        const itemRegex = /<item>([\s\S]*?)<\/item>/gi;
        let match;

        while ((match = itemRegex.exec(xmlText)) !== null) {
            const itemContent = match[1];

            // Title
            const titleMatch = /<title>([\s\S]*?)<\/title>/i.exec(itemContent);
            let rawTitle = titleMatch ? titleMatch[1].replace(/<!\[CDATA\[(.*?)\]\]>/gi, "$1").trim() : "";

            // Link
            const linkMatch = /<link>([\s\S]*?)<\/link>/i.exec(itemContent);
            const link = linkMatch ? linkMatch[1].trim() : "";

            // Source
            const sourceMatch = /<source[^>]*>([\s\S]*?)<\/source>/i.exec(itemContent);
            let source = sourceMatch ? sourceMatch[1].replace(/<!\[CDATA\[(.*?)\]\]>/gi, "$1").trim() : "";

            // PubDate
            const pubDateMatch = /<pubDate>([\s\S]*?)<\/pubDate>/i.exec(itemContent);
            const pubDate = pubDateMatch ? pubDateMatch[1].trim() : "";

            // Clean title: remove " - SourceName" from end of title if present
            let headline = rawTitle;
            if (source && headline.endsWith(" - " + source)) {
                headline = headline.substring(0, headline.length - (" - " + source).length);
            } else {
                const lastDash = headline.lastIndexOf(" - ");
                if (lastDash > 0) {
                    if (!source) source = headline.substring(lastDash + 3).trim();
                    headline = headline.substring(0, lastDash).trim();
                }
            }

            // Decode HTML entities
            headline = headline.replace(/&amp;/g, "&")
                               .replace(/&quot;/g, "\"")
                               .replace(/&#39;/g, "'")
                               .replace(/&lt;/g, "<")
                               .replace(/&gt;/g, ">");

            if (headline && link) {
                items.push({
                    headline: headline,
                    link: link,
                    source: source || "Google News",
                    pubDate: pubDate,
                    time: formatTimeAgo(pubDate),
                    category: category,
                    accent: root.categoryColorMap[category] || "#8be9fd"
                });
            }

            if (items.length >= 6) {
                break;
            }
        }

        return items;
    }

    function openArticle(url) {
        if (!url) return;
        Qt.openUrlExternally(url);
    }

    function fetchNews(category, force) {
        if (request.running) return;

        root.currentCategory = category;
        root.loading = true;
        root.error = "";

        const url = getFeedUrl(category);
        request.command = [
            "curl", "-fsSL", "--max-time", "12",
            "-H", "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
            url
        ];
        request.running = true;
    }

    Component.onCompleted: {
        fetchNews("technology");
    }

    // Refresh twice a day (every 12 hours = 43,200,000 ms)
    Timer {
        interval: 43200000
        running: true
        repeat: true
        onTriggered: root.fetchNews(root.currentCategory, true)
    }

    Process {
        id: request

        stdout: StdioCollector {
            id: response
        }

        onExited: (exitCode, exitStatus) => {
            root.loading = false;

            if (exitCode !== 0 || !response.text) {
                root.error = "Không thể tải tin tức";
                return;
            }

            try {
                const parsed = parseXmlRss(response.text, root.currentCategory);
                if (parsed.length > 0) {
                    root.articles = parsed;
                    root.lastUpdated = new Date();
                }
            } catch (err) {
                root.error = "Lỗi xử lý tin tức";
                console.warn("NewsService parse error:", err);
            }
        }
    }
}
