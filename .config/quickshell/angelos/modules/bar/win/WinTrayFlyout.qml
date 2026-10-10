pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.config
import qs.services
import qs.widgets

// The ^ flyout of hidden tray icons.
WinFlyout {
    id: root

    required property var menu             // WinMenu for the icons' own menus
    readonly property var items: SystemTray.items.values
    readonly property int cols: Math.min(5, Math.max(1, items.length))
    flyoutWidth: cols * 40 + 16
    contentHeight: Math.ceil(items.length / cols) * 40 + 16
    place: "center"
    panelId: "win-tray"

    Grid {
        x: 8
        y: 8
        columns: root.cols
        Repeater {
            model: SystemTray.items
            Rectangle {
                id: cell
                required property var modelData
                width: 40
                height: 40
                radius: 4
                color: ma.pressed ? WinStyle.subtlePress : ma.containsMouse ? WinStyle.subtleHover : "transparent"
                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    sourceSize: Qt.size(32, 32)
                    source: cell.modelData.icon
                    smooth: true
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: m => {
                        if (m.button === Qt.MiddleButton)
                            cell.modelData.secondaryActivate();
                        else if (m.button === Qt.RightButton || cell.modelData.onlyMenu) {
                            if (cell.modelData.hasMenu)
                                root.menu.openTray(root.button, cell.modelData.menu);
                        } else {
                            cell.modelData.activate();
                            root.hide();
                        }
                    }
                    onWheel: w => cell.modelData.scroll(w.angleDelta.y, false)
                }
            }
        }
    }
}
