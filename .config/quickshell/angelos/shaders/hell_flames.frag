#version 440
// A row of pixel flames licking up from a hell window's top edge (PxWindow.hell).
// Column heights come from value noise that drifts with `time` (stepped by a timer,
// a few frames a second — pixel-art flicker, not smooth motion); blood at the root,
// embers, then flame tips; a spark now and then above them.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float seed;
    vec2 cells;     // the strip in art pixels: columns, rows
};

float hash(float x) {
    return fract(sin(x * 91.3458 + seed * 17.13) * 47453.5453);
}
float noise(float x) {
    float i = floor(x);
    float f = fract(x);
    return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void main() {
    float col = floor(qt_TexCoord0.x * cells.x);
    float row = floor((1.0 - qt_TexCoord0.y) * cells.y);     // 0 = the window's edge
    float n = noise(col * 0.45 + time * 0.9) * 0.7 + noise(col * 1.3 - time * 1.7) * 0.3;
    float h = floor(1.0 + n * (cells.y - 1.0));
    vec4 c = vec4(0.0);
    if (row < h) {
        float t = row / max(h, 1.0);
        vec3 rgb = t < 0.34 ? vec3(0.70, 0.08, 0.17) : t < 0.67 ? vec3(1.0, 0.42, 0.10) : vec3(1.0, 0.69, 0.18);
        if (row == h - 1.0 && hash(col + floor(time * 3.0)) > 0.7)
            rgb = vec3(1.0, 0.92, 0.55);
        c = vec4(rgb, 1.0);
    } else if (row == h + 1.0 + floor(hash(col * 3.1 + floor(time)) * 2.0) && hash(col * 7.7 + floor(time * 2.0)) > 0.93) {
        c = vec4(1.0, 0.69, 0.18, 1.0);
    }
    fragColor = c * qt_Opacity;
}
