// Unit HP bar in one draw: dark frame + green fill on a single quad (was two boxes = two draws per unit).
// The fill share is a per-instance uniform, so every bar shares this one material.
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, shadows_disabled, depth_draw_never;

uniform vec3 frame_color : source_color = vec3(0.08, 0.06, 0.04);
uniform vec3 fill_color : source_color = vec3(0.22, 0.92, 0.28);
uniform vec2 size = vec2(0.92, 0.10);   // metres, same as the quad
uniform vec2 inset = vec2(0.02, 0.015); // frame thickness
instance uniform float fill = 1.0;

// always faces the camera, whichever way the unit turns (free: done on the GPU, no per-frame node updates)
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * size;
	bool inside = p.x > inset.x && p.x < inset.x + (size.x - 2.0 * inset.x) * fill
		&& p.y > inset.y && p.y < size.y - inset.y;
	ALBEDO = inside ? fill_color : frame_color;
	ALPHA = 1.0;
}
