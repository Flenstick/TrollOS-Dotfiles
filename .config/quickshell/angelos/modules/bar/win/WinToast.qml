pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.widgets

// Windows 11 toast: acrylic card at the bottom right that slides in from the
// screen edge; app line on top, picture, title, text, Fluent action buttons.
Item {
    id: root

    required property var notification
    readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical
    readonly property int timeout: critical ? 0 : (notification && notification.expireTimeout > 0 ? notification.expireTimeout : Config.notifications.timeout)
    readonly property string img: Notifs.iconFor(notification)
    readonly property alias cardItem: card
    width: 364
    implicitHeight: card.height

    // slide in from the right edge
    property real slide: 1
    Component.onCompleted: inAnim.start()
    NumberAnimation {
        id: inAnim
        target: root
        property: "slide"
        from: 1
        to: 0
        duration: WinStyle.slow + 60
        easing.type: Easing.BezierSpline
        easing.bezierCurve: WinStyle.decelerate
    }

    property int elapsed: 0
    Timer {
        interval: 100
        repeat: true
        running: root.timeout > 0 && !hover.hovered
        onTriggered: {
            root.elapsed += interval;
            if (root.elapsed >= root.timeout)
                Notifs.dismissPopup(root.notification);
        }
    }
    HoverHandler {
        id: hover
    }

    RectangularShadow {
        anchors.fill: card
        radius: 8
        blur: 24
        offset.y: 6
        color: WinStyle.shadow
        opacity: card.opacity
    }
    Rectangle {
        id: card
        x: root.slide * (root.width + 40)
        width: root.width
        height: col.implicitHeight + 28
        radius: 8
        color: WinStyle.flyout
        border.width: 1
        border.color: WinStyle.flyoutLine
        opacity: 1 - root.slide * 0.6

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => {
                if (m.button === Qt.RightButton) {
                    Notifs.close(root.notification);
                    return;
                }
                const def = root.notification.actions.find(a => a.identifier === "default");
                if (def)
                    def.invoke();
                Notifs.dismissPopup(root.notification);
            }
        }

        Column {
            id: col
            x: 16
            y: 12
            width: parent.width - 32
            spacing: 10

            Row {
                spacing: 8
                width: parent.width
                AppIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 16
                    readonly property var n: root.notification
                    iconName: n && n.appIcon && !n.appIcon.startsWith("/") ? n.appIcon : ""
                    appId: n ? (n.desktopEntry || n.appName || "") : ""
                }
                WinText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 100
                    text: root.notification ? (root.notification.appName || "angelOS") : ""
                    font.pixelSize: WinStyle.caption
                    color: WinStyle.text
                }
            }
            Row {
                width: parent.width
                spacing: 12
                // app logo / sender picture, round like Windows crops it
                Item {
                    id: pic
                    visible: root.img !== ""
                    width: 48
                    height: 48
                    Image {
                        id: picImg
                        anchors.fill: parent
                        source: root.img
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(96, 96)
                        asynchronous: true
                        visible: false
                    }
                    Rectangle {
                        id: picMask
                        anchors.fill: parent
                        radius: 24
                        visible: false
                        layer.enabled: true
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: picImg
                        maskEnabled: true
                        maskSource: picMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1
                    }
                }
                Column {
                    width: parent.width - (pic.visible ? 60 : 0)
                    anchors.verticalCenter: pic.visible ? pic.verticalCenter : undefined
                    spacing: 2
                    WinText {
                        width: parent.width
                        text: root.notification ? root.notification.summary : ""
                        strong: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        color: root.critical ? "#ff99a4" : WinStyle.text
                    }
                    WinText {
                        width: parent.width
                        visible: text !== ""
                        text: root.notification ? Notifs.safeMarkup(root.notification.body) : ""
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        color: WinStyle.text2
                        linkColor: WinStyle.accent
                        onLinkActivated: l => Notifs.openLink(l)
                    }
                }
            }
            Row {
                visible: root.notification && root.notification.actions.filter(a => a.identifier !== "default").length > 0
                width: parent.width
                spacing: 8
                Repeater {
                    model: root.notification ? root.notification.actions.filter(a => a.identifier !== "default") : []
                    Rectangle {
                        id: ab
                        required property var modelData
                        required property int index
                        readonly property int n: Math.max(1, root.notification.actions.filter(a => a.identifier !== "default").length)
                        width: (col.width - (n - 1) * 8) / n
                        height: 32
                        radius: 4
                        color: index === 0 ? (am.containsMouse ? WinStyle.accentHover : WinStyle.accent) : am.containsMouse ? WinStyle.controlHover : WinStyle.control
                        border.width: 1
                        border.color: WinStyle.controlLine
                        WinText {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            horizontalAlignment: Text.AlignHCenter
                            text: ab.modelData.text || ab.modelData.identifier
                            color: ab.index === 0 ? WinStyle.onAccent : WinStyle.text
                        }
                        MouseArea {
                            id: am
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                ab.modelData.invoke();
                                Notifs.dismissPopup(root.notification);
                            }
                        }
                    }
                }
            }
        }

        // ⋯ (notification settings) and × in the header, on hover like Windows
        Row {
            visible: hover.hovered
            anchors.right: parent.right
            anchors.rightMargin: 8
            y: 6
            spacing: 2
            Repeater {
                model: ["more", "close"]
                Rectangle {
                    id: hb
                    required property string modelData
                    width: 32
                    height: 28
                    radius: 4
                    color: hbm.containsMouse ? WinStyle.subtleHover : "transparent"
                    WinText {
                        visible: hb.modelData === "more"
                        anchors.centerIn: parent
                        text: "⋯"
                        font.pixelSize: 14
                    }
                    WinIcon {
                        visible: hb.modelData === "close"
                        anchors.centerIn: parent
                        name: "dismiss-regular"
                        size: 12
                    }
                    MouseArea {
                        id: hbm
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (hb.modelData === "close")
                                Notifs.close(root.notification);
                            else {
                                Notifs.dismissPopup(root.notification);
                                Shell.openSettings("notifications");
                            }
                        }
                    }
                }
            }
        }
    }
}
