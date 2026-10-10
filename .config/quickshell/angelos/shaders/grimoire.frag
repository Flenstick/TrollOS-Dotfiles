#version 440
// Settings as a grimoire (Y2K → Settings in hell): the page is re-inked on parchment.
// Whatever reads as "background" (dark in a dark theme, light in a light one) turns into
// paper, text and lines into brown ink, saturated colours (the accent) into red ink.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 paper;
    vec4 ink;
    vec4 redInk;
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
    float l = dot(rgb, vec3(0.299, 0.587, 0.114));
    float sat = max(rgb.r, max(rgb.g, rgb.b)) - min(rgb.r, min(rgb.g, rgb.b));
    // midtones (bevels, a picked button) stay visible as faint ink
    float t = smoothstep(0.35, 0.95, invert > 0.5 ? 1.0 - l : l);
    vec3 inkCol = mix(ink.rgb, redInk.rgb, smoothstep(0.15, 0.4, sat));
    vec3 o = mix(inkCol, paper.rgb, t);
    fragColor = vec4(o * a, a) * qt_Opacity;
}
