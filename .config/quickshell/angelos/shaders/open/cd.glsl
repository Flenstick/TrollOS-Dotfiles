// angelOS open: a CD — the window spins in as a growing disc with a rainbow rim, and the hole in the middle closes up.
vec3 angelos_rainbow(float h) {
    return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

vec4 open_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_clamped_progress;
    float e = 1.0 - pow(1.0 - p, 3.0);
    float aspect = size_geo.x / size_geo.y;
    vec2 q = (coords_geo.xy - 0.5) * vec2(aspect, 1.0);
    if (p >= 0.999) {
        if (coords_geo.x < 0.0 || coords_geo.x > 1.0 || coords_geo.y < 0.0 || coords_geo.y > 1.0)
            return vec4(0.0);
        return texture2D(niri_tex, (niri_geo_to_tex * coords_geo).st);
    }
    float radius = length(vec2(aspect, 1.0) * 0.5) * 1.02 * e;
    float d = length(q);
    float hole = radius * 0.22 * (1.0 - smoothstep(0.5, 0.95, p));
    if (d > radius || d < hole)
        return vec4(0.0);
    // the picture spins with the disc and stops
    float angle = (1.0 - e) * 2.5;
    vec2 r = mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * q;
    vec2 g = r / vec2(aspect, 1.0) + 0.5;
    if (g.x < 0.0 || g.x > 1.0 || g.y < 0.0 || g.y > 1.0)
        return vec4(0.0);
    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * vec3(g, 1.0)).st);
    vec3 sheen = angelos_rainbow(fract(atan(q.y, q.x) / 6.2832 * 2.0 + p * 1.5));
    float band = radius * 0.07 + 0.01;
    float rim = smoothstep(radius - band, radius, d) + (hole > 0.0 ? 1.0 - smoothstep(hole, hole + band * 0.6, d) : 0.0);
    color.rgb = mix(color.rgb, sheen * color.a, clamp(rim, 0.0, 1.0) * 0.85 * (1.0 - p));
    // an iridescent sheen over the whole disc while it spins
    color.rgb = mix(color.rgb, sheen * color.a, 0.2 * (1.0 - e));
    return color * smoothstep(0.0, 0.1, p);
}
