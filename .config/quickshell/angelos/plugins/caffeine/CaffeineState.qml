pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shared on/off state. The Wayland idle inhibitor itself lives in BarWidget
// (it needs a window); here we also hold a logind "idle" inhibitor so an
// IdleAction= in logind.conf can't suspend the PC either. Manual sleep from
// the power menu still works, like in GNOME.
Singleton {
    id: root

    property bool active: false
    // переживает перезагрузку оболочки, но не ПК: /run/user очищается при выключении
    readonly property string flag: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/angelos-caffeine"

    Component.onCompleted: restore.running = true
    Process {
        id: restore
        command: ["test", "-e", root.flag]
        onExited: code => root.active = code === 0
    }

    function toggle() {
        active = !active;
        Quickshell.execDetached(active ? ["touch", flag] : ["rm", "-f", flag]);
        const icon = Qt.resolvedUrl(active ? "cup-on.png" : "cup-off.png").toString().replace("file://", "");
        Quickshell.execDetached(["notify-send", "-a", "angelOS", "-t", "2000", "-i", icon,
            active ? "☕ Кофеин включён" : "Кофеин выключен",
            active ? "Экран не погаснет, ПК не уснёт" : "Снова можно спать"]);
    }

    Process {
        running: root.active
        command: ["systemd-inhibit", "--what=idle", "--who=angelOS", "--why=Кофеин", "--mode=block", "sleep", "infinity"]
    }
}
