pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// TrollOS: desktop layouts (Settings → Макеты): a whole look in one click — the palette, the
// panel's layout (services/DesktopLayouts), the Start wordmark and emblem, the desk sprites,
// the angel's look, a cursor and Pixora icons in its colours (scripts/preset-assets.py), the
// wallpaper as a picture or alive (modules/background/ShaderWalls).
//
//   apply(id, animated)   the first apply keeps what was there before in
//                         ~/.local/state/angelos/desktop-preset-before.json; restore() puts
//                         all of it back and forgets it
//   `qs -c angelos ipc call presets list | apply <id> [still] | restore | status`
Singleton {
    id: root

    // ---- the layouts ----
    // settings: "section.key" -> value; plugins: id -> on (a plugin that isn't installed is
    // skipped); cursor: [theme, primary, secondary, border]; icons: [name, lightness ramp]
    readonly property var presets: [
        {
            "id": "satanic",
            "name": "Satanic Theme (Flen)",
            "about": I18n.t("Как у автора TrollOS: чёрный с кровью и золотом, кресты на столах, пентаграмма в «Пуске», готика кровью, барашек вместо ангела, красный курсор и иконки, адская туманность.", "As the author of TrollOS has it: black with blood and gold, crosses on the desks, a pentagram in Start, blood gothic, the lamb for the angel, a red cursor and icons, the hell nebula."),
            "shader": "nebula",
            "swatch": ["#0b0607", "#d3202e", "#c9a24a", "#ecdccb"],
            "layout": "default",
            "settings": {
                "appearance.flavor": "inferno",
                "appearance.customAccent": "#991f28",
                "appearance.mode": "dark",
                "appearance.fontTitle": "",
                "settingsUi.skin": "classic",
                "bar.logoStyle": "infernoGothic",
                "bar.logoEmblem": "pentagramRed",
                "bar.logoText": true,
                "bar.showMedia": false,
                "bar.inferno": false,
                "workspaces.sprite": "cross",
                "y2k.angelLook": "lamb",
                "y2k.helper": false,
                "y2k.sparkles": true
            },
            "plugins": {
                "hell-nebula": false,
                "layout-fx": true,
                "bandage-cat": true,
                "cat": false
            },
            "cursor": ["TrollOS-Inferno", "#d3202e", "#7a0a16", "#120306"],
            "icons": ["inferno", [[0, "#120306"], [0.28, "#480a16"], [0.55, "#c41a2a"], [0.78, "#e87860"], [1, "#ecdccb"]]]
        },
        {
            "id": "vampire",
            "name": I18n.t("Vampire · Готика", "Vampire · Gothic"),
            "about": I18n.t("Ночь, вино и серебро: луна над готическим замком, летучие мыши, туман. Классическая панель, кресты на столах, полумесяц и «Nocturne» серебром в «Пуске».", "Night, wine and silver: the moon over a gothic castle, bats, fog. The classic panel, crosses on the desks, a crescent and «Nocturne» in silver on Start."),
            "shader": "vampire",
            "swatch": ["#0d0a12", "#b0285f", "#c8c3d6", "#e6e1ef"],
            "layout": "classic",
            "settings": {
                "appearance.flavor": "vampire",
                "appearance.customAccent": "",
                "appearance.mode": "dark",
                "appearance.fontTitle": "",
                "settingsUi.skin": "classic",
                "bar.logoStyle": "vampireNocturne",
                "bar.logoEmblem": "moon",
                "bar.logoText": true,
                "bar.inferno": false,
                "workspaces.sprite": "cross",
                "y2k.angelLook": "adult",
                "y2k.helper": false,
                "y2k.sparkles": false
            },
            "plugins": {
                "hell-nebula": false
            },
            "cursor": ["TrollOS-Vampire", "#e6e1ef", "#b0285f", "#0d0a12"],
            "icons": ["vampire", [[0, "#0a0710"], [0.3, "#3a1430"], [0.55, "#8e2a5c"], [0.78, "#a89cc4"], [1, "#eeeaf6"]]]
        },
        {
            "id": "void",
            "name": I18n.t("Void · Минимал", "Void · Minimal"),
            "about": I18n.t("Чёрное и белое, ничего лишнего: для учёбы и работы, бережёт батарею ноутбука. Компактная панель, затмение и «V O I D» в «Пуске», точки на столах, ангел спрятан, медленное звёздное поле.", "Black and white, nothing extra: for study and work, easy on a laptop's battery. The compact panel, an eclipse and «V O I D» on Start, dots on the desks, the angel hidden, a slow starfield."),
            "shader": "void",
            "swatch": ["#0a0a0a", "#d0d0d0", "#7aa2c8", "#e8e8e8"],
            "layout": "compact",
            "settings": {
                "appearance.flavor": "void",
                "appearance.customAccent": "",
                "appearance.mode": "dark",
                "appearance.fontTitle": "",
                "settingsUi.skin": "classic",
                "bar.logoStyle": "voidCaps",
                "bar.logoEmblem": "eclipse",
                "bar.logoText": true,
                "bar.inferno": false,
                "workspaces.sprite": "dot",
                "y2k.helper": false,
                "y2k.sparkles": false
            },
            "plugins": {
                "hell-nebula": false
            },
            "cursor": ["TrollOS-Void", "#f2f2f2", "#8a8a8a", "#0a0a0a"],
            "icons": ["void", [[0, "#0a0a0a"], [0.35, "#3a3a3a"], [0.65, "#9a9a9a"], [1, "#f2f2f2"]]]
        }
        ,
        {
            "id": "material",
            "name": "Material You",
            "about": I18n.t("Вся система как Android: Material 3 — скругления, Roboto, символы, плавающая панель-таблетка, значки и цвета из одного акцента. Акцент, стиль палитры, углы и значки — в «Material You».", "The whole system like Android: Material 3 — rounded shapes, Roboto, symbols, a floating pill panel, icons and colours from one accent. The accent, the palette style, corners and icons — under «Material You»."),
            "shader": "material",
            "swatch": ["#141218", "#d0bcff", "#efb8c8", "#e6e0e9"],
            "layout": "default",
            "settings": {
                "appearance.flavor": "material",
                "appearance.customAccent": "",
                "appearance.fontTitle": "",
                "settingsUi.skin": "material",
                "bar.style": "taskbar",
                "bar.logoStyle": "classic",
                "bar.logoEmblem": "splat",
                "bar.logoText": true,
                "bar.inferno": false,
                "workspaces.sprite": "heart",
                "y2k.helper": false,
                "y2k.sparkles": false
            },
            "plugins": {
                "hell-nebula": false,
                "layout-fx": false,
                "bandage-cat": false,
                "cat": false,
                "panel-shooter": false,
                "friend-runner": false
            },
            "cursorTheme": "Adwaita",
            "fonts": true
        }
    ]
    function byId(id) {
        return presets.find(p => p.id === id) || null;
    }
    function still(p) {
        return Quickshell.shellDir + "/data/wallshaders/stills/" + p.shader + ".jpg";
    }
    // a laptop on its battery: the page offers the picture first
    readonly property bool preferStill: Power.discharging

    // ---- the state ----
    property string current: ""              // the layout last applied ("" = none / restored)
    property var before: null                // what was there before the first apply
    property string busy: ""                 // the layout being applied
    property string step: ""                 // what it's doing (the page shows it)
    property string error: ""
    readonly property bool canRestore: !!before

    readonly property string statePath: Config.stateDir + "/desktop-preset-before.json"
    AsyncFile {
        id: file
        path: root.statePath
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.before = j.before || null;
                root.current = j.current || "";
            } catch (e) {
                root.before = null;
            }
        }
    }
    function _save() {
        file.write(JSON.stringify({
            "version": 1,
            "current": current,
            "before": before
        }, null, 1));
    }

    function _get(path) {
        const i = path.indexOf(".");
        const sec = Config[path.slice(0, i)];
        return sec ? sec[path.slice(i + 1)] : undefined;
    }
    function _set(path, v) {
        const i = path.indexOf(".");
        const sec = Config[path.slice(0, i)];
        if (sec)
            sec[path.slice(i + 1)] = JSON.parse(JSON.stringify(v));
    }
    function _plugin(id) {
        return Plugins.byId(id);
    }

    // everything any layout touches, as it is now
    function _snapshot() {
        const settings = {}, plugins = {};
        for (const p of presets) {
            for (const k of Object.keys(p.settings))
                settings[k] = _get(k);
            for (const id of Object.keys(p.plugins)) {
                const pl = _plugin(id);
                if (pl)
                    plugins[id] = Plugins.isEnabled(pl);
            }
        }
        return {
            "settings": JSON.parse(JSON.stringify(settings)),
            "plugins": plugins,
            "layout": Config.bar.layoutPreset || "default",
            "cursor": [Config.cursor.theme, Config.cursor.size],
            "iconTheme": iconTheme,
            "wallpaper": {
                "fallback": Config.wallpaper.fallback,
                "outputs": JSON.parse(JSON.stringify(Config.wallpaper.outputs || {})),
                "workspaces": JSON.parse(JSON.stringify(Config.wallpaper.workspaces || {})),
                "shaders": Config.wallpaper.shaders
            }
        };
    }

    // the GTK icon theme in use (asked once at start, and before a snapshot)
    property string iconTheme: ""
    Process {
        id: iconProbe
        running: Config.ready
        command: ["python3", Quickshell.shellDir + "/scripts/preset-assets.py", "icon-theme-status"]
        stdout: StdioCollector {
            onStreamFinished: root.iconTheme = text.trim()
        }
    }

    // ---- applying ----
    // the assets go first (icons, the icon theme, the cursor), then the settings: the palette's
    // change renders the templates, and folder-tint tints the folders over the new icons
    property var _queue: []
    property var _then: null
    function _run(cmds, then) {
        _queue = cmds.slice();
        _then = then;
        _next();
    }
    function _next() {
        if (!_queue.length) {
            const f = _then;
            _then = null;
            if (f)
                f();
            return;
        }
        const c = _queue.shift();
        step = c.label;
        worker.command = c.cmd;
        worker.running = true;
    }
    Process {
        id: worker
        property string err: ""
        stderr: StdioCollector {
            onStreamFinished: worker.err = text.trim()
        }
        onExited: code => {
            // a cursor or icons that didn't build leave the old ones: the rest still goes on
            if (code !== 0)
                root.error = (root.error ? root.error + "\n" : "") + root.step + ": " + (worker.err.split("\n").pop() || ("exit " + code));
            root._next();
        }
    }
    function _assets(p) {
        const py = ["python3", Quickshell.shellDir + "/scripts/preset-assets.py"];
        const out = [];
        if (p.fonts)
            out.push({
                "label": I18n.t("Скачиваю шрифты Material…", "Fetching Material's fonts…"),
                "cmd": py.concat(["fonts"])
            });
        if (p.icons) {
            out.push({
                "label": I18n.t("Перекрашиваю иконки…", "Recolouring the icons…"),
                "cmd": py.concat(["icons", p.icons[0], JSON.stringify(p.icons[1])])
            });
            out.push({
                "label": I18n.t("Ставлю иконки…", "Setting the icons…"),
                "cmd": py.concat(["icon-theme", "pixora-" + p.icons[0]])
            });
        }
        if (p.cursor)
            out.push({
                "label": I18n.t("Собираю курсор…", "Building the cursor…"),
                "cmd": py.concat(["cursor"].concat(p.cursor))
            });
        return out;
    }

    function apply(id, animated) {
        const p = byId(id);
        if (!p || busy)
            return false;
        if (!before) {
            before = _snapshot();
            _save();
        }
        busy = id;
        error = "";
        _run(Shell.dev ? [] : _assets(p), () => {
            root.step = I18n.t("Применяю…", "Applying…");
            for (const k of Object.keys(p.settings))
                root._set(k, p.settings[k]);
            DesktopLayouts.apply(p.layout);
            for (const pid of Object.keys(p.plugins))
                if (root._plugin(pid))
                    Plugins.setEnabled(pid, p.plugins[pid]);
            Config.wallpaper.shaders = !!animated;
            Wallpapers.setEverywhere(root.still(p));
            if (p.cursor && !Shell.dev)
                Cursors.apply(p.cursor[0], Config.cursor.size || 24);
            else if (p.cursorTheme && !Shell.dev)
                Cursors.apply(p.cursorTheme, Config.cursor.size || 24);
            root.current = id;
            root._save();
            ThemeExport.apply();
            root._done();
        });
        return true;
    }

    function restore() {
        const b = before;
        if (!b || busy)
            return false;
        busy = "restore";
        error = "";
        const py = ["python3", Quickshell.shellDir + "/scripts/preset-assets.py"];
        const cmds = b.iconTheme && !Shell.dev ? [
            {
                "label": I18n.t("Возвращаю иконки…", "Putting the icons back…"),
                "cmd": py.concat(["icon-theme", b.iconTheme])
            }
        ] : [];
        _run(cmds, () => {
            root.step = I18n.t("Возвращаю…", "Putting it back…");
            for (const k of Object.keys(b.settings || {}))
                if (b.settings[k] !== undefined)
                    root._set(k, b.settings[k]);
            DesktopLayouts.apply(b.layout || "default");
            for (const pid of Object.keys(b.plugins || {}))
                if (root._plugin(pid))
                    Plugins.setEnabled(pid, b.plugins[pid]);
            const w = b.wallpaper || {};
            Config.wallpaper.fallback = w.fallback || "";
            Config.wallpaper.outputs = w.outputs || ({});
            Config.wallpaper.workspaces = w.workspaces || ({});
            Config.wallpaper.shaders = w.shaders !== false;
            if (b.cursor && b.cursor[0] && !Shell.dev)
                Cursors.apply(b.cursor[0], b.cursor[1] || 24);
            root.before = null;
            root.current = "";
            root._save();
            ThemeExport.apply();
            root._done();
        });
        return true;
    }
    function _done() {
        busy = "";
        step = "";
        iconProbe.running = true;
    }

    IpcHandler {
        target: "presets"
        function list(): string {
            return root.presets.map(p => p.id + " — " + p.name).join("\n");
        }
        function apply(id: string, still: string): string {
            return root.apply(id, still !== "still") ? "ok" : "no such layout, or busy";
        }
        function restore(): string {
            return root.restore() ? "ok" : "nothing to restore, or busy";
        }
        function status(): string {
            return JSON.stringify({
                "current": root.current,
                "busy": root.busy,
                "step": root.step,
                "error": root.error,
                "canRestore": root.canRestore,
                "iconTheme": root.iconTheme
            });
        }
    }
}
