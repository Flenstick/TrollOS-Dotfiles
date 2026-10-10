// angelOS open: the window drops in from above with a slight tilt and bounces on its spot.
float angelos_bounce(float p) {
    float n = 7.5625;
    float d = 2.75;
    if (p < 1.0 / d)
        return n * p * p;
    if (p < 2.0 / d) {
        p -= 1.5 / d;
        return n * p * p + 0.75;
    }
    if (p < 2.5 / d) {
        p -= 2.25 / d;
        return n * p * p + 0.9375;
    }
    p -= 2.625 / d;
    return n * p * p + 0.984375;
}

vec4 open_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_clamped_progress;
    float e = angelos_bounce(p);
    // rotate about the bottom middle, the tilt straightens as it lands
    vec2 coords = (coords_geo.xy - vec2(0.5, 1.0)) * size_geo.xy;
    coords.y += (1.0 - e) * min(size_geo.y * 0.6, 420.0);
    float r = niri_random_seed < 0.5 ? -1.0 : 1.0;
    float angle = (1.0 - e) * 0.08 * r;
    coords = mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * coords;
    vec2 g = coords / size_geo.xy + vec2(0.5, 1.0);
    if (g.x < 0.0 || g.x > 1.0 || g.y < 0.0 || g.y > 1.0)
        return vec4(0.0);
    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * vec3(g, 1.0)).st);
    return color * smoothstep(0.0, 0.15, p);
}
