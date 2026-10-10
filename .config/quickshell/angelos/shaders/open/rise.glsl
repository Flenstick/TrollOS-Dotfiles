// angelOS open: unfolds up out of the taskbar, the lower part widening last (the reverse of "Into the bar").
vec4 open_color(vec3 coords_geo, vec3 size_geo) {
    float p = niri_clamped_progress;
    float c = (1.0 - p) * (1.0 - p);
    float scale = mix(1.0, 0.06, c);
    vec2 center = mix(vec2(0.5), vec2(0.5, 1.5), c);
    vec2 g = (coords_geo.xy - center) / scale + 0.5;
    float squeeze = mix(1.0, 0.35, c * clamp(g.y, 0.0, 1.0));
    g.x = (g.x - 0.5) / squeeze + 0.5;
    if (g.x < 0.0 || g.x > 1.0 || g.y < 0.0 || g.y > 1.0)
        return vec4(0.0);
    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * vec3(g, 1.0)).st);
    return color * smoothstep(0.0, 0.3, p);
}
