pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Settings → Updates: pull the dotfiles repository this system was installed
// from and run its installer (scripts/dotfiles-update.sh). Checks once a day
// when allowed; never installs by itself.
Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/dotfiles-update.sh"
    readonly property string managedDir: Config.home + "/.local/share/angelos/dotfiles"
    property string found: ""                     // repository found on disk
    readonly property string repo: Config.expand(Config.updates.repo) || found
    property string state: "idle"                 // idle | checking | updating | cloning | rollingback | done | failed
    property var log: []
    property var incoming: []
    property int behind: 0
    property int ahead: 0
    property int dirty: 0
    property string branch: ""
    property string remote: ""
    property bool trusted: true
    property string error: ""
    readonly property bool busy: state === "checking" || state === "updating" || state === "cloning" || state === "rollingback"
    // TrollOS: files where the user's edits and the update could not be merged
    // (the user's file stays, the new version is next to it as *.trollos-new)
    property var conflicts: []
    // the latest update snapshot, for «Откатить»: {dir, from, to, when, rolledBack}
    property var last: null
    readonly property bool canRollback: !!last && !last.rolledBack
    readonly property bool available: behind > 0

    function find() {
        if (!finder.running)
            finder.running = true;
    }
    function check() {
        if (busy || !repo)
            return;
        state = "checking";
        error = "";
        checker.command = ["bash", script, "--check", repo];
        checker.running = true;
    }
    function update() {
        if (busy || !repo)
            return;
        state = "updating";
        conflicts = [];
        log = ["» " + repo];
        runner.command = ["bash", script, repo];
        runner.running = true;
    }
    function clone() {
        if (busy)
            return;
        state = "cloning";
        log = [];
        runner.command = ["bash", script, "--clone", managedDir];
        runner.running = true;
    }
    function rollback() {
        if (busy || !canRollback)
            return;
        state = "rollingback";
        conflicts = [];
        log = [];
        runner.command = ["bash", script, "--rollback"].concat(repo ? [repo] : []);
        runner.running = true;
    }
    // TrollOS: angelOS (the original) — only where the repository has an "upstream" remote (the author's)
    property bool hasUpstream: false
    property int upstreamBehind: 0
    property var upstreamIncoming: []
    property bool upstreamChecking: false
    function checkUpstream() {
        if (!repo || upstreamReader.running)
            return;
        upstreamChecking = true;
        upstreamReader.command = ["bash", script, "--upstream", repo];
        upstreamReader.running = true;
    }
    Process {
        id: upstreamReader
        stdout: StdioCollector {
            onStreamFinished: {
                const inc = [];
                let has = false, n = 0;
                for (const l of text.split("\n")) {
                    if (l.startsWith("BEHIND ")) {
                        has = true;
                        n = parseInt(l.slice(7)) || 0;
                    } else if (l.startsWith("IN "))
                        inc.push(l.slice(3));
                }
                root.hasUpstream = has;
                root.upstreamBehind = n;
                root.upstreamIncoming = inc;
            }
        }
        onExited: root.upstreamChecking = false
    }
    function readLast() {
        if (!lastReader.running)
            lastReader.running = true;
    }
    function restartShell() {
        Quickshell.execDetached([Quickshell.shellDir + "/bin/angelos", "restart"]);
    }

    Process {
        id: finder
        running: true
        command: ["bash", root.script, "--find"]
        stdout: StdioCollector {
            onStreamFinished: root.found = text.trim()
        }
    }
    Process {
        id: lastReader
        running: true
        command: ["bash", root.script, "--last"]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const l of text.split("\n")) {
                    const i = l.indexOf(" ");
                    if (i > 0)
                        o[l.slice(0, i)] = l.slice(i + 1);
                }
                root.last = o.SNAPSHOT ? {
                    "dir": o.SNAPSHOT,
                    "from": (o.FROM || "").slice(0, 7),
                    "to": (o.TO || "").slice(0, 7),
                    "when": o.WHEN || "",
                    "rolledBack": o.ROLLEDBACK === "1"
                } : null;
            }
        }
    }
    Process {
        id: checker
        stdout: StdioCollector {
            onStreamFinished: {
                const inc = [];
                for (const l of text.split("\n")) {
                    const parts = l.split(" ");
                    const k = parts.shift();
                    const v = parts.join(" ");
                    if (k === "BRANCH")
                        root.branch = v;
                    else if (k === "BEHIND")
                        root.behind = parseInt(v) || 0;
                    else if (k === "AHEAD")
                        root.ahead = parseInt(v) || 0;
                    else if (k === "DIRTY")
                        root.dirty = parseInt(v) || 0;
                    else if (k === "REMOTE")
                        root.remote = v;
                    else if (k === "TRUSTED")
                        root.trusted = v === "1";
                    else if (k === "IN")
                        inc.push(v);
                    else if (k === "ERR")
                        root.error = v;
                }
                root.incoming = inc;
                Config.updates.lastCheck = new Date().toISOString();
                Config.updates.available = root.behind;
            }
        }
        onExited: code => {
            root.checkUpstream();
            root.state = code === 0 ? "idle" : "failed";
            if (code !== 0 && !root.error)
                root.error = I18n.t("не удалось связаться с репозиторием", "could not reach the repository");
            root.maybeNotify();
        }
    }
    Process {
        id: runner
        stdout: SplitParser {
            onRead: line => {
                root.log = root.log.concat([line]).slice(-500);
                const m = /^» CONFLICT (.+)$/.exec(line);
                if (m)
                    root.conflicts = root.conflicts.concat([m[1]]);
            }
        }
        stderr: SplitParser {
            onRead: line => root.log = root.log.concat([line]).slice(-500)
        }
        onExited: code => {
            const cloned = root.state === "cloning";
            root.state = code === 0 ? "done" : "failed";
            root.log = root.log.concat([code === 0 ? I18n.t("✓ готово", "✓ done") : I18n.t("✕ код выхода ", "✕ exit code ") + code]);
            if (code === 0 && !cloned) {
                // the installer ships default binds / cursor: put the user's choices back
                WorkspaceAnim.reapply();
                if (Config.cursor.theme)
                    Cursors.apply(Config.cursor.theme, Config.cursor.size);
            }
            root.find();
            root.readLast();
            Qt.callLater(root.check);
        }
    }

    // ---- once a day, only telling ----
    property string notifiedFor: ""
    function maybeNotify() {
        if (behind <= 0 || !incoming.length || Shell.dev)
            return;
        const head = incoming[0].split(" ")[0];
        if (head === notifiedFor)
            return;
        notifiedFor = head;
        Quickshell.execDetached(["notify-send", "-a", "TrollOS", "-i", "system-software-update", I18n.t("Доступно обновление TrollOS", "A TrollOS update is available"), I18n.t("Новых изменений: ", "New changes: ") + behind + I18n.t(". Настройки → Обновления.", ". Settings → Updates.")]);
    }
    Timer {
        interval: 90 * 1000
        running: Config.ready && Config.updates.autoCheck
        repeat: true
        onTriggered: {
            interval = 6 * 3600 * 1000;
            const last = Date.parse(Config.updates.lastCheck || "") || 0;
            if (Date.now() - last > 22 * 3600 * 1000)
                root.check();
        }
    }
}
