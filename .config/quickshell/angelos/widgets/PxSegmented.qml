import QtQuick
import qs.config
import qs.services

// Row of toggle buttons; model: [{label, value, icon}]. In the Windows 11
// Settings skin it becomes a Fluent combo box, like Windows uses for choices.
Row {
    id: root

    property var model: []
    property var currentValue
    signal activated(var value)
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow

    spacing: Theme.u * 2
    x: fluent && parent && parent.objectName === "settingSlot" ? parent.width - width : 0

    Repeater {
        model: root.fluent ? [] : root.model
        PxButton {
            required property var modelData
            text: modelData.label || ""
            icon: modelData.icon || ""
            checked: root.currentValue === modelData.value
            onClicked: {
                root.currentValue = modelData.value;
                root.activated(modelData.value);
            }
        }
    }
    FluentCombo {
        visible: root.fluent
        model: root.fluent ? root.model : []
        currentValue: root.currentValue
        onActivated: v => {
            root.currentValue = v;
            root.activated(v);
        }
    }
}
