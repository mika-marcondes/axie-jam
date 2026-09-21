shader_type spatial;

uniform vec4 white_color : source_color = vec4(
	0.95, 0.93, 0.88, 1.0
);

uniform vec4 orange_color : source_color = vec4(
	1.0, 0.30, 0.05, 1.0
);

uniform vec4 light_orange_color : source_color = vec4(
	1.0, 0.58, 0.16, 1.0
);

uniform vec4 dark_orange_color : source_color = vec4(
	0.85, 0.16, 0.03, 1.0
);

uniform float band_top = 0.34;
uniform float band_bottom = 0.68;

uniform float triangle_count = 8.0;
uniform float triangle_strength = 0.9;

uniform float bottom_accent_start = 0.88;

uniform float roughness = 0.42;
uniform float specular_amount = 0.55;


float triangle_wave(float value) {
	float phase = fract(value);

	return 1.0 - abs(
		phase * 2.0 - 1.0
	);
}


void fragment() {
	vec3 color = white_color.rgb;

	float band_mask = step(
		band_top,
		UV.y
	) * (
		1.0 - step(
			band_bottom,
			UV.y
		)
	);

	if (band_mask > 0.0) {
		float band_height = (
			band_bottom - band_top
		);

		float band_y = (
			UV.y - band_top
		) / band_height;

		float triangle = triangle_wave(
			UV.x * triangle_count
		);

		float upper_shape = (
			1.0 - band_y
		) * triangle_strength;

		float lower_shape = (
			band_y
		) * triangle_strength;

		vec3 band_color = orange_color.rgb;

		if (triangle > upper_shape) {
			band_color = light_orange_color.rgb;
		}

		if (
			triangle > lower_shape
			&& band_y > 0.5
		) {
			band_color = dark_orange_color.rgb;
		}

		color = band_color;
	}

	if (UV.y > bottom_accent_start) {
		color = mix(
			orange_color.rgb,
			dark_orange_color.rgb,
			0.35
		);
	}

	ALBEDO = color;
	ROUGHNESS = roughness;
	SPECULAR = specular_amount;
	METALLIC = 0.0;
}