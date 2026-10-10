import QtQuick
import qs.config

// Пиксельный эквалайзер: столбики прыгают, пока играет музыка.
Row {
    id: root

    property bool playing: false
    property bool tall: false
    readonly property int u: Theme.u
    readonly property int maxH: u * (tall ? 12 : 8)

    spacing: u
    height: maxH

    Repeater {
        model: 4
        Rectangle {
            id: barItem
            required property int index
            property real level: 0.3
            y: root.maxH - height
            width: root.u * 2
            height: Math.max(root.u * 2, Math.round(root.maxH * level / root.u) * root.u)
            color: index % 2 ? Theme.accent2 : Theme.accent
            Behavior on height {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutQuad
                }
            }
            Timer {
                interval: 170 + barItem.index * 37
                running: root.playing && root.visible
                repeat: true
                onTriggered: barItem.level = 0.2 + Math.random() * 0.8
                onRunningChanged: if (!running)
                    barItem.level = 0.3
            }
        }
    }
}
