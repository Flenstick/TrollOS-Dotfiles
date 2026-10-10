pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// User settings, persisted to ~/.config/angelos/settings.json.
// Every property change is written back after a short debounce.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/angelos"
    readonly property string pluginsDir: dir + "/plugins"
    readonly property string templatesDir: dir + "/templates"
    readonly property string stateDir: home + "/.local/state/angelos"
    readonly property string cacheDir: home + "/.cache/angelos"

    property bool newConfig: false
    readonly property bool ready: file.loaded || newConfig
    property alias appearance: adapter.appearance
    property alias bar: adapter.bar
    property alias dock: adapter.dock
    property alias win: adapter.win
    property alias wallpaper: adapter.wallpaper
    property alias workspaces: adapter.workspaces
    property alias lyrics: adapter.lyrics
    property alias setup: adapter.setup
    property alias notifications: adapter.notifications
    property alias osd: adapter.osd
    property alias launcher: adapter.launcher
    property alias voxtype: adapter.voxtype
    property alias desktop: adapter.desktop
    property alias lock: adapter.lock
    property alias idle: adapter.idle
    property alias sidebar: adapter.sidebar
    property alias capture: adapter.capture
    property alias plugins: adapter.plugins
    property alias dotfiles: adapter.dotfiles
    property alias system: adapter.system
    property alias developer: adapter.developer
    property alias settingsUi: adapter.settingsUi
    property alias profile: adapter.profile
    property alias screenTime: adapter.screenTime
    property alias y2k: adapter.y2k
    property alias cursor: adapter.cursor
    property alias updates: adapter.updates
    property alias network: adapter.network

    function expand(path) {
        if (!path)
            return "";
        return path.startsWith("~/") ? home + path.slice(1) : path;
    }

    // JSON maps have to be reassigned to notify the adapter.
    function setIn(obj, prop, key, value) {
        const copy = Object.assign({}, obj[prop] || {});
        if (value === undefined || value === null || value === "")
            delete copy[key];
        else
            copy[key] = value;
        obj[prop] = copy;
    }

    Timer {
        id: saveTimer
        interval: 350
        onTriggered: file.writeAdapter()
    }

    Process {
        id: mkdirs
        running: true
        command: ["sh", "-c", 'mkdir -p "$@" && chmod 700 "$4"', "sh", root.dir, root.pluginsDir, root.templatesDir, root.stateDir, root.cacheDir + "/lyrics"]
    }

    FileView {
        id: file
        path: root.dir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: saveTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.newConfig = true;
                saveTimer.restart();
            }
        }

        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property string customAccent: "#c77dff"
                property string language: "ru"
                property string mode: "dark"        // light | dark | auto
                property int lightFrom: 8           // auto: light theme from this hour
                property int darkFrom: 20           // auto: dark theme from this hour
                property string flavor: "overdose" // bubblegum | overdose | cyberangel
                property real opacity: 0.84         // panel background opacity (blur shows through)
                property bool blur: true
                property int px: 2                  // size of one "art pixel" in screen pixels
                property int fontScale: 1           // 1 or 2 keeps pixel fonts crisp
                property bool shadows: true         // hard pixel drop shadows
                property bool themeApps: true       // render templates for kitty/foot/gtk/niri
                property var disabledTemplates: []
                property string fontTitle: ""       // "" = Pixeloid Sans
                property string fontBody: ""        // "" = CozetteVector
                property string fontMono: ""        // "" = Pixeloid Mono
                property bool autoWallpaperColors: true // flavor "wallpaper": follow wallpaper changes
                property string paletteScreen: ""  // screen whose wallpaper feeds the palette; "" = first
            }

            property JsonObject bar: JsonObject {
                property string style: "taskbar"    // taskbar | top | island | windows
                property var screens: []            // empty = every screen
                property bool compactOnVertical: true
                property bool showWindows: true
                property bool taskLabels: false
                property int taskMinWidth: 40       // task buttons with titles, in art pixels
                property int taskMaxWidth: 90
                property string workspaceStyle: "hearts" // hearts | icons | both
                property int workspaceIcons: 3      // max app icons per workspace
                property bool allWindows: false     // taskbar: every window, not only current workspace
                property bool showMedia: true
                property bool showSeconds: false
                property string startLabel: "TrollOS"
                property string startStyle: "classic" // classic (Win98 list) | win11 (centred, pinned grid) | fullscreen (iPhone-like app grid)
                property var startPinned: []        // desktop entry ids pinned in Start
                property string startAlign: "auto" // auto (classic at the button, win11 centred) | left | center | right
                property int startWidth: 100        // Start menu width, % of the default
                property int startRows: 3           // win11: rows of pinned apps
                property string logoStyle: "classic" // classic | angel
                property bool metaTap: true         // a short Meta tap opens Start (Windows-like)
                property int metaTapMs: 400         // longer presses are holds, not taps
                property bool metaTapFullscreen: false // also over fullscreen windows / games
                property var layout: ({})           // {left:[], center:[], right:[]}; empty = defaults
                property var hidden: []             // widget ids removed from the bar
                property string trayTint: "accent"  // off | mono | accent — recolor tray icons to the theme
                property bool tintTasks: false      // same for window buttons
                property string taskRightClick: "menu" // menu (window menu with Close) | close (closes at once) | none
                property bool taskMiddleClose: true // middle click on a window button closes the window
                property bool taskHoverClose: false // × on the hovered window button
                property bool floating: false       // taskbar: a floating panel with gaps around it
                property string layoutPreset: "default" // Settings → Раскладки: default | macos | win11 | compact | ubuntu | classic | chromeos | elementary | cinnamon
                property var layoutSaved: ({})      // the user's own layout, kept while a preset is on
            }

            // bar.style "windows" + bar.startStyle "windows": a Windows 11 look-alike (modules/bar/win)
            property JsonObject win: JsonObject {
                property string accent: "windows"   // windows (Windows blue) | theme (angelOS accent)
                property string align: "center"     // center | left — taskbar icons and Start
                property var pinned: []             // taskbar apps (desktop ids); empty = most used
                property var order: []              // taskbar order (app keys), set by dragging icons
                property var startPinned: []        // Start "Закреплено" (desktop ids); empty = most used
                property bool search: true          // search button on the taskbar
                property bool taskView: true        // task view button (niri overview)
                property bool lyrics: false         // song line at the left, where Windows keeps Widgets
                property bool recommended: true     // Start: recently opened files and new apps
                property bool gradient: false       // Windows 11 "Bloom" gradient wallpaper (dark/light follows the theme)
                property string icons: "angelos"    // windows (Win11 icon theme) | angelos (your icons)
                property bool settingsSkin: false   // angelOS Settings drawn like Windows 11 "Параметры"
                property bool snip: false           // screenshots like the Snipping Tool (angelos-snip)
                property bool altTab: true          // Windows-style Alt+Tab instead of niri's (cfg/win-alttab.kdl)
                property bool edgeResize: true      // drag the focused window's edges / corners to resize it
                property bool offered: false        // the "make it like Windows?" question was answered
                property var savedWallpaper: ({})   // what to put back when the layout is left
                property string savedIconTheme: ""
            }

            property JsonObject dock: JsonObject {
                property bool enabled: false
                property string position: "bottom"  // bottom (floating, centred) | left (full height strip)
                property var pinned: []             // desktop entry ids; empty = most used apps
                property int size: 22               // icon size, art pixels
                property bool magnify: true         // icons grow under the pointer (bottom dock)
                property bool appsButton: true      // grid button that opens Start
                property bool running: true         // also show running apps that are not pinned
            }

            property JsonObject wallpaper: JsonObject {
                property string dir: "~/Pictures"
                property string fallback: "~/Pictures/wallpapers/TrollOS/trollos-dark.png"
                property var outputs: ({})          // "DP-1" -> path
                property var workspaces: ({})       // "DP-1:2" -> path
                property string transition: "mosaic-dither" // mosaic-dither | mosaic | dither | none (only when the picture changes)
                property int duration: 750
                property int maxBlock: 48
            }

            property JsonObject workspaces: JsonObject {
                property string popupMode: "bar"    // bar (flash next to the hearts) | window | off
                property string popupPosition: "bottom-center"
                property bool indicator: false      // heart strip on the right edge
            property int popupMs: 650
            property bool phrases: true
            property string switchFx: "soft"    // soft | slide | bounce | teleport | pixel | heart | glitch | instant
                property string heartAnim: "smart"  // hearts/icons indicator: smart | collide | ender | hop | worm | pixel | beat | sparkle | drop | glitch | slide | off
                property var names: ({})            // "DP-1:1" -> "работа"
            }

            property JsonObject lyrics: JsonObject {
                property bool enabled: true         // current line in the middle of the bar
                property var screens: []            // empty = every bar
                property int offsetMs: 0
                property string artwork: "note"          // note | cover
                property bool typewriter: true
                property string preferPlayer: "spotify"
                property var sources: ["local", "player", "lrclib", "netease", "kugou", "qq", "ovh"] // tried in this order
                property int sourcesVersion: 0      // 2 = the list knows kugou/qq/local/player (older lists get them once)
            }

            property JsonObject setup: JsonObject {
                property bool complete: false
            }

            property JsonObject notifications: JsonObject {
                property bool dnd: false
                property int timeout: 6000
                property string screen: ""          // empty = focused output
                property string position: "top-right"
                property int maxPopups: 4
            }

            property JsonObject osd: JsonObject {
                property bool enabled: true
                property bool layout: true          // show keyboard layout switches
                property string position: "bottom-center"
                property int ms: 900
            }

            property JsonObject desktop: JsonObject {
                property var widgets: []            // [{uid, type, screen, x, y, settings}]; x/y < 0 = from the right/bottom
                property bool initialized: false
                property bool snap: true
                property string titleSuffix: "exe"  // widget titles end in .exe | .sh | .bin
            }

            property JsonObject voxtype: JsonObject {
                property string indicator: "angelos" // angelos | classic (old GTK circle) | off
                property string position: "bottom-center"
            }

            property JsonObject launcher: JsonObject {
                property string terminal: "kitty"
                property var usage: ({})            // desktop id -> launches
            }

            property JsonObject lock: JsonObject {
                property int idleMinutes: 0         // 0 = never lock automatically
                property bool onSleep: true         // lock before suspend/hibernate (logind), so waking up shows the lock
                property bool pixelate: true
                property bool hearts: true          // floating pixel hearts
                property bool reactions: true       // hearts on typing, a broken heart on a mistake, a burst on unlock
                property bool indicators: true      // Caps Lock, layout, battery, time locked, missed notifications
                property bool stream: false         // NGO stream overlay: LIVE badge, viewers, cute chat
                property string streamTitle: ""      // "" = "angel is on a break" 
            }

            property JsonObject idle: JsonObject {
                property int minutes: 0             // start the idle screen after N idle minutes; 0 = by hand only
                property string text: ""            // "" = angelOS ASCII art
                property string effect: "random"    // random | decrypt | rain | beams | wave | typewriter | hearts | glitch
                property string colors: "accent"    // accent | mono | rainbow
                property bool clock: true
                property bool allScreens: true
            }

            property JsonObject sidebar: JsonObject {
                property bool enabled: false        // experimental
                property string screen: ""          // "" = first screen
                property string edge: "right"       // left | right | top | bottom — where the tab sits
                property real offset: 0.5           // tab position along that edge, 0..1
                property var sections: ["toggles", "media", "sound", "system", "ai"]
            }

            property JsonObject capture: JsonObject {
                property string skin: "ropes"       // ropes | window | stream — region selector and recording overlay
                property bool themeColors: false    // NGO skins in the angelOS theme instead of the NGO palette
            }

            property JsonObject plugins: JsonObject {
                property var enabled: ({})          // id -> bool (missing = manifest default)
                property var data: ({})             // id -> plugin settings object
            }

            property JsonObject dotfiles: JsonObject {
                property string repo: "~/PixelStreetArt_Dotfiles_Niri"
                property string command: "./install.sh"
                property string env: "DOTFILES_MODE=full SKIP_PACKAGES=1 INSTALL_VOXTYPE=0 DOWNLOAD_VOXTYPE_MODEL=0 ENABLE_SERVICES=0"
                property bool reloadNiri: true
            }

            property JsonObject system: JsonObject {
                property string terminal: "kitty"
                property string fileManager: "nautilus"
                property string monitor: "auto"
                property string monitorProgram: ""
                property bool monitorInTerminal: false
                property bool monitorFloat: true    // the task manager opens as a floating window (niri rule)
                property string monitorSize: "medium" // compact | medium | large | tall | custom
                property int monitorWidth: 1200     // custom size, logical px
                property int monitorHeight: 760
                property string monitorPlace: "center" // center | corner (bottom-right, next to the tray)
                property bool nautilusDefaults: false // angelOS Nautilus extensions + prefs applied once
            }

            property JsonObject cursor: JsonObject {
                property string theme: ""           // "" = leave the system cursor alone
                property int size: 24
                property bool flatpak: true         // also hand the theme to Flatpak apps
            }

            property JsonObject updates: JsonObject {
                property string repo: ""            // "" = found automatically (installer marker, ~/PixelStreetArt_Dotfiles_Niri)
                property bool autoCheck: true       // look for updates once a day, never installs by itself
                property string lastCheck: ""
                property int available: 0
            }

            property JsonObject network: JsonObject {
                property bool showWifi: true        // bar/sidebar Wi-Fi indicator when a Wi-Fi adapter exists
                property bool showBluetooth: true
            }

            property JsonObject y2k: JsonObject {
                property bool helper: true          // the pixel angel in a screen corner
                property string helperScreen: ""   // "" = the main screen
                property string helperTips: "rare" // off | rare | often
                property bool helperGreeted: false
                property bool sparkles: true        // sparkle trail over the bare desktop
                property var sparkleScreens: []     // empty = every screen
                property bool sounds: true
                property real soundVolume: 0.55
                property var soundOff: ["click"]    // events kept quiet: startup notify error click shutdown angel
                property bool boot: true            // CD-ROM style loading screen once per login
                property var bootScreens: []        // empty = every screen
            }

            property JsonObject settingsUi: JsonObject {
                property bool expert: false         // false: advanced groups folded; true: every setting shown
            }

            // TrollOS: screen time per day and per app (services/ScreenTime, Settings → Экранное время)
            property JsonObject screenTime: JsonObject {
                property bool track: true           // count the time at the computer
                property bool apps: true            // and which app was in focus
            }

            // TrollOS: the user's card at the top of Settings (and the Start menu avatar)
            property JsonObject profile: JsonObject {
                property string avatar: ""          // picture copied to ~/.config/angelos/avatar.*; "" = the splat
                property string name: ""            // "" = the account's full name, else the login
            }

            property JsonObject developer: JsonObject {
                property bool enabled: false
                property string provider: "claude-cli" // claude-cli | codex-cli (browser login) | openai | anthropic (API key)
                property string openaiModel: "gpt-5.4"
                property string anthropicModel: "claude-opus-5-5"
                property string claudeCliModel: "sonnet" // "" = the CLI default; aliases: haiku / sonnet / opus / fable
                property string codexCliModel: ""
                property var efforts: ({})          // provider -> low | medium | high | xhigh | max | ultra ("" = model default)
                property int autoRepair: 1          // automatic repair rounds after failed checks (0–2)
                property int maxOutputTokens: 32000
            }
        }
    }
}
