import QtQuick
import QtQuick.Templates as T
import qs.config
import qs.services

// Dropdown. model: array of strings or {label, value, icon}.
Item {
    id: root

    property var model: []
    property var currentValue
    property string placeholder: "—"
    signal activated(var value)

    readonly property var items: (model || []).map(m => typeof m === "object" ? m : {
                label: String(m),
                value: m
            })
    readonly property int currentIndex: items.findIndex(i => i.value === currentValue)
    readonly property string currentLabel: currentIndex >= 0 ? items[currentIndex].label : placeholder

    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow
    implicitWidth: fluent ? fcombo.implicitWidth : Theme.u * 100
    implicitHeight: fluent ? 32 : Theme.sizeBody + Theme.u * 10
    x: fluent && parent && parent.objectName === "settingSlot" ? parent.width - width : 0

    FluentCombo {
        id: fcombo
        visible: root.fluent
        z: 10
        anchors.fill: parent
        model: root.fluent ? root.model : []
        currentValue: root.currentValue
        placeholder: root.placeholder
        onActivated: v => {
            root.currentValue = v;
            root.activated(v);
        }
    }

    PxBox {
        anchors.fill: parent
        visible: !root.fluent
        sunken: true
        color: Theme.sunken
    }
    PxText {
        visible: !root.fluent
        anchors.left: parent.left
        anchors.right: arrow.left
        anchors.leftMargin: Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentLabel
        elide: Text.ElideRight
    }
    PxBox {
        id: arrow
        visible: !root.fluent
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Theme.u * 2
        width: height
        sunken: mouse.pressed
        PxIcon {
            anchors.centerIn: parent
            name: "arrowDown"
            pixel: Math.max(1, Theme.u - 1)
        }
    }
    MouseArea {
        id: mouse
        enabled: !root.fluent
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.opened ? popup.close() : popup.open()
    }

    T.Popup {
        id: popup
        y: root.height
        width: root.width
        height: Math.min(list.contentHeight + Theme.u * 4, Theme.u * 150)
        padding: Theme.u * 2
        modal: false
        focus: true
        closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside

        background: PxBox {
            color: Theme.face
            shadow: true
        }
        contentItem: ListView {
            id: list
            clip: true
            model: root.items
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: opt
                required property var modelData
                required property int index
                width: list.width
                height: Theme.sizeBody + Theme.u * 7
                color: optMouse.containsMouse ? Theme.select : index === root.currentIndex ? Theme.faceAlt : "transparent"
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.u * 4
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    spacing: Theme.u * 3
                    PxIcon {
                        visible: !!opt.modelData.icon
                        name: opt.modelData.icon || "heart"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    PxText {
                        text: opt.modelData.label
                        color: optMouse.containsMouse ? Theme.selectText : Theme.text
                    }
                }
                MouseArea {
                    id: optMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentValue = opt.modelData.value;
                        root.activated(opt.modelData.value);
                        popup.close();
                    }
                }
            }
        }
    }
}
