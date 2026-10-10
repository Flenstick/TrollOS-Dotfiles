import QtQuick
import qs.config

// A big tile of the simple settings view (Home, All sections), drawn in the settings skin
// (Config.settingsUi.skin). Its size comes from the grid, so every tile is the same:
//   classic   a raised angelOS box: icon, name, one line of what's inside
//   windose   a NEEDY GIRL OVERDOSE desktop shortcut: a white sticker with a pink rim and a
//             hard shadow, the name in a pink bubble
//   stream    a super chat from Ame's stream: a coloured header with the icon and name,
//             the hint as the message
Item {
    id: root

    property string skin: Config.settingsUi.skin || "classic"
    property string icon: "heart"
    property string text: ""
    property string hint: ""
    property bool small: false
    property int tint: 0                    // the stream skin colours its super chats in turn
    signal clicked

    readonly property bool hot: mouse.containsMouse
    readonly property bool down: mouse.pressed
    readonly property var chatColors: [Theme.ngoPink, Theme.ngoLilac, Theme.ngoMint]
    readonly property color chat: chatColors[tint % chatColors.length]

    // ---- classic ----
    PxBox {
        visible: root.skin === "classic"
        anchors.fill: parent
        sunken: root.down
        color: root.hot ? Theme.mix(Theme.face, Theme.accent, 0.2) : Theme.face
        shadow: Config.appearance.shadows && !root.down
        Column {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.down ? Theme.u : 0
            anchors.verticalCenterOffset: root.down ? Theme.u : 0
            width: parent.width - Theme.u * 8
            spacing: Theme.u * 2
            PxIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: root.icon
                pixel: root.small ? Theme.u : Theme.u * 2
            }
            PxText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.text
                font.bold: true
                elide: Text.ElideRight
            }
            PxText {
                visible: root.hint !== ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.hint
                kind: "tiny"
                dim: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }

    // ---- windose: a desktop sticker ----
    Item {
        visible: root.skin === "windose"
        anchors.fill: parent
        readonly property real plate: Math.min(width - Theme.u * 4, height - label.height - Theme.u * (root.hint && !root.small ? 16 : 6), root.small ? Theme.u * 26 : Theme.u * 34)
        // the hard sticker shadow
        Rectangle {
            x: sticker.x + Theme.u
            y: sticker.y + Theme.u
            width: sticker.width
            height: sticker.height
            radius: sticker.radius
            color: Qt.alpha(Theme.shadow, Theme.dark ? 0.25 : 0.12)
        }
        Rectangle {
            id: sticker
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.u * 2
            width: parent.plate
            height: width
            radius: Theme.u * 4
            color: Theme.windoseSticker
            border.width: Theme.u
            border.color: root.hot ? Theme.windoseLavender : Theme.windoseLine
            scale: root.down ? 0.92 : root.hot ? 1.05 : 1
            rotation: root.hot ? -3 : 0
            Behavior on scale {
                NumberAnimation {
                    duration: Motion.ms(90)
                }
            }
            Behavior on rotation {
                NumberAnimation {
                    duration: Motion.ms(90)
                }
            }
            PxIcon {
                anchors.centerIn: parent
                name: root.icon
                pixel: root.small ? Theme.u : Theme.u * 2
                ink: Theme.windoseInk
                fill: Theme.windoseRose
                fill2: Theme.windoseLavender
                light: Theme.windoseLavender
                body: Theme.windoseSticker
            }
        }
        Rectangle {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: sticker.bottom
            anchors.topMargin: Theme.u * 2
            width: Math.min(parent.width, labelText.implicitWidth + Theme.u * 6)
            height: labelText.implicitHeight + Theme.u * 2
            radius: height / 2
            color: root.hot ? Theme.windoseLavender : Theme.mix(Theme.windoseSticker, Theme.windoseRose, 0.36)
            border.width: Math.max(1, Theme.u / 2)
            border.color: Theme.windoseLine
            PxText {
                id: labelText
                anchors.centerIn: parent
                width: Math.min(implicitWidth, root.width - Theme.u * 6)
                elide: Text.ElideRight
                text: root.text
                font.bold: true
                color: Theme.windoseInk
            }
        }
        PxText {
            visible: root.hint !== "" && !root.small
            anchors.top: label.bottom
            anchors.topMargin: Theme.u
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.hint
            kind: "tiny"
            color: Theme.textDim
            opacity: 0.8
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    // ---- stream: a super chat ----
    Rectangle {
        visible: root.skin === "stream"
        anchors.fill: parent
        anchors.margins: root.down ? Theme.u : 0
        radius: Theme.u * 3
        color: Theme.streamPanel
        border.width: root.hot ? Theme.u : Math.max(1, Theme.u / 2)
        border.color: root.hot ? root.chat : Qt.alpha(root.chat, 0.5)
        clip: true
        Rectangle {
            id: chatHead
            width: parent.width
            height: root.small ? Theme.u * 16 : Theme.u * 20
            color: root.chat
            Row {
                x: Theme.u * 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.u * 3
                Rectangle {
                    width: chatHead.height - Theme.u * 6
                    height: width
                    radius: width / 2
                    color: Theme.ngoSticker
                    anchors.verticalCenter: parent.verticalCenter
                    PxIcon {
                        anchors.centerIn: parent
                        name: root.icon
                        pixel: Math.max(1, Math.round(Theme.u * (root.small ? 0.5 : 1)))
                        ink: Theme.ngoInk
                        fill: root.chat
                    }
                }
                PxText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: chatHead.width - chatHead.height - Theme.u * 6
                    elide: Text.ElideRight
                    text: root.text
                    font.bold: true
                    color: Theme.ngoInk
                }
            }
        }
        PxText {
            visible: root.hint !== ""
            anchors.top: chatHead.bottom
            anchors.topMargin: Theme.u * 3
            x: Theme.u * 4
            width: parent.width - Theme.u * 8
            text: root.hint
            kind: "tiny"
            color: Theme.streamText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        PxText {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.u * 3
            text: "♡"
            color: root.chat
            visible: !root.small
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
