pragma ComponentBehavior: Bound

import QtQuick
import qs.config

// An iron chain hanging from its top (hell's bars: the capsules' tombstones hang on two,
// chains dangle under the top strip): `links` rings and side links in art pixels, swinging
// a little around the top while `swing` (degrees) is not 0.
Item {
    id: root

    property int links: 4
    property int pixel: Theme.u
    property real swing: 0
    property real phase: 0
    property real t: 0
    readonly property var ring: [".###.", "#w..#", "#...#", "#...#", ".###."]
    readonly property var side: [".#.", "#w#", "#w#", ".#."]

    implicitWidth: pixel * 5
    implicitHeight: col.implicitHeight
    width: implicitWidth
    height: implicitHeight
    transformOrigin: Item.Top
    rotation: swing === 0 ? 0 : Math.round(Math.sin(t * 1.9 + phase) * swing * 2) / 2

    Timer {
        interval: 120
        repeat: true
        running: root.swing !== 0 && root.visible && !Motion.still
        onTriggered: root.t += 0.12
    }
    Column {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: -root.pixel
        Repeater {
            model: root.links * 2
            PxIcon {
                required property int index
                anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                pixel: root.pixel
                bitmap: index % 2 === 0 ? root.ring : root.side
                ink: "#3a3236"
                light: "#8d8288"
                body: "#4c4247"
            }
        }
    }
}
