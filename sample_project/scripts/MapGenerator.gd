class_name MapGenerator
extends Node2D

signal map_generated

const TILE_SIZE: int = 32
const MAP_WIDTH: int = 40
const MAP_HEIGHT: int = 60

enum TileType {
	GRASS,
	SAND,
	WATER,
	SHALLOW_WATER,
	ROCK,
	DIRT
}

var map_type: CivData.MapType = CivData.MapType.FOREST_VALLEY
var seed_val: int = 1337
var tiles: Array = [] # 2D array [x][y]
var astar: AStar2D = AStar2D.new()

var trees: Dictionary = {} # Vector2i -> {hp: int, max_hp: int}
var gold_mines: Dictionary = {} # Vector2i -> {gold: int}
var berry_bushes: Dictionary = {} # Vector2i -> {food: int}
var occupied_cells: Dictionary = {} # Vector2i -> Node (Buildings or obstacles)

var player_start_pos: Vector2
var enemy_start_pos: Vector2

var noise: FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

func generate(chosen_map_type: CivData.MapType, custom_seed: int = -1) -> void:
	map_type = chosen_map_type
	seed_val = custom_seed if custom_seed != -1 else randi()
	noise.seed = seed_val
	noise.frequency = 0.05
	
	tiles.clear()
	trees.clear()
	gold_mines.clear()
	berry_bushes.clear()
	occupied_cells.clear()
	astar.clear()
	
	for x in range(MAP_WIDTH):
		var col = []
		col.resize(MAP_HEIGHT)
		tiles.append(col)
		
	# 1. Base terrain generation based on map type
	_generate_terrain_types()
	
	# 2. Base placement (Player in South, Enemy in North)
	player_start_pos = Vector2(MAP_WIDTH * 0.5 * TILE_SIZE, (MAP_HEIGHT - 8) * TILE_SIZE)
	enemy_start_pos = Vector2(MAP_WIDTH * 0.5 * TILE_SIZE, 8 * TILE_SIZE)
	
	# Clear landing zones
	_clear_area(Vector2i(MAP_WIDTH * 0.5, MAP_HEIGHT - 8), 6)
	_clear_area(Vector2i(MAP_WIDTH * 0.5, 8), 6)
	
	# 3. Resource generation
	_generate_resources()
	
	# 4. Build AStar graph
	_build_astar_grid()
	
	queue_redraw()
	map_generated.emit()

func _generate_terrain_types() -> void:
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var n = noise.get_noise_2d(float(x * 2.5), float(y * 2.5))
			var tile = TileType.GRASS
			
			match map_type:
				CivData.MapType.DESERT_OASIS:
					tile = TileType.SAND
					# Center oasis lake
					var dist_to_center = Vector2(x, y).distance_to(Vector2(MAP_WIDTH * 0.5, MAP_HEIGHT * 0.5))
					if dist_to_center < 5.5 + n * 3.0:
						tile = TileType.WATER
					elif dist_to_center < 8.0:
						tile = TileType.GRASS
						
				CivData.MapType.RIVER_CROSSING:
					var river_y = MAP_HEIGHT * 0.5 + sin(x * 0.25) * 3.5 + n * 2.0
					if abs(y - river_y) < 2.5:
						# Crossings (Fords) at x = 10, 20, 30
						if abs(x - 10) <= 2 or abs(x - 20) <= 2 or abs(x - 30) <= 2:
							tile = TileType.SHALLOW_WATER
						else:
							tile = TileType.WATER
					else:
						tile = TileType.GRASS
						
				CivData.MapType.HIGHLAND_PLAINS:
					if n > 0.35:
						tile = TileType.ROCK
					elif n > 0.1:
						tile = TileType.DIRT
					else:
						tile = TileType.GRASS
						
				CivData.MapType.GOLD_RUSH:
					if n > 0.3:
						tile = TileType.DIRT
					elif n < -0.4:
						tile = TileType.WATER
					else:
						tile = TileType.GRASS
						
				CivData.MapType.FOREST_VALLEY:
					if n < -0.35:
						tile = TileType.WATER
					elif n > 0.25:
						tile = TileType.DIRT
					else:
						tile = TileType.GRASS
			
			tiles[x][y] = tile

func _clear_area(center: Vector2i, radius: int) -> void:
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			if is_valid_cell(x, y):
				if tiles[x][y] == TileType.WATER:
					tiles[x][y] = TileType.GRASS if map_type != CivData.MapType.DESERT_OASIS else TileType.SAND

func _generate_resources() -> void:
	var cfg = CivData.get_map_config(map_type)
	var tree_density = cfg.get("tree_density", 0.25)
	
	# Guaranteed starter resources near bases
	_spawn_base_cluster(Vector2i(MAP_WIDTH * 0.5, MAP_HEIGHT - 8))
	_spawn_base_cluster(Vector2i(MAP_WIDTH * 0.5, 8))
	
	# Scattered trees
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var cell = Vector2i(x, y)
			if not is_cell_passable_terrain(x, y):
				continue
			if cell in trees or cell in gold_mines or cell in berry_bushes:
				continue
				
			# Avoid starting spawns
			if cell.distance_to(Vector2i(MAP_WIDTH * 0.5, MAP_HEIGHT - 8)) < 5:
				continue
			if cell.distance_to(Vector2i(MAP_WIDTH * 0.5, 8)) < 5:
				continue
				
			var tree_noise = noise.get_noise_2d(float(x * 5.0 + 100), float(y * 5.0 + 100))
			if map_type == CivData.MapType.FOREST_VALLEY:
				# Heavy flanking forests
				var dist_from_center_x = abs(x - MAP_WIDTH * 0.5)
				if (dist_from_center_x > 6 and tree_noise > -0.15) or tree_noise > 0.35:
					trees[cell] = {"hp": 100, "max_hp": 100}
			elif map_type == CivData.MapType.DESERT_OASIS:
				var dist_center = Vector2(x, y).distance_to(Vector2(MAP_WIDTH * 0.5, MAP_HEIGHT * 0.5))
				if dist_center >= 6.0 and dist_center <= 10.0 and randf() < 0.4:
					trees[cell] = {"hp": 100, "max_hp": 100}
			else:
				if tree_noise > (0.5 - tree_density):
					trees[cell] = {"hp": 100, "max_hp": 100}

	# Scattered Gold Mines
	var total_gold = cfg.get("gold_nodes", 8)
	for i in range(total_gold):
		var spot = _find_random_empty_spot(Vector2i(3, 12), Vector2i(MAP_WIDTH - 4, MAP_HEIGHT - 13))
		if spot != Vector2i(-1, -1):
			_spawn_resource_cluster(spot, "gold", randi_range(2, 4))
			
	# Scattered Berries
	var total_food = cfg.get("food_nodes", 8)
	for i in range(total_food):
		var spot = _find_random_empty_spot(Vector2i(3, 12), Vector2i(MAP_WIDTH - 4, MAP_HEIGHT - 13))
		if spot != Vector2i(-1, -1):
			_spawn_resource_cluster(spot, "food", randi_range(2, 3))

func _spawn_base_cluster(center: Vector2i) -> void:
	# Gold node near base
	var gold_offset = Vector2i(-4, 2) if center.y > 20 else Vector2i(-4, -2)
	_spawn_resource_cluster(center + gold_offset, "gold", 3)
	
	# Berry bush near base
	var berry_offset = Vector2i(4, 2) if center.y > 20 else Vector2i(4, -2)
	_spawn_resource_cluster(center + berry_offset, "food", 3)
	
	# Wood line behind base
	var wood_y_dir = 1 if center.y > 20 else -1
	for dx in range(-4, 5):
		for dy in range(1, 4):
			var c = center + Vector2i(dx, dy * wood_y_dir)
			if is_valid_cell(c.x, c.y):
				trees[c] = {"hp": 100, "max_hp": 100}

func _spawn_resource_cluster(origin: Vector2i, type: String, count: int) -> void:
	var placed = 0
	var queue = [origin]
	var visited = {}
	
	while queue.size() > 0 and placed < count:
		var curr = queue.pop_front()
		if not is_valid_cell(curr.x, curr.y) or curr in visited:
			continue
		visited[curr] = true
		
		if is_cell_passable_terrain(curr.x, curr.y) and not (curr in trees or curr in gold_mines or curr in berry_bushes):
			if type == "gold":
				gold_mines[curr] = {"gold": 800}
			elif type == "food":
				berry_bushes[curr] = {"food": 250}
			placed += 1
			
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			queue.append(curr + dir)

func _find_random_empty_spot(min_bound: Vector2i, max_bound: Vector2i) -> Vector2i:
	for attempt in range(50):
		var rx = randi_range(min_bound.x, max_bound.x)
		var ry = randi_range(min_bound.y, max_bound.y)
		var c = Vector2i(rx, ry)
		if is_cell_passable_terrain(rx, ry) and not (c in trees or c in gold_mines or c in berry_bushes):
			return c
	return Vector2i(-1, -1)

func _build_astar_grid() -> void:
	astar.clear()
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var id = _cell_to_id(x, y)
			astar.add_point(id, Vector2(x * TILE_SIZE + TILE_SIZE * 0.5, y * TILE_SIZE + TILE_SIZE * 0.5))
			var passable = is_cell_walkable(Vector2i(x, y))
			astar.set_point_disabled(id, not passable)
			
	# Connect neighbors
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var id1 = _cell_to_id(x, y)
			if x + 1 < MAP_WIDTH:
				var id2 = _cell_to_id(x + 1, y)
				astar.connect_points(id1, id2)
			if y + 1 < MAP_HEIGHT:
				var id3 = _cell_to_id(x, y + 1)
				astar.connect_points(id1, id3)
			# Diagonal connections
			if x + 1 < MAP_WIDTH and y + 1 < MAP_HEIGHT:
				var id4 = _cell_to_id(x + 1, y + 1)
				astar.connect_points(id1, id4)
			if x - 1 >= 0 and y + 1 < MAP_HEIGHT:
				var id5 = _cell_to_id(x - 1, y + 1)
				astar.connect_points(id1, id5)

func _cell_to_id(x: int, y: int) -> int:
	return y * MAP_WIDTH + x

func _id_to_cell(id: int) -> Vector2i:
	return Vector2i(id % MAP_WIDTH, int(float(id) / float(MAP_WIDTH)))

func is_valid_cell(x: int, y: int) -> bool:
	return x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT

func is_cell_passable_terrain(x: int, y: int) -> bool:
	if not is_valid_cell(x, y):
		return false
	var t = tiles[x][y]
	return t != TileType.WATER and t != TileType.ROCK

func is_cell_walkable(cell: Vector2i) -> bool:
	if not is_cell_passable_terrain(cell.x, cell.y):
		return false
	if cell in trees or cell in gold_mines or cell in occupied_cells:
		return false
	return true

func update_cell_walkability(cell: Vector2i) -> void:
	if is_valid_cell(cell.x, cell.y):
		var id = _cell_to_id(cell.x, cell.y)
		astar.set_point_disabled(id, not is_cell_walkable(cell))

func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / TILE_SIZE), int(pos.y / TILE_SIZE))

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_SIZE + TILE_SIZE * 0.5, cell.y * TILE_SIZE + TILE_SIZE * 0.5)

func get_path_to_target(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	var from_cell = world_to_cell(from_world)
	var to_cell = world_to_cell(to_world)
	
	from_cell.x = clamp(from_cell.x, 0, MAP_WIDTH - 1)
	from_cell.y = clamp(from_cell.y, 0, MAP_HEIGHT - 1)
	to_cell.x = clamp(to_cell.x, 0, MAP_WIDTH - 1)
	to_cell.y = clamp(to_cell.y, 0, MAP_HEIGHT - 1)
	
	var from_id = _cell_to_id(from_cell.x, from_cell.y)
	var to_id = _cell_to_id(to_cell.x, to_cell.y)
	
	# If target is occupied/disabled (e.g. tree or gold mine or building), find closest walkable neighbor
	if astar.is_point_disabled(to_id):
		var best_dist = 999999.0
		var best_id = -1
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var nc = to_cell + Vector2i(dx, dy)
				if is_valid_cell(nc.x, nc.y):
					var nid = _cell_to_id(nc.x, nc.y)
					if not astar.is_point_disabled(nid):
						var d = nc.distance_squared_to(from_cell)
						if d < best_dist:
							best_dist = d
							best_id = nid
		if best_id != -1:
			to_id = best_id
			
	if astar.is_point_disabled(from_id):
		# If unit got stuck, find nearest valid
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var nc = from_cell + Vector2i(dx, dy)
				if is_valid_cell(nc.x, nc.y):
					var nid = _cell_to_id(nc.x, nc.y)
					if not astar.is_point_disabled(nid):
						from_id = nid
						break
						
	return astar.get_point_path(from_id, to_id)

func harvest_tree(cell: Vector2i, amount: int) -> int:
	if not cell in trees:
		return 0
	var t = trees[cell]
	var harvested = min(amount, t.hp)
	t.hp -= harvested
	if t.hp <= 0:
		trees.erase(cell)
		update_cell_walkability(cell)
		queue_redraw()
	return harvested

func harvest_gold(cell: Vector2i, amount: int) -> int:
	if not cell in gold_mines:
		return 0
	var g = gold_mines[cell]
	var harvested = min(amount, g.gold)
	g.gold -= harvested
	if g.gold <= 0:
		gold_mines.erase(cell)
		update_cell_walkability(cell)
		queue_redraw()
	return harvested

func harvest_food(cell: Vector2i, amount: int) -> int:
	if not cell in berry_bushes:
		return 0
	var b = berry_bushes[cell]
	var harvested = min(amount, b.food)
	b.food -= harvested
	if b.food <= 0:
		berry_bushes.erase(cell)
		queue_redraw()
	return harvested

func register_building_cells(origin_cell: Vector2i, size: Vector2i, building_node: Node) -> void:
	for dx in range(size.x):
		for dy in range(size.y):
			var c = origin_cell + Vector2i(dx, dy)
			occupied_cells[c] = building_node
			update_cell_walkability(c)

func unregister_building_cells(origin_cell: Vector2i, size: Vector2i) -> void:
	for dx in range(size.x):
		for dy in range(size.y):
			var c = origin_cell + Vector2i(dx, dy)
			occupied_cells.erase(c)
			update_cell_walkability(c)

func _draw() -> void:
	if tiles.is_empty():
		return
		
	var cfg = CivData.get_map_config(map_type)
	var g_color = cfg.get("ground_color", Color(0.24, 0.48, 0.22))
	var g_accent = cfg.get("ground_accent", Color(0.29, 0.55, 0.26))
	var w_color = cfg.get("water_color", Color(0.18, 0.42, 0.65))
	
	# Draw background grid & terrain tiles
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var rect = Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			var tile = tiles[x][y]
			var col = g_color
			
			match tile:
				TileType.GRASS:
					col = g_color if (x + y) % 2 == 0 else g_accent
				TileType.SAND:
					col = Color(0.84, 0.76, 0.48) if (x + y) % 2 == 0 else Color(0.80, 0.70, 0.42)
				TileType.WATER:
					col = w_color
				TileType.SHALLOW_WATER:
					col = w_color.lerp(Color(0.8, 0.75, 0.5), 0.45)
				TileType.ROCK:
					col = Color(0.48, 0.46, 0.44)
				TileType.DIRT:
					col = Color(0.45, 0.35, 0.22)
					
			draw_rect(rect, col)
			# Subtle grid outline for tactical feel
			draw_rect(rect, Color(0, 0, 0, 0.05), false, 1.0)
			
			if tile == TileType.WATER:
				# Animated/rippled lines
				draw_line(Vector2(rect.position.x + 4, rect.position.y + 16), Vector2(rect.position.x + 26, rect.position.y + 16), Color(1, 1, 1, 0.2), 2.0)
			elif tile == TileType.SHALLOW_WATER:
				# Wood plank bridge look
				draw_line(Vector2(rect.position.x, rect.position.y + 8), Vector2(rect.position.x + TILE_SIZE, rect.position.y + 8), Color(0.3, 0.2, 0.1, 0.6), 2.0)
				draw_line(Vector2(rect.position.x, rect.position.y + 24), Vector2(rect.position.x + TILE_SIZE, rect.position.y + 24), Color(0.3, 0.2, 0.1, 0.6), 2.0)

	# Draw Berry Bushes
	for cell in berry_bushes.keys():
		var center = cell_to_world(cell)
		# Bush foliage
		draw_circle(center + Vector2(0, 2), 10.0, Color(0.18, 0.45, 0.18))
		draw_circle(center + Vector2(-4, -2), 8.0, Color(0.24, 0.55, 0.22))
		draw_circle(center + Vector2(4, -1), 7.0, Color(0.22, 0.52, 0.20))
		# Red berries
		draw_circle(center + Vector2(-3, 0), 2.5, Color(0.9, 0.15, 0.15))
		draw_circle(center + Vector2(3, 2), 2.5, Color(0.95, 0.2, 0.2))
		draw_circle(center + Vector2(1, -4), 2.5, Color(0.85, 0.1, 0.1))

	# Draw Gold Mines
	for cell in gold_mines.keys():
		var center = cell_to_world(cell)
		# Rocky base
		var rock_pts = PackedVector2Array([
			center + Vector2(-12, 10), center + Vector2(-14, 0),
			center + Vector2(-6, -11), center + Vector2(7, -12),
			center + Vector2(14, -2), center + Vector2(12, 10)
		])
		draw_colored_polygon(rock_pts, Color(0.35, 0.35, 0.38))
		draw_polyline(rock_pts, Color(0.2, 0.2, 0.22), 2.0)
		# Golden crystals
		draw_rect(Rect2(center.x - 7, center.y - 6, 6, 6), Color(1.0, 0.85, 0.15))
		draw_rect(Rect2(center.x + 2, center.y - 8, 7, 7), Color(0.95, 0.75, 0.1))
		draw_rect(Rect2(center.x - 2, center.y + 1, 6, 6), Color(1.0, 0.9, 0.3))

	# Draw Trees
	for cell in trees.keys():
		var center = cell_to_world(cell)
		# Shadow
		draw_circle(center + Vector2(2, 8), 9.0, Color(0, 0, 0, 0.25))
		# Trunk
		draw_rect(Rect2(center.x - 3, center.y + 2, 6, 8), Color(0.38, 0.24, 0.12))
		# Canopy layers
		draw_circle(center + Vector2(0, 0), 12.0, Color(0.12, 0.38, 0.12))
		draw_circle(center + Vector2(-3, -4), 10.0, Color(0.16, 0.48, 0.16))
		draw_circle(center + Vector2(3, -5), 9.0, Color(0.22, 0.58, 0.22))
