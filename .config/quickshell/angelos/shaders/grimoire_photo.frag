#version 440
// A picture inside the grimoire (wallpaper thumbnails, cursor previews): shaders/grimoire.frag
// re-inks the whole page by brightness and turns it around in a dark theme, so a photo came
// out as its negative. This runs first, on the picture alone, and hands the page shader the
// grey that it will turn back into the picture's own brightness: an old engraving in ink on
// parchment, the right way round. invert: the page shader's own flag (a dark theme).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float invert;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec4 c = texture(source, qt_TexCoord0);
    float a = c.a;
    if (a < 0.003) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 rgb = c.rgb / a;
    float l = clamp(dot(rgb, vec3(0.299, 0.587, 0.114)) * 0.92 + 0.04, 0.001, 0.999);
    // the page maps t = smoothstep(0.35, 0.95, x): find the x that gives t = l
    float s = 0.5 - sin(asin(1.0 - 2.0 * l) / 3.0);
    float x = 0.35 + 0.6 * s;
    float v = invert > 0.5 ? 1.0 - x : x;
    fragColor = vec4(vec3(v) * a, a) * qt_Opacity;
}
