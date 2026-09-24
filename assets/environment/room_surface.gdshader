shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.7,0.7,0.7,1.0);
uniform int surface_kind = 0;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p = world_position.xz;
	float shade = 1.0;
	if(surface_kind == 0) {
		vec2 cell = abs(fract(p/1.2)-0.5);
		float seam = smoothstep(0.493,0.499,max(cell.x,cell.y));
		shade = 1.0 - seam*0.08;
	} else if(surface_kind == 1) {
		float grain = sin(p.x*36.0 + sin(p.y*1.7)*2.0 + sin(p.x*9.0));
		shade = 0.98 + grain*0.016;
	} else {
		float detail = clamp(1.0 - length(fwidth(p))*90.0,0.0,1.0);
		shade = 0.985 + 0.015*detail*sin(p.x*160.0)*sin(p.y*160.0);
	}
	ALBEDO = base_color.rgb * shade;
	ROUGHNESS = surface_kind == 1 ? 0.56 : 0.86;
	SPECULAR = 0.28;
}
