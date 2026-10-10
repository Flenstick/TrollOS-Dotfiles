import QtQuick
import Quickshell.Io

// Экран телефона на компьютере: scrcpy по Wi-Fi (беспроводная отладка).
// mirror.sh находит телефон, при первом разе спаривает по коду.
Item {
    id: root

    property string name: "Телефон"
    // idle | connecting | need-wifi | need-pair | pairing | running | error
    property string state: "idle"
    property string message: ""
    property string serial: ""
    readonly property bool running: scrcpy.running
    readonly property bool busy: state === "connecting" || state === "pairing"
    readonly property string script: decodeURIComponent(String(Qt.resolvedUrl("mirror.sh")).replace("file://", ""))
    signal launched

    // ---- размер окна (niri): кнопки в острове, пропорции телефона сохраняются ----
    readonly property int startHeight: 720
    readonly property var heights: [420, 560, 720, 880, 1000]
    property int winId: -1
    property real ratio: 0            // ширина / высота видео
    property int winHeight: startHeight
    property bool full: false

    function findWindow() {
        if (!finder.running)
            finder.running = true;
    }
    function resizeTo(h) {
        if (winId < 0 || ratio <= 0)
            return;
        winHeight = h;
        if (full)
            toggleFull();
        niriProc.command = ["sh", "-c", 'niri msg action set-window-height --id "$1" "$2" && niri msg action set-window-width --id "$1" "$3"', "sh", String(winId), String(h), String(Math.round(h * ratio))];
        niriProc.running = true;
    }
    function grow() {
        const next = heights.find(h => h > winHeight + 8);
        resizeTo(next !== undefined ? next : heights[heights.length - 1]);
    }
    function shrink() {
        const smaller = heights.filter(h => h < winHeight - 8);
        resizeTo(smaller.length ? smaller[smaller.length - 1] : heights[0]);
    }
    function toggleFull() {
        if (winId < 0)
            return;
        full = !full;
        fullProc.command = ["niri", "msg", "action", "fullscreen-window", "--id", String(winId)];
        fullProc.running = true;
    }
    Process {
        id: niriProc
    }
    Process {
        id: fullProc
    }
    // окно scrcpy появляется не сразу — ищем несколько раз
    property int tries: 0
    Timer {
        id: findTimer
        interval: 400
        repeat: true
        onTriggered: {
            if (root.winId >= 0 || ++root.tries > 25 || !scrcpy.running)
                stop();
            else
                root.findWindow();
        }
    }
    // телефон повернули — scrcpy сам меняет окно, обновим пропорции
    Timer {
        interval: 2000
        repeat: true
        running: scrcpy.running && root.winId >= 0 && !root.full
        onTriggered: root.findWindow()
    }
    Process {
        id: finder
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = [];
                try {
                    list = JSON.parse(this.text);
                } catch (e) {
                    return;
                }
                const w = list.filter(x => x.app_id === "angelos-phone" || x.app_id === "scrcpy").sort((a, b) => b.id - a.id)[0];
                if (!w)
                    return;
                root.winId = w.id;
                const sz = w.layout && w.layout.window_size;
                if (sz && sz[1] > 0) {
                    root.ratio = sz[0] / sz[1];
                    root.winHeight = sz[1];
                }
            }
        }
    }

    function start() {
        if (scrcpy.running || conn.running)
            return;
        state = "connecting";
        message = "Ищу телефон в сети…";
        conn.command = ["sh", script, "connect"];
        conn.running = true;
    }
    function pair(code) {
        code = String(code).replace(/\D/g, "");
        if (code.length !== 6 || conn.running)
            return;
        state = "pairing";
        message = "Спариваю с телефоном…";
        conn.command = ["sh", script, "pair", code];
        conn.running = true;
    }
    // проверка окна без телефона (ipc island mirrorFake): вместо scrcpy — пустой kitty
    function startFake() {
        if (scrcpy.running)
            return;
        scrcpy.fake = true;
        scrcpy.running = true;
    }
    // звук телефона идёт в компьютер (на телефоне в это время тихо); переключение перезапускает трансляцию
    property bool audio: true
    property bool restarting: false
    function setAudio(on) {
        if (audio === on)
            return;
        audio = on;
        if (scrcpy.running) {
            restarting = true;
            stop();
        }
    }
    function stop() {
        scrcpy.stopping = true;
        scrcpy.running = false;
    }
    function toggle() {
        if (scrcpy.running)
            stop();
        else if (state === "idle" || state === "error")
            start();
        else
            dismiss();
    }
    function dismiss() {
        if (!conn.running && !scrcpy.running)
            state = "idle";
    }

    Process {
        id: conn
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                const last = lines[lines.length - 1] || "";
                console.log("[island] mirror:", last);
                if (last.startsWith("ok ")) {
                    root.serial = last.slice(3).trim();
                    root.message = "Запускаю трансляцию…";
                    scrcpy.running = true;
                } else if (last === "need-wifi") {
                    root.state = "need-wifi";
                    root.message = "";
                } else if (last === "need-pair") {
                    root.state = "need-pair";
                    root.message = "";
                } else if (last === "no-pair-service") {
                    root.state = "need-pair";
                    root.message = "Не вижу окно с кодом — открой на телефоне «Подключение с помощью кода»";
                } else if (last.startsWith("pair-failed")) {
                    root.state = "need-pair";
                    root.message = "Код не подошёл — попробуй новый";
                } else {
                    root.state = "error";
                    root.message = "Не получилось подключиться к телефону";
                }
            }
        }
        stderr: SplitParser {
            onRead: line => console.log("[island] mirror:", line)
        }
    }

    Process {
        id: scrcpy
        property string lastErr: ""
        property bool stopping: false
        property bool fake: false
        command: fake ? ["kitty", "--class", "angelos-phone", "-o", "remember_window_size=no", "-o", "initial_window_width=330", "-o", "initial_window_height=720", "sh", "-c", "echo экран телефона; sleep 600"] : ["scrcpy", "-s", root.serial, "--window-title", root.name, "--max-size", "1920", "--window-height", String(root.startHeight), "--video-codec=h264", "--window-borderless", "--stay-awake"].concat(root.audio ? [] : ["--no-audio"])
        environment: ({
                "SDL_VIDEODRIVER": "wayland",
                "SDL_VIDEO_WAYLAND_WMCLASS": "angelos-phone",
                "SDL_APP_ID": "angelos-phone"
            })
        stderr: SplitParser {
            onRead: line => {
                console.log("[island] scrcpy:", line);
                if (/ERROR/.test(line))
                    scrcpy.lastErr = line.replace(/^.*ERROR:\s*/, "");
            }
        }
        onRunningChanged: {
            if (running) {
                lastErr = "";
                stopping = false;
                root.winId = -1;
                root.ratio = 0;
                root.full = false;
                root.tries = 0;
                findTimer.restart();
                root.state = "running";
                root.message = "";
                root.launched();
            }
        }
        onExited: code => {
            if (root.restarting) {
                root.restarting = false;
                running = true;
                return;
            }
            fake = false;
            if (code === 0 || stopping || root.state !== "running") {
                root.state = "idle";
                return;
            }
            root.state = "error";
            root.message = lastErr !== "" ? lastErr : "Трансляция оборвалась";
        }
    }
}
