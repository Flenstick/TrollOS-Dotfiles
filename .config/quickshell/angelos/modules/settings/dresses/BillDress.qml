pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings.dresses

// Settings in the circle of gluttony: the bill of fare. A chalkboard in a wooden frame hung
// on a nail by its string, the view chalked on it, a crossed fork and knife in its corners and
// the smudges of yesterday's dishes not quite wiped off.
HellDress {
    id: dress

    paper: "#262b25"
    ink: "#e6e2d3"
    redInk: "#e3a75c"
    title: I18n.t("Меню · сегодня подаём настройки", "Menu · today we serve Settings")
    titleColor: "#e6d9b8"
    closer: "#5a3d24"
    closerInk: "#e6d9b8"
    headHeight: Theme.u * 26
    pageX: Theme.u * 12
    pageRight: Theme.u * 12
    pageTop: headHeight + Theme.u * 4
    pageBottom: Theme.u * 12

    // the string and the nail
    Rectangle {
        x: dress.width / 2 - width / 2
        y: Theme.u * 2
        width: Theme.u * 4
        height: width
        radius: width / 2
        color: "#8c8a80"
    }
    Repeater {
        model: 2
        Rectangle {
            required property int index
            readonly property real dx: dress.width * 0.3
            readonly property real dy: dress.headHeight - Theme.u * 4
            x: dress.width / 2
            y: Theme.u * 4
            width: Math.hypot(dx, dy)
            height: Math.max(1, Theme.u / 2)
            transformOrigin: Item.Left
            rotation: (index ? 180 - Math.atan2(dy, dx) * 180 / Math.PI : Math.atan2(dy, dx) * 180 / Math.PI)
            color: "#7a6a52"
        }
    }
    // the frame
    Rectangle {
        x: Theme.u * 4
        y: dress.headHeight - Theme.u * 4
        width: dress.width - Theme.u * 8
        height: dress.height - y - Theme.u * 4
        color: "#5a3d24"
        border.width: Math.max(2, Theme.u)
        border.color: "#2e1e10"
        // the grain
        Repeater {
            model: 5
            Rectangle {
                required property int index
                x: Theme.u * 2
                y: (index + 1) * parent.height / 6
                width: parent.width - Theme.u * 4
                height: Math.max(1, Theme.u / 2)
                color: Qt.alpha("#2e1e10", 0.35)
            }
        }
    }
    // the fork and the knife, crossed, in two corners
    Repeater {
        model: 2
        PxIcon {
            required property int index
            z: 2
            bitmap: ["w.w.w....", "w.w.w....", "wwwww....", ".www...w.", "..w...ww.", "...w.ww..", "....ww...", "...ww.w..", "..ww...w.", ".ww.....w", "ww.......", "w........"]
            pixel: Math.max(1, Theme.u)
            light: "#e6e2d3"
            mirror: index === 1
            x: index ? dress.width - width - Theme.u * 6 : Theme.u * 6
            y: dress.height - height - Theme.u * 6
            opacity: 0.8
        }
    }
    // smudges of chalk
    Repeater {
        model: 3
        Rectangle {
            required property int index
            z: 2
            x: dress.pageX + [0.12, 0.7, 0.42][index] * (dress.width - dress.pageX * 2)
            y: dress.pageTop + [0.08, 0.86, 0.5][index] * (dress.height - dress.pageTop - dress.pageBottom)
            width: Theme.u * [24, 32, 18][index]
            height: Theme.u * [6, 8, 4][index]
            radius: height / 2
            rotation: [-8, 6, -3][index]
            color: Qt.alpha("#e6e2d3", 0.05)
        }
    }
}
