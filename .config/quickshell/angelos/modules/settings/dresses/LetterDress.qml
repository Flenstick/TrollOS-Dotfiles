pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings.dresses

// Settings in the circle of lust: a letter. A wine-dark envelope torn open, its flap thrown
// back, the view handwritten on the letter drawn half out of it, and the wax seal with its
// heart broken at the flap's point. The wind leaves its streaks at the edges.
HellDress {
    id: dress

    paper: "#f2e3e3"
    ink: "#3e1427"
    redInk: "#a3264f"
    title: I18n.t("Тебе. Настройки", "For you. Settings")
    titleFont: Theme.fontScript
    titlePx: Theme.scriptPx(Theme.sizeTitle)
    titleColor: "#f0c9d4"
    closer: "#7a2440"
    closerInk: "#f2e3e3"
    closerCorner: Theme.u * 6
    pageX: Theme.u * 16
    pageRight: Theme.u * 16
    pageTop: headHeight + Theme.u * 16
    pageBottom: Theme.u * 6

    // the envelope
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: dress.headHeight
        color: "#4e1c2f"
        border.width: Math.max(2, Theme.u)
        border.color: "#2a0d18"
    }
    // the flap, thrown back over the head
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: Math.max(2, Theme.u)
            strokeColor: "#2a0d18"
            fillColor: "#64243c"
            startX: 0
            startY: dress.headHeight
            PathLine {
                x: dress.width / 2
                y: 0
            }
            PathLine {
                x: dress.width
                y: dress.headHeight
            }
            PathLine {
                x: 0
                y: dress.headHeight
            }
        }
    }
    // the pocket's fold lines, from the corners to the middle
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: Math.max(1, Theme.u / 2)
            strokeColor: Qt.alpha("#f0c9d4", 0.25)
            fillColor: "transparent"
            startX: 0
            startY: dress.height
            PathLine {
                x: dress.width / 2
                y: dress.height * 0.6
            }
            PathLine {
                x: dress.width
                y: dress.height
            }
        }
    }
    // the wind's streaks along the sides
    Repeater {
        model: 6
        Rectangle {
            required property int index
            x: index % 2 ? dress.width - width - Theme.u * 2 : Theme.u * 2
            y: dress.pageTop + (index + 1) * (dress.height - dress.pageTop) / 7
            width: Theme.u * (6 + (index * 3) % 7)
            height: Math.max(1, Theme.u / 2)
            color: Qt.alpha("#f0c9d4", 0.35)
        }
    }
    // the broken seal
    Rectangle {
        z: 2
        x: (dress.width - width) / 2
        y: dress.pageTop - height / 2
        width: Theme.u * 18
        height: width
        radius: width / 2
        color: "#9c1f45"
        border.width: Math.max(1, Theme.u)
        border.color: "#5a0f27"
        PxIcon {
            anchors.centerIn: parent
            name: "heartBroken"
            pixel: Math.max(1, Math.round(Theme.u * 0.75))
            ink: "#5a0f27"
            fill: "#f0c9d4"
            fill2: "#f0c9d4"
            fill3: "#f0c9d4"
            bad: "#f0c9d4"
            light: "#f0c9d4"
        }
    }
}
