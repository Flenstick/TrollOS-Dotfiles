import QtQuick
import qs.config
import qs.widgets

// "What she breaks" (Settings → Y2K, D4): her fist lands in the corner and it spreads over a
// little desk — the very drawing the desktop gets (widgets/BreakageArt). variant: circle (the
// current circle's set, one after another) | random (every kind, another one each pass) | one
// kind (HellLook.breakageKinds).
Scene {
    id: root

    readonly property var kinds: HellLook.breakageKinds
    readonly property string kind: variant === "random" ? kinds[loops % kinds.length] : variant === "circle" || !variant ? HellLook.breakage[loops % HellLook.breakage.length] : kinds.includes(variant) ? variant : "glass"

    // a window it breaks over
    Rectangle {
        x: Math.round(root.width * 0.3)
        y: Math.round(root.height * 0.12)
        width: Math.round(root.width * 0.5)
        height: Math.round(root.height * 0.55)
        color: Theme.face
        border.width: Math.max(1, Theme.u / 2)
        border.color: Theme.lo
        Rectangle {
            width: parent.width
            height: Theme.u * 6
            color: Theme.faceAlt
        }
    }
    // the corner square, as on the desktop (ScreenCracks: bottom left by default)
    BreakageArt {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: root.height
        height: root.height
        kind: root.kind
        grow: root.steps(root.seg(0.12, 0.7), 12)
        seed: 7 + root.loops
        weak: Config.y2k.cracks === "weak"
        impact: Qt.point(0.14, 0.92)
        clock: root.t * 4
    }
}
