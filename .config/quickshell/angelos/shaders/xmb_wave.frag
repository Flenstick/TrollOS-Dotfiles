#version 440
// PSP XMB background (modules/bar/StartXmb): a soft vertical gradient in the theme's
// colours with slow translucent ribbons drifting across the middle, like the PSP's
// "wave". `time` in seconds; drawn only while Start is open.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float aspect;    // width / height
    vec4 skyTop;
    vec4 skyBottom;
    vec4 wave;
};

// one ribbon: a band around a wandering line, brighter at its edges (the PSP sheen)
float ribbon(vec2 uv, float base, float amp, float freq, float speed, float phase, float width) {
    float x = uv.x * aspect;
    float y = base + amp * sin(x * freq + time * speed + phase) + amp * 0.45 * sin(x * freq * 2.3 - time * speed * 1.7 + phase * 1.9);
    float d = abs(uv.y - y);
    float body = smoothstep(width, 0.0, d) * 0.35;
    float rim = smoothstep(0.004, 0.0, abs(d - width * 0.8)) * 0.6;
    return body + rim;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec3 c = mix(skyTop.rgb, skyBottom.rgb, smoothstep(0.0, 1.0, uv.y));
    float w = 0.0;
    w += ribbon(uv, 0.56, 0.035, 2.1, 0.22, 0.0, 0.05);
    w += ribbon(uv, 0.60, 0.045, 1.6, 0.17, 2.1, 0.03) * 0.8;
    w += ribbon(uv, 0.58, 0.025, 3.0, -0.28, 4.2, 0.012) * 0.9;
    w += ribbon(uv, 0.62, 0.05, 1.2, 0.12, 1.3, 0.08) * 0.5;
    c += wave.rgb * w * wave.a;
    fragColor = vec4(c, 1.0) * qt_Opacity;
}
