pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import qs.config
import qs.services

// Windows 11 combo box (Settings skin): current choice + chevron, a rounded
// list that opens over it with the chosen row marked by an accent pill.
Item {
    id: root

    property var model: []
    property var currentValue
    property string placeholder: "—"
    signal activated(var value)

    readonly property var items: (model || []).map(m => typeof m === "object" ? m : {
                "label": String(m),
                "value": m
            })
    readonly property int currentIndex: items.findIndex(i => i.value === currentValue)
    readonly property string currentLabel: currentIndex >= 0 ? items[currentIndex].label : placeholder

    implicitWidth: Math.min(320, Math.max(140, measure.implicitWidth + 56))
    implicitHeight: 32
    Text {
        id: measure
        visible: false
        text: root.items.reduce((a, i) => String(i.label).length > a.length ? String(i.label) : a, root.placeholder)
        font.family: WinStyle.font
        font.pixelSize: 14
    }

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: ma.pressed ? WinStyle.subtlePress : ma.containsMouse ? WinStyle.controlHover : WinStyle.control
        border.width: 1
        border.color: WinStyle.controlLine
    }
    Text {
        x: 12
        width: parent.width - 44
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentLabel
        elide: Text.ElideRight
        color: WinStyle.text
        font.family: WinStyle.font
        font.pixelSize: 14
        renderType: Text.NativeRendering
    }
    Image {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: ma.pressed ? 1 : 0
        width: 12
        height: 12
        sourceSize: Qt.size(24, 24)
        source: Qt.resolvedUrl("../modules/bar/win/icons/" + (WinStyle.dark ? "d/" : "l/") + "chevron_down-regular.svg")
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: popup.opened ? popup.close() : popup.open()
    }

    T.Popup {
        id: popup
        // Windows opens the list over the box, the chosen row where the box is
        y: -Math.max(0, root.currentIndex) * 36 - 4
        width: Math.max(root.width, 160)
        height: Math.min(list.contentHeight + 8, 36 * 10 + 8)
        padding: 4
        modal: false
        focus: true
        closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: WinStyle.fast
            }
            NumberAnimation {
                property: "scale"
                from: 0.96
                to: 1
                duration: WinStyle.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: WinStyle.decelerate
            }
        }
        background: Rectangle {
            radius: 8
            color: WinStyle.menu
            border.width: 1
            border.color: WinStyle.flyoutLine
        }
        contentItem: ListView {
            id: list
            clip: true
            model: root.items
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                id: opt
                required property var modelData
                required property int index
                width: list.width
                height: 36
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 4
                    color: om.containsMouse ? WinStyle.subtleHover : opt.index === root.currentIndex ? WinStyle.subtlePress : "transparent"
                }
                Rectangle {
                    visible: opt.index === root.currentIndex
                    x: 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 16
                    radius: 1.5
                    color: WinStyle.accent
                }
                Text {
                    x: 14
                    width: parent.width - 24
                    anchors.verticalCenter: parent.verticalCenter
                    text: opt.modelData.label
                    elide: Text.ElideRight
                    color: WinStyle.text
                    font.family: WinStyle.font
                    font.pixelSize: 14
                    renderType: Text.NativeRendering
                }
                MouseArea {
                    id: om
                    anchors.fill: parent
                    hoverEnabled: true
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
