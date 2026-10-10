import QtQuick
import Quickshell.Io

// Телефон через KDE Connect: кто на связи, батарея, отправка файлов / текста / буфера.
Item {
    id: root

    property bool watching: false          // остров открыт — опрашиваем чаще
    property string deviceId: ""
    property string name: ""
    property bool reachable: false
    property int battery: -1
    property bool charging: false
    readonly property bool ready: reachable && deviceId !== ""
    signal picked(var files)               // выбрали файлы в диалоге — Main откроет остров и отправит

    // последняя отправка: idle | sending | done | error
    property string state: "idle"
    property string stateText: ""

    function refresh() {
        if (!probe.running)
            probe.running = true;
    }

    function fileName(u) {
        let s = String(u);
        if (s.startsWith("file://"))
            s = decodeURIComponent(s.slice(7));
        const parts = s.split("/").filter(p => p !== "");
        return parts.length ? parts[parts.length - 1] : s;
    }

    function run(argv, sendingText, doneText, sharing) {
        if (!ready || sender.running)
            return false;
        jobFailed = "";
        progress = -1;
        sender.sharing = !!sharing;
        state = "sending";
        stateText = sendingText;
        sender.doneText = doneText;
        sender.command = argv;
        sender.running = true;
        return true;
    }

    function sendFiles(urls) {
        const list = urls.map(u => String(u)).filter(u => u !== "");
        if (!list.length)
            return false;
        const label = list.length === 1 ? fileName(list[0]) : list.length + " файл(ов)";
        return run(["sh", "-c", 'id=$1; shift; for f; do kdeconnect-cli -d "$id" --share "$f" || exit 1; done', "sh", deviceId].concat(list), "Отправляю " + label + "…", label + " — на телефоне", list.every(u => u.startsWith("file://") || u.startsWith("/")));
    }
    // картинка/файл по ссылке из браузера: скачать (у Pinterest — оригинал) и отправить файлом
    function sendWebFile(url) {
        const label = fileName(url.split("?")[0]) || "картинку";
        return run(["sh", "-c", `
id=$1; url=$2; dir="$HOME/.cache/angelos/island"; mkdir -p "$dir"
name=$(basename "\${url%%[?#]*}"); [ -n "$name" ] || name=file
f="$dir/$(date +%s)-$name"
orig=$(printf %s "$url" | sed -E 's#i[.]pinimg[.]com/[0-9]+x[0-9]*/#i.pinimg.com/originals/#')
get() { curl -fsSL --max-time 40 -A 'Mozilla/5.0 (X11; Linux x86_64)' -o "$f" "$1"; }
get "$orig" || get "$url" || exit 2
kdeconnect-cli -d "$id" --share "$f"
`, "sh", deviceId, url], "Скачиваю " + label + "…", label + " — на телефоне", true);
    }
    function sendText(text) {
        return run(["kdeconnect-cli", "-d", deviceId, "--share-text", text], "Отправляю текст…", "Текст на телефоне");
    }
    function sendClipboard() {
        return run(["kdeconnect-cli", "-d", deviceId, "--send-clipboard"], "Отправляю буфер…", "Буфер обмена на телефоне");
    }
    function ring() {
        return run(["kdeconnect-cli", "-d", deviceId, "--ring"], "Звоню на телефон…", "Телефон звонит");
    }
    function reject(text) {
        state = "error";
        stateText = text;
        forget.restart();
    }
    // для проверки анимации (ipc island fxTest): притвориться, что отправили
    function fake(result) {
        state = "sending";
        stateText = "Отправляю test.png…";
        fakeTimer.result = result;
        fakeTimer.restart();
    }
    Timer {
        id: fakeTimer
        property string result: "done"
        interval: 250
        onTriggered: {
            root.state = result === "error" ? "error" : "done";
            root.stateText = result === "error" ? "Не получилось — телефон не ответил" : "test.png — на телефоне";
            forget.restart();
        }
    }
    function pickAndSend() {
        if (ready && !picker.running)
            picker.running = true;
    }

    Process {
        id: probe
        command: ["sh", "-c", `
a=$(kdeconnect-cli -a --id-name-only 2>/dev/null | head -n1)
r=1
if [ -z "$a" ]; then r=0; a=$(kdeconnect-cli -l --id-name-only 2>/dev/null | head -n1); fi
[ -z "$a" ] && { echo none; exit 0; }
id=\${a%% *}; name=\${a#* }
p=/modules/kdeconnect/devices/$id/battery
c=$(busctl --user get-property org.kde.kdeconnect $p org.kde.kdeconnect.device.battery charge 2>/dev/null | awk '{print $2}')
ch=$(busctl --user get-property org.kde.kdeconnect $p org.kde.kdeconnect.device.battery isCharging 2>/dev/null | awk '{print $2}')
printf '%s\\t%s\\t%s\\t%s\\t%s\\n' "$r" "$id" "$name" "\${c:--1}" "\${ch:-false}"
`]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t === "" || t === "none") {
                    root.deviceId = "";
                    root.name = "";
                    root.reachable = false;
                    root.battery = -1;
                    return;
                }
                const f = t.split("\t");
                root.reachable = f[0] === "1";
                root.deviceId = f[1] || "";
                root.name = f[2] || "Телефон";
                root.battery = parseInt(f[3]);
                if (isNaN(root.battery))
                    root.battery = -1;
                root.charging = f[4] === "true";
            }
        }
    }

    Process {
        id: sender
        property string doneText: ""
        property bool sharing: false       // это отправка файлов: итог скажет служба задач
        stderr: StdioCollector {
            onStreamFinished: if (this.text.trim() !== "")
                console.log("[island] kdeconnect:", this.text.trim())
        }
        onExited: code => {
            if (code !== 0) {
                root.finish(false, code === 2 ? "Не получилось скачать картинку" : "Не получилось — телефон не ответил");
                return;
            }
            // kdeconnect-cli только ставит файл в очередь — ждём настоящую передачу
            if (sharing && root.jobsReady) {
                root.waitingJobs = true;
                noJob.restart();
            } else
                root.finish(true, doneText);
        }
    }
    function finish(ok, text) {
        waitingJobs = false;
        noJob.stop();
        settle.stop();
        progress = -1;
        jobFailed = "";
        state = ok ? "done" : "error";
        stateText = text;
        forget.restart();
    }

    // ---- настоящая передача: прогресс от службы задач KDE (jobserver.py) ----
    property bool jobsReady: false
    property bool waitingJobs: false
    property var phoneJobs: ({})           // id -> {file, total}
    property int phoneJobCount: 0
    property real progress: -1             // 0..1, -1 — неизвестно
    property string jobFailed: ""
    property var otherJob: null            // чужая задача KDE (копирование и т. п.): {id, title, file, percent}
    signal otherJobStarted

    function cancel() {
        for (const id in phoneJobs)
            jobProc.write("cancel " + id + "\n");
        if (otherJob)
            jobProc.write("cancel " + otherJob.id + "\n");
    }

    function jobLine(line) {
        let e;
        try {
            e = JSON.parse(line);
        } catch (err) {
            return;
        }
        if (e.ev === "ready") {
            jobsReady = true;
            return;
        }
        if (e.ev === "lost") {
            jobsReady = false;
            console.log("[island] org.kde.kuiserver уже занят кем-то другим — прогресс KDE не будет в острове");
            return;
        }
        const isPhone = e.ev === "new" ? /kdeconnect/i.test(e.app || "") : !!phoneJobs[e.id];
        if (e.ev === "new") {
            if (isPhone) {
                const j = Object.assign({}, phoneJobs);
                j[e.id] = {
                    "file": ""
                };
                phoneJobs = j;
                phoneJobCount++;
                noJob.stop();
                settle.stop();
                if (state !== "sending") {
                    // отправили не из острова (Dolphin, меню «Отправить на…») — всё равно показываем
                    state = "sending";
                    stateText = "Отправляю…";
                    externalSend();
                }
            } else {
                otherJob = {
                    "id": e.id,
                    "title": "",
                    "file": "",
                    "percent": -1
                };
                otherJobStarted();
            }
            return;
        }
        if (e.ev === "update") {
            const d = e.data || {};
            const pct = d.percent !== undefined ? d.percent / 100 : d.totalBytes > 0 && d.processedBytes !== undefined ? d.processedBytes / d.totalBytes : -1;
            const file = d.descriptionValue1 || "";
            if (isPhone) {
                if (pct >= 0)
                    progress = Math.min(1, pct);
                if (file !== "")
                    phoneJobs[e.id].file = fileName(file);
                const f = phoneJobs[e.id].file;
                stateText = "Отправляю " + (f || "файл") + (progress >= 0 ? " — " + Math.round(progress * 100) + "%" : "…");
            } else if (otherJob && otherJob.id === e.id) {
                const o = Object.assign({}, otherJob);
                if (d.title)
                    o.title = d.title;
                if (file !== "")
                    o.file = fileName(file);
                if (pct >= 0)
                    o.percent = Math.min(1, pct);
                otherJob = o;
            }
            return;
        }
        if (e.ev === "end") {
            if (isPhone) {
                const j = Object.assign({}, phoneJobs);
                const f = j[e.id] ? j[e.id].file : "";
                delete j[e.id];
                phoneJobs = j;
                phoneJobCount--;
                if (e.code !== 0)
                    jobFailed = e.code === 1 ? "Отправка отменена" : (e.msg || "Передача прервалась") + (f ? " (" + f + ")" : "");
                if (phoneJobCount <= 0 && !sender.running)
                    settle.restart();
            } else if (otherJob && otherJob.id === e.id) {
                otherJob = null;
            }
        }
    }
    signal externalSend

    // файлов несколько — следующая передача стартует не сразу
    Timer {
        id: settle
        interval: 900
        onTriggered: {
            if (root.phoneJobCount > 0)
                return;
            if (root.jobFailed !== "")
                root.finish(false, root.jobFailed);
            else
                root.finish(true, root.state === "sending" && sender.doneText !== "" && root.waitingJobs ? sender.doneText : "Файл на телефоне");
        }
    }
    // передача так и не началась — значит, обошлось без неё (или служба не та)
    Timer {
        id: noJob
        interval: 5000
        onTriggered: if (root.waitingJobs && root.phoneJobCount === 0)
            root.finish(true, sender.doneText)
    }

    Process {
        id: jobProc
        command: ["python3", "-I", decodeURIComponent(String(Qt.resolvedUrl("jobserver.py")).replace("file://", ""))]
        running: true
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => root.jobLine(line)
        }
        stderr: SplitParser {
            onRead: line => console.log("[island] jobserver:", line)
        }
        onExited: root.jobsReady = false
    }

    Timer {
        id: forget
        interval: 6000
        onTriggered: if (root.state !== "sending")
            root.state = "idle"
    }

    Process {
        id: picker
        command: ["zenity", "--file-selection", "--multiple", "--separator=\n", "--title=Отправить на телефон"]
        stdout: StdioCollector {
            onStreamFinished: {
                const files = this.text.split("\n").filter(s => s !== "");
                if (files.length)
                    root.picked(files);
            }
        }
    }

    Timer {
        interval: root.watching ? 5000 : 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
    onWatchingChanged: if (watching)
        refresh()
}
