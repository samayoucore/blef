shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 panel_size = vec2(400.0, 400.0);
uniform float blur_strength = 5.0;
uniform float background_opacity : hint_range(0.0, 1.0) = 0.76;
uniform vec4 tint : source_color = vec4(0.055, 0.062, 0.060, 1.0);
uniform float corner_radius = 20.0;
void fragment() {
    vec2 p = SCREEN_PIXEL_SIZE * blur_strength;
    vec3 scene = texture(screen_texture, SCREEN_UV).rgb * 0.20;
    scene += texture(screen_texture, SCREEN_UV + vec2(p.x, 0.0)).rgb * 0.12;
    scene += texture(screen_texture, SCREEN_UV - vec2(p.x, 0.0)).rgb * 0.12;
    scene += texture(screen_texture, SCREEN_UV + vec2(0.0, p.y)).rgb * 0.12;
    scene += texture(screen_texture, SCREEN_UV - vec2(0.0, p.y)).rgb * 0.12;
    scene += texture(screen_texture, SCREEN_UV + p).rgb * 0.08;
    scene += texture(screen_texture, SCREEN_UV - p).rgb * 0.08;
    scene += texture(screen_texture, SCREEN_UV + vec2(p.x, -p.y)).rgb * 0.08;
    scene += texture(screen_texture, SCREEN_UV + vec2(-p.x, p.y)).rgb * 0.08;
    vec2 q = abs((UV - 0.5) * panel_size) - panel_size * 0.5 + corner_radius;
    float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
    float mask = 1.0 - smoothstep(-1.0, 0.5, distance_to_edge);
    vec3 glass = mix(scene, tint.rgb, background_opacity);
    glass += vec3(0.018) * (1.0 - UV.y);
    COLOR = vec4(glass, mask);
}
