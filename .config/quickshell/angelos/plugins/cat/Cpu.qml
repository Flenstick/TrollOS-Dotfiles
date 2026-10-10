pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// CPU load 0..100 from /proc/stat.
Singleton {
    id: root

    property real percent: 0
    property int intervalMs: 2000
    property var _last: null

    Timer {
        interval: root.intervalMs
        running: !Shell.locked   // nothing to show behind the lock screen
        repeat: true
        triggeredOnStart: true
        onTriggered: stat.reload()
    }
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
            if (root._last && total > root._last.total)
                root.percent = Math.max(0, Math.min(100, 100 * (1 - (idle - root._last.idle) / (total - root._last.total))));
            root._last = {
                "total": total,
                "idle": idle
            };
        }
    }
}
