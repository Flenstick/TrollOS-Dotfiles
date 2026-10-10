import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// `qs -c angelos ipc call angelos <fn> [args]` — the `angelos` CLI wraps this.
IpcHandler {
    target: "angelos"

    function settings(page: string): void {
        Shell.toggleSettings(page);
    }
    function showLyrics(): void {
        Config.lyrics.enabled = true;
        Config.lyrics.screens = [];
        Lyrics.visibleToggle = true;
    }
    function setup(): void {
        Shell.setupOpen = true;
    }
    // open the wizard on a given step (0 = welcome)
    function setupStep(step: int): void {
        Shell.setupOpen = true;
        Shell.setupStepRequested(step);
    }
    // Start menu on a screen (default: focused); what a Meta tap does
    function startMenu(screen: string): void {
        Shell.toggleStart(screen);
    }
    // switch workspaces through angelOS: a number, up, down or prev
    function ws(target: string): void {
        WorkspaceAnim.go(target);
    }
    // dev only: fake niri workspaces on an output and switch between them the way
    // niri reports it (a new workspace list, then the activation), to test the
    // bar animations without touching real workspaces
    function fakeSwitch(output: string, count: int, idx: int): string {
        if (!Shell.dev)
            return "dev only";
        let list = Niri.workspaces.filter(w => w.output !== output);
        for (let i = 1; i <= count; i++)
            list.push({"id": 9000 + i, "idx": i, "name": null, "output": output, "is_active": i === idx, "is_focused": false, "is_urgent": false, "active_window_id": null});
        Niri._setWorkspaces(list);
        Niri.workspaceActivated(Niri.workspaces.find(w => w.id === 9000 + idx), false);
        return "ok";
    }
    // the heart animation on every bar, without switching workspaces (0-based cells)
    function heartDemo(from: int, to: int): void {
        Shell.heartDemo(from, to);
    }
    function heartAnim(style: string): string {
        const all = ["smart", "collide", "ender", "hop", "worm", "pixel", "beat", "sparkle", "drop", "glitch", "slide", "off"];
        if (!all.includes(style))
            return "styles: " + all.join(", ");
        Config.workspaces.heartAnim = style;
        return "ok";
    }
    // classic | win11 | fullscreen
    function startStyle(style: string): string {
        if (!["classic", "win11", "fullscreen"].includes(style))
            return "styles: classic, win11, fullscreen";
        Config.bar.startStyle = style;
        return "ok";
    }
    function launcher(): void {
        Shell.launcherOpen = !Shell.launcherOpen;
    }
    function launcherWith(text: string): void {
        Shell.launcherPrefill = text;
        Shell.launcherOpen = true;
    }
    function session(): void {
        Shell.sessionOpen = !Shell.sessionOpen;
    }
    function clipboard(): void {
        Shell.clipboardOpen = !Shell.clipboardOpen;
    }
    // Mod+G overlay: notes, pictures, GIFs, videos; pinned ones stay on screen
    function overlay(): void {
        Overlay.toggle();
    }
    // put a note or a file (picture/GIF/video) on the overlay: angelos overlayAdd ~/cat.gif
    function overlayAdd(what: string): string {
        if (what.startsWith("/") || what.startsWith("~/") || what.startsWith("file://"))
            return Overlay.addMedia(Config.expand(what)) ? "ok" : "unsupported file";
        Overlay.addNote(what);
        return "ok";
    }
    // toggle a desktop widget: angelos widget clock DP-1 (types: clock sysmon cava nowplaying plugin:<id>)
    function widget(type: string, screen: string): string {
        if (!DesktopWidgets.typeInfo(type))
            return "unknown widget: " + type + " (" + DesktopWidgets.types.map(t => t.type).join(", ") + ")";
        DesktopWidgets.toggle(type, screen || (Shell.focusedScreen ? Shell.focusedScreen.name : ""));
        return "ok";
    }
    function widgetEdit(): void {
        DesktopWidgets.editMode = !DesktopWidgets.editMode;
    }
    // replays a left click at (x, y) of a desktop widget, as its proxy would
    function widgetClick(uid: string, x: int, y: int): string {
        const h = DesktopWidgets.hosts[uid];
        if (!h)
            return "no widget";
        if (!h.takes(x, y, Qt.LeftButton))
            return "nothing clickable there";
        h.press(x, y, Qt.LeftButton);
        h.release(x, y, Qt.LeftButton);
        return "ok";
    }
    // what a pointer at (x, y) of a desktop widget would hit: {title, cursor, target}
    function widgetProbe(uid: string, x: int, y: int): string {
        const h = DesktopWidgets.hosts[uid];
        if (!h)
            return "no widget " + uid + "; have: " + Object.keys(DesktopWidgets.hosts).join(", ");
        const t = h.targetAt(x, y, "clicked");
        return JSON.stringify({
            "title": h.isTitleDrag(x, y),
            "cursor": h.cursorAt(x, y),
            "target": t ? String(t.item) : null,
            "size": [h.width, h.height]
        });
    }
    // the configured system monitor, floating (Settings → System → Task Manager)
    function taskManager(): void {
        DesktopActions.launchMonitor();
    }
    function settingsPage(page: string): void {
        Shell.openSettings(page);
    }
    // settings search: `angelos searchSettings "прозрачность панели"` → the best matches
    function searchSettings(text: string): string {
        SettingsSearch.load();
        return JSON.stringify({
            "complete": SettingsSearch.complete(text),
            "results": SettingsSearch.search(text, 8).map(r => ({
                        "title": r.title,
                        "where": r.crumb,
                        "page": r.page,
                        "score": Math.round(r.score * 100) / 100
                    }))
        });
    }
    function settingsQuery(text: string): void {
        Shell.openSettings();
        Qt.callLater(() => {
            if (Shell.settingsView)
                Shell.settingsView.setQuery(text);
        });
    }
    // open settings at the best match: `angelos openSetting blur`
    function openSetting(text: string): string {
        Shell.openSettings();
        const r = SettingsSearch.search(text, 1)[0];
        if (!r)
            return "not found";
        Qt.callLater(() => {
            if (Shell.settingsView)
                Shell.settingsView.openResult(r);
        });
        return r.title + (r.crumb ? " · " + r.crumb : "");
    }
    function launcherText(text: string): void {
        if (!Shell.launcherOpen)
            Shell.launcherOpen = true;
        Shell.launcherText = text;
    }
    // open the right-click desktop menu (x, y in screen pixels); sub: "" | view | new | open | more
    function desktopMenu(screen: string, x: int, y: int, sub: string): string {
        const m = Shell.desktopMenus[screen || (Shell.focusedScreen ? Shell.focusedScreen.name : "")];
        if (!m)
            return "no desktop on " + screen;
        if (x < 0) {
            m.close();
            return "closed";
        }
        if (!m.visible)
            m.openAt(x, y);
        if (sub)
            m.openSub(sub);
        return "ok";
    }
    function tourNext(): void {
        Tour.next();
    }
    function tourStop(): void {
        Tour.stop();
    }
    function tour(): void {
        Tour.start();
    }
    function lock(): void {
        Shell.lock();
    }
    // show the lock screen without locking (Esc or any password closes it)
    function lockPreview(): void {
        Shell.lockPreview = !Shell.lockPreview;
    }
    // preview only: "" shows the wrong-password reaction, any text the unlock
    function lockPreviewTry(text: string): void {
        if (Shell.lockPreviewTry)
            Shell.lockPreviewTry(text);
    }
    // experimental sidebar (Settings → Bar → Sidebar)
    function sidebar(): string {
        if (!Sidebar.enabled)
            return "sidebar is off (Settings → Bar → Sidebar)";
        Sidebar.toggle();
        return Sidebar.open ? "open" : "closed";
    }
    // screensaver: animated ASCII art until any input
    function idle(): void {
        Idle.toggle();
    }
    // look the current song up again, skipping the caches
    function lyricsRefetch(): void {
        Lyrics.refetch();
    }
    function lyrics(): void {
        Config.lyrics.enabled = !Config.lyrics.enabled;
    }
    function theme(mode: string): void {
        Config.appearance.mode = mode === "toggle" ? (Theme.dark ? "light" : "dark") : mode;
    }
    function flavor(name: string): void {
        Config.appearance.flavor = name;
    }
    function wallpaper(path: string): void {
        if (path === "random")
            Wallpapers.random("");
        else
            Wallpapers.setEverywhere(path);
    }
    // wallpaper for one monitor: angelos wallpaperOn DP-1 <path|random>
    function wallpaperOn(screen: string, path: string): string {
        if (!Shell.screenByName(screen))
            return "no screen " + screen;
        if (path === "random")
            Wallpapers.random(screen);
        else
            Wallpapers.setForOutput(screen, path);
        return "ok";
    }
    function bar(style: string): void {
        Config.bar.style = style;
    }
    // Windows 11 copy options: winSet settingsSkin true | gradient false | icons angelos | align left …
    function winSet(key: string, value: string): string {
        if (!(key in Config.win))
            return "keys: accent align search taskView lyrics recommended gradient icons settingsSkin snip offered";
        let v = value;
        try {
            v = JSON.parse(value);
        } catch (e) {}
        Config.win[key] = v;
        return "ok";
    }
    // whole-desktop layout (Settings → Раскладки): default | macos | win11 | compact | ubuntu | classic | chromeos | elementary | cinnamon
    function layout(id: string): string {
        if (!id)
            return DesktopLayouts.current;
        return DesktopLayouts.apply(id) ? "ok" : "layouts: " + DesktopLayouts.ids.join(", ");
    }
    function volumeUp(): void {
        Audio.step(0.05);
    }
    function volumeDown(): void {
        Audio.step(-0.05);
    }
    function mute(): void {
        Audio.toggleMute();
    }
    function micMute(): void {
        Audio.toggleMic();
    }
    function media(cmd: string): void {
        const p = Lyrics.player;
        if (!p)
            return;
        if (cmd === "next")
            p.next();
        else if (cmd === "previous" || cmd === "prev")
            p.previous();
        else if (cmd === "pause")
            p.pause();
        else if (cmd === "play")
            p.play();
        else
            p.togglePlaying();
    }
    // owner only: dotfiles pull | publish | check (no-op in the public version)
    function dotfiles(action: string): string {
        if (!Owner.enabled || !Owner.jobs)
            return "owner features are not available";
        Shell.openSettings("dotfiles");
        if (action === "pull")
            Owner.jobs.update();
        else if (action === "publish")
            Owner.jobs.publish(false);
        else if (action === "check")
            Owner.jobs.publish(true);
        return "ok";
    }
    // used by ~/.local/bin/polkit-agent-guard to hand the session slot back to angelOS
    function polkitRegister(): void {
        if (Shell.polkitReregister)
            Shell.polkitReregister();
    }
    function plugins(): void {
        Plugins.reload();
    }
    function reload(): void {
        Quickshell.reload(true);
    }
    // soft | dash | dissolve | heart | ender | instant
    function switchFx(style: string): string {
        if (!WorkspaceAnim.styles.some(x => x.id === style))
            return "styles: " + WorkspaceAnim.styles.map(x => x.id).join(", ");
        WorkspaceAnim.pick(style);
        return WorkspaceAnim.log || "ok";
    }
    // the current workspace transition over an output, without switching
    function testTransition(output: string): string {
        if (!WorkspaceAnim.captured)
            return "the current style (" + WorkspaceAnim.current.id + ") is niri's own animation";
        WorkspaceAnim.preview(output);
        return "ok";
    }
    // replay the workspace switch animation on an output (handy after tweaking settings)
    function testFx(output: string): void {
        const ws = Niri.activeWorkspace(output || Niri.focusedOutput);
        if (ws)
            Niri.workspaceActivated(ws, false);
    }
    function testNotify(): void {
        if (!Shell.dev) {
            Quickshell.execDetached(["notify-send", "-a", "angelOS", I18n.t("Привет ♡", "Hello ♡"), I18n.t("тестовое уведомление", "test notification")]);
            return;
        }
        Notifs.popups = Notifs.popups.concat([
            {
                "id": 900000 + Math.floor(Math.random() * 99999),
                "appName": "angelOS",
                "summary": I18n.t("Привет, это тест ♡", "Hello, this is a test ♡"),
                "body": I18n.t("Уведомление в стиле <b>NGO</b>: пиксели, розовый и сердечки. <i>Клик</i> — закрыть.", "An <b>NGO</b> notification: pixels, pink and hearts. <i>Click</i> to dismiss."),
                "actions": [
                    {
                        "text": I18n.t("Ответить", "Reply"),
                        "identifier": "reply",
                        "invoke": () => {}
                    }
                ],
                "urgency": 1,
                "expireTimeout": -1,
                "image": "",
                "appIcon": "kitty",
                "desktopEntry": "",
                "tracked": false
            }
        ]);
    }
    function testOsd(): void {
        Audio.changed("volume");
    }
    function panel(name: string, output: string): bool {
        return PopupManager.showPanel(name, output);
    }
    function taskLabels(show: bool): void {
        Config.bar.taskLabels = show;
    }
    function claudeBar(mode: string): void {
        if (["off", "five", "week", "both"].includes(mode)) {
            const p = Plugins.byId("claude-companion");
            if (p)
                Plugins.context(p).set("barLimit", mode);
        }
    }
    function lyricArtwork(mode: string): void {
        if (["note", "cover"].includes(mode))
            Config.lyrics.artwork = mode;
    }
    // font presets: angelos | arcade | soft | block (missing fonts are downloaded)
    function fontPreset(id: string): string {
        const p = Fonts.presets.find(x => x.id === id);
        if (!p)
            return "presets: " + Fonts.presets.map(x => x.id).join(", ");
        Fonts.applyPreset(p);
        return "ok";
    }
    function blur(enabled: bool): void {
        Config.appearance.blur = enabled;
    }
    function diagnostics(): string {
        const bars = {};
        for (const k of Object.keys(Shell.barViews))
            bars[k] = Shell.barViews[k].diagnostics();
        return JSON.stringify({
            settings: Shell.settingsView ? Shell.settingsView.diagnostics() : null,
            bars: bars,
            lyrics: {
                status: Lyrics.status,
                source: Lyrics.source,
                track: Lyrics.artist + " — " + Lyrics.title,
                hasLyrics: Lyrics.hasLyrics,
                enabled: Config.lyrics.enabled,
                visible: Lyrics.visibleToggle,
                screens: Config.lyrics.screens,
                index: Lyrics.index,
                line: Lyrics.current,
                count: Lyrics.lines.length
            },
            popup: PopupManager.active ? PopupManager.active.title : "",
            panels: PopupManager.registered.map(p => ({
                        id: p.panelId,
                        output: p.outputName,
                        visible: p.visible,
                        width: p.width,
                        height: p.height
                    })),
            language: Config.appearance.language
        });
    }
    function status(): string {
        return JSON.stringify({
            "theme": Theme.dark ? "dark" : "light",
            "flavor": Config.appearance.flavor,
            "bar": Config.bar.style,
            "lyrics": Lyrics.status,
            "track": Lyrics.title,
            "plugins": Plugins.enabledPlugins.map(p => p.id),
            "screens": Shell.screens.map(s => s.name),
            "polkit": Shell.polkitRegistered,
            "notifications": true
        });
    }
}
