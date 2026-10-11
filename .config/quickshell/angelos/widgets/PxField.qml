import QtQuick
import qs.config
import qs.services
import "A11y.js" as A11y

Item {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property bool password: false
    property string icon: ""
    property string kind: "body"
    readonly property string settingsSkin: Theme.settingsSkinFor(root.parent)
    // the Golden Gate skin's System Settings: a Mac field (a capsule with a magnifier for the
    // search, rounded otherwise), the accent's ring while typing
    readonly property bool mac: settingsSkin === "goldengate"
    // TrollOS: the «Material You» skin — the search as Material 3's search bar (a pill on
    // surfaceContainerHigh), any other field outlined (2 dp primary while typing)
    readonly property bool md: settingsSkin === "material"
    readonly property bool mdSearch: md && icon === "search"
    // Enter applies and leaves the field, Esc just leaves it (issue #9) — unless
    // the field is the whole point of its window (launcher, search, passwords)
    property bool keepFocus: false
    signal accepted
    signal edited
    signal keyPressed(var event)

    implicitWidth: Theme.u * 100
    implicitHeight: md ? Theme.mdPx(mdSearch ? 48 : 44) : mac ? input.font.pixelSize + GoldenGate.px(14) : input.font.pixelSize + Theme.u * 10

    function focusField() {
        input.forceActiveFocus();
    }

    Rectangle {
        visible: root.mac
        anchors.fill: parent
        anchors.margins: -GoldenGate.px(3)
        radius: height / 2
        color: "transparent"
        border.width: GoldenGate.px(3)
        border.color: Qt.alpha(GoldenGate.accent, 0.45)
        opacity: input.activeFocus ? 1 : 0
    }
    Rectangle {
        visible: root.mac
        anchors.fill: parent
        radius: root.icon === "search" ? height / 2 : GoldenGate.px(7)
        color: GoldenGate.dark ? Qt.rgba(1, 1, 1, 0.1) : "#ffffff"
        border.width: 1
        border.color: GoldenGate.separator
    }
    Rectangle {
        visible: root.md
        anchors.fill: parent
        radius: root.mdSearch ? Theme.mdRadius("full") : Theme.mdRadius("xs")
        color: root.mdSearch ? Theme.md.surfaceContainerHigh : "transparent"
        border.width: root.mdSearch ? 0 : Theme.mdPx(input.activeFocus ? 2 : 1)
        border.color: input.activeFocus ? Theme.md.primary : Theme.md.outline
    }
    MdSymbol {
        visible: root.md && root.icon !== ""
        anchors.centerIn: ico
        name: "search"
        size: Theme.mdPx(22)
        color: Theme.md.onSurfaceVariant
    }
    PxBox {
        anchors.fill: parent
        visible: root.settingsSkin === "classic"
        color: Theme.sunken
        edgeColor: input.activeFocus ? Theme.accent : Theme.edge
    }
    Rectangle {
        visible: root.settingsSkin !== "classic" && !root.mac && !root.md
        anchors.fill: parent
        radius: root.settingsSkin === "stream" ? Theme.u * 2 : 0
        color: root.settingsSkin === "stream" ? Theme.streamPanel : Theme.windoseSticker
        border.width: Math.max(1, Theme.u / 2)
        border.color: input.activeFocus ? Theme.accent : root.settingsSkin === "stream" ? Theme.mix(Theme.streamLive, Theme.streamPanel, 0.4) : Theme.windoseLine
    }

    MacIcon {
        visible: root.mac && root.icon !== ""
        anchors.centerIn: ico
        name: root.icon === "search" ? "search" : "circle-help"
        size: GoldenGate.px(15)
        stroke: 2
        color: GoldenGate.secondaryLabel
    }
    PxIcon {
        id: ico
        opacity: root.mac || root.md ? 0 : 1
        visible: root.icon !== ""
        name: root.icon || "search"
        x: root.md ? Theme.mdPx(16) : Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
        ink: root.settingsSkin === "stream" ? Theme.streamLive : root.settingsSkin === "windose" ? Theme.windoseRose : Theme.dark ? Theme.text : Theme.edge
    }

    TextInput {
        id: input
        Accessible.name: A11y.name(A11y.rowLabel(root), null, root.placeholder)
        anchors.left: ico.visible ? ico.right : parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.md ? Theme.mdPx(root.icon !== "" ? 12 : 16) : Theme.u * 5
        anchors.rightMargin: root.md ? Theme.mdPx(16) : Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: root.md ? Theme.md.onSurface : Theme.text
        selectionColor: root.md ? Qt.alpha(Theme.md.primary, 0.35) : Theme.select
        selectedTextColor: Theme.selectText
        // handwritten in the grimoire (Theme.scriptWindows), like PxText
        readonly property bool script: Theme.scriptWindows.length > 0 && Theme.scriptWindows.includes(Window.window)
        font.family: script ? Theme.fontScript : root.md ? Theme.mdFont : root.mac ? Theme.macFont : root.kind === "title" ? Theme.fontTitle : Theme.fontBody
        font.pixelSize: script ? Theme.scriptPx(root.kind === "title" ? Theme.sizeTitle : Theme.sizeBody) : root.md ? Theme.mdPx(root.kind === "title" ? 16 : 15) : root.mac ? GoldenGate.px(root.kind === "title" ? 15 : 13) : root.kind === "title" ? Theme.sizeTitle : Theme.sizeBody
        font.hintingPreference: root.mac || root.md ? Font.PreferVerticalHinting : Font.PreferFullHinting
        renderType: script || root.mac || root.md ? Text.QtRendering : Text.NativeRendering
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "♥"
        selectByMouse: true
        onAccepted: {
            root.accepted();
            if (!root.keepFocus)
                input.focus = false;
        }
        Keys.onPressed: e => {
            root.keyPressed(e);
            if (!e.accepted && !root.keepFocus && e.key === Qt.Key_Escape) {
                input.focus = false;
                e.accepted = true;
            }
        }
        onTextEdited: root.edited()

        cursorDelegate: Rectangle {
            id: caret
            width: root.mac ? 1 : root.md ? Theme.mdPx(2) : Theme.u * 2
            color: root.mac ? GoldenGate.label : root.md ? Theme.md.primary : Theme.accent
            visible: input.activeFocus
            onVisibleChanged: opacity = 1
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: input.activeFocus && !Motion.still
                onStopped: caret.opacity = 1
                PropertyAction {
                    value: 1
                }
                PauseAnimation {
                    duration: Motion.ms(480)
                }
                PropertyAction {
                    value: 0
                }
                PauseAnimation {
                    duration: Motion.ms(480)
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
}
