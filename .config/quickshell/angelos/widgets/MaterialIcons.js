.pragma library
// TrollOS: angelOS's pixel icons (widgets/Icons.js) as Material Symbols — the «Material You»
// skin draws a symbol where it knows one (font ligatures: the text "settings" is the gear).
//   fromPixel(name) -> the symbol's name, or "" (then the pixel icon stays)
//   family(style)   -> the font family for rounded | outlined | sharp

var map = {
    "splat": "auto_awesome", "camera": "photo_camera", "document": "description", "heart": "favorite",
    "fire": "local_fire_department", "chat": "chat", "cd": "album", "sparkleStar": "auto_awesome",
    "heartBroken": "heart_broken", "heartHorns": "favorite", "heartSmall": "favorite", "pill": "medication",
    "star": "star", "sparkle": "auto_awesome", "calc": "calculate", "gear": "settings", "monitor": "desktop_windows",
    "keyboard": "keyboard", "mouse": "mouse", "chip": "memory", "speaker": "volume_up", "speakerMute": "volume_off",
    "mic": "mic", "micMute": "mic_off", "bell": "notifications", "bellOff": "notifications_off", "music": "music_note",
    "lock": "lock", "power": "power_settings_new", "moon": "dark_mode", "coffee": "coffee", "sun": "light_mode",
    "logout": "logout", "refresh": "refresh", "folder": "folder", "plug": "power", "image": "image",
    "palette": "palette", "layers": "layers", "package": "extension", "terminal": "terminal", "window": "web_asset",
    "calendar": "calendar_month", "info": "info", "warn": "warning", "trash": "delete", "search": "search",
    "check": "check", "close": "close", "minimize": "minimize", "maximize": "crop_square", "plus": "add",
    "minus": "remove", "arrowRight": "chevron_right", "arrowLeft": "chevron_left", "arrowDown": "expand_more",
    "arrowUp": "expand_less", "play": "play_arrow", "pause": "pause", "next": "skip_next", "prev": "skip_previous",
    "pin": "keep", "bot": "smart_toy", "botHorns": "smart_toy", "botHell": "smart_toy", "gauge": "speed",
    "skull": "skull", "eye": "visibility", "pentagram": "star", "ghost": "domino_mask", "spider": "pest_control",
    "wifi": "wifi", "wifiOff": "wifi_off", "wifi1": "wifi_1_bar", "wifi2": "wifi_2_bar", "ethernet": "lan",
    "bluetoothOff": "bluetooth_disabled", "bluetooth": "bluetooth", "gamepad": "sports_esports", "cursor": "arrow_selector_tool",
    "download": "download", "grid": "apps", "battery": "battery_full", "bolt": "bolt", "clock": "schedule",
    "drop": "water_drop", "leaf": "eco", "touchpad": "touchpad_mouse", "fingerprint": "fingerprint",
    "rotate": "screen_rotation", "plane": "flight", "laptop": "laptop", "cloud": "cloud", "cloudSun": "partly_cloudy_day",
    "rain": "rainy", "snow": "weather_snowy", "storm": "thunderstorm", "fog": "foggy", "hdd": "hard_drive",
    "note": "sticky_note_2", "external": "open_in_new", "width": "width", "scan": "document_scanner",
    "contrast": "contrast", "undo": "undo", "copy": "content_copy", "edit": "edit", "share": "share",
    "user": "person", "home": "home", "brush": "brush", "map": "map", "phone": "smartphone", "video": "videocam",
    "dotRing": "radio_button_unchecked", "crossInv": "add", "pentagramInv": "star"
};

function fromPixel(name) {
    return map[name] || "";
}

function family(style) {
    return style === "outlined" ? "Material Symbols Outlined" : style === "sharp" ? "Material Symbols Sharp" : "Material Symbols Rounded";
}
