pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Панель эмодзи как Win + . в Windows. Данные: emoji.json (Unicode emoji-test +
// русские названия CLDR, без тонов кожи — тон накладывается на лету) и extras.json
// (каомодзи и символы). Вставка: панель закрывается, фокус возвращается окну,
// текст кладётся в буфер (wl-copy) и печатается туда, где курсор (wtype).
Item {
    id: root

    property var plugin
    property bool open: false
    property string tab: "emoji"       // emoji | kaomoji | symbols | clipboard

    property var emoji: []
    property var kaomoji: []
    property var symbols: []
    property var recent: plugin ? plugin.get("recent", []) : []      // [{s, n}]
    property int tone: plugin ? plugin.get("tone", 0) : 0             // 0 — жёлтый, 1..5
    readonly property bool typeIn: plugin ? plugin.get("typeIn", true) : true

    readonly property var tones: ["", "\u{1F3FB}", "\u{1F3FC}", "\u{1F3FD}", "\u{1F3FE}", "\u{1F3FF}"]
    readonly property var terminals: ["kitty", "foot", "footclient", "Alacritty", "org.wezfurlong.wezterm", "com.mitchellh.ghostty", "org.kde.konsole", "org.gnome.Console", "org.gnome.Terminal"]

    // эмодзи с учётом выбранного тона кожи
    function withTone(item) {
        if (!item.t || tone === 0)
            return item.e;
        const first = String.fromCodePoint(item.e.codePointAt(0));
        let rest = item.e.slice(first.length);
        if (rest.startsWith("️"))
            rest = rest.slice(1);
        return first + tones[tone] + rest;
    }
    function setTone(t) {
        tone = t;
        if (plugin)
            plugin.set("tone", t);
    }

    function remember(s, n) {
        const list = [{
                "s": s,
                "n": n || ""
            }].concat(recent.filter(r => r.s !== s)).slice(0, 36);
        recent = list;
        if (plugin)
            plugin.set("recent", list);
    }

    // клик: вставить (и в буфер); copyOnly — только в буфер
    function insert(s, n, copyOnly) {
        remember(s, n);
        open = false;
        pending.text = s;
        pending.copyOnly = copyOnly || !typeIn;
        pending.restart();
    }
    Timer {
        id: pending
        property string text: ""
        property bool copyOnly: false
        interval: 140       // дождаться, пока фокус клавиатуры вернётся окну
        onTriggered: Quickshell.execDetached(["sh", "-c", copyOnly ? 'printf %s "$1" | wl-copy' : 'printf %s "$1" | wl-copy; wtype -- "$1"', "sh", text])
    }

    // картинка из истории буфера: скопировать и нажать Ctrl+V (в терминале Ctrl+Shift+V)
    function pasteImage(entry, copyOnly) {
        open = false;
        Clipboard.copy(entry);
        if (copyOnly || !typeIn)
            return;
        const app = Niri.focusedWindow ? Niri.focusedWindow.app_id : "";
        imagePaste.command = terminals.includes(app) ? ["wtype", "-M", "ctrl", "-M", "shift", "v", "-m", "shift", "-m", "ctrl"] : ["wtype", "-M", "ctrl", "v", "-m", "ctrl"];
        imagePaste.restart();
    }
    Timer {
        id: imagePaste
        property var command: []
        interval: 260
        onTriggered: Quickshell.execDetached(command)
    }

    FileView {
        path: Qt.resolvedUrl("emoji.json").toString().replace("file://", "")
        onLoaded: root.emoji = JSON.parse(text())
    }
    FileView {
        path: Qt.resolvedUrl("extras.json").toString().replace("file://", "")
        onLoaded: {
            const d = JSON.parse(text());
            root.kaomoji = d.kaomoji;
            root.symbols = d.symbols;
        }
    }

    IpcHandler {
        target: "emoji"
        function toggle(): void {
            root.open = !root.open;
        }
        // emoji | kaomoji | symbols | clipboard
        function open(tab: string): void {
            root.tab = tab || "emoji";
            root.open = true;
        }
        function close(): void {
            root.open = false;
        }
        // вкл/выкл печать в окно (иначе — только копировать в буфер)
        function toggleTyping(): void {
            if (root.plugin)
                root.plugin.set("typeIn", !root.typeIn);
        }
    }

    EmojiWindow {
        host: root
    }
}
