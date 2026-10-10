pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets

// Region screenshot skins (Settings → Screenshots): ropes | window | stream.
// The selection is dragged open over a little desktop, holds, and the shot
// flashes. The real skins are drawn by scripts/capture_skins.py; this is the gif.
Scene {
    id: root

    readonly property real k: ease(seg(0.08, 0.5))
    readonly property point a: Qt.point(width * 0.22, height * 0.24)
    readonly property point b: Qt.point(width * (0.22 + 0.5 * k), height * (0.24 + 0.52 * k))
    readonly property real flash: t > 0.8 ? Math.max(0, 1 - (t - 0.8) / 0.12) : 0
    readonly property int s: Math.max(1, Math.round(Theme.u / 2))
    readonly property int march: Math.floor(t * 40)

    MiniWindow {
        x: root.width * 0.1
        y: root.height * 0.12
        width: root.width * 0.5
        height: root.height * 0.6
        active: false
    }
    MiniWindow {
        x: root.width * 0.45
        y: root.height * 0.35
        width: root.width * 0.45
        height: root.height * 0.5
    }
    // everything outside the selection is dimmed
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha("#000000", 0.3)
    }

    Item {
        id: sel
        x: root.a.x
        y: root.a.y
        width: Math.max(1, root.b.x - root.a.x)
        height: Math.max(1, root.b.y - root.a.y)

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha("#ffffff", 0.08)
        }

        // ---- ropes: tied to the top edge of the screen, swinging a little ----
        Repeater {
            model: root.variant === "ropes" || root.variant === "" ? 2 : 0
            Rectangle {
                required property int index
                readonly property real sway: Math.sin(root.t * 12 + index) * root.s * 3
                x: (index ? sel.width : 0) - root.s + sway
                y: -sel.y
                width: root.s * 2
                height: sel.y
                color: "#b88a4a"
            }
        }
        Rectangle {
            visible: root.variant === "ropes" || root.variant === ""
            anchors.fill: parent
            color: "transparent"
            border.width: root.s * 2
            border.color: "#b88a4a"
        }

        // ---- screenshot.exe: a window with a pink title bar and marching ants ----
        Rectangle {
            visible: root.variant === "window"
            anchors.fill: parent
            color: "transparent"
            border.width: root.s
            border.color: Theme.edge
            Rectangle {
                width: parent.width
                height: Math.max(Theme.u * 5, root.s * 8)
                y: -height
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: "#ff4fa3"
                    }
                    GradientStop {
                        position: 1
                        color: "#7b4dff"
                    }
                }
                PxText {
                    x: Theme.u * 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.exe("screenshot")
                    kind: "tiny"
                    color: "#ffffff"
                    visible: sel.width > implicitWidth + Theme.u * 4
                }
            }
            // marching ants along the top and bottom edges
            Repeater {
                model: Math.floor(sel.width / (root.s * 6))
                Rectangle {
                    required property int index
                    x: ((index * 6 + root.march) % Math.max(1, Math.floor(sel.width / root.s))) * root.s
                    y: sel.height - root.s
                    width: root.s * 3
                    height: root.s
                    color: "#ffffff"
                }
            }
            PxIcon {
                x: -width / 2
                y: sel.height - height / 2
                name: "heartSmall"
                pixel: root.s
            }
            PxIcon {
                x: sel.width - width / 2
                y: sel.height - height / 2
                name: "heartSmall"
                pixel: root.s
            }
        }

        // ---- Ame's stream: a chain of marching hearts and a LIVE badge ----
        Repeater {
            model: root.variant === "stream" ? Math.max(0, Math.floor((sel.width + sel.height) * 2 / (Theme.u * 6))) : 0
            PxIcon {
                required property int index
                readonly property real per: (sel.width + sel.height) * 2
                readonly property real d: ((index * Theme.u * 6 + root.march * root.s * 2) % Math.max(1, per))
                x: (d < sel.width ? d : d < sel.width + sel.height ? sel.width : d < sel.width * 2 + sel.height ? sel.width * 2 + sel.height - d : 0) - width / 2
                y: (d < sel.width ? 0 : d < sel.width + sel.height ? d - sel.width : d < sel.width * 2 + sel.height ? sel.height : per - d) - height / 2
                name: "heartSmall"
                pixel: root.s
            }
        }
        Rectangle {
            visible: root.variant === "stream"
            x: Theme.u * 2
            y: Theme.u * 2
            width: liveText.implicitWidth + Theme.u * 3
            height: liveText.implicitHeight + Theme.u
            color: "#ff2e7e"
            PxText {
                id: liveText
                anchors.centerIn: parent
                text: "LIVE"
                kind: "tiny"
                color: "#ffffff"
            }
        }

        // the size badge
        Rectangle {
            visible: sel.width > Theme.u * 20
            x: sel.width - width
            y: sel.height + Theme.u
            width: sizeText.implicitWidth + Theme.u * 3
            height: sizeText.implicitHeight + Theme.u
            color: root.variant === "stream" ? "#ffd1e8" : Theme.face
            radius: root.variant === "stream" ? Theme.u * 2 : 0
            PxText {
                id: sizeText
                anchors.centerIn: parent
                text: (root.variant === "stream" ? "kawaii " : "") + Math.round(sel.width * 4) + "×" + Math.round(sel.height * 4)
                kind: "tiny"
                color: Theme.edge
            }
        }
    }

    // the shot
    Rectangle {
        anchors.fill: parent
        color: "#ffffff"
        opacity: root.flash * 0.8
    }
}
