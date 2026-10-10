#version 440
// What the hell bar can't draw in its own colours — app icons (window buttons, the tray) and
// plugins without a hell bar look of their own — in the circle's sprite ramp: the darks become
// `sprite` (the body tone, ≥ 3:1 on the plate), the middle `spriteHi`, the lights `text`.
// Luminance keeps the shapes and the shading, alpha stays as it is: a dark puppy or a dark
// app icon never sinks into the plate, and nothing turns into the accent (that is for states).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 sprite;
    vec4 spriteHi;
    vec4 text;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    float a = c.a;
    if (a < 0.004) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 rgb = c.rgb / a;
    float l = clamp(dot(rgb, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);
    vec3 o = l < 0.5 ? mix(sprite.rgb, spriteHi.rgb, l * 2.0) : mix(spriteHi.rgb, text.rgb, (l - 0.5) * 2.0);
    fragColor = vec4(o * a, a) * qt_Opacity;
}
