#version 440
// The rim of a window or widget in hell (widgets/HellEdge, PxWindow.hell): what the circle
// did to its edges, in art pixels, still. Only `event` (0 → 1 → 0, a few seconds, now and
// then, on one window at a time) moves something — the thing seen from the corner of an eye.
//   kind 0 scorch  the lower edge burnt into the dark, chipped corners; event: one ember glows
//   kind 1 frost   rime along every edge, a few spikes; event: the rime creeps a pixel further
//   kind 2 tarnish blotches of dull metal along the edges; event: a glint runs along the top
//   kind 3 wet     a dark wet band at the bottom; event: a drop gathers and falls
//   kind 4 ash     grey flecks settled on the top edge; event: a fleck drifts off
//   kind 5 wind    the right edge frayed, pixels torn away; event: a few more tear
//   kind 6 grime   dirt crusted along the bottom
//   kind 7 iron    rivets in the corners, a seam along the top; event: the seam glows
//   kind 8 blood   dried streaks down the sides
//   kind 9 pitch   tar along the bottom edge; event: a drop of it slides down
// colours: edge (the darkest), rim, light (ember, rime, glint), stain
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 cells;     // the window in art pixels
    float kind;
    float seed;
    float event;    // 0..1..0
    vec4 cEdge;
    vec4 cRim;
    vec4 cLight;
    vec4 cStain;
};

float hash(vec2 p) {
    return fract(sin(dot(p + seed * 1.37, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 cell = floor(qt_TexCoord0 * cells);
    vec2 n = cells - 1.0;
    float top = cell.y, bottom = n.y - cell.y, left = cell.x, right = n.x - cell.x;
    float side = min(left, right);
    int k = int(kind + 0.5);
    vec4 o = vec4(0.0);
    float h = hash(cell);
    float col = hash(vec2(cell.x, 0.0));
    float row = hash(vec2(0.0, cell.y));

    if (k == 0) {
        // burnt from below: up to 3 rows, thinning upwards; chips in the corners
        float depth = floor(col * 3.0) + 1.0;
        if (bottom < depth && h < 0.75 - bottom * 0.2)
            o = cEdge;
        if ((top < 1.0 || side < 1.0) && h < 0.07)
            o = cEdge;
        // the ember: one pixel near the bottom, by the seed
        float ex = floor(fract(seed * 0.618) * (n.x - 6.0)) + 3.0;
        if (cell.x == ex && bottom == 2.0)
            o = event > 0.02 ? mix(cStain, cLight, event) : cStain;
    } else if (k == 1) {
        float reach = 1.0 + floor(col * 2.0) + (event > 0.5 ? 1.0 : 0.0);
        if ((top < reach || bottom < 1.0 || side < 1.0) && h < 0.3)
            o = cLight;
        if (top < reach + 2.0 && top >= reach && col > 0.93)
            o = cLight;
    } else if (k == 2) {
        if ((top < 2.0 || bottom < 2.0 || side < 2.0) && hash(floor(cell / 3.0)) < 0.25)
            o = cStain;
        if (top < 1.0 && event > 0.0 && abs(cell.x / n.x - event) < 0.02)
            o = cLight;
    } else if (k == 3) {
        if (bottom < 2.0 + floor(col * 2.0))
            o = cStain;
        float dx = floor(fract(seed * 0.618) * (n.x - 6.0)) + 3.0;
        float dy = n.y - 3.0 + floor(event * 6.0);
        if (event > 0.0 && cell.x == dx && cell.y == dy)
            o = cLight;
    } else if (k == 4) {
        if (top < 2.0 && h < 0.3)
            o = cStain;
        float fx = floor(fract(seed * 0.618) * (n.x - 6.0)) + 3.0 + floor(event * 5.0);
        if (event > 0.0 && cell.x == fx && cell.y == 2.0 - floor(event * 3.0))
            o = cStain;
    } else if (k == 5) {
        // frayed: dark notches eaten into the right edge, deeper in some rows
        float torn = 1.0 + floor(row * 3.0) + (event > 0.5 && row > 0.7 ? 1.0 : 0.0);
        if (right < torn && h < 0.8)
            o = cEdge;
    } else if (k == 6) {
        if (bottom < 1.0 + floor(col * 3.0) && h < 0.6)
            o = cStain;
    } else if (k == 7) {
        bool corner = (left == 2.0 || right == 2.0) && (top == 2.0 || bottom == 2.0);
        if (corner)
            o = cRim;
        if (top == 1.0)
            o = event > 0.02 ? mix(cStain, cLight, event) : cStain;
    } else if (k == 8) {
        float streak = hash(vec2(floor(cell.y / 7.0), cell.x < n.x * 0.5 ? 1.0 : 2.0));
        if (side < 1.0 && streak < 0.4)
            o = cStain;
    } else {
        if (bottom < 1.0 + floor(col * 2.0))
            o = cStain;
        float dx = floor(fract(seed * 0.618) * (n.x - 6.0)) + 3.0;
        if (cell.x == dx && bottom < 1.0 + floor(event * 4.0))
            o = cStain;
    }
    fragColor = vec4(o.rgb * o.a, o.a) * qt_Opacity;
}
