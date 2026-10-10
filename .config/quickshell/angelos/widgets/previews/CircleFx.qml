import QtQuick
import qs.config
import qs.services
import qs.widgets

// The way into a circle of hell (Settings → Appearance → Motion, D4): the real veil
// (shaders/circle_veil, as modules/y2k/CircleTransition draws it) comes down over a little
// desk, the circle's number and name come up out of the dark, the dark lifts on the circle's
// own colours. variant: the motion level — full (the blow shakes the screen), calm (slower,
// no shaking), off (a cut: before, then after).
Scene {
    id: root

    readonly property string circleId: "greed"
    readonly property var look: HellLook.merged(HellLook.fallback, HellLook.looks.base, HellLook.looks[circleId])
    readonly property var pal: look.palette || ({})
    readonly property bool cut: variant === "off"
    readonly property bool gentle: variant === "calm"
    // the dark: down, a hold, up — calm takes longer both ways
    readonly property real veil: cut ? 0 : gentle ? Math.min(seg(0.08, 0.4), 1 - seg(0.7, 0.95)) : Math.min(seg(0.12, 0.28), 1 - seg(0.78, 0.9))
    readonly property real title: cut ? 0 : gentle ? Math.min(seg(0.38, 0.52), 1 - seg(0.68, 0.78)) : Math.min(seg(0.32, 0.4), 1 - seg(0.74, 0.8))
    readonly property bool after: t >= (cut ? 0.5 : gentle ? 0.7 : 0.78)
    // the blow in the dark: a few frames of shaking, full only
    readonly property real jolt: variant === "full" && t > 0.28 && t < 0.36 ? (Math.floor(t * 120) % 2 ? 1 : -1) * Theme.u * 2 : 0

    Item {
        id: world
        x: root.jolt
        width: root.width
        height: root.height
        Rectangle {
            anchors.fill: parent
            visible: root.after
            color: root.pal.body || "#0b0809"
        }
        // a window on the desk
        Rectangle {
            x: Math.round(root.width * 0.16)
            y: Math.round(root.height * 0.14)
            width: Math.round(root.width * 0.46)
            height: Math.round(root.height * 0.56)
            color: root.after ? root.pal.face : Theme.face
            border.width: Math.max(1, Theme.u / 2)
            border.color: root.after ? root.pal.rim : Theme.lo
            Rectangle {
                width: parent.width
                height: Theme.u * 6
                color: root.after ? root.pal.faceAlt : Theme.mix(Theme.faceAlt, Theme.accent, 0.3)
            }
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    x: Theme.u * 4
                    y: Theme.u * (11 + index * 6)
                    width: parent.width * (0.7 - index * 0.15)
                    height: Theme.u * 2
                    color: root.after ? root.pal.textDim : Theme.textDim
                    opacity: 0.6
                }
            }
        }
        // the bar
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Theme.u * 8
            color: root.after ? root.pal.plate : Theme.face
            Rectangle {
                width: parent.width
                height: Math.max(1, Theme.u / 2)
                color: root.after ? root.pal.accent : Theme.accent
            }
        }
    }
    ShaderEffect {
        anchors.fill: parent
        visible: root.veil > 0
        property real progress: root.veil
        property real cell: Theme.u * 2
        property size size: Qt.size(width, height)
        property color tint: "#030303"
        fragmentShader: Qt.resolvedUrl("../../shaders/circle_veil.frag.qsb")
    }
    Column {
        anchors.centerIn: parent
        spacing: Theme.u * 2
        opacity: root.title
        visible: opacity > 0
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Theme.roman(Story.circleN(root.circleId))
            color: root.pal.accent || Theme.hellAccent
            font.family: Theme.fontHell
            font.pixelSize: Theme.hellPx(Math.max(2, Theme.fs * 2))
            renderType: Text.NativeRendering
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.look.name ? I18n.label(root.look.name) : ""
            color: root.pal.text || Theme.hellText
            font.family: Theme.fontHellText
            font.pixelSize: Theme.hellTextPx(Math.max(1, Theme.fs))
            renderType: Text.NativeRendering
        }
    }
}
