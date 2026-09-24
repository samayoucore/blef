shader_type spatial;
render_mode unshaded, cull_back, depth_prepass_alpha;

uniform sampler2D card_texture : source_color, filter_linear_mipmap;
uniform float source_aspect = 0.75;
uniform vec4 card_crop = vec4(0.045, 0.014, 0.91, 0.972);
uniform float corner_radius = 0.055;

void fragment() {
	const float card_aspect = 0.8;
	vec2 source_uv = UV;
	if (source_aspect < card_aspect) {
		source_uv.x = (UV.x - 0.5) * (card_aspect / source_aspect) + 0.5;
	} else if (source_aspect > card_aspect) {
		source_uv.y = (UV.y - 0.5) * (source_aspect / card_aspect) + 0.5;
	}
	if (source_uv.x < 0.0 || source_uv.x > 1.0 || source_uv.y < 0.0 || source_uv.y > 1.0) discard;
	vec2 local_uv = (source_uv - card_crop.xy) / card_crop.zw;
	vec2 q = abs(local_uv - vec2(0.5)) - vec2(0.5 - corner_radius);
	float distance_to_card = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	if (distance_to_card > 0.0) discard;
	vec4 color = texture(card_texture, source_uv);
	if (color.a < 0.02) discard;
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
