pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// UI state shared by modules + small helpers.
Singleton {
    id: root

    property var settingsView: null
    property var settingsWindow: null        // the Settings window while it has the TrollOS sidebar (not the Windows 11 skin)
    property var barViews: ({})
    property bool setupOpen: false
    signal setupStepRequested(int step)
    property bool settingsOpen: false
    property string settingsPage: "appearance"
    property bool launcherOpen: false
    property string launcherPrefill: ""
    property bool sessionOpen: false
    property bool bootOpen: false            // Y2K loading screen (modules/y2k/BootScreen)
    // the shell's own pid: its windows (settings, osu!mini…) share it, so
    // "End task" on them would kill angelOS itself
    property int pid: 0
    property Process pidProbe: Process {
        running: true
        command: ["sh", "-c", "echo $PPID"]
        stdout: StdioCollector {
            onStreamFinished: root.pid = parseInt(text) || 0
        }
    }
    property bool clipboardOpen: false
    property bool gameOpen: false            // osu!mini window (plugin osu-mini)
    property bool locked: false
    property bool lockPreview: false         // the lock screen in a normal overlay, nothing is checked
    property var lockPreviewTry: null        // (text) → plays the preview's reaction; never touches PAM
    property var polkitReregister: null
    property bool polkitRegistered: false
    readonly property bool dev: Quickshell.env("ANGELOS_DEV") === "1"
    // niri sends "angelOS [dev]" windows to the non-stream monitor (cfg/rules.kdl)
    readonly property string appTitle: dev ? "angelOS [dev]" : "angelOS"
    // demo/recording mode: popups open from IPC without an input grab
    readonly property bool demo: Quickshell.env("ANGELOS_DEMO") === "1"
    property var desktopMenus: ({})   // screen name -> DesktopMenu
    property string launcherText: ""
    // a plugin that opens from the lyrics line (dynamic-island): {toggle(item, screen), dragEnter(item, screen)}
    property var lyricsHook: null
    property var lyricsItems: ({})   // screen name -> BarLyrics, the island grows from it
    // screen name -> Item inside the wallpaper surface, above the picture and below
    // the desktop widgets: plugins parent their "live wallpaper" items here instead
    // of opening their own background surface (which would cover the widgets)
    property var wallpaperSlots: ({})
    // plays the workspace heart animation on the bars without switching (settings preview, `angelos heartDemo`)
    signal heartDemo(int from, int to)

    function lock() {
        closeStart();
        locked = true;
    }

    // ---- Start menu: a layer-shell overlay per screen (xdg popups opened without
    // a click are dismissed by the compositor, so Meta taps could not use them) ----
    property string startScreen: ""          // screen whose Start menu is open
    property var fluentWindow: null          // the Settings window while it is drawn like Windows 11 (WinSettingsView)
    property string startWarm: ""            // Windows copy: pointer on Start — map the menu's layer ahead of the click
    property var startButtons: ({})          // screen -> {item, window} of its Start button
    function registerStartButton(screen, item, window) {
        const m = Object.assign({}, startButtons);
        m[screen] = {
            "item": item,
            "window": window
        };
        startButtons = m;
    }
    function unregisterStartButton(screen, item) {
        if (!startButtons[screen] || startButtons[screen].item !== item)
            return;
        const m = Object.assign({}, startButtons);
        delete m[screen];
        startButtons = m;
    }
    function openStart(screen) {
        screen = screen || (focusedScreen ? focusedScreen.name : "");
        if (!screen || locked)
            return;
        launcherOpen = false;
        startScreen = screen;
    }
    function closeStart() {
        startScreen = "";
    }
    function toggleStart(screen) {
        screen = screen || (focusedScreen ? focusedScreen.name : "");
        if (startScreen === screen)
            closeStart();
        else
            openStart(screen);
    }

    // ANGELOS_SCREENS=HDMI-A-1,... limits the shell to some outputs (dev runs, streaming setups)
    readonly property var onlyScreens: (Quickshell.env("ANGELOS_SCREENS") || "").split(",").filter(s => s !== "")
    readonly property var screens: dev && onlyScreens.length ? Quickshell.screens.filter(s => onlyScreens.includes(s.name)) : Quickshell.screens
    readonly property var focusedScreen: screens.find(s => s.name === Niri.focusedOutput) || screens[0]
    // the widest screen: the main landscape monitor next to portrait side screens
    readonly property var primaryScreen: screens.reduce((best, s) => !best || s.width > best.width ? s : best, null)

    function screenByName(name) {
        return screens.find(s => s.name === name) || null;
    }

    function openSettings(page) {
        if (page)
            settingsPage = page;
        else if (!settingsOpen && !Config.settingsUi.expert)
            settingsPage = "home";      // the simple view starts from the tiles
        settingsOpen = true;
    }
    function toggleSettings(page) {
        if (settingsOpen && (!page || page === settingsPage))
            settingsOpen = false;
        else
            openSettings(page);
    }
    // Apps started from angelOS get the environment the shell itself started with:
    // the renderer variables bin/angelos set for the shell are put back, and the
    // cursor follows Settings → Cursor even before the next login.
    function _pre(name) {
        const v = Quickshell.env("ANGELOS_PRE_" + name);
        return v === null || v === undefined || v === "" ? null : v;
    }
    readonly property var childEnv: {
        const e = {};
        if (Quickshell.env("ANGELOS_PRE_QT_PLUGIN_PATH") != null)
            e.QT_PLUGIN_PATH = _pre("QT_PLUGIN_PATH");
        if (Quickshell.env("ANGELOS_PRE_QSG_RHI_BACKEND") != null)
            e.QSG_RHI_BACKEND = _pre("QSG_RHI_BACKEND");
        e.ANGELOS_PRE_QT_PLUGIN_PATH = null;
        e.ANGELOS_PRE_QSG_RHI_BACKEND = null;
        if (Cursors.theme) {
            e.XCURSOR_THEME = Cursors.theme;
            e.XCURSOR_SIZE = String(Cursors.size);
        }
        return e;
    }
    function exec(cmd, workingDirectory) {
        const ctx = {
            "command": cmd,
            "environment": childEnv
        };
        if (workingDirectory)
            ctx.workingDirectory = workingDirectory;
        Quickshell.execDetached(ctx);
    }
    function sh(script) {
        exec(["sh", "-c", script]);
    }
    // argv to run a command in the configured terminal (kitty/foot take the program directly);
    // appId names the terminal window so niri rules can match it (the task manager floats)
    function terminalArgv(argv, appId) {
        const t = Config.system.terminal || "kitty";
        const base = t.split("/").pop();
        let cls = [];
        if (appId)
            cls = base === "foot" ? ["--app-id=" + appId] : base === "ghostty" ? ["--class=" + appId] : base === "wezterm" ? ["--class", appId] : base === "kitty" || base === "alacritty" ? ["--class", appId] : [];
        if (!argv || argv.length === 0)
            return [t].concat(cls);
        if (base === "kitty" || base === "foot")
            return [t].concat(cls, argv);
        if (base === "wezterm")
            return [t, "start"].concat(cls, ["--"], argv);
        return [t].concat(cls, ["-e"], argv);
    }
    function terminal(cmd) {
        exec(terminalArgv(cmd ? ["sh", "-c", cmd] : []));
    }
    function openPath(path) {
        exec(["xdg-open", Config.expand(path)]);
    }
}
