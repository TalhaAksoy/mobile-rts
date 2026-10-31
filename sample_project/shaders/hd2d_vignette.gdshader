// Soft vignette for the HD-2D look. Multiplies the frame (no screen-texture read -> nearly free),
// strongest in the corners, untouched in the centre where the player works. Drawn on a CanvasLayer
// BELOW the HUD so menus/buttons are never darkened.
shader_type canvas_item;
render_mode blend_mul;

uniform float strength = 0.32;
uniform float inner = 0.42;   // radius (in half-diagonal units) where darkening starts
uniform vec3 tint = vec3(0.86, 0.88, 1.0);   // corners drift cool, like OT-style grading

void fragment() {
	vec2 d = (UV - 0.5) * vec2(1.0, 1.25);
	float r = length(d) / 0.8;
	float v = smoothstep(inner, 1.05, r) * strength;
	COLOR = vec4(mix(vec3(1.0), tint * (1.0 - v), v / max(strength, 0.001)), 1.0);
}
