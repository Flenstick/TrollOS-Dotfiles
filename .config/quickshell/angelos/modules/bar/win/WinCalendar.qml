pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Clock / bell flyout: notification centre on top, the month calendar below,
// like Windows 11 (two stacked acrylic cards).
WinFlyout {
    id: root

    flyoutWidth: 360
    place: "right"
    panelId: "win-calendar"
    readonly property int notifH: Math.min(420, 56 + (Notifs.history.length ? Math.min(Notifs.history.length, 4) * 86 : 64))
    readonly property int calH: 404
    contentHeight: notifH + 12 + calH
    onOpened: {
        month = new Date(today.getFullYear(), today.getMonth(), 1);
        Notifs.markRead();
    }

    // two stacked cards instead of one frame
    plain: true
    cardA: notifCard
    cardB: calCard

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    readonly property date today: clock.date
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)

    // ---- notifications ----
    RectangularShadow {
        anchors.fill: notifCard
        radius: 8
        blur: 28
        offset.y: 8
        color: WinStyle.shadow
    }
    RectangularShadow {
        anchors.fill: calCard
        radius: 8
        blur: 28
        offset.y: 8
        color: WinStyle.shadow
    }
    Rectangle {
        id: notifCard
        width: root.flyoutWidth
        height: root.notifH
        radius: 8
        color: WinStyle.flyout
        border.width: 1
        border.color: WinStyle.flyoutLine
        clip: true

        WinText {
            x: 16
            y: 16
            text: I18n.t("Уведомления", "Notifications")
            strong: true
        }
        Rectangle {
            visible: Notifs.history.length > 0
            anchors.right: parent.right
            anchors.rightMargin: 12
            y: 12
            width: clearText.implicitWidth + 20
            height: 28
            radius: 4
            color: cma.containsMouse ? WinStyle.controlHover : WinStyle.control
            border.width: 1
            border.color: WinStyle.controlLine
            WinText {
                id: clearText
                anchors.centerIn: parent
                text: I18n.t("Очистить все", "Clear all")
                font.pixelSize: WinStyle.caption
            }
            MouseArea {
                id: cma
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Notifs.clearHistory()
            }
        }
        WinText {
            visible: Notifs.history.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: 64
            text: I18n.t("Нет новых уведомлений", "No new notifications")
            color: WinStyle.text2
        }
        ListView {
            x: 8
            y: 52
            width: parent.width - 16
            height: parent.height - 60
            clip: true
            spacing: 6
            model: Notifs.history
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: n
                required property var modelData
                width: ListView.view.width
                height: 80
                radius: 6
                color: nma.containsMouse ? WinStyle.controlHover : WinStyle.card
                border.width: 1
                border.color: WinStyle.controlLine
                Row {
                    x: 12
                    y: 10
                    spacing: 8
                    Image {
                        width: 16
                        height: 16
                        sourceSize: Qt.size(32, 32)
                        source: {
                            const i = n.modelData.icon || "";
                            return i.startsWith("/") ? "file://" + i : i.includes("://") ? i : i ? Quickshell.iconPath(i, true) : "";
                        }
                    }
                    WinText {
                        text: n.modelData.appName || "angelOS"
                        font.pixelSize: WinStyle.caption
                        color: WinStyle.text2
                    }
                }
                WinText {
                    anchors.right: parent.right
                    anchors.rightMargin: 36
                    y: 10
                    text: Qt.formatTime(new Date(n.modelData.time), "HH:mm")
                    font.pixelSize: WinStyle.caption
                    color: WinStyle.text3
                }
                WinText {
                    x: 12
                    y: 32
                    width: parent.width - 24
                    text: n.modelData.summary
                    strong: true
                }
                WinText {
                    x: 12
                    y: 52
                    width: parent.width - 24
                    text: String(n.modelData.body || "").replace(/<[^>]*>/g, "")
                    color: WinStyle.text2
                    font.pixelSize: WinStyle.caption
                }
                MouseArea {
                    id: nma
                    anchors.fill: parent
                    hoverEnabled: true
                }
                Rectangle {
                    visible: nma.containsMouse || xma.containsMouse
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    y: 6
                    width: 24
                    height: 24
                    radius: 4
                    color: xma.containsMouse ? WinStyle.subtleHover : "transparent"
                    WinIcon {
                        anchors.centerIn: parent
                        name: "dismiss-regular"
                        size: 12
                    }
                    MouseArea {
                        id: xma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Notifs.removeHistory(n.modelData.hid)
                    }
                }
            }
        }
    }

    // ---- calendar ----
    Rectangle {
        id: calCard
        y: root.notifH + 12
        width: root.flyoutWidth
        height: root.calH
        radius: 8
        color: WinStyle.flyout
        border.width: 1
        border.color: WinStyle.flyoutLine
        clip: true

        WinText {
            x: 16
            y: 0
            height: 48
            text: {
                const s = Qt.locale().toString(root.today, "dddd, d MMMM");
                return s.charAt(0).toUpperCase() + s.slice(1);
            }
            strong: true
        }
        Rectangle {
            y: 48
            width: parent.width
            height: 1
            color: WinStyle.divider
        }
        WinText {
            x: 16
            y: 56
            height: 40
            text: {
                const s = Qt.locale().standaloneMonthName(root.month.getMonth()) + " " + root.month.getFullYear();
                return s.charAt(0).toUpperCase() + s.slice(1);
            }
            strong: true
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            y: 60
            Repeater {
                model: [-1, 1]
                Rectangle {
                    required property int modelData
                    width: 32
                    height: 32
                    radius: 4
                    color: ama.containsMouse ? WinStyle.subtleHover : "transparent"
                    WinIcon {
                        anchors.centerIn: parent
                        name: "chevron_up-regular"
                        size: 12
                        rotation: parent.modelData > 0 ? 180 : 0
                    }
                    MouseArea {
                        id: ama
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() + parent.modelData, 1)
                    }
                }
            }
        }

        Grid {
            id: days
            x: 14
            y: 100
            columns: 7
            readonly property int first: (root.month.getDay() + 6) % 7          // Monday first
            readonly property date start: new Date(root.month.getFullYear(), root.month.getMonth(), 1 - first)
            Repeater {
                model: 7
                WinText {
                    required property int index
                    width: 47
                    height: 36
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((index + 1) % 7, Locale.ShortFormat).slice(0, 2)
                    font.pixelSize: WinStyle.caption
                    strong: true
                }
            }
            Repeater {
                model: 42
                Item {
                    id: cell
                    required property int index
                    readonly property date d: new Date(days.start.getFullYear(), days.start.getMonth(), days.start.getDate() + index)
                    readonly property bool inMonth: d.getMonth() === root.month.getMonth()
                    readonly property bool isToday: d.toDateString() === root.today.toDateString()
                    width: 47
                    height: 40
                    Rectangle {
                        anchors.centerIn: parent
                        width: 38
                        height: 38
                        radius: 19
                        color: cell.isToday ? (dma.containsMouse ? WinStyle.accentHover : WinStyle.accent) : dma.containsMouse ? WinStyle.subtleHover : "transparent"
                    }
                    WinText {
                        anchors.centerIn: parent
                        text: cell.d.getDate()
                        color: cell.isToday ? WinStyle.onAccent : cell.inMonth ? WinStyle.text : WinStyle.text3
                        strong: cell.isToday
                    }
                    MouseArea {
                        id: dma
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }
    }
}
