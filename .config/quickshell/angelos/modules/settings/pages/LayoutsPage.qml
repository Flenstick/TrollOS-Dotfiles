pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings

// Whole-desktop layouts (like Zorin's): pick a card, the bar, Start and dock follow.
PxPage {
    id: page

    heading: I18n.t("Раскладки", "Layouts")
    subtitle: I18n.t("Как будет выглядеть система: где панель, «Пуск» и док. «Как сейчас» — твоя раскладка, она запоминается при первом переключении, и к ней всегда можно вернуться.", "How the desktop looks: where the bar, Start and the dock sit. “Current” is your own layout — it is saved the first time you switch, so you can always come back.")

    // each card gets its own desk colour, like Zorin's gallery
    readonly property var tints: ({
            "default": Theme.accent,
            "macos": "#ff7a45",
            "win11": "#f5b82e",
            "windows": "#1f6fd8",
            "compact": "#2fa8f0",
            "ubuntu": "#a5603f",
            "classic": "#1db6a3",
            "chromeos": "#f2384a",
            "elementary": "#9a5ce0",
            "cinnamon": "#2fcf82"
        })

    // after switching to the Windows 11 copy: offer the rest of the Windows look
    PxGroup {
        id: offer
        width: parent.width
        visible: Config.bar.style === "windows" && !Config.win.offered
        title: I18n.t("Сделать всё как в Windows 11?", "Make everything look like Windows 11?")
        icon: "sparkle"
        property bool optSettings: true
        property bool optGradient: true
        property bool optIcons: true
        property bool optSnip: true
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Панель уже как в Windows. Можно переделать и остальное — всё вернётся, если выбрать другую раскладку.", "The taskbar already looks like Windows. The rest can follow — it all comes back when you pick another layout.")
        }
        PxCheck {
            text: I18n.t("Параметры (это окно) в стиле Windows 11", "Settings (this window) like Windows 11")
            checked: offer.optSettings
            onToggled: c => offer.optSettings = c
        }
        PxCheck {
            text: I18n.t("Обои-градиент Bloom, как в Windows 11", "The Bloom gradient wallpaper of Windows 11")
            checked: offer.optGradient
            onToggled: c => offer.optGradient = c
        }
        PxCheck {
            text: I18n.t("Значки приложений и папок как в Windows", "Windows app and folder icons")
            checked: offer.optIcons
            onToggled: c => offer.optIcons = c
        }
        PxCheck {
            text: I18n.t("Скриншоты как «Ножницы» Windows", "Screenshots like the Snipping Tool")
            checked: offer.optSnip
            onToggled: c => offer.optSnip = c
        }
        Row {
            spacing: Theme.u * 4
            PxButton {
                accent: true
                text: I18n.t("Сделать как в Windows", "Make it like Windows")
                onClicked: {
                    Config.win.settingsSkin = offer.optSettings;
                    Config.win.gradient = offer.optGradient;
                    Config.win.icons = offer.optIcons ? "windows" : "angelos";
                    Config.win.snip = offer.optSnip;
                    Config.win.offered = true;
                }
            }
            PxButton {
                text: I18n.t("Только панель", "Just the taskbar")
                onClicked: {
                    Config.win.settingsSkin = false;
                    Config.win.gradient = false;
                    Config.win.icons = "angelos";
                    Config.win.snip = false;
                    Config.win.offered = true;
                }
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Раскладки", "Layouts")
        icon: "grid"

        Grid {
            id: cards
            width: parent.width
            columns: width > Theme.u * 300 ? 3 : 2
            spacing: Theme.u * 6
            readonly property real cardW: (width - spacing * (columns - 1)) / columns

            Repeater {
                model: DesktopLayouts.presets
                LayoutCard {
                    required property var modelData
                    preset: modelData
                    width: cards.cardW
                }
            }
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("Раскладка меняет только панель, «Пуск» и док — обои, цвета, плагины и виджеты остаются. Тонкая настройка — в разделе «Панель».", "A layout only changes the bar, Start and the dock — wallpaper, colours, plugins and widgets stay. Fine-tune it under “Bar”.")
        }
    }

    PxGroup {
        width: parent.width
        visible: Config.bar.style === "windows"
        title: I18n.t("Windows 11 — копия", "Windows 11 replica")
        icon: "window"

        SettingRow {
            label: I18n.t("Цвет акцента", "Accent colour")
            hint: I18n.t("синий как в Windows или цвет темы angelOS", "Windows blue or the angelOS theme colour")
            PxSegmented {
                model: [
                    {
                        "label": "Windows",
                        "value": "windows"
                    },
                    {
                        "label": I18n.t("Тема", "Theme"),
                        "value": "theme"
                    }
                ]
                currentValue: Config.win.accent
                onActivated: v => Config.win.accent = v
            }
        }
        SettingRow {
            label: I18n.t("Параметры в стиле Windows 11", "Settings like Windows 11")
            hint: I18n.t("это окно: навигация слева, карточки, переключатели Fluent", "This window: navigation on the left, cards, Fluent switches")
            PxToggle {
                checked: Config.win.settingsSkin
                onToggled: c => Config.win.settingsSkin = c
            }
        }
        SettingRow {
            label: I18n.t("Обои-градиент Bloom", "Bloom gradient wallpaper")
            hint: I18n.t("тёмный или светлый по теме; твои обои вернутся, когда выключишь", "Dark or light with the theme; your wallpaper comes back when it is off")
            PxToggle {
                checked: Config.win.gradient
                onToggled: c => Config.win.gradient = c
            }
        }
        SettingRow {
            label: I18n.t("Значки", "Icons")
            hint: I18n.t("Windows — тема значков Win11 для панели, «Пуска» и приложений", "Windows: the Win11 icon theme for the taskbar, Start and apps")
            PxSegmented {
                model: [
                    {
                        "label": "Windows",
                        "value": "windows"
                    },
                    {
                        "label": "angelOS",
                        "value": "angelos"
                    }
                ]
                currentValue: Config.win.icons
                onActivated: v => Config.win.icons = v
            }
        }
        SettingRow {
            label: I18n.t("Растягивать окна за края", "Resize windows by their edges")
            hint: I18n.t("как в Windows: потяни край или угол активного окна", "Like Windows: drag an edge or a corner of the active window")
            PxToggle {
                checked: Config.win.edgeResize
                onToggled: c => Config.win.edgeResize = c
            }
        }
        SettingRow {
            label: I18n.t("Alt+Tab как в Windows", "Windows-style Alt+Tab")
            hint: I18n.t("выключено — встроенный переключатель niri", "Off: niri's own switcher")
            PxToggle {
                checked: Config.win.altTab
                onToggled: c => Config.win.altTab = c
            }
        }
        SettingRow {
            label: I18n.t("Скриншоты как «Ножницы»", "Snipping Tool screenshots")
            hint: I18n.t("Print / Mod+Shift+S: затемнение, панель режимов сверху", "Print / Mod+Shift+S: dimmed screen, mode bar on top")
            PxToggle {
                checked: Config.win.snip
                onToggled: c => Config.win.snip = c
            }
        }
        SettingRow {
            label: I18n.t("Выравнивание панели задач", "Taskbar alignment")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("По центру", "Center"),
                        "value": "center"
                    },
                    {
                        "label": I18n.t("Слева", "Left"),
                        "value": "left"
                    }
                ]
                currentValue: Config.win.align
                onActivated: v => Config.win.align = v
            }
        }
        SettingRow {
            label: I18n.t("Поиск", "Search")
            PxToggle {
                checked: Config.win.search
                onToggled: c => Config.win.search = c
            }
        }
        SettingRow {
            label: I18n.t("Представление задач", "Task view")
            hint: I18n.t("обзор niri", "niri overview")
            PxToggle {
                checked: Config.win.taskView
                onToggled: c => Config.win.taskView = c
            }
        }
        SettingRow {
            label: I18n.t("Рекомендуем в «Пуске»", "Recommended in Start")
            hint: I18n.t("недавние файлы; выключено — больше закреплённых", "Recent files; off gives more room to pinned apps")
            PxToggle {
                checked: Config.win.recommended
                onToggled: c => Config.win.recommended = c
            }
        }
        SettingRow {
            label: I18n.t("Строка песни слева", "Song line on the left")
            hint: I18n.t("лирика / остров там, где у Windows «Виджеты»", "Lyrics / the island where Windows keeps Widgets")
            PxToggle {
                checked: Config.win.lyrics
                onToggled: c => Config.win.lyrics = c
            }
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("Закреплять на панели задач и в «Пуске» — правой кнопкой по значку. Шрифт: Segoe UI, если установлен, иначе Noto Sans. Иконки — Fluent UI System Icons (Microsoft, MIT).", "Pin to the taskbar and Start with a right click. Font: Segoe UI when installed, Noto Sans otherwise. Icons: Fluent UI System Icons (Microsoft, MIT).")
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Док", "Dock")
        icon: "layers"

        SettingRow {
            label: I18n.t("Показывать док", "Show the dock")
            hint: I18n.t("закреплённые и открытые приложения; клик — открыть или перейти, ещё клик — следующее окно, колёсико-клик — новое окно, ПКМ — меню", "Pinned and running apps; click opens or goes there, again — the next window, middle click — a new window, right click — menu")
            PxToggle {
                checked: Config.dock.enabled
                onToggled: c => Config.dock.enabled = c
            }
        }
        SettingRow {
            visible: Config.dock.enabled
            label: I18n.t("Где", "Position")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Снизу", "Bottom"),
                        "value": "bottom"
                    },
                    {
                        "label": I18n.t("Слева", "Left"),
                        "value": "left"
                    }
                ]
                currentValue: Config.dock.position
                onActivated: v => Config.dock.position = v
            }
        }
        SettingRow {
            visible: Config.dock.enabled && Config.dock.position === "bottom"
            label: I18n.t("Увеличение под курсором", "Magnify under the pointer")
            hint: I18n.t("значки растут, как в macOS", "Icons grow like on macOS")
            PxToggle {
                checked: Config.dock.magnify
                onToggled: c => Config.dock.magnify = c
            }
        }
        SettingRow {
            visible: Config.dock.enabled
            label: I18n.t("Размер значков", "Icon size")
            PxSlider {
                width: parent.width
                from: 14
                to: 36
                stepSize: 1
                value: Config.dock.size
                suffix: " px×" + Theme.u
                onReleased: v => Config.dock.size = v
            }
        }
        SettingRow {
            visible: Config.dock.enabled
            label: I18n.t("Кнопка «Все приложения»", "“All apps” button")
            PxToggle {
                checked: Config.dock.appsButton
                onToggled: c => Config.dock.appsButton = c
            }
        }
        SettingRow {
            visible: Config.dock.enabled
            label: I18n.t("Открытые приложения", "Running apps")
            hint: I18n.t("показывать и незакреплённые, пока они открыты", "Also show apps that are not pinned while they run")
            PxToggle {
                checked: Config.dock.running
                onToggled: c => Config.dock.running = c
            }
        }
        SettingRow {
            visible: Config.dock.enabled
            label: I18n.t("Закреплённые", "Pinned")
            hint: (Config.dock.pinned || []).length ? I18n.t("× — открепить; закрепить можно и в доке через ПКМ", "× unpins; you can also pin from the dock's right-click menu") : I18n.t("пока пусто — в доке самые частые приложения", "Empty for now — the dock shows your most used apps")
            Column {
                width: parent.width
                spacing: Theme.u * 3
                Flow {
                    width: parent.width
                    spacing: Theme.u * 3
                    Repeater {
                        model: (Config.dock.pinned || []).map(id => StartApps.apps.find(a => a.id === id)).filter(a => !!a)
                        PxBox {
                            id: chip
                            required property var modelData
                            width: chipRow.implicitWidth + Theme.u * 6
                            height: Theme.u * 14
                            color: Theme.face
                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: Theme.u * 3
                                AppIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    iconName: chip.modelData.icon || ""
                                    appId: chip.modelData.id
                                    size: Theme.u * 8
                                }
                                PxText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: chip.modelData.name
                                }
                                PxButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    compact: true
                                    icon: "close"
                                    iconPixel: Math.max(1, Theme.u - 1)
                                    width: Theme.u * 9
                                    height: Theme.u * 9
                                    onClicked: Config.dock.pinned = (Config.dock.pinned || []).filter(id => id !== chip.modelData.id)
                                }
                            }
                        }
                    }
                }
                PxCombo {
                    width: Math.min(parent.width, Theme.u * 140)
                    placeholder: I18n.t("Закрепить приложение…", "Pin an app…")
                    model: StartApps.apps.filter(a => !(Config.dock.pinned || []).includes(a.id)).map(a => ({
                                "label": a.name,
                                "value": a.id
                            }))
                    currentValue: ""
                    onActivated: v => {
                        // the first pin keeps what the dock showed until now
                        const cur = (Config.dock.pinned || []).length ? Config.dock.pinned.slice() : StartApps.frequent.slice(0, 7).map(a => a.id);
                        if (!cur.includes(v))
                            cur.push(v);
                        Config.dock.pinned = cur;
                    }
                }
            }
        }
    }

    // ---- a card: a tiny desktop drawn from the preset's preview spec ----
    component LayoutCard: Item {
        id: card

        required property var preset
        readonly property var pv: preset.preview || {}
        readonly property bool startInRow: pv.tasks === "center" && pv.menuAt === "center"   // Windows 11: Start sits with the windows
        readonly property bool active: DesktopLayouts.current === preset.id
        readonly property color tint: page.tints[preset.id] || Theme.accent

        height: desk.height + caption.implicitHeight + hintText.implicitHeight + Theme.u * 8

        PxBox {
            id: frame
            width: parent.width
            height: desk.height + Theme.u * 4
            sunken: true
            color: card.active ? Theme.accent : mouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.35) : Theme.sunken

            Item {
                id: desk
                x: Theme.u * 2
                y: Theme.u * 2
                width: parent.width - Theme.u * 4
                height: Math.round(width * 0.58)
                clip: true
                readonly property real s: width / 160   // drawing unit: the desk is 160 × 93

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Qt.lighter(card.tint, 1.25)
                        }
                        GradientStop {
                            position: 1
                            color: card.tint
                        }
                    }
                }

                // top strip
                Rectangle {
                    visible: card.pv.bar === "top"
                    width: parent.width
                    height: 5 * desk.s
                    color: Qt.alpha("#ffffff", 0.85)
                    Row {
                        x: 3 * desk.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * desk.s
                        Repeater {
                            model: 3
                            Rectangle {
                                width: 2.4 * desk.s
                                height: 2.4 * desk.s
                                color: Qt.alpha("#000000", 0.45)
                            }
                        }
                    }
                    Rectangle {
                        // clock in the middle (Ubuntu / elementary) or at the right
                        width: 12 * desk.s
                        height: 2 * desk.s
                        anchors.verticalCenter: parent.verticalCenter
                        x: card.pv.clock === "center" ? (parent.width - width) / 2 : parent.width - width - 3 * desk.s
                        color: Qt.alpha("#000000", 0.45)
                    }
                }

                // bottom taskbar (full width or floating)
                Rectangle {
                    id: taskbar
                    visible: card.pv.bar === "bottom"
                    readonly property real m: card.pv.float ? 4 * desk.s : 0
                    x: m
                    width: parent.width - m * 2
                    height: 7 * desk.s
                    y: parent.height - height - m
                    radius: card.pv.float ? 1.5 * desk.s : 0
                    color: card.pv.win ? Qt.alpha("#202020", 0.85) : Qt.alpha("#ffffff", 0.88)

                    // start button + window icons: left, centred or with titles
                    Rectangle {
                        visible: !card.startInRow
                        x: 2 * desk.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: (card.pv.menu === "list" ? 10 : 4) * desk.s
                        height: 4 * desk.s
                        color: card.tint
                    }
                    Row {
                        visible: !!card.pv.tasks && card.pv.tasks !== "none"
                        x: card.pv.tasks === "center" ? (parent.width - width) / 2 : (card.pv.menu === "list" ? 15 : 9) * desk.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1.6 * desk.s
                        Rectangle {
                            visible: card.startInRow
                            width: 4 * desk.s
                            height: 4 * desk.s
                            color: card.tint
                        }
                        Repeater {
                            model: card.pv.tasks === "labels" ? 3 : 6
                            Rectangle {
                                required property int index
                                width: (card.pv.tasks === "labels" ? 18 : 4) * desk.s
                                height: 4 * desk.s
                                color: card.pv.tasks === "labels" ? Qt.alpha("#000000", 0.18) : Qt.hsla((index * 0.13 + 0.02) % 1, 0.6, 0.55, 1)
                            }
                        }
                    }
                    Row {
                        // tray + clock
                        anchors.right: parent.right
                        anchors.rightMargin: 2 * desk.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1.2 * desk.s
                        Repeater {
                            model: 3
                            Rectangle {
                                width: 2 * desk.s
                                height: 2 * desk.s
                                color: Qt.alpha("#000000", 0.4)
                            }
                        }
                        Rectangle {
                            width: 8 * desk.s
                            height: 2 * desk.s
                            color: Qt.alpha("#000000", 0.4)
                        }
                    }
                }

                // dock: centred shelf (bottom) or a strip on the left
                Rectangle {
                    visible: card.pv.dock === "bottom"
                    width: dockRow.width + 4 * desk.s
                    height: 8 * desk.s
                    x: (parent.width - width) / 2
                    y: parent.height - height - 2.5 * desk.s
                    radius: 2 * desk.s
                    color: Qt.alpha("#ffffff", 0.8)
                    Row {
                        id: dockRow
                        anchors.centerIn: parent
                        spacing: 1.6 * desk.s
                        Repeater {
                            model: 8
                            Rectangle {
                                required property int index
                                width: 4.6 * desk.s
                                height: 4.6 * desk.s
                                radius: desk.s
                                color: index === 7 ? Qt.alpha("#000000", 0.3) : Qt.hsla((index * 0.13 + 0.02) % 1, 0.6, 0.55, 1)
                            }
                        }
                    }
                }
                Rectangle {
                    visible: card.pv.dock === "left"
                    y: card.pv.bar === "top" ? 5 * desk.s : 0
                    width: 8 * desk.s
                    height: parent.height - y
                    color: Qt.alpha("#000000", 0.35)
                    Column {
                        x: 1.7 * desk.s
                        y: 2 * desk.s
                        spacing: 1.6 * desk.s
                        Repeater {
                            model: 7
                            Rectangle {
                                required property int index
                                width: 4.6 * desk.s
                                height: 4.6 * desk.s
                                radius: desk.s
                                color: Qt.hsla((index * 0.13 + 0.02) % 1, 0.6, 0.55, 1)
                            }
                        }
                    }
                    Grid {
                        // "show apps" at the foot
                        columns: 3
                        spacing: 0.6 * desk.s
                        x: 1.9 * desk.s
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2 * desk.s
                        Repeater {
                            model: 9
                            Rectangle {
                                width: 1 * desk.s
                                height: 1 * desk.s
                                color: "#ffffff"
                            }
                        }
                    }
                }

                // the Start menu, open
                Rectangle {
                    id: menu
                    visible: card.pv.menu === "grid" || card.pv.menu === "list"
                    readonly property bool list: card.pv.menu === "list"
                    readonly property real bottomEdge: card.pv.bar === "bottom" ? taskbar.y - 2 * desk.s : parent.height - 4 * desk.s
                    width: (list ? 30 : 58) * desk.s
                    height: (list ? 52 : 50) * desk.s
                    x: card.pv.menuAt === "center" ? (parent.width - width) / 2 : (card.pv.float ? 4 : 2) * desk.s
                    y: card.pv.menuAt === "topleft" ? 7 * desk.s : bottomEdge - height
                    radius: (card.pv.win ? 2.4 : 1.2) * desk.s
                    color: card.pv.win ? Qt.alpha("#2c2c2c", 0.92) : Qt.alpha("#ffffff", 0.94)
                    Rectangle {
                        // Windows: search pill on top
                        visible: !!card.pv.win
                        x: 6 * desk.s
                        y: 3 * desk.s
                        width: parent.width - 12 * desk.s
                        height: 3.5 * desk.s
                        radius: height / 2
                        color: Qt.alpha("#ffffff", 0.12)
                    }
                    border.width: Math.max(1, desk.s * 0.4)
                    border.color: Qt.alpha("#000000", 0.12)

                    Grid {
                        visible: !menu.list
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -2 * desk.s
                        columns: 6
                        spacing: 3.2 * desk.s
                        Repeater {
                            model: 18
                            Rectangle {
                                required property int index
                                width: 4.4 * desk.s
                                height: 4.4 * desk.s
                                color: Qt.hsla((index * 0.17 + 0.05) % 1, 0.55, 0.58, 1)
                            }
                        }
                    }
                    Column {
                        visible: menu.list
                        x: 3 * desk.s
                        y: 3 * desk.s
                        spacing: 2.6 * desk.s
                        Repeater {
                            model: 9
                            Row {
                                required property int index
                                spacing: 1.6 * desk.s
                                Rectangle {
                                    width: 2.6 * desk.s
                                    height: 2.6 * desk.s
                                    color: Qt.hsla((index * 0.17 + 0.05) % 1, 0.55, 0.58, 1)
                                }
                                Rectangle {
                                    width: (10 + (index * 7) % 9) * desk.s
                                    height: 1.6 * desk.s
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Qt.alpha("#000000", 0.25)
                                }
                            }
                        }
                    }
                }
            }

            // ✓ on the chosen one
            PxBox {
                visible: card.active
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.u * 4
                width: Theme.u * 12
                height: Theme.u * 12
                color: Theme.accent
                PxIcon {
                    anchors.centerIn: parent
                    name: "check"
                    ink: Theme.selectText
                    pixel: Math.max(1, Theme.u - 1)
                }
            }
        }

        PxText {
            id: caption
            anchors.top: frame.bottom
            anchors.topMargin: Theme.u * 3
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: card.preset.id === "default" || card.preset.id === "compact" || card.preset.id === "windows" ? card.preset.label : I18n.t("Как ", "") + card.preset.label + I18n.t("", "-like")
            font.bold: card.active
            color: card.active ? (Theme.dark ? Theme.accent : Theme.edge) : Theme.text
        }
        PxText {
            id: hintText
            anchors.top: caption.bottom
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            kind: "tiny"
            dim: true
            text: card.preset.hint
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: DesktopLayouts.apply(card.preset.id)
        }
    }
}
