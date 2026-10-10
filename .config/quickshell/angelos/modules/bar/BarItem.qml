pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.modules.bar.parts

// One bar widget by id ("clock", "tray", "plugin:cat", …).
Loader {
    id: root

    required property string wid
    required property var bar          // BarContent: screenName, barWindow, above, compact, itemHeight, …
    property bool fillTasks: false
    property real lyricsMax: Theme.u * 150

    readonly property bool tall: wid === "start" || wid === "tasks" || wid === "media" || wid === "lyrics"
    Layout.fillWidth: fillTasks && wid === "tasks"
    // outside the stretching left side (Windows 11 / ChromeOS layouts) an icon row
    // takes just its buttons, so the run stays centred
    readonly property bool tightTasks: wid === "tasks" && !fillTasks && !!item && item.iconsOnly
    Layout.minimumWidth: wid === "tasks" ? (tightTasks ? 0 : Theme.u * 16) : -1
    Layout.preferredWidth: wid === "tasks" ? (fillTasks ? Theme.u * 16 : tightTasks ? Math.min(item.rowWidth, Theme.u * 300) : Theme.u * 120) : -1
    Layout.preferredHeight: tall ? bar.itemHeight : -1
    Layout.alignment: Qt.AlignVCenter
    // Never bind a parent's visibility to its child's effective visibility:
    // once hidden during a track change, both can otherwise stay hidden.
    visible: {
        if (wid === "tasks")
            return Config.bar.showWindows;
        if (wid === "media")
            return Config.bar.showMedia && !!Lyrics.player && Lyrics.title !== "";
        if (wid === "lyrics")
            return Config.lyrics.enabled && (!!Shell.lyricsHook || Lyrics.visibleToggle && Lyrics.hasLyrics) && (!Config.lyrics.screens.length || Config.lyrics.screens.includes(bar.screenName)) && lyricsMax >= Theme.u * 50;
        return true;
    }

    // guided tips find bar elements by "bar:<id>"
    Component.onCompleted: if (bar && bar.barWindow)
        Tour.register("bar:" + wid, root, bar.barWindow)
    Component.onDestruction: Tour.unregister("bar:" + wid, root)

    sourceComponent: {
        switch (wid) {
        case "start":
            return startC;
        case "workspaces":
            return wsC;
        case "tasks":
            return tasksC;
        case "lyrics":
            return lyricsC;
        case "media":
            return mediaC;
        case "tray":
            return trayC;
        case "layout":
            return layoutC;
        case "volume":
            return volumeC;
        case "bell":
            return bellC;
        case "clock":
            return clockC;
        default:
            return wid.startsWith("plugin:") ? pluginC : null;
        }
    }

    Component {
        id: startC
        StartButton {
            small: root.bar.compact || root.bar.style !== "taskbar"
            above: root.bar.above
            screenName: root.bar.screenName
            barWindow: root.bar.barWindow
        }
    }
    Component {
        id: wsC
        Workspaces {
            screenName: root.bar.screenName
        }
    }
    Component {
        id: tasksC
        Tasks {
            screenName: root.bar.screenName
            above: root.bar.above
            iconsOnly: root.bar.compact || root.bar.style === "island" || !Config.bar.taskLabels
            visible: Config.bar.showWindows
        }
    }
    Component {
        id: lyricsC
        BarLyrics {
            screenName: root.bar.screenName
            maxWidth: root.lyricsMax
            fixedWidth: true
        }
    }
    Component {
        id: mediaC
        Media {
            maxWidth: root.bar.compact ? 0 : Theme.u * 130
            showTitle: !root.bar.lyricsShown
            visible: Config.bar.showMedia && !!Lyrics.player && Lyrics.title !== ""
        }
    }
    Component {
        id: trayC
        Tray {
            above: root.bar.above
        }
    }
    Component {
        id: layoutC
        KbLayout {}
    }
    Component {
        id: volumeC
        Volume {
            above: root.bar.above
            showPercent: !root.bar.compact && root.bar.style === "taskbar"
        }
    }
    Component {
        id: bellC
        Bell {}
    }
    Component {
        id: clockC
        Clock {
            screenName: root.bar.screenName
            above: root.bar.above
            showDate: root.bar.style === "taskbar"
        }
    }
    Component {
        id: pluginC
        Loader {
            readonly property var p: Plugins.byId(root.wid.slice(7))
            function load() {
                if (p && !item)
                    setSource(Plugins.url(p, p.barWidget), {
                        "plugin": Plugins.context(p),
                        "screenName": root.bar.screenName,
                        "barWindow": root.bar.barWindow
                    });
            }
            onPChanged: load()
            Component.onCompleted: load()
        }
    }
}
