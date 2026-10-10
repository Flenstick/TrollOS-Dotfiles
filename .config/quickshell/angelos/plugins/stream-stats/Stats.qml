pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Shared numbers for the stream-stats plugin (0..1).
Singleton {
    id: root

    property real stress: 0
    property real darkness: 0
    property real love: 0
    property var _last: null

    Timer {
        interval: 2000
        running: !Shell.locked   // nothing to show behind the lock screen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            mem.reload();
            up.reload();
        }
    }
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
            if (root._last) {
                const dt = total - root._last.total, di = idle - root._last.idle;
                root.stress = dt > 0 ? 1 - di / dt : 0;
            }
            root._last = {
                "total": total,
                "idle": idle
            };
        }
    }
    FileView {
        id: mem
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const g = k => parseInt((t.match(new RegExp(k + ":\\s+(\\d+)")) || [0, 0])[1]);
            root.darkness = 1 - g("MemAvailable") / Math.max(1, g("MemTotal"));
        }
    }
    FileView {
        id: up
        path: "/proc/uptime"
        onLoaded: root.love = Math.min(1, parseFloat(text()) / (8 * 3600))
    }
}
