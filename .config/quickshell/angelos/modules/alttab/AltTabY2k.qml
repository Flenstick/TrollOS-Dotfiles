pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Alt+Tab, Y2K style: a glossy chrome bubble panel, cards like candy buttons,
// the pick iridescent (pink → lilac → cyan) with a glow and twinkling ✦ around
// it, its title in a silver pill. Smooth, round and shiny — the 2000s way.
Item {
    id: root

    required property var host
    readonly property int s: Theme.u
    readonly property int cell: s * 44
    readonly property int perRow: Math.max(1, Math.min(AltTab.items.length, Math.floor(((host.screen ? host.screen.width : 1920) * 0.8) / (cell + s * 6))))
    readonly property string font: "Verdana"
    readonly property color steel: "#5a6b93"
    implicitWidth: grid.width + s * 24
    implicitHeight: heading.height + grid.height + pill.height + s * 34

    // ---- the chrome bubble ----
    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.margins: root.s * 2
        radius: root.s * 12
        border.width: Math.max(1, root.s / 2)
        border.color: "#8fa2c8"
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#fdfdff"
            }
            GradientStop {
                position: 0.48
                color: "#e3e9f5"
            }
            GradientStop {
                position: 0.52
                color: "#d3dbec"
            }
            GradientStop {
                position: 1
                color: "#eef3fb"
            }
        }
        // inner white rim
        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.max(1, root.s / 2) + 1
            radius: parent.radius - 2
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.9)
        }
        // gloss over the top half
        Rectangle {
            x: root.s * 3
            y: root.s * 2
            width: parent.width - root.s * 6
            height: parent.height * 0.42
            radius: root.s * 10
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.rgba(1, 1, 1, 0.85)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(1, 1, 1, 0.05)
                }
            }
        }
    }

    Text {
        id: heading
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.s * 8
        text: "✧ " + I18n.t("выбери окно", "switch window") + " ✧"
        font.family: root.font
        font.pixelSize: Theme.sizeBody + 2
        font.italic: true
        font.bold: true
        color: root.steel
        style: Text.Raised
        styleColor: "#ffffff"
    }

    Grid {
        id: grid
        anchors.horizontalCenter: parent.horizontalCenter
        y: heading.y + heading.height + root.s * 8
        columns: root.perRow
        spacing: root.s * 6
        Repeater {
            model: AltTab.items
            Item {
                id: card
                required property var modelData
                required property int index
                readonly property bool picked: index === AltTab.index
                width: root.cell
                height: root.cell + (Config.alttab.titles ? root.s * 8 : 0)
                // glow behind the pick
                Rectangle {
                    visible: card.picked
                    anchors.fill: candy
                    anchors.margins: -root.s * 3
                    radius: candy.radius + root.s * 3
                    color: Qt.rgba(1, 0.55, 0.85, 0.35)
                }
                Rectangle {
                    id: candy
                    width: parent.width
                    height: root.cell
                    radius: root.s * 8
                    border.width: 1
                    border.color: card.picked ? "#b07ad8" : "#b9c5dc"
                    gradient: card.picked ? shiny : plain
                    scale: card.picked ? 1.06 : hover.containsMouse ? 1.02 : 1
                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.ms(120)
                            easing.type: Easing.OutBack
                        }
                    }
                    Gradient {
                        id: plain
                        GradientStop {
                            position: 0
                            color: "#ffffff"
                        }
                        GradientStop {
                            position: 1
                            color: "#e1e7f3"
                        }
                    }
                    Gradient {
                        id: shiny
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: "#ff9ad5"
                        }
                        GradientStop {
                            position: 0.5
                            color: "#c6a4ff"
                        }
                        GradientStop {
                            position: 1
                            color: "#8fe3ff"
                        }
                    }
                    AppIcon {
                        anchors.centerIn: parent
                        appId: card.modelData.app_id || ""
                        size: root.s * 24
                    }
                    // candy gloss
                    Rectangle {
                        x: root.s * 2
                        y: root.s * 1.5
                        width: parent.width - root.s * 4
                        height: parent.height * 0.45
                        radius: parent.radius - root.s
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.rgba(1, 1, 1, 0.8)
                            }
                            GradientStop {
                                position: 1
                                color: Qt.rgba(1, 1, 1, 0.08)
                            }
                        }
                    }
                }
                Text {
                    visible: Config.alttab.titles
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: root.host.appName(card.modelData)
                    font.family: root.font
                    font.pixelSize: Theme.sizeBody - 1
                    font.bold: card.picked
                    color: card.picked ? "#8a3fb8" : root.steel
                }
                // twinkling sparkles around the pick
                Repeater {
                    model: card.picked ? [[-0.1, -0.08, 0, "#ffffff"], [1.02, 0.12, 180, "#ff7fcf"], [0.88, 0.95, 360, "#7fdcff"], [0.02, 0.8, 520, "#ffffff"]] : []
                    Text {
                        id: star
                        required property var modelData
                        x: modelData[0] * candy.width - width / 2
                        y: modelData[1] * candy.height - height / 2
                        text: "✦"
                        font.pixelSize: Theme.sizeBody + root.s * 2
                        color: modelData[3]
                        style: Text.Outline
                        styleColor: Qt.rgba(0.55, 0.35, 0.8, 0.5)
                        opacity: 0
                        scale: 0.5
                        SequentialAnimation {
                            running: !Motion.still
                            alwaysRunToEnd: true
                            loops: Animation.Infinite
                            PauseAnimation {
                                duration: Motion.ms(star.modelData[2])
                            }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: star
                                    property: "opacity"
                                    to: 1
                                    duration: Motion.ms(260)
                                }
                                NumberAnimation {
                                    target: star
                                    property: "scale"
                                    to: 1.1
                                    duration: Motion.ms(260)
                                    easing.type: Easing.OutBack
                                }
                            }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: star
                                    property: "opacity"
                                    to: 0
                                    duration: Motion.ms(380)
                                }
                                NumberAnimation {
                                    target: star
                                    property: "scale"
                                    to: 0.4
                                    duration: Motion.ms(380)
                                }
                            }
                            PauseAnimation {
                                duration: Motion.ms(700 - star.modelData[2])
                            }
                        }
                    }
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: AltTab.select(card.index)
                    onClicked: {
                        AltTab.select(card.index);
                        AltTab.commit();
                    }
                }
            }
        }
    }

    // the pick's title in a silver pill
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: grid.y + grid.height + root.s * 8
        width: Math.min(root.width - root.s * 20, pillText.implicitWidth + root.s * 16)
        height: pillText.implicitHeight + root.s * 6
        radius: height / 2
        border.width: 1
        border.color: "#9fb0d0"
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#ffffff"
            }
            GradientStop {
                position: 1
                color: "#cfd8ea"
            }
        }
        Text {
            id: pillText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - root.s * 12)
            elide: Text.ElideMiddle
            text: (AltTab.current ? (Niri.titleOf(AltTab.current) || root.host.appName(AltTab.current)) : "") + (root.host.place(AltTab.current) ? "  ·  " + root.host.place(AltTab.current) : "")
            font.family: root.font
            font.pixelSize: Theme.sizeBody
            color: root.steel
        }
    }
}
