import QtQuick
import qs.config

// A workspace's sprite (Settings → Workspaces → Desk sprite): heart | star | cd.
// `lit` = the active desk: full colours (the CD's rainbow), and on becoming
// active the CD spins once in 90° steps and the star twinkles — pixel-exact,
// no smoothing, nothing runs while it stands still.
PxIcon {
    id: root

    property string sprite: Config.workspaces.sprite || "heart"
    property bool lit: false
    property color tone: Theme.accent4          // the fill when not lit
    property bool playful: true                 // spin / twinkle on activation
    // the hell bar: one tone (fill) for the whole sprite, an outline in the dim text
    property bool barInk: false
    readonly property string kind: ["heart", "star", "cd"].includes(sprite) ? sprite : "heart"
    property int turn: 0                        // quarter turns
    property real glint: 0

    name: iconOf(kind)
    fill: lit ? Theme.accent : tone
    fill2: barInk ? fill : lit ? Theme.accent2 : tone
    fill3: barInk ? fill : lit ? Theme.accent3 : tone
    light: barInk ? (lit ? Theme.hellText : Theme.hellSpriteHi) : glint > 0.5 ? Theme.accent3 : "#ffffff"
    ink: barInk ? (lit ? Theme.hellText : Theme.hellTextDim) : Theme.dark ? Theme.text : Theme.edge
    rotation: turn * 90

    function iconOf(k) {
        return k === "star" ? "sparkleStar" : k === "cd" ? "cd" : "heart";
    }
    function celebrate() {
        if (!playful)
            return;
        if (kind === "cd") {
            turn = 0;
            spin.restart();
        } else if (kind === "star") {
            twinkle.restart();
        }
    }
    onLitChanged: if (lit)
        celebrate()

    // a CD spinning up and slowing down: 90° steps, shorter gaps in the middle
    Timer {
        id: spin
        property int step: 0
        readonly property var gaps: [110, 80, 60, 50, 50, 60, 80, 110]
        interval: gaps[Math.min(step, gaps.length - 1)]
        repeat: true
        onRunningChanged: if (running)
            step = 0
        onTriggered: {
            root.turn = (root.turn + 1) % 4;
            step++;
            if (step >= gaps.length) {
                stop();
                root.turn = 0;
            }
        }
    }
    // the star: two flashes of its white core
    SequentialAnimation {
        id: twinkle
        PropertyAction {
            target: root
            property: "glint"
            value: 1
        }
        PauseAnimation {
            duration: Motion.ms(90)
        }
        PropertyAction {
            target: root
            property: "glint"
            value: 0
        }
        PauseAnimation {
            duration: Motion.ms(90)
        }
        PropertyAction {
            target: root
            property: "glint"
            value: 1
        }
        PauseAnimation {
            duration: Motion.ms(90)
        }
        PropertyAction {
            target: root
            property: "glint"
            value: 0
        }
    }
}
