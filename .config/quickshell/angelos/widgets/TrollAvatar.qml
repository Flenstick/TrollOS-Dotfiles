import QtQuick
import qs.config
import qs.services

// The user's picture (Settings → Профиль) in a pixel frame, or the TrollOS
// splat when none is set.
Item {
    id: root

    property int size: Theme.u * 26
    property bool framed: true
    readonly property string source: Config.profile.avatar ? "file://" + Config.expand(Config.profile.avatar) : ""
    readonly property bool hasPicture: pic.status === Image.Ready

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        visible: root.framed
        color: Theme.sunken
        border.width: Theme.u
        border.color: Theme.accent
    }
    Image {
        id: pic
        anchors.fill: parent
        anchors.margins: root.framed ? Theme.u * 2 : 0
        source: root.source
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        visible: status === Image.Ready
    }
    PxIcon {
        visible: !root.hasPicture
        anchors.centerIn: parent
        name: "splat"
        pixel: Math.max(1, Math.floor((root.size - Theme.u * 6) / 13))
        bad: Theme.accent
    }
}
