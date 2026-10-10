import QtQuick
import qs.config
import qs.services

// Win98 group box: etched frame with the title cut into the top edge.
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
    implicitHeight: fluent ? (folded ? fhead.height : fhead.height + 8 + col.implicitHeight) : folded ? head.height + Theme.u * 4 : col.implicitHeight + head.height + Theme.pad * 2

    readonly property int lineY: head.height / 2
    readonly property int b: Math.max(1, Theme.u / 2)

    // etched frame: lo line + hi line offset by one
    Repeater {
        model: root.fluent ? 0 : 2
        Item {
            required property int index
            readonly property color c: index === 0 ? Theme.lo : Theme.hi
            readonly property int o: index * root.b
            x: o
            y: root.lineY + o
            width: root.width - root.b
            height: root.height - root.lineY - root.b
            Rectangle { x: 0; y: 0; width: Theme.u * 4; height: root.b; color: parent.c }
            Rectangle { x: head.x + head.width + Theme.u * 2 - parent.o; y: 0; width: Math.max(0, parent.width - x); height: root.b; color: parent.c }
            Rectangle { x: 0; y: 0; width: root.b; height: parent.height; color: parent.c }
            Rectangle { x: parent.width - root.b; y: 0; width: root.b; height: parent.height; color: parent.c }
            Rectangle { x: 0; y: parent.height - root.b; width: parent.width; height: root.b; color: parent.c }
        }
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
        visible: !root.fluent
        x: Theme.u * 6
        spacing: Theme.u * 3
        leftPadding: Theme.u * 2
        rightPadding: Theme.u * 2
        PxIcon {
            visible: root.icon !== ""
            name: root.icon || "heart"
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            visible: root.advanced && !Config.settingsUi.expert
            text: root.folded ? "▸" : "▾"
            kind: "title"
            color: Theme.dark ? Theme.accent : Theme.edge
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            text: root.title
            kind: "title"
            color: Theme.dark ? Theme.accent : Theme.edge
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
        width: head.width
        height: head.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }

    Column {
        id: col
        visible: !root.folded
        x: root.fluent ? 0 : Theme.pad
        y: root.fluent ? fhead.height + 8 : head.height + Theme.u * 4
        width: root.width - (root.fluent ? 0 : Theme.pad * 2)
        spacing: root.fluent ? 4 : root.spacing
    }
}
