import QtQuick
import qs.config
import "Cerberus.js" as Frames

// A puppy Cerberus in the circle's colours (widgets/Cerberus.js): `frame` steps the run
// (five frames), `asleep` lies him down with zzz, `blink` hides the zzz for a beat.
// The cat plugin is one in hell; the Wheel of Hell lets a big one run across the screen.
// Fur in the sprite tone and the heads a step lighter (Theme.hellSprite, hellSpriteHi: they
// stand out from the dark plates and walls, 3:1 at least), the dark outline around them,
// bone-white collar spikes; the eyes and the tail's flame take the accent only while he is
// `alert` (chasing souls: a state), otherwise the text colour.
PxIcon {
    property int frame: 0
    property bool asleep: false
    property bool blink: false
    property bool alert: false

    bitmap: asleep ? Frames.cerberusSleep.map((r, i) => blink && i < 4 ? r.replace(/y/g, ".") : r) : Frames.cerberus(frame)
    ink: Theme.hellEdge
    body: Theme.hellSprite
    fill: Theme.hellBlood
    fill3: alert ? Theme.hellAccent : asleep ? Theme.hellTextDim : Theme.hellSpriteHi
    light: Theme.hellText
    bad: alert ? Theme.hellAccent : Theme.hellText
    palette: ({
            "g": Theme.hex(Theme.hellSpriteHi)
        })
}
