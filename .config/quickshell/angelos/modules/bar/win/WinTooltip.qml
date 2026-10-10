import QtQuick
import Quickshell
import qs.services

// Windows tooltip: small rounded card above the hovered taskbar button.
PopupWindow {
    id: root
    required property Item anchorItem
    property string text: ""
    anchor.item: anchorItem
    anchor.rect.x: anchorItem.width / 2
    anchor.rect.y: 0
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    anchor.adjustment: PopupAdjustment.Slide
    grabFocus: false
    color: "transparent"
    visible: false
    implicitWidth: box.width
    implicitHeight: box.height + 8
    mask: Region {}
    onVisibleChanged: if (visible) fade.restart()

    Rectangle {
        id: box
        width: Math.min(360, label.implicitWidth + 18)
        height: label.implicitHeight + 12
        radius: 4
        color: WinStyle.menu
        border.width: 1
        border.color: WinStyle.flyoutLine
        WinText {
            id: label
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 342)
            text: root.text
            font.pixelSize: WinStyle.caption
        }
        NumberAnimation on opacity {
            id: fade
            from: 0
            to: 1
            duration: WinStyle.fast
        }
    }
}
