#version 440
// Hell's lyrics on the bar (BarLyrics while the demon rules, Y2K → Lyrics in hell). The
// text comes in white from its layer and leaves in fire's colours: yellow at the top,
// ember in the middle, blood at its feet.
//   mode 0, the new line: it burns up out of the flames — a ragged front climbs from
//     below (progress 0 → 1), white-hot where it is, pixel flames lick over it, sparks
//     rise; once it stands the letters smoulder a little at their feet.
//   mode 1, the line before: it chars black, then crumbles from below into ash that
//     drifts up, an ember rim on what is left.
// Everything but the glyphs snaps to the art-pixel grid (`cells`); `time` comes in steps.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float time;
    float mode;
    float seed;
    vec2 cells;     // the item in art pixels: columns, rows
    vec2 texel;     // one real pixel in texture coordinates (the dark outline)
};
layout(binding = 1) uniform sampler2D source;

float hash(vec2 p) {
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}
float hash1(float x) {
    return fract(sin(x * 91.3458 + seed * 3.17) * 47453.5453);
}
float noise1(float x) {
    float i = floor(x);
    float f = fract(x);
    return mix(hash1(i), hash1(i + 1.0), f * f * (3.0 - 2.0 * f));
}
// y: 0 at the top of the line, 1 at its feet
vec3 fire(float y) {
    vec3 top = vec3(1.0, 0.93, 0.58);
    vec3 mid = vec3(1.0, 0.6, 0.18);
    vec3 low = vec3(0.96, 0.27, 0.14);
    return y < 0.5 ? mix(top, mid, smoothstep(0.2, 0.55, y)) : mix(mid, low, smoothstep(0.6, 0.95, y));
}
// the glyphs grown by a pixel: a soot outline keeps the burnt letters readable
float around(vec2 uv) {
    float m = 0.0;
    m = max(m, texture(source, uv + vec2(texel.x, 0.0)).a);
    m = max(m, texture(source, uv - vec2(texel.x, 0.0)).a);
    m = max(m, texture(source, uv + vec2(0.0, texel.y)).a);
    m = max(m, texture(source, uv - vec2(0.0, texel.y)).a);
    m = max(m, texture(source, uv + texel).a);
    return m;
}
// a few cells rising through the item, `n` of them
float sparks(vec2 cell, float t, float n, float salt) {
    float hit = 0.0;
    for (int i = 0; i < 10; i++) {
        float k = float(i);
        if (k >= n)
            break;
        float sx = floor(hash1(k * 13.7 + salt) * cells.x);
        float speed = 0.6 + hash1(k * 5.3 + salt) * 0.9;
        float sy = floor((1.0 - fract(t * speed * 0.5 + hash1(k * 7.1 + salt))) * cells.y);
        float sway = floor((noise1(k * 3.0 + t * 1.5) - 0.5) * 3.0);
        hit = max(hit, (cell.x == sx + sway && cell.y == sy) ? 1.0 : 0.0);
    }
    return hit;
}

void main() {
    vec2 cell = floor(qt_TexCoord0 * cells);
    vec2 uv = (cell + 0.5) / cells;
    // the glyphs, sharp; thin antialiased strokes of the burnt font made a little bolder
    float a = min(1.0, texture(source, qt_TexCoord0).a * 1.5);
    float t = floor(time * 8.0) / 8.0;
    vec4 c = vec4(0.0);

    if (mode < 0.5) {
        float p = clamp(progress, 0.0, 1.0);
        // the front climbs from below the feet to above the top, ragged
        float front = 1.2 - p * 1.6 + (noise1(cell.x * 0.35 + t * 3.0) - 0.5) * 0.35;
        float d = uv.y - front;                     // > 0: below the front, revealed
        if (d > 0.0) {
            float edge = max(0.0, around(qt_TexCoord0) - a);
            c = vec4(0.04, 0.01, 0.01, 1.0) * edge * 0.9;
        }
        if (d > 0.0 && a > 0.0) {
            vec3 col = fire(uv.y);
            col = mix(col, vec3(1.0, 0.96, 0.78), (1.0 - smoothstep(0.0, 0.25, d)) * 0.85);
            if (p >= 1.0) {
                // smouldering feet: an ember cell now and then
                float ember = step(0.9, hash(cell + floor(t * 2.0))) * smoothstep(0.62, 1.0, uv.y);
                col = mix(col, vec3(1.0, 0.72, 0.22), ember);
            }
            c = mix(c, vec4(col, 1.0), a);
        }
        if (p < 1.0) {
            // flames standing on the front, over and between the letters
            // separate tongues: some columns have none
            float tongue = noise1(cell.x * 0.42 + t * 1.7);
            float h = tongue < 0.38 ? 0.06 : 0.12 + (tongue - 0.38) * 1.1 + noise1(cell.x * 1.3 - t * 5.0) * 0.18;
            float above = front - uv.y;
            if (above > -0.06 && above < h) {
                float k = clamp(above / h, 0.0, 1.0);
                vec3 fc = k < 0.34 ? vec3(0.74, 0.09, 0.16) : k < 0.68 ? vec3(1.0, 0.42, 0.10) : vec3(1.0, 0.69, 0.18);
                float alive = step(hash(cell + vec2(0.0, floor(t * 6.0))), 0.97 - k * 0.6);
                float fade = 1.0 - smoothstep(0.7, 1.0, p);
                c = mix(c, vec4(fc, 1.0), alive * fade);
            }
            // sparks flying up while it burns
            float s = sparks(cell, time, 8.0, 1.0) * (1.0 - smoothstep(0.8, 1.0, p));
            c = mix(c, vec4(1.0, 0.86, 0.4, 1.0), s);
        }
    } else {
        float p = clamp(progress, 0.0, 1.0);
        vec3 col = mix(fire(uv.y), vec3(0.16, 0.05, 0.04), smoothstep(0.0, 0.4, p));
        // crumbles from its feet up; each cell goes when the noise says so
        float last = (1.0 - uv.y) * 0.65 + hash(cell) * 0.35;
        float th = (p - 0.25) / 0.75;
        float alive = step(th, last);
        float rim = alive * (1.0 - step(th + 0.1, last)) * step(0.0, th);
        col = mix(col, vec3(1.0, 0.42, 0.10), rim);
        c = vec4(col, 1.0) * a * alive;
        // grey ash flecks drifting up from where it stood
        float ash = sparks(cell, time * 0.7, 10.0, 9.0) * smoothstep(0.2, 0.5, p) * (1.0 - smoothstep(0.85, 1.0, p));
        c = mix(c, vec4(0.42, 0.36, 0.34, 1.0), ash * 0.9);
    }
    fragColor = c * qt_Opacity;
}
