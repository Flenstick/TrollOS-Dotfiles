import QtQuick
import qs.config
import qs.services
import qs.widgets

// Обложка играющего трека (или нотка, если обложки нет).
Rectangle {
    id: root

    radius: Math.max(2, width / 5)
    color: Qt.alpha(Theme.accent, 0.25)
    clip: true

    Image {
        id: img
        anchors.fill: parent
        source: Lyrics.artUrl
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
    }
    PxIcon {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        name: "music"
        pixel: Math.max(1, Math.floor(root.width / 16))
    }
}
