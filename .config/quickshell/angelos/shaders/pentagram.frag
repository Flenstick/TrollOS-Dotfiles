#version 440
// Hell's right-click menu (PentagramLook): the pentagram and its two circles drawing
// themselves in glowing red as the menu opens (progress 0 → 1). Done on the GPU: the
// Canvas it replaces redrew the whole blurred sigil on the CPU every frame of the
// opening and stuttered. The glow is the Canvas shadow (blur 6u) as a gaussian.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float side;      // the item's size in px (a square)
    float star;      // the points' radius
    float ring;      // the outer (runes') circle
    float u;         // Theme.u
    vec4 blood;
    vec4 ember;
};

const float PI = 3.14159265;
const float TAU = 6.28318531;

float segment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-4), 0.0, 1.0);
    return length(pa - ba * h);
}
vec2 point(int i) {
    float a = -PI / 2.0 + float(i) * TAU / 5.0;
    return vec2(cos(a), sin(a)) * star;
}
// the circles grow clockwise from the top, like ctx.arc(…, -π/2, -π/2 + 2π·p);
// past the drawn part: the distance to its ends (round ends, the glow goes round them)
float arc(vec2 p, float r, float p01) {
    if (p01 <= 0.0)
        return 1e5;
    float a = mod(atan(p.y, p.x) + PI / 2.0 + TAU, TAU);
    if (a <= TAU * p01)
        return abs(length(p) - r);
    float e = -PI / 2.0 + TAU * p01;
    return min(length(p - vec2(0.0, -r)), length(p - vec2(cos(e), sin(e)) * r));
}
// a stroke of half-width hw at distance d: antialiased coverage
float cover(float d, float hw) {
    return clamp(hw + 0.5 - d, 0.0, 1.0);
}
vec4 over(vec4 dst, vec3 rgb, float a) {
    return vec4(rgb * a, a) + dst * (1.0 - a);
}

void main() {
    float p = clamp(progress, 0.0, 1.0);
    vec2 q = (qt_TexCoord0 - 0.5) * side;

    float thin = max(1.0, u) * 0.5;
    float thick = max(2.0, u * 1.5) * 0.5;
    float hot = max(1.0, u * 0.5) * 0.5;

    float dInner = arc(q, star + u * 3.0, p);
    float dOuter = arc(q, ring, p);
    // the star: every second point, the five strokes one after another
    float dStar = 1e5;
    float done = p * 5.0;
    for (int s = 0; s < 5; s++) {
        float t = clamp(done - float(s), 0.0, 1.0);
        if (t <= 0.0)
            break;
        // every second point: 0 2 4 1 3 0
        vec2 a = point(int(mod(float(2 * s), 5.0))), b = point(int(mod(float(2 * s + 2), 5.0)));
        dStar = min(dStar, segment(q, a, a + (b - a) * t));
    }

    // the glow under everything: the Canvas shadow (blur 6u) of a thin line is faint,
    // a gaussian with sigma 2.5u at about a third of the line's strength
    float sigma = max(1.0, u * 2.5);
    float k = 1.0 / (2.0 * sigma * sigma);
    float g = 0.0;
    g = max(g, 0.28 * exp(-pow(max(0.0, dInner - thin), 2.0) * k));
    g = max(g, 0.14 * exp(-pow(max(0.0, dOuter - thin), 2.0) * k));
    g = max(g, 0.4 * exp(-pow(max(0.0, dStar - thick), 2.0) * k));

    vec4 c = vec4(blood.rgb, 1.0) * g;
    c = over(c, blood.rgb, 0.45 * cover(dOuter, thin));
    c = over(c, blood.rgb, 0.9 * cover(dInner, thin));
    c = over(c, blood.rgb, cover(dStar, thick));
    c = over(c, ember.rgb, 0.8 * cover(dStar, hot));
    fragColor = c * qt_Opacity;
}
