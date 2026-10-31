// HD-2D water: deep-teal body with slow, pixel-quantised ripple bands and sparkles.
// World-space and texel-snapped (32 px / m) so it matches the pixel-art ground. Cheap: no screen
// or depth texture reads (Compatibility renderer friendly).
shader_type spatial;
render_mode blend_mix, cull_disabled, specular_schlick_ggx, depth_draw_opaque;

uniform vec3 deep_color : source_color = vec3(0.05, 0.17, 0.26);
uniform vec3 mid_color : source_color = vec3(0.09, 0.29, 0.38);
uniform vec3 light_color : source_color = vec3(0.28, 0.55, 0.62);
uniform vec3 sparkle_color : source_color = vec3(0.92, 0.98, 1.0);
uniform float px_per_m = 16.0;
uniform float speed = 0.6;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = floor(world_pos.xz * px_per_m) / px_per_m;
	float t = TIME * speed;
	float w = sin(p.x * 2.1 + t) * 0.5 + sin(p.y * 2.7 - t * 0.8 + p.x * 0.6) * 0.5;
	float band = floor((w * 0.5 + 0.5) * 4.0) / 3.0;   // 4 quantised tones
	vec3 col = mix(deep_color, mid_color, band);
	if (band > 0.99) {
		col = light_color;
	}
	// sparkles: rare texels that blink
	vec2 cell = floor(world_pos.xz * px_per_m);
	float s = hash(cell + floor(t * 1.5));
	if (s > 0.992) {
		col = sparkle_color;
	}
	ALBEDO = col;
	ALPHA = 0.9;
	ROUGHNESS = 0.55;
	SPECULAR = 0.25;
}
