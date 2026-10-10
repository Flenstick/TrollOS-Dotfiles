pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Start while the demon rules (Y2K → Angel or demon → Start in hell): a dark slab in the
// circle's colours with its rim (HellEdge), the Hell wordmark, a dim pentagram drawing itself behind
// the list as it opens (shaders/pentagram.frag). Left: "Summon" — the pinned and most
// used apps. Right: the grimoire (Settings), the wallpaper she guards, begging her to
// bring the angel back (Angel.plea, counted like in her menu), the portal once it is open,
// the terminal and files. Power along the foot. Arrows walk everything in one ring,
// Enter runs, typing summons the launcher — the same body interface as the other looks.
PxBox {
    id: root

    signal closeRequested
    property int current: -1
    property real reveal: 1
    readonly property var prefs: StartPrefs.of("classic")
    readonly property int u: Theme.u

    readonly property var apps: StartApps.pinned.slice(0, 7)
    readonly property var entries: {
        const list = [];
        for (const a of apps)
            list.push({
                "side": "apps",
                "text": a.name,
                "app": a,
                "act": () => StartApps.launch(a)
            });
        const right = [
            {
                "text": HellLook.dressName(HellLook.settingsPick),
                "icon": "document",
                "hint": I18n.t("настройки", "settings"),
                "act": () => Shell.openSettings()
            },
            {
                "text": I18n.t("Обои ада", "Hell's wallpaper"),
                "icon": "image",
                "act": () => Shell.openSettings("wallpaper")
            },
            {
                "text": Angel.now && Story.tryLabel(I18n.t("Искать выход", "Seek the way out")),
                "icon": "heart",
                "show": Angel.demon && !Angel.transition,
                "act": () => Angel.plea()
            },
            {
                "text": I18n.t("Портал в рай", "Portal to heaven"),
                "icon": "sparkle",
                "show": Angel.portalOpen && Angel.demon,
                "act": () => Angel.portal()
            },
            {
                "text": I18n.t("Терминал", "Terminal"),
                "icon": "terminal",
                "act": () => Shell.terminal()
            },
            {
                "text": I18n.t("Файлы", "Files"),
                "icon": "folder",
                "act": () => Shell.exec([Config.system.fileManager || "xdg-open", Config.home])
            },
            {
                "text": I18n.t("Все программы…", "All programs…"),
                "icon": "search",
                "act": () => Shell.launcherOpen = true
            }
        ];
        for (const e of right)
            if (e.show === undefined || e.show)
                list.push(Object.assign({
                    "side": "right"
                }, e));
        for (const e of [
                {
                    "text": I18n.t("Запечатать", "Seal"),
                    "icon": "lock",
                    "act": () => Shell.lock()
                },
                {
                    "text": I18n.t("Заставка", "Idle"),
                    "icon": "moon",
                    "act": () => Idle.start()
                },
                {
                    "text": I18n.t("Выключение…", "Power…"),
                    "icon": "power",
                    "act": () => Shell.sessionOpen = true
                }
            ])
            list.push(Object.assign({
                "side": "power"
            }, e));
        return list;
    }

    function reset() {
        current = -1;
    }
    function setQuery(text) {
    }
    function run(index) {
        const e = entries[index];
        if (!e)
            return;
        closeRequested();
        Qt.callLater(e.act);
    }
    function key(e) {
        const n = entries.length;
        if (e.key === Qt.Key_Escape || e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R)
            closeRequested();
        else if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier)))
            current = current < 0 ? 0 : (current + 1) % n;
        else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab)
            current = current < 0 ? n - 1 : (current - 1 + n) % n;
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_Left) {
            // across: apps ↔ the right column
            const side = current >= 0 ? entries[current].side : "apps";
            const want = side === "apps" ? "right" : "apps";
            const i = entries.findIndex(x => x.side === want);
            if (i >= 0)
                current = i;
        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
            run(current >= 0 ? current : 0);
        else if (e.text && e.text.trim() !== "" && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            Shell.launcherPrefill = e.text;
            closeRequested();
            Qt.callLater(() => Shell.launcherOpen = true);
        } else
            return;
        e.accepted = true;
    }

    width: Math.round(u * 220 * prefs.size)
    height: head.height + cols.height + foot.height + u * 6
    color: Theme.hellPanel
    edgeColor: Theme.hellHi
    flat: true
    shadow: Config.appearance.shadows

    // the circle's rim on the slab's edges, over everything (no input)
    HellEdge {
        anchors.fill: parent
        z: 10
        seed: 6
    }

    // the pentagram behind the lists, drawing itself as the menu opens
    ShaderEffect {
        readonly property real d: Math.min(root.width * 0.5, cols.height * 1.05)
        x: root.width - d - root.u * 2
        y: head.height + (cols.height - d) / 2
        width: d
        height: d
        opacity: 0.32
        property real progress: Math.min(1, root.reveal * 1.15)
        property real side: d
        property real star: d * 0.34
        property real ring: d * 0.44
        property real u: root.u
        property color blood: Theme.hellRim
        property color ember: Theme.hellBlood
        fragmentShader: Qt.resolvedUrl("../../shaders/pentagram.frag.qsb")
    }

    // ---- head: the Hell wordmark on blood ----
    Rectangle {
        id: head
        width: parent.width
        height: root.u * 28
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.mix(Theme.hellFaceAlt, Theme.hellBlood, 0.45)
            }
            GradientStop {
                position: 1
                color: Theme.hellFace
            }
        }
        AngelLogo {
            anchors.left: parent.left
            anchors.leftMargin: root.u * 6
            anchors.verticalCenter: parent.verticalCenter
            variant: "hell"
        }
        PxText {
            anchors.right: parent.right
            anchors.rightMargin: root.u * 6
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.hellTextDim
            kind: "tiny"
            text: StartApps.userName + I18n.t(" · душа заложена", " · soul pledged")
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: root.u
            color: Theme.hellBlood
        }
    }

    // one row; `at` is its place in root.entries (the keyboard walks them in that order)
    component Entry: Item {
        id: entry
        property int at: 0
        readonly property var modelData: root.entries[at] || ({})
        readonly property bool lit: root.current === at || mouse.containsMouse
        width: parent ? parent.width : 0
        height: Theme.sizeBody + root.u * 9
        Rectangle {
            anchors.fill: parent
            visible: entry.lit
            color: Qt.alpha(Theme.hellBlood, 0.55)
            border.width: Math.max(1, root.u / 2)
            border.color: Theme.hellAccent
        }
        // an ember glows at the start of the lit row
        Rectangle {
            visible: entry.lit
            x: root.u
            anchors.verticalCenter: parent.verticalCenter
            width: root.u
            height: parent.height - root.u * 4
            color: Theme.hellText
        }
        Row {
            x: root.u * 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.u * 3
            AppIcon {
                visible: !!entry.modelData.app
                anchors.verticalCenter: parent.verticalCenter
                size: root.u * 10
                appId: entry.modelData.app ? entry.modelData.app.id : ""
                iconName: entry.modelData.app ? entry.modelData.app.icon || "" : ""
            }
            PxIcon {
                visible: !entry.modelData.app
                anchors.verticalCenter: parent.verticalCenter
                name: entry.modelData.icon || "fire"
                ink: Theme.hellEdge
                fill: entry.lit ? Theme.hellText : Theme.hellTextDim
                fill2: Theme.hellBlood
                fill3: Theme.hellTextDim
                light: Theme.hellText
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                width: entry.width - root.u * 22
                elide: Text.ElideRight
                color: entry.lit ? Theme.hellText : Theme.hellTextDim
                text: entry.modelData.text
            }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: if (containsMouse)
                root.current = entry.at
            onClicked: root.run(entry.at)
        }
    }

    // ---- the two columns ----
    Row {
        id: cols
        y: head.height + root.u * 3
        x: root.u * 3
        width: root.width - root.u * 6
        height: Math.max(left.implicitHeight, right.implicitHeight)
        spacing: root.u * 3
        Column {
            id: left
            width: (cols.width - cols.spacing) * 0.52
            PxText {
                x: root.u * 3
                height: implicitHeight + root.u * 3
                font.family: Theme.latin(text) ? Theme.fontHell : Theme.fontTitle
                font.pixelSize: Theme.latin(text) ? Theme.hellPx(1) : Theme.sizeBody
                color: Theme.hellTextDim
                text: I18n.t("Призвать", "Summon")
            }
            Repeater {
                model: root.entries.map((e, i) => i).filter(i => root.entries[i].side === "apps")
                Entry {
                    required property int modelData
                    at: modelData
                }
            }
        }
        Rectangle {
            width: Math.max(1, root.u / 2)
            height: cols.height
            color: Qt.alpha(Theme.hellBlood, 0.6)
        }
        Column {
            id: right
            width: cols.width - left.width - cols.spacing * 2 - Math.max(1, root.u / 2)
            PxText {
                x: root.u * 3
                height: implicitHeight + root.u * 3
                font.family: Theme.latin(text) ? Theme.fontHell : Theme.fontTitle
                font.pixelSize: Theme.latin(text) ? Theme.hellPx(1) : Theme.sizeBody
                color: Theme.hellTextDim
                text: I18n.t("Её владения", "Her domain")
            }
            Repeater {
                model: root.entries.map((e, i) => i).filter(i => root.entries[i].side === "right")
                Entry {
                    required property int modelData
                    at: modelData
                }
            }
        }
    }

    // ---- power along the foot, and how to search ----
    Item {
        id: foot
        anchors.bottom: parent.bottom
        width: parent.width
        height: powerRow.height + hint.height + root.u * 6
        Rectangle {
            width: parent.width
            height: root.u
            color: Qt.alpha(Theme.hellBlood, 0.7)
        }
        Row {
            id: powerRow
            y: root.u * 3
            x: root.u * 3
            width: parent.width - root.u * 6
            Repeater {
                model: root.entries.map((e, i) => i).filter(i => root.entries[i].side === "power")
                Entry {
                    required property int modelData
                    at: modelData
                    width: powerRow.width / 3
                }
            }
        }
        PxText {
            id: hint
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.u * 2
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            kind: "tiny"
            color: Theme.hellTextDim
            text: I18n.t("печатай — призыв ⛧", "type to summon ⛧")
        }
    }
}
