pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string location: "Da Nang, Vietnam"
    readonly property real latitude: 16.0544
    readonly property real longitude: 108.2022

    property bool loading: false
    property string error: ""
    property real temperature: NaN
    property real feelsLike: NaN
    property int humidity: 0
    property real windSpeed: 0
    property int weatherCode: -1
    property bool isDay: true
    property date updatedAt

    readonly property string temperatureText: Number.isFinite(temperature)
        ? Math.round(temperature) + "°C" : "--°"
    readonly property string description: conditionForCode(weatherCode, loading)
    readonly property string iconName: iconForWeather(weatherCode, isDay, temperature, humidity)
    readonly property color iconColour: colourForWeather(weatherCode, isDay, temperature)

    function conditionForCode(code: int, isLoading: bool): string {
        if (code === 0)
            return "Clear";
        if (code === 1)
            return "Mostly clear";
        if (code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code === 45 || code === 48)
            return "Foggy";
        if (code >= 51 && code <= 57)
            return "Drizzle";
        if (code >= 61 && code <= 65)
            return "Rain";
        if (code >= 66 && code <= 67)
            return "Freezing rain";
        if (code >= 71 && code <= 77)
            return "Snow";
        if (code >= 80 && code <= 82)
            return "Rain showers";
        if (code >= 85 && code <= 86)
            return "Snow showers";
        if (code >= 95)
            return "Thunderstorm";
        return isLoading ? "Updating…" : "Clear";
    }

    function iconForWeather(code: int, daytime: bool, temp: real, hum: int): string {
        // Thunderstorm
        if (code >= 95)
            return "thunderstorm";

        // Snow / Freezing
        if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86) || (Number.isFinite(temp) && temp <= 0))
            return "ac_unit";

        // Heavy Rain / Showers
        if (code >= 80 && code <= 82 || code === 65)
            return "rainy";

        // Rain / Drizzle
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return "rainy";

        // Fog
        if (code === 45 || code === 48)
            return "foggy";

        // Overcast
        if (code === 3)
            return "cloud";

        // High Humidity & warm (mùa nồm / oi bức ẩm ướt)
        if (hum >= 88 && (code === 1 || code === 2))
            return "water_drop";

        // Partly cloudy
        if (code === 1 || code === 2)
            return daytime ? "partly_cloudy_day" : "partly_cloudy_night";

        // Clear Sun / Night
        if (code === 0 || code === -1) {
            if (Number.isFinite(temp) && temp >= 36)
                return "sunny"; // Extreme heat
            return daytime ? "sunny" : "bedtime";
        }

        return daytime ? "sunny" : "bedtime";
    }

    function colourForWeather(code: int, daytime: bool, temp: real): color {
        // Thunderstorm -> Dracula Red
        if (code >= 95)
            return "#ff5555";

        // Extreme heat ($T >= 35°C$) -> Dracula Red/Orange
        if (Number.isFinite(temp) && temp >= 35)
            return "#ff5555";

        // Cold / Snow ($T <= 14°C$) -> Dracula Cyan
        if ((Number.isFinite(temp) && temp <= 14) || (code >= 71 && code <= 77))
            return "#8be9fd";

        // Rain / Drizzle -> Dracula Cyan
        if (code >= 51 && code <= 67 || code >= 80 && code <= 82)
            return "#8be9fd";

        // Overcast / Fog -> Dracula Comment Blue
        if (code === 3 || code === 45 || code === 48)
            return "#6272a4";

        // Partly cloudy -> Dracula Yellow
        if (code === 1 || code === 2)
            return daytime ? "#f1fa8c" : "#bd93f9";

        // Clear day -> Dracula Orange
        if (daytime)
            return "#ffb86c";

        // Clear night -> Dracula Purple
        return "#bd93f9";
    }

    function reload(): void {
        if (request.running)
            return;

        loading = true;
        error = "";
        request.running = true;
    }

    Component.onCompleted: reload()

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.reload()
    }

    Process {
        id: request

        command: [
            "curl", "-fsS", "--max-time", "15",
            "https://api.open-meteo.com/v1/forecast?latitude="
                + root.latitude + "&longitude=" + root.longitude
                + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m"
                + "&timezone=Asia%2FHo_Chi_Minh"
        ]

        stdout: StdioCollector {
            id: response
        }

        onExited: (exitCode, exitStatus) => {
            root.loading = false;

            if (exitCode !== 0) {
                root.error = "Unable to update weather";
                return;
            }

            try {
                const data = JSON.parse(response.text);
                const current = data.current;

                root.temperature = current.temperature_2m;
                root.feelsLike = current.apparent_temperature;
                root.humidity = current.relative_humidity_2m;
                root.windSpeed = current.wind_speed_10m;
                root.weatherCode = current.weather_code;
                root.isDay = current.is_day === 1;
                root.updatedAt = new Date();
            } catch (parseError) {
                root.error = "Invalid weather response";
                console.warn("WeatherService:", parseError);
            }
        }
    }
}
