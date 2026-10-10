pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

// Windows 11 Start (bar.startStyle "windows"): search, "Закреплено" grid with
// pages, "Рекомендуем" (recently opened files), "Все приложения" list, search
// results with a details pane, the user and the power button at the foot.
// It rises from behind the taskbar (clipped at its top edge) like on Windows.
Item {
    id: root

    signal closeRequested
    property real reveal: 1
    property int current: -1
    property string query: ""
    property string view: "home"            // home | all | more  (search shows while query is set)
    readonly property bool searching: query.trim() !== ""
    property int page: 0
    property var menuItems: []              // the open local menu
    property point menuAt: Qt.point(0, 0)

    readonly property int margin: 32         // room for the shadow around the menu
    readonly property int mw: 642
    readonly property int mh: 726
    readonly property alias blurItem: menu
    width: mw + margin * 2
    height: mh + margin + 12

    clip: true

    // ---- data ----
    readonly property var pinnedIds: {
        const own = Config.win.startPinned || [];
        const ids = own.length ? own : StartApps.pinned.slice(0, 18).map(a => a.id);
        return ids.filter(id => StartApps.apps.some(a => a.id === id));
    }
    readonly property var pinned: pinnedIds.map(id => StartApps.apps.find(a => a.id === id))
    readonly property int rows: Config.win.recommended ? 3 : 6
    readonly property int perPage: 6 * rows
    readonly property int pages: Math.max(1, Math.ceil(pinned.length / perPage))
    readonly property var pageItems: pinned.slice(page * perPage, (page + 1) * perPage)

    function isPinned(app) {
        return pinnedIds.includes(app.id);
    }
    function togglePin(app) {
        const ids = pinnedIds.slice();
        const i = ids.indexOf(app.id);
        if (i >= 0)
            ids.splice(i, 1);
        else
            ids.push(app.id);
        Config.win.startPinned = ids;
    }
    function moveToFront(app) {
        Config.win.startPinned = [app.id].concat(pinnedIds.filter(id => id !== app.id));
        page = 0;
    }
    function taskbarPinned(app) {
        const ids = (Config.win.pinned || []).length ? Config.win.pinned : StartApps.frequent.slice(0, 6).map(a => a.id);
        return ids.includes(app.id);
    }
    function toggleTaskbar(app) {
        let ids = ((Config.win.pinned || []).length ? Config.win.pinned : StartApps.frequent.slice(0, 6).map(a => a.id)).slice();
        ids = ids.includes(app.id) ? ids.filter(i => i !== app.id) : ids.concat([app.id]);
        Config.win.pinned = ids;
    }

    // recently opened files (GTK's recently-used.xbel)
    property var recent: []
    property bool recentDirty: true
    FileView {
        id: xbel
        path: Quickshell.env("HOME") + "/.local/share/recently-used.xbel"
        watchChanges: true
        printErrors: false
        blockLoading: false
        onFileChanged: {
            root.recentDirty = true;
            reload();
        }
        // parse when the file changes, never while the menu is opening
        onLoaded: {
            root.recentDirty = true;
            Qt.callLater(root.parseRecent);
        }
    }
    function parseRecent() {
        if (!recentDirty)
            return;
        recentDirty = false;
        const t = xbel.text();
        if (!t)
            return;
        const re = /<bookmark href="([^"]+)"[^>]*?modified="([^"]+)"[^>]*?visited="([^"]+)"[^>]*>([\s\S]*?)<\/bookmark>/g;
        const out = [];
        let m;
        while ((m = re.exec(t)) !== null) {
            if (!m[1].startsWith("file://"))
                continue;
            const mime = (/mime-type type="([^"]+)"/.exec(m[4]) || [])[1] || "";
            const when = Math.max(Date.parse(m[2]) || 0, Date.parse(m[3]) || 0);
            let path = m[1].slice(7);
            try {
                path = decodeURIComponent(path);
            } catch (e) {}
            out.push({
                "path": path,
                "name": path.split("/").pop(),
                "dir": path.split("/").slice(0, -1).join("/"),
                "mime": mime,
                "when": when
            });
        }
        out.sort((a, b) => b.when - a.when);
        const seen = {};
        recent = out.filter(r => !seen[r.path] && (seen[r.path] = true)).slice(0, 40);
    }
    function mimeIcon(mime) {
        if (mime === "inode/directory")
            return Quickshell.iconPath("folder", true);
        const a = mime.replace("/", "-");
        const g = mime.split("/")[0] + "-x-generic";
        return Quickshell.iconPath(a, true) || Quickshell.iconPath(g, true) || Quickshell.iconPath("text-x-generic", true);
    }
    function ago(ms) {
        const d = (Date.now() - ms) / 1000;
        if (d < 60)
            return I18n.t("Только что", "Just now");
        if (d < 3600)
            return Math.floor(d / 60) + I18n.t(" мин. назад", " min ago");
        const then = new Date(ms), now = new Date();
        if (then.toDateString() === now.toDateString())
            return Math.floor(d / 3600) + I18n.t(" ч. назад", " h ago");
        const y = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
        if (then.toDateString() === y.toDateString())
            return I18n.t("Вчера в ", "Yesterday at ") + Qt.formatTime(then, "HH:mm");
        return Qt.locale().toString(then, "d MMM");
    }

    // search results: best match, apps, documents
    readonly property var results: {
        if (!searching)
            return [];
        const q = query.trim().toLowerCase();
        const apps = StartApps.search(q).slice(0, 9).map(a => ({
                    "kind": "app",
                    "app": a
                }));
        const docs = recent.filter(r => r.name.toLowerCase().includes(q)).slice(0, 5).map(r => ({
                    "kind": "file",
                    "file": r
                }));
        return apps.concat(docs);
    }
    readonly property var selected: searching ? results[Math.max(0, current)] || null : null

    // display name from passwd
    property string fullName: WinStyle.userName
    Process {
        running: true
        command: ["getent", "passwd", WinStyle.userName]
        stdout: StdioCollector {
            onStreamFinished: {
                const g = (text.split(":")[4] || "").split(",")[0].trim();
                if (g)
                    root.fullName = g;
            }
        }
    }

    // ---- actions ----
    function reset() {
        current = -1;
        query = "";
        view = "home";
        page = 0;
        menuItems = [];
    }
    function run(app) {
        closeRequested();
        Qt.callLater(() => StartApps.launch(app));
    }
    function openFile(f) {
        closeRequested();
        Qt.callLater(() => Shell.openPath(f.path));
    }
    function act(fn) {
        closeRequested();
        Qt.callLater(fn);
    }
    function openResult(r) {
        if (!r)
            return;
        if (r.kind === "app")
            run(r.app);
        else
            openFile(r.file);
    }
    function showMenu(items, item, x, y) {
        const p = item.mapToItem(menu, x, y);
        menuAt = Qt.point(p.x, p.y);
        menuItems = items;
    }
    function appMenu(app, item, x, y) {
        showMenu([
            {
                "text": I18n.t("Открыть", "Open"),
                "icon": "apps-regular",
                "run": () => run(app)
            },
            {
                "text": isPinned(app) ? I18n.t("Открепить от начального экрана", "Unpin from Start") : I18n.t("Закрепить на начальном экране", "Pin to Start"),
                "icon": isPinned(app) ? "pin_off-regular" : "pin-regular",
                "run": () => togglePin(app)
            },
            {
                "text": taskbarPinned(app) ? I18n.t("Открепить от панели задач", "Unpin from taskbar") : I18n.t("Закрепить на панели задач", "Pin to taskbar"),
                "icon": taskbarPinned(app) ? "pin_off-regular" : "pin-regular",
                "run": () => toggleTaskbar(app)
            }
        ].concat(isPinned(app) && pinnedIds.indexOf(app.id) > 0 ? [
            {
                "text": I18n.t("Переместить в начало", "Move to front"),
                "icon": "arrow_clockwise-regular",
                "run": () => moveToFront(app)
            }
        ] : []), item, x, y);
    }

    // keys come from the overlay; the query is typed here
    function key(e) {
        const mods = e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier);
        if (e.key === Qt.Key_Escape) {
            if (menuItems.length)
                menuItems = [];
            else if (searching)
                query = "";
            else if (view !== "home")
                view = "home";
            else
                closeRequested();
        } else if (e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R)
            closeRequested();
        else if (e.key === Qt.Key_Backspace) {
            query = (e.modifiers & Qt.ControlModifier) ? query.replace(/\S*\s*$/, "") : query.slice(0, -1);
            current = -1;
        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            if (searching)
                openResult(root.results[Math.max(0, current)]);
            else if (view === "home" && current >= 0 && pageItems[current])
                run(pageItems[current]);
            else if (view === "all" && current >= 0)
                run(StartApps.apps[current]);
        } else if (e.key === Qt.Key_Down || e.key === Qt.Key_Up || e.key === Qt.Key_Left || e.key === Qt.Key_Right) {
            const dy = e.key === Qt.Key_Down ? 1 : e.key === Qt.Key_Up ? -1 : 0;
            const dx = e.key === Qt.Key_Right ? 1 : e.key === Qt.Key_Left ? -1 : 0;
            const n = searching ? root.results.length : view === "home" ? pageItems.length : StartApps.apps.length;
            if (!n)
                return;
            if (current < 0)
                current = 0;
            else if (searching || view === "all")
                current = Math.max(0, Math.min(n - 1, current + dy + dx));
            else
                current = Math.max(0, Math.min(n - 1, current + dx + dy * 6));
            if (view === "all" && !searching)
                allList.positionViewAtIndex(current, ListView.Contain);
        } else if (e.key === Qt.Key_V && (e.modifiers & Qt.ControlModifier)) {
            // no clipboard read from here; ignore
        } else if (e.text && e.text.length && !mods && e.text.charCodeAt(0) >= 32) {
            query += e.text;
            current = 0;
        } else
            return;
        e.accepted = true;
    }

    // ---- the menu surface ----
    RectangularShadow {
        anchors.fill: menu
        radius: 8
        blur: 30
        offset.y: 8
        color: WinStyle.shadow
        opacity: menu.opacity
    }
    Rectangle {
        id: menu
        x: root.margin
        y: root.margin + (1 - root.reveal) * (root.mh + 12)
        width: root.mw
        height: root.mh
        radius: 8
        color: WinStyle.flyout
        border.width: 1
        border.color: WinStyle.flyoutLine
        opacity: Math.min(1, root.reveal * 2)
        clip: true

        // a click anywhere closes the open local menu
        MouseArea {
            anchors.fill: parent
            enabled: root.menuItems.length > 0
            z: 50
            acceptedButtons: Qt.AllButtons
            onPressed: root.menuItems = []
        }

        // search box
        Rectangle {
            id: search
            x: 32
            y: 28
            width: root.mw - 64
            height: 36
            radius: 18
            color: WinStyle.field
            border.width: 1
            border.color: WinStyle.controlLine
            Rectangle {
                // focused underline (accent), like a Fluent text box
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 36
                height: 2
                radius: 1
                color: WinStyle.accent
                opacity: root.searching ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: WinStyle.fast
                    }
                }
            }
            WinIcon {
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                name: "search-regular"
                size: 16
            }
            WinText {
                id: qText
                x: 42
                width: parent.width - 60
                anchors.verticalCenter: parent.verticalCenter
                text: root.query || I18n.t("Поиск приложений, параметров и документов", "Search for apps, settings and documents")
                color: root.query ? WinStyle.text : WinStyle.text3
            }
            Rectangle {
                // caret
                x: qText.x + (root.query ? Math.min(qText.width, qText.contentWidth) + 1 : 0)
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 18
                color: WinStyle.text
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.reveal > 0.5
                    NumberAnimation {
                        to: 1
                        duration: 0
                    }
                    PauseAnimation {
                        duration: 530
                    }
                    NumberAnimation {
                        to: 0
                        duration: 0
                    }
                    PauseAnimation {
                        duration: 530
                    }
                }
            }
        }

        // ---- home: pinned + recommended ----
        Item {
            id: home
            y: 80
            width: root.mw
            height: root.mh - 80 - 64
            readonly property real t: !root.searching && root.view === "home" ? 1 : 0
            opacity: t
            visible: opacity > 0
            x: (1 - t) * -48
            Behavior on opacity {
                NumberAnimation {
                    duration: WinStyle.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }

            SectionHead {
                y: 8
                title: I18n.t("Закреплено", "Pinned")
                button: I18n.t("Все приложения", "All apps")
                onButtonClicked: {
                    root.view = "all";
                    root.current = -1;
                }
            }

            Item {
                id: pinArea
                x: 33
                y: 44
                width: 576
                height: root.rows * 90
                clip: true

                Grid {
                    id: grid
                    columns: 6
                    y: pageAnim.offset
                    Repeater {
                        model: root.pageItems
                        Item {
                            id: tile
                            required property var modelData
                            required property int index
                            readonly property bool sel: root.current === index && !root.searching
                            width: 96
                            height: 90
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 4
                                color: tma.pressed ? WinStyle.subtlePress : tma.containsMouse || tile.sel ? WinStyle.subtleHover : "transparent"
                                border.width: tile.sel ? 2 : 0
                                border.color: WinStyle.text
                            }
                            AppIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 16
                                appId: tile.modelData.id
                                iconName: tile.modelData.icon || ""
                                size: 32
                                scale: tma.pressed ? 0.88 : 1
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: WinStyle.fast
                                    }
                                }
                            }
                            WinText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 56
                                width: 84
                                horizontalAlignment: Text.AlignHCenter
                                text: tile.modelData.name
                                font.pixelSize: WinStyle.caption
                            }
                            MouseArea {
                                id: tma
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: m => m.button === Qt.RightButton ? root.appMenu(tile.modelData, tile, m.x, m.y) : root.run(tile.modelData)
                            }
                        }
                    }
                }
                WheelHandler {
                    onWheel: e => {
                        const np = Math.max(0, Math.min(root.pages - 1, root.page + (e.angleDelta.y < 0 ? 1 : -1)));
                        if (np !== root.page)
                            pageAnim.flip(np);
                    }
                }
            }
            // page flip: slide the grid away and the next page in
            QtObject {
                id: pageAnim
                property real offset: 0
                function flip(np) {
                    const dir = np > root.page ? 1 : -1;
                    root.page = np;
                    root.current = -1;
                    offset = dir * 60;
                    slide.restart();
                }
                property NumberAnimation slide: NumberAnimation {
                    target: pageAnim
                    property: "offset"
                    to: 0
                    duration: WinStyle.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }
            // page dots
            Column {
                visible: root.pages > 1
                x: root.mw - 22
                anchors.verticalCenter: pinArea.verticalCenter
                spacing: 8
                Repeater {
                    model: root.pages
                    Rectangle {
                        required property int index
                        width: 6
                        height: index === root.page ? 12 : 6
                        radius: 3
                        color: index === root.page ? WinStyle.text2 : WinStyle.text3
                        Behavior on height {
                            NumberAnimation {
                                duration: WinStyle.fast
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: if (parent.index !== root.page)
                                pageAnim.flip(parent.index)
                        }
                    }
                }
            }

            // recommended
            Item {
                visible: Config.win.recommended
                y: pinArea.y + pinArea.height + 12
                width: root.mw
                height: parent.height - y

                SectionHead {
                    title: I18n.t("Рекомендуем", "Recommended")
                    button: I18n.t("Дополнительно", "More")
                    showButton: root.recent.length > 6
                    onButtonClicked: {
                        root.view = "more";
                        root.current = -1;
                    }
                }
                WinText {
                    visible: root.recent.length === 0
                    x: 56
                    y: 48
                    width: root.mw - 112
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    text: I18n.t("Чем больше вы пользуетесь устройством, тем больше новых элементов будет здесь появляться.", "The more you use your device, the more we'll show your new apps here.")
                    color: WinStyle.text2
                    font.pixelSize: WinStyle.caption
                }
                Grid {
                    x: 40
                    y: 40
                    columns: 2
                    columnSpacing: 8
                    Repeater {
                        model: root.recent.slice(0, 6)
                        FileRow {
                            required property var modelData
                            file: modelData
                            width: 277
                        }
                    }
                }
            }
        }

        // ---- all apps / more recent ----
        Item {
            id: listView
            y: 80
            width: root.mw
            height: root.mh - 80 - 64
            readonly property real t: !root.searching && root.view !== "home" ? 1 : 0
            opacity: t
            visible: opacity > 0
            x: (1 - t) * 48
            Behavior on opacity {
                NumberAnimation {
                    duration: WinStyle.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }

            SectionHead {
                y: 8
                title: root.view === "more" ? I18n.t("Рекомендуем", "Recommended") : I18n.t("Все приложения", "All apps")
                button: I18n.t("Назад", "Back")
                back: true
                onButtonClicked: {
                    root.view = "home";
                    root.current = -1;
                }
            }

            ListView {
                id: allList
                visible: root.view === "all"
                x: 40
                y: 44
                width: root.mw - 72
                height: parent.height - 48
                clip: true
                model: StartApps.apps
                boundsBehavior: Flickable.StopAtBounds
                delegate: Item {
                    id: arow
                    required property var modelData
                    required property int index
                    // letter groups like Windows: a header before the first app of each letter
                    function letter(a) {
                        const c = String(a ? a.name : "").charAt(0).toUpperCase();
                        return c.toLowerCase() !== c ? c : "#";
                    }
                    readonly property string head: letter(modelData)
                    readonly property bool first: index === 0 || letter(StartApps.apps[index - 1]) !== head
                    width: allList.width
                    height: (first ? 40 : 0) + 40
                    Rectangle {
                        visible: arow.first
                        x: 4
                        y: 4
                        width: 32
                        height: 32
                        radius: 4
                        color: secMa.containsMouse ? WinStyle.subtleHover : "transparent"
                        WinText {
                            anchors.centerIn: parent
                            text: arow.head
                            strong: true
                        }
                        MouseArea {
                            id: secMa
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: (arow.first ? 40 : 0) + 2
                        anchors.leftMargin: 2
                        anchors.rightMargin: 2
                        anchors.bottomMargin: 2
                        radius: 4
                        color: ama.pressed ? WinStyle.subtlePress : ama.containsMouse || root.current === arow.index ? WinStyle.subtleHover : "transparent"
                    }
                    AppIcon {
                        x: 16
                        y: (arow.first ? 40 : 0) + 8
                        appId: arow.modelData.id
                        iconName: arow.modelData.icon || ""
                        size: 24
                    }
                    WinText {
                        x: 56
                        y: arow.first ? 40 : 0
                        height: 40
                        width: parent.width - 72
                        text: arow.modelData.name
                    }
                    MouseArea {
                        id: ama
                        anchors.fill: parent
                        anchors.topMargin: arow.first ? 40 : 0
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: m => m.button === Qt.RightButton ? root.appMenu(arow.modelData, arow, m.x, m.y) : root.run(arow.modelData)
                    }
                }
            }
            ListView {
                visible: root.view === "more"
                x: 40
                y: 44
                width: root.mw - 72
                height: parent.height - 48
                clip: true
                spacing: 2
                model: root.recent
                boundsBehavior: Flickable.StopAtBounds
                delegate: FileRow {
                    required property var modelData
                    file: modelData
                    width: ListView.view.width
                }
            }
        }

        // ---- search results ----
        Item {
            id: resultsPane
            width: root.mw
            height: root.mh - 80 - 64
            readonly property real t: root.searching ? 1 : 0
            opacity: t
            visible: opacity > 0
            y: 80 + (1 - t) * 24
            Behavior on opacity {
                NumberAnimation {
                    duration: WinStyle.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }

            WinText {
                visible: root.searching && root.results.length === 0
                x: 56
                y: 24
                text: I18n.t("Ничего не найдено по запросу «", "No results for “") + root.query.trim() + I18n.t("»", "”")
                color: WinStyle.text2
            }

            // left: list
            Flickable {
                x: 24
                y: 8
                width: 300
                height: parent.height - 16
                contentHeight: resCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: resCol
                    width: parent.width
                    Repeater {
                        model: root.results
                        Column {
                            id: rr
                            required property var modelData
                            required property int index
                            readonly property bool best: index === 0
                            readonly property bool firstDoc: modelData.kind === "file" && (index === 0 || root.results[index - 1].kind !== "file")
                            readonly property bool firstApp: modelData.kind === "app" && index === 1
                            width: parent.width
                            WinText {
                                visible: rr.best || rr.firstDoc || rr.firstApp
                                height: visible ? 32 : 0
                                x: 12
                                text: rr.best ? I18n.t("Лучшее соответствие", "Best match") : rr.firstDoc ? I18n.t("Документы", "Documents") : I18n.t("Приложения", "Apps")
                                strong: true
                                font.pixelSize: WinStyle.caption
                            }
                            Item {
                                width: parent.width
                                height: rr.best ? 64 : 40
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    radius: 4
                                    color: root.current === rr.index || root.current < 0 && rr.best ? WinStyle.subtleHover : rma.containsMouse ? WinStyle.subtlePress : "transparent"
                                    Rectangle {
                                        visible: root.current === rr.index || root.current < 0 && rr.best
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 3
                                        height: 16
                                        radius: 1.5
                                        color: WinStyle.accent
                                    }
                                }
                                AppIcon {
                                    visible: rr.modelData.kind === "app"
                                    x: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    appId: rr.modelData.app ? rr.modelData.app.id : ""
                                    iconName: rr.modelData.app ? rr.modelData.app.icon || "" : ""
                                    size: rr.best ? 32 : 20
                                }
                                Image {
                                    visible: rr.modelData.kind === "file"
                                    x: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rr.best ? 32 : 20
                                    height: width
                                    sourceSize: Qt.size(64, 64)
                                    source: rr.modelData.file ? root.mimeIcon(rr.modelData.file.mime) : ""
                                }
                                Column {
                                    x: rr.best ? 58 : 46
                                    width: parent.width - x - 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    WinText {
                                        width: parent.width
                                        text: rr.modelData.kind === "app" ? rr.modelData.app.name : rr.modelData.file.name
                                        strong: rr.best
                                    }
                                    WinText {
                                        visible: rr.best || rr.modelData.kind === "file"
                                        width: parent.width
                                        text: rr.modelData.kind === "app" ? I18n.t("Приложение", "App") : rr.modelData.file.dir.replace(Quickshell.env("HOME"), "~")
                                        color: WinStyle.text2
                                        font.pixelSize: WinStyle.caption
                                    }
                                }
                                MouseArea {
                                    id: rma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onEntered: root.current = rr.index
                                    onClicked: m => {
                                        if (m.button === Qt.RightButton && rr.modelData.kind === "app")
                                            root.appMenu(rr.modelData.app, rma, m.x, m.y);
                                        else
                                            root.openResult(rr.modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // right: details of the selected result
            Rectangle {
                visible: !!root.selected
                x: 336
                y: 8
                width: root.mw - 336 - 24
                height: parent.height - 16
                radius: 8
                color: WinStyle.card
                border.width: 1
                border.color: WinStyle.controlLine
                readonly property var s: root.selected
                readonly property bool isApp: !!s && s.kind === "app"

                AppIcon {
                    visible: parent.isApp
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 36
                    appId: parent.isApp ? parent.s.app.id : ""
                    iconName: parent.isApp ? parent.s.app.icon || "" : ""
                    size: 64
                }
                Image {
                    visible: !parent.isApp && !!parent.s
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 36
                    width: 64
                    height: 64
                    sourceSize: Qt.size(128, 128)
                    source: parent.s && parent.s.file ? root.mimeIcon(parent.s.file.mime) : ""
                }
                WinText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 116
                    width: parent.width - 32
                    horizontalAlignment: Text.AlignHCenter
                    text: !parent.s ? "" : parent.isApp ? parent.s.app.name : parent.s.file.name
                    font.pixelSize: WinStyle.subtitle
                    font.family: WinStyle.fontDisplay
                    strong: true
                }
                WinText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 148
                    text: !parent.s ? "" : parent.isApp ? I18n.t("Приложение", "App") : root.ago(parent.s.file.when)
                    color: WinStyle.text2
                    font.pixelSize: WinStyle.caption
                }
                Rectangle {
                    x: 16
                    y: 180
                    width: parent.width - 32
                    height: 1
                    color: WinStyle.divider
                }
                Column {
                    x: 8
                    y: 188
                    width: parent.width - 16
                    Repeater {
                        model: {
                            const s = root.selected;
                            if (!s)
                                return [];
                            if (s.kind === "file")
                                return [
                                    {
                                        "text": I18n.t("Открыть", "Open"),
                                        "icon": "document-regular",
                                        "run": () => root.openFile(s.file)
                                    },
                                    {
                                        "text": I18n.t("Открыть расположение файла", "Open file location"),
                                        "icon": "folder-regular",
                                        "run": () => root.act(() => Shell.openPath(s.file.dir))
                                    }
                                ];
                            const a = s.app;
                            return [
                                {
                                    "text": I18n.t("Открыть", "Open"),
                                    "icon": "apps-regular",
                                    "run": () => root.run(a)
                                },
                                {
                                    "text": root.isPinned(a) ? I18n.t("Открепить от начального экрана", "Unpin from Start") : I18n.t("Закрепить на начальном экране", "Pin to Start"),
                                    "icon": root.isPinned(a) ? "pin_off-regular" : "pin-regular",
                                    "run": () => root.togglePin(a)
                                },
                                {
                                    "text": root.taskbarPinned(a) ? I18n.t("Открепить от панели задач", "Unpin from taskbar") : I18n.t("Закрепить на панели задач", "Pin to taskbar"),
                                    "icon": root.taskbarPinned(a) ? "pin_off-regular" : "pin-regular",
                                    "run": () => root.toggleTaskbar(a)
                                }
                            ];
                        }
                        Item {
                            id: act
                            required property var modelData
                            width: parent.width
                            height: 36
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: 4
                                color: actMa.containsMouse ? WinStyle.subtleHover : "transparent"
                            }
                            WinIcon {
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                name: act.modelData.icon
                            }
                            WinText {
                                x: 40
                                width: parent.width - 48
                                anchors.verticalCenter: parent.verticalCenter
                                text: act.modelData.text
                            }
                            MouseArea {
                                id: actMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: act.modelData.run()
                            }
                        }
                    }
                }
            }
        }

        // ---- footer: user and power ----
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 64
            color: WinStyle.flyoutFoot
            Rectangle {
                width: parent.width
                height: 1
                color: WinStyle.divider
            }

            Item {
                id: user
                x: 40
                width: Math.min(260, userRow.implicitWidth + 24)
                height: 40
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: uma.pressed ? WinStyle.subtlePress : uma.containsMouse ? WinStyle.subtleHover : "transparent"
                }
                Row {
                    id: userRow
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    Item {
                        width: 32
                        height: 32
                        Rectangle {
                            id: avFallback
                            anchors.fill: parent
                            radius: 16
                            color: WinStyle.control
                            visible: av.status !== Image.Ready
                            WinIcon {
                                anchors.centerIn: parent
                                name: "person-regular"
                            }
                        }
                        Image {
                            id: av
                            anchors.fill: parent
                            source: WinStyle.avatar
                            sourceSize: Qt.size(64, 64)
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }
                        Rectangle {
                            id: avMask
                            anchors.fill: parent
                            radius: 16
                            visible: false
                            layer.enabled: true
                        }
                        MultiEffect {
                            anchors.fill: parent
                            visible: av.status === Image.Ready
                            source: av
                            maskEnabled: true
                            maskSource: avMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1
                        }
                    }
                    WinText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.fullName
                        font.pixelSize: WinStyle.caption
                    }
                }
                MouseArea {
                    id: uma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.showMenu([
                        {
                            "text": I18n.t("Изменить параметры учётной записи", "Change account settings"),
                            "icon": "person-regular",
                            "run": () => root.act(() => Shell.openSettings("home"))
                        },
                        {
                            "text": I18n.t("Заблокировать", "Lock"),
                            "icon": "lock_closed-regular",
                            "run": () => root.act(() => Shell.lock())
                        },
                        {
                            "text": I18n.t("Выход", "Sign out"),
                            "icon": "sign_out-regular",
                            "run": () => root.act(() => Shell.exec(["niri", "msg", "action", "quit", "--skip-confirmation"]))
                        }
                    ], user, 0, -4)
                }
            }

            Rectangle {
                id: power
                anchors.right: parent.right
                anchors.rightMargin: 40
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 4
                color: pma.pressed ? WinStyle.subtlePress : pma.containsMouse ? WinStyle.subtleHover : "transparent"
                WinIcon {
                    anchors.centerIn: parent
                    name: "power-regular"
                }
                MouseArea {
                    id: pma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.showMenu([
                        {
                            "text": I18n.t("Спящий режим", "Sleep"),
                            "icon": "weather_moon-regular",
                            "run": () => root.act(() => Shell.exec(["systemctl", "suspend"]))
                        },
                        {
                            "text": I18n.t("Завершение работы", "Shut down"),
                            "icon": "power-regular",
                            "run": () => root.act(() => Shell.exec(["systemctl", "poweroff"]))
                        },
                        {
                            "text": I18n.t("Перезагрузка", "Restart"),
                            "icon": "arrow_clockwise-regular",
                            "run": () => root.act(() => Shell.exec(["systemctl", "reboot"]))
                        }
                    ], power, power.width, -4)
                }
            }
        }

        // ---- local context menu ----
        Rectangle {
            id: ctx
            visible: root.menuItems.length > 0
            z: 60
            width: Math.max(200, ctxCol.implicitWidth)
            height: ctxCol.implicitHeight + 8
            // open upwards when near the bottom, keep inside the menu
            x: Math.max(8, Math.min(root.mw - width - 8, root.menuAt.x - (root.menuAt.y > root.mh - 80 ? width : 0)))
            y: root.menuAt.y > root.mh / 2 ? Math.max(8, root.menuAt.y - height) : Math.min(root.mh - height - 8, root.menuAt.y)
            radius: 8
            color: WinStyle.menu
            border.width: 1
            border.color: WinStyle.flyoutLine
            onVisibleChanged: if (visible)
                ctxIn.restart()
            NumberAnimation {
                id: ctxIn
                target: ctx
                property: "opacity"
                from: 0
                to: 1
                duration: WinStyle.fast
            }
            Column {
                id: ctxCol
                y: 4
                width: parent.width
                Repeater {
                    model: root.menuItems
                    Item {
                        id: ci
                        required property var modelData
                        width: ctxCol.width
                        implicitWidth: 64 + ciText.implicitWidth
                        height: 36
                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            anchors.topMargin: 2
                            anchors.bottomMargin: 2
                            radius: 4
                            color: cima.containsMouse ? WinStyle.subtleHover : "transparent"
                        }
                        WinIcon {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            name: ci.modelData.icon || ""
                        }
                        WinText {
                            id: ciText
                            x: 44
                            anchors.verticalCenter: parent.verticalCenter
                            text: ci.modelData.text
                        }
                        MouseArea {
                            id: cima
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.menuItems = [];
                                ci.modelData.run();
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- pieces ----
    component SectionHead: Item {
        id: sh
        property string title: ""
        property string button: ""
        property bool back: false
        property bool showButton: true
        signal buttonClicked
        width: root.mw
        height: 28
        WinText {
            x: 56
            anchors.verticalCenter: parent.verticalCenter
            text: sh.title
            strong: true
        }
        Rectangle {
            visible: sh.showButton
            anchors.right: parent.right
            anchors.rightMargin: 48
            anchors.verticalCenter: parent.verticalCenter
            width: btnRow.implicitWidth + 20
            height: 24
            radius: 4
            color: sbma.pressed ? WinStyle.subtlePress : sbma.containsMouse ? WinStyle.controlHover : WinStyle.control
            border.width: 1
            border.color: WinStyle.controlLine
            Row {
                id: btnRow
                anchors.centerIn: parent
                spacing: 6
                layoutDirection: sh.back ? Qt.RightToLeft : Qt.LeftToRight
                WinText {
                    text: sh.button
                    font.pixelSize: WinStyle.caption
                }
                WinIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: sh.back ? "chevron_left-regular" : "chevron_right-regular"
                    size: 12
                }
            }
            MouseArea {
                id: sbma
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sh.buttonClicked()
            }
        }
    }

    component FileRow: Item {
        id: fr
        required property var file
        height: 56
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 4
            color: frma.pressed ? WinStyle.subtlePress : frma.containsMouse ? WinStyle.subtleHover : "transparent"
        }
        Image {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            sourceSize: Qt.size(64, 64)
            source: root.mimeIcon(fr.file.mime)
        }
        Column {
            x: 58
            width: parent.width - 70
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            WinText {
                width: parent.width
                text: fr.file.name
                font.pixelSize: WinStyle.caption
            }
            WinText {
                width: parent.width
                text: root.ago(fr.file.when)
                color: WinStyle.text2
                font.pixelSize: WinStyle.caption
            }
        }
        MouseArea {
            id: frma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => {
                if (m.button === Qt.RightButton)
                    root.showMenu([
                        {
                            "text": I18n.t("Открыть", "Open"),
                            "icon": "document-regular",
                            "run": () => root.openFile(fr.file)
                        },
                        {
                            "text": I18n.t("Открыть расположение файла", "Open file location"),
                            "icon": "folder-regular",
                            "run": () => root.act(() => Shell.openPath(fr.file.dir))
                        }
                    ], fr, m.x, m.y);
                else
                    root.openFile(fr.file);
            }
        }
    }
}
