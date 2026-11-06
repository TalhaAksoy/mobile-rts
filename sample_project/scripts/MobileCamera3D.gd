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

func setup_bounds(width: float, height: float) -> void:
	map_bounds_min = Vector2(4, 4)
	map_bounds_max = Vector2(width - 4, height - 4)
	_clamp_camera()

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
	if top_down:
		# orthographic, straight down: keep the view centre inside the map
		position.x = clamp(position.x, map_bounds_min.x + 4.0, map_bounds_max.x - 4.0)
		position.z = clamp(position.z, map_bounds_min.y + 4.0, max(map_bounds_min.y + 4.0, map_bounds_max.y - 4.0))
		return
	var offset_z = position.y * 1.0
	var bottom_view_offset = position.y / tan(deg_to_rad(45.0 + fov * 0.5))
	position.x = clamp(position.x, map_bounds_min.x + 4.0, map_bounds_max.x - 4.0)
	var min_z = map_bounds_min.y + offset_z
	var max_z = map_bounds_max.y + bottom_view_offset - 2.0
	position.z = clamp(position.z, min_z, max(min_z, max_z))

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
