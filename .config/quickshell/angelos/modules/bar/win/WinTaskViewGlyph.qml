import QtQuick
import qs.services

// Task view icon: two staggered rounded panes, like the Windows 11 button.
Item {
    property int size: 24
    width: size
    height: size
    Rectangle {
        x: size * 0.08
        y: size * 0.18
        width: size * 0.58
        height: size * 0.58
        radius: size * 0.1
        color: "transparent"
        border.width: Math.max(1.5, size / 14)
        border.color: WinStyle.dark ? "#b8b8b8" : "#5a5a5a"
    }
    Rectangle {
        x: size * 0.34
        y: size * 0.26
        width: size * 0.58
        height: size * 0.58
        radius: size * 0.1
        color: WinStyle.dark ? "#3a3a3a" : "#e8e8e8"
        border.width: Math.max(1.5, size / 14)
        border.color: WinStyle.dark ? "#f0f0f0" : "#2a2a2a"
    }
}
