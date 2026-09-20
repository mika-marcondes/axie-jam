shader_type spatial;

render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 glow_color : source_color = vec4(
	0.2, 0.9, 1.0, 1.0
);

uniform float glow_strength : hint_range(
	0.0, 1.0
) = 0.0;

void fragment() {
	float fresnel = pow(
		1.0 - clamp(
			dot(NORMAL, VIEW),
			0.0,
			1.0
		),
		2.0
	);

	ALBEDO = glow_color.rgb;
	ALPHA = fresnel * glow_strength;
}