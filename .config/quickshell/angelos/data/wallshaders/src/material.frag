#version 440
// TrollOS «Material You»: Material 3 Expressive's shapes in the scheme's own tones — a scalloped
// "cookie", a soft pill and two round blobs drift and breathe on the surface; they take the
// colours from the seed (c0 surface, c1 primary container, c2 tertiary container, c3 secondary
// container, c4 primary), so the wallpaper follows the accent. Its still is never shown alone:
// the layer stays (frozen) when the wallpaper is set to a picture.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec2 size;
    float glow;
    vec4 c0;
    vec4 c1;
    vec4 c2;
    vec4 c3;
    vec4 c4;
};

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}
// a pill (rounded box) turned by a
float sdPill(vec2 p, vec2 b, float r, float a) {
    float c = cos(a), s = sin(a);
    p = mat2(c, -s, s, c) * p;
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
// Material 3 Expressive's "cookie": a circle with n soft scallops, turned by a
float sdCookie(vec2 p, float r, float n, float depth, float a) {
    float ang = atan(p.y, p.x) + a;
    float rr = r * (1.0 + depth * cos(n * ang));
    return (length(p) - rr) * 0.85;
}
// fill with a soft edge and a soft shadow under it
vec3 layer(vec3 col, float d, vec3 c, float px, vec2 shOff, float dsh) {
    col = mix(col, col * 0.80, (1.0 - smoothstep(-0.02, 0.06, dsh)) * 0.35);
    return mix(col, c, 1.0 - smoothstep(-px, px, d));
}

void main() {
    float aspect = size.x / size.y;
    vec2 uv = qt_TexCoord0;
    vec2 p = vec2((uv.x - 0.5) * aspect, 0.5 - uv.y);
    float t = time * 0.06;
    float px = 1.5 / size.y;

    // the surface, a breath of the primary toward one corner
    vec3 col = mix(c0.rgb, mix(c0.rgb, c1.rgb, 0.35), smoothstep(1.2, -0.2, length(p - vec2(-0.6 * aspect, 0.5))));

    vec2 off = vec2(0.012, -0.018);
    // the big cookie, low on the right, turning slowly
    vec2 pc = p - vec2(0.42 * aspect / 1.78 + 0.03 * sin(t * 0.7), -0.28 + 0.02 * cos(t));
    float dc = sdCookie(pc, 0.36 + 0.01 * sin(t * 1.3), 9.0, 0.055, t * 0.5);
    float dcs = sdCookie(pc - off, 0.36, 9.0, 0.055, t * 0.5);
    col = layer(col, dc, c1.rgb, px, off, dcs);

    // a pill across the upper left
    vec2 pp = p - vec2(-0.55 * aspect / 1.78 + 0.03 * cos(t * 0.8), 0.27 + 0.02 * sin(t * 1.1));
    float dp = sdPill(pp, vec2(0.34, 0.11), 0.11, 0.55 + 0.05 * sin(t));
    float dps = sdPill(pp - off, vec2(0.34, 0.11), 0.11, 0.55 + 0.05 * sin(t));
    col = layer(col, dp, c2.rgb, px, off, dps);

    // two round blobs
    vec2 pb = p - vec2(-0.10 + 0.04 * sin(t * 0.9 + 1.0), -0.33 + 0.03 * cos(t * 0.6));
    float db = sdCircle(pb, 0.13);
    col = layer(col, db, c3.rgb, px, off, sdCircle(pb - off, 0.13));
    vec2 pd = p - vec2(0.12 * aspect + 0.03 * cos(t * 1.2), 0.30 + 0.025 * sin(t * 0.8));
    float dd = sdCircle(pd, 0.065);
    col = layer(col, dd, c4.rgb, px, off, sdCircle(pd - off, 0.065));

    // a ring of small dots around the cookie, like a progress indicator at rest
    float ang = atan(pc.y, pc.x) - t * 0.25;
    float ring = abs(length(pc) - 0.47);
    float dots = smoothstep(0.012, 0.004, ring) * smoothstep(0.55, 0.62, 0.5 + 0.5 * cos(ang * 24.0));
    col = mix(col, c4.rgb, dots * 0.55 * (1.0 + glow));

    // a whisper of grain against banding
    col += (hash(uv * size + fract(time)) - 0.5) / 255.0 * 2.0;
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
