import QtQuick
import qs.config

// TrollOS: a Material Symbol (the «Material You» skin): the font draws the glyph its name
// spells (ligatures). `fill` 0..1 is the FILL axis — filled for what is on or picked.
Text {
    id: root
    property string name: ""
    property real size: Theme.mdPx(20)
    property real fill: 0
    property int weight: 400

    text: name
    color: Theme.text
    font.family: Theme.mdSymbolFont
    font.pixelSize: size
    font.variableAxes: ({
            "FILL": Math.max(0, Math.min(1, fill)),
            "wght": weight,
            "opsz": Math.max(20, Math.min(48, size))
        })
    renderType: Text.QtRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
    Behavior on fill {
        NumberAnimation {
            duration: Motion.ms(150)
        }
    }
}
