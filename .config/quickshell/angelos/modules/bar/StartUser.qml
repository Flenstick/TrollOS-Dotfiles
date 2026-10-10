import QtQuick
import qs.config
import qs.services
import qs.widgets

// The user in Start (item 7 of the 2026-10-01 list): the avatar — the picture picked in
// Settings → Bar → Start (StartPrefs.avatar), the system's one, or a heart — in a
// bevelled pixel frame, and the name. A click opens where the avatar is chosen.
Row {
    id: root

    property int size: Theme.u * 13
    property bool showName: true
    property color textColor: Theme.text
    property color frameColor: Theme.accent
    property string kind: "body"            // the name's PxText kind
    property bool clickable: true
    signal opened

    spacing: Theme.u * 4

    PxBox {
        id: frame
        width: root.size
        height: root.size
        color: root.frameColor
        anchors.verticalCenter: parent.verticalCenter
        Image {
            id: pic
            anchors.fill: parent
            anchors.margins: frame.inset
            source: StartPrefs.avatarUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            // pixel avatar: decoded tiny and blown up without smoothing
            sourceSize: Config.bar.avatarPixel ? Qt.size(20, 20) : Qt.size(root.size * 2, root.size * 2)
            smooth: !Config.bar.avatarPixel
            mipmap: !Config.bar.avatarPixel
            visible: status === Image.Ready
        }
        PxIcon {
            visible: pic.status !== Image.Ready
            anchors.centerIn: parent
            name: "heart"
            fill: "#ffffff"
            pixel: Math.max(1, Math.round(root.size / (Theme.u * 13)) * Theme.u)
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.clickable
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.opened();
                Shell.openSettings("bar");
            }
        }
    }
    PxText {
        visible: root.showName
        anchors.verticalCenter: parent.verticalCenter
        text: StartPrefs.userName
        kind: root.kind
        color: root.textColor
    }
}
