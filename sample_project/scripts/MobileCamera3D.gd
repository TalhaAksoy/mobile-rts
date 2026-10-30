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

func _ready() -> void:
	# Classic 2.5D / HD-2D Diorama angle (45 degrees)
	rotation_degrees = Vector3(-45, 0, 0)
	position.y = target_height

func setup_bounds(width: float, height: float) -> void:
	map_bounds_min = Vector2(4, 4)
	map_bounds_max = Vector2(width - 4, height - 4)
	_clamp_camera()

func _unhandled_input(event: InputEvent) -> void:
	# Mouse / Single Touch Drag
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start_mouse_pos = event.position
				drag_start_cam_pos = position
			else:
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_target_height(target_height - 2.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_target_height(target_height + 2.5)

	elif event is InputEventMouseMotion and is_dragging:
		var delta_pixels = drag_start_mouse_pos - event.position
		# Convert screen delta to 3D ground displacement based on camera height
		var factor = (position.y / 800.0) * 1.6
		var new_x = drag_start_cam_pos.x + delta_pixels.x * factor
		var new_z = drag_start_cam_pos.z + delta_pixels.y * factor * 1.4
		position.x = new_x
		position.z = new_z
		_clamp_camera()

	# Mobile Multi-touch pinch zoom
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
	if abs(position.y - target_height) > 0.05:
		position.y = lerp(position.y, target_height, delta * 10.0)
		_clamp_camera()

func _set_target_height(val: float) -> void:
	target_height = clamp(val, min_height, max_height)

func jump_to(target_pos: Vector3, smooth: bool = true) -> void:
	# Camera is offset behind target for 45 deg tilt (tan 45 = 1.0)
	var offset_z = position.y * 1.0
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
	var offset_z = position.y * 1.0
	var bottom_view_offset = position.y / tan(deg_to_rad(45.0 + fov * 0.5))
	position.x = clamp(position.x, map_bounds_min.x + 4.0, map_bounds_max.x - 4.0)
	var min_z = map_bounds_min.y + offset_z
	var max_z = map_bounds_max.y + bottom_view_offset - 2.0
	position.z = clamp(position.z, min_z, max(min_z, max_z))

func raycast_ground(screen_pos: Vector2) -> Vector3:
	var ray_origin = project_ray_origin(screen_pos)
	var ray_normal = project_ray_normal(screen_pos)
	var ground_plane = Plane(Vector3.UP, 0.0)
	var hit = ground_plane.intersects_ray(ray_origin, ray_normal)
	if hit != null:
		return hit
	return Vector3.ZERO
