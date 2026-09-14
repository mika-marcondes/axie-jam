shader_type spatial;

uniform vec4 color_a : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform vec4 color_b : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float checker_scale = 20.0;

void fragment() {
	vec2 uv = UV * checker_scale;

	float checker = mod(floor(uv.x) + floor(uv.y), 2.0);

	vec4 albedo_color = mix(color_a, color_b, checker);

	ALBEDO = albedo_color.rgb;
	ROUGHNESS = 0.8;
}