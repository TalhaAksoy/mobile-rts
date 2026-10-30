class_name MapGenerator3D
extends Node3D

const PixelArtTextures = preload("res://scripts/PixelArtTextures.gd")

signal map_generated

const TILE_SIZE: float = 2.0
const MAP_WIDTH: int = 32
const MAP_HEIGHT: int = 60

enum TileType {
	GRASS,
	SAND,
	WATER,
	SHALLOW_WATER,
	ROCK,
	DIRT
}

enum FogState {
	UNEXPLORED = 0,
	EXPLORED = 1,
	VISIBLE = 2
}

var fog_grid: Array = []
var fog_image: Image = null
var fog_texture: ImageTexture = null
var fog_mesh_inst: MeshInstance3D = null

var map_type: CivData.MapType = CivData.MapType.FOREST_VALLEY
var seed_val: int = 1337
var tiles: Array = []
var height_map: Array = [] # 2D array [x][y] of float heights
var astar: AStar2D = AStar2D.new()

var trees: Dictionary = {} # Vector2i -> Node3D
var gold_mines: Dictionary = {} # Vector2i -> Node3D
var stone_mines: Dictionary = {} # Vector2i -> Node3D
var berry_bushes: Dictionary = {} # Vector2i -> Node3D
var occupied_cells: Dictionary = {}

var player_start_pos: Vector3
var enemy_start_pos: Vector3

var noise: FastNoiseLite = FastNoiseLite.new()
var detail_noise: FastNoiseLite = FastNoiseLite.new()

@onready var ground_container: Node3D = $GroundContainer
@onready var props_container: Node3D = $PropsContainer

var water_mesh_instances: Array[MeshInstance3D] = []
var bridge_mesh_instances: Array[Node3D] = []
var gold_crystal_materials: Array[StandardMaterial3D] = []
var anim_time: float = 0.0

func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = 0.15

func _process(delta: float) -> void:
	anim_time += delta
	
	# 1. Subtle water surface ripples
	for w_inst in water_mesh_instances:
		if is_instance_valid(w_inst):
			w_inst.position.y = -0.3 + sin(anim_time * 2.2 + w_inst.position.x * 0.4) * 0.04
			
	# 2. Pulsing gold mine sparkles / gleam
	var gold_pulse = 0.35 + sin(anim_time * 4.0) * 0.25
	for g_mat in gold_crystal_materials:
		if is_instance_valid(g_mat):
			g_mat.emission_energy_multiplier = gold_pulse
			
	# 3. Gentle wind sway on trees
	for tree_data in trees.values():
		var t_node = tree_data.get("node") as Node3D
		if is_instance_valid(t_node):
			var sway = sin(anim_time * 2.6 + t_node.position.x * 0.8 + t_node.position.z * 0.4) * 0.045
			t_node.rotation.z = sway

func generate(chosen_map_type: CivData.MapType, custom_seed: int = -1) -> void:
	map_type = chosen_map_type
	seed_val = custom_seed if custom_seed != -1 else randi()
	noise.seed = seed_val
	noise.frequency = 0.05
	detail_noise.seed = seed_val + 99

	for child in ground_container.get_children():
		child.queue_free()
	for child in props_container.get_children():
		child.queue_free()

	water_mesh_instances.clear()
	bridge_mesh_instances.clear()
	gold_crystal_materials.clear()
	tiles.clear()
	height_map.clear()
	trees.clear()
	gold_mines.clear()
	berry_bushes.clear()
	occupied_cells.clear()
	astar.clear()

	for x in range(MAP_WIDTH):
		var col_tiles = []
		col_tiles.resize(MAP_HEIGHT)
		tiles.append(col_tiles)
		var col_h = []
		col_h.resize(MAP_HEIGHT)
		height_map.append(col_h)

	_generate_terrain_types_and_heights()

	player_start_pos = cell_to_world(Vector2i(int(MAP_WIDTH * 0.5), MAP_HEIGHT - 12))
	enemy_start_pos = cell_to_world(Vector2i(int(MAP_WIDTH * 0.5), 10))

	_clear_area(world_to_cell(player_start_pos), 7)
	_clear_area(world_to_cell(enemy_start_pos), 7)

	# 1. Create Natural Organic Smooth Terrain Mesh
	_create_natural_organic_terrain()

	# 2. Create 3D Resources with Natural Props
	_generate_3d_resources()

	# 3. Build AStar Pathfinding
	_build_astar_grid()

	# 4. Initialize HD-2D Diorama Fog of War
	_init_fog_of_war()
	_reveal_circle(world_to_cell(player_start_pos), 12)
	update_fog_of_war([], [], [], [])

	map_generated.emit()

func _init_fog_of_war() -> void:
	fog_grid.clear()
	for x in range(MAP_WIDTH):
		var col = []
		col.resize(MAP_HEIGHT)
		col.fill(FogState.UNEXPLORED)
		fog_grid.append(col)

	fog_image = Image.create(MAP_WIDTH, MAP_HEIGHT, false, Image.FORMAT_RGBA8)
	fog_image.fill(Color(0.04, 0.04, 0.06, 0.98))
	fog_texture = ImageTexture.create_from_image(fog_image)

	if is_instance_valid(fog_mesh_inst):
		fog_mesh_inst.queue_free()

	# Find highest elevation on current map
	var max_h = 0.0
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			if height_map[x][y] > max_h:
				max_h = height_map[x][y]

	fog_mesh_inst = MeshInstance3D.new()
	fog_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var pm = PlaneMesh.new()
	pm.size = Vector2(MAP_WIDTH * TILE_SIZE + 6.0, MAP_HEIGHT * TILE_SIZE + 6.0)
	fog_mesh_inst.mesh = pm
	# Position at base elevation with no-depth-test overlay so no tree crowns punch through
	fog_mesh_inst.position = Vector3((MAP_WIDTH * TILE_SIZE) * 0.5, 0.45, (MAP_HEIGHT * TILE_SIZE) * 0.5)

	var f_mat = StandardMaterial3D.new()
	f_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	f_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	f_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	f_mat.no_depth_test = true
	f_mat.render_priority = 25
	f_mat.albedo_texture = fog_texture
	f_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	fog_mesh_inst.material_override = f_mat
	ground_container.add_child(fog_mesh_inst)

func get_fog_state(cell: Vector2i) -> FogState:
	if is_valid_cell(cell.x, cell.y) and not fog_grid.is_empty():
		return fog_grid[cell.x][cell.y]
	return FogState.UNEXPLORED

func update_fog_of_war(player_units: Array, player_buildings: Array, enemy_units: Array, enemy_buildings: Array) -> void:
	if fog_grid.is_empty() or fog_image == null or fog_texture == null:
		return

	# 1. Decay current visible cells to explored
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			if fog_grid[x][y] == FogState.VISIBLE:
				fog_grid[x][y] = FogState.EXPLORED

	# 2. Reveal around player units
	for u in player_units:
		if is_instance_valid(u) and u.hp > 0:
			var center = world_to_cell(u.global_position)
			var r = 9 if u.is_cavalry() else 6
			_reveal_circle(center, r)

	# 3. Reveal around player buildings
	for b in player_buildings:
		if is_instance_valid(b) and b.hp > 0:
			var center = b.origin_cell + Vector2i(int(b.grid_size.x * 0.5), int(b.grid_size.y * 0.5))
			var r = 12 if b.building_type == Building3D.BuildingType.TOWN_CENTER else (10 if b.building_type in [Building3D.BuildingType.TOWER, Building3D.BuildingType.CASTLE] else 7)
			_reveal_circle(center, r)

	# 4. Render to fog texture
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var st = fog_grid[x][y]
			if st == FogState.VISIBLE:
				fog_image.set_pixel(x, y, Color(0, 0, 0, 0.0))
			elif st == FogState.EXPLORED:
				fog_image.set_pixel(x, y, Color(0.05, 0.05, 0.08, 0.55))
			else:
				fog_image.set_pixel(x, y, Color(0.04, 0.04, 0.06, 0.96))

	fog_texture.update(fog_image)

	# 5. Hide/show enemy entities based on line of sight
	for eu in enemy_units:
		if is_instance_valid(eu):
			var c = world_to_cell(eu.global_position)
			eu.visible = (get_fog_state(c) == FogState.VISIBLE)

	for eb in enemy_buildings:
		if is_instance_valid(eb):
			var c = eb.origin_cell
			eb.visible = (get_fog_state(c) >= FogState.EXPLORED)

	# 6. Hide resources in UNEXPLORED fog, shroud in EXPLORED fog
	for cell in trees:
		var t_data = trees[cell]
		var t_raw = t_data.get("node")
		if is_instance_valid(t_raw) and t_raw is Node3D:
			var t_node = t_raw as Node3D
			var st = get_fog_state(cell)
			t_node.visible = (st >= FogState.EXPLORED)
			if t_node.visible and t_node.get_child_count() > 0:
				var spr = t_node.get_child(0)
				if is_instance_valid(spr) and spr is Sprite3D:
					spr.modulate = Color(1.0, 1.0, 1.0, 1.0) if st == FogState.VISIBLE else Color(0.68, 0.68, 0.74, 1.0)

	for cell in gold_mines:
		var g_data = gold_mines[cell]
		var g_raw = g_data.get("node")
		if is_instance_valid(g_raw) and g_raw is Node3D:
			var g_node = g_raw as Node3D
			var st = get_fog_state(cell)
			g_node.visible = (st >= FogState.EXPLORED)
			if g_node.visible and g_node.get_child_count() > 0:
				var spr = g_node.get_child(0)
				if is_instance_valid(spr) and spr is Sprite3D:
					spr.modulate = Color(1.0, 1.0, 1.0, 1.0) if st == FogState.VISIBLE else Color(0.68, 0.68, 0.74, 1.0)

	for cell in stone_mines:
		var s_data = stone_mines[cell]
		var s_raw = s_data.get("node")
		if is_instance_valid(s_raw) and s_raw is Node3D:
			var s_node = s_raw as Node3D
			var st = get_fog_state(cell)
			s_node.visible = (st >= FogState.EXPLORED)
			if s_node.visible and s_node.get_child_count() > 0:
				var spr = s_node.get_child(0)
				if is_instance_valid(spr) and spr is Sprite3D:
					spr.modulate = Color(1.0, 1.0, 1.0, 1.0) if st == FogState.VISIBLE else Color(0.68, 0.68, 0.74, 1.0)

	for cell in berry_bushes:
		var b_data = berry_bushes[cell]
		var b_raw = b_data.get("node")
		if is_instance_valid(b_raw) and b_raw is Node3D:
			var b_node = b_raw as Node3D
			var st = get_fog_state(cell)
			b_node.visible = (st >= FogState.EXPLORED)
			if b_node.visible and b_node.get_child_count() > 0:
				var spr = b_node.get_child(0)
				if is_instance_valid(spr) and spr is Sprite3D:
					spr.modulate = Color(1.0, 1.0, 1.0, 1.0) if st == FogState.VISIBLE else Color(0.68, 0.68, 0.74, 1.0)

	# 7. Hide water and bridges in UNEXPLORED fog
	for wi in water_mesh_instances:
		if is_instance_valid(wi):
			var cell = wi.get_meta("cell", Vector2i(-1, -1))
			if cell != Vector2i(-1, -1):
				wi.visible = (get_fog_state(cell) >= FogState.EXPLORED)

	for bi in bridge_mesh_instances:
		if is_instance_valid(bi):
			var cell = bi.get_meta("cell", Vector2i(-1, -1))
			if cell != Vector2i(-1, -1):
				bi.visible = (get_fog_state(cell) >= FogState.EXPLORED)

func _reveal_circle(center: Vector2i, radius: int) -> void:
	var r2 = radius * radius
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy <= r2:
				var cx = center.x + dx
				var cy = center.y + dy
				if is_valid_cell(cx, cy):
					fog_grid[cx][cy] = FogState.VISIBLE

func _generate_terrain_types_and_heights() -> void:
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var n = noise.get_noise_2d(float(x * 2.8), float(y * 2.8))
			var tile = TileType.GRASS
			var h = 0.0 # Default Tier 1 Lowland

			# Discrete Stepped Diorama Elevations (HD-2D Stepped Terraces)
			match map_type:
				CivData.MapType.DESERT_OASIS:
					tile = TileType.SAND
					var dist_center = Vector2(x, y).distance_to(Vector2(MAP_WIDTH * 0.5, MAP_HEIGHT * 0.5))
					if dist_center < 4.8 + n * 1.8:
						tile = TileType.WATER
						h = -0.65
					elif dist_center < 7.2:
						tile = TileType.GRASS
						h = 0.0
					elif n > 0.32:
						h = 0.75 # Plateau dune
					else:
						h = 0.0

				CivData.MapType.RIVER_CROSSING:
					var river_y = MAP_HEIGHT * 0.5 + sin(x * 0.32) * 2.6 + n * 1.5
					if abs(y - river_y) < 2.0:
						if abs(x - 7) <= 1 or abs(x - 15) <= 1 or abs(x - 23) <= 1:
							tile = TileType.SHALLOW_WATER
							h = -0.15
						else:
							tile = TileType.WATER
							h = -0.65
					elif n > 0.28:
						tile = TileType.DIRT
						h = 0.75 # Stepped hill tier
					else:
						tile = TileType.GRASS
						h = 0.0

				CivData.MapType.HIGHLAND_PLAINS:
					if n > 0.45:
						tile = TileType.ROCK
						h = 1.50 # Tier 3 Peak
					elif n > 0.15:
						tile = TileType.DIRT
						h = 0.75 # Tier 2 Plateau
					else:
						tile = TileType.GRASS
						h = 0.0

				CivData.MapType.GOLD_RUSH:
					if n < -0.38:
						tile = TileType.WATER
						h = -0.65
					elif n > 0.25:
						tile = TileType.DIRT
						h = 0.75
					else:
						tile = TileType.GRASS
						h = 0.0

				CivData.MapType.FOREST_VALLEY:
					if n < -0.38:
						tile = TileType.WATER
						h = -0.65
					elif n > 0.30:
						tile = TileType.DIRT
						h = 0.75 # Stepped Forest Plateau
					else:
						tile = TileType.GRASS
						h = 0.0

			tiles[x][y] = tile
			height_map[x][y] = h

func _clear_area(center: Vector2i, radius: int) -> void:
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			if is_valid_cell(x, y):
				if tiles[x][y] == TileType.WATER:
					tiles[x][y] = TileType.GRASS if map_type != CivData.MapType.DESERT_OASIS else TileType.SAND
				height_map[x][y] = 0.0 # Clean flat diorama building terrace

func _create_natural_organic_terrain() -> void:
	# Build Stepped HD-2D Diorama Terrain (Top faces, Stepped Cliff drops, and Diorama Base Skirting)
	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_texture = PixelArtTextures.get_diorama_grass_texture()
	grass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	grass_mat.roughness = 0.85

	var cliff_mat = StandardMaterial3D.new()
	cliff_mat.albedo_texture = PixelArtTextures.get_stepped_cliff_texture()
	cliff_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cliff_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cliff_mat.roughness = 0.70

	var wood_base_mat = StandardMaterial3D.new()
	wood_base_mat.albedo_texture = PixelArtTextures.get_diorama_wood_base_texture()
	wood_base_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	wood_base_mat.roughness = 0.40
	wood_base_mat.metallic = 0.15

	var sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.85, 0.75, 0.48)
	sand_mat.roughness = 0.85

	# 1. Top Plateau Faces
	var st_top = SurfaceTool.new()
	st_top.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var h = height_map[x][y]
			var x0 = x * TILE_SIZE
			var x1 = (x + 1) * TILE_SIZE
			var z0 = y * TILE_SIZE
			var z1 = (y + 1) * TILE_SIZE

			var p0 = Vector3(x0, h, z0)
			var p1 = Vector3(x1, h, z0)
			var p2 = Vector3(x1, h, z1)
			var p3 = Vector3(x0, h, z1)

			st_top.set_normal(Vector3(0, 1, 0))
			st_top.set_uv(Vector2(0, 0))
			st_top.add_vertex(p0)
			st_top.set_uv(Vector2(1, 0))
			st_top.add_vertex(p1)
			st_top.set_uv(Vector2(1, 1))
			st_top.add_vertex(p2)

			st_top.set_uv(Vector2(0, 0))
			st_top.add_vertex(p0)
			st_top.set_uv(Vector2(1, 1))
			st_top.add_vertex(p2)
			st_top.set_uv(Vector2(0, 1))
			st_top.add_vertex(p3)

	var top_mesh = st_top.commit()
	var top_inst = MeshInstance3D.new()
	top_inst.mesh = top_mesh
	top_inst.material_override = grass_mat if map_type != CivData.MapType.DESERT_OASIS else sand_mat
	ground_container.add_child(top_inst)

	# 2. Vertical Stepped Cliff Quads between elevation tiers
	var st_cliffs = SurfaceTool.new()
	st_cliffs.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var h = height_map[x][y]
			var x0 = x * TILE_SIZE
			var x1 = (x + 1) * TILE_SIZE
			var z0 = y * TILE_SIZE
			var z1 = (y + 1) * TILE_SIZE

			# Check +X neighbor
			if x + 1 < MAP_WIDTH and h > height_map[x + 1][y]:
				var nh = height_map[x + 1][y]
				st_cliffs.set_normal(Vector3(1, 0, 0))
				st_cliffs.set_uv(Vector2(0, 0)); st_cliffs.add_vertex(Vector3(x1, h, z0))
				st_cliffs.set_uv(Vector2(1, 0)); st_cliffs.add_vertex(Vector3(x1, h, z1))
				st_cliffs.set_uv(Vector2(1, 1)); st_cliffs.add_vertex(Vector3(x1, nh, z1))
				st_cliffs.set_uv(Vector2(0, 0)); st_cliffs.add_vertex(Vector3(x1, h, z0))
				st_cliffs.set_uv(Vector2(1, 1)); st_cliffs.add_vertex(Vector3(x1, nh, z1))
				st_cliffs.set_uv(Vector2(0, 1)); st_cliffs.add_vertex(Vector3(x1, nh, z0))

			# Check -X neighbor
			if x - 1 >= 0 and h > height_map[x - 1][y]:
				var nh = height_map[x - 1][y]
				st_cliffs.set_normal(Vector3(-1, 0, 0))
				st_cliffs.set_uv(Vector2(0, 0)); st_cliffs.add_vertex(Vector3(x0, h, z1))
				st_cliffs.set_uv(Vector2(1, 0)); st_cliffs.add_vertex(Vector3(x0, h, z0))
				st_cliffs.set_uv(Vector2(1, 1)); st_cliffs.add_vertex(Vector3(x0, nh, z0))
				st_cliffs.set_uv(Vector2(0, 0)); st_cliffs.add_vertex(Vector3(x0, h, z1))
				st_cliffs.set_uv(Vector2(1, 1)); st_cliffs.add_vertex(Vector3(x0, nh, z0))
				st_cliffs.set_uv(Vector2(0, 1)); st_cliffs.add_vertex(Vector3(x0, nh, z1))

			# Check +Z neighbor
			if y + 1 < MAP_HEIGHT and h > height_map[x][y + 1]:
				var nh = height_map[x][y + 1]
				st_cliffs.set_normal(Vector3(0, 0, 1))
				st_cliffs.set_uv(Vector2(0, 0)); st_cliffs.add_vertex(Vector3(x1, h, z1))
				st_cliffs.set_uv(Vector2(1, 0)); st_cliffs.add_vertex(Vector3(x0, h, z1))
				st_cliffs.set_uv(Vector2(1, 1)); st_cliffs.add_vertex(Vector3(x0, nh, z1))
				st_cliffs.set_uv(Vector2(0, 0)); st_cliffs.add_vertex(Vector3(x1, h, z1))
				st_cliffs.set_uv(Vector2(1, 1)); st_cliffs.add_vertex(Vector3(x0, nh, z1))
				st_cliffs.set_uv(Vector2(0, 1)); st_cliffs.add_vertex(Vector3(x1, nh, z1))

			# Check -Z neighbor
			if y - 1 >= 0 and h > height_map[x][y - 1]:
				var nh = height_map[x][y - 1]
				st_cliffs.set_normal(Vector3(0, 0, -1))
				st_cliffs.set_uv(Vector2(0, 0)); st_cliffs.add_vertex(Vector3(x0, h, z0))
				st_cliffs.set_uv(Vector2(1, 0)); st_cliffs.add_vertex(Vector3(x1, h, z0))
				st_cliffs.set_uv(Vector2(1, 1)); st_cliffs.add_vertex(Vector3(x1, nh, z0))
				st_cliffs.set_uv(Vector2(0, 0)); st_cliffs.add_vertex(Vector3(x0, h, z0))
				st_cliffs.set_uv(Vector2(1, 1)); st_cliffs.add_vertex(Vector3(x1, nh, z0))
				st_cliffs.set_uv(Vector2(0, 1)); st_cliffs.add_vertex(Vector3(x0, nh, z0))

	var cliff_mesh = st_cliffs.commit()
	var cliff_inst = MeshInstance3D.new()
	cliff_inst.mesh = cliff_mesh
	cliff_inst.material_override = cliff_mat
	ground_container.add_child(cliff_inst)

	# 3. Outer Diorama Perimeter Skirting Slab (Handcrafted Tabletop Model Box Frame)
	var st_skirt = SurfaceTool.new()
	st_skirt.begin(Mesh.PRIMITIVE_TRIANGLES)
	var skirt_bottom_y = -2.5

	# -X Edge
	for y in range(MAP_HEIGHT):
		var h = height_map[0][y]
		var z0 = y * TILE_SIZE
		var z1 = (y + 1) * TILE_SIZE
		st_skirt.set_normal(Vector3(-1, 0, 0))
		st_skirt.set_uv(Vector2(0, 0)); st_skirt.add_vertex(Vector3(0, h, z1))
		st_skirt.set_uv(Vector2(1, 0)); st_skirt.add_vertex(Vector3(0, h, z0))
		st_skirt.set_uv(Vector2(1, 1)); st_skirt.add_vertex(Vector3(0, skirt_bottom_y, z0))
		st_skirt.set_uv(Vector2(0, 0)); st_skirt.add_vertex(Vector3(0, h, z1))
		st_skirt.set_uv(Vector2(1, 1)); st_skirt.add_vertex(Vector3(0, skirt_bottom_y, z0))
		st_skirt.set_uv(Vector2(0, 1)); st_skirt.add_vertex(Vector3(0, skirt_bottom_y, z1))

	# +X Edge
	var max_x_pos = MAP_WIDTH * TILE_SIZE
	for y in range(MAP_HEIGHT):
		var h = height_map[MAP_WIDTH - 1][y]
		var z0 = y * TILE_SIZE
		var z1 = (y + 1) * TILE_SIZE
		st_skirt.set_normal(Vector3(1, 0, 0))
		st_skirt.set_uv(Vector2(0, 0)); st_skirt.add_vertex(Vector3(max_x_pos, h, z0))
		st_skirt.set_uv(Vector2(1, 0)); st_skirt.add_vertex(Vector3(max_x_pos, h, z1))
		st_skirt.set_uv(Vector2(1, 1)); st_skirt.add_vertex(Vector3(max_x_pos, skirt_bottom_y, z1))
		st_skirt.set_uv(Vector2(0, 0)); st_skirt.add_vertex(Vector3(max_x_pos, h, z0))
		st_skirt.set_uv(Vector2(1, 1)); st_skirt.add_vertex(Vector3(max_x_pos, skirt_bottom_y, z1))
		st_skirt.set_uv(Vector2(0, 1)); st_skirt.add_vertex(Vector3(max_x_pos, skirt_bottom_y, z0))

	# -Z Edge
	for x in range(MAP_WIDTH):
		var h = height_map[x][0]
		var x0 = x * TILE_SIZE
		var x1 = (x + 1) * TILE_SIZE
		st_skirt.set_normal(Vector3(0, 0, -1))
		st_skirt.set_uv(Vector2(0, 0)); st_skirt.add_vertex(Vector3(x0, h, 0))
		st_skirt.set_uv(Vector2(1, 0)); st_skirt.add_vertex(Vector3(x1, h, 0))
		st_skirt.set_uv(Vector2(1, 1)); st_skirt.add_vertex(Vector3(x1, skirt_bottom_y, 0))
		st_skirt.set_uv(Vector2(0, 0)); st_skirt.add_vertex(Vector3(x0, h, 0))
		st_skirt.set_uv(Vector2(1, 1)); st_skirt.add_vertex(Vector3(x1, skirt_bottom_y, 0))
		st_skirt.set_uv(Vector2(0, 1)); st_skirt.add_vertex(Vector3(x0, skirt_bottom_y, 0))

	# +Z Edge
	var max_z_pos = MAP_HEIGHT * TILE_SIZE
	for x in range(MAP_WIDTH):
		var h = height_map[x][MAP_HEIGHT - 1]
		var x0 = x * TILE_SIZE
		var x1 = (x + 1) * TILE_SIZE
		st_skirt.set_normal(Vector3(0, 0, 1))
		st_skirt.set_uv(Vector2(0, 0)); st_skirt.add_vertex(Vector3(x1, h, max_z_pos))
		st_skirt.set_uv(Vector2(1, 0)); st_skirt.add_vertex(Vector3(x0, h, max_z_pos))
		st_skirt.set_uv(Vector2(1, 1)); st_skirt.add_vertex(Vector3(x0, skirt_bottom_y, max_z_pos))
		st_skirt.set_uv(Vector2(0, 0)); st_skirt.add_vertex(Vector3(x1, h, max_z_pos))
		st_skirt.set_uv(Vector2(1, 1)); st_skirt.add_vertex(Vector3(x0, skirt_bottom_y, max_z_pos))
		st_skirt.set_uv(Vector2(0, 1)); st_skirt.add_vertex(Vector3(x1, skirt_bottom_y, max_z_pos))

	var skirt_mesh = st_skirt.commit()
	var skirt_inst = MeshInstance3D.new()
	skirt_inst.mesh = skirt_mesh
	skirt_inst.material_override = wood_base_mat
	ground_container.add_child(skirt_inst)

	# 3b. Outer Tabletop Diorama Base Board (Eliminates background void forever)
	var table_mesh = BoxMesh.new()
	table_mesh.size = Vector3(MAP_WIDTH * TILE_SIZE + 60.0, 1.0, MAP_HEIGHT * TILE_SIZE + 80.0)
	var table_inst = MeshInstance3D.new()
	table_inst.mesh = table_mesh
	table_inst.position = Vector3((MAP_WIDTH * TILE_SIZE) * 0.5, -2.8, (MAP_HEIGHT * TILE_SIZE) * 0.5 + 5.0)
	table_inst.material_override = wood_base_mat
	ground_container.add_child(table_inst)

	# 4. Animated Water Surfaces for Water Cells
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.14, 0.45, 0.72, 0.85)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.roughness = 0.10
	water_mat.metallic = 0.30

	var w_mesh = PlaneMesh.new()
	w_mesh.size = Vector2(TILE_SIZE * 1.02, TILE_SIZE * 1.02)

	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			if tiles[x][y] == TileType.WATER:
				var wi = MeshInstance3D.new()
				wi.mesh = w_mesh
				wi.position = Vector3(x * TILE_SIZE + TILE_SIZE * 0.5, -0.35, y * TILE_SIZE + TILE_SIZE * 0.5)
				wi.material_override = water_mat
				wi.set_meta("cell", Vector2i(x, y))
				ground_container.add_child(wi)
				water_mesh_instances.append(wi)
			elif tiles[x][y] == TileType.SHALLOW_WATER:
				_spawn_wooden_bridge(Vector2i(x, y))

func _spawn_wooden_bridge(cell: Vector2i) -> void:
	var bridge = Node3D.new()
	bridge.position = cell_to_world(cell) + Vector3(0, -0.1, 0)
	bridge.set_meta("cell", cell)
	var plank_mat = StandardMaterial3D.new()
	plank_mat.albedo_color = Color(0.42, 0.28, 0.16)
	plank_mat.roughness = 0.85

	for i in range(-2, 3):
		var plank = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(TILE_SIZE * 0.9, 0.12, 0.32)
		plank.mesh = p_mesh
		plank.position = Vector3(0, 0, i * 0.38)
		plank.material_override = plank_mat
		bridge.add_child(plank)

	ground_container.add_child(bridge)
	bridge_mesh_instances.append(bridge)

func _generate_3d_resources() -> void:
	var cfg = CivData.get_map_config(map_type)
	var tree_density = cfg.get("tree_density", 0.25)

	_spawn_base_cluster(world_to_cell(player_start_pos))
	_spawn_base_cluster(world_to_cell(enemy_start_pos))

	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var cell = Vector2i(x, y)
			if not is_cell_passable_terrain(x, y):
				continue
			if cell in trees or cell in gold_mines or cell in berry_bushes:
				continue
			if cell.distance_to(world_to_cell(player_start_pos)) < 4 or cell.distance_to(world_to_cell(enemy_start_pos)) < 4:
				continue

			var tree_noise = noise.get_noise_2d(float(x * 6.0 + 80), float(y * 6.0 + 80))
			var should_spawn = false
			if map_type == CivData.MapType.FOREST_VALLEY:
				var dist_cx = abs(x - MAP_WIDTH * 0.5)
				should_spawn = (dist_cx > 4.5 and tree_noise > -0.12) or tree_noise > 0.30
			elif map_type == CivData.MapType.DESERT_OASIS:
				var dist_center = Vector2(x, y).distance_to(Vector2(MAP_WIDTH * 0.5, MAP_HEIGHT * 0.5))
				should_spawn = dist_center >= 5.0 and dist_center <= 8.5 and randf() < 0.4
			else:
				should_spawn = tree_noise > (0.46 - tree_density)

			if should_spawn:
				_spawn_3d_tree(cell)

	var total_gold = cfg.get("gold_nodes", 7)
	for i in range(total_gold):
		var spot = _find_random_empty_spot(Vector2i(3, 8), Vector2i(MAP_WIDTH - 4, MAP_HEIGHT - 9))
		if spot != Vector2i(-1, -1):
			_spawn_resource_cluster(spot, "gold", randi_range(2, 3))

	var total_stone = cfg.get("stone_nodes", 6)
	for i in range(total_stone):
		var spot = _find_random_empty_spot(Vector2i(3, 8), Vector2i(MAP_WIDTH - 4, MAP_HEIGHT - 9))
		if spot != Vector2i(-1, -1):
			_spawn_resource_cluster(spot, "stone", randi_range(2, 3))

	var total_food = cfg.get("food_nodes", 7)
	for i in range(total_food):
		var spot = _find_random_empty_spot(Vector2i(3, 8), Vector2i(MAP_WIDTH - 4, MAP_HEIGHT - 9))
		if spot != Vector2i(-1, -1):
			_spawn_resource_cluster(spot, "food", randi_range(2, 3))

func _spawn_base_cluster(center: Vector2i) -> void:
	var dir_y = 1 if center.y > int(MAP_HEIGHT * 0.5) else -1
	# Place base resources to the flanks and rear, preserving a clear front courtyard
	_spawn_resource_cluster(center + Vector2i(-5, 0), "gold", 3)
	_spawn_resource_cluster(center + Vector2i(-6, 3 * dir_y), "stone", 3)
	_spawn_resource_cluster(center + Vector2i(5, 0), "food", 3)

	# Woodline grove to the rear and side, keeping a 4-tile front clearance
	for dx in range(-4, 5):
		for dy in [2, 3]:
			if abs(dx) <= 2 and dy == 2:
				continue # Keep direct doorway clear
			var c = center + Vector2i(dx, dy * dir_y)
			if is_valid_cell(c.x, c.y) and is_cell_passable_terrain(c.x, c.y):
				_spawn_3d_tree(c)

func _spawn_resource_cluster(origin: Vector2i, type: String, count: int) -> void:
	var placed = 0
	var queue = [origin]
	var visited = {}

	while queue.size() > 0 and placed < count:
		var curr = queue.pop_front()
		if not is_valid_cell(curr.x, curr.y) or curr in visited:
			continue
		visited[curr] = true

		if is_cell_passable_terrain(curr.x, curr.y) and not (curr in trees or curr in gold_mines or curr in stone_mines or curr in berry_bushes):
			if type == "gold":
				_spawn_3d_gold(curr)
			elif type == "stone":
				_spawn_3d_stone(curr)
			elif type == "food":
				_spawn_3d_berry(curr)
			placed += 1

		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			queue.append(curr + dir)

var model_cache: Dictionary = {}

func _get_nature_model(rel_path: String) -> Node3D:
	if model_cache.has(rel_path):
		var cached = model_cache[rel_path] as Node3D
		if is_instance_valid(cached):
			return cached.duplicate()
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	var full_p = ProjectSettings.globalize_path(rel_path)
	if doc.append_from_file(full_p, state) == OK:
		var scene = doc.generate_scene(state)
		if scene != null:
			model_cache[rel_path] = scene
			return scene.duplicate()
	return null

func _create_resource_area(node: Node3D, cell: Vector2i, type: String, radius: float, height: float, y_offset: float) -> Area3D:
	var area = Area3D.new()
	area.name = "SelectionArea"
	area.collision_layer = 4 # Layer 3 (bitmask 4) - dedicated Resource layer
	area.collision_mask = 0
	area.set_meta("res_type", type)
	area.set_meta("resource_type", type)
	area.set_meta("res_cell", cell)
	area.set_meta("cell", cell)

	var shape = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	shape.position = Vector3(0, y_offset, 0)
	area.add_child(shape)
	node.add_child(area)
	return area

func _spawn_3d_tree(cell: Vector2i) -> void:
	var tree_node = Node3D.new()
	var ground_y = height_map[cell.x][cell.y]
	tree_node.position = cell_to_world(cell) + Vector3(0, ground_y, 0)

	var is_pine = (randf() < 0.45)
	var spr = Sprite3D.new()
	spr.texture = PixelArtTextures.get_pine_tree_texture() if is_pine else PixelArtTextures.get_oak_tree_texture()
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.shaded = true
	spr.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	spr.pixel_size = 0.055
	spr.position = Vector3(0, 1.7, 0)
	tree_node.add_child(spr)

	_create_resource_area(tree_node, cell, "wood", 0.95, 3.6, 1.8)
	tree_node.visible = false

	props_container.add_child(tree_node)
	trees[cell] = {
		"node": tree_node,
		"hp": 100,
		"max_amount": 100,
		"name": "Çam Ağacı" if is_pine else "Meşe Ağacı",
		"type": "wood"
	}

func _spawn_3d_gold(cell: Vector2i) -> void:
	var gold_node = Node3D.new()
	var ground_y = height_map[cell.x][cell.y]
	gold_node.position = cell_to_world(cell) + Vector3(0, ground_y, 0)

	var spr = Sprite3D.new()
	spr.texture = PixelArtTextures.get_gold_node_texture()
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.shaded = true
	spr.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	spr.pixel_size = 0.055
	spr.position = Vector3(0, 0.95, 0)
	gold_node.add_child(spr)

	_create_resource_area(gold_node, cell, "gold", 0.90, 1.8, 0.9)
	gold_node.visible = false

	props_container.add_child(gold_node)
	gold_mines[cell] = {
		"node": gold_node,
		"gold": 800,
		"max_amount": 800,
		"name": "Altın Madeni",
		"type": "gold"
	}

func _spawn_3d_stone(cell: Vector2i) -> void:
	var stone_node = Node3D.new()
	var ground_y = height_map[cell.x][cell.y]
	stone_node.position = cell_to_world(cell) + Vector3(0, ground_y, 0)

	var spr = Sprite3D.new()
	spr.texture = PixelArtTextures.get_stone_node_texture()
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.shaded = true
	spr.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	spr.pixel_size = 0.055
	spr.position = Vector3(0, 0.95, 0)
	stone_node.add_child(spr)

	_create_resource_area(stone_node, cell, "stone", 0.90, 1.8, 0.9)
	stone_node.visible = false

	props_container.add_child(stone_node)
	stone_mines[cell] = {
		"node": stone_node,
		"stone": 750,
		"max_amount": 750,
		"name": "Taş Ocağı",
		"type": "stone"
	}

func _spawn_3d_berry(cell: Vector2i) -> void:
	var berry_node = Node3D.new()
	var ground_y = height_map[cell.x][cell.y]
	berry_node.position = cell_to_world(cell) + Vector3(0, ground_y, 0)

	var spr = Sprite3D.new()
	spr.texture = PixelArtTextures.get_berry_bush_texture()
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.shaded = true
	spr.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	spr.pixel_size = 0.055
	spr.position = Vector3(0, 0.95, 0)
	berry_node.add_child(spr)

	_create_resource_area(berry_node, cell, "food", 0.85, 1.6, 0.8)
	berry_node.visible = false

	props_container.add_child(berry_node)
	berry_bushes[cell] = {
		"node": berry_node,
		"food": 500,
		"max_amount": 500,
		"name": "Böğürtlen Çalısı",
		"type": "food"
	}

func _find_random_empty_spot(min_b: Vector2i, max_b: Vector2i) -> Vector2i:
	for attempt in range(40):
		var rx = randi_range(min_b.x, max_b.x)
		var ry = randi_range(min_b.y, max_b.y)
		var c = Vector2i(rx, ry)
		if is_cell_passable_terrain(rx, ry) and not (c in trees or c in gold_mines or c in stone_mines or c in berry_bushes):
			return c
	return Vector2i(-1, -1)

func _build_astar_grid() -> void:
	astar.clear()
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var id = _cell_to_id(x, y)
			astar.add_point(id, Vector2(x, y))
			astar.set_point_disabled(id, not is_cell_walkable(Vector2i(x, y)))

	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var id1 = _cell_to_id(x, y)
			if x + 1 < MAP_WIDTH:
				astar.connect_points(id1, _cell_to_id(x + 1, y))
			if y + 1 < MAP_HEIGHT:
				astar.connect_points(id1, _cell_to_id(x, y + 1))
			if x + 1 < MAP_WIDTH and y + 1 < MAP_HEIGHT:
				astar.connect_points(id1, _cell_to_id(x + 1, y + 1))
			if x - 1 >= 0 and y + 1 < MAP_HEIGHT:
				astar.connect_points(id1, _cell_to_id(x - 1, y + 1))

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
	if cell in trees or cell in gold_mines or cell in stone_mines or cell in occupied_cells:
		return false
	return true

func update_cell_walkability(cell: Vector2i) -> void:
	if is_valid_cell(cell.x, cell.y):
		var id = _cell_to_id(cell.x, cell.y)
		astar.set_point_disabled(id, not is_cell_walkable(cell))

func world_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(int(pos.x / TILE_SIZE), int(pos.z / TILE_SIZE))

func cell_to_world(cell: Vector2i) -> Vector3:
	var h = 0.0
	if is_valid_cell(cell.x, cell.y) and height_map.size() > cell.x:
		h = height_map[cell.x][cell.y]
	return Vector3(cell.x * TILE_SIZE + TILE_SIZE * 0.5, h, cell.y * TILE_SIZE + TILE_SIZE * 0.5)

func get_path_to_target(from_world: Vector3, to_world: Vector3) -> Array[Vector3]:
	var from_cell = world_to_cell(from_world)
	var to_cell = world_to_cell(to_world)

	from_cell.x = clamp(from_cell.x, 0, MAP_WIDTH - 1)
	from_cell.y = clamp(from_cell.y, 0, MAP_HEIGHT - 1)
	to_cell.x = clamp(to_cell.x, 0, MAP_WIDTH - 1)
	to_cell.y = clamp(to_cell.y, 0, MAP_HEIGHT - 1)

	var from_id = _cell_to_id(from_cell.x, from_cell.y)
	var to_id = _cell_to_id(to_cell.x, to_cell.y)

	if astar.is_point_disabled(to_id):
		var best_dist = 999999.0
		var best_id = -1
		for r in range(1, 6):
			for dx in range(-r, r + 1):
				for dy in range(-r, r + 1):
					if abs(dx) != r and abs(dy) != r:
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
				break
		if best_id != -1:
			to_id = best_id

	if astar.is_point_disabled(from_id):
		var best_id = -1
		var best_dist = 999999.0
		for r in range(1, 6):
			for dx in range(-r, r + 1):
				for dy in range(-r, r + 1):
					if abs(dx) != r and abs(dy) != r:
						continue
					var nc = from_cell + Vector2i(dx, dy)
					if is_valid_cell(nc.x, nc.y):
						var nid = _cell_to_id(nc.x, nc.y)
						if not astar.is_point_disabled(nid):
							var d = nc.distance_squared_to(to_cell)
							if d < best_dist:
								best_dist = d
								best_id = nid
			if best_id != -1:
				break
		if best_id != -1:
			from_id = best_id

	var pts2d = astar.get_point_path(from_id, to_id)
	var pts3d: Array[Vector3] = []
	for p in pts2d:
		pts3d.append(cell_to_world(Vector2i(int(p.x), int(p.y))))
	return pts3d

func harvest_tree(cell: Vector2i, amount: int) -> int:
	if not cell in trees:
		return 0
	var t = trees[cell]
	var cur = t.get("hp", t.get("amount", 100))
	var harvested = min(amount, cur)
	cur -= harvested
	t["hp"] = cur
	t["amount"] = cur
	if cur <= 0:
		if is_instance_valid(t.get("node", null)):
			t["node"].queue_free()
		trees.erase(cell)
		update_cell_walkability(cell)
	return harvested

func harvest_gold(cell: Vector2i, amount: int) -> int:
	if not cell in gold_mines:
		return 0
	var g = gold_mines[cell]
	var cur = g.get("gold", g.get("amount", 800))
	var harvested = min(amount, cur)
	cur -= harvested
	g["gold"] = cur
	g["amount"] = cur
	if cur <= 0:
		if is_instance_valid(g.get("node", null)):
			g["node"].queue_free()
		gold_mines.erase(cell)
		update_cell_walkability(cell)
	return harvested

func harvest_stone(cell: Vector2i, amount: int) -> int:
	if not cell in stone_mines:
		return 0
	var s = stone_mines[cell]
	var cur = s.get("stone", s.get("amount", 800))
	var harvested = min(amount, cur)
	cur -= harvested
	s["stone"] = cur
	s["amount"] = cur
	if cur <= 0:
		if is_instance_valid(s.get("node", null)):
			s["node"].queue_free()
		stone_mines.erase(cell)
		update_cell_walkability(cell)
	return harvested

func harvest_food(cell: Vector2i, amount: int) -> int:
	if not cell in berry_bushes:
		return 0
	var b = berry_bushes[cell]
	var cur = b.get("food", b.get("amount", 100))
	var harvested = min(amount, cur)
	cur -= harvested
	b["food"] = cur
	b["amount"] = cur
	if cur <= 0:
		if is_instance_valid(b.get("node", null)):
			b["node"].queue_free()
		berry_bushes.erase(cell)
	return harvested

func register_building_cells(origin_cell: Vector2i, size: Vector2i, building_node: Node3D) -> void:
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

func get_resource_at_cell(cell: Vector2i, type: String = "") -> Dictionary:
	if (type == "wood" or type == "") and cell in trees:
		var t = trees[cell]
		return {
			"cell": cell,
			"type": "wood",
			"name": t.get("name", "Meşe Ağacı"),
			"amount": t.get("hp", 0),
			"max_amount": t.get("max_amount", 100),
			"node": t.get("node", null)
		}
	elif (type == "gold" or type == "") and cell in gold_mines:
		var g = gold_mines[cell]
		return {
			"cell": cell,
			"type": "gold",
			"name": g.get("name", "Altın Madeni"),
			"amount": g.get("gold", 0),
			"max_amount": g.get("max_amount", 800),
			"node": g.get("node", null)
		}
	elif (type == "stone" or type == "") and cell in stone_mines:
		var s = stone_mines[cell]
		return {
			"cell": cell,
			"type": "stone",
			"name": s.get("name", "Taş Ocağı"),
			"amount": s.get("stone", 0),
			"max_amount": s.get("max_amount", 750),
			"node": s.get("node", null)
		}
	elif (type == "food" or type == "") and cell in berry_bushes:
		var b = berry_bushes[cell]
		return {
			"cell": cell,
			"type": "food",
			"name": b.get("name", "Böğürtlen Çalısı"),
			"amount": b.get("food", 0),
			"max_amount": b.get("max_amount", 500),
			"node": b.get("node", null)
		}
	return {}

func find_nearest_resource_node(from_pos: Vector3, type: String, max_world_distance: float) -> Vector2i:
	var dict: Dictionary = {}
	match type:
		"wood": dict = trees
		"gold": dict = gold_mines
		"stone": dict = stone_mines
		"food": dict = berry_bushes

	var best_cell = Vector2i(-1, -1)
	var min_dist_sq = max_world_distance * max_world_distance
	for cell in dict.keys():
		var node_info = dict[cell]
		var amt = node_info.get("hp", node_info.get("gold", node_info.get("stone", node_info.get("food", 0))))
		if amt <= 0:
			continue
		var w_pos = cell_to_world(cell)
		var d_sq = from_pos.distance_squared_to(w_pos)
		if d_sq < min_dist_sq:
			min_dist_sq = d_sq
			best_cell = cell
	return best_cell
