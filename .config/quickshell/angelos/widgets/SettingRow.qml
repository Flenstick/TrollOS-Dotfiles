import QtQuick
import qs.config
import qs.services

// "label ........ control" row with an optional hint below the label.
// With `preview` set to a scene (widgets/previews/<scene>.qml), controls call
// show(value, caption) when an option is clicked and a looping preview.exe
// opens under the row; its × folds it away.
Item {
    id: root

    property string label: ""
    property string hint: ""
    // Windows 11 Settings: each row is its own card, label left, control right
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow
    readonly property int pad: fluent ? 16 : 0
    property int labelWidth: fluent ? Math.min(380, (width - 32) * 0.5) : Math.min(Theme.u * 120, width * 0.45)
    default property alias control: slot.data
    property string preview: ""
    property string previewVariant: ""
    property string previewCaption: ""
    property bool previewOpen: false
    readonly property int rowHeight: fluent ? Math.max(labels.implicitHeight + 26, slot.childrenRect.height + 22, 52) : Math.max(labels.implicitHeight, slot.childrenRect.height) + Theme.u * 2

    function show(value, caption) {
        if (!preview)
            return;
        previewVariant = String(value);
        previewCaption = caption || "";
        previewOpen = true;
        if (gif.item)
            gif.item.restart();
    }

    width: parent ? parent.width : implicitWidth
    implicitHeight: rowHeight + (gif.item ? gif.item.implicitHeight + Theme.u * 3 : 0)

    Rectangle {
        visible: root.fluent
        width: parent.width
        height: root.rowHeight
        radius: 4
        color: WinStyle.card
        border.width: 1
        border.color: WinStyle.controlLine
    }
    Column {
        id: labels
        x: root.pad
        width: root.labelWidth
        y: (root.rowHeight - implicitHeight) / 2
        PxText {
            width: parent.width
            text: root.label
            wrapMode: Text.Wrap
        }
        PxText {
            visible: root.hint !== ""
            width: parent.width
            text: root.hint
            kind: "tiny"
            dim: true
            wrapMode: Text.Wrap
        }
    }
    Item {
        id: slot
        objectName: "settingSlot"
        anchors.left: labels.right
        anchors.leftMargin: root.fluent ? 16 : Theme.u * 6
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        y: (root.rowHeight - height) / 2
        height: childrenRect.height
    }
    Loader {
        id: gif
        active: root.preview !== "" && root.previewOpen
        y: root.rowHeight + Theme.u
        x: Math.min(root.labelWidth, Theme.u * 20)
        width: Math.min(root.width - x, Theme.u * 230)
        sourceComponent: PxPreview {
            width: gif.width
            height: implicitHeight
            scene: root.preview
            variant: root.previewVariant
            caption: root.previewCaption
            onCloseClicked: root.previewOpen = false
        }
    }
}
