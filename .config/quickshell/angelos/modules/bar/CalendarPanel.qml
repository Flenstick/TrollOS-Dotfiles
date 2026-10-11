pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Month grid + notification history.
BarPopup {
    id: root
    signal burnAll   // TrollOS Inferno: «очистить» — все уведомления сгорают каскадом

    title: I18n.exe(I18n.t("календарь", "calendar"))
    panelId: "calendar"                  // `angelos panel calendar`, a gesture (services/Gestures)
    icon: "calendar"
    contentWidth: Theme.u * 170
    contentHeight: Theme.u * 250

    property date month: new Date()
    onVisibleChanged: if (visible) {
        month = new Date();
        Notifs.markRead();
    }

    readonly property var days: {
        const first = new Date(month.getFullYear(), month.getMonth(), 1);
        const offset = (first.getDay() + 6) % 7;
        const count = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < offset; i++)
            out.push(0);
        for (let d = 1; d <= count; d++)
            out.push(d);
        return out;
    }

    Column {
        anchors.fill: parent
        spacing: Theme.u * 4

        Row {
            width: parent.width
            PxButton {
                compact: true
                icon: "arrowLeft"
                onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() - 1, 1)
            }
            PxText {
                width: parent.width - Theme.u * 30
                horizontalAlignment: Text.AlignHCenter
                kind: "title"
                text: I18n.locale.standaloneMonthName(root.month.getMonth()) + " " + root.month.getFullYear()
            }
            PxButton {
                compact: true
                icon: "arrowRight"
                onClicked: root.month = new Date(root.month.getFullYear(), root.month.getMonth() + 1, 1)
            }
        }

        Grid {
            id: grid
            columns: 7
            width: parent.width
            readonly property int cell: Math.floor(width / 7)
            Repeater {
                model: [I18n.t("пн", "Mon"), I18n.t("вт", "Tue"), I18n.t("ср", "Wed"), I18n.t("чт", "Thu"), I18n.t("пт", "Fri"), I18n.t("сб", "Sat"), I18n.t("вс", "Sun")]
                PxText {
                    required property string modelData
                    width: grid.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    dim: true
                }
            }
            Repeater {
                model: root.days
                Item {
                    id: day
                    required property int modelData
                    readonly property var now: new Date()
                    readonly property bool today: modelData === now.getDate() && root.month.getMonth() === now.getMonth() && root.month.getFullYear() === now.getFullYear()
                    width: grid.cell
                    height: Theme.u * 11
                    // TrollOS Inferno: сегодня — перевёрнутая пентаграмма вместо сердечка
                    // TrollOS: the «Material You» skin — today a primary circle
                    Rectangle {
                        visible: day.today && Theme.settingsSkinFor(parent) === "material"
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height, Theme.mdPx(32))
                        height: width
                        radius: width / 2
                        color: Theme.md.primary
                    }
                    PxIcon {
                        visible: day.today && Theme.settingsSkinFor(parent) !== "material"
                        anchors.centerIn: parent
                        name: Theme.infernoLook ? "pentagramInv" : "heart"
                        pixel: Theme.infernoLook ? Theme.u : Theme.u + 1
                        ink: Theme.infernoLook ? Theme.mix(Theme.accent, Theme.edge, 0.3) : Theme.edge
                        fill: Theme.accent
                        opacity: Theme.infernoLook ? 0.85 : 1
                    }
                    PxText {
                        anchors.centerIn: parent
                        visible: day.modelData > 0
                        text: day.modelData
                        readonly property bool md: Theme.settingsSkinFor(parent) === "material"
                        color: day.today ? (md ? Theme.md.onPrimary : "#ffffff") : Theme.text
                        font.bold: day.today
                        style: day.today && !md ? Text.Outline : Text.Normal
                        styleColor: Theme.edge
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: Theme.u * 3
            PxText {
                kind: "title"
                text: I18n.t("Уведомления", "Notifications")
                width: parent.width - dnd.width - clear.width - Theme.u * 6
            }
            PxToggle {
                id: dnd
                text: I18n.t("тихо", "Quiet")
                checked: Config.notifications.dnd
                onToggled: c => Config.notifications.dnd = c
            }
            PxButton {
                id: clear
                compact: true
                icon: "trash"
                // TrollOS Inferno: сначала всё сгорает каскадом, потом очищается
                onClicked: {
                    if (Notifs.history.length === 0)
                        return;
                    root.burnAll();
                    clearLater.interval = 520 + Math.min(Notifs.history.length, 12) * 70;
                    clearLater.restart();
                }
                Timer {
                    id: clearLater
                    onTriggered: Notifs.clearHistory()
                }
            }
        }

        PxBox {
            width: parent.width
            height: parent.height - y
            sunken: true
            color: Qt.alpha(Theme.sunken, 0.7)

            PxScroll {
                anchors.fill: parent
                anchors.margins: Theme.u * 2
                contentHeight: list.implicitHeight

                Column {
                    id: list
                    width: parent.width
                    spacing: Theme.u * 2
                    PxText {
                        visible: Notifs.history.length === 0
                        text: I18n.t("  никто не пишет… ⛧", "  No activity… ⛧")
                        dim: true
                        height: Theme.u * 20
                    }
                    Repeater {
                        model: Notifs.history
                        Item {
                            id: h
                            required property var modelData
                            required property int index
                            width: list.width
                            // сгорание: огненная кромка слева направо, за ней пепел, потом схлопывание
                            property real burn: 0
                            property real collapse: 0
                            property bool dying: false
                            height: (hcol.implicitHeight + Theme.u * 6) * (1 - collapse)
                            clip: dying
                            function burnAway(delay, remove) {
                                if (dying)
                                    return;
                                dying = true;
                                burnAnim.delay = delay;
                                burnAnim.remove = remove;
                                burnAnim.restart();
                            }
                            Connections {
                                target: root
                                function onBurnAll() {
                                    h.burnAway(Math.min(h.index, 12) * 70, false);
                                }
                            }
                            SequentialAnimation {
                                id: burnAnim
                                property int delay: 0
                                property bool remove: true
                                PauseAnimation { duration: burnAnim.delay }
                                NumberAnimation { target: h; property: "burn"; from: 0; to: 1; duration: 380; easing.type: Easing.InQuad }
                                NumberAnimation { target: h; property: "collapse"; to: 1; duration: 140; easing.type: Easing.InCubic }
                                ScriptAction { script: if (burnAnim.remove) Notifs.removeHistory(h.modelData.hid) }
                            }
                            Rectangle {
                                anchors.fill: parent
                                color: hm.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.12) : "transparent"
                            }
                            AppIcon {
                                id: hicon
                                x: Theme.u * 2
                                y: Theme.u * 3
                                iconName: h.modelData.icon || ""
                                size: Theme.u * 10
                            }
                            Column {
                                id: hcol
                                x: hicon.width + Theme.u * 5
                                y: Theme.u * 3
                                width: parent.width - x - Theme.u * 12
                                PxText {
                                    width: parent.width
                                    text: h.modelData.summary
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                PxText {
                                    width: parent.width
                                    text: Notifs.safeMarkup(h.modelData.body)
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    dim: true
                                }
                                PxText {
                                    text: h.modelData.appName + " · " + Qt.formatTime(new Date(h.modelData.time), "HH:mm")
                                    kind: "tiny"
                                    dim: true
                                }
                            }
                            MouseArea {
                                id: hm
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: h.burnAway(0, true)
                            }
                            // пепел за кромкой
                            Rectangle {
                                visible: h.burn > 0
                                width: h.width * h.burn
                                height: h.height
                                color: Theme.mix(Theme.sunken, Theme.face, 0.4)
                                opacity: 0.96
                            }
                            // огненная кромка
                            Rectangle {
                                visible: h.burn > 0 && h.burn < 1
                                x: h.width * h.burn - width + 6
                                width: Theme.u * 10
                                height: h.height
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.55; color: Theme.accent }
                                    GradientStop { position: 0.85; color: Theme.accent3 }
                                    GradientStop { position: 1.0; color: "#ffe2a0" }
                                }
                            }
                            // угольки взлетают от кромки
                            Repeater {
                                model: 7
                                Rectangle {
                                    required property int index
                                    readonly property real t: Math.max(0, Math.min(1, h.burn * 1.4 - index * 0.06))
                                    visible: h.burn > 0 && h.burn < 1 && t > 0
                                    width: index % 3 === 0 ? Theme.u * 2 : Theme.u
                                    height: width
                                    color: index % 2 ? Theme.accent3 : Theme.accent
                                    x: h.width * h.burn - Theme.u * 3 + (index % 4) * Theme.u
                                    y: h.height * (0.15 + 0.7 * ((index * 37) % 10) / 10) - t * Theme.u * 8
                                    opacity: 1 - t * 0.6
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
