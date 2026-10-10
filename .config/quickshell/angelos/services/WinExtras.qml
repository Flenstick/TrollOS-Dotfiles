pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Windows 11 layout extras that reach outside the shell: the Bloom wallpaper and
// the system (GTK) icon theme. They are on only while bar.style is "windows";
// what was there before is kept in Config.win.saved* and put back the moment the
// layout is left (also after a restart in between).
Singleton {
    id: root

    readonly property bool active: Config.bar.style === "windows"
    // TrollOS: Settings have their own views and skins since the angelOS 3 merge; the Fluent skin is gone
    readonly property bool fluentSettings: false
    readonly property bool wantBloom: active && Config.win.gradient
    readonly property bool wantIcons: active && Config.win.icons === "windows"
    readonly property string bloomPath: Quickshell.env("HOME") + "/Pictures/wallpapers/win11-bloom-" + (Theme.dark ? "dark" : "light") + ".png"
    readonly property string iconTheme: Theme.dark ? "Win11-dark" : "Win11"

    // names of the app icons the Win11 theme has (AppIcon only asks for these)
    property var winIconSet: ({})
    Process {
        running: true
        command: ["sh", "-c", 'ls "$HOME/.local/share/icons/Win11/apps/scalable" 2>/dev/null | sed -n "s/\\.svg$//p"']
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                for (const n of text.split("\n"))
                    if (n)
                        m[n] = true;
                root.winIconSet = m;
            }
        }
    }

    property bool ready: false
    Timer {
        // let settings.json load before touching anything
        interval: 1500
        running: true
        onTriggered: {
            root.ready = true;
            root.sync();
            root.writeAltTab();
        }
    }
    // ---- Alt+Tab: niri hands Alt+Tab to the shell while the layout is on ----
    readonly property bool wantAltTab: active && Config.win.altTab
    readonly property string altTabFile: Quickshell.env("HOME") + "/.config/niri/cfg/win-alttab.kdl"
    readonly property string altTabKdl: wantAltTab ? '// angelOS (WinExtras): Windows 11 Alt+Tab of the shell, written while the Windows layout is on.\nbinds {\n    Alt+Tab repeat=false { spawn "qs" "-c" "angelos" "ipc" "call" "alttab" "next"; }\n    Alt+Shift+Tab repeat=false { spawn "qs" "-c" "angelos" "ipc" "call" "alttab" "prev"; }\n}\n' : '// angelOS (WinExtras): empty — niri\'s own Alt+Tab is used outside the Windows layout.\n'
    onAltTabKdlChanged: writeAltTab()
    function writeAltTab() {
        if (!ready)
            return;
        Quickshell.execDetached(["sh", "-c", '[ "$(cat "$1" 2>/dev/null)" = "$2" ] || printf "%s" "$2" > "$1"', "sh", altTabFile, altTabKdl]);
    }
    onWantBloomChanged: sync()
    onWantIconsChanged: sync()
    onBloomPathChanged: sync()
    onIconThemeChanged: sync()

    // Order matters: a wallpaper change re-renders the palette, and angelOS's pixora-folders
    // template then flips the icon theme to pixora-dark and back for ~0.3 s. So the user's
    // icon theme is saved before the wallpaper changes, and restored before it comes back.
    function sync() {
        if (!ready)
            return;
        // ---- GTK icon theme first ----
        if (wantIcons) {
            if (!Config.win.savedIconTheme) {
                if (!readTheme.running)
                    readTheme.running = true;     // saves, applies, then calls sync() again
                return;
            }
            setTheme(iconTheme, iconTheme, iconTheme);
        } else if (Config.win.savedIconTheme) {
            let o = {};
            try {
                o = JSON.parse(Config.win.savedIconTheme);
            } catch (e) {
                o = {
                    "gs": Config.win.savedIconTheme
                };
            }
            setTheme(o.gs || "", o.ini3 || "", o.ini4 || "");
            Config.win.savedIconTheme = "";
            wallLater.restart();                // the wallpaper after the theme has settled
            return;
        }
        syncWallpaper();
    }
    Timer {
        id: wallLater
        interval: 700
        onTriggered: root.syncWallpaper()
    }
    function syncWallpaper() {
        const saved = Config.win.savedWallpaper || {};
        const have = saved.fallback !== undefined;
        if (wantBloom) {
            if (!have)
                Config.win.savedWallpaper = {
                    "fallback": Config.wallpaper.fallback,
                    "outputs": JSON.parse(JSON.stringify(Config.wallpaper.outputs || {})),
                    "workspaces": JSON.parse(JSON.stringify(Config.wallpaper.workspaces || {}))
                };
            if (Config.wallpaper.fallback !== bloomPath || Object.keys(Config.wallpaper.outputs || {}).length) {
                Config.wallpaper.outputs = ({});
                Config.wallpaper.workspaces = ({});
                Config.wallpaper.fallback = bloomPath;
            }
        } else if (have) {
            Config.wallpaper.outputs = saved.outputs || ({});
            Config.wallpaper.workspaces = saved.workspaces || ({});
            Config.wallpaper.fallback = saved.fallback || "";
            Config.win.savedWallpaper = ({});
        }
    }

    readonly property string ini3: Quickshell.env("HOME") + "/.config/gtk-3.0/settings.ini"
    readonly property string ini4: Quickshell.env("HOME") + "/.config/gtk-4.0/settings.ini"
    Process {
        id: readTheme
        command: ["sh", "-c", 'gsettings get org.gnome.desktop.interface icon-theme | tr -d "\x27"; for f in "$1" "$2"; do printf "%s\\n" "$(sed -n "s/^gtk-icon-theme-name=//p" "$f" 2>/dev/null | head -1)"; done', "sh", root.ini3, root.ini4]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n").map(x => x.trim());
                const gs = l[0] || "", i3 = l[1] || "", i4 = l[2] || "";
                if (!Config.win.savedIconTheme && gs && !gs.startsWith("Win11"))
                    Config.win.savedIconTheme = JSON.stringify({
                        "gs": gs,
                        "ini3": i3,
                        "ini4": i4
                    });
                if (root.wantIcons && Config.win.savedIconTheme)
                    root.sync();
            }
        }
    }
    // gsettings for GTK4 / portals, settings.ini for GTK3/4 apps started later ("" = leave)
    function setTheme(gs, i3, i4) {
        Quickshell.execDetached(["sh", "-c", '[ -n "$1" ] && gsettings set org.gnome.desktop.interface icon-theme "$1"; [ -n "$2" ] && [ -f "$4" ] && sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$2/" "$4"; [ -n "$3" ] && [ -f "$5" ] && sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$3/" "$5"; true', "sh", gs, i3, i4, root.ini3, root.ini4]);
    }
}
