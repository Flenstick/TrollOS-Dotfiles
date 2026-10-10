pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services
import qs.widgets

// Alt+Tab, NEEDY GIRL OVERDOSE style: a Windose window — a pink-to-lilac title
// bar with the three little buttons, a checkered pastel desk, windows as
// desktop icons, the pick in a dotted frame with a heart bouncing over it, and
// a line from Ame at the bottom. Fixed Windose colours, not the theme's.
Item {
    id: root

    required property var host
    readonly property color ink: "#3b1d4a"
    readonly property color cream: "#fff4fb"
    readonly property color pink: "#ff8fc8"
    readonly property color hot: "#ff4fa3"
    readonly property color lilac: "#b99cff"
    readonly property color sky: "#8fd3ff"
    readonly property int s: Theme.u                // one art pixel
    readonly property int cell: s * 44
    readonly property int perRow: Math.max(1, Math.min(AltTab.items.length, Math.floor(((host.screen ? host.screen.width : 1920) * 0.78) / (cell + s * 4))))
    // Ame has something to say every time it opens
    readonly property var lines: [[I18n.t("Какое окошко, P-chan? ♡", "Which one, P-chan? ♡"), "どれにする？"], [I18n.t("Выбирай быстрее, я жду~", "Pick faster, I'm waiting~"), "はやくはやく〜"], [I18n.t("Ame смотрит ✧", "Ame is watching ✧"), "みてるよ"], [I18n.t("Только не закрывай меня!", "Just don't close me!"), "しんどい…"], [I18n.t("Интернет-ангел одобряет ✧", "Internet Angel approves ✧"), "超てんちゃん"]]
    readonly property var line: lines[AltTab.serial % lines.length]
    implicitWidth: body.width + s * 4
    implicitHeight: titleBar.height + body.height + status.height + s * 6

    // hard pixel shadow, then the frame
    Rectangle {
        x: root.s * 3
        y: root.s * 3
        width: parent.width - root.s * 3
        height: parent.height - root.s * 3
        color: Qt.alpha(root.ink, 0.4)
    }
    Rectangle {
        id: frame
        width: parent.width - root.s * 3
        height: parent.height - root.s * 3
        color: root.cream
        border.width: root.s
        border.color: root.ink
    }

    // ---- title bar ----
    Rectangle {
        id: titleBar
        x: root.s
        y: root.s
        width: frame.width - root.s * 2
        height: root.s * 13
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: root.pink
            }
            GradientStop {
                position: 1
                color: root.lilac
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: root.s
            color: root.ink
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: root.s * 4
            spacing: root.s * 3
            PxIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "heart"
                fill: root.hot
                ink: root.ink
                light: "#ffffff"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Windose ▸ " + I18n.exe("alt+tab")
                font.family: Theme.fontTitle
                font.pixelSize: Theme.sizeBody
                font.bold: true
                color: "#ffffff"
                style: Text.Outline
                styleColor: root.ink
            }
        }
        // _ □ × like every Windose window
        Row {
            anchors.right: parent.right
            anchors.rightMargin: root.s * 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.s * 2
            Repeater {
                model: ["minimize", "maximize", "close"]
                Rectangle {
                    required property string modelData
                    width: root.s * 9
                    height: root.s * 8
                    color: root.cream
                    border.width: root.s
                    border.color: root.ink
                    PxIcon {
                        anchors.centerIn: parent
                        name: parent.modelData
                        pixel: Math.max(1, root.s / 2)
                        ink: root.ink
                    }
                }
            }
        }
    }

    // ---- the checkered desk with the windows as icons ----
    Item {
        id: body
        x: root.s * 2
        y: titleBar.y + titleBar.height
        width: Math.max(grid.width, bubble.width) + root.s * 16
        height: grid.height + bubble.height + root.s * 22
        clip: true
        Image {
            anchors.fill: parent
            fillMode: Image.Tile
            smooth: false
            source: "data:image/svg+xml;utf8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="' + root.s * 16 + '" height="' + root.s * 16 + '"><rect width="100%" height="100%" fill="#fff4fb"/><rect width="' + root.s * 8 + '" height="' + root.s * 8 + '" fill="#ffe3f1"/><rect x="' + root.s * 8 + '" y="' + root.s * 8 + '" width="' + root.s * 8 + '" height="' + root.s * 8 + '" fill="#ffe3f1"/></svg>')
        }
        Grid {
            id: grid
            x: root.s * 8
            y: root.s * 12
            columns: root.perRow
            columnSpacing: root.s * 4
            rowSpacing: root.s * 10
            Repeater {
                model: AltTab.items
                Item {
                    id: icon
                    required property var modelData
                    required property int index
                    readonly property bool picked: index === AltTab.index
                    width: root.cell
                    height: root.cell + (Config.alttab.titles ? root.s * 4 : 0)
                    // a dotted focus frame, Windows 98 style
                    Shape {
                        anchors.fill: parent
                        visible: icon.picked
                        ShapePath {
                            strokeColor: root.hot
                            strokeWidth: root.s
                            strokeStyle: ShapePath.DashLine
                            dashPattern: [2, 2]
                            fillColor: Qt.alpha(root.pink, 0.22)
                            startX: 0
                            startY: 0
                            PathLine {
                                x: icon.width
                                y: 0
                            }
                            PathLine {
                                x: icon.width
                                y: icon.height
                            }
                            PathLine {
                                x: 0
                                y: icon.height
                            }
                            PathLine {
                                x: 0
                                y: 0
                            }
                        }
                    }
                    // the icon on a little white tile
                    Rectangle {
                        id: tile
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.s * 5
                        width: root.s * 26
                        height: width
                        radius: root.s * 3
                        color: "#ffffff"
                        border.width: root.s
                        border.color: icon.picked ? root.hot : root.ink
                        AppIcon {
                            anchors.centerIn: parent
                            appId: icon.modelData.app_id || ""
                            size: root.s * 20
                        }
                    }
                    Rectangle {
                        visible: Config.alttab.titles
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: tile.bottom
                        anchors.topMargin: root.s * 3
                        width: Math.min(parent.width - root.s * 2, label.implicitWidth + root.s * 4)
                        height: label.implicitHeight + root.s * 2
                        color: icon.picked ? root.hot : "#ffffff"
                        border.width: icon.picked ? 0 : root.s / 2
                        border.color: root.ink
                        Text {
                            id: label
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, root.cell - root.s * 6)
                            elide: Text.ElideRight
                            text: root.host.appName(icon.modelData)
                            font.family: Theme.fontBody
                            font.pixelSize: Theme.sizeBody
                            color: icon.picked ? "#ffffff" : root.ink
                        }
                    }
                    // a heart bouncing over the pick
                    PxIcon {
                        id: bouncer
                        visible: icon.picked
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "heart"
                        pixel: root.s
                        fill: root.hot
                        ink: root.ink
                        property real hop: 0
                        y: -height + root.s - hop
                        SequentialAnimation on hop {
                            running: icon.picked && !Motion.still
                            alwaysRunToEnd: true
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 0
                                to: root.s * 5
                                duration: Motion.ms(220)
                                easing.type: Easing.OutQuad
                            }
                            NumberAnimation {
                                from: root.s * 5
                                to: 0
                                duration: Motion.ms(220)
                                easing.type: Easing.InQuad
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: AltTab.select(icon.index)
                        onClicked: {
                            AltTab.select(icon.index);
                            AltTab.commit();
                        }
                    }
                }
            }
        }
        // Ame's line
        Rectangle {
            id: bubble
            x: root.s * 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.s * 6
            width: bubbleRow.implicitWidth + root.s * 10
            height: bubbleRow.implicitHeight + root.s * 6
            radius: root.s * 4
            color: "#ffffff"
            border.width: root.s
            border.color: root.ink
            Row {
                id: bubbleRow
                anchors.centerIn: parent
                spacing: root.s * 3
                PxIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "chat"
                    fill: root.hot
                    ink: root.ink
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.line[0]
                    font.family: Theme.fontBody
                    font.pixelSize: Theme.sizeBody
                    color: root.ink
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.line[1]
                    font.pixelSize: Theme.sizeBody
                    color: root.hot
                }
            }
        }
    }

    // ---- status strip: the pick's title ----
    Rectangle {
        id: status
        x: root.s
        y: body.y + body.height
        width: frame.width - root.s * 2
        height: root.s * 11
        color: root.cream
        Rectangle {
            width: parent.width
            height: root.s
            color: root.ink
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: root.s * 4
            width: parent.width - root.s * 8 - where.width
            elide: Text.ElideMiddle
            text: "♡ " + (AltTab.current ? (Niri.titleOf(AltTab.current) || root.host.appName(AltTab.current)) : "")
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeBody
            color: root.ink
        }
        Text {
            id: where
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.s * 4
            text: root.host.place(AltTab.current)
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeBody
            color: root.lilac
        }
    }
}
