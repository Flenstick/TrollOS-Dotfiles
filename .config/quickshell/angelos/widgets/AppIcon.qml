import QtQuick
import Quickshell
import qs.config
import qs.services

// App icon by app-id / icon name; falls back to a pixel window.
Item {
    id: root

    property string appId: ""
    property string iconName: ""
    property int size: Theme.u * 8
    property string tint: "off"   // off | mono | accent
    // on the hell bar: the circle's sprite ramp instead (HellBarTint), so no app icon turns
    // into a blot or sinks into the plate
    property bool hellBar: false
    layer.enabled: hellBar
    layer.effect: HellBarTint {}

    readonly property string name: {
        let n = iconName;
        if (!n && appId) {
            const e = DesktopEntries.heuristicLookup(appId);
            n = e && e.icon ? e.icon : appId;
        }
        return n || "";
    }
    readonly property string themed: {
        const n = name;
        if (!n)
            return "";
        if (n.startsWith("/") || n.includes("://"))
            return n.startsWith("/") ? "file://" + n : n;
        return Quickshell.iconPath(n, true) || Quickshell.iconPath(n.toLowerCase(), true) || "";
    }
    // Windows 11 layout with Windows icons: the Win11 icon theme first, the usual icon if it has none
    readonly property bool winIcons: Config.bar.style === "windows" && Config.win.icons === "windows"
    property string winTried: ""
    readonly property string winPath: winIcons && name && !!WinExtras.winIconSet[name] && winTried !== name ? "file://" + Quickshell.env("HOME") + "/.local/share/icons/Win11/apps/scalable/" + name + ".svg" : ""
    readonly property string resolved: winPath || themed

    implicitWidth: size
    implicitHeight: size

    TintedImage {
        id: img
        anchors.fill: parent
        visible: root.resolved !== ""
        source: root.resolved
        size: root.size
        mode: root.hellBar ? "off" : root.tint
    }
    PxIcon {
        anchors.centerIn: parent
        visible: root.resolved === ""
        name: "window"
        pixel: Math.max(1, Math.floor(root.size / 10))
    }
    // no Win11 icon for this app: fall back to the normal one
    Connections {
        target: img.children.length ? img.children[0] : null
        ignoreUnknownSignals: true
        function onStatusChanged() {
            const i = img.children[0];
            if (root.winPath && i && i.status === Image.Error)
                root.winTried = root.name;
        }
    }
}
