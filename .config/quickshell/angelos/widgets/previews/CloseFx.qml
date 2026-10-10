import QtQuick
import qs.config
import qs.widgets

// Close animations (services/WindowAnim close ids): default | pixel | heart | crt |
// glitch | fall | minimize | off. The × is clicked, then the window goes.
Scene {
    id: root

    readonly property real k: seg(0.3, 0.72)          // animation progress
    readonly property bool closing: t >= 0.3
    readonly property rect r: Qt.rect(width * 0.26, height * 0.1, width * 0.44, height * 0.55)
    function rnd(i) {
        const x = Math.sin(i * 12.9898 + 78.233) * 43758.5453;
        return x - Math.floor(x);
    }

    MiniBar {
        id: bar
        y: root.height - height
        width: root.width
        height: Math.round(root.height * 0.17)
        count: 2
        hot: !root.closing ? 0 : -1
        hidden: root.k >= 1 ? 0 : -1
    }

    // ---- the window, drawn per style ----
    Item {
        id: holder
        x: root.r.x
        y: root.r.y
        width: root.r.width
        height: root.r.height
        opacity: {
            if (!root.closing)
                return 1;
            switch (root.variant) {
            case "off":
                return 0;
            case "pixel":
                return 1;
            case "crt":
                return root.k < 0.9 ? 1 : 1 - (root.k - 0.9) * 10;
            case "minimize":
                return 1 - root.k * 0.6;
            default:
                return 1 - root.k;
            }
        }
        visible: opacity > 0 && (root.variant !== "glitch" || !root.closing) && root.k < 1
        transformOrigin: Item.Center
        rotation: root.variant === "fall" ? root.k * 28 : 0
        transform: [
            Scale {
                origin.x: holder.width / 2
                origin.y: holder.height / 2
                xScale: {
                    if (!root.closing)
                        return 1;
                    if (root.variant === "crt")
                        return root.k < 0.55 ? 1 : Math.max(0.02, 1 - (root.k - 0.55) / 0.35);
                    if (root.variant === "default")
                        return 1 - 0.15 * root.k;
                    if (root.variant === "heart")
                        return 1 - root.k;
                    if (root.variant === "minimize")
                        return 1 - 0.85 * root.ease(root.k);
                    return 1;
                }
                yScale: {
                    if (!root.closing)
                        return 1;
                    if (root.variant === "crt")
                        return Math.max(0.03, 1 - root.k / 0.55);
                    if (root.variant === "default")
                        return 1 - 0.15 * root.k;
                    if (root.variant === "heart")
                        return 1 - root.k;
                    if (root.variant === "minimize")
                        return 1 - 0.85 * root.ease(root.k);
                    return 1;
                }
            },
            Translate {
                x: root.variant === "minimize" && root.closing ? (bar.buttonPoint(0).x - root.r.x - root.r.width / 2) * root.ease(root.k) : 0
                y: {
                    if (!root.closing)
                        return 0;
                    if (root.variant === "fall")
                        return root.k * root.k * root.height * 1.1;
                    if (root.variant === "minimize")
                        return (bar.buttonPoint(0).y - root.r.y - root.r.height / 2) * root.ease(root.k);
                    return 0;
                }
            }
        ]

        MiniWindow {
            anchors.fill: parent
            closeHot: root.t > 0.2 && root.t < 0.32
        }
        // old TV: the picture burns white while it folds
        Rectangle {
            anchors.fill: parent
            color: "#ffffff"
            opacity: root.variant === "crt" && root.closing ? Math.min(1, root.k * 1.6) : 0
        }
        // pixels: holes open in random order
        Grid {
            anchors.fill: parent
            columns: 10
            visible: root.variant === "pixel" && root.closing
            Repeater {
                model: 70
                Rectangle {
                    required property int index
                    width: holder.width / 10
                    height: holder.height / 7
                    color: Theme.desk
                    opacity: root.k > root.rnd(index) * 0.85 ? 1 : 0
                }
            }
        }
    }

    // glitch: slices jump sideways, then blink out
    Repeater {
        model: 6
        Item {
            required property int index
            readonly property int frame: Math.floor(root.t * 40)
            visible: root.variant === "glitch" && root.closing && root.k < 0.95 && (root.k < 0.6 || root.rnd(index + frame) > root.k)
            x: root.r.x + (root.rnd(index * 7 + frame) - 0.5) * root.r.width * 0.35 * Math.sin(root.k * Math.PI)
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
                opacity: 0.35 * root.rnd(parent.index + parent.frame * 3)
            }
        }
    }

    // heart: the window shrinks into a heart that pops into sparkles
    PxIcon {
        visible: root.variant === "heart" && root.closing && root.k < 0.85
        name: "heart"
        pixel: Math.max(1, Math.round(Theme.u * (0.5 + root.k * 2.5)))
        x: root.r.x + root.r.width / 2 - width / 2
        y: root.r.y + root.r.height / 2 - height / 2
    }
    Repeater {
        model: 8
        PxIcon {
            required property int index
            readonly property real a: index / 8 * Math.PI * 2
            readonly property real d: root.seg(0.6, 0.85) * root.r.width * 0.6
            visible: root.variant === "heart" && root.k > 0.6 && root.k < 1
            name: "sparkle"
            pixel: 1
            x: root.r.x + root.r.width / 2 + Math.cos(a) * d
            y: root.r.y + root.r.height / 2 + Math.sin(a) * d
            opacity: 1 - root.seg(0.75, 0.9)
        }
    }

    MiniCursor {
        readonly property point closeAt: Qt.point(root.r.x + root.r.width - root.r.height * 0.13, root.r.y + root.r.height * 0.1)
        readonly property point p: root.mixp(Qt.point(root.width * 0.86, root.height * 0.55), closeAt, root.ease(root.seg(0.02, 0.2)))
        x: p.x
        y: p.y
        click: root.t > 0.2 && root.t < 0.3 ? "left" : ""
    }
}
