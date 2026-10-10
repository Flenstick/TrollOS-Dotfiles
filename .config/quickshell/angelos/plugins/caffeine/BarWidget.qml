import QtQuick
import Quickshell.Wayland
import qs.config
import qs.widgets
import "."

// Cup on the bar: click toggles. Steam = awake.
Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow

    implicitWidth: cup.implicitWidth + Theme.u * 4
    implicitHeight: Theme.u * 13

    // niri pauses idle timers (swayidle, auto-lock, screen off) while this is on
    IdleInhibitor {
        window: root.barWindow
        enabled: CaffeineState.active
    }

    PxIcon {
        id: cup
        anchors.centerIn: parent
        pixel: Theme.u
        opacity: CaffeineState.active || mouse.containsMouse ? 1 : 0.55
        bitmap: CaffeineState.active ? [
            "..w..w.....",
            ".w..w......",
            "..w..w.....",
            "#########..",
            "#yyyyyyy###",
            "#ooooooo#.#",
            "#ooooooo#.#",
            "#ooooooo###",
            ".#ooooo#...",
            "..#####...."
        ] : [
            "...........",
            "...........",
            "...........",
            "#########..",
            "#fffffff###",
            "#fffffff#.#",
            "#fffffff#.#",
            "#fffffff###",
            ".#fffff#...",
            "..#####...."
        ]
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: CaffeineState.toggle()
    }
}
