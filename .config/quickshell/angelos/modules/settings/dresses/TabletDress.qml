pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings.dresses

// Settings in the circle of wrath: a tablet of stone, its top arched, the view cut into its
// smooth face; the black water of the Styx laps at its foot.
HellDress {
    id: dress

    paper: "#c7c4bb"
    ink: "#22262b"
    redInk: "#1f4a66"
    title: I18n.t("Скрижаль", "The Tablet")
    titleColor: "#d9d6cd"
    closer: "#3a3d40"
    closerInk: "#d9d6cd"
    headHeight: Theme.u * 30
    pageX: Theme.u * 14
    pageRight: Theme.u * 14
    pageTop: headHeight
    pageBottom: Theme.u * 22
    pageCorner: Theme.u * 2

    // the stele
    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: Theme.u * 6
        topLeftRadius: Math.min(width, height) * 0.25
        topRightRadius: Math.min(width, height) * 0.25
        color: "#4a4d50"
        border.width: Math.max(2, Theme.u)
        border.color: "#26282a"
        // the cut line round its face
        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.u * 6
            topLeftRadius: parent.topLeftRadius - Theme.u * 6
            topRightRadius: parent.topRightRadius - Theme.u * 6
            color: "transparent"
            border.width: Math.max(1, Theme.u / 2)
            border.color: Qt.alpha("#d9d6cd", 0.25)
        }
    }
    // the Styx at its foot: rows of small waves
    Item {
        z: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Theme.u * 14
        clip: true
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: Theme.u * 4
            color: "#0f1a1e"
        }
        Repeater {
            model: 3
            Row {
                id: waves
                required property int index
                x: -(index * Theme.u * 5)
                y: index * Theme.u * 4
                Repeater {
                    model: Math.ceil(dress.width / (Theme.u * 10)) + 2
                    PxIcon {
                        bitmap: ["..xx......", ".x..x.....", "x....x...x"]
                        pixel: Math.max(1, Theme.u)
                        fill2: Qt.alpha("#5f8a96", 0.8 - waves.index * 0.2)
                    }
                }
            }
        }
    }
}
