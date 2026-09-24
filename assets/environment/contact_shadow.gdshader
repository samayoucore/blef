shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform float strength = 0.19;
void fragment() {
	vec2 p = abs(UV*2.0-1.0);
	float distance_to_center = pow(pow(p.x,4.0)+pow(p.y,4.0),0.25);
	ALBEDO = vec3(0.12,0.15,0.12);
	ALPHA = strength * (1.0-smoothstep(0.25,1.0,distance_to_center));
}
