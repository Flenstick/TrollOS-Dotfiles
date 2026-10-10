import QtQuick
import qs.config
import qs.widgets

// Bar styles: taskbar (Win98, bottom) | top (thin strip) | island (floating) | dock
// (a floating shelf at the bottom, the icon under the pointer grown) | capsules (three pills
// at the top) | windose (pastel, pill buttons). The bar slides in; a window sits in the
// space it leaves.
Scene {
    id: root

    readonly property real k: ease(seg(0.1, 0.35))
    readonly property real barH: Math.round(height * 0.15)

    MiniWindow {
        x: root.width * 0.12
        y: root.variant === "top" ? root.barH * 0.7 + Theme.u * 3 : root.variant === "island" || root.variant === "capsules" ? root.barH + Theme.u * 5 : Theme.u * 4
        width: root.width * 0.76
        height: root.height - y - (root.variant === "taskbar" || root.variant === "windose" ? root.barH : root.variant === "dock" ? root.barH + Theme.u * 4 : 0) - Theme.u * 4
    }

    MiniBar {
        visible: root.variant === "taskbar"
        width: root.width
        height: root.barH
        y: root.height - height * root.k
        count: 3
        hot: 0
    }
    // thin strip across the top: workspaces left, clock right
    Rectangle {
        visible: root.variant === "top"
        width: root.width
        height: root.barH * 0.7
        y: -height * (1 - root.k)
        color: Theme.face
        Row {
            x: Theme.u * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 2
            Repeater {
                model: 4
                PxIcon {
                    required property int index
                    name: "heart"
                    pixel: 1
                    opacity: index === 0 ? 1 : 0.4
                }
            }
        }
        PxText {
            x: parent.width - width - Theme.u * 3
            anchors.verticalCenter: parent.verticalCenter
            text: "12:00"
            kind: "tiny"
        }
    }
    // floating island in the middle of the top edge
    Rectangle {
        visible: root.variant === "island"
        width: root.width * 0.46
        height: root.barH * 0.8
        x: (root.width - width) / 2
        y: Theme.u * 2 - (height + Theme.u * 2) * (1 - root.k)
        color: Theme.face
        border.width: Math.max(1, Theme.u / 2)
        border.color: Theme.edge
        Row {
            anchors.centerIn: parent
            spacing: Theme.u * 3
            Repeater {
                model: 3
                PxIcon {
                    required property int index
                    name: ["heart", "music", "wifi"][index]
                    pixel: 1
                }
            }
            PxText {
                text: "12:00"
                kind: "tiny"
            }
        }
    }
    // the dock: a shelf at the bottom centre, the middle icon grown under the pointer
    Rectangle {
        visible: root.variant === "dock"
        width: root.width * 0.5
        height: root.barH
        x: (root.width - width) / 2
        y: root.height - Theme.u * 2 - height * root.k
        color: Theme.face
        border.width: Math.max(1, Theme.u / 2)
        border.color: Theme.edge
        Rectangle {
            width: parent.width
            height: Theme.u * 2
            y: parent.height - height
            color: Theme.faceAlt
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.u * 2
            spacing: Theme.u * 2
            Repeater {
                model: 5
                PxIcon {
                    required property int index
                    anchors.bottom: parent.bottom
                    name: ["heart", "folder", "terminal", "music", "gear"][index]
                    pixel: index === 2 ? 2 : 1
                }
            }
        }
    }
    // capsules: three pills along the top
    Repeater {
        model: root.variant === "capsules" ? [[0.03, 0.22], [0.37, 0.26], [0.77, 0.2]] : []
        Rectangle {
            required property var modelData
            x: root.width * modelData[0]
            width: root.width * modelData[1]
            height: root.barH * 0.75
            y: Theme.u * 2 - (height + Theme.u * 2) * (1 - root.k)
            radius: height / 2
            antialiasing: false
            color: Theme.face
            border.width: Math.max(1, Theme.u / 2)
            border.color: Theme.edge
            Row {
                anchors.centerIn: parent
                spacing: Theme.u * 2
                Repeater {
                    model: 2
                    PxIcon {
                        required property int index
                        name: ["heart", "music"][index]
                        pixel: 1
                    }
                }
            }
        }
    }
    // Windose: pastel paper, a rose stripe, pill buttons
    Rectangle {
        visible: root.variant === "windose"
        width: root.width
        height: root.barH
        y: root.height - height * root.k
        color: Theme.windosePaper
        Rectangle {
            width: parent.width
            height: Math.max(1, Theme.u / 2) * 2
            color: Theme.windoseRose
        }
        Row {
            x: Theme.u * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 2
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    width: index === 0 ? root.width * 0.16 : root.width * 0.12
                    height: root.barH * 0.62
                    radius: height / 2
                    antialiasing: false
                    color: index === 0 ? Theme.windoseRose : Theme.windoseSticker
                    border.width: Math.max(1, Theme.u / 2)
                    border.color: Theme.windoseLine
                }
            }
        }
        PxText {
            x: parent.width - width - Theme.u * 3
            anchors.verticalCenter: parent.verticalCenter
            text: "♡ 12:00"
            kind: "tiny"
        }
    }
}
