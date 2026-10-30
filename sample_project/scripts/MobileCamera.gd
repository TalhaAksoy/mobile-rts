class_name MobileCamera
extends Camera2D

@export var map_bounds: Rect2 = Rect2(0, 0, 1280, 1920)

var is_dragging: bool = false
var drag_start_mouse_pos: Vector2
var drag_start_cam_pos: Vector2

var min_zoom: float = 0.55
var max_zoom: float = 1.6
var target_zoom: float = 0.95

# Touch pinch zoom tracking
var touch_points: Dictionary = {}

func _ready() -> void:
	zoom = Vector2(target_zoom, target_zoom)

func setup_bounds(width_px: float, height_px: float) -> void:
	map_bounds = Rect2(0, 0, width_px, height_px)
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
			_set_target_zoom(target_zoom + 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_target_zoom(target_zoom - 0.1)
			
	elif event is InputEventMouseMotion and is_dragging:
		var delta_pos = (drag_start_mouse_pos - event.position) / zoom.x
		position = drag_start_cam_pos + delta_pos
		_clamp_camera()

	# Mobile Multi-touch pinch zoom
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)
			
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if touch_points.size() == 2:
			var pts = touch_points.values()
			var prev_dist = (pts[0] - event.relative).distance_to(pts[1])
			var new_dist = pts[0].distance_to(pts[1])
			var zoom_factor = new_dist / max(1.0, prev_dist)
			_set_target_zoom(target_zoom * zoom_factor)

func _process(delta: float) -> void:
	# Smooth zoom interpolation
	if abs(zoom.x - target_zoom) > 0.005:
		var new_z = lerp(zoom.x, target_zoom, delta * 12.0)
		zoom = Vector2(new_z, new_z)
		_clamp_camera()

func _set_target_zoom(val: float) -> void:
	target_zoom = clamp(val, min_zoom, max_zoom)

func jump_to(pos: Vector2, smooth: bool = true) -> void:
	if smooth:
		var tw = create_tween()
		tw.tween_property(self, "position", pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		position = pos
	_clamp_camera()

func _clamp_camera() -> void:
	var vp_size = get_viewport_rect().size / zoom.x
	var half_vp = vp_size * 0.5
	
	position.x = clamp(position.x, map_bounds.position.x + half_vp.x * 0.5, map_bounds.end.x - half_vp.x * 0.5)
	position.y = clamp(position.y, map_bounds.position.y + half_vp.y * 0.5, map_bounds.end.y - half_vp.y * 0.5)
