import QtQuick
import qs.config
import qs.services

// Settings block (TrollOS): a raised pixel box with a hard shadow and a small
// accent caption inside — macOS-style grouping in the system's own look.
// `advanced` groups fold into a "▸ Дополнительно" header in the simple settings
// view (Settings → Эксперт off); clicking the header unfolds them.
Item {
    id: root

    property string title: ""
    property string icon: ""
    property int spacing: Theme.u * 5
    property bool advanced: false
    property bool open: false
    readonly property bool folded: advanced && !open && !Config.settingsUi.expert
    default property alias content: col.data
    // Windows 11 Settings: a plain section title over stacked cards (SettingRow draws its card)
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow

    implicitWidth: col.implicitWidth + Theme.pad * 2
    readonly property bool hasHead: title !== "" || icon !== ""
    readonly property int headGap: hasHead && !folded ? Theme.u * 4 : 0
    implicitHeight: fluent ? (folded ? fhead.height : fhead.height + 8 + col.implicitHeight) : Theme.pad * 2 + (hasHead ? head.height : 0) + headGap + (folded ? 0 : col.implicitHeight)

    PxBox {
        visible: !root.fluent
        anchors.fill: parent
        color: Qt.alpha(Theme.face, Config.appearance.blur ? 0.9 : 1)
        shadow: Config.appearance.shadows
    }

    Row {
        id: fhead
        visible: root.fluent
        height: root.fluent ? (root.title !== "" ? 28 : 0) : 0
        spacing: 6
        Text {
            visible: root.advanced && !Config.settingsUi.expert
            anchors.verticalCenter: parent.verticalCenter
            text: root.folded ? "›" : "⌄"
            color: WinStyle.text
            font.family: WinStyle.font
            font.pixelSize: 14
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: WinStyle.text
            font.family: WinStyle.font
            font.pixelSize: 14
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }
        Text {
            visible: root.folded
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.t("· дополнительно", "· advanced")
            color: WinStyle.text2
            font.family: WinStyle.font
            font.pixelSize: 12
        }
    }
    MouseArea {
        visible: root.fluent && root.advanced && !Config.settingsUi.expert
        width: fhead.width
        height: fhead.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }
    Row {
        id: head
        visible: !root.fluent && root.hasHead
        x: Theme.pad
        y: Theme.pad
        spacing: Theme.u * 3
        PxIcon {
            visible: root.icon !== ""
            name: root.icon || "heart"
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            visible: root.advanced && !Config.settingsUi.expert
            text: root.folded ? "▸" : "▾"
            color: Theme.dark ? Theme.accent : Theme.edge
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            text: root.title.toUpperCase()
            color: Theme.dark ? Theme.accent : Theme.edge
            font.letterSpacing: Theme.u / 2
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            visible: root.folded
            text: I18n.t("· дополнительно", "· advanced")
            kind: "tiny"
            dim: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        visible: !root.fluent && root.advanced && !Config.settingsUi.expert
        x: head.x
        y: head.y
        width: head.width
        height: head.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }

    Column {
        id: col
        visible: !root.folded
        x: root.fluent ? 0 : Theme.pad
        y: root.fluent ? fhead.height + 8 : Theme.pad + (root.hasHead ? head.height : 0) + root.headGap
        width: root.width - (root.fluent ? 0 : Theme.pad * 2)
        spacing: root.fluent ? 4 : root.spacing
    }
}
