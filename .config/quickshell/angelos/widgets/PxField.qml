import QtQuick
import qs.config
import qs.services

Item {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property bool password: false
    property string icon: ""
    property string kind: "body"
    signal accepted
    signal edited
    signal keyPressed(var event)
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow

    implicitWidth: Theme.u * 100
    implicitHeight: fluent ? 32 : input.font.pixelSize + Theme.u * 10

    function focusField() {
        input.forceActiveFocus();
    }

    // Fluent text box: rounded, accent underline while typing
    Rectangle {
        visible: root.fluent
        anchors.fill: parent
        radius: 4
        color: input.activeFocus ? (WinStyle.dark ? Qt.rgba(0.12, 0.12, 0.12, 0.9) : "#ffffff") : WinStyle.control
        border.width: 1
        border.color: WinStyle.controlLine
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 2
            height: input.activeFocus ? 2 : 1
            color: input.activeFocus ? WinStyle.accent : WinStyle.controlBottom
        }
    }
    PxBox {
        anchors.fill: parent
        visible: !root.fluent
        sunken: true
        color: Theme.sunken
        edgeColor: input.activeFocus ? Theme.accent : Theme.edge
    }

    PxIcon {
        id: ico
        visible: root.icon !== "" && !root.fluent
        name: root.icon || "search"
        x: Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
    }

    TextInput {
        id: input
        anchors.left: ico.visible ? ico.right : parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.fluent ? 11 : Theme.u * 5
        anchors.rightMargin: root.fluent ? (root.icon !== "" ? 36 : 11) : Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: root.fluent ? WinStyle.text : Theme.text
        selectionColor: root.fluent ? WinStyle.accent : Theme.select
        selectedTextColor: root.fluent ? WinStyle.onAccent : Theme.selectText
        font.family: root.fluent ? WinStyle.font : root.kind === "title" ? Theme.fontTitle : Theme.fontBody
        font.pixelSize: root.fluent ? 14 : root.kind === "title" ? Theme.sizeTitle : Theme.sizeBody
        font.hintingPreference: Font.PreferFullHinting
        renderType: Text.NativeRendering
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "♥"
        selectByMouse: true
        onAccepted: root.accepted()
        Keys.onPressed: e => root.keyPressed(e)
        onTextEdited: root.edited()

        cursorDelegate: Rectangle {
            width: root.fluent ? 1 : Theme.u * 2
            color: root.fluent ? WinStyle.text : Theme.accent
            visible: input.activeFocus
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: input.activeFocus
                PropertyAction {
                    value: 1
                }
                PauseAnimation {
                    duration: 480
                }
                PropertyAction {
                    value: 0
                }
                PauseAnimation {
                    duration: 480
                }
            }
        }
    }

    PxText {
        anchors.fill: input
        visible: input.text === "" && !input.inputMethodComposing
        text: root.placeholder
        dim: true
        font: input.font
        elide: Text.ElideRight
    }
    Image {
        visible: root.fluent && root.icon !== ""
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        sourceSize: Qt.size(28, 28)
        source: root.fluent && root.icon ? Qt.resolvedUrl("../modules/bar/win/icons/" + (WinStyle.dark ? "d/" : "l/") + (WinStyle.fluentIcon(root.icon) || "search-regular") + ".svg") : ""
    }
}
