import QtQuick
import qs.config
import Quickshell
import qs.services
import "."

// Nags when "stress" stays high.
Item {
    id: root
    property var plugin
    property int high: 0

    Timer {
        interval: 5000
        running: !Shell.locked   // nothing to show behind the lock screen
        repeat: true
        onTriggered: {
            root.high = Stats.stress > 0.9 ? root.high + 1 : 0;
            if (root.high === 6 && root.plugin && root.plugin.get("nag", true))
                Quickshell.execDetached(["notify-send", "-a", I18n.t("Стрим-статы", "Stream stats"), "стресс 100%!!", "компьютер перегрелся от любви… может, передохнём? ♡"]);
        }
    }
}
