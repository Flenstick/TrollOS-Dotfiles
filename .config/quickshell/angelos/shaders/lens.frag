#version 440
// The lens (modules/lens/LensOverlay, extras/lens-live): the screen's picture magnified
// around `spot` inside a circle (shape 0) or a square (1) at `center`, with a pixel
// rim; outside it nothing (the live screen shows through). The snapshot lens sits on
// what it magnifies (spot = center); the live one beside it. crisp: sharp pixels.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 center;     // the glass, px in the item
    vec2 spot;       // what it magnifies, px in the item
    vec2 itemSize;
    vec2 texSize;    // the picture's pixels (physical)
    float radius;    // px
    float zoom;
    float shape;
    float crisp;
    float rim;       // the rim's width, px
    vec4 rimColor;
    vec4 edgeColor;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 p = qt_TexCoord0 * itemSize;
    vec2 d = p - center;
    float dist = shape < 0.5 ? length(d) : max(abs(d.x), abs(d.y));
    if (dist > radius + rim * 2.0) {
        fragColor = vec4(0.0);
        return;
    }
    if (dist > radius) {
        // the rim: the accent, an ink line outside
        vec4 c = dist > radius + rim ? edgeColor : rimColor;
        fragColor = vec4(c.rgb, 1.0) * c.a * qt_Opacity;
        return;
    }
    vec2 uv = (spot + d / zoom) / itemSize;
    if (crisp > 0.5)
        uv = (floor(uv * texSize) + 0.5) / texSize;
    vec4 c = texture(source, clamp(uv, vec2(0.0), vec2(1.0)));
    fragColor = vec4(c.rgb, 1.0) * qt_Opacity;
}
