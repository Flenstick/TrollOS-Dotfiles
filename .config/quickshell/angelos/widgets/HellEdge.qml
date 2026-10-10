import QtQuick
import qs.config

// The rim of a window or widget in hell (shaders/hell_edge.frag): what the circle did to its
// edges (HellLook.edge = {kind, colors: [edge, rim, light, stain]}) — burnt, rimed, rusted,
// wet… Still; only the rare event (HellLook.event, services/HellAmbient) moves it, and only
// on the windows whose `seed` picks the event's target. Lies over the window, takes no input.
ShaderEffect {
    id: root

    property var spec: HellLook.edge
    property real seed: 0
    readonly property var kinds: ["scorch", "frost", "tarnish", "wet", "ash", "wind", "grime", "iron", "blood", "pitch"]
    readonly property real kind: Math.max(0, kinds.indexOf(spec && spec.kind ? spec.kind : "scorch"))
    readonly property real event: HellLook.eventTarget >= 0 && Math.floor(seed) % 6 === HellLook.eventTarget ? HellLook.event : 0
    readonly property var colors: spec && spec.colors && spec.colors.length >= 4 ? spec.colors : ["#040303", "#3b2a26", "#d8643a", "#2a1512"]
    readonly property color cEdge: colors[0]
    readonly property color cRim: colors[1]
    readonly property color cLight: colors[2]
    readonly property color cStain: colors[3]
    readonly property real dpr: Window.window && Window.window.devicePixelRatio > 0 ? Window.window.devicePixelRatio : 1
    readonly property real artPx: Math.max(1, Math.round(Theme.u * dpr))
    readonly property size cells: Qt.size(Math.max(1, Math.round(width * dpr / artPx)), Math.max(1, Math.round(height * dpr / artPx)))
    fragmentShader: Qt.resolvedUrl("../shaders/hell_edge.frag.qsb")
}
