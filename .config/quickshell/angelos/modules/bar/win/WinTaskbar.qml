pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar.parts

// Windows 11 taskbar (bar.style "windows"): 48 px acrylic strip, Start / Search /
// Task view and app buttons (pinned + running, grouped by app) in the middle,
// hidden-icons chevron, quick settings, clock and the bell on the right.
PanelWindow {
    id: win

    required property var modelData
    readonly property string screenName: modelData.name
    readonly property bool centred: Config.win.align !== "left"

    screen: modelData
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: 48
    exclusionMode: Shell.dev ? ExclusionMode.Ignore : ExclusionMode.Auto
    color: "transparent"
    WlrLayershell.namespace: "angelos-bar"
    WlrLayershell.layer: WlrLayer.Top

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: bg
    }

    // ---- apps on the taskbar ----
    function keyOf(appId) {
        const e = appId ? DesktopEntries.heuristicLookup(appId) : null;
        return e ? e.id : appId || "?";
    }
    readonly property var pinnedIds: {
        const ids = (Config.win.pinned || []).filter(id => StartApps.apps.some(a => a.id === id));
        return ids.length || (Config.win.pinned || []).length ? ids : StartApps.frequent.slice(0, 6).map(a => a.id);
    }
    readonly property var entries: {
        const out = [];
        const byKey = {};
        for (const id of pinnedIds) {
            const e = {
                "key": id,
                "app": StartApps.apps.find(a => a.id === id) || null,
                "appId": id,
                "pinned": true,
                "windows": []
            };
            byKey[id] = e;
            out.push(e);
        }
        for (const w of Niri.sortedWindows(Niri.windows)) {
            const k = keyOf(w.app_id);
            let e = byKey[k];
            if (!e) {
                e = {
                    "key": k,
                    "app": DesktopEntries.heuristicLookup(w.app_id || "") || null,
                    "appId": w.app_id || "",
                    "pinned": false,
                    "windows": []
                };
                byKey[k] = e;
                out.push(e);
            }
            e.windows.push(w);
        }
        // the order the user dragged icons into (unknown apps keep their place after)
        const ord = Config.win.order || [];
        const pos = k => {
            const i = ord.indexOf(k);
            return i >= 0 ? i : 10000;
        };
        return out.map((e, i) => ({
                    "e": e,
                    "i": i
                })).sort((a, b) => pos(a.e.key) - pos(b.e.key) || a.i - b.i).map(x => x.e);
    }
    readonly property var entryMap: {
        const m = {};
        for (const e of entries)
            m[e.key] = e;
        return m;
    }

    // Buttons live in a ListModel that is only patched (insert / remove / move),
    // so switching workspaces or focus never rebuilds them (no blinking icons).
    ListModel {
        id: appModel
    }
    property string dragKey: ""
    function syncModel() {
        if (dragKey !== "")
            return;
        const target = entries.map(e => e.key);
        for (let i = appModel.count - 1; i >= 0; i--)
            if (!target.includes(appModel.get(i).key))
                appModel.remove(i);
        for (let i = 0; i < target.length; i++) {
            if (i < appModel.count && appModel.get(i).key === target[i])
                continue;
            let j = -1;
            for (let k = i + 1; k < appModel.count; k++)
                if (appModel.get(k).key === target[i]) {
                    j = k;
                    break;
                }
            if (j >= 0)
                appModel.move(j, i, 1);
            else
                appModel.insert(i, {
                    "key": target[i]
                });
        }
    }
    onEntriesChanged: syncModel()
    Component.onCompleted: syncModel()
    function saveOrder() {
        const keys = [];
        for (let i = 0; i < appModel.count; i++)
            keys.push(appModel.get(i).key);
        Config.win.order = keys.concat((Config.win.order || []).filter(k => !keys.includes(k)));
    }
    function setPinned(ids) {
        Config.win.pinned = ids;
    }
    function togglePin(e) {
        const ids = pinnedIds.slice();
        const i = ids.indexOf(e.key);
        if (i >= 0)
            ids.splice(i, 1);
        else
            ids.push(e.key);
        setPinned(ids);
    }
    function activate(e) {
        if (!e.windows.length)
            return launch(e);
        const i = e.windows.findIndex(w => w.is_focused);
        Niri.focusWindow((i >= 0 ? e.windows[(i + 1) % e.windows.length] : e.windows[0]).id);
    }
    function launch(e) {
        if (e && e.app)
            StartApps.launch(e.app);
    }

    // ---- surface ----
    Item {
        id: content
        anchors.fill: parent

        Rectangle {
            id: bg
            anchors.fill: parent
            color: WinStyle.taskbar
            Rectangle {
                width: parent.width
                height: 1
                color: WinStyle.taskbarLine
            }
        }

        // right click on empty taskbar
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: m => barMenu.openAbove(content, [
                    {
                        "text": I18n.t("Параметры панели задач", "Taskbar settings"),
                        "icon": "settings-regular",
                        "run": () => Shell.openSettings("layouts")
                    },
                    {
                        "text": I18n.t("Диспетчер задач", "Task Manager"),
                        "icon": "apps-regular",
                        "run": () => DesktopActions.launchMonitor()
                    }
                ], m.x)
        }
        MouseArea {
            anchors.fill: parent
            z: 100
            acceptedButtons: Qt.AllButtons
            onPressed: m => {
                PopupManager.barPressed();
                m.accepted = false;
            }
        }

        // song line where Windows keeps Widgets (Settings → Раскладки)
        Loader {
            active: Config.win.lyrics && win.centred
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: BarLyrics {
                screenName: win.screenName
                maxWidth: Math.max(0, mid.x - 40)
                fixedWidth: false
            }
        }

        // ---- middle: Start, Search, Task view, apps ----
        Row {
            id: mid
            x: win.centred ? Math.round((parent.width - width) / 2) : 12
            height: parent.height
            spacing: 0
            move: Transition {
                NumberAnimation {
                    properties: "x"
                    duration: WinStyle.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }
            Behavior on x {
                NumberAnimation {
                    duration: WinStyle.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.standard
                }
            }

            TaskButton {
                id: startBtn
                width: 44
                tip: I18n.t("Пуск", "Start")
                onClicked: Shell.toggleStart(win.screenName)
                onRightClicked: winX.openAbove(startBtn, win.winXItems(), startBtn.width / 2)
                WinLogo {
                    anchors.centerIn: parent
                    size: 20
                    scale: startBtn.pressed ? 0.8 : 1
                    Behavior on scale {
                        NumberAnimation {
                            duration: WinStyle.fast
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: WinStyle.decelerate
                        }
                    }
                }
                onHoveredChanged: {
                    if (hovered) {
                        coolStart.stop();
                        Shell.startWarm = win.screenName;
                    } else
                        coolStart.restart();
                }
                Timer {
                    id: coolStart
                    interval: 1500
                    onTriggered: if (Shell.startWarm === win.screenName)
                        Shell.startWarm = ""
                }
                Component.onCompleted: Shell.registerStartButton(win.screenName, startBtn, win)
                Component.onDestruction: Shell.unregisterStartButton(win.screenName, startBtn)
            }
            TaskButton {
                id: searchBtn
                visible: Config.win.search
                width: 44
                tip: I18n.t("Поиск", "Search")
                onClicked: Shell.toggleStart(win.screenName)
                WinIcon {
                    anchors.centerIn: parent
                    name: "search-regular"
                    size: 20
                    scale: searchBtn.pressed ? 0.8 : 1
                    Behavior on scale {
                        NumberAnimation {
                            duration: WinStyle.fast
                        }
                    }
                }
            }
            TaskButton {
                id: tvBtn
                visible: Config.win.taskView
                width: 44
                tip: I18n.t("Представление задач", "Task view")
                onClicked: Niri.toggleOverview()
                WinTaskViewGlyph {
                    anchors.centerIn: parent
                    size: 22
                    scale: tvBtn.pressed ? 0.8 : 1
                    Behavior on scale {
                        NumberAnimation {
                            duration: WinStyle.fast
                        }
                    }
                }
            }

            Repeater {
                id: appRep
                model: appModel
                AppButton {
                    required property string key
                    required property int index
                    entry: win.entryMap[key] || ({
                            "key": key,
                            "app": null,
                            "appId": key,
                            "pinned": false,
                            "windows": []
                        })
                }
            }
        }

        // ---- right: chevron, quick settings, clock, bell ----
        Row {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: 8
            height: parent.height
            spacing: 0

            TaskButton {
                id: chevron
                visible: SystemTray.items.values.length > 0
                width: 28
                tip: I18n.t("Отображать скрытые значки", "Show hidden icons")
                checked: trayFlyout.visible
                onClicked: trayFlyout.toggle(chevron)
                WinIcon {
                    anchors.centerIn: parent
                    name: "chevron_up-regular"
                    size: 16
                    rotation: trayFlyout.visible ? 180 : 0
                    Behavior on rotation {
                        NumberAnimation {
                            duration: WinStyle.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: WinStyle.standard
                        }
                    }
                }
            }
            TaskButton {
                id: lang
                visible: Niri.keyboardLayouts.length > 1
                width: Math.max(30, langText.implicitWidth + 12)
                tip: Niri.layoutName
                onClicked: Niri.switchLayout(true)
                WinText {
                    id: langText
                    anchors.centerIn: parent
                    // Windows writes the language, not the layout: РУС / ENG / УКР
                    text: {
                        const n = Niri.layoutName;
                        return /^Russian/.test(n) ? "РУС" : /^English/.test(n) ? "ENG" : /^Ukrainian/.test(n) ? "УКР" : /^German/.test(n) ? "DEU" : Niri.layoutShort.toUpperCase();
                    }
                    font.pixelSize: WinStyle.caption
                }
            }
            TaskButton {
                id: qsBtn
                width: qsRow.implicitWidth + 16
                tip: I18n.t("Громкость: ", "Volume: ") + Math.round(Audio.volume * 100) + "%"
                checked: quick.visible
                onClicked: quick.toggle(qsBtn)
                onWheel: d => Audio.step(d > 0 ? 0.02 : -0.02)
                Row {
                    id: qsRow
                    anchors.centerIn: parent
                    spacing: 8
                    WinIcon {
                        name: Wifi.hasWifi && Wifi.enabled ? "wifi_1-regular" : "desktop-regular"
                        size: 16
                        opacity: Wifi.online || !Wifi.available ? 1 : 0.55
                    }
                    WinIcon {
                        name: Audio.muted || Audio.volume <= 0 ? "speaker_mute-regular" : Audio.volume < 0.34 ? "speaker_0-regular" : Audio.volume < 0.67 ? "speaker_1-regular" : "speaker_2-regular"
                        size: 16
                    }
                }
            }
            TaskButton {
                id: clockBtn
                width: clockCol.implicitWidth + 16
                checked: cal.visible
                tip: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
                onClicked: cal.toggle(clockBtn)
                Column {
                    id: clockCol
                    anchors.centerIn: parent
                    WinText {
                        anchors.right: parent.right
                        text: Qt.formatTime(clock.date, "HH:mm")
                        font.pixelSize: WinStyle.caption
                    }
                    WinText {
                        anchors.right: parent.right
                        text: Qt.formatDate(clock.date, "dd.MM.yyyy")
                        font.pixelSize: WinStyle.caption
                    }
                }
            }
            TaskButton {
                id: bell
                width: 30
                tip: Config.notifications.dnd ? I18n.t("Не беспокоить", "Do not disturb") : I18n.t("Уведомления", "Notifications")
                checked: cal.visible
                onClicked: cal.toggle(clockBtn)
                WinIcon {
                    anchors.centerIn: parent
                    visible: Notifs.unread === 0 || Config.notifications.dnd
                    name: Config.notifications.dnd ? "alert_snooze-regular" : "alert-regular"
                    size: 16
                }
                Rectangle {
                    visible: Notifs.unread > 0 && !Config.notifications.dnd
                    anchors.centerIn: parent
                    width: Math.max(18, badge.implicitWidth + 8)
                    height: 18
                    radius: 9
                    color: WinStyle.accent
                    WinText {
                        id: badge
                        anchors.centerIn: parent
                        text: Notifs.unread > 99 ? "99+" : String(Notifs.unread)
                        color: WinStyle.onAccent
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---- flyouts and menus ----
    WinMenu {
        id: barMenu
        anchorItem: content
    }
    WinMenu {
        id: winX
        anchorItem: content
    }
    WinMenu {
        id: jumpMenu
        anchorItem: content
    }
    WinQuickSettings {
        id: quick
        anchorItem: content
    }
    WinCalendar {
        id: cal
        anchorItem: content
    }
    WinTrayFlyout {
        id: trayFlyout
        anchorItem: content
        menu: barMenu
    }
    WinPreview {
        id: preview
        anchorItem: content
        taskbar: win
    }

    // Win+X (right click on Start)
    function winXItems() {
        const power = [
            {
                "text": I18n.t("Заблокировать", "Lock"),
                "icon": "lock_closed-regular",
                "run": () => Shell.lock()
            },
            {
                "text": I18n.t("Выход", "Sign out"),
                "icon": "sign_out-regular",
                "run": () => Shell.exec(["niri", "msg", "action", "quit", "--skip-confirmation"])
            },
            {
                "separator": true
            },
            {
                "text": I18n.t("Спящий режим", "Sleep"),
                "icon": "weather_moon-regular",
                "run": () => Shell.exec(["systemctl", "suspend"])
            },
            {
                "text": I18n.t("Завершение работы", "Shut down"),
                "icon": "power-regular",
                "run": () => Shell.exec(["systemctl", "poweroff"])
            },
            {
                "text": I18n.t("Перезагрузка", "Restart"),
                "icon": "arrow_clockwise-regular",
                "run": () => Shell.exec(["systemctl", "reboot"])
            }
        ];
        return [
            {
                "text": I18n.t("Установленные приложения", "Installed apps"),
                "run": () => Shell.openStart(win.screenName)
            },
            {
                "text": I18n.t("Параметры", "Settings"),
                "run": () => Shell.openSettings("home")
            },
            {
                "text": I18n.t("Диспетчер задач", "Task Manager"),
                "run": () => DesktopActions.launchMonitor()
            },
            {
                "text": I18n.t("Терминал", "Terminal"),
                "run": () => Shell.exec([Config.launcher.terminal || "kitty"])
            },
            {
                "separator": true
            },
            {
                "text": I18n.t("Проводник", "File Explorer"),
                "run": () => Shell.openPath(Quickshell.env("HOME"))
            },
            {
                "text": I18n.t("Поиск", "Search"),
                "run": () => Shell.openStart(win.screenName)
            },
            {
                "text": I18n.t("Выполнить", "Run"),
                "run": () => Shell.launcherOpen = true
            },
            {
                "separator": true
            },
            {
                "text": I18n.t("Завершение работы или выход из системы", "Shut down or sign out"),
                "sub": power
            },
            {
                "text": I18n.t("Рабочий стол", "Desktop"),
                "run": () => Niri.toggleOverview()
            }
        ];
    }

    // ---- pieces ----

    // the rounded hover box every taskbar button has
    component TaskButton: Item {
        id: tb
        property string tip: ""
        property bool checked: false
        property bool draggable: false
        property bool dragging: false
        readonly property bool hovered: ma.containsMouse
        readonly property bool pressed: ma.pressed
        signal dragMoved(real rowX)
        signal dragEnded
        signal clicked
        signal rightClicked
        signal middleClicked
        signal wheel(real delta)
        height: 48
        width: 44

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            radius: 4
            color: tb.pressed ? WinStyle.subtlePress : (tb.hovered || tb.checked) ? WinStyle.subtleHover : "transparent"
            border.width: (tb.hovered || tb.checked) && !tb.pressed ? 1 : 0
            border.color: WinStyle.controlLine
            Behavior on color {
                ColorAnimation {
                    duration: WinStyle.fast
                }
            }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            property real downX: 0
            preventStealing: tb.draggable
            onPressed: m => downX = m.x
            onPositionChanged: m => {
                if (!tb.draggable || !pressed || !(pressedButtons & Qt.LeftButton))
                    return;
                if (!tb.dragging && Math.abs(m.x - downX) > 6) {
                    tb.dragging = true;
                    tipTimer.stop();
                    tipBox.visible = false;
                }
                if (tb.dragging)
                    tb.dragMoved(mapToItem(tb.parent, m.x, 0).x);
            }
            onReleased: if (tb.dragging)
                dragEndTimer.start()
            onClicked: m => {
                if (tb.dragging)
                    return;
                tipTimer.stop();
                tipBox.visible = false;
                if (m.button === Qt.RightButton)
                    tb.rightClicked();
                else if (m.button === Qt.MiddleButton)
                    tb.middleClicked();
                else
                    tb.clicked();
            }
            onWheel: w => tb.wheel(w.angleDelta.y)
            onContainsMouseChanged: {
                if (containsMouse && tb.tip && !PopupManager.active)
                    tipTimer.restart();
                else {
                    tipTimer.stop();
                    tipBox.visible = false;
                }
            }
        }
        Timer {
            id: tipTimer
            interval: 600
            onTriggered: tipBox.visible = true
        }
        // end the drag after the release's click has been swallowed
        Timer {
            id: dragEndTimer
            interval: 1
            onTriggered: {
                tb.dragging = false;
                tb.dragEnded();
            }
        }
        WinTooltip {
            id: tipBox
            anchorItem: tb
            text: tb.tip
        }
    }

    // pinned / running app, grouped
    component AppButton: TaskButton {
        id: ab
        required property var entry
        readonly property var wins: entry.windows
        readonly property bool running: wins.length > 0
        readonly property bool focused: wins.some(w => w.is_focused)
        readonly property bool urgent: wins.some(w => w.is_urgent)
        readonly property string name: entry.app ? entry.app.name : wins.length ? (wins[0].title || entry.appId) : entry.appId
        width: 44
        checked: focused && !dragging
        tip: ""
        property real jump: 0
        draggable: true

        // press and drag along the taskbar to reorder, like Windows
        property real grabX: 0
        property real pointerX: 0
        z: dragging ? 10 : 0
        transform: Translate {
            x: ab.dragging ? ab.pointerX - ab.grabX - ab.x : 0
        }
        onDragMoved: rowX => {
            if (win.dragKey === "") {
                win.dragKey = ab.entry.key;
                ab.grabX = rowX - ab.x;
                preview.hideNow();
            }
            ab.pointerX = rowX;
            // first app slot = after Start / Search / Task view
            const first = appRep.count ? appRep.itemAt(0).x : 0;
            let slot = Math.floor((rowX - first) / ab.width);
            slot = Math.max(0, Math.min(appModel.count - 1, slot));
            if (slot !== ab.index)
                appModel.move(ab.index, slot, 1);
        }
        onDragEnded: {
            win.dragKey = "";
            win.saveOrder();
            win.syncModel();
        }

        // new running apps grow in
        scale: 0.4
        opacity: 0
        Component.onCompleted: appear.start()
        ParallelAnimation {
            id: appear
            NumberAnimation {
                target: ab
                property: "scale"
                to: 1
                duration: WinStyle.slow
                easing.type: Easing.BezierSpline
                easing.bezierCurve: WinStyle.decelerate
            }
            NumberAnimation {
                target: ab
                property: "opacity"
                to: 1
                duration: WinStyle.fast
            }
        }

        // urgent: the amber flash Windows gives a window that wants attention
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            radius: 4
            visible: ab.urgent && !ab.focused
            color: "#c89a2a"
            SequentialAnimation on opacity {
                running: ab.urgent && !ab.focused
                loops: Animation.Infinite
                NumberAnimation {
                    from: 0.25
                    to: 0.75
                    duration: 600
                }
                NumberAnimation {
                    from: 0.75
                    to: 0.25
                    duration: 600
                }
            }
        }

        AppIcon {
            id: ico
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -ab.jump + (ab.pressed ? 1 : 0)
            appId: ab.entry.appId
            iconName: ab.entry.app && ab.entry.app.icon ? ab.entry.app.icon : ""
            size: 24
            scale: ab.pressed ? 0.82 : 1
            Behavior on scale {
                NumberAnimation {
                    duration: WinStyle.fast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }
        }
        // running pill: short grey, long accent when in front
        Rectangle {
            visible: ab.running
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 4 - height - 1
            height: 3
            radius: 1.5
            width: ab.focused ? 16 : 6
            color: ab.focused ? WinStyle.accent : WinStyle.indicator
            Behavior on width {
                NumberAnimation {
                    duration: WinStyle.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: WinStyle.decelerate
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: WinStyle.normal
                }
            }
        }

        SequentialAnimation {
            id: bounce
            NumberAnimation {
                target: ab
                property: "jump"
                to: 7
                duration: 160
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: ab
                property: "jump"
                to: 0
                duration: 420
                easing.type: Easing.OutBounce
            }
        }

        onClicked: {
            preview.hideNow();
            if (!ab.running)
                bounce.restart();
            win.activate(ab.entry);
        }
        onMiddleClicked: {
            bounce.restart();
            win.launch(ab.entry);
        }
        onRightClicked: {
            preview.hideNow();
            const e = ab.entry;
            const list = [];
            if (e.app)
                list.push({
                    "text": e.app.name,
                    "appIcon": e.appId,
                    "appIconName": e.app.icon || "",
                    "run": () => {
                        bounce.restart();
                        win.launch(e);
                    }
                });
            list.push({
                "text": e.pinned ? I18n.t("Открепить от панели задач", "Unpin from taskbar") : I18n.t("Закрепить на панели задач", "Pin to taskbar"),
                "icon": e.pinned ? "pin_off-regular" : "pin-regular",
                "run": () => win.togglePin(e)
            });
            if (e.windows.length)
                list.push({
                    "text": e.windows.length > 1 ? I18n.t("Закрыть все окна", "Close all windows") : I18n.t("Закрыть окно", "Close window"),
                    "icon": "dismiss-regular",
                    "run": () => e.windows.forEach(w => Niri.closeWindow(w.id))
                });
            jumpMenu.openAbove(ab, list);
        }
        onHoveredChanged: {
            if (hovered && ab.running && !ab.dragging)
                preview.hoverOn(ab, ab.entry);
            else
                preview.hoverOff();
        }
    }

    RightClickGuard {}
}
