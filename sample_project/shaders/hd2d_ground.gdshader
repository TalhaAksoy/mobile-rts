// HD-2D terrain: pixel-art ground textures sampled in WORLD space (no per-tile repetition grid),
// blended by a per-map control texture with Bayer-dithered, texel-snapped thresholds so every
// transition (grass -> dry grass -> dirt -> path) is a crisp pixel step instead of a soft blur.
// Control texture (built by scripts/HD2DGround.gd): R = road/path, G = bare dirt,
// B = alternate ground (dry grass / dark sand), A = macro light variation (0.5 = neutral).
// Slopes (from the surface normal of the smooth hill mesh): worn earth on steeper ground, the
// biome's rock on the steepest faces; also through the dithered step, so edges stay pixel-crisp.
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
uniform sampler2D tex_cliff : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform vec3 cliff_tint = vec3(1.0);
uniform float earth_slope = 0.11;    // 1 - normal.y where bare earth starts (~27 deg)
uniform float rock_slope = 0.24;     // ... and rock (~40 deg)
// Hill relief, painted like a diorama so elevation reads from the high top-down camera:
// slopes facing the sun brighter, slopes facing away darker (in quantised bands), high ground a
// touch lighter than low ground.
uniform vec3 sun_dir = vec3(-0.572, 0.588, -0.572);   // towards the sun (scene DirectionalLight3D)
uniform float relief_strength = 1.25;
uniform float height_tint = 0.05;    // brightness change per metre of elevation

varying vec3 world_pos;
varying vec3 world_nrm;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
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
	// slopes: earth, then rock (rock texture projected sideways so its strata run along the hill)
	float slope = 1.0 - normalize(world_nrm).y;
	col = mix(col, texture(tex_dirt, uv + vec2(0.41, 0.07)).rgb * 0.92, step(earth_slope, slope + d * 0.25));
	vec2 side_uv = vec2(world_pos.x + world_pos.z, world_pos.y * 1.6) / tex_tile_m;
	col = mix(col, texture(tex_cliff, side_uv).rgb * cliff_tint, step(rock_slope, slope + d * 0.3));
	// relief: aspect shading relative to flat ground, in 0.06 steps, plus a height tint
	vec3 n = normalize(world_nrm);
	vec3 L = normalize(sun_dir);
	float aspect = (dot(n, L) - L.y) * relief_strength;
	aspect = floor(aspect / 0.06 + 0.5 + d * 0.5) * 0.06;
	col *= clamp(1.0 + aspect + clamp(world_pos.y, -1.0, 4.5) * height_tint, 0.7, 1.3);
	// macro light variation, quantised to 4 steps so it stays "pixel-art"
	float macro = floor((c.a - 0.5) * 8.0 + 0.5) / 4.0;
	col *= (1.0 + macro * macro_strength) * tint;

	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
