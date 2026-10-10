pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets
import "."

// Счётчик Гейгера из кейса тира. Пока он в руке, весь экран — поле замера:
// фонят окна (у каждого приложения свой уровень и «горячее пятно» внутри),
// печать Бафомета на обоях, если стол пустой, и спрятанные изотопы — их надо
// найти по щелчкам. ЛКМ — замер на месте, ПКМ / СКМ / Esc — убрать.
Item {
    id: root

    property var plugin
    property bool sound: true
    property real volume: 0.6

    readonly property real background: 0.45      // фон, щелчков в секунду
    readonly property real usvPerCps: 0.26        // 0.45 cps ≈ 0.12 мкЗв/ч
    readonly property real maxCps: 400

    // насколько «светится» приложение, 0..1; остальным — свой стабильный случайный уровень
    readonly property var apps: ({
            "discord": 0.9,
            "vesktop": 0.9,
            "equibop": 0.9,
            "cs2": 1,
            "steam": 0.6,
            "org.vinegarhq.Sober": 0.75,
            "org.vinegarhq.Vinegar": 0.75,
            "kitty": 0.5,
            "zen": 0.3,
            "firefox": 0.3,
            "org.telegram.desktop": 0.55,
            "next-music": 0.2,
            "spotify": 0.2,
            "dev.diktor.Diktor": 0.35,
            "org.gnome.Nautilus": 0.05
        })
    readonly property var isotopeNames: ["Цезий-137", "Кобальт-60", "Стронций-90", "Радий-226", "Америций-241", "Плутоний-239", "Уран-235", "Полоний-210", "Иод-131"]

    property real mx: -1000
    property real my: -1000
    property bool aiming: false
    property real now: Date.now()
    property real lastClick: 0
    property real shownCps: background
    property real cps: background
    property string source: ""
    property var isotopes: []
    property int nextClick: 0

    readonly property real usv: shownCps * usvPerCps

    Component.onDestruction: Gun.geiger = false

    Connections {
        target: Gun
        function onGeigerChanged() {
            if (Gun.geiger)
                root.scatter();
        }
    }

    function hash(s) {
        let h = 2166136261;
        for (let i = 0; i < s.length; i++)
            h = Math.imul(h ^ s.charCodeAt(i), 16777619);
        return (h >>> 0) / 4294967296;
    }
    function appLevel(app) {
        if (apps[app] !== undefined)
            return apps[app];
        const r = hash(app || "?");
        return r < 0.35 ? 0 : (r - 0.35) * 0.7;
    }

    // a fresh set of hidden sources every time the counter is taken
    function scatter() {
        const scr = win.screen;
        const w = scr ? scr.width : 1920, h = scr ? scr.height : 1080;
        const names = isotopeNames.slice();
        const list = [];
        for (let i = 0; i < 3; i++) {
            const n = names.splice(Math.floor(Math.random() * names.length), 1)[0];
            list.push({
                "x": w * (0.06 + Math.random() * 0.88),
                "y": h * (0.08 + Math.random() * 0.76),
                "name": n,
                "str": 120 + Math.random() * 160,
                "found": false
            });
        }
        isotopes = list;
        floaters.clear();
    }

    // ---- windows of the active workspace, in screen coordinates ----
    // niri reports positions only for floating windows; with
    // center-focused-column "always" the focused column sits in the middle of
    // the working area and the others follow by width + gaps (as in angelos-shot)
    property real gaps: 16
    property bool centred: true
    FileView {
        path: Quickshell.env("HOME") + "/.config/niri/cfg/layout.kdl"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const src = text().replace(/\/\/[^\n]*/g, "");
            const m = src.match(/\bgaps\s+([\d.]+)/);
            if (m)
                root.gaps = parseFloat(m[1]);
            root.centred = /center-focused-column\s+"always"/.test(src);
        }
    }

    readonly property var rects: {
        const scr = win.screen;
        if (!Gun.geiger || !scr || Niri.overviewOpen)
            return [];
        const ws = Niri.activeWorkspace(scr.name);
        if (!ws)
            return [];
        const ow = win.width, oh = win.height;
        const top = Config.bar.style !== "taskbar";
        const wa = [0, top ? oh - probe.height : 0, probe.width || ow, probe.height || oh];
        const mine = Niri.windows.filter(w => w.workspace_id === ws.id);
        const out = [];
        const cols = {};
        for (const w of mine) {
            const lay = w.layout || {};
            if (w.is_floating && lay.tile_pos_in_workspace_view) {
                const off = lay.window_offset_in_tile || [0, 0];
                out.push({
                    "x": wa[0] + lay.tile_pos_in_workspace_view[0] + off[0],
                    "y": wa[1] + lay.tile_pos_in_workspace_view[1] + off[1],
                    "w": lay.window_size[0],
                    "h": lay.window_size[1],
                    "win": w
                });
            } else if (!w.is_floating && lay.pos_in_scrolling_layout) {
                const c = lay.pos_in_scrolling_layout[0];
                (cols[c] = cols[c] || []).push(w);
            }
        }
        const order = Object.keys(cols).map(Number).sort((a, b) => a - b);
        if (!root.centred || !order.length)
            return out;
        let active = mine.find(w => w.id === ws.active_window_id && !w.is_floating && w.layout && w.layout.pos_in_scrolling_layout);
        if (!active) {
            const ts = w => (w.focus_timestamp ? w.focus_timestamp.secs + w.focus_timestamp.nanos / 1e9 : 0);
            active = order.map(c => cols[c]).flat().reduce((a, b) => ts(b) > ts(a) ? b : a);
        }
        const acol = active.layout.pos_in_scrolling_layout[0];
        const width = {};
        for (const c of order)
            width[c] = Math.max(...cols[c].map(w => w.layout.tile_size[0]));
        const xs = {};
        xs[acol] = width[acol] >= ow - 0.5 ? 0 : wa[0] + (wa[2] - width[acol]) / 2;
        const i = order.indexOf(acol);
        for (let j = i + 1; j < order.length; j++)
            xs[order[j]] = xs[order[j - 1]] + width[order[j - 1]] + root.gaps;
        for (let j = i - 1; j >= 0; j--)
            xs[order[j]] = xs[order[j + 1]] - root.gaps - width[order[j]];
        for (const c of order) {
            const items = cols[c].slice().sort((a, b) => a.layout.pos_in_scrolling_layout[1] - b.layout.pos_in_scrolling_layout[1]);
            const heights = items.map(w => w.layout.tile_size[1]);
            const stacked = items.length > 1 && heights.reduce((a, b) => a + b, 0) + root.gaps * (items.length + 1) <= wa[3] + 1;
            let y = wa[1] + root.gaps;
            items.forEach((w, k) => {
                const lay = w.layout, th = heights[k];
                let ty;
                if (th >= oh - 0.5)
                    ty = 0;
                else if (stacked) {
                    ty = y;
                    y += th + root.gaps;
                } else
                    ty = wa[1] + Math.max(0, (wa[3] - th) / 2);
                const off = lay.window_offset_in_tile || [0, 0];
                const x0 = xs[c] + (width[c] - lay.tile_size[0]) / 2 + off[0];
                const r = {
                    "x": Math.max(0, x0),
                    "y": Math.max(0, ty + off[1]),
                    "w": Math.min(ow, x0 + lay.window_size[0]) - Math.max(0, x0),
                    "h": Math.min(oh, ty + off[1] + lay.window_size[1]) - Math.max(0, ty + off[1]),
                    "win": w
                };
                if (r.w > 8 && r.h > 8)
                    out.push(r);
            });
        }
        return out;
    }

    // the sigil on the wallpaper (plugin sigil-wallpaper), when the desk is empty
    readonly property var sigil: {
        const scr = win.screen;
        if (!Gun.geiger || !scr)
            return null;
        const ws = Niri.activeWorkspace(scr.name);
        if (!ws || Niri.windowsOn(ws.id).length || !/sigil|baphomet/i.test(Wallpapers.resolve(scr.name, ws.idx)))
            return null;
        const k = Math.max(win.width / 3840, win.height / 2160);
        return {
            "x": (win.width - 3840 * k) / 2 + 1920 * k,
            "y": (win.height - 2160 * k) / 2 + 1050 * k,
            "r": 500 * k
        };
    }

    // clicks per second at a point, and who is to blame
    function measure(x, y) {
        let total = background, best = "", bestCps = 0;
        const add = (c, name) => {
            total += c;
            if (c > bestCps) {
                bestCps = c;
                best = name;
            }
        };
        for (const r of rects) {
            const L = appLevel(r.win.app_id);
            if (!L)
                continue;
            const dx = Math.max(r.x - x, 0, x - r.x - r.w), dy = Math.max(r.y - y, 0, y - r.y - r.h);
            const d = Math.hypot(dx, dy);
            if (d > 0) {
                add(L * 3 / (1 + (d / 40) * (d / 40)), r.win.app_id);
                continue;
            }
            // a hot spot somewhere inside every window, the same one each time
            const hx = r.x + r.w * (0.2 + 0.6 * hash("x" + r.win.id)), hy = r.y + r.h * (0.2 + 0.6 * hash("y" + r.win.id));
            const dh = Math.hypot(x - hx, y - hy) / 140;
            add(L * (3 + 45 / (1 + dh * dh)), r.win.app_id);
        }
        if (sigil) {
            const d = Math.hypot(x - sigil.x, y - sigil.y);
            const core = d / (sigil.r * 0.25);
            const ring = (d - sigil.r) / (sigil.r * 0.08);
            add(260 / (1 + core * core) + 25 * Math.exp(-ring * ring), I18n.t("печать Бафомета", "the sigil"));
        }
        for (const s of isotopes) {
            const d = Math.hypot(x - s.x, y - s.y) / 36;
            add(s.str / (1 + d * d), s.found ? s.name : "???");
        }
        return {
            "cps": Math.min(total, maxCps),
            "source": bestCps > background * 2 ? best : ""
        };
    }

    function poisson(mean) {
        if (mean > 30)
            return Math.max(0, Math.round(mean + Math.sqrt(mean) * (Math.random() + Math.random() + Math.random() - 1.5) * 2));
        const L = Math.exp(-mean);
        let k = 0, p = 1;
        do {
            k++;
            p *= Math.random();
        } while (p > L)
        return k - 1;
    }

    function click() {
        lastClick = now;
        if (sound)
            pool.objectAt(nextClick++ % pool.count).play();
    }

    function fmt(v) {
        return v < 10 ? v.toFixed(2) : v < 100 ? v.toFixed(1) : Math.min(9999, Math.round(v)).toString();
    }

    function reading(x, y) {
        const r = measure(x, y);
        floaters.append({
            "x": x,
            "y": y,
            "text": fmt(r.cps * usvPerCps) + I18n.t(" мкЗв/ч", " µSv/h") + (r.source && r.source !== "???" ? "  · " + r.source : ""),
            "good": false,
            "at": now
        });
    }

    Instantiator {
        id: pool
        model: 8
        delegate: SoundEffect {
            required property int index
            source: root.plugin ? root.plugin.url("sfx/geiger" + (index % 3 + 1) + ".wav") : ""
            volume: root.volume * 0.8
        }
    }

    ListModel {
        id: floaters
    }

    // invisible layer that only measures the working area (the screen minus the bar)
    PanelWindow {
        id: probe
        screen: win.screen
        visible: Gun.geiger
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "angelos-geiger-probe"
        WlrLayershell.layer: WlrLayer.Background
        // a right click into the window's corner can crash Qt (widgets/RightClickGuard)
        RightClickGuard {}
    }

    PanelWindow {
        id: win

        readonly property int u: Theme.u
        readonly property int k: Math.max(2, Math.round(Theme.u * 1.5))

        screen: Shell.focusedScreen
        visible: Gun.geiger
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "angelos-geiger"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Gun.geiger ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        onVisibleChanged: if (visible)
            keys.forceActiveFocus()

        FrameAnimation {
            running: win.visible
            onTriggered: {
                const dt = Math.min(frameTime, 0.05);
                root.now = Date.now();
                const r = root.aiming ? root.measure(root.mx, root.my) : {
                    "cps": root.background,
                    "source": ""
                };
                root.cps = r.cps;
                root.source = r.source;
                const n = root.poisson(r.cps * dt);
                if (n > 0)
                    root.click();
                // the display averages the clicks it really counted, like a real one
                root.shownCps += (n / dt - root.shownCps) * (1 - Math.exp(-dt / (r.cps > 20 ? 0.5 : 1.4)));
                if (root.aiming)
                    for (let i = 0; i < root.isotopes.length; i++) {
                        const s = root.isotopes[i];
                        if (!s.found && Math.hypot(root.mx - s.x, root.my - s.y) < win.u * 11) {
                            const list = root.isotopes.slice();
                            list[i] = Object.assign({}, s, {
                                "found": true
                            });
                            root.isotopes = list;
                            floaters.append({
                                "x": s.x,
                                "y": s.y - win.u * 10,
                                "text": I18n.t("Найден: ", "Found: ") + s.name + "!",
                                "good": true,
                                "at": root.now
                            });
                        }
                    }
                for (let i = floaters.count - 1; i >= 0; i--)
                    if (root.now - floaters.get(i).at > 1800)
                        floaters.remove(i);
            }
        }

        // a high dose: the screen edges turn green and snow appears
        Item {
            id: glow
            readonly property real level: Math.max(0, Math.min(1, (root.usv - 8) / 60))
            anchors.fill: parent
            visible: level > 0
            opacity: level * (0.75 + 0.25 * Math.sin(root.now / 90))
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    readonly property bool side: index >= 2
                    width: side ? win.u * 60 : glow.width
                    height: side ? glow.height : win.u * 60
                    x: index === 3 ? glow.width - width : 0
                    y: index === 1 ? glow.height - height : 0
                    gradient: Gradient {
                        orientation: parent.side ? Gradient.Horizontal : Gradient.Vertical
                        GradientStop {
                            position: 0
                            color: parent.index === 1 || parent.index === 3 ? "transparent" : Qt.alpha("#5dff3a", 0.45)
                        }
                        GradientStop {
                            position: 1
                            color: parent.index === 1 || parent.index === 3 ? Qt.alpha("#5dff3a", 0.45) : "transparent"
                        }
                    }
                }
            }
        }
        Repeater {
            model: glow.level > 0.2 ? Math.round(glow.level * 40) : 0
            Rectangle {
                required property int index
                readonly property real seed: Math.floor(root.now / 50) * 97 + index * 31
                x: (Math.sin(seed) * 0.5 + 0.5) * win.width
                y: (Math.sin(seed * 1.7 + 3) * 0.5 + 0.5) * win.height
                width: win.k
                height: win.k
                color: index % 3 ? "#e8ffe0" : "#7dff4a"
                opacity: 0.7
            }
        }

        // found isotopes stay where they lie
        Repeater {
            model: root.isotopes
            Item {
                id: iso
                required property var modelData
                visible: modelData.found
                x: modelData.x
                y: modelData.y
                readonly property real pulse: 0.5 + 0.5 * Math.sin(root.now / 160 + modelData.x)
                Rectangle {
                    anchors.centerIn: parent
                    width: win.k * (6 + iso.pulse * 3)
                    height: width
                    radius: width / 2
                    color: Qt.alpha("#5dff3a", 0.18 + 0.12 * iso.pulse)
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: win.k * 3
                    height: win.k * 3
                    color: "#7dff4a"
                    border.width: Math.max(1, win.k / 2)
                    border.color: "#1f5f12"
                }
                PxText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: win.k * 5
                    text: "☢ " + iso.modelData.name
                    kind: "tiny"
                    color: "#b6ff9a"
                    style: Text.Outline
                    styleColor: "#000000"
                }
            }
        }

        Repeater {
            model: floaters
            PxText {
                required property var model
                readonly property real t: (root.now - model.at) / 1800
                x: model.x - width / 2
                y: model.y - win.u * 14 - t * win.u * 16
                opacity: Math.min(1, (1 - t) * 2)
                text: model.text
                kind: model.good ? "title" : "body"
                font.bold: true
                color: model.good ? "#7dff4a" : "#ffffff"
                style: Text.Outline
                styleColor: "#000000"
            }
        }

        // ---- the counter in hand: probe tip at the cursor ----
        Item {
            id: device
            readonly property int k: win.k
            readonly property bool flip: root.mx > win.width - k * 56
            readonly property real bodyY: Math.max(-k * 24, Math.min(-k * 7, win.height - root.my - k * 27))
            readonly property bool beep: root.now - root.lastClick < 35
            readonly property bool alarm: root.usv > 30
            visible: root.aiming
            x: root.mx
            y: root.my
            // a little shake on every click
            transform: Translate {
                x: device.beep ? (Math.random() - 0.5) * win.u : 0
                y: device.beep ? (Math.random() - 0.5) * win.u : 0
            }

            // probe: grille at the tip, metal tube
            Rectangle {
                x: device.flip ? -device.k * 15 : 0
                y: -device.k * 2
                width: device.k * 15
                height: device.k * 4
                color: "#9aa1ad"
                border.width: Math.max(1, device.k / 2)
                border.color: "#15161a"
                Rectangle {
                    x: device.k
                    y: device.k / 2 + 1
                    width: parent.width - device.k * 2
                    height: Math.max(1, device.k / 2)
                    color: "#d8dde6"
                }
                Row {
                    x: device.flip ? parent.width - width - device.k / 2 : device.k / 2
                    y: device.k / 2
                    height: parent.height - device.k
                    spacing: Math.max(1, device.k / 2)
                    Repeater {
                        model: 3
                        Rectangle {
                            width: Math.max(1, device.k / 2)
                            height: parent.height
                            color: "#2a2c31"
                        }
                    }
                }
            }

            // body
            Rectangle {
                id: body
                x: device.flip ? -device.k * 52 : device.k * 14
                y: device.bodyY
                width: device.k * 38
                height: device.k * 26
                color: "#f2c230"
                border.width: device.k
                border.color: "#15161a"
                Rectangle {
                    x: device.k
                    y: parent.height - device.k * 3
                    width: parent.width - device.k * 2
                    height: device.k * 2
                    color: "#c99a1a"
                }

                // display
                Rectangle {
                    x: device.k * 3
                    y: device.k * 3
                    width: parent.width - device.k * 6
                    height: device.k * 10
                    color: device.alarm && Math.floor(root.now / 250) % 2 ? "#4a1414" : "#1b2a17"
                    border.width: Math.max(1, device.k / 2)
                    border.color: "#0b0f0a"
                    PxText {
                        anchors.left: parent.left
                        anchors.leftMargin: device.k
                        anchors.top: parent.top
                        anchors.topMargin: device.k / 2
                        text: root.fmt(root.usv)
                        kind: "title"
                        font.bold: true
                        color: device.alarm ? "#ff6a5a" : "#9cff7a"
                    }
                    PxText {
                        anchors.right: parent.right
                        anchors.rightMargin: device.k
                        anchors.top: parent.top
                        anchors.topMargin: device.k
                        text: I18n.t("мкЗв/ч", "µSv/h")
                        kind: "tiny"
                        color: "#6fbf55"
                    }
                    PxText {
                        anchors.left: parent.left
                        anchors.leftMargin: device.k
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: device.k / 2
                        elide: Text.ElideRight
                        text: device.alarm ? I18n.t("ОПАСНО!", "DANGER!") : root.source ? "▸ " + root.source : I18n.t("фон", "background")
                        kind: "tiny"
                        color: device.alarm ? "#ff6a5a" : "#6fbf55"
                    }
                }

                // log meter 0.1 … 1000 мкЗв/ч
                Row {
                    id: meter
                    readonly property real frac: Math.max(0, Math.min(1, Math.log10(Math.max(root.usv, 0.1) / 0.1) / 4))
                    x: device.k * 3
                    y: device.k * 15
                    spacing: Math.max(1, device.k / 3)
                    Repeater {
                        model: 10
                        Rectangle {
                            required property int index
                            width: device.k * 2
                            height: device.k * 3
                            color: index < 4 ? "#3fbf3f" : index < 7 ? "#f2a02a" : "#e0322a"
                            opacity: (index + 0.5) / 10 <= meter.frac ? 1 : 0.22
                            border.width: Math.max(1, device.k / 3)
                            border.color: "#15161a"
                        }
                    }
                }
                // LED
                Rectangle {
                    x: parent.width - device.k * 6
                    y: device.k * 15
                    width: device.k * 3
                    height: device.k * 3
                    radius: width / 2
                    color: device.beep ? "#ff3a2a" : "#5a1a16"
                    border.width: Math.max(1, device.k / 3)
                    border.color: "#15161a"
                }
                Text {
                    x: device.k * 3
                    y: device.k * 18.5
                    text: "☢"
                    font.pixelSize: device.k * 5
                    color: "#15161a"
                }
                // speaker
                Column {
                    x: parent.width - device.k * 16
                    y: device.k * 19.5
                    spacing: Math.max(1, device.k / 2)
                    Repeater {
                        model: 2
                        Rectangle {
                            width: device.k * 12
                            height: Math.max(1, device.k / 2)
                            color: "#7a5a0a"
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.BlankCursor
            onContainsMouseChanged: root.aiming = containsMouse
            onPositionChanged: m => {
                root.mx = m.x;
                root.my = m.y;
                root.aiming = true;
            }
            onPressed: m => {
                keys.forceActiveFocus();
                if (m.button === Qt.LeftButton)
                    root.reading(m.x, m.y);
                else
                    Gun.geiger = false;
            }
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape)
                    Gun.geiger = false;
                else
                    return;
                e.accepted = true;
            }
        }

        PxBox {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: win.u * 6
            width: hint.implicitWidth + win.u * 8
            height: hint.implicitHeight + win.u * 4
            color: Qt.alpha(Theme.face, 0.92)
            PxText {
                id: hint
                anchors.centerIn: parent
                kind: "tiny"
                text: I18n.t("☢ найдено изотопов: ", "☢ isotopes found: ") + root.isotopes.filter(s => s.found).length + "/" + root.isotopes.length + "   " + I18n.t("ЛКМ — замер · ПКМ/Esc — убрать", "LMB — reading · RMB/Esc — put away")
            }
        }
        // a right click into the window's corner can crash Qt (widgets/RightClickGuard)
        RightClickGuard {}
    }
}
