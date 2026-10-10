import QtQuick
import qs.config

// A row of hell's pixel flames licking up from this strip's bottom edge
// (shaders/hell_flames.frag, the same as a hell window's): `rows` art pixels high,
// stepped a few times a second while `live`. Turned over (`down`) they hang from the top.
ShaderEffect {
    id: root

    property int rows: 7
    property bool live: true
    property bool down: false
    property real time: 0
    property real seed: 0
    readonly property size cells: Qt.size(Math.max(1, Math.round(width / Theme.u)), rows)
    height: Theme.u * rows
    fragmentShader: Qt.resolvedUrl("../shaders/hell_flames.frag.qsb")
    transform: Scale {
        origin.y: root.height / 2
        yScale: root.down ? -1 : 1
    }

    Timer {
        interval: 140
        repeat: true
        running: root.live && root.visible && !Motion.still
        onTriggered: root.time += 0.14
    }
}
