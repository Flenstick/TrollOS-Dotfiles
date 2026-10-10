pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// Codex limits, today's tokens and live sessions from scan.py (local session logs).
// Limits are whatever the provider sent with its last answer: an API key or a
// third-party provider may send none, then only token counts are shown.
Singleton {
    id: root

    property var data: ({})
    property string status: "idle"      // idle | ok | nocodex | error
    property date updated: new Date(0)
    property int intervalSec: 60
    property real now: Date.now()

    readonly property var limits: data.limits || null
    readonly property var five: window(limits ? limits.primary : null)
    readonly property var week: window(limits ? limits.secondary : null)
    readonly property var credits: limits && limits.credits ? limits.credits : null
    readonly property bool hasLimits: !!five || !!week
    readonly property real fiveLeft: five ? five.left : -1
    readonly property real weekLeft: week ? week.left : -1
    readonly property var today: data.today || ({})
    readonly property var sessions: data.sessions || []
    readonly property string state: sessions.some(s => s.state === "working") ? "working" : sessions.length ? "done" : "none"
    readonly property string plan: limits && limits.plan_type ? String(limits.plan_type) : ""
    readonly property string limitsAgo: data.limitsAt ? ago(data.limitsAt * 1000) : ""

    function window(w) {
        if (!w || w.used_percent === undefined || w.used_percent === null)
            return null;
        const resets = w.resets_at ? new Date(w.resets_at * 1000) : null;
        // the window has rolled over since Codex last heard from the provider
        const rolled = !!resets && resets.getTime() < now;
        const used = rolled ? 0 : Math.max(0, Math.min(100, w.used_percent));
        return {
            "used": used,
            "left": Math.round(100 - used),
            "resetsAt": rolled ? null : resets,
            "minutes": w.window_minutes || 0,
            "rolled": rolled
        };
    }
    function windowLabel(minutes) {
        if (minutes === 300)
            return I18n.t("5 часов", "5 hours");
        if (minutes === 10080)
            return I18n.t("неделя", "week");
        return minutes >= 1440 ? Math.round(minutes / 1440) + I18n.t(" дн", " d") : Math.round(minutes / 60) + I18n.t(" ч", " h");
    }
    function untilText(d) {
        if (!d)
            return "";
        const m = Math.max(0, Math.round((d.getTime() - now) / 60000));
        if (m < 60)
            return m + I18n.t(" мин", " min");
        const h = Math.floor(m / 60);
        if (h < 48)
            return h + I18n.t(" ч ", " h ") + (m % 60) + I18n.t(" мин", " min");
        return Math.floor(h / 24) + I18n.t(" д ", " d ") + (h % 24) + I18n.t(" ч", " h");
    }
    function ago(ms) {
        const m = Math.max(0, Math.round((now - ms) / 60000));
        return m < 1 ? I18n.t("только что", "just now") : m < 60 ? m + I18n.t(" мин назад", " min ago") : m < 2880 ? Math.round(m / 60) + I18n.t(" ч назад", " h ago") : Math.round(m / 1440) + I18n.t(" дн назад", " d ago");
    }
    function tokens(n) {
        n = n || 0;
        return n >= 1e6 ? (n / 1e6).toFixed(1) + "M" : n >= 1e3 ? (n / 1e3).toFixed(0) + "k" : String(n);
    }
    function colorFor(left, theme) {
        return left < 0 ? theme.textDim : left <= 15 ? theme.danger : left <= 40 ? theme.accent3 : theme.ok;
    }
    function stateColor(s, theme) {
        return s === "working" ? theme.accent3 : s === "done" ? theme.ok : theme.textDim;
    }
    readonly property var words: ({
            "working": I18n.t("работает", "Working"),
            "done": I18n.t("готово ♡", "Ready ♡"),
            "none": I18n.t("нет сессий", "No sessions")
        })
    // hell (Theme.hell): plainer words in the circle's text colours (readable on its plates)
    readonly property var hellWords: ({
            "working": I18n.t("работает", "Working"),
            "done": I18n.t("готово", "Done"),
            "none": I18n.t("ни души", "No souls")
        })
    function hellStateColor(s, theme) {
        return s === "working" ? theme.hellText : s === "done" ? theme.hellAccent : theme.hellTextDim;
    }

    function refresh() {
        now = Date.now();
        if (!scanner.running)
            scanner.running = true;
    }
    Timer {
        interval: root.intervalSec * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Process {
        id: scanner
        command: ["python3", Quickshell.shellDir + "/plugins/codex-companion/scan.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (d.error) {
                        root.status = "error";
                        return;
                    }
                    root.data = d;
                    root.status = d.installed ? "ok" : "nocodex";
                    root.updated = new Date();
                } catch (e) {
                    root.status = "error";
                }
            }
        }
        stderr: StdioCollector {}
    }

    // ---- quick question: `codex exec` without the shell tool or web search, read-only ----
    property var answer: null           // {q, text, error}
    property bool asking: false
    function ask(q) {
        q = (q || "").trim();
        if (!q || asker.running)
            return;
        asking = true;
        answer = {
            "q": q,
            "text": "",
            "error": false
        };
        asker.question = q + "\n\n(Answer briefly in plain text; it is shown as a desktop notification. Reply in the language of the question.)";
        asker.running = true;
    }
    Process {
        id: asker
        property string question: ""
        stdinEnabled: true
        command: ["sh", "-c", 'mkdir -p "$1" && cd "$1" && exec codex exec --ephemeral --skip-git-repo-check --sandbox read-only --disable shell_tool -c web_search=disabled --color never -', "sh", Config.cacheDir + "/codex-ask"]
        onStarted: {
            write(question);
            stdinEnabled = false;   // EOF: the prompt is complete
        }
        stdout: StdioCollector {
            id: askOut
        }
        stderr: StdioCollector {
            id: askErr
        }
        onExited: code => {
            stdinEnabled = true;
            const text = askOut.text.trim();
            const failed = code !== 0 || text === "";
            const message = failed ? (code === 127 ? I18n.t("codex не найден в PATH", "codex was not found in PATH") : (askErr.text.trim().split("\n").slice(-2).join(" ") || I18n.t("codex завершился с кодом ", "codex exited with code ") + code)) : text;
            root.asking = false;
            root.answer = {
                "q": root.answer ? root.answer.q : "",
                "text": message,
                "error": failed
            };
            Quickshell.execDetached(["notify-send", "-a", "Codex", failed ? I18n.t("Codex: ошибка", "Codex: error") : I18n.t("Codex ответил ♡", "Codex replied ♡"), message.length > 280 ? message.slice(0, 280) + "…" : message]);
            root.refresh();
        }
    }

    // ---- terminal sessions ----
    function launch(args) {
        const argv = ["sh", "-c", 'cd "$HOME"; exec codex "$@"', "sh"].concat(args || []);
        Quickshell.execDetached(Shell.terminalArgv(argv));
    }
    function login() {
        Quickshell.execDetached(Shell.terminalArgv(["sh", "-c", 'codex login; printf "\\n♡ Enter — закрыть / close"; read _']));
    }
}
