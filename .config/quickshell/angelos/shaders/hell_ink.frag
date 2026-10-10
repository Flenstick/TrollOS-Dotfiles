#version 440
// Any Start look (StartOverlay, Y2K → Start in hell: "hell version") and any Alt+Tab style
// (AltTabHost, "skin") re-inked in the circle's palette (the bar draws itself now: BarContent):
// a few flat colours by what a pixel is — near black → plate, dark →
// face, mid → dim, light → text, coloured (the accent, app icons) → two dulled embers.
// `keep` is no longer read (it kept a little of an icon's hue in the old loud hell).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float keep;
    vec4 plate;
    vec4 face;
    vec4 dim;
    vec4 text;
    vec4 accent;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    if (c.a < 0.003) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 rgb = c.rgb / c.a;
    float l = dot(rgb, vec3(0.299, 0.587, 0.114));
    float sat = max(rgb.r, max(rgb.g, rgb.b)) - min(rgb.r, min(rgb.g, rgb.b));
    vec3 o;
    // coloured pixels (app icons, the look's own accent) in two dulled embers, so a menu
    // full of icons isn't a wall of the accent: the lighter half nearer it, the rest deeper
    if (sat > 0.32 && l > 0.16)
        o = l > 0.5 ? mix(dim.rgb, accent.rgb, 0.6) : mix(face.rgb, accent.rgb, 0.45);
    else if (l < 0.05)
        o = plate.rgb;
    else if (l < 0.2)
        o = face.rgb;
    else if (l < 0.6)
        o = dim.rgb;
    else
        o = text.rgb;
    // translucent menus stay translucent (blur shows through), text and icons stay whole
    fragColor = vec4(o * c.a, c.a) * qt_Opacity;
}
