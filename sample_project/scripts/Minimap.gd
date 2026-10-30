class_name Minimap
extends Control

@export var map_gen: MapGenerator
@export var camera: MobileCamera
@export var game_controller: GameController

var is_dragging: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(90, 135) # 40x60 ratio

func _process(_delta: float) -> void:
	if visible and is_instance_valid(game_controller) and game_controller.is_game_active:
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not is_instance_valid(map_gen) or not is_instance_valid(camera):
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			if event.pressed:
				_jump_camera_to_click(event.position)
	elif event is InputEventMouseMotion and is_dragging:
		_jump_camera_to_click(event.position)

func _jump_camera_to_click(local_pos: Vector2) -> void:
	var norm_x = clamp(local_pos.x / size.x, 0.0, 1.0)
	var norm_y = clamp(local_pos.y / size.y, 0.0, 1.0)
	var world_x = norm_x * (MapGenerator.MAP_WIDTH * MapGenerator.TILE_SIZE)
	var world_y = norm_y * (MapGenerator.MAP_HEIGHT * MapGenerator.TILE_SIZE)
	camera.jump_to(Vector2(world_x, world_y))

func _draw() -> void:
	if not is_instance_valid(map_gen) or map_gen.tiles.is_empty():
		return
		
	# Background border
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.14, 0.85))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 0.45, 0.5, 0.9), false, 1.5)
	
	var sx = size.x / float(MapGenerator.MAP_WIDTH)
	var sy = size.y / float(MapGenerator.MAP_HEIGHT)
	
	# Draw Water / Obstacles
	for x in range(MapGenerator.MAP_WIDTH):
		for y in range(MapGenerator.MAP_HEIGHT):
			var t = map_gen.tiles[x][y]
			if t == MapGenerator.TileType.WATER:
				draw_rect(Rect2(x * sx, y * sy, ceil(sx), ceil(sy)), Color(0.2, 0.45, 0.75, 0.8))
			elif t == MapGenerator.TileType.SHALLOW_WATER:
				draw_rect(Rect2(x * sx, y * sy, ceil(sx), ceil(sy)), Color(0.6, 0.55, 0.35, 0.8))
				
	# Draw Gold nodes (yellow dots)
	for cell in map_gen.gold_mines.keys():
		draw_rect(Rect2(cell.x * sx - 0.5, cell.y * sy - 0.5, 2.5, 2.5), Color(1.0, 0.85, 0.2))

	if not is_instance_valid(game_controller):
		return

	# Draw Buildings
	for b in game_controller.buildings:
		if is_instance_valid(b):
			var cell = b.origin_cell
			var col = Color(0.2, 0.6, 1.0) if b.team == 0 else Color(1.0, 0.25, 0.25)
			var bw = b.grid_size.x * sx
			var bh = b.grid_size.y * sy
			draw_rect(Rect2(cell.x * sx, cell.y * sy, bw, bh), col)

	# Draw Units
	for u in game_controller.units:
		if is_instance_valid(u):
			var c = map_gen.world_to_cell(u.global_position)
			var col = Color(0.4, 0.8, 1.0) if u.team == 0 else Color(1.0, 0.35, 0.35)
			draw_rect(Rect2(c.x * sx - 1.0, c.y * sy - 1.0, 3.0, 3.0), col)

	# Draw Camera Viewport Box
	if is_instance_valid(camera):
		var vp_size = camera.get_viewport_rect().size / camera.zoom.x
		var cam_rect_world = Rect2(camera.position - vp_size * 0.5, vp_size)
		var total_w = MapGenerator.MAP_WIDTH * MapGenerator.TILE_SIZE
		var total_h = MapGenerator.MAP_HEIGHT * MapGenerator.TILE_SIZE
		
		var vp_norm_pos = Vector2(cam_rect_world.position.x / total_w, cam_rect_world.position.y / total_h)
		var vp_norm_size = Vector2(cam_rect_world.size.x / total_w, cam_rect_world.size.y / total_h)
		
		var vp_rect = Rect2(vp_norm_pos.x * size.x, vp_norm_pos.y * size.y, vp_norm_size.x * size.x, vp_norm_size.y * size.y)
		draw_rect(vp_rect, Color(1, 1, 1, 0.7), false, 1.5)
