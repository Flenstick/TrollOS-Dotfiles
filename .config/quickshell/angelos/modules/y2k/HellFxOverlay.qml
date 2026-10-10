pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Hell's own screen effects (services/HellFx), one click-through overlay per effect
// while it plays — never takes input, never stays mapped:
//   the salute at the end of a song (BarLyrics in hell): embers, sparks, pixel skulls,
//   pentagrams and horned hearts burst from where the lyrics were and fall with
//   gravity, fading out in ~2 s; a top bar throws them downwards.
//   Cerberus (the Wheel of Hell): a big puppy runs across the bottom of the screen,
//   hopping, embers falling off his tail, three barks (Sounds "bark").
// Stepped like everything pixel: 24 fps, positions on the art-pixel grid.
Scope {
    id: root

    // ---- the salute ----
    property string fwScreen: ""
    property real fwX: 0
    property real fwY: 0
    property bool fwTop: false
    property real fwT: 0                     // seconds since the burst
    property int fwSerial: 0
    readonly property real fwLength: 2.6
    property var sparks: []                  // [{x, y, vx, vy, kind, life, born, size, spin}]

    // ---- Cerberus runs across ----
    property string cbScreen: ""
    property real cbT: 0
    property bool cbRight: true              // left to right
    readonly property real cbLength: 3.8
    function run(screen) {
        cbScreen = screen;
        cbT = 0;
        cbRight = Math.random() < 0.5;
        Sounds.play("bark");
        cbClock.restart();
    }
    Timer {
        id: cbClock
        interval: 42
        repeat: true
        onTriggered: {
            root.cbT += interval / 1000;
            if (root.cbT >= root.cbLength) {
                stop();
                root.cbScreen = "";
            }
        }
    }

    function allowed(screen) {
        return Angel.demon && !Shell.dev && StreamMode.effectsOn(screen) && !!Shell.screenByName(screen);
    }

    Connections {
        target: HellFx
        function onFireworks(screen, x, y, fromTop) {
            if (root.allowed(screen) && !Motion.still)
                root.salute(screen, x, y, fromTop);
        }
        function onCerberus(screen) {
            if (root.allowed(screen) && !Shell.fullscreenOn(screen) && !Motion.still)
                root.run(screen);
        }
    }

    function salute(screen, x, y, fromTop) {
        fwScreen = screen;
        fwX = x;
        fwY = y;
        fwTop = fromTop;
        fwT = 0;
        fwSerial++;
        let s = fwSerial * 7919 + 13;
        const rnd = () => {
            s = (s * 16807) % 2147483647;
            return (s - 1) / 2147483646;
        };
        const kinds = ["ember", "ember", "ember", "spark", "spark", "spark", "skull", "pentagram", "heartHorns", "ember", "spark", "heartHorns"];
        const out = [];
        // the main burst, then two smaller pops a moment later beside it
        const pops = [[0, 0, 0, 44], [0.22, -0.8, -0.35, 16], [0.38, 0.9, -0.25, 16]];
        for (const [at, ox, oy, n] of pops) {
            const cx = x + ox * Theme.u * 60, cy = y + oy * Theme.u * 50 * (fromTop ? -1 : 1);
            for (let i = 0; i < n; i++) {
                const k = kinds[Math.floor(rnd() * kinds.length)];
                // upwards in a wide cone (downwards from a top bar), a bit of everything sideways
                const a = (fromTop ? Math.PI / 2 : -Math.PI / 2) + (rnd() - 0.5) * (at > 0 ? Math.PI * 1.6 : Math.PI * 1.25);
                const v = Theme.u * (at > 0 ? 90 + rnd() * 140 : 140 + rnd() * 230);
                out.push({
                    "x": cx,
                    "y": cy,
                    "vx": Math.cos(a) * v,
                    "vy": Math.sin(a) * v,
                    "kind": k,
                    "born": at,
                    "life": 1.4 + rnd() * 1.0,
                    "size": k === "ember" ? (rnd() < 0.3 ? 2 : 1) : 1,
                    "spin": rnd() < 0.5 ? 90 : -90,
                    "hue": rnd()
                });
            }
        }
        sparks = out;
        fwClock.restart();
    }
    Timer {
        id: fwClock
        interval: 42
        repeat: true
        onTriggered: {
            root.fwT += interval / 1000;
            if (root.fwT >= root.fwLength) {
                stop();
                root.sparks = [];
                root.fwScreen = "";
            }
        }
    }

    LazyLoader {
        active: root.fwScreen !== "" && root.sparks.length > 0

        PanelWindow {
            id: fwWin
            screen: Shell.screenByName(root.fwScreen)
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "angelos-hellfx"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            readonly property int px: Math.max(2, Theme.u)
            readonly property real gravity: Theme.u * 260

            RightClickGuard {}

            Repeater {
                model: root.sparks.length
                Item {
                    id: bit
                    required property int index
                    readonly property var sp: root.sparks[index] || ({})
                    readonly property real age: root.fwT - (sp.born || 0)
                    readonly property real k: Math.max(0, Math.min(1, age / (sp.life || 1)))
                    readonly property real px: fwWin.px
                    // ballistic, with a little air drag on the sideways speed
                    readonly property real dx: (sp.vx || 0) * age * (1 - Math.min(0.5, age * 0.25))
                    readonly property real dy: (sp.vy || 0) * age + fwWin.gravity * age * age / 2
                    x: Math.round(((sp.x || 0) + dx) / px) * px - width / 2
                    y: Math.round(((sp.y || 0) + dy) / px) * px - height / 2
                    visible: age >= 0 && k < 1
                    // the last third fades in steps
                    opacity: k < 0.66 ? 1 : Math.round((1 - k) / 0.34 * 4) / 4
                    width: icon.visible ? icon.width : dot.width
                    height: icon.visible ? icon.height : dot.height
                    rotation: icon.visible ? Math.round(age * 4) * (sp.spin || 90) % 360 : 0

                    Rectangle {
                        id: dot
                        visible: bit.sp.kind === "ember" || bit.sp.kind === "spark"
                        width: bit.px * (bit.sp.size || 1) * (bit.sp.kind === "spark" ? 1 : 2)
                        height: width
                        // embers cool from yellow through orange to blood; sparks stay hot
                        color: bit.sp.kind === "spark" ? (bit.k < 0.5 ? "#fff3c4" : "#ffd35a") : bit.k < 0.3 ? "#ffd35a" : bit.k < 0.65 ? Theme.hellEmber : Theme.hellBlood
                    }
                    PxIcon {
                        id: icon
                        visible: !dot.visible
                        name: bit.sp.kind === "skull" ? "skull" : bit.sp.kind === "pentagram" ? "pentagram" : "heartHorns"
                        pixel: bit.px
                        ink: Theme.hellEdge
                        light: Theme.hellText
                        body: Theme.hellFace
                        fill: bit.sp.kind === "pentagram" ? Theme.hellEmber : Theme.hellBlood
                        fill3: Theme.hellFlame
                        bad: bit.sp.kind === "skull" ? Theme.hellEmber : Theme.hellFlame
                    }
                }
            }
        }
    }

    LazyLoader {
        active: root.cbScreen !== ""

        PanelWindow {
            id: cbWin
            screen: Shell.screenByName(root.cbScreen)
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "angelos-hellfx"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            readonly property int px: Math.max(2, Theme.u * 3)
            readonly property real k: root.cbT / root.cbLength
            // across the whole width and out of sight on both ends
            readonly property real runX: -dog.width + (width + dog.width * 2) * k
            readonly property real dogX: root.cbRight ? runX : width - runX - dog.width
            readonly property real floor: height - Theme.u * 26

            RightClickGuard {}

            // embers dropping off the tail: where he was a moment ago, cooling down
            Repeater {
                model: 10
                Rectangle {
                    required property int index
                    readonly property real back: (index + 1) * 0.07
                    readonly property real at: Math.max(0, cbWin.k - back / root.cbLength)
                    readonly property real tx: root.cbRight ? -dog.width + (cbWin.width + dog.width * 2) * at : cbWin.width - (-dog.width + (cbWin.width + dog.width * 2) * at) - dog.width
                    width: cbWin.px
                    height: cbWin.px
                    x: Math.round((tx + (root.cbRight ? cbWin.px * 2 : dog.width - cbWin.px * 3)) / cbWin.px) * cbWin.px
                    y: Math.round((cbWin.floor - dog.height * 0.55 + index * index * cbWin.px * 0.35) / cbWin.px) * cbWin.px
                    color: index < 3 ? Theme.hellFlame : index < 6 ? Theme.hellEmber : Theme.hellBlood
                    opacity: Math.round((1 - index / 10) * 4) / 4
                    visible: cbWin.k > back / root.cbLength
                }
            }
            CerberusSprite {
                id: dog
                alert: true
                pixel: cbWin.px
                frame: Math.floor(root.cbT * 14) % 5
                x: Math.round(cbWin.dogX / cbWin.px) * cbWin.px
                // little hops, on the pixel grid
                y: Math.round((cbWin.floor - height - Math.abs(Math.sin(root.cbT * 11)) * Theme.u * 5) / cbWin.px) * cbWin.px
                transform: Scale {
                    origin.x: dog.width / 2
                    xScale: root.cbRight ? 1 : -1
                }
            }
        }
    }
}
