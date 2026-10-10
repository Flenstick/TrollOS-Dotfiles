import QtQuick
import qs.config

// A glossy Y2K chrome bubble behind a menu (Settings → Right-click menu → Y2K gloss):
// rounded, a shine band over the top half, a rainbow stripe, twinkling sparkles.
// Dark themes get dark chrome, light ones silver, so the theme's text stays readable.
Item {
    id: root

    property real radius: Theme.u * 7
    property bool sparkles: true

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.mix(Theme.menuSurface, "#ffffff", Theme.dark ? 0.24 : 0.7)
            }
            GradientStop {
                position: 0.55
                color: Theme.mix(Theme.menuSurface, Theme.accent2, Theme.dark ? 0.2 : 0.25)
            }
            GradientStop {
                position: 1
                color: Theme.mix(Theme.menuSurface, Theme.accent, Theme.dark ? 0.38 : 0.4)
            }
        }
        border.width: Math.max(1, Theme.u / 2)
        border.color: Qt.alpha("#ffffff", Theme.dark ? 0.6 : 0.9)
    }
    // the dark outer rim
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Math.max(1, Theme.u / 2)
        radius: root.radius + Math.max(1, Theme.u / 2)
        color: "transparent"
        border.width: Math.max(1, Theme.u / 2)
        border.color: Qt.alpha(Theme.edge, 0.55)
        z: -1
    }
    // the shine
    Rectangle {
        x: Theme.u * 2
        y: Theme.u
        width: parent.width - Theme.u * 4
        height: Math.min(Theme.u * 26, parent.height * 0.42)
        radius: root.radius - Theme.u
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.alpha("#ffffff", Theme.dark ? 0.34 : 0.65)
            }
            GradientStop {
                position: 1
                color: Qt.alpha("#ffffff", 0.02)
            }
        }
    }
    // the rainbow stripe
    Rectangle {
        x: root.radius
        y: Math.max(2, Theme.u * 1.5)
        width: parent.width - root.radius * 2
        height: Math.max(3, Theme.u * 1.5)
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: "#ff6fb0"
            }
            GradientStop {
                position: 0.33
                color: "#ffe066"
            }
            GradientStop {
                position: 0.66
                color: "#8fe3ff"
            }
            GradientStop {
                position: 1
                color: "#c9b6ff"
            }
        }
    }
    Repeater {
        model: root.sparkles ? 3 : 0
        PxIcon {
            id: tw
            required property int index
            name: "sparkle"
            pixel: Math.max(1, Math.round(Theme.u / 2))
            fill: index === 1 ? Theme.accent2 : "#ffffff"
            x: [root.width - width - Theme.u * 3, -width / 2, root.width - width / 2][index]
            y: [Theme.u * 3, root.height * 0.55, root.height - height / 2][index]
            opacity: 0
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.visible && !Motion.still
                alwaysRunToEnd: true
                PauseAnimation {
                    duration: Motion.ms(400 + tw.index * 700)
                }
                NumberAnimation {
                    to: 1
                    duration: Motion.ms(260)
                }
                NumberAnimation {
                    to: 0
                    duration: Motion.ms(420)
                }
                PauseAnimation {
                    duration: Motion.ms(1400)
                }
            }
        }
    }
}
