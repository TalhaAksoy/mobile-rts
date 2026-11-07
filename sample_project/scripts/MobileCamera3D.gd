class_name MobileCamera3D
extends Camera3D

@export var map_bounds_min: Vector2 = Vector2(0, 0)
@export var map_bounds_max: Vector2 = Vector2(60, 92)

var is_dragging: bool = false
var drag_start_mouse_pos: Vector2
var drag_start_cam_pos: Vector3

var min_height: float = 12.0
var max_height: float = 38.0
var target_height: float = 24.0

var touch_points: Dictionary = {}
var prev_pinch_distance: float = -1.0

func zoom_in(step: float = 3.5) -> void:
	_set_target_height(target_height - step)

func zoom_out(step: float = 3.5) -> void:
	_set_target_height(target_height + step)

## 3D style: perspective, 45 deg diorama angle. 2D sprite style: orthographic, straight down (top-down),
## position.y stays the zoom value (minimap, pan speed and the capture tool read it).
const TOP_DOWN_SIZE_PER_HEIGHT := 1.53       # same view coverage as the 75 deg perspective at that height
var top_down: bool = false

func _ready() -> void:
	_apply_view_mode()
	position.y = target_height

func _apply_view_mode() -> void:
	top_down = FactionArtManager.top_down()
	if top_down:
		projection = PROJECTION_ORTHOGONAL
		rotation_degrees = Vector3(-90, 0, 0)
		size = position.y * TOP_DOWN_SIZE_PER_HEIGHT if position.y > 0.1 else target_height * TOP_DOWN_SIZE_PER_HEIGHT
	else:
		projection = PROJECTION_PERSPECTIVE
		# Classic 2.5D / HD-2D Diorama angle (45 degrees)
		rotation_degrees = Vector3(-45, 0, 0)

## World size of the map (x 0..map_size.x, z 0..map_size.y).
var map_size := Vector2(60, 92)
## Screen strips covered by the HUD (viewport px): the top bar and the bottom menu with whatever is open
## above it (build panel, queue, placement bar). UIManager3D updates them every frame.
var screen_inset_top := 0.0
var screen_inset_bottom := 0.0
## How far past the map edge the visible area may go, so the outermost cells are not stuck under the HUD.
const EDGE_MARGIN := 1.5

func setup_bounds(width: float, height: float) -> void:
	map_size = Vector2(width, height)
	map_bounds_min = Vector2(4, 4)
	map_bounds_max = Vector2(width - 4, height - 4)
	_clamp_camera()

## Called by the HUD; only stored: a menu opening or closing never jumps the view, the next pan or zoom
## respects the new limits.
func set_screen_insets(top_px: float, bottom_px: float) -> void:
	screen_inset_top = maxf(0.0, top_px)
	screen_inset_bottom = maxf(0.0, bottom_px)

func pan_by_screen_delta(delta_pixels: Vector2) -> void:
	var factor = (position.y / 800.0) * 1.6
	position.x += delta_pixels.x * factor
	position.z += delta_pixels.y * factor * (1.0 if top_down else 1.4)
	_clamp_camera()

func pan_to_drag(drag_start_screen: Vector2, current_screen: Vector2, drag_start_cam: Vector3) -> void:
	var delta_pixels = drag_start_screen - current_screen
	var factor = (position.y / 800.0) * 1.6
	position.x = drag_start_cam.x + delta_pixels.x * factor
	position.z = drag_start_cam.z + delta_pixels.y * factor * (1.0 if top_down else 1.4)
	_clamp_camera()

func _unhandled_input(event: InputEvent) -> void:
	# Mouse Wheel Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_target_height(target_height - 2.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_target_height(target_height + 2.5)

	# Mobile Multi-touch pinch zoom (2+ fingers)
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)
			if touch_points.size() < 2:
				prev_pinch_distance = -1.0

	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if touch_points.size() >= 2:
			var pts = touch_points.values()
			var dist = pts[0].distance_to(pts[1])
			if prev_pinch_distance > 0.0:
				var factor = prev_pinch_distance / max(1.0, dist)
				_set_target_height(target_height * factor)
			prev_pinch_distance = dist

	# Keyboard Zoom Shortcuts (+ / - / Z / X)
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD, KEY_Z]:
			zoom_in()
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT, KEY_X]:
			zoom_out()

func _process(delta: float) -> void:
	if top_down != FactionArtManager.top_down():
		_apply_view_mode()
		_clamp_camera()
	if abs(position.y - target_height) > 0.05:
		position.y = lerp(position.y, target_height, delta * 10.0)
		_clamp_camera()
	elif not is_zero_approx(delta):
		# the HUD shrank (a menu closed): ease back inside the new limits instead of jumping on the next pan
		var lim := camera_limits()
		var want := Vector2(clampf(position.x, lim["min"].x, lim["max"].x), clampf(position.z, lim["min"].y, lim["max"].y))
		var cur := Vector2(position.x, position.z)
		if cur.distance_to(want) > 0.01:
			cur = cur.lerp(want, minf(1.0, delta * 6.0))
			position.x = cur.x
			position.z = cur.y
	if top_down:
		size = position.y * TOP_DOWN_SIZE_PER_HEIGHT

func _set_target_height(val: float) -> void:
	target_height = clamp(val, min_height, max_height)

func jump_to(target_pos: Vector3, smooth: bool = true) -> void:
	# Camera is offset behind target for 45 deg tilt (tan 45 = 1.0); straight above it in top-down
	var offset_z = 0.0 if top_down else position.y * 1.0
	var dest = Vector3(target_pos.x, position.y, target_pos.z + offset_z)

	if smooth:
		var tw = create_tween()
		tw.tween_property(self, "position:x", dest.x, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "position:z", dest.z, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		position.x = dest.x
		position.z = dest.z
	_clamp_camera()

func _clamp_camera() -> void:
	var lim := camera_limits()
	position.x = clamp(position.x, lim["min"].x, lim["max"].x)
	position.z = clamp(position.z, lim["min"].y, lim["max"].y)

## Ground point (y = 0) seen at a viewport pixel, relative to the camera's x/z. The offset does not depend on
## where the camera is, only on its height, angle and zoom, so it turns screen rows into camera limits.
func _ground_offset(px: Vector2) -> Vector2:
	var o := project_ray_origin(px)
	var n := project_ray_normal(px)
	if n.y > -0.01:
		n.y = -0.01
	var hit := o + n * (o.y / -n.y)
	return Vector2(hit.x - position.x, hit.z - position.z)

## Camera x/z range ({"min": Vector2, "max": Vector2}) that lets every map edge be brought into the part of
## the screen the HUD leaves free, EDGE_MARGIN past it:
##  * bottom edge -> just above the bottom menu (whatever is open), left / right edges -> the screen sides
##    on the lowest free row (the narrowest one in perspective), so all four corners can be reached
##  * top edge -> just under the top bar (top-down 2D); in the 3D perspective the top rows look far past the
##    map, so the middle of the free area is used instead
func camera_limits() -> Dictionary:
	var vs := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(540, 960)
	var top_row := clampf(screen_inset_top, 0.0, vs.y - 2.0)
	var bottom_row := clampf(vs.y - screen_inset_bottom, top_row + 1.0, vs.y)
	var ref_top_row := top_row if top_down else (top_row + bottom_row) * 0.5
	var off_top := _ground_offset(Vector2(vs.x * 0.5, ref_top_row))
	var off_bottom := _ground_offset(Vector2(vs.x * 0.5, bottom_row - 1.0))
	var off_left := _ground_offset(Vector2(0.0, bottom_row - 1.0))
	var off_right := _ground_offset(Vector2(vs.x, bottom_row - 1.0))
	var mn := Vector2(-EDGE_MARGIN - off_left.x, -EDGE_MARGIN - off_top.y)
	var mx := Vector2(map_size.x + EDGE_MARGIN - off_right.x, map_size.y + EDGE_MARGIN - off_bottom.y)
	if mn.x > mx.x:
		mn.x = (mn.x + mx.x) * 0.5
		mx.x = mn.x
	if mn.y > mx.y:
		mn.y = (mn.y + mx.y) * 0.5
		mx.y = mn.y
	return {"min": mn, "max": mx}

## Where a screen point hits the ground. With a terrain (`terrain` = MapGenerator3D) the ray is
## marched down to the hill surface, so a tap on a hilltop lands on the hilltop and not on the
## y = 0 plane behind it.
var terrain: Node = null

func raycast_ground(screen_pos: Vector2) -> Vector3:
	var ray_origin = project_ray_origin(screen_pos)
	var ray_normal = project_ray_normal(screen_pos)
	var ground_plane = Plane(Vector3.UP, 0.0)
	var hit = ground_plane.intersects_ray(ray_origin, ray_normal)
	if terrain != null and is_instance_valid(terrain) and ray_normal.y < -0.01:
		var top: float = terrain.max_terrain_h + 0.1
		# from the ray's point at the highest ground down to the lowest bed, 0.25 m steps
		var t0: float = (ray_origin.y - top) / -ray_normal.y
		var t1: float = (ray_origin.y - (MapGenerator3D.WATER_H - 0.1)) / -ray_normal.y
		var prev_t := t0
		var t := t0
		while t <= t1:
			var p: Vector3 = ray_origin + ray_normal * t
			if p.y <= terrain.get_height_at(p):
				# refine between the last point above and this one
				var lo := prev_t
				var hi := t
				for k in 6:
					var mid := (lo + hi) * 0.5
					var q: Vector3 = ray_origin + ray_normal * mid
					if q.y <= terrain.get_height_at(q):
						hi = mid
					else:
						lo = mid
				return ray_origin + ray_normal * hi
			prev_t = t
			t += 0.25
	if hit != null:
		return hit
	return Vector3.ZERO
