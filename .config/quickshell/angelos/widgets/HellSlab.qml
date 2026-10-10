import QtQuick
import qs.config

// Hell's stone behind a bar (shaders/hell_slab.frag), in art pixels: "lava" (obsidian
// with glowing cracks), "stone" (dark rock, ember veins), "brimstone" (sulphur crusts),
// "tomb" (grey tombstone) or "blood" (Hellose's black and blood check). The lava breathes
// a few times a second while `live`.
ShaderEffect {
    id: root

    property string look: "lava"
    property bool live: true
    property bool bevelled: true
    property real seed: 0
    property real time: 0
    readonly property real kind: ({
            "lava": 0,
            "stone": 1,
            "brimstone": 2,
            "tomb": 3,
            "blood": 4
        })[look] || 0
    readonly property real bevel: bevelled ? 1 : 0
    readonly property size cells: Qt.size(Math.max(1, Math.round(width / Theme.u)), Math.max(1, Math.round(height / Theme.u)))
    fragmentShader: Qt.resolvedUrl("../shaders/hell_slab.frag.qsb")

    Timer {
        interval: 166
        repeat: true
        running: root.live && root.visible && root.look !== "tomb" && root.look !== "blood" && !Motion.still
        onTriggered: root.time += 0.166
    }
}
