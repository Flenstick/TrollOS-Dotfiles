pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// TrollOS: Material You's upkeep while the look is on (the palette "material" with the skin
// "material" — the «Material You» desktop layout, Settings → Material You). Nothing here runs
// for anyone else.
//   the icons   Papirus recoloured in the scheme (scripts/preset-assets.py md-icons) whenever
//               the seed, the variant, light/dark or the icon mode change — a moment later, once
//   the fonts   Roboto Flex and Material Symbols, downloaded once if fontconfig lacks them
//   the seed    from the wallpaper when asked (Config.material.fromWallpaper → Theme.wallpaperSeed)
//   `qs -c angelos ipc call materialyou status | seed <#hex> | variant <v> | rebuild`
Singleton {
    id: root

    readonly property bool on: Theme.materialOn && Theme.materialSkin
    readonly property string py: Quickshell.shellDir + "/scripts/preset-assets.py"
    property string step: ""                 // what it is doing (the page shows it)
    // the recoloured app icons there are (AppIcon takes them straight from the folder: the shell
    // reads its icon theme only when it starts); iconRev changes with every rebuild (no stale cache)
    readonly property string iconDir: Quickshell.env("HOME") + "/.local/share/icons/MaterialYou/64x64/apps/"
    property var iconSet: ({})
    property int iconRev: 0
    readonly property bool useIcons: on && Config.material.icons !== "off"
    function listIcons() {
        lister.running = false;
        lister.running = true;
    }
    Process {
        id: lister
        command: ["sh", "-c", 'ls "$1" 2>/dev/null', "sh", root.iconDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const f of text.split("\n"))
                    if (f.endsWith(".svg"))
                        o[f.slice(0, -4)] = true;
                root.iconSet = o;
                root.iconRev++;
            }
        }
    }
    onUseIconsChanged: if (useIcons)
        listIcons()
    property string error: ""

    // ---- the icons ----
    readonly property string iconKey: on && Config.material.icons !== "off" ? [Theme.materialSeed, Theme.materialVariant, Config.material.icons, Theme.dark ? "1" : "0"].join("|") : ""
    onIconKeyChanged: if (iconKey)
        iconTimer.restart()
    Timer {
        id: iconTimer
        interval: 900
        onTriggered: root.rebuildIcons()
    }
    function rebuildIcons() {
        if (!root.on || Config.material.icons === "off" || Shell.dev)
            return;
        if (icons.running) {
            iconTimer.restart();
            return;
        }
        step = I18n.t("Перекрашиваю значки…", "Recolouring the icons…");
        error = "";
        icons.command = ["sh", "-c", 'python3 "$1" md-icons "$2" "$3" "$4" "$5" && python3 "$1" icon-theme MaterialYou', "sh", py, Theme.materialSeed, Theme.materialVariant, Config.material.icons, Theme.dark ? "1" : "0"];
        icons.running = true;
    }
    Process {
        id: icons
        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                root.error = text.trim().split("\n").pop()
        }
        onExited: code => {
            root.step = "";
            if (code !== 0 && !root.error)
                root.error = "md-icons: exit " + code;
            if (code === 0)
                root.listIcons();
        }
    }

    // ---- the fonts, once ----
    property bool _fontsAsked: false
    onOnChanged: if (on && !_fontsAsked && !Shell.dev) {
        _fontsAsked = true;
        fonts.running = true;
    }
    Process {
        id: fonts
        command: ["python3", root.py, "fonts"]
    }

    // ---- the seed from the wallpaper ----
    readonly property string wallPath: {
        const s = Quickshell.screens[0];
        if (!s)
            return "";
        const ws = Niri.activeWorkspace(s.name);
        return Wallpapers.resolve(s.name, ws ? ws.idx : 1) || "";
    }
    readonly property bool wantWallSeed: Config.ready && Config.material.fromWallpaper && wallPath !== ""
    onWantWallSeedChanged: if (wantWallSeed)
        seedTimer.restart()
    onWallPathChanged: if (wantWallSeed)
        seedTimer.restart()
    Timer {
        id: seedTimer
        interval: 400
        onTriggered: {
            seedProc.command = ["python3", root.py, "seed-from", root.wallPath.replace(/^file:\/\//, "")];
            seedProc.running = true;
        }
    }
    Process {
        id: seedProc
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim();
                if (/^#[0-9a-f]{6}$/i.test(s))
                    Theme.wallpaperSeed = s;
            }
        }
    }

    IpcHandler {
        target: "materialyou"
        function status(): string {
            return JSON.stringify({
                "on": root.on,
                "seed": Theme.materialSeed,
                "variant": Theme.materialVariant,
                "icons": Config.material.icons,
                "step": root.step,
                "error": root.error
            });
        }
        function seed(hex: string): string {
            if (!/^#?[0-9a-fA-F]{6}$/.test(hex))
                return "a colour like #6750a4";
            Config.material.seed = hex.startsWith("#") ? hex : "#" + hex;
            Config.material.fromWallpaper = false;
            return "ok";
        }
        function variant(v: string): string {
            if (!["tonalSpot", "vibrant", "expressive", "neutral", "monochrome", "fidelity"].includes(v))
                return "tonalSpot | vibrant | expressive | neutral | monochrome | fidelity";
            Config.material.variant = v;
            return "ok";
        }
        function rebuild(): void {
            root.rebuildIcons();
        }
    }
}
