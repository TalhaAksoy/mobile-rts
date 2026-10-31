// HD-2D terrain: pixel-art ground textures sampled in WORLD space (no per-tile repetition grid),
// blended by a per-map control texture with Bayer-dithered, texel-snapped thresholds so every
// transition (grass -> dry grass -> dirt -> path) is a crisp pixel step instead of a soft blur.
// Control texture (built by scripts/HD2DGround.gd): R = road/path, G = bare dirt,
// B = alternate ground (dry grass / dark sand), A = macro light variation (0.5 = neutral).
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform sampler2D tex_base : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_alt : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_dirt : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_path : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D control : filter_linear, repeat_disable;
uniform vec2 map_size_m = vec2(64.0, 120.0);
uniform float tex_tile_m = 2.0;      // one 64 px texture tile covers 2 m  -> 32 px / m
uniform float px_per_m = 32.0;
uniform float dither_amount = 0.22;
uniform float macro_strength = 0.10;
uniform vec3 tint = vec3(1.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[i] / 16.0 - 0.47;
}

void fragment() {
	vec2 texel = floor(world_pos.xz * px_per_m);
	vec2 snapped = (texel + 0.5) / px_per_m;
	vec4 c = texture(control, snapped / map_size_m);
	float d = bayer4(texel) * dither_amount;
	vec2 uv = world_pos.xz / tex_tile_m;

	vec3 col = texture(tex_base, uv).rgb;
	col = mix(col, texture(tex_alt, uv + vec2(0.37, 0.61)).rgb, step(0.5, c.b + d));
	col = mix(col, texture(tex_dirt, uv + vec2(0.13, 0.29)).rgb, step(0.5, c.g + d));
	col = mix(col, texture(tex_path, uv).rgb, step(0.5, c.r + d));
	// macro light variation, quantised to 4 steps so it stays "pixel-art"
	float macro = floor((c.a - 0.5) * 8.0 + 0.5) / 4.0;
	col *= (1.0 + macro * macro_strength) * tint;

	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
