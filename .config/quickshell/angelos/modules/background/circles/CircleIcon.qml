import QtQuick
import qs.config
import qs.widgets

// An entry's icon in a circle's menu look: hell's bone and dim ink, the accent on the one
// you're on. `ink` is the outline (dark on the looks drawn on paper).
PxIcon {
    property bool hot: false
    ink: Theme.hellText
    fill: hot ? Theme.hellAccent : Theme.hellTextDim
    fill2: Theme.hellRim
    fill3: Theme.hellTextDim
    body: Theme.hellFaceAlt
    light: Theme.hellText
    bad: Theme.hellAccent
}
