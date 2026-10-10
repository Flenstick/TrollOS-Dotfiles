import QtQuick
import qs.config
import qs.widgets
import qs.services

// Scrollable settings page: a column of PxGroups.
PxScroll {
    id: root

    property string heading: ""
    property string subtitle: ""
    default property alias items: col.data
    readonly property int innerWidth: col.width
    readonly property bool fluent: WinExtras.fluentSettings && !!Window.window && Window.window === Shell.fluentWindow
    // TrollOS Settings: the page name is in the header next to «назад»
    readonly property bool chrome: !fluent && !!Window.window && Window.window === Shell.settingsWindow

    contentHeight: col.implicitHeight + Theme.u * 10

    Column {
        id: col
        x: root.fluent ? 0 : Theme.u * 4
        y: root.fluent ? 4 : Theme.u * 4
        width: parent.width - (root.fluent ? 16 : Theme.u * 8)
        spacing: root.fluent ? 28 : Theme.u * 8

        Column {
            visible: root.heading !== "" && (!root.chrome || root.subtitle !== "")
            width: parent.width
            spacing: Theme.u
            PxText {
                // Windows and the TrollOS sidebar show the page name in the window header instead
                visible: !root.fluent && !root.chrome
                text: root.heading
                kind: "big"
                color: Theme.dark ? Theme.accent : Theme.edge
            }
            PxText {
                visible: root.subtitle !== ""
                width: parent.width
                text: root.subtitle
                dim: true
                wrapMode: Text.Wrap
            }
        }
    }
}
