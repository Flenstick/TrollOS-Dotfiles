import QtQuick
import qs.config
import qs.widgets
import "."

// Desktop "codex.exe": mascot, state and limits. The host draws the frame.
Item {
    id: root

    property var plugin
    property string screenName
    property var widget
    readonly property string mode: plugin ? plugin.get("orb", "always") : "always"   // always | active | off
    readonly property bool wantVisible: mode === "always" || (mode === "active" && CodexState.state !== "none")

    implicitWidth: Theme.u * 116
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: Theme.u * 3
        Mascot {
            anchors.horizontalCenter: parent.horizontalCenter
            pixel: Theme.u * 3
        }
        // hell (manifest "realms"): her words in blackletter, fire colours
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: (Theme.hell ? CodexState.hellWords : CodexState.words)[CodexState.state] || ""
            kind: "title"
            font.family: Theme.hell && Theme.latin(text) ? Theme.fontHell : Theme.fontTitle
            font.pixelSize: Theme.hell && Theme.latin(text) ? Theme.hellPx(Theme.fs) : Theme.sizeTitle
            color: Theme.hell ? CodexState.hellStateColor(CodexState.state, Theme) : CodexState.stateColor(CodexState.state, Theme)
        }
        Limits {
            width: parent.width
            compact: true
            hell: Theme.hell
        }
    }
}
