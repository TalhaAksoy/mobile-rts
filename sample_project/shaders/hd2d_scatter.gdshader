// HD-2D ground scatter (grass tufts, flowers, pebbles ...): crossed pixel-art quads drawn through a
// MultiMesh. INSTANCE_CUSTOM.xy = top-left UV of the sprite cell in the 4x8 atlas.
// Lit with an "up" normal so the sprites shade exactly like the ground they stand on.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D atlas : source_color, filter_nearest, repeat_disable;
uniform vec2 cell_uv = vec2(0.25, 0.125);   // one 16 px sprite cell in the 4x8 atlas
uniform float wind_strength = 0.045;
uniform float wind_speed = 1.7;
varying float ao;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float top = 1.0 - UV.y;   // 0 at the ground, 1 at the sprite top
	float sway = sin(TIME * wind_speed + wp.x * 0.7 + wp.z * 0.45) * wind_strength * top;
	VERTEX.x += sway;
	VERTEX.z += sway * 0.5;
	NORMAL = vec3(0.0, 1.0, 0.0);
	ao = mix(0.62, 1.05, top);   // darker roots: the sprite sits IN the grass, not on it
	UV = INSTANCE_CUSTOM.xy + UV * cell_uv;
}

void fragment() {
	vec4 t = texture(atlas, UV);
	ALBEDO = t.rgb * ao;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
