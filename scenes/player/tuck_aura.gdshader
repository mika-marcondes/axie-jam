shader_type spatial;

render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 aura_color : source_color = vec4(0.3, 0.8, 1.0, 0.55);
uniform float tuck_amount : hint_range(0.0, 1.0) = 0.0;
uniform float fresnel_power : hint_range(0.5, 8.0) = 2.5;

void fragment() {
	float facing = max(dot(NORMAL, VIEW), 0.0);
	float rim = pow(1.0 - facing, fresnel_power);

	float full_tuck = smoothstep(0.85, 1.0, tuck_amount);
	float pulse = 0.9 + 0.1 * sin(TIME * 8.0);
	float pulse_strength = mix(1.0, pulse, full_tuck);

	ALBEDO = aura_color.rgb;
	EMISSION = aura_color.rgb * (0.5 + tuck_amount * 1.5);

	ALPHA = (
		rim
		* aura_color.a
		* tuck_amount
		* pulse_strength
	);
}