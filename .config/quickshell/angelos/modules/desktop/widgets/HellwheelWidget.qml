pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// The Wheel of Hell (wheel666.exe): hell's own desktop widget, gone in heaven
// (DesktopWidgets: "hell": true). Eight sectors (Angel.wheelSectors) — two pleas that
// count towards the angel's return, a punishment (her joke and a prank), a new hell
// wallpaper, Cerberus running across the screen, an earthquake, a cursed cursor for an
// hour, a dud. One spin per 20 minutes. The spin itself is Angel's (wheelAngle, the
// ticks, the result): both copies of the widget, its face and its input copy, only
// show it. Drawn at art resolution and scaled up, so it turns pixel by pixel.
Item {
    id: root

    property string screenName
    property var widget

    readonly property int d: 72                  // the wheel, art pixels
    readonly property int px: Theme.u
    readonly property var labels: ({
            "plea": I18n.t("Испытание", "A trial"),
            "punish": I18n.t("Наказание", "Punishment"),
            "newHell": I18n.t("Новый ад", "A new hell"),
            "cerberus": I18n.t("Цербер", "Cerberus"),
            "quake": I18n.t("Землетрясение", "Earthquake"),
            "cursed": I18n.t("Проклятый курсор", "Cursed cursor"),
            "dud": I18n.t("Пустышка", "A dud")
        })
    // the sectors in the circle's few colours: the pleas stand out in the one accent
    readonly property var colours: ({
            "plea": String(Theme.hellAccent),
            "punish": String(Theme.hellBlood),
            "newHell": String(Theme.hellFaceAlt),
            "cerberus": String(Theme.hellRim),
            "quake": String(Theme.hellFace),
            "cursed": String(Theme.hellHi),
            "dud": String(Theme.hellSunken)
        })
    readonly property var icons: ({
            "plea": "heart",
            "punish": "skull",
            "newHell": "image",
            "cerberus": "fire",
            "quake": "warn",
            "cursed": "cursor",
            "dud": "ghost"
        })

    // the countdown: minutes until the next spin, refreshed while on show
    property double clock: Date.now()
    Timer {
        interval: 15000
        repeat: true
        running: root.visible && !Shell.hiddenScreen(root.screenName)
        triggeredOnStart: true
        onTriggered: root.clock = Date.now()
    }
    readonly property int minutesLeft: Math.ceil(Math.max(0, Angel.wheelCooldown - (clock - (Story.player.wheelAt || 0))) / 60000)
    readonly property bool ready: minutesLeft <= 0 && !Angel.wheelSpinning
    // where it stopped last, for a minute
    readonly property bool showLast: !Angel.wheelSpinning && Angel.wheelLast !== "" && clock - Angel.wheelLastAt < 60000

    implicitWidth: Math.max(wheelBox.width, foot.implicitWidth) + Theme.u * 8
    implicitHeight: col.implicitHeight + Theme.u * 2

    // the rim's lights: dark at rest (hell is still), a chase only while it spins
    property int blink: 0
    Timer {
        interval: 70
        repeat: true
        running: Angel.wheelSpinning && root.visible && !Shell.hiddenScreen(root.screenName)
        onTriggered: root.blink++
    }

    Column {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.u * 3

        Item {
            id: wheelBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.d * root.px
            height: (root.d + 6) * root.px

            // art resolution: one texel a pixel, scaled up crisp
            Item {
                id: art
                width: root.d
                height: root.d + 6
                scale: root.px
                transformOrigin: Item.TopLeft
                layer.enabled: true
                layer.smooth: false
                layer.textureSize: Qt.size(width, height)

                Item {
                    id: spin
                    y: 6
                    width: root.d
                    height: root.d
                    rotation: Angel.wheelAngle
                    smooth: false

                    Canvas {
                        id: disc
                        anchors.fill: parent
                        renderTarget: Canvas.Image
                        smooth: false
                        antialiasing: false
                        onPaint: {
                            const ctx = getContext("2d");
                            const c = root.d / 2, R = c - 1;
                            ctx.clearRect(0, 0, width, height);
                            for (let y = 0; y < root.d; y++)
                                for (let x = 0; x < root.d; x++) {
                                    const dx = x + 0.5 - c, dy = y + 0.5 - c, r = Math.sqrt(dx * dx + dy * dy);
                                    if (r > R)
                                        continue;
                                    let th = Math.atan2(dx, -dy) * 180 / Math.PI;
                                    th = (th + 360) % 360;
                                    const sector = Math.round(th / 45) % 8;
                                    const local = ((th + 22.5) % 45 + 45) % 45;
                                    let col = root.colours[Angel.wheelSectors[sector]];
                                    if (r > R - 1.2)
                                        col = Theme.hellEdge;
                                    else if (r > R - 4)
                                        col = Theme.hellFace;
                                    else if (r < 7.5)
                                        col = r > 6.4 ? Theme.hellRim : Theme.hellBody;
                                    else if (local < 0.9 || local > 44.1)
                                        col = Theme.hellEdge;
                                    else if (r > R - 5.2)
                                        col = Theme.hellEdge;
                                    else if ((x + y) % 2 === 0 && r > R - 9)
                                        col = Qt.darker(col, 1.25);
                                    ctx.fillStyle = col;
                                    ctx.fillRect(x, y, 1, 1);
                                }
                        }
                        Component.onCompleted: requestPaint()
                    }
                    // the sectors' pictures, facing out
                    Repeater {
                        model: 8
                        PxIcon {
                            required property int index
                            readonly property real a: index * 45
                            readonly property string sid: Angel.wheelSectors[index]
                            pixel: 1
                            name: root.icons[sid]
                            ink: Theme.hellEdge
                            light: Theme.hellText
                            body: Theme.hellFace
                            fill: Theme.hellTextDim
                            fill2: Theme.hellTextDim
                            fill3: Theme.hellTextDim
                            bad: Theme.hellText
                            x: root.d / 2 + Math.sin(a * Math.PI / 180) * 22 - width / 2
                            y: root.d / 2 - Math.cos(a * Math.PI / 180) * 22 - height / 2
                            rotation: a
                            smooth: false
                        }
                    }
                    // the lights around the rim
                    Repeater {
                        model: 16
                        Rectangle {
                            required property int index
                            readonly property real a: index * 22.5 + 11.25
                            readonly property bool on: Angel.wheelSpinning && (index + root.blink) % 4 === 0
                            width: 2
                            height: 2
                            x: Math.round(root.d / 2 + Math.sin(a * Math.PI / 180) * (root.d / 2 - 3.6) - 1)
                            y: Math.round(root.d / 2 - Math.cos(a * Math.PI / 180) * (root.d / 2 - 3.6) - 1)
                            color: on ? Theme.hellAccent : Theme.hellRim
                        }
                    }
                    PxIcon {
                        anchors.centerIn: parent
                        name: "pentagram"
                        pixel: 1
                        ink: Theme.hellEdge
                        fill: Theme.hellRim
                        smooth: false
                    }
                }
                // the pitchfork pointer at the top; it flicks back at each sector it passes
                PxIcon {
                    id: pointer
                    x: (root.d - width) / 2
                    y: 0
                    pixel: 1
                    bitmap: ["...#...", "..#y#..", "..#y#..", "#######", "#y#y#y#", "#y#y#y#", ".#.#.#.", "..#.#.."]
                    ink: Theme.hellEdge
                    fill3: Theme.hellTextDim
                    transformOrigin: Item.Top
                    readonly property real local: (((-Angel.wheelAngle % 360) + 360 + 22.5) % 45)
                    rotation: Angel.wheelSpinning && local < 9 ? -16 * (1 - local / 9) : 0
                    smooth: false
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Angel.wheelSpin(root.screenName)
            }
        }

        Column {
            id: foot
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.u * 2
            PxButton {
                anchors.horizontalCenter: parent.horizontalCenter
                hell: true
                icon: "pentagram"
                text: Angel.wheelSpinning ? I18n.t("Крутится…", "Spinning…") : I18n.t("Крутить", "Spin")
                enabled: !Angel.wheelSpinning
                onClicked: Angel.wheelSpin(root.screenName)
            }
            PxText {
                anchors.horizontalCenter: parent.horizontalCenter
                kind: "tiny"
                color: root.showLast ? Theme.hellAccent : Theme.hellTextDim
                text: root.showLast ? "» " + (root.labels[Angel.wheelLast] || "") + " «" : Angel.wheelSpinning ? I18n.t("ставки сделаны", "the bets are placed") : root.ready ? I18n.t("крути, грешник", "spin it, sinner") : I18n.t("остывает: ещё ", "cooling down: ") + root.minutesLeft + I18n.t(" мин", " min")
            }
        }
    }
}
