pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// TrollOS: desktop layouts (services/DesktopPresets) — a card each: its wallpaper with a little
// panel over it, its colours, what it is. «Применить» asks once: the wallpaper alive or a
// picture (on a laptop's battery the picture comes first). «Вернуть как было» undoes it all.
PxPage {
    id: page

    heading: I18n.t("Макеты", "Desktop looks")
    subtitle: I18n.t("Готовый вид системы одной кнопкой: цвета, панель, курсор, иконки и обои вместе. Всё прежнее запоминается — можно вернуть как было.", "A ready look in one click: colours, the panel, the cursor, icons and wallpaper together. What was there before is kept, so it can all come back.")

    property string asking: ""               // the card asking «alive or a picture?»

    PxGroup {
        name: "looks"
        width: parent.width
        title: I18n.t("Макеты", "Looks")
        icon: "sparkle"

        Grid {
            id: cards
            width: parent.width
            columns: width > Theme.u * 300 ? 3 : width > Theme.u * 180 ? 2 : 1
            spacing: Theme.u * 6
            readonly property real cardW: (width - spacing * (columns - 1)) / columns

            Repeater {
                model: DesktopPresets.presets
                delegate: PxBox {
                    id: card
                    required property var modelData
                    readonly property bool current: DesktopPresets.current === modelData.id
                    readonly property bool asking: page.asking === modelData.id
                    readonly property bool busy: DesktopPresets.busy === modelData.id
                    width: cards.cardW
                    height: body.implicitHeight + Theme.u * 8
                    sunken: current
                    color: current ? Theme.mix(Theme.face, Theme.accent, 0.18) : Theme.face

                    Column {
                        id: body
                        x: Theme.u * 4
                        y: Theme.u * 4
                        width: parent.width - Theme.u * 8
                        spacing: Theme.u * 3

                        // the look in small: its wallpaper, a panel in its colours along the bottom
                        Item {
                            width: parent.width
                            height: Math.round(width * 9 / 16)
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: "file://" + DesktopPresets.still(card.modelData)
                                sourceSize.width: 480
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                            }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: Math.max(Theme.u * 4, parent.height * 0.09)
                                color: card.modelData.swatch[0]
                                opacity: 0.92
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Theme.u * 2
                                    spacing: Theme.u * 2
                                    Repeater {
                                        model: 4
                                        delegate: Rectangle {
                                            required property int index
                                            width: Theme.u * 2
                                            height: Theme.u * 2
                                            radius: card.modelData.id === "void" ? width / 2 : 0
                                            color: index === 0 ? card.modelData.swatch[1] : card.modelData.swatch[3]
                                            opacity: index === 0 ? 1 : 0.45
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.u * 2
                                    width: Theme.u * 10
                                    height: Theme.u
                                    color: card.modelData.swatch[2]
                                    opacity: 0.8
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.width: Math.max(1, Theme.u / 2)
                                border.color: card.current ? Theme.accent : Theme.edge
                            }
                            PxText {
                                visible: card.current
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Theme.u * 2
                                text: I18n.t("сейчас", "now")
                                kind: "tiny"
                                color: card.modelData.swatch[3]
                            }
                        }

                        Row {
                            spacing: Theme.u
                            Repeater {
                                model: card.modelData.swatch
                                delegate: Rectangle {
                                    required property string modelData
                                    width: Theme.u * 5
                                    height: Theme.u * 3
                                    color: modelData
                                    border.width: 1
                                    border.color: Theme.edge
                                }
                            }
                        }
                        PxText {
                            width: parent.width
                            text: card.modelData.name
                            kind: "title"
                            elide: Text.ElideRight
                        }
                        PxText {
                            width: parent.width
                            text: card.modelData.about
                            wrapMode: Text.Wrap
                            dim: true
                            kind: "tiny"
                        }

                        // apply, or the one question before it
                        PxButton {
                            visible: !card.asking && !card.busy
                            enabled: !DesktopPresets.busy
                            accent: !card.current
                            text: card.current ? I18n.t("Применить заново", "Apply again") : I18n.t("Применить", "Apply")
                            icon: "sparkle"
                            onClicked: page.asking = card.modelData.id
                        }
                        Column {
                            visible: card.asking
                            width: parent.width
                            spacing: Theme.u * 2
                            PxText {
                                width: parent.width
                                wrapMode: Text.Wrap
                                text: I18n.t("Обои сделать живыми?", "Make the wallpaper alive?")
                            }
                            PxText {
                                width: parent.width
                                wrapMode: Text.Wrap
                                dim: true
                                kind: "tiny"
                                text: DesktopPresets.preferStill ? I18n.t("Ноутбук сейчас от батареи — живые обои немного её едят. Двигаются, только когда на столе нет окон.", "The laptop is on its battery now — live wallpaper eats a little of it. They move only while the desk has no windows.") : I18n.t("Двигаются, только когда на столе нет окон; в играх и на весь экран стоят.", "They move only while the desk has no windows; in games and fullscreen they stand still.")
                            }
                            Flow {
                                width: parent.width
                                spacing: Theme.u * 2
                                PxButton {
                                    accent: !DesktopPresets.preferStill
                                    text: I18n.t("Живые ✦", "Alive ✦")
                                    onClicked: {
                                        page.asking = "";
                                        DesktopPresets.apply(card.modelData.id, true);
                                    }
                                }
                                PxButton {
                                    accent: DesktopPresets.preferStill
                                    text: I18n.t("Картинка", "A picture")
                                    onClicked: {
                                        page.asking = "";
                                        DesktopPresets.apply(card.modelData.id, false);
                                    }
                                }
                                PxButton {
                                    flat: true
                                    text: I18n.t("Отмена", "Cancel")
                                    onClicked: page.asking = ""
                                }
                            }
                        }
                        PxText {
                            visible: card.busy
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: DesktopPresets.step || I18n.t("Применяю…", "Applying…")
                        }
                    }
                }
            }
        }

        PxText {
            visible: DesktopPresets.error !== ""
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.danger
            text: I18n.t("Не всё получилось (остальное применено): ", "Not everything worked (the rest is applied): ") + DesktopPresets.error
        }

        SettingRow {
            visible: DesktopPresets.canRestore
            label: I18n.t("Вернуть как было", "Put it all back")
            hint: I18n.t("цвета, панель, курсор, иконки, обои и плагины — как до первого макета", "Colours, the panel, cursor, icons, wallpaper and plugins as before the first look")
            PxButton {
                text: DesktopPresets.busy === "restore" ? (DesktopPresets.step || I18n.t("Возвращаю…", "Putting it back…")) : I18n.t("Вернуть", "Put back")
                icon: "refresh"
                enabled: !DesktopPresets.busy
                onClicked: DesktopPresets.restore()
            }
        }
        SettingRow {
            label: I18n.t("Живые обои", "Live wallpaper")
            hint: I18n.t("у макетов: туманность, луна с мышами, звёзды; выключено — просто картинка", "The looks' own: the nebula, the moon with bats, the stars; off is just the picture")
            PxToggle {
                checked: Config.wallpaper.shaders
                onToggled: v => Config.wallpaper.shaders = v
            }
        }
    }
}
