pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Windows 11 look for bar.style "windows": Fluent colours (dark / light follow
// angelOS), Segoe UI when installed (Noto Sans otherwise), Fluent motion curves.
// Sizes are real pixels like on Windows at 100 % scale, not angelOS art pixels.
Singleton {
    id: root

    readonly property bool dark: Theme.dark

    // ---- type ----
    readonly property var families: Qt.fontFamilies()
    readonly property string font: ["Segoe UI Variable Text", "Segoe UI Variable", "Segoe UI", "Noto Sans", "Open Sans"].find(f => families.includes(f)) || "sans-serif"
    readonly property string fontDisplay: ["Segoe UI Variable Display", "Segoe UI Variable", "Segoe UI", "Noto Sans"].find(f => families.includes(f)) || font
    readonly property int caption: 12
    readonly property int body: 14
    readonly property int subtitle: 20

    // ---- colours ----
    readonly property color accent: Config.win.accent === "theme" ? Theme.accent : dark ? "#60cdff" : "#005fb8"
    readonly property color accentHover: Qt.tint(accent, dark ? "#1a000000" : "#1affffff")
    readonly property bool accentLight: 0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b > 0.55
    readonly property color onAccent: accentLight ? "#000000" : "#ffffff"
    readonly property color text: dark ? "#ffffff" : Qt.rgba(0, 0, 0, 0.896)
    readonly property color text2: dark ? Qt.rgba(1, 1, 1, 0.786) : Qt.rgba(0, 0, 0, 0.606)
    readonly property color text3: dark ? Qt.rgba(1, 1, 1, 0.544) : Qt.rgba(0, 0, 0, 0.446)
    readonly property color textOff: dark ? Qt.rgba(1, 1, 1, 0.363) : Qt.rgba(0, 0, 0, 0.361)

    // acrylic surfaces (the compositor blurs what's behind them)
    readonly property color taskbar: dark ? Qt.rgba(0.110, 0.110, 0.110, 0.86) : Qt.rgba(0.933, 0.933, 0.933, 0.86)
    readonly property color taskbarLine: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color flyout: dark ? Qt.rgba(0.173, 0.173, 0.173, 0.90) : Qt.rgba(0.953, 0.953, 0.953, 0.90)
    readonly property color flyoutLine: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color flyoutFoot: dark ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(0, 0, 0, 0.035)
    readonly property color menu: dark ? Qt.rgba(0.17, 0.17, 0.17, 0.96) : Qt.rgba(0.98, 0.98, 0.98, 0.96)

    // controls
    readonly property color subtleHover: dark ? Qt.rgba(1, 1, 1, 0.061) : Qt.rgba(0, 0, 0, 0.037)
    readonly property color subtlePress: dark ? Qt.rgba(1, 1, 1, 0.042) : Qt.rgba(0, 0, 0, 0.024)
    readonly property color control: dark ? Qt.rgba(1, 1, 1, 0.061) : Qt.rgba(1, 1, 1, 0.7)
    readonly property color controlHover: dark ? Qt.rgba(1, 1, 1, 0.084) : Qt.rgba(0.976, 0.976, 0.976, 0.5)
    readonly property color controlLine: dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color controlBottom: dark ? Qt.rgba(1, 1, 1, 0.035) : Qt.rgba(0, 0, 0, 0.16)
    readonly property color field: dark ? Qt.rgba(0.118, 0.118, 0.118, 0.7) : Qt.rgba(1, 1, 1, 0.7)
    readonly property color card: dark ? Qt.rgba(1, 1, 1, 0.051) : Qt.rgba(1, 1, 1, 0.7)
    readonly property color divider: dark ? Qt.rgba(1, 1, 1, 0.084) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color indicator: dark ? Qt.rgba(1, 1, 1, 0.545) : Qt.rgba(0, 0, 0, 0.446)
    readonly property color shadow: dark ? Qt.rgba(0, 0, 0, 0.42) : Qt.rgba(0, 0, 0, 0.18)

    // ---- motion (Fluent) ----
    readonly property var decelerate: [0.1, 0.9, 0.2, 1, 1, 1]     // things coming in
    readonly property var accelerate: [0.7, 0, 1, 0.5, 1, 1]       // things leaving
    readonly property var standard: [0.8, 0, 0.2, 1, 1, 1]
    readonly property int fast: 167
    readonly property int normal: 250
    readonly property int slow: 333


    // angelOS pixel icon name → Fluent icon (modules/bar/win/icons), "" = none
    readonly property var fluentIcons: ({
            "heart": "heart-regular",
            "heartBroken": "heart_broken-regular",
            "heartSmall": "heart-regular",
            "pill": "pill-regular",
            "star": "star-regular",
            "sparkle": "sparkle-regular",
            "gear": "settings-regular",
            "monitor": "desktop-regular",
            "keyboard": "keyboard-regular",
            "mouse": "cursor-regular",
            "chip": "developer_board-regular",
            "speaker": "speaker_2-regular",
            "speakerMute": "speaker_mute-regular",
            "mic": "mic-regular",
            "micMute": "mic_off-regular",
            "bell": "alert-regular",
            "bellOff": "alert_off-regular",
            "music": "music_note_2-regular",
            "lock": "lock_closed-regular",
            "power": "power-regular",
            "moon": "weather_moon-regular",
            "sun": "weather_sunny-regular",
            "logout": "sign_out-regular",
            "refresh": "arrow_clockwise-regular",
            "folder": "folder-regular",
            "plug": "plug_connected-regular",
            "image": "image-regular",
            "palette": "color-regular",
            "layers": "layer-regular",
            "package": "box-regular",
            "terminal": "window_dev_tools-regular",
            "window": "window-regular",
            "calendar": "calendar-regular",
            "info": "info-regular",
            "warn": "warning-regular",
            "trash": "delete-regular",
            "search": "search-regular",
            "check": "checkmark-regular",
            "close": "dismiss-regular",
            "minimize": "subtract-regular",
            "maximize": "maximize-regular",
            "plus": "add-regular",
            "minus": "subtract-regular",
            "arrowRight": "arrow_right-regular",
            "arrowLeft": "arrow_left-regular",
            "arrowDown": "arrow_down-regular",
            "arrowUp": "arrow_up-regular",
            "play": "play-filled",
            "pause": "pause-filled",
            "next": "next-filled",
            "prev": "previous-filled",
            "pin": "pin-regular",
            "bot": "bot-regular",
            "gauge": "gauge-regular",
            "ghost": "emoji-regular",
            "wifi": "wifi_1-regular",
            "wifiOff": "wifi_off-regular",
            "bluetooth": "bluetooth-regular",
            "gamepad": "games-regular",
            "cursor": "cursor-regular",
            "download": "arrow_download-regular",
            "grid": "grid-regular",
            "document": "document-regular"
        })
    function fluentIcon(name) {
        return fluentIcons[name] || "";
    }

    readonly property string userName: Quickshell.env("USER") || "user"
    readonly property string avatar: "file:///var/lib/AccountsService/icons/" + userName
}
