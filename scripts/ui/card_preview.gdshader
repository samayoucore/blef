shader_type canvas_item;

render_mode unshaded;

// Source images are complete renders with a pale background outside the
// physical card. Keep one shared crop for the collection thumbnails too.
uniform vec4 card_crop = vec4(0.045, 0.014, 0.91, 0.972);
uniform float corner_radius = 0.055;
varying vec4 vertex_color;
void vertex() { vertex_color = COLOR; }

void fragment() {
	vec2 local_uv = (UV - card_crop.xy) / card_crop.zw;
	vec2 q = abs(local_uv - vec2(0.5)) - vec2(0.5 - corner_radius);
	float distance_to_card = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	if (distance_to_card > 0.0) {
		discard;
	}
	COLOR = texture(TEXTURE, UV) * vertex_color;
}
