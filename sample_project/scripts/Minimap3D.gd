class_name Minimap3D
extends Control

@export var map_gen: MapGenerator3D
@export var camera: MobileCamera3D
@export var game_controller: Node

var is_dragging: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(100, 150)

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
	var world_x = norm_x * (MapGenerator3D.MAP_WIDTH * MapGenerator3D.TILE_SIZE)
	var world_z = norm_y * (MapGenerator3D.MAP_HEIGHT * MapGenerator3D.TILE_SIZE)
	camera.jump_to(Vector3(world_x, 0, world_z))

func _draw() -> void:
	if not is_instance_valid(map_gen) or map_gen.tiles.is_empty():
		return

	# Antique Parchment Chart Background
	draw_rect(Rect2(Vector2.ZERO, size), ParchmentTheme.PARCHMENT_BG)
	# Weathered edge vignette
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.72, 0.62, 0.45, 0.4))
	# Embossed Leather & Gold Border
	draw_rect(Rect2(Vector2.ZERO, size), ParchmentTheme.LEATHER_BORDER, false, 3.0)
	draw_rect(Rect2(Vector2.ZERO, size).grow(-3.0), ParchmentTheme.BRONZE_GOLD, false, 1.0)

	var sx = size.x / float(MapGenerator3D.MAP_WIDTH)
	var sy = size.y / float(MapGenerator3D.MAP_HEIGHT)

	# Water & Bridges (Antique ink wash style)
	for x in range(MapGenerator3D.MAP_WIDTH):
		for y in range(MapGenerator3D.MAP_HEIGHT):
			var t = map_gen.tiles[x][y]
			if t == MapGenerator3D.TileType.WATER:
				draw_rect(Rect2(x * sx, y * sy, ceil(sx), ceil(sy)), Color(0.32, 0.46, 0.58, 0.85))
			elif t == MapGenerator3D.TileType.SHALLOW_WATER:
				draw_rect(Rect2(x * sx, y * sy, ceil(sx), ceil(sy)), Color(0.68, 0.58, 0.42, 0.85))

	# Gold Nodes (Golden coin stamps)
	for cell in map_gen.gold_mines.keys():
		draw_circle(Vector2(cell.x * sx + sx * 0.5, cell.y * sy + sy * 0.5), 2.5, Color(0.85, 0.68, 0.15))
		draw_circle(Vector2(cell.x * sx + sx * 0.5, cell.y * sy + sy * 0.5), 1.2, Color(0.3, 0.2, 0.05))

	# Stone Nodes (Granite slate stamps)
	for cell in map_gen.stone_mines.keys():
		draw_circle(Vector2(cell.x * sx + sx * 0.5, cell.y * sy + sy * 0.5), 2.2, Color(0.65, 0.65, 0.70))
		draw_circle(Vector2(cell.x * sx + sx * 0.5, cell.y * sy + sy * 0.5), 1.0, Color(0.2, 0.2, 0.25))

	if not is_instance_valid(game_controller):
		return

	# Buildings (Heraldic block stamps)
	for b in game_controller.buildings:
		if is_instance_valid(b):
			var cell = b.origin_cell
			if b.team != 0 and map_gen.get_fog_state(cell) == MapGenerator3D.FogState.UNEXPLORED:
				continue
			var col = Color(0.18, 0.45, 0.85) if b.team == 0 else Color(0.85, 0.18, 0.18)
			var bw = b.grid_size.x * sx
			var bh = b.grid_size.y * sy
			var b_rect = Rect2(cell.x * sx, cell.y * sy, bw, bh)
			draw_rect(b_rect, col)
			draw_rect(b_rect, ParchmentTheme.INK_DARK, false, 1.0)

	# Units (Heraldic dots)
	for u in game_controller.units:
		if is_instance_valid(u):
			var c = map_gen.world_to_cell(u.global_position)
			if u.team != 0 and map_gen.get_fog_state(c) != MapGenerator3D.FogState.VISIBLE:
				continue
			var col = Color(0.15, 0.45, 0.95) if u.team == 0 else Color(0.9, 0.15, 0.15)
			var u_center = Vector2(c.x * sx + sx * 0.5, c.y * sy + sy * 0.5)
			draw_circle(u_center, 2.8, col)
			draw_circle(u_center, 2.8, ParchmentTheme.INK_DARK, false, 1.0)

	# Fog of War on Minimap Shroud
	if not map_gen.fog_grid.is_empty():
		for x in range(MapGenerator3D.MAP_WIDTH):
			for y in range(MapGenerator3D.MAP_HEIGHT):
				var st = map_gen.fog_grid[x][y]
				if st == MapGenerator3D.FogState.UNEXPLORED:
					draw_rect(Rect2(x * sx, y * sy, ceil(sx), ceil(sy)), Color(0.12, 0.10, 0.08, 0.88))
				elif st == MapGenerator3D.FogState.EXPLORED:
					draw_rect(Rect2(x * sx, y * sy, ceil(sx), ceil(sy)), Color(0.25, 0.22, 0.18, 0.35))

	# Camera Viewport Box (Inked surveyor box)
	if is_instance_valid(camera):
		var total_w = MapGenerator3D.MAP_WIDTH * MapGenerator3D.TILE_SIZE
		var total_h = MapGenerator3D.MAP_HEIGHT * MapGenerator3D.TILE_SIZE
		var cam_cx = (camera.position.x / total_w) * size.x
		var cam_cz = ((camera.position.z - camera.position.y * 0.65) / total_h) * size.y
		var box_w = (camera.position.y / total_w) * size.x * 0.9
		var box_h = (camera.position.y / total_h) * size.y * 1.1
		var cam_rect = Rect2(cam_cx - box_w * 0.5, cam_cz - box_h * 0.5, box_w, box_h)
		draw_rect(cam_rect, Color(0.16, 0.11, 0.07, 0.8), false, 2.0)
		draw_rect(cam_rect.grow(1.0), Color(0.95, 0.85, 0.4, 0.6), false, 1.0)

	# Antique North Compass Marker in corner
	var comp_pos = Vector2(size.x - 12, 14)
	draw_line(comp_pos, comp_pos + Vector2(0, -8), Color(0.8, 0.2, 0.2), 2.0)
	draw_string(ParchmentTheme.get_serif_font(10), comp_pos + Vector2(-3, -9), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.8, 0.2, 0.2))
