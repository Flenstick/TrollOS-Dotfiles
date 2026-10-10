import QtQuick
import qs.config
import qs.modules.background

// The open flyout of a circle's menu look: hell's column of pills (FlyColumn; heaven's looks
// set hell: false) next to the entry it came from — `at` is where that entry is (its outer edge), `reach` how close to the
// middle the pills may come.
FlyColumn {
    id: fly

    property point at: Qt.point(menu.cx, menu.cy)
    hell: true
    angle: Math.atan2(at.y - menu.cy, at.x - menu.cx)
    radius: Math.hypot(at.x - menu.cx, at.y - menu.cy) + Theme.u * 8
}
