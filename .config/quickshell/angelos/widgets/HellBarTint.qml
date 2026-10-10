import QtQuick
import qs.config

// The hell bar's tint as a layer effect (shaders/hell_bar_tint.frag): app icons and plugins
// without a hell bar look of their own, in the circle's sprite ramp — darks to the sprite
// body, the middle to its lighter tone, lights to the text; shapes and shading stay.
//   layer.enabled: barInk
//   layer.effect: HellBarTint {}
ShaderEffect {
    fragmentShader: Qt.resolvedUrl("../shaders/hell_bar_tint.frag.qsb")
    property color sprite: Theme.hellSprite
    property color spriteHi: Theme.hellSpriteHi
    property color text: Theme.hellText
}
