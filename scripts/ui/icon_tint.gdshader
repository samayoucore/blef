shader_type canvas_item;

// The reference icons are black silhouettes with transparent backgrounds.
// Rebuild the visible pixels from alpha so one PNG can be used in any UI color.
uniform vec4 tint : source_color = vec4(1.0);
varying vec4 vertex_color;
void vertex() { vertex_color = COLOR; }

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(tint.rgb, alpha * tint.a) * vertex_color;
}
