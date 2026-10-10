pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Mod+G overlay (as in end-4 dots): notes, pictures, GIFs and videos laid over the
// screen. Pinned ones stay on top after the overlay closes and survive restarts.
// State: ~/.config/angelos/overlay.json; added files are copied (reflink on btrfs)
// to ~/.local/share/angelos/overlay so they do not vanish with the original.
Singleton {
    id: root

    property bool open: false
    property string screen: ""               // output the open overlay is shown on
    property bool picking: false             // file dialog running (the overlay steps aside)
    property int revision: 0                 // bumps on every change of an item
    readonly property string mediaDir: Config.home + "/.local/share/angelos/overlay"
    property var items: []                   // live list; patch() edits entries in place
    readonly property var ids: items.map(i => i.id)
    readonly property var imageExt: ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "avif", "apng", "jxl"]
    readonly property var animatedExt: ["gif", "webp", "apng"]
    readonly property var videoExt: ["mp4", "webm", "mkv", "mov", "avi", "m4v", "ogv"]
    readonly property var noteColors: ["pink", "yellow", "mint", "blue", "lilac", "theme"]

    function toggle() {
        if (open)
            open = false;
        else
            show();
    }
    function show() {
        screen = Shell.focusedScreen ? Shell.focusedScreen.name : "";
        Shell.closeStart();
        open = true;
    }

    // items on outputs that are gone fall back to the primary screen
    function screenOf(item) {
        return Shell.screenByName(item.screen) ? item.screen : (Shell.primaryScreen ? Shell.primaryScreen.name : "");
    }
    function byId(id) {
        return items.find(i => i.id === id) || null;
    }
    function kindOf(path) {
        const ext = String(path).split("?")[0].split(".").pop().toLowerCase();
        return videoExt.includes(ext) ? "video" : imageExt.includes(ext) ? "image" : "";
    }
    function isAnimated(path) {
        return animatedExt.includes(String(path).split(".").pop().toLowerCase());
    }

    function _commit(list) {
        items = list;
        revision++;
        saveTimer.restart();
    }
    function patch(id, fields) {
        const it = byId(id);
        if (!it)
            return;
        let changed = false;
        for (const k in fields)
            if (it[k] !== fields[k]) {
                it[k] = fields[k];
                changed = true;
            }
        if (!changed)
            return;
        revision++;
        saveTimer.restart();
    }
    function _place(w, h) {
        const s = Shell.screenByName(screen) || Shell.focusedScreen;
        const n = items.filter(i => i.screen === (s ? s.name : "")).length % 8;
        return {
            "screen": s ? s.name : "",
            "x": Math.round((s ? s.width : 1920) / 2 - w / 2 + n * 28 - 98),
            "y": Math.round((s ? s.height : 1080) / 2 - h / 2 + n * 28 - 70)
        };
    }
    function _add(fields) {
        const it = Object.assign({
            "id": Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36),
            "pinned": false,
            "clickable": false,
            "opacity": 1
        }, _place(fields.w, fields.h), fields);
        _commit(items.concat([it]));
        if (!open)
            show();
        return it.id;
    }

    function addNote(text) {
        return _add({
            "kind": "note",
            "w": 260,
            "h": 200,
            "text": text || "",
            "color": "pink",
            "fontSize": 0
        });
    }
    // copies the file first, the item appears once the copy is in place
    function addMedia(path) {
        path = decodeURIComponent(String(path).replace(/^file:\/\//, ""));
        const kind = kindOf(path);
        if (!kind || !path.startsWith("/"))
            return false;
        const name = path.split("/").pop();
        const dest = mediaDir + "/" + Date.now().toString(36) + "-" + name.replace(/[^A-Za-z0-9._-]/g, "_").slice(-80);
        const p = copier.createObject(root, {
            "command": ["sh", "-c", 'mkdir -p "$1" && cp --reflink=auto -- "$2" "$3"', "sh", mediaDir, path, dest]
        });
        p.done.connect(ok => {
            if (ok)
                _add({
                    "kind": kind,
                    "w": 360,
                    "h": 240,
                    "path": dest,
                    "name": name,
                    "muted": true,
                    "fit": true            // first load sizes the frame to the picture's ratio
                });
            p.destroy();
        });
        p.running = true;
        return true;
    }
    function addFromClipboard() {
        const img = Clipboard.history.find(h => h.kind === "image" && h.path);
        if (img)
            return addMedia(img.path);
        const txt = Clipboard.history.find(h => (h.kind || "text") === "text" && h.text);
        if (!txt)
            return false;
        const t = String(txt.text).trim();
        if (t.startsWith("/") || t.startsWith("file://"))
            if (addMedia(t))
                return true;
        addNote(t);
        return true;
    }
    function remove(id) {
        const it = byId(id);
        if (!it)
            return;
        _commit(items.filter(i => i.id !== id));
        if (it.path && it.path.startsWith(mediaDir + "/"))
            Quickshell.execDetached(["rm", "-f", "--", it.path]);
    }
    function clearUnpinned() {
        items.filter(i => !i.pinned).forEach(i => remove(i.id));
    }

    // zenity, kdialog as a fallback; the overlay hides so the dialog gets the keyboard
    function pickMedia() {
        if (picking)
            return;
        picking = true;
        open = false;
        picker.running = true;
    }
    Process {
        id: picker
        command: ["sh", "-c", 'if command -v zenity >/dev/null; then zenity --file-selection --multiple --separator="\n" --title="$1" --file-filter="$2 | *.png *.jpg *.jpeg *.gif *.webp *.bmp *.svg *.avif *.jxl *.mp4 *.webm *.mkv *.mov *.avi *.m4v *.ogv" --file-filter="* | *"; elif command -v kdialog >/dev/null; then kdialog --title "$1" --multiple --separate-output --getopenfilename "$HOME" "*.png *.jpg *.jpeg *.gif *.webp *.bmp *.svg *.avif *.jxl *.mp4 *.webm *.mkv *.mov *.avi *.m4v *.ogv|$2"; fi', "sh", I18n.t("Картинка, GIF или видео на экран", "Picture, GIF or video for the screen"), I18n.t("Картинки и видео", "Pictures and videos")]
        stdout: StdioCollector {
            onStreamFinished: {
                const files = text.split("\n").map(s => s.trim()).filter(s => s !== "");
                root.picking = false;
                files.forEach(f => root.addMedia(f));
                if (files.length === 0)
                    root.show();
            }
        }
    }
    Component {
        id: copier
        Process {
            signal done(bool ok)
            onExited: code => done(code === 0)
        }
    }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: {
            adapter.items = JSON.parse(JSON.stringify(root.items));
            file.writeAdapter();
        }
    }
    FileView {
        id: file
        path: Config.dir + "/overlay.json"
        onLoaded: {
            root.items = JSON.parse(JSON.stringify(adapter.items || [])).filter(i => i && i.id && i.kind);
            root.revision++;
        }
        JsonAdapter {
            id: adapter
            property var items: []
        }
    }
}
