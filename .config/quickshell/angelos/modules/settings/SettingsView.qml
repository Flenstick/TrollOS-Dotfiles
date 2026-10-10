pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar.win
import "../bar/win/NavIcons.js" as Nav

// Settings content (frame, sidebar, pages). Hosted by SettingsWindow.
Item {
    id: win

    Component.onCompleted: {
        Shell.settingsView = win;
        SettingsSearch.load();
    }
    Component.onDestruction: if (Shell.settingsView === win)
        Shell.settingsView = null
    function diagnostics() {
        return {
            page: Shell.settingsPage,
            source: String(page.source),
            status: page.status,
            plugin: page.item && page.item.loadedPlugin !== undefined ? page.item.loadedPlugin : ""
        };
    }
    property var hostWindow: null
    readonly property alias frame: frame
    // Windows 11 layout + "Параметры как в Windows": Fluent chrome around the same pages
    readonly property bool fluent: WinExtras.fluentSettings
    readonly property Item blurItem: fluent ? fchrome : frame
    Binding {
        target: Shell
        property: "fluentWindow"
        value: win.fluent ? win.Window.window : null
        when: win.fluent
        restoreMode: Binding.RestoreValue
    }
    readonly property var groups: [
        {
            "title": I18n.t("Вид", "Appearance"),
            "pages": [
                {
                    "id": "appearance",
                    "label": I18n.t("Внешний вид", "Appearance"),
                    "icon": "palette"
                },
                {
                    "id": "fonts",
                    "label": I18n.t("Шрифты", "Fonts"),
                    "icon": "document"
                },
                {
                    "id": "wallpaper",
                    "label": I18n.t("Обои", "Wallpaper"),
                    "icon": "image"
                },
                {
                    "id": "capture",
                    "label": I18n.t("Скриншоты", "Screenshots"),
                    "icon": "image"
                },
                {
                    "id": "cursor",
                    "label": I18n.t("Курсор", "Cursor"),
                    "icon": "cursor"
                },
                {
                    "id": "widgets",
                    "label": I18n.t("Виджеты", "Widgets"),
                    "icon": "layers"
                },
                {
                    "id": "layouts",
                    "label": I18n.t("Раскладки", "Layouts"),
                    "icon": "grid"
                },
                {
                    "id": "bar",
                    "label": I18n.t("Панель", "Bar"),
                    "icon": "window"
                },
                {
                    "id": "workspaces",
                    "label": I18n.t("Воркспейсы", "Workspaces"),
                    "icon": "layers"
                },
                {
                    "id": "lyrics",
                    "label": I18n.t("Лирика", "Lyrics"),
                    "icon": "mic"
                },
                {
                    "id": "y2k",
                    "label": "Y2K ✧",
                    "icon": "sparkle"
                }
            ]
        },
        {
            "title": I18n.t("Устройства", "Devices"),
            "pages": [
                {
                    "id": "monitor",
                    "label": I18n.t("Монитор", "Monitor"),
                    "icon": "monitor"
                },
                {
                    "id": "keyboard",
                    "label": I18n.t("Клавиатура и мышь", "Keyboard and mouse"),
                    "icon": "keyboard"
                },
                {
                    "id": "shortcuts",
                    "label": I18n.t("Горячие клавиши", "Shortcuts"),
                    "icon": "keyboard"
                },
                {
                    "id": "windows",
                    "label": I18n.t("Поведение окон", "Window behavior"),
                    "icon": "window"
                },
                {
                    "id": "sound",
                    "label": I18n.t("Звук", "Sound"),
                    "icon": "speaker"
                },
                {
                    "id": "network",
                    "label": I18n.t("Сеть и Wi-Fi", "Network and Wi-Fi"),
                    "icon": "wifi"
                },
                {
                    "id": "bluetooth",
                    "label": "Bluetooth",
                    "icon": "bluetooth"
                },
                {
                    "id": "gamepad",
                    "label": I18n.t("Геймпад", "Gamepad"),
                    "icon": "gamepad"
                }
            ]
        },
        {
            "title": I18n.t("Система", "System"),
            "pages": [
                {
                    "id": "defaults",
                    "label": I18n.t("По умолчанию", "Default apps"),
                    "icon": "star"
                },
                {
                    "id": "notifications",
                    "label": I18n.t("Уведомления", "Notifications"),
                    "icon": "bell"
                },
                {
                    "id": "plugins",
                    "label": I18n.t("Плагины", "Plugins"),
                    "icon": "plug"
                },
                {
                    "id": "studio",
                    "label": I18n.t("Мастер плагинов", "Plugin Studio"),
                    "icon": "sparkle",
                    "developer": true
                },
                {
                    "id": "dotfiles",
                    "label": "Dotfiles",
                    "icon": "package",
                    "owner": true
                },
                {
                    "id": "lock",
                    "label": I18n.t("Блокировка и заставка", "Lock and idle"),
                    "icon": "lock"
                },
                {
                    "id": "updates",
                    "label": I18n.t("Обновления", "Updates"),
                    "icon": "download"
                },
                {
                    "id": "system",
                    "label": "System",
                    "icon": "chip"
                }
            ]
        },
        {
            "title": I18n.t("Плагины", "Plugins"),
            "pages": Plugins.settingsPages.map(p => ({
                        "id": "plugin:" + p.id,
                        "label": I18n.label(p.name),
                        "icon": p.icon || "plug"
                    }))
        }
    ]
    // owner-only pages vanish in the public version
    readonly property var visibleGroups: groups.map(g => ({
                "title": g.title,
                "pages": g.pages.filter(p => (!p.owner || Owner.enabled) && (!p.developer || Config.developer.enabled))
            })).filter(g => g.pages.length > 0)
    readonly property var allPages: visibleGroups.reduce((a, g) => a.concat(g.pages), [])
    readonly property var currentPage: allPages.find(p => p.id === Shell.settingsPage) || null
    // simple view: home tiles + main settings (advanced groups folded); expert: every page in the sidebar
    readonly property bool expert: Config.settingsUi.expert
    readonly property bool atHome: !expert && (Shell.settingsPage === "home" || Shell.settingsPage === "more")
    function setExpert(on) {
        Config.settingsUi.expert = on;
        if (on && (Shell.settingsPage === "home" || Shell.settingsPage === "more"))
            Shell.settingsPage = "appearance";
        else if (!on)
            Shell.settingsPage = "home";
    }

    // ---- search (services/SettingsSearch) ----
    property string query: ""
    property int sel: 0
    property var results: []
    onQueryChanged: {
        if (!query.trim())
            results = [];
        searchTimer.restart();
    }
    // one frame: keys typed together are searched once (a search takes ~1 ms)
    Timer {
        id: searchTimer
        interval: 16
        onTriggered: win.results = win.query.trim() ? SettingsSearch.search(win.query, 14) : []
    }
    Connections {
        target: SettingsSearch
        function onDocsChanged() {
            if (win.query.trim())
                searchTimer.restart();
        }
    }
    readonly property string ghost: query ? SettingsSearch.complete(query) : ""
    property var pendingTarget: null
    Binding {
        target: SettingsSearch
        property: "pageInfo"
        value: {
            const m = {};
            for (const p of win.allPages)
                m[p.id] = {
                    "label": p.label,
                    "icon": p.icon
                };
            return m;
        }
    }
    // `angelos settingsQuery "…"`: type into the search box (scripts, previews)
    function setQuery(t) {
        search.text = t;
        query = t;
        sel = 0;
        search.focusField();
    }
    function acceptGhost() {
        if (!ghost)
            return false;
        search.text = query + ghost;
        query = search.text;
        sel = 0;
        return true;
    }
    function openResult(r) {
        if (!r)
            return;
        pendingTarget = r.kind === "page" ? null : r;
        query = "";
        search.text = "";
        if (Shell.settingsPage === r.page)
            targetTimer.restart();
        else
            Shell.settingsPage = r.page;
    }
    // scroll the page to the found setting and flash it
    function findItem(item, r) {
        if (!item || !item.visible)
            return null;
        if (r.kind === "row" && item.label === r.target && item.hint !== undefined)
            return item;
        if (r.kind === "group" && item.title === r.target && item.spacing !== undefined)
            return item;
        for (const c of item.children) {
            const f = findItem(c, r);
            if (f)
                return f;
        }
        return null;
    }
    function unfoldAll(item) {
        let any = false;
        if (item.folded === true && item.advanced !== undefined) {
            item.open = true;
            any = true;
        }
        for (const c of item.children)
            any = unfoldAll(c) || any;
        return any;
    }
    function showTarget() {
        const r = pendingTarget;
        pendingTarget = null;
        const pg = page.item;
        if (!r || !pg || !pg.flick)
            return;
        const it = findItem(pg.flick.contentItem, r) || (r.kind === "row" ? findItem(pg.flick.contentItem, {
                "kind": "group",
                "target": String(r.crumb).split(" › ")[1] || ""
            }) : null);
        if (!it) {
            // the setting may sit in a folded "Advanced" group of the simple view
            if (!r.unfolded && unfoldAll(pg.flick.contentItem)) {
                pendingTarget = Object.assign({}, r, {
                    "unfolded": true
                });
                targetTimer.restart();
            }
            return;
        }
        const y = it.mapToItem(pg.flick.contentItem, 0, 0).y;
        pg.scrollBy(Math.max(0, y - Theme.u * 8) - pg.flick.contentY);
        flashComp.createObject(it);
    }
    Timer {
        id: targetTimer
        interval: 60
        onTriggered: win.showTarget()
    }
    Component {
        id: flashComp
        Rectangle {
            id: flash
            anchors.fill: parent
            anchors.margins: -Theme.u * 2
            z: 100
            color: Qt.alpha(Theme.accent, 0.12)
            border.width: Math.max(2, Theme.u)
            border.color: Theme.accent
            SequentialAnimation on opacity {
                running: true
                PauseAnimation {
                    duration: 900
                }
                NumberAnimation {
                    to: 0
                    duration: 900
                }
                ScriptAction {
                    script: flash.destroy()
                }
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+F"
        enabled: !win.fluent
        onActivated: search.focusField()
    }

    PxWindow {
        id: frame
        visible: !win.fluent
        anchors.fill: parent
        anchors.rightMargin: Config.appearance.shadows ? Theme.u * 2 : 0
        anchors.bottomMargin: Config.appearance.shadows ? Theme.u * 2 : 0
        title: "angelOS · " + (win.currentPage ? win.currentPage.label : Shell.settingsPage === "more" ? I18n.t("Все разделы", "All sections") : I18n.t("Настройки", "Settings"))
        icon: win.currentPage ? win.currentPage.icon : "gear"
        minimizable: false
        maximizable: true
        onCloseClicked: Shell.settingsOpen = false
        onMaximizeClicked: if (win.hostWindow)
            win.hostWindow.maximized = !win.hostWindow.maximized
        onTitlePressed: if (win.hostWindow)
            win.hostWindow.startSystemMove()
        bodyPadding: Theme.u * 4

        // sidebar (expert view)
        PxBox {
            id: sidebar
            visible: win.expert
            width: Theme.u * 95
            height: parent.height
            sunken: true
            color: Qt.alpha(Theme.sunken, 0.55)
        }

        // search box and results: in the sidebar (expert) or above the page (simple)
        Item {
            id: searchArea
            parent: win.expert ? sidebar : pageBox
            anchors.fill: parent
            z: 5

            PxField {
                id: search
                x: win.expert ? Theme.u * 2 : homeBtn.x + (homeBtn.visible ? homeBtn.width + Theme.u * 3 : 0)
                y: Theme.u * 2
                width: win.expert ? parent.width - Theme.u * 4 : expertBtn.x - x - Theme.u * 3
                icon: "search"
                placeholder: I18n.t("Поиск настроек…", "Search settings…")
                onEdited: {
                    win.query = text;
                    win.sel = 0;
                }
                onAccepted: win.openResult(win.results[Math.min(win.sel, win.results.length - 1)])
                onKeyPressed: e => {
                    if (e.key === Qt.Key_Tab || (e.key === Qt.Key_Right && search.input.cursorPosition === search.text.length)) {
                        if (win.acceptGhost())
                            e.accepted = true;
                    } else if (e.key === Qt.Key_Down) {
                        win.sel = Math.min(win.results.length - 1, win.sel + 1);
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Up) {
                        win.sel = Math.max(0, win.sel - 1);
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Escape && search.text !== "") {
                        search.text = "";
                        win.query = "";
                        e.accepted = true;
                    }
                }
                // the rest of the suggested word, dimmed after the caret: "Bl" → "ur"
                PxText {
                    visible: win.ghost !== "" && search.input.activeFocus && search.input.contentWidth + implicitWidth < search.input.width
                    x: search.input.x + search.input.contentWidth
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.ghost
                    font: search.input.font
                    color: Theme.textDim
                    opacity: 0.8
                }
            }
            PxText {
                visible: win.ghost !== "" && search.input.activeFocus
                anchors.top: search.bottom
                anchors.right: search.right
                anchors.topMargin: Theme.u
                text: "Tab ↹ " + search.text + win.ghost
                kind: "tiny"
                dim: true
                width: search.width
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
            }

            // results
            Rectangle {
                visible: !win.expert && resultsBox.visible
                anchors.fill: parent
                anchors.topMargin: search.height + Theme.u * 6
                color: Theme.face
            }
            PxScroll {
                id: resultsBox
                visible: win.query.trim() !== ""
                anchors.fill: parent
                anchors.margins: Theme.u * 2
                anchors.topMargin: search.height + Theme.u * 10
                contentHeight: resultCol.implicitHeight
                Column {
                    id: resultCol
                    width: parent.width
                    spacing: Theme.u
                    PxText {
                        visible: win.results.length === 0
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: SettingsSearch.loaded ? I18n.t("Ничего не нашлось. Попробуй другое слово — «экран», «прозрачность», «хоткеи»…", "Nothing found. Try another word — “display”, “transparency”, “hotkeys”…") : "…"
                        dim: true
                        leftPadding: Theme.u * 3
                    }
                    Repeater {
                        model: win.results
                        Rectangle {
                            id: res
                            required property var modelData
                            required property int index
                            readonly property bool picked: win.sel === index
                            width: resultCol.width
                            height: resRow.implicitHeight + Theme.u * 4
                            color: picked ? Theme.select : rm.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : "transparent"
                            Row {
                                id: resRow
                                x: Theme.u * 3
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.u * 3
                                PxIcon {
                                    name: res.modelData.icon || "gear"
                                    anchors.verticalCenter: parent.verticalCenter
                                    ink: res.picked ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
                                }
                                Column {
                                    width: res.width - Theme.u * 20
                                    PxText {
                                        width: parent.width
                                        text: res.modelData.title
                                        elide: Text.ElideRight
                                        font.bold: res.modelData.kind === "page"
                                        color: res.picked ? Theme.selectText : Theme.text
                                    }
                                    PxText {
                                        visible: text !== ""
                                        width: parent.width
                                        text: res.modelData.crumb || res.modelData.hint
                                        kind: "tiny"
                                        elide: Text.ElideRight
                                        color: res.picked ? Theme.selectText : Theme.textDim
                                    }
                                }
                            }
                            MouseArea {
                                id: rm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: win.sel = res.index
                                onClicked: win.openResult(res.modelData)
                            }
                        }
                    }
                }
            }
        }

        // expert sidebar: every page
        PxScroll {
            parent: sidebar
            visible: win.query.trim() === ""
            anchors.fill: parent
            anchors.margins: Theme.u * 2
            anchors.topMargin: search.height + Theme.u * 4
            contentHeight: side.implicitHeight

            Column {
                id: side
                width: parent.width
                spacing: Theme.u

                // back to the simple view
                Rectangle {
                    width: side.width
                    height: Theme.u * 15
                    color: sm.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : "transparent"
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.u * 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.u * 4
                        PxIcon {
                            name: "grid"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        PxText {
                            text: I18n.t("Простой вид", "Simple view")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: sm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.setExpert(false)
                    }
                }

                Repeater {
                    model: win.visibleGroups
                    Column {
                        id: grp
                        required property var modelData
                        width: side.width
                        spacing: Theme.u
                        PxText {
                            text: "✧ " + grp.modelData.title
                            kind: "tiny"
                            dim: true
                            topPadding: Theme.u * 4
                            leftPadding: Theme.u * 3
                            bottomPadding: Theme.u
                        }
                        Repeater {
                            model: grp.modelData.pages
                            Rectangle {
                                id: entry
                                required property var modelData
                                readonly property bool sel: Shell.settingsPage === modelData.id
                                width: grp.width
                                height: Theme.u * 15
                                color: sel ? Theme.select : em.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : "transparent"
                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.u * 4
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                    spacing: Theme.u * 4
                                    PxIcon {
                                        name: entry.modelData.icon
                                        anchors.verticalCenter: parent.verticalCenter
                                        ink: entry.sel ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
                                    }
                                    PxText {
                                        width: entry.width - Theme.u * 24
                                        elide: Text.ElideRight
                                        text: entry.modelData.label
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: entry.sel ? Theme.selectText : Theme.text
                                        font.bold: entry.sel
                                    }
                                }
                                MouseArea {
                                    id: em
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Shell.settingsPage = entry.modelData.id
                                }
                            }
                        }
                    }
                }
            }
        }

        // page
        PxBox {
            id: pageBox
            anchors.left: win.expert ? sidebar.right : parent.left
            anchors.leftMargin: win.expert ? Theme.u * 4 : 0
            anchors.right: parent.right
            height: parent.height
            sunken: true
            color: Qt.alpha(Theme.face, Config.appearance.blur ? 0.55 : 1)

            // simple view header: home, (search), expert
            PxButton {
                id: homeBtn
                visible: !win.expert && Shell.settingsPage !== "home"
                x: Theme.u * 2
                y: Theme.u * 2
                height: search.height
                compact: true
                icon: "arrowLeft"
                text: I18n.t("Главная", "Home")
                onClicked: Shell.settingsPage = "home"
            }
            PxButton {
                id: expertBtn
                visible: !win.expert
                x: parent.width - width - Theme.u * 2
                y: Theme.u * 2
                height: search.height
                compact: true
                icon: "gear"
                text: I18n.t("Эксперт", "Expert")
                onClicked: win.setExpert(true)
            }

            Loader {
                id: page
                parent: win.fluent ? fpage : pageBox
                anchors.fill: parent
                anchors.margins: win.fluent ? 0 : Theme.u * 3
                anchors.topMargin: win.fluent ? 0 : win.expert ? Theme.u * 3 : search.height + Theme.u * 6
                active: win.hostWindow ? win.hostWindow.visible : true
                onLoaded: if (win.pendingTarget)
                    targetTimer.restart()
                source: {
                    const id = Shell.settingsPage;
                    if (id === "home" || id === "more")
                        return win.expert && !win.fluent ? "pages/AppearancePage.qml" : id === "home" ? "pages/HomePage.qml" : "pages/MorePage.qml";
                    if (id.startsWith("plugin:"))
                        return "pages/PluginSettingsPage.qml";
                    if (id === "dotfiles")
                        return Owner.enabled ? "file://" + Owner.dir + "/DotfilesPage.qml" : "pages/AppearancePage.qml";
                    const name = id.charAt(0).toUpperCase() + id.slice(1);
                    return "pages/" + (win.allPages.find(p => p.id === id) ? name : "Appearance") + "Page.qml";
                }
            }
        }

        // resize grip
        PxIcon {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: -Theme.u * 3
            name: "sparkle"
            fill: Theme.textDim
            MouseArea {
                anchors.fill: parent
                anchors.margins: -Theme.u * 3
                cursorShape: Qt.SizeFDiagCursor
                onPressed: if (win.hostWindow)
                    win.hostWindow.startSystemResize(Edges.Bottom | Edges.Right)
            }
        }
    }

    // ================= Windows 11 "Параметры" chrome =================
    Rectangle {
        id: fchrome
        visible: win.fluent
        anchors.fill: parent
        radius: 8
        // Mica: the wallpaper's colour shows faintly through
        color: WinStyle.dark ? Qt.rgba(0.125, 0.125, 0.125, 0.94) : Qt.rgba(0.953, 0.953, 0.953, 0.94)
        border.width: 1
        border.color: WinStyle.flyoutLine

        readonly property var navPages: [{
                "id": "home",
                "label": I18n.t("Главная", "Home"),
                "group": ""
            }].concat(win.visibleGroups.reduce((a, g) => a.concat(g.pages.map(p => Object.assign({
                    "group": g.title
                }, p))), []))
        readonly property var current: navPages.find(p => p.id === Shell.settingsPage) || navPages[0]
        function navIcon(id) {
            const k = id.startsWith("plugin:") ? "plugin" : id;
            const e = Nav.nav[k] || Nav.nav.system;
            return Qt.resolvedUrl("../bar/win/icons/c/" + e[0] + "-" + e[1].slice(1) + ".svg");
        }
        property var history: []
        Connections {
            target: Shell
            function onSettingsPageChanged() {
                if (!fchrome.goingBack && fchrome.lastPage && fchrome.lastPage !== Shell.settingsPage)
                    fchrome.history = fchrome.history.concat([fchrome.lastPage]).slice(-30);
                fchrome.goingBack = false;
                fchrome.lastPage = Shell.settingsPage;
            }
        }
        property string lastPage: Shell.settingsPage
        property bool goingBack: false
        function back() {
            if (!history.length)
                return;
            goingBack = true;
            const h = history.slice();
            const p = h.pop();
            history = h;
            Shell.settingsPage = p;
        }

        // ---- title bar ----
        MouseArea {
            width: parent.width
            height: 48
            acceptedButtons: Qt.LeftButton
            onPressed: if (win.hostWindow)
                win.hostWindow.startSystemMove()
            onDoubleClicked: if (win.hostWindow)
                win.hostWindow.maximized = !win.hostWindow.maximized
        }
        Rectangle {
            id: backBtn
            visible: fchrome.history.length > 0
            x: 6
            y: 6
            width: 40
            height: 36
            radius: 4
            color: bma.pressed ? WinStyle.subtlePress : bma.containsMouse ? WinStyle.subtleHover : "transparent"
            WinIcon {
                anchors.centerIn: parent
                name: "arrow_left-regular"
                size: 16
            }
            MouseArea {
                id: bma
                anchors.fill: parent
                hoverEnabled: true
                onClicked: fchrome.back()
            }
        }
        WinText {
            x: backBtn.visible ? 56 : 16
            y: 0
            height: 48
            text: I18n.t("Параметры", "Settings")
            font.pixelSize: 12
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 1
            y: 1
            Repeater {
                model: ["min", "max", "close"]
                Rectangle {
                    id: cap
                    required property string modelData
                    width: 46
                    height: 32
                    radius: modelData === "close" ? 0 : 0
                    color: cma.containsMouse ? (cap.modelData === "close" ? "#c42b1c" : WinStyle.subtleHover) : "transparent"
                    // Windows caption glyphs, drawn
                    Item {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        Rectangle {
                            visible: cap.modelData === "min"
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10
                            height: 1
                            color: WinStyle.text
                        }
                        Rectangle {
                            visible: cap.modelData === "max"
                            anchors.fill: parent
                            color: "transparent"
                            radius: 1.5
                            border.width: 1
                            border.color: WinStyle.text
                        }
                        Repeater {
                            model: cap.modelData === "close" ? [45, -45] : []
                            Rectangle {
                                required property int modelData
                                anchors.centerIn: parent
                                width: 13
                                height: 1
                                rotation: modelData
                                antialiasing: true
                                color: cma.containsMouse ? "#ffffff" : WinStyle.text
                            }
                        }
                    }
                    MouseArea {
                        id: cma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (cap.modelData === "close")
                                Shell.settingsOpen = false;
                            else if (cap.modelData === "max" && win.hostWindow)
                                win.hostWindow.maximized = !win.hostWindow.maximized;
                            else if (cap.modelData === "min")
                                Shell.settingsOpen = false;
                        }
                    }
                }
            }
        }

        // ---- navigation pane ----
        Item {
            id: nav
            x: 0
            y: 48
            width: 312
            height: parent.height - 48

            // account
            Item {
                id: acct
                x: 20
                y: 6
                width: parent.width - 40
                height: 84
                Item {
                    id: avBox
                    width: 64
                    height: 64
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: fav
                        anchors.fill: parent
                        source: WinStyle.avatar
                        sourceSize: Qt.size(128, 128)
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }
                    Rectangle {
                        id: favMask
                        anchors.fill: parent
                        radius: 32
                        visible: false
                        layer.enabled: true
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: fav
                        maskEnabled: true
                        maskSource: favMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1
                        visible: fav.status === Image.Ready
                    }
                }
                Column {
                    anchors.left: avBox.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 80
                    WinText {
                        width: parent.width
                        text: fchrome.fullName
                        strong: true
                    }
                    WinText {
                        width: parent.width
                        text: I18n.t("Локальная учётная запись", "Local account")
                        color: WinStyle.text2
                        font.pixelSize: 12
                    }
                }
            }

            // search
            PxField {
                id: fsearch
                x: 16
                y: 104
                width: parent.width - 32
                icon: "search"
                placeholder: I18n.t("Найти параметр", "Find a setting")
                onEdited: {
                    win.query = text;
                    win.sel = 0;
                }
                onAccepted: {
                    win.openResult(win.results[Math.min(win.sel, win.results.length - 1)]);
                    fsearch.text = "";
                }
                onKeyPressed: e => {
                    if (e.key === Qt.Key_Down) {
                        win.sel = Math.min(win.results.length - 1, win.sel + 1);
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Up) {
                        win.sel = Math.max(0, win.sel - 1);
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Escape && fsearch.text !== "") {
                        fsearch.text = "";
                        win.query = "";
                        e.accepted = true;
                    }
                }
            }

            // pages
            Flickable {
                id: navList
                x: 4
                y: 148
                width: parent.width - 8
                height: parent.height - y - 8
                contentHeight: navCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // the accent pill glides to the chosen page, like Windows
                Rectangle {
                    id: pill
                    z: 2
                    x: 12
                    width: 3
                    height: 16
                    radius: 1.5
                    color: WinStyle.accent
                    readonly property Item target: {
                        const i = fchrome.navPages.findIndex(p => p.id === Shell.settingsPage);
                        return i >= 0 ? navRep.itemAt(i) : null;
                    }
                    visible: !!target
                    y: target ? target.y + (target.height - height) / 2 : 0
                    Behavior on y {
                        NumberAnimation {
                            duration: WinStyle.slow
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: WinStyle.decelerate
                        }
                    }
                }
                Column {
                    id: navCol
                    width: navList.width
                    Repeater {
                        id: navRep
                        model: fchrome.navPages
                        Item {
                            id: ni
                            required property var modelData
                            readonly property bool sel: Shell.settingsPage === modelData.id
                            width: navCol.width
                            height: 40
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                anchors.topMargin: 2
                                anchors.bottomMargin: 2
                                radius: 4
                                color: nma.pressed ? WinStyle.subtlePress : ni.sel || nma.containsMouse ? WinStyle.subtleHover : "transparent"
                            }
                            Image {
                                x: 28
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                sourceSize: Qt.size(32, 32)
                                source: ni.modelData.id === "home" ? Qt.resolvedUrl("../bar/win/icons/c/person_circle-60cdff.svg") : fchrome.navIcon(ni.modelData.id)
                            }
                            WinText {
                                x: 60
                                width: parent.width - 76
                                anchors.verticalCenter: parent.verticalCenter
                                text: ni.modelData.label
                            }
                            MouseArea {
                                id: nma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Shell.settingsPage = ni.modelData.id
                            }
                        }
                    }
                }
            }

            // search results under the box
            Rectangle {
                visible: win.query.trim() !== ""
                z: 20
                x: 16
                y: fsearch.y + fsearch.height + 4
                width: fsearch.width
                height: Math.min(360, resList.contentHeight + 8)
                radius: 8
                color: WinStyle.menu
                border.width: 1
                border.color: WinStyle.flyoutLine
                ListView {
                    id: resList
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    model: win.results
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Item {
                        id: fr
                        required property var modelData
                        required property int index
                        width: resList.width
                        height: 40
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 4
                            color: win.sel === fr.index || frm.containsMouse ? WinStyle.subtleHover : "transparent"
                        }
                        Image {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            sourceSize: Qt.size(32, 32)
                            source: fchrome.navIcon(fr.modelData.page || "system")
                        }
                        Column {
                            x: 36
                            width: parent.width - 44
                            anchors.verticalCenter: parent.verticalCenter
                            WinText {
                                width: parent.width
                                text: fr.modelData.title
                                font.pixelSize: 13
                            }
                            WinText {
                                visible: text !== ""
                                width: parent.width
                                text: fr.modelData.crumb || ""
                                color: WinStyle.text2
                                font.pixelSize: 11
                            }
                        }
                        MouseArea {
                            id: frm
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: win.sel = fr.index
                            onClicked: {
                                win.openResult(fr.modelData);
                                fsearch.text = "";
                            }
                        }
                    }
                    WinText {
                        visible: win.results.length === 0
                        x: 10
                        height: 36
                        text: I18n.t("Ничего не найдено", "No results")
                        color: WinStyle.text2
                    }
                }
            }
        }

        // ---- content ----
        Item {
            id: content
            anchors.left: nav.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 48

            // breadcrumb title: "Group › Page"
            Row {
                id: crumb
                x: 20
                y: 8
                spacing: 12
                WinText {
                    visible: !!fchrome.current.group
                    text: fchrome.current.group || ""
                    color: WinStyle.text2
                    font.pixelSize: 28
                    font.family: WinStyle.fontDisplay
                    strong: true
                }
                WinIcon {
                    visible: !!fchrome.current.group
                    anchors.verticalCenter: parent.verticalCenter
                    name: "chevron_right-regular"
                    size: 16
                }
                WinText {
                    text: fchrome.current.label
                    font.pixelSize: 28
                    font.family: WinStyle.fontDisplay
                    strong: true
                }
            }
            Item {
                id: fpage
                x: 20
                y: 72
                width: parent.width - 28
                height: parent.height - y - 4
                clip: true
                // page change: slide up a little and fade in, like Windows
                property real t: 1
                opacity: t
                transform: Translate {
                    y: (1 - fpage.t) * 24
                }
                Connections {
                    target: Shell
                    function onSettingsPageChanged() {
                        if (win.fluent)
                            pageIn.restart();
                    }
                }
                NumberAnimation {
                    id: pageIn
                    target: fpage
                    property: "t"
                    from: 0
                    to: 1
                    duration: WinStyle.slow
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }
        }

        property string fullName: WinStyle.userName
        Process {
            running: win.fluent
            command: ["getent", "passwd", WinStyle.userName]
            stdout: StdioCollector {
                onStreamFinished: {
                    const g = (text.split(":")[4] || "").split(",")[0].trim();
                    if (g)
                        fchrome.fullName = g;
                }
            }
        }
        Shortcut {
            sequence: "Ctrl+F"
            enabled: win.fluent
            onActivated: fsearch.focusField()
        }
    }
}
