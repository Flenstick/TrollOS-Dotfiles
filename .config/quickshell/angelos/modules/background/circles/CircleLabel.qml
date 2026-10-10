import QtQuick
import qs.config
import qs.widgets

// An entry's name in a circle's menu look: tiny, bone on an outline of the pit, bold on the
// one you're on.
PxText {
    property bool hot: false
    kind: "tiny"
    font.bold: hot
    color: hot ? Theme.hellText : Theme.mix(Theme.hellText, Theme.hellTextDim, 0.35)
    style: Text.Outline
    styleColor: Theme.hellPlate
    horizontalAlignment: Text.AlignHCenter
}
