pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets
import qs.modules.bar
import "."

// Bar icon: leaf / scales / lightning. Click — menu, wheel — switch modes.
Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow

    implicitWidth: icon.implicitWidth + Theme.u * 4
    implicitHeight: Theme.u * 13

    PxIcon {
        id: icon
        anchors.centerIn: parent
        pixel: Theme.u
        opacity: mouse.containsMouse || popup.visible ? 1 : 0.8
        bitmap: PowerMode.current.bitmap
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: e => e.button === Qt.MiddleButton ? PowerMode.cycle() : popup.toggle()
        onWheel: w => PowerMode.step(w.angleDelta.y > 0 ? 1 : -1)
    }

    Connections {
        target: PowerMode
        function onMenuRequested() {
            popup.toggle();
        }
    }

    BarPopup {
        id: popup
        panelId: "power-mode"
        anchorItem: root
        above: Config.bar.style === "taskbar"
        title: "power.exe"
        icon: "power"
        contentWidth: Theme.u * 130
        contentHeight: list.implicitHeight

        Column {
            id: list
            width: parent.width
            spacing: Theme.u * 2

            Repeater {
                // by index: a Repeater would turn the bitmap rows into a QStringList, which PxIcon can't draw
                model: PowerMode.available.length
                PxButton {
                    id: row
                    required property int index
                    readonly property var modelData: PowerMode.available[index]
                    width: list.width
                    height: Theme.u * 20
                    checked: PowerMode.current.id === modelData.id
                    onClicked: PowerMode.set(modelData.id)

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.u * 5
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.u * 5
                        Item {
                            width: Theme.u * 11
                            height: Theme.u * 10
                            anchors.verticalCenter: parent.verticalCenter
                            PxIcon {
                                anchors.centerIn: parent
                                bitmap: row.modelData.bitmap
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            PxText {
                                text: row.modelData.name
                            }
                            PxText {
                                kind: "tiny"
                                dim: true
                                text: row.modelData.hint
                            }
                        }
                    }
                }
            }
            PxText {
                visible: PowerMode.degraded !== ""
                width: list.width
                wrapMode: Text.Wrap
                kind: "tiny"
                dim: true
                text: "⚠ производительность урезана: " + PowerMode.degraded
            }
        }
    }
}
