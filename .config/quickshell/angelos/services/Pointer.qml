pragma Singleton

import QtQuick
import Quickshell

// Where the pointer is, as far as angelOS can tell: niri tells nobody the global
// pointer position, so the shell's own surfaces report it while the pointer is
// over them (the desktop under the windows, the taskbar), in screen coordinates.
// Over an app window the last known spot stays and `over` turns false.
// Used by the demon's cracked glass (modules/y2k/ScreenCracks): it clears up as you come near.
Singleton {
    id: root

    property string screen: ""
    property real x: 0
    property real y: 0
    property bool over: false                // over a reporting surface right now
    property string source: ""               // which one ("desk", "bar")

    function report(src, screenName, px, py) {
        screen = screenName;
        x = px;
        y = py;
        source = src;
        over = true;
    }
    // the pointer left that surface; another one may have picked it up already
    function left(src, screenName) {
        if (source === src && screen === screenName)
            over = false;
    }
}
