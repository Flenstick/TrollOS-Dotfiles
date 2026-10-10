pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// A short tap of Meta opens the Start menu, like on Windows (scripts/meta-tap.py).
// Holding Meta or using it in a shortcut does nothing.
Singleton {
    id: root
    // Alt state from the same evdev listener (Windows-style Alt+Tab closes on release)
    property bool altDown: false
    signal altReleased

    property string status: "off"      // off | starting | ready | noperm | noevdev | error
    // a dev instance next to the live one would open a second menu on every tap
    readonly property bool wanted: Config.ready && Config.bar.metaTap && (!Shell.dev || Quickshell.env("ANGELOS_DEV_TAP") === "1")

    function coversOutput(w) {
        const s = Shell.screenByName(Niri.focusedOutput);
        const size = w && w.layout ? w.layout.window_size : null;
        return !!s && !!size && size[0] >= s.width && size[1] >= s.height;
    }
    function tap() {
        if (Shell.locked || Shell.sessionOpen || Shell.clipboardOpen || Idle.active)
            return;
        if (Shell.launcherOpen) {
            Shell.launcherOpen = false;
            return;
        }
        if (Shell.startScreen === "" && !Config.bar.metaTapFullscreen && coversOutput(Niri.focusedWindow))
            return;   // games and fullscreen video keep the keyboard
        Shell.toggleStart("");
    }

    Process {
        id: daemon
        running: root.wanted
        command: ["python3", "-u", Quickshell.shellDir + "/scripts/meta-tap.py", "--max-ms", String(Config.bar.metaTapMs)]
        onRunningChanged: {
            if (running)
                root.status = "starting";
            else if (root.status === "starting" || root.status === "ready")
                root.status = root.wanted ? "error" : "off";
        }
        stdout: SplitParser {
            onRead: line => {
                if (line === "tap")
                    root.tap();
                else if (line === "alt1")
                    root.altDown = true;
                else if (line === "alt0") {
                    root.altDown = false;
                    root.altReleased();
                }
                else if (["ready", "noperm", "noevdev"].includes(line))
                    root.status = line;
            }
        }
        stderr: StdioCollector {}
        onExited: if (root.wanted && root.status !== "noperm" && root.status !== "noevdev")
            restart.start()
    }
    Timer {
        id: restart
        interval: 5000
        onTriggered: if (root.wanted)
            daemon.running = true
    }
    // new threshold: restart the daemon with it
    Connections {
        target: Config.bar
        function onMetaTapMsChanged() {
            if (daemon.running) {
                daemon.running = false;
                restart.interval = 300;
                restart.start();
            }
        }
    }
}
