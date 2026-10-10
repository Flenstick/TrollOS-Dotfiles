pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Hover over a running app: its windows as cards above the button (niri does not
// share window pictures, so each card shows the app icon and the title).
// Click a card to go there, × closes that window.
PopupWindow {
    id: root

    required property Item anchorItem
    required property var taskbar
    property var entry: null
    property Item button: null
    readonly property var wins: {
        if (!entry)
            return [];
        // follow the live window list, the entry snapshot goes stale
        const k = entry.key;
        return Niri.sortedWindows(Niri.windows).filter(w => taskbar.keyOf(w.app_id) === k);
    }
    readonly property int pad: 24
    readonly property int cardW: 200
    readonly property int cardH: 132
    property bool overCards: false

    function hoverOn(btn, e) {
        leave.stop();
        if (visible && entry && entry.key === e.key)
            return;
        button = btn;
        entry = e;
        if (visible) {
            place();
            anchor.updateAnchor();
        } else
            enter.restart();
    }
    function hoverOff() {
        enter.stop();
        leave.restart();
    }
    function hideNow() {
        enter.stop();
        leave.stop();
        visible = false;
    }
    function place() {
        const p = button.mapToItem(anchorItem, 0, 0);
        anchor.rect.x = p.x + button.width / 2;
        anchor.rect.y = pad - 4;
    }
    Timer {
        id: enter
        interval: 450
        onTriggered: {
            if (PopupManager.active || !root.button)
                return;
            root.place();
            root.visible = true;
        }
    }
    Timer {
        id: leave
        interval: 280
        onTriggered: if (!root.overCards)
            root.visible = false
    }
    onWinsChanged: if (visible && wins.length === 0)
        visible = false

    anchor.item: anchorItem
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    anchor.adjustment: PopupAdjustment.Slide
    grabFocus: false
    visible: false
    color: "transparent"
    implicitWidth: frame.width + pad * 2
    implicitHeight: frame.height + pad * 2
    mask: Region {
        item: frame
    }
    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: frame
        radius: 8
    }

    property real reveal: 0
    onVisibleChanged: if (visible)
        revealAnim.restart()
    NumberAnimation {
        id: revealAnim
        target: root
        property: "reveal"
        from: 0
        to: 1
        duration: WinStyle.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: WinStyle.decelerate
    }

    RectangularShadow {
        anchors.fill: frame
        radius: 8
        blur: 24
        offset.y: 6
        color: WinStyle.shadow
        opacity: frame.opacity
    }
    Rectangle {
        id: frame
        x: root.pad
        y: root.pad + (1 - root.reveal) * 14
        width: row.width + 16
        height: root.cardH + 16
        radius: 8
        color: WinStyle.flyout
        border.width: 1
        border.color: WinStyle.flyoutLine
        opacity: Math.min(1, root.reveal * 1.5)

        HoverHandler {
            onHoveredChanged: {
                root.overCards = hovered;
                if (hovered)
                    leave.stop();
                else
                    leave.restart();
            }
        }

        Row {
            id: row
            x: 8
            y: 8
            spacing: 8
            Repeater {
                model: root.wins.slice(0, 6)
                Item {
                    id: card
                    required property var modelData
                    width: root.cardW
                    height: root.cardH
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: cardArea.containsMouse ? WinStyle.subtleHover : "transparent"
                        border.width: card.modelData.is_focused ? 1 : 0
                        border.color: WinStyle.controlLine
                    }
                    Row {
                        x: 10
                        y: 8
                        spacing: 8
                        width: parent.width - 20
                        AppIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            appId: card.modelData.app_id || ""
                            size: 16
                        }
                        WinText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 24 - (closeBtn.visible ? 28 : 0)
                            text: card.modelData.title || card.modelData.app_id || ""
                            font.pixelSize: WinStyle.caption
                        }
                    }
                    // stand-in for the window picture
                    Rectangle {
                        x: 10
                        y: 34
                        width: parent.width - 20
                        height: parent.height - 44
                        radius: 4
                        color: WinStyle.card
                        border.width: 1
                        border.color: WinStyle.controlLine
                        AppIcon {
                            anchors.centerIn: parent
                            appId: card.modelData.app_id || ""
                            size: 48
                        }
                    }
                    MouseArea {
                        id: cardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: m => {
                            if (m.button === Qt.MiddleButton)
                                Niri.closeWindow(card.modelData.id);
                            else {
                                Niri.focusWindow(card.modelData.id);
                                root.hideNow();
                            }
                        }
                    }
                    Rectangle {
                        id: closeBtn
                        visible: cardArea.containsMouse || closeArea.containsMouse
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        y: 4
                        width: 24
                        height: 24
                        radius: 4
                        color: closeArea.containsMouse ? "#c42b1c" : "transparent"
                        WinIcon {
                            anchors.centerIn: parent
                            name: "dismiss-regular"
                            size: 12
                        }
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Niri.closeWindow(card.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
