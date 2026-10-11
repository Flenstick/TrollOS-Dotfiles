pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// TrollOS: Material You's own settings (config/MaterialColor.js, services/MaterialYou): the
// accent the scheme grows from, the palette style, light or dark, corners, the font, the icons,
// the panel — the «Material You» desktop layout (Settings → Макеты) turns the look on.
PxPage {
    id: page

    heading: "Material You"
    subtitle: I18n.t("Всё оформление растёт из одного акцентного цвета — как в Android 12 и новее.", "The whole look grows from one accent colour — like Android 12 and later.")

    readonly property var m: Config.material
    readonly property var md: Theme.md
    readonly property bool active: MaterialYou.on
    // Android's own seeds and a few more
    readonly property var seeds: ["#6750a4", "#b3261e", "#e46f1b", "#c9a227", "#386a20", "#006a6a", "#0061a4", "#7d5260", "#5b5f97", "#984061", "#3d6373", "#6b5e4e"]

    PxGroup {
        name: "look"
        title: I18n.t("Макет", "The look")
        icon: "sparkle"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            visible: !page.active
            text: I18n.t("Сейчас Material You выключен. Включи его в «Макеты» → Material You — тогда всё ниже сразу видно на всей системе.", "Material You is off now. Turn it on under «Desktop looks» → Material You — then everything below shows on the whole system at once.")
        }
        Row {
            spacing: Theme.u * 3
            PxButton {
                visible: !page.active
                accent: true
                icon: "sparkle"
                text: I18n.t("Включить Material You", "Turn Material You on")
                enabled: !DesktopPresets.busy
                onClicked: DesktopPresets.apply("material", Config.wallpaper.shaders)
            }
            PxButton {
                visible: page.active && DesktopPresets.canRestore
                icon: "refresh"
                text: I18n.t("Вернуть прежний вид", "Back to the old look")
                enabled: !DesktopPresets.busy
                onClicked: DesktopPresets.restore()
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                visible: DesktopPresets.busy !== "" || MaterialYou.step !== ""
                text: DesktopPresets.step || MaterialYou.step
                dim: true
            }
        }

        // the scheme in small: its roles as chips, a switch, a button, a slider
        Rectangle {
            width: parent.width
            height: preview.implicitHeight + Theme.mdPx(32)
            radius: Theme.mdRadius("xl")
            color: page.md.surfaceContainerLow
            border.width: 1
            border.color: Qt.alpha(page.md.outlineVariant, 0.6)
            Column {
                id: preview
                x: Theme.mdPx(16)
                y: Theme.mdPx(16)
                width: parent.width - Theme.mdPx(32)
                spacing: Theme.mdPx(12)
                Flow {
                    width: parent.width
                    spacing: Theme.mdPx(8)
                    Repeater {
                        model: [["primary", "onPrimary"], ["primaryContainer", "onPrimaryContainer"], ["secondary", "onSecondary"], ["secondaryContainer", "onSecondaryContainer"], ["tertiary", "onTertiary"], ["tertiaryContainer", "onTertiaryContainer"], ["surfaceContainerHighest", "onSurface"], ["error", "onError"]]
                        delegate: Rectangle {
                            required property var modelData
                            width: chip.implicitWidth + Theme.mdPx(24)
                            height: Theme.mdPx(32)
                            radius: Theme.mdRadius("s")
                            color: page.md[modelData[0]]
                            Text {
                                id: chip
                                anchors.centerIn: parent
                                text: parent.modelData[0]
                                color: page.md[parent.modelData[1]]
                                font.family: Theme.mdFont
                                font.pixelSize: Theme.mdPx(12)
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
                Row {
                    spacing: Theme.mdPx(16)
                    Rectangle {
                        width: Theme.mdPx(120)
                        height: Theme.mdPx(40)
                        radius: Theme.mdRadius("full")
                        color: page.md.primary
                        Text {
                            anchors.centerIn: parent
                            text: I18n.t("Кнопка", "Button")
                            color: page.md.onPrimary
                            font.family: Theme.mdFont
                            font.pixelSize: Theme.mdPx(14)
                            font.weight: Font.Medium
                        }
                    }
                    Rectangle {
                        width: Theme.mdPx(120)
                        height: Theme.mdPx(40)
                        radius: Theme.mdRadius("full")
                        color: page.md.secondaryContainer
                        Text {
                            anchors.centerIn: parent
                            text: I18n.t("Тональная", "Tonal")
                            color: page.md.onSecondaryContainer
                            font.family: Theme.mdFont
                            font.pixelSize: Theme.mdPx(14)
                            font.weight: Font.Medium
                        }
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.mdPx(52)
                        height: Theme.mdPx(32)
                        radius: Theme.mdRadius("full")
                        color: page.md.primary
                        Rectangle {
                            x: parent.width - width - Theme.mdPx(4)
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.mdPx(24)
                            height: width
                            radius: Math.min(width / 2, Theme.mdRadius("full"))
                            color: page.md.onPrimary
                        }
                    }
                    WavyLine {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.mdPx(160)
                        height: Theme.mdPx(24)
                        progress: 0.62
                        playing: true
                        color: page.md.primary
                        track: page.md.secondaryContainer
                    }
                }
            }
        }
    }

    PxGroup {
        name: "accent"
        title: I18n.t("Акцентный цвет", "Accent colour")
        icon: "palette"
        width: parent.width
        SettingRow {
            label: I18n.t("Из обоев", "From the wallpaper")
            hint: I18n.t("самый яркий цвет картинки на рабочем столе", "The wallpaper's most colourful colour")
            PxToggle {
                checked: page.m.fromWallpaper
                onToggled: v => page.m.fromWallpaper = v
            }
        }
        // the swatches: a circle each, the picked one with a ring and a check
        Flow {
            width: parent.width
            spacing: Theme.mdPx(10)
            opacity: page.m.fromWallpaper ? 0.4 : 1
            Repeater {
                model: page.seeds
                delegate: Item {
                    id: sw
                    required property string modelData
                    readonly property bool picked: !page.m.fromWallpaper && String(page.m.seed).toLowerCase() === modelData
                    width: Theme.mdPx(48)
                    height: width
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: sw.picked ? Theme.mdPx(3) : 0
                        border.color: Theme.md.primary
                    }
                    // the swatch shows what the scheme would be: the seed's primary over its container
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - Theme.mdPx(10)
                        height: width
                        radius: width / 2
                        color: sw.modelData
                        MdSymbol {
                            anchors.centerIn: parent
                            visible: sw.picked
                            name: "check"
                            weight: 700
                            color: "#ffffff"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            page.m.fromWallpaper = false;
                            page.m.seed = sw.modelData;
                        }
                    }
                }
            }
        }
        SettingRow {
            label: I18n.t("Свой цвет", "Your own colour")
            hint: I18n.t("любой #rrggbb", "Any #rrggbb")
            Row {
                spacing: Theme.u * 3
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.mdPx(28)
                    height: width
                    radius: width / 2
                    color: Theme.materialSeed
                    border.width: 1
                    border.color: Theme.md.outline
                }
                PxField {
                    id: hex
                    width: Theme.mdPx(140)
                    text: page.m.seed
                    placeholder: "#6750a4"
                    onAccepted: {
                        const v = text.trim();
                        if (/^#?[0-9a-fA-F]{6}$/.test(v)) {
                            page.m.fromWallpaper = false;
                            page.m.seed = (v.startsWith("#") ? v : "#" + v).toLowerCase();
                        } else {
                            text = page.m.seed;
                        }
                    }
                }
            }
        }
        SettingRow {
            label: I18n.t("Стиль палитры", "Palette style")
            hint: ({
                    "tonalSpot": I18n.t("как в Android по умолчанию: спокойный акцент", "Android's default: a calm accent"),
                    "vibrant": I18n.t("насыщенно, яркие контейнеры", "Saturated, bright containers"),
                    "expressive": I18n.t("неожиданные сочетания: акцент уходит по кругу", "Unexpected pairs: the accent turns round the wheel"),
                    "neutral": I18n.t("почти серая, акцент едва заметен", "Nearly grey, a hint of the accent"),
                    "monochrome": I18n.t("чёрно-белая", "Black and white"),
                    "fidelity": I18n.t("точно твой цвет, без смягчения", "Your colour exactly, unsoftened")
                })[page.m.variant] || ""
            PxSegmented {
                model: [
                    {
                        "label": "Tonal",
                        "value": "tonalSpot"
                    },
                    {
                        "label": "Vibrant",
                        "value": "vibrant"
                    },
                    {
                        "label": "Expressive",
                        "value": "expressive"
                    },
                    {
                        "label": "Neutral",
                        "value": "neutral"
                    },
                    {
                        "label": "Mono",
                        "value": "monochrome"
                    },
                    {
                        "label": "Fidelity",
                        "value": "fidelity"
                    }
                ]
                currentValue: page.m.variant
                onActivated: v => page.m.variant = v
            }
        }
        SettingRow {
            label: I18n.t("Тема", "Theme")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Светлая", "Light"),
                        "value": "light",
                        "icon": "sun"
                    },
                    {
                        "label": I18n.t("Тёмная", "Dark"),
                        "value": "dark",
                        "icon": "moon"
                    },
                    {
                        "label": I18n.t("Авто", "Auto"),
                        "value": "auto",
                        "icon": "clock"
                    }
                ]
                currentValue: Config.appearance.mode
                onActivated: v => Config.appearance.mode = v
            }
        }
    }

    PxGroup {
        name: "shape"
        title: I18n.t("Форма и шрифт", "Shape and type")
        icon: "layers"
        width: parent.width
        SettingRow {
            label: I18n.t("Углы", "Corners")
            hint: I18n.t("насколько скруглены кнопки, карточки и окна", "How round buttons, cards and windows are")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Круглые", "Round"),
                        "value": "round"
                    },
                    {
                        "label": I18n.t("Мягкие", "Soft"),
                        "value": "soft"
                    },
                    {
                        "label": I18n.t("Острые", "Square"),
                        "value": "square"
                    }
                ]
                currentValue: page.m.corners
                onActivated: v => page.m.corners = v
            }
        }
        SettingRow {
            label: I18n.t("Шрифт", "Font")
            hint: I18n.t("Google Sans Flex — без кириллицы: русский будет другим шрифтом", "Google Sans Flex has no Cyrillic")
            PxCombo {
                width: Theme.mdPx(220)
                model: [
                    {
                        "label": "Roboto Flex",
                        "value": "Roboto Flex"
                    },
                    {
                        "label": "Google Sans Flex",
                        "value": "Google Sans Flex"
                    },
                    {
                        "label": "Inter",
                        "value": "Inter"
                    },
                    {
                        "label": "Noto Sans",
                        "value": "Noto Sans"
                    },
                    {
                        "label": I18n.t("Системный", "The system's"),
                        "value": ""
                    }
                ]
                currentValue: page.m.font
                onActivated: v => page.m.font = v
            }
        }
        SettingRow {
            label: I18n.t("Символы", "Symbols")
            hint: I18n.t("значки интерфейса: Material Symbols", "The interface's icons: Material Symbols")
            PxSegmented {
                model: [
                    {
                        "label": "Rounded",
                        "value": "rounded"
                    },
                    {
                        "label": "Outlined",
                        "value": "outlined"
                    },
                    {
                        "label": "Sharp",
                        "value": "sharp"
                    }
                ]
                currentValue: page.m.symbols
                onActivated: v => page.m.symbols = v
            }
        }
    }

    PxGroup {
        name: "icons"
        title: I18n.t("Значки приложений", "App icons")
        icon: "grid"
        width: parent.width
        SettingRow {
            label: I18n.t("Перекраска", "Recolour")
            hint: page.m.icons === "themed" ? I18n.t("все значки в тонах акцента — как тематические значки Android", "Every icon in the accent's tones, like Android's themed icons") : page.m.icons === "colored" ? I18n.t("цветные Papirus, папки в цвет акцента", "Papirus in colour, the folders in the accent") : I18n.t("значки не трогаются", "The icons are left alone")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Тематические", "Themed"),
                        "value": "themed"
                    },
                    {
                        "label": I18n.t("Цветные", "Colourful"),
                        "value": "colored"
                    },
                    {
                        "label": I18n.t("Не трогать", "Leave"),
                        "value": "off"
                    }
                ]
                currentValue: page.m.icons
                onActivated: v => page.m.icons = v
            }
        }
        PxText {
            visible: MaterialYou.error !== ""
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.danger
            text: MaterialYou.error + (MaterialYou.error.indexOf("Papirus") >= 0 ? I18n.t(" — поставь: sudo pacman -S papirus-icon-theme", " — install: sudo pacman -S papirus-icon-theme") : "")
        }
    }

    PxGroup {
        name: "desktop"
        title: I18n.t("Рабочий стол", "Desktop")
        icon: "monitor"
        width: parent.width
        SettingRow {
            label: I18n.t("Панель-таблетка", "Pill panel")
            hint: I18n.t("панель парит с отступами и скруглена; выключено — от края до края", "The panel floats rounded with gaps; off: edge to edge")
            PxToggle {
                checked: page.m.pillBar
                onToggled: v => page.m.pillBar = v
            }
        }
        SettingRow {
            label: I18n.t("Волна у трека", "A wave for the track")
            hint: I18n.t("пока играет музыка, полоска прогресса волнистая (Dynamic Island, плеер)", "While music plays the progress bar is a wave (Dynamic Island, the player)")
            PxToggle {
                checked: page.m.wavy
                onToggled: v => page.m.wavy = v
            }
        }
        SettingRow {
            label: I18n.t("Живые обои", "Live wallpaper")
            hint: I18n.t("фигуры Material медленно плывут; выключено — стоят на месте", "Material's shapes drift slowly; off: they stand still")
            PxToggle {
                checked: Config.wallpaper.shaders
                onToggled: v => Config.wallpaper.shaders = v
            }
        }
        SettingRow {
            label: I18n.t("Залитые символы", "Filled symbols")
            hint: I18n.t("включённое и выбранное — залитым значком", "What is on or picked as a filled symbol")
            PxToggle {
                checked: page.m.filledIcons
                onToggled: v => page.m.filledIcons = v
            }
        }
    }
}
