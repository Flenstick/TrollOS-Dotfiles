import QtQuick
import qs.config
import qs.widgets

// Open animations (services/WindowAnim open ids): default | pop | pixel | heart |
// star | cd | crt | glitch | drop | rise | off. Start is clicked, the window
// comes in, then stays a moment.
Scene {
    id: root

    readonly property real k: seg(0.22, 0.62)          // animation progress
    readonly property bool opening: t >= 0.22
    readonly property bool shown: k >= 1
    readonly property rect r: Qt.rect(width * 0.26, height * 0.1, width * 0.44, height * 0.55)
    readonly property point start: Qt.point(bar.x + bar.height * 0.6, bar.y + bar.height / 2)
    function rnd(i) {
        const x = Math.sin(i * 12.9898 + 78.233) * 43758.5453;
        return x - Math.floor(x);
    }
    function outCubic(x) {
        return 1 - Math.pow(1 - x, 3);
    }
    function spring(x) {
        return 1 - Math.pow(2, -9 * x) * Math.cos(x * 10.5);
    }
    function bounce(x) {
        const n = 7.5625, d = 2.75;
        if (x < 1 / d)
            return n * x * x;
        if (x < 2 / d)
            return n * (x -= 1.5 / d) * x + 0.75;
        if (x < 2.5 / d)
            return n * (x -= 2.25 / d) * x + 0.9375;
        return n * (x -= 2.625 / d) * x + 0.984375;
    }

    MiniBar {
        id: bar
        y: root.height - height
        width: root.width
        height: Math.round(root.height * 0.17)
        count: root.opening ? 2 : 1
        hot: root.opening ? 1 : -1
    }

    // ---- the window, drawn per style ----
    Item {
        id: holder
        x: root.r.x
        y: root.r.y
        width: root.r.width
        height: root.r.height
        visible: root.opening && root.variant !== "glitch" || root.shown
        opacity: {
            if (!root.opening)
                return 0;
            switch (root.variant) {
            case "off":
                return 1;
            case "pixel":
            case "heart":
            case "star":
            case "cd":
                return 1;
            case "crt":
                return root.k < 0.05 ? 0 : 1;
            case "rise":
                return Math.min(1, root.k / 0.3);
            default:
                return Math.min(1, root.k / 0.2);
            }
        }
        rotation: root.variant === "drop" ? (1 - root.bounce(root.k)) * 6 : root.variant === "cd" ? (1 - root.outCubic(root.k)) * -140 : 0
        transform: [
            Scale {
                origin.x: holder.width / 2
                origin.y: holder.height / 2
                xScale: {
                    const k = root.k;
                    switch (root.variant) {
                    case "default":
                        return 0.85 + 0.15 * root.outCubic(k);
                    case "pop":
                        return 0.45 + 0.55 * root.spring(k);
                    case "crt":
                        return Math.max(0.02, Math.min(1, k / 0.3));
                    case "rise":
                        return 0.15 + 0.85 * root.outCubic(k);
                    case "cd":
                        return Math.max(0.02, root.outCubic(k));
                    default:
                        return 1;
                    }
                }
                yScale: {
                    const k = root.k;
                    switch (root.variant) {
                    case "default":
                        return 0.85 + 0.15 * root.outCubic(k);
                    case "pop":
                        return 0.45 + 0.55 * root.spring(k);
                    case "crt":
                        return Math.max(0.03, root.outCubic(Math.max(0, Math.min(1, (k - 0.3) / 0.4))));
                    case "rise":
                        return 0.15 + 0.85 * root.outCubic(k);
                    case "cd":
                        return Math.max(0.02, root.outCubic(k));
                    default:
                        return 1;
                    }
                }
            },
            Translate {
                x: root.variant === "rise" ? (root.start.x - root.r.x - root.r.width / 2) * (1 - root.outCubic(root.k)) : 0
                y: {
                    if (root.variant === "drop")
                        return -(1 - root.bounce(root.k)) * root.height * 0.6;
                    if (root.variant === "rise")
                        return (root.start.y - root.r.y - root.r.height / 2) * (1 - root.outCubic(root.k));
                    return 0;
                }
            }
        ]

        MiniWindow {
            anchors.fill: parent
        }
        // old TV: the tube glows white, the picture comes through
        Rectangle {
            anchors.fill: parent
            color: "#ffffff"
            opacity: root.variant === "crt" ? 1 - Math.max(0, Math.min(1, (root.k - 0.35) / 0.5)) : 0
        }
        // bubble: a pink-to-cyan rim that fades
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: Math.max(2, Theme.u)
            border.color: Theme.mix(Theme.accent, Theme.accent2, 0.5)
            opacity: root.variant === "pop" ? 1 - Math.max(0, Math.min(1, (root.k - 0.35) / 0.55)) : 0
        }
        // pixels: blocks arrive in random order, flashing pink
        Grid {
            anchors.fill: parent
            columns: 10
            visible: root.variant === "pixel" && !root.shown
            Repeater {
                model: 70
                Rectangle {
                    required property int index
                    readonly property real at: root.rnd(index) * 0.6 + Math.floor(index / 10) / 7 * 0.2
                    width: holder.width / 10
                    height: holder.height / 7
                    color: root.k < at ? Theme.desk : Theme.accent
                    opacity: root.k < at ? 1 : Math.max(0, 1 - (root.k - at) / 0.12) * 0.8
                }
            }
        }
        // heart / star / CD: the window shows through a growing shape — drawn as
        // the shape's sprite growing over it, the window covered outside
        Rectangle {
            anchors.fill: parent
            color: Theme.desk
            visible: (root.variant === "heart" || root.variant === "star") && !root.shown
            opacity: 1 - root.seg(0.5, 0.6)
        }
    }

    PxIcon {
        visible: (root.variant === "heart" || root.variant === "star") && root.opening && !root.shown
        name: root.variant === "star" ? "sparkleStar" : "heart"
        pixel: Math.max(1, Math.round(Theme.u * (0.4 + root.outCubic(root.k) * 3.2)))
        x: root.r.x + root.r.width / 2 - width / 2
        y: root.r.y + root.r.height / 2 - height / 2
        opacity: 1 - root.seg(0.55, 0.62)
    }
    // CD: a rainbow sheen spinning over the disc
    PxIcon {
        visible: root.variant === "cd" && root.opening && root.k < 0.95
        name: "cd"
        pixel: Math.max(1, Math.round(Theme.u * 2))
        x: root.r.x + root.r.width / 2 - width / 2
        y: root.r.y + root.r.height / 2 - height / 2
        rotation: Math.floor(root.k * 12) * 90
        opacity: 0.8 * (1 - root.k)
    }

    // glitch: slices come in from the sides and settle
    Repeater {
        model: 6
        Item {
            required property int index
            readonly property int frame: Math.floor(root.t * 40)
            visible: root.variant === "glitch" && root.opening && !root.shown && (root.k > 0.4 || root.rnd(index + frame) < root.k + 0.2)
            x: root.r.x + (root.rnd(index * 7 + frame) - 0.5) * root.r.width * 0.35 * (1 - root.k)
            y: root.r.y + index * root.r.height / 6
            width: root.r.width
            height: Math.ceil(root.r.height / 6)
            clip: true
            MiniWindow {
                y: -parent.index * root.r.height / 6
                width: root.r.width
                height: root.r.height
            }
            Rectangle {
                anchors.fill: parent
                color: [Theme.accent, Theme.accent2, Theme.accent3][parent.index % 3]
                opacity: 0.35 * root.rnd(parent.index + parent.frame * 3) * (1 - root.k)
            }
        }
    }

    MiniCursor {
        readonly property point p: root.mixp(Qt.point(root.width * 0.5, root.height * 0.5), root.start, root.ease(root.seg(0.02, 0.18)))
        x: p.x
        y: p.y
        click: root.t > 0.17 && root.t < 0.24 ? "left" : ""
    }
}
