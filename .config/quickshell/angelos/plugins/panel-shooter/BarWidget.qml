import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar
import "."
import "Sprites.js" as Sprites

// Pistol next to the tray (targets: Discord friends from friend-runner): click opens the case, right click grabs/holsters
// the gun right away. While armed it shows the rounds left in the magazine.
Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow

    implicitWidth: row.implicitWidth + Theme.u * 6
    implicitHeight: Theme.u * 13

    PxBox {
        anchors.fill: parent
        visible: mouse.containsMouse || Gun.armed || Gun.geiger || popup.visible
        sunken: Gun.armed || Gun.geiger || mouse.pressed
        color: Gun.armed ? Theme.mix(Theme.face, Theme.danger, Theme.dark ? 0.45 : 0.3) : Gun.geiger ? Theme.mix(Theme.face, "#5dbf3a", Theme.dark ? 0.4 : 0.3) : Theme.mix(Theme.face, Theme.accent, 0.12)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.u * 2

        PxIcon {
            visible: Gun.geiger
            anchors.verticalCenter: parent.verticalCenter
            bitmap: Sprites.GEIGER
            pixel: Theme.u
            ink: "#15161a"
            fill: "#f2c230"
            fill2: "#1b2a17"
            fill3: "#3fbf3f"
            body: "#9aa1ad"
            light: "#d8dde6"
            bad: "#ff3a2a"
        }
        PxIcon {
            visible: !Gun.geiger
            anchors.verticalCenter: parent.verticalCenter
            bitmap: Sprites.GUN
            pixel: Theme.u
            ink: Theme.dark ? Theme.text : Theme.edge
            body: Theme.dark ? Theme.faceAlt : "#5b5f69"
            light: Theme.dark ? Theme.textDim : "#9aa1ad"
        }
        Row {
            visible: Gun.armed
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Theme.u / 2)
            Repeater {
                model: Gun.magSize
                Rectangle {
                    required property int index
                    width: Theme.u
                    height: Theme.u * 4
                    color: index < Gun.ammo ? "#e8c46a" : Qt.alpha(Theme.textDim, 0.3)
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            if (m.button === Qt.RightButton)
                Gun.toggle();
            else
                popup.toggle();
        }
    }

    BarPopup {
        id: popup
        panelId: "panel-shooter"
        anchorItem: root
        above: Config.bar.style === "taskbar"
        title: I18n.exe(I18n.t("тир", "range"))
        icon: "gamepad"
        contentWidth: Theme.u * 140
        contentHeight: Theme.u * 130

        Column {
            anchors.fill: parent
            anchors.margins: Theme.u * 4
            spacing: Theme.u * 4

            // the case: the pistol and the Geiger counter (click one to take it)
            PxBox {
                width: parent.width
                height: Theme.u * 42
                sunken: true
                color: Theme.dark ? "#2a1d16" : "#6e4a33"

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.u * 8

                    Item {
                        width: caseGun.width + Theme.u * 10
                        height: caseGeiger.height + Theme.u * 8
                        Rectangle {
                            anchors.centerIn: parent
                            width: caseGun.width + Theme.u * 10
                            height: caseGun.height + Theme.u * 8
                            color: gunSlot.containsMouse ? "#a4303f" : Theme.dark ? "#4a1820" : "#8c2232"
                            border.width: Theme.u
                            border.color: Qt.darker(color, 1.4)
                            visible: !Gun.armed
                        }
                        PxIcon {
                            id: caseGun
                            visible: !Gun.armed
                            anchors.centerIn: parent
                            bitmap: Sprites.GUN
                            pixel: Theme.u * 3
                            ink: "#15161a"
                            body: "#3d4049"
                            light: "#9aa1ad"
                        }
                        PxText {
                            visible: Gun.armed
                            anchors.centerIn: parent
                            text: I18n.t("пусто", "empty")
                            color: "#d9c3a8"
                            kind: "tiny"
                        }
                        MouseArea {
                            id: gunSlot
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Gun.toggle();
                                if (Gun.armed)
                                    popup.toggle();
                            }
                        }
                    }

                    Item {
                        width: caseGeiger.width + Theme.u * 10
                        height: caseGeiger.height + Theme.u * 8
                        Rectangle {
                            anchors.fill: parent
                            color: geigerSlot.containsMouse ? "#2c5a2a" : Theme.dark ? "#1c3320" : "#2f5a35"
                            border.width: Theme.u
                            border.color: Qt.darker(color, 1.4)
                            visible: !Gun.geiger
                        }
                        PxIcon {
                            id: caseGeiger
                            visible: !Gun.geiger
                            anchors.centerIn: parent
                            bitmap: Sprites.GEIGER
                            pixel: Theme.u * 3
                            ink: "#15161a"
                            fill: "#f2c230"
                            fill2: "#1b2a17"
                            fill3: "#3fbf3f"
                            body: "#9aa1ad"
                            light: "#d8dde6"
                            bad: "#ff3a2a"
                        }
                        PxText {
                            visible: Gun.geiger
                            anchors.centerIn: parent
                            text: I18n.t("пусто", "empty")
                            color: "#d9c3a8"
                            kind: "tiny"
                        }
                        MouseArea {
                            id: geigerSlot
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Gun.toggleGeiger();
                                if (Gun.geiger)
                                    popup.toggle();
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: Theme.u * 3
                PxButton {
                    width: (parent.width - parent.spacing) / 2
                    accent: !Gun.armed
                    icon: Gun.armed ? "close" : "gamepad"
                    text: Gun.armed ? I18n.t("Убрать пистолет", "Holster") : I18n.t("Взять пистолет", "Take the pistol")
                    onClicked: {
                        Gun.toggle();
                        if (Gun.armed)
                            popup.toggle();
                    }
                }
                PxButton {
                    width: (parent.width - parent.spacing) / 2
                    accent: !Gun.geiger
                    icon: Gun.geiger ? "close" : "gauge"
                    text: Gun.geiger ? I18n.t("Убрать счётчик", "Put it away") : I18n.t("Счётчик Гейгера", "Geiger counter")
                    onClicked: {
                        Gun.toggleGeiger();
                        if (Gun.geiger)
                            popup.toggle();
                    }
                }
            }

            Row {
                width: parent.width
                spacing: Theme.u * 3
                PxButton {
                    width: (parent.width - parent.spacing) / 2
                    icon: "plus"
                    text: I18n.t("Тестовый друг", "Test friend")
                    onClicked: Shell.sh("qs -c angelos ipc call friends test")
                }
                PxButton {
                    width: (parent.width - parent.spacing) / 2
                    icon: "gear"
                    text: I18n.t("Настройки", "Settings")
                    onClicked: {
                        popup.toggle();
                        Shell.openSettings("plugin:panel-shooter");
                    }
                }
            }

            Grid {
                columns: 2
                columnSpacing: Theme.u * 8
                rowSpacing: Theme.u
                PxText {
                    dim: true
                    text: I18n.t("Всего убито", "Total kills")
                }
                PxText {
                    font.bold: true
                    text: Gun.totalKills
                }
                PxText {
                    dim: true
                    text: I18n.t("Хедшотов", "Headshots")
                }
                PxText {
                    font.bold: true
                    text: Gun.totalHeadshots
                }
                PxText {
                    dim: true
                    text: I18n.t("Меткость (сейчас)", "Accuracy (session)")
                }
                PxText {
                    font.bold: true
                    text: Gun.shots ? Math.round(100 * Gun.hits / Gun.shots) + "%  (" + Gun.hits + "/" + Gun.shots + ")" : "—"
                }
            }

            PxText {
                width: parent.width
                wrapMode: Text.WordWrap
                kind: "tiny"
                dim: true
                text: I18n.t("Стреляй по друзьям, которые выбегают из Discord. ЛКМ — огонь · ПКМ или R — перезарядка · Esc — убрать. ПКМ по этой кнопке — быстро взять/убрать. Счётчиком Гейгера води по окнам и столу: фонят приложения, а где-то спрятаны три изотопа.", "Shoot the friends running out of Discord. LMB fires · RMB or R reloads · Esc holsters. Right-click this button to grab/holster quickly. Sweep windows and the desktop with the Geiger counter: apps glow, and three isotopes are hidden somewhere.")
            }
        }
    }
}
