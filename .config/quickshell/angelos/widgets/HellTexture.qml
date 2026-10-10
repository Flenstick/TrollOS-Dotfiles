import QtQuick
import qs.config

// Hell's ground (shaders/hell_texture.frag): the pattern and colours a circle gives
// (`spec`, by default the bar's: HellLook.bar = {texture, colors[4], scale, crack, glow,
// seed}). Art pixels are counted in device pixels — one is round(Theme.u × the screen's
// scale) of them — so the pattern stays crisp at 1.25×, 1.5×, 2×. Nothing moves unless
// `time` is driven from outside (a circle's rare event): a still frame costs nothing.
ShaderEffect {
    id: root

    property var spec: HellLook.bar
    property real time: 0
    readonly property var kinds: ["stone", "ash", "water", "ice", "iron", "sand", "pitch", "whirl"]
    readonly property real kind: Math.max(0, kinds.indexOf(spec && spec.texture ? spec.texture : "stone"))
    readonly property real grid: spec && spec.scale ? spec.scale : 10
    readonly property real crack: spec && spec.crack !== undefined ? spec.crack : 0.5
    readonly property real glow: spec && spec.glow !== undefined ? spec.glow : 0
    readonly property real seed: spec && spec.seed !== undefined ? spec.seed : 1
    readonly property var colors: spec && spec.colors && spec.colors.length >= 4 ? spec.colors : ["#120708", "#1a0b0d", "#2a0e10", "#5a1814"]
    readonly property color c0: colors[0]
    readonly property color c1: colors[1]
    readonly property color c2: colors[2]
    readonly property color c3: colors[3]
    readonly property real dpr: Window.window && Window.window.devicePixelRatio > 0 ? Window.window.devicePixelRatio : 1
    readonly property real artPx: Math.max(1, Math.round(Theme.u * dpr))
    readonly property size cells: Qt.size(Math.max(1, Math.round(width * dpr / artPx)), Math.max(1, Math.round(height * dpr / artPx)))
    fragmentShader: Qt.resolvedUrl("../shaders/hell_texture.frag.qsb")
}
