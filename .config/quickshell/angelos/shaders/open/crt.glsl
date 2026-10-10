// angelOS open: an old TV switching on — a dot, a bright line, then the picture opens up with a white flash and scanlines.
vec4 open_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_clamped_progress;
    // dot → line, then the line opens up
    float sx = max(smoothstep(0.0, 0.3, p), 4.0 / size_geo.x);
    float q = clamp((p - 0.3) / 0.4, 0.0, 1.0);
    float sy = max(1.0 - pow(1.0 - q, 3.0), 3.0 / size_geo.y);
    vec2 c = coords_geo.xy - 0.5;
    vec2 g = vec2(c.x / sx, c.y / sy) + 0.5;
    if (g.x < 0.0 || g.x > 1.0 || g.y < 0.0 || g.y > 1.0)
        return vec4(0.0);
    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * vec3(g, 1.0)).st);
    // the tube glows white first, the picture comes through
    float flash = 1.0 - smoothstep(0.35, 0.85, p);
    color = mix(color, vec4(1.0), flash);
    // scanlines while it warms up
    float scan = 0.8 + 0.2 * sin(coords_geo.y * size_geo.y * 3.14159);
    color.rgb *= mix(1.0, scan, 1.0 - smoothstep(0.7, 1.0, p));
    return color * smoothstep(0.0, 0.08, p);
}
