class_name MapGenerator3D
extends Node3D

const PixelArtTextures = preload("res://scripts/PixelArtTextures.gd")

signal map_generated

const TILE_SIZE: float = 2.0
## Map size (picked on the new-game screen). Small is the original 32x60 map every mobile test ran on.
enum MapSize { SMALL, MEDIUM, LARGE }
const MAP_SIZE_DIMS: Array[Vector2i] = [Vector2i(32, 60), Vector2i(48, 76), Vector2i(64, 96)]
const MAP_SIZE_MAX_BOTS: Array[int] = [1, 3, 5]
const MAP_SIZE_NAMES: Array[String] = ["Küçük", "Orta", "Büyük"]
## Instance values (set by set_map_size before generate); read them from the generator, not the class.
var MAP_WIDTH: int = 32
var MAP_HEIGHT: int = 60
var map_size: int = MapSize.SMALL

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
var height_map: Array = [] # 2D array [x][y] of float heights: the terrain surface at each cell centre

## Continuous terrain surface (natural rolling hills, no stepped terraces). The tier logic in
## _generate_terrain_types_and_heights gives each cell a target level; _build_height_grid blurs those
## levels into a vertex grid (SUB vertices per cell edge) that the ground mesh is built from, and
## get_height_at() samples the SAME triangles, so units, buildings, trees and grass sit exactly on
## the visible ground.
const SUB: int = 2                   # height-grid vertices per cell edge -> 1 m spacing
const HILL_H: float = 2.2            # hill / plateau level
const PEAK_H: float = 4.4            # highland rock peaks
const WATER_H: float = -0.65         # lake / river bed
const SHALLOW_H: float = -0.2        # ford
const WATER_SURFACE_Y: float = -0.3
const BLUR_SIGMA: float = 0.95       # in cells: how wide the slopes are
const ROLL_AMPLITUDE: float = 0.22   # gentle undulation of the open ground (not in the bases)
const BASE_FLAT_R: float = 7.5       # cells around each Town Center kept level
## Max height difference inside a building footprint: buildings go on level ground, not on slopes.
const MAX_BUILD_RISE: float = 0.8
var hgrid := PackedFloat32Array()
var hgrid_w: int = 0
var hgrid_h: int = 0
var max_terrain_h: float = 0.0
var astar: AStar2D = AStar2D.new()

var trees: Dictionary = {} # Vector2i -> Node3D
var gold_mines: Dictionary = {} # Vector2i -> Node3D
var stone_mines: Dictionary = {} # Vector2i -> Node3D
var berry_bushes: Dictionary = {} # Vector2i -> Node3D
## Resource cells a unit could not get within gathering range of (boxed in by terrain/trees).
## Skipped by auto-retargeting and the bot; cleared whenever walkability changes (a tree is cut,
## a building is placed/destroyed), so a node that becomes reachable is used again.
var unreachable_resource_cells: Dictionary = {}
var occupied_cells: Dictionary = {}
## Farm fields (Building3D FARM placed from a Mill). Fields are WALKABLE but not buildable, so a
## ring of fields never walls a Mill in. field_cells: any covered cell -> field origin cell.
## farm_fields: origin -> {"building", "team", "farmer"} once the field is completed (infinite food).
var field_cells: Dictionary = {}
var farm_fields: Dictionary = {}
## field origin -> height of the field's top. A field is flat, so it sits on the HIGHEST ground under
## it (on the lowest it sank up to MAX_BUILD_RISE into a slope); get_height_at() returns this on its
## cells so units walk on the field, not inside it.
var field_tops: Dictionary = {}

var player_start_pos: Vector3
var enemy_start_pos: Vector3          # = start_positions[1] (the first bot)
## Town Center spot of every team: [0] = player (bottom centre), [1..] = bots around the map.
var start_positions: Array[Vector3] = []

var noise: FastNoiseLite = FastNoiseLite.new()
## Everything random in map generation (resource spots, cluster sizes, oasis palms, tree species,
## prop yaw/scale) draws from this generator, seeded from seed_val: the same seed always builds the
## same map, which is how a saved game gets its map back (SaveManager regenerates it from the seed).
var map_rng := RandomNumberGenerator.new()
var detail_noise: FastNoiseLite = FastNoiseLite.new()

@onready var ground_container: Node3D = $GroundContainer
@onready var props_container: Node3D = $PropsContainer

var water_mesh_instances: Array[MeshInstance3D] = []
var bridge_mesh_instances: Array[Node3D] = []
var gold_crystal_materials: Array[StandardMaterial3D] = []
var anim_time: float = 0.0
## HD-2D terrain material (shaders/hd2d_ground.gdshader); control texture set after A* is built.
var ground_mat: ShaderMaterial = null
## Ground scatter instances per cell (hidden when a building is placed on the cell).
var scatter_cell_index: Dictionary = {}

func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = 0.15

func _process(delta: float) -> void:
	anim_time += delta
	
	# 1. Subtle water surface ripples
	for w_inst in water_mesh_instances:
		if is_instance_valid(w_inst):
			w_inst.position.y = WATER_SURFACE_Y + sin(anim_time * 2.2) * 0.03
			
	# 2. Pulsing gold mine sparkles / gleam
	var gold_pulse = 0.35 + sin(anim_time * 4.0) * 0.25
	for g_mat in gold_crystal_materials:
		if is_instance_valid(g_mat):
			g_mat.emission_energy_multiplier = gold_pulse
			
	# 3. Gentle wind sway on trees (3D models only: a flat 2D sprite would just spin in place)
	if FactionArtManager.top_down():
		return
	for tree_data in trees.values():
		var t_node = tree_data.get("node") as Node3D
		if is_instance_valid(t_node):
			var sway = sin(anim_time * 2.6 + t_node.position.x * 0.8 + t_node.position.z * 0.4) * 0.045
			t_node.rotation.z = sway

func set_map_size(sz: int) -> void:
	map_size = clampi(sz, 0, MAP_SIZE_DIMS.size() - 1)
	MAP_WIDTH = MAP_SIZE_DIMS[map_size].x
	MAP_HEIGHT = MAP_SIZE_DIMS[map_size].y

static func max_bots_for(sz: int) -> int:
	return MAP_SIZE_MAX_BOTS[clampi(sz, 0, MAP_SIZE_MAX_BOTS.size() - 1)]

## Start cells: the player at the bottom centre; one bot = top centre (the original 1v1 layout);
## more bots are spread evenly on an ellipse round the map, so every base is ~25+ cells from the next.
func _start_cells(n_bots: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i(int(MAP_WIDTH * 0.5), MAP_HEIGHT - 12)]
	if n_bots <= 1:
		cells.append(Vector2i(int(MAP_WIDTH * 0.5), 10))
		return cells
	var top := 10.0
	var bottom := float(MAP_HEIGHT - 12)
	var cx := MAP_WIDTH * 0.5
	var cy := (top + bottom) * 0.5
	var rx := MAP_WIDTH * 0.5 - 9.0
	var ry := (bottom - top) * 0.5
	for i in n_bots:
		var a := PI * 0.5 + TAU * float(i + 1) / float(n_bots + 1)
		cells.append(Vector2i(roundi(cx + cos(a) * rx), roundi(cy + sin(a) * ry)))
	return cells

func get_start_pos(team: int) -> Vector3:
	return start_positions[team] if team >= 0 and team < start_positions.size() else enemy_start_pos

func _base_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for p in start_positions:
		out.append(world_to_cell(p))
	return out

func _near_any_base(c: Vector2i, r: float) -> bool:
	for p in start_positions:
		if c.distance_to(world_to_cell(p)) < r:
			return true
	return false

func generate(chosen_map_type: CivData.MapType, custom_seed: int = -1, n_bots: int = 1) -> void:
	map_type = chosen_map_type
	seed_val = custom_seed if custom_seed != -1 else randi()
	map_rng.seed = seed_val
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
	stone_mines.clear()      # was missing: a reload kept the old map's (invisible) stone mines
	berry_bushes.clear()
	unreachable_resource_cells.clear()
	occupied_cells.clear()
	field_cells.clear()
	farm_fields.clear()
	field_tops.clear()
	astar.clear()

	for x in range(MAP_WIDTH):
		var col_tiles = []
		col_tiles.resize(MAP_HEIGHT)
		tiles.append(col_tiles)
		var col_h = []
		col_h.resize(MAP_HEIGHT)
		height_map.append(col_h)

	_generate_terrain_types_and_heights()

	start_positions.clear()
	for c in _start_cells(n_bots):
		start_positions.append(cell_to_world(c))
		_clear_area(c, 7)
	player_start_pos = start_positions[0]
	enemy_start_pos = start_positions[1]
	_build_height_grid()
	for i in start_positions.size():
		start_positions[i] = cell_to_world(world_to_cell(start_positions[i]))
	player_start_pos = start_positions[0]
	enemy_start_pos = start_positions[1]

	# 1. Create Natural Organic Smooth Terrain Mesh
	_create_natural_organic_terrain()

	# 2. Create 3D Resources with Natural Props
	_generate_3d_resources()

	# 3. Build AStar Pathfinding
	_build_astar_grid()

	# 3b. HD-2D ground control map (roads follow A* routes, so it needs the grid)
	if ground_mat != null:
		var control_img := HD2DGround.build_control_image(self)
		ground_mat.set_shader_parameter("control", ImageTexture.create_from_image(control_img))
		# 3c. Ground scatter (tufts, flowers, pebbles) driven by the same control map
		var scatter := HD2DScatter.build(self, control_img)
		for n in scatter["nodes"]:
			ground_container.add_child(n)
		scatter_cell_index = scatter["cell_index"]

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

	# 7. Hide bridges in UNEXPLORED fog (the single water surface stays; the fog overlay covers it)
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
						h = WATER_H
					elif dist_center < 7.2:
						tile = TileType.GRASS
						h = 0.0
					elif n > 0.32:
						h = HILL_H # dune ridge
					else:
						h = 0.0

				CivData.MapType.RIVER_CROSSING:
					var river_y = MAP_HEIGHT * 0.5 + sin(x * 0.32) * 2.6 + n * 1.5
					if abs(y - river_y) < 2.0:
						if _is_ford_column(x):
							tile = TileType.SHALLOW_WATER
							h = SHALLOW_H
						else:
							tile = TileType.WATER
							h = WATER_H
					elif n > 0.28:
						tile = TileType.DIRT
						h = HILL_H # hill
					else:
						tile = TileType.GRASS
						h = 0.0

				CivData.MapType.HIGHLAND_PLAINS:
					if n > 0.45:
						tile = TileType.ROCK
						h = PEAK_H # rocky peak
					elif n > 0.15:
						tile = TileType.DIRT
						h = HILL_H # hill
					else:
						tile = TileType.GRASS
						h = 0.0

				CivData.MapType.GOLD_RUSH:
					if n < -0.38:
						tile = TileType.WATER
						h = WATER_H
					elif n > 0.25:
						tile = TileType.DIRT
						h = HILL_H
					else:
						tile = TileType.GRASS
						h = 0.0

				CivData.MapType.FOREST_VALLEY:
					if n < -0.38:
						tile = TileType.WATER
						h = WATER_H
					elif n > 0.30:
						tile = TileType.DIRT
						h = HILL_H # forested hill
					else:
						tile = TileType.GRASS
						h = 0.0

			tiles[x][y] = tile
			height_map[x][y] = h

## River Crossing fords: every 8 columns from x = 7, kept 8 columns off the east edge (32 wide: 7, 15, 23).
func _is_ford_column(x: int) -> bool:
	for fx in range(7, MAP_WIDTH - 8, 8):
		if abs(x - fx) <= 1:
			return true
	return false

func _clear_area(center: Vector2i, radius: int) -> void:
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			if is_valid_cell(x, y):
				# (fords too: with more bots a base can sit on the River Crossing river)
				if tiles[x][y] == TileType.WATER or tiles[x][y] == TileType.SHALLOW_WATER:
					tiles[x][y] = TileType.GRASS if map_type != CivData.MapType.DESERT_OASIS else TileType.SAND
				height_map[x][y] = 0.0 # Clean flat diorama building terrace

## Blurs the per-cell target levels (height_map, after the bases were flattened) into the vertex
## grid, keeps lake / river beds under the water surface and fords at ford level, adds a gentle
## roll to open ground, then stores the surface height at every cell centre back into height_map.
func _build_height_grid() -> void:
	# 1) separable gaussian blur of the cell levels (edge cells extended)
	var r := int(ceil(BLUR_SIGMA * 2.5))
	var kernel: Array[float] = []
	for k in range(-r, r + 1):
		kernel.append(exp(-float(k * k) / (2.0 * BLUR_SIGMA * BLUR_SIGMA)))
	# banks: land next to water is held low, so hills meet rivers and lakes with a slope, not a wall
	var level := PackedFloat32Array(); level.resize(MAP_WIDTH * MAP_HEIGHT)
	for y in MAP_HEIGHT:
		for x in MAP_WIDTH:
			var lv: float = height_map[x][y]
			if tiles[x][y] != TileType.WATER and tiles[x][y] != TileType.SHALLOW_WATER:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
					var nb: Vector2i = Vector2i(x, y) + d
					if is_valid_cell(nb.x, nb.y) and tiles[nb.x][nb.y] == TileType.WATER:
						lv = minf(lv, 0.2)
						break
			level[y * MAP_WIDTH + x] = lv
	var tmp := PackedFloat32Array(); tmp.resize(MAP_WIDTH * MAP_HEIGHT)
	var blurred := PackedFloat32Array(); blurred.resize(MAP_WIDTH * MAP_HEIGHT)
	for y in MAP_HEIGHT:
		for x in MAP_WIDTH:
			var sum := 0.0
			var wsum := 0.0
			for k in range(-r, r + 1):
				var w: float = kernel[k + r]
				sum += level[y * MAP_WIDTH + clampi(x + k, 0, MAP_WIDTH - 1)] * w
				wsum += w
			tmp[y * MAP_WIDTH + x] = sum / wsum
	for y in MAP_HEIGHT:
		for x in MAP_WIDTH:
			var sum := 0.0
			var wsum := 0.0
			for k in range(-r, r + 1):
				var w: float = kernel[k + r]
				sum += tmp[clampi(y + k, 0, MAP_HEIGHT - 1) * MAP_WIDTH + x] * w
				wsum += w
			blurred[y * MAP_WIDTH + x] = sum / wsum

	# 2) vertex grid: bilinear between blurred cell centres
	hgrid_w = MAP_WIDTH * SUB + 1
	hgrid_h = MAP_HEIGHT * SUB + 1
	hgrid.resize(hgrid_w * hgrid_h)
	var roll := FastNoiseLite.new()
	roll.seed = seed_val + 77
	roll.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	roll.frequency = 0.09
	var bases: Array[Vector2] = []
	for bc in _base_cells():
		bases.append(Vector2(bc) + Vector2(0.5, 0.5))
	max_terrain_h = 0.0
	for j in hgrid_h:
		for i in hgrid_w:
			var u := float(i) / SUB          # cell units
			var v := float(j) / SUB
			var fx := clampf(u - 0.5, 0.0, MAP_WIDTH - 1.0)
			var fz := clampf(v - 0.5, 0.0, MAP_HEIGHT - 1.0)
			var x0 := mini(int(fx), MAP_WIDTH - 2)
			var z0 := mini(int(fz), MAP_HEIGHT - 2)
			var tx := fx - x0
			var tz := fz - z0
			var h := lerpf(lerpf(blurred[z0 * MAP_WIDTH + x0], blurred[z0 * MAP_WIDTH + x0 + 1], tx),
				lerpf(blurred[(z0 + 1) * MAP_WIDTH + x0], blurred[(z0 + 1) * MAP_WIDTH + x0 + 1], tx), tz)
			# the cells touching this vertex (1 at a cell centre, 2 on an edge, 4 at a corner); under
			# water when at least half of them are water, so lake corners come out rounded
			var n_touch := 0
			var n_water := 0
			var ford := false
			var xs: Array = [int(floor(u))] if int(ceil(u)) - 1 == int(floor(u)) else [int(ceil(u)) - 1, int(floor(u))]
			var zs: Array = [int(floor(v))] if int(ceil(v)) - 1 == int(floor(v)) else [int(ceil(v)) - 1, int(floor(v))]
			for cx in xs:
				for cz in zs:
					if is_valid_cell(cx, cz):
						n_touch += 1
						if tiles[cx][cz] == TileType.WATER:
							n_water += 1
						elif tiles[cx][cz] == TileType.SHALLOW_WATER:
							ford = true
			var deep := n_water > 0 and n_water * 2 >= n_touch
			if deep:
				h = minf(h, WATER_SURFACE_Y - 0.2)       # under the water surface
			elif ford:
				h = SHALLOW_H
			else:
				# bases stay level ground (the blur would otherwise pull nearby hills into them)
				var base_d := INF
				for bp in bases:
					base_d = minf(base_d, Vector2(u, v).distance_to(bp))
				h *= smoothstep(BASE_FLAT_R, BASE_FLAT_R + 2.5, base_d)
				h += roll.get_noise_2d(u, v) * ROLL_AMPLITUDE * smoothstep(BASE_FLAT_R + 0.5, BASE_FLAT_R + 4.0, base_d)
				h = maxf(h, WATER_SURFACE_Y + 0.18)      # dry land stays above it (shore = sloping bank)
			hgrid[j * hgrid_w + i] = h
			max_terrain_h = maxf(max_terrain_h, h)

	# 3) cell centres = the surface there (exactly a grid vertex when SUB is even)
	for x in MAP_WIDTH:
		for y in MAP_HEIGHT:
			height_map[x][y] = get_height_at(Vector3((x + 0.5) * TILE_SIZE, 0, (y + 0.5) * TILE_SIZE))

func _gh(i: int, j: int) -> float:
	return hgrid[clampi(j, 0, hgrid_h - 1) * hgrid_w + clampi(i, 0, hgrid_w - 1)]

## Terrain surface height at a world position: the same two triangles per grid square as the mesh.
func get_height_at(pos: Vector3) -> float:
	if hgrid.is_empty():
		return 0.0
	var gx := clampf(pos.x / TILE_SIZE * SUB, 0.0, hgrid_w - 1.001)
	var gz := clampf(pos.z / TILE_SIZE * SUB, 0.0, hgrid_h - 1.001)
	var i := int(gx)
	var j := int(gz)
	var fx := gx - i
	var fz := gz - j
	var h00 := hgrid[j * hgrid_w + i]
	var h10 := hgrid[j * hgrid_w + i + 1]
	var h01 := hgrid[(j + 1) * hgrid_w + i]
	var h11 := hgrid[(j + 1) * hgrid_w + i + 1]
	var h: float
	if fx >= fz:
		h = h00 + fx * (h10 - h00) + fz * (h11 - h10)
	else:
		h = h00 + fz * (h01 - h00) + fx * (h11 - h01)
	if not field_cells.is_empty():
		var c := Vector2i(int(pos.x / TILE_SIZE), int(pos.z / TILE_SIZE))
		if field_cells.has(c):
			h = maxf(h, float(field_tops.get(field_cells[c], h)))
	return h

## Lowest / highest ground under a footprint (grid vertices inside it, edges included).
func get_footprint_height_range(origin: Vector2i, size: Vector2i) -> Vector2:
	var lo := INF
	var hi := -INF
	for j in range(origin.y * SUB, (origin.y + size.y) * SUB + 1):
		for i in range(origin.x * SUB, (origin.x + size.x) * SUB + 1):
			var h := _gh(i, j)
			lo = minf(lo, h)
			hi = maxf(hi, h)
	return Vector2(lo, hi)

## Buildings sit at the lowest point of their footprint (slightly dug into the uphill side, never
## floating over the downhill side).
func get_footprint_height(origin: Vector2i, size: Vector2i) -> float:
	return get_footprint_height_range(origin, size).x

## Level enough to build on: the ground rises at most MAX_BUILD_RISE across the footprint.
func is_area_level(origin: Vector2i, size: Vector2i) -> bool:
	var r := get_footprint_height_range(origin, size)
	return r.y - r.x <= MAX_BUILD_RISE

func _build_ground_mesh() -> ArrayMesh:
	var step_m := TILE_SIZE / SUB
	var verts := PackedVector3Array(); verts.resize(hgrid_w * hgrid_h)
	var norms := PackedVector3Array(); norms.resize(hgrid_w * hgrid_h)
	for j in hgrid_h:
		for i in hgrid_w:
			verts[j * hgrid_w + i] = Vector3(i * step_m, hgrid[j * hgrid_w + i], j * step_m)
			norms[j * hgrid_w + i] = Vector3(_gh(i - 1, j) - _gh(i + 1, j), 2.0 * step_m, _gh(i, j - 1) - _gh(i, j + 1)).normalized()
	var idx := PackedInt32Array()
	idx.resize((hgrid_w - 1) * (hgrid_h - 1) * 6)
	var k := 0
	for j in hgrid_h - 1:
		for i in hgrid_w - 1:
			var p0 := j * hgrid_w + i
			var p1 := p0 + 1
			var p3 := p0 + hgrid_w
			var p2 := p3 + 1
			# same diagonal (p0-p2) as get_height_at
			idx[k] = p0; idx[k + 1] = p1; idx[k + 2] = p2
			idx[k + 3] = p0; idx[k + 4] = p2; idx[k + 5] = p3
			k += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _skirt_quad(st: SurfaceTool, a: Vector3, b: Vector3, n: Vector3, bottom: float) -> void:
	st.set_normal(n)
	st.set_uv(Vector2(0, 0)); st.add_vertex(a)
	st.set_uv(Vector2(1, 0)); st.add_vertex(b)
	st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(b.x, bottom, b.z))
	st.set_uv(Vector2(0, 0)); st.add_vertex(a)
	st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(b.x, bottom, b.z))
	st.set_uv(Vector2(0, 1)); st.add_vertex(Vector3(a.x, bottom, a.z))

func _create_natural_organic_terrain() -> void:
	# HD-2D diorama terrain: smooth ground surface + base skirting
	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_texture = PixelArtTextures.get_diorama_grass_texture()
	# Tone the procedural grass down (it was near-neon next to the 3D diorama buildings);
	# a warmer, darker field makes buildings, units and resources pop instead of competing.
	grass_mat.albedo_color = Color(0.80, 0.85, 0.70)
	grass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	grass_mat.roughness = 0.85

	# rock texture for steep slopes (sampled by the ground shader)
	var cliff_mat = StandardMaterial3D.new()
	cliff_mat.albedo_texture = PixelArtTextures.get_stepped_cliff_texture()
	cliff_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cliff_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cliff_mat.roughness = 0.70
	cliff_mat.albedo_color = HD2DGround.cliff_tint(map_type)   # sandstone / granite / autumn earth

	var wood_base_mat = StandardMaterial3D.new()
	wood_base_mat.albedo_texture = PixelArtTextures.get_diorama_wood_base_texture()
	wood_base_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	wood_base_mat.roughness = 0.40
	wood_base_mat.metallic = 0.15

	var sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.85, 0.75, 0.48)
	sand_mat.roughness = 0.85

	# 1. Ground surface: one smooth mesh over the height grid (rolling hills, no stepped walls).
	#    Steep slopes get earth / rock in the ground shader from the surface normal.
	var top_inst = MeshInstance3D.new()
	top_inst.mesh = _build_ground_mesh()
	ground_mat = HD2DGround.make_material(map_type)
	ground_mat.set_shader_parameter("map_size_m", Vector2(MAP_WIDTH * TILE_SIZE, MAP_HEIGHT * TILE_SIZE))
	ground_mat.set_shader_parameter("tex_cliff", cliff_mat.albedo_texture)
	ground_mat.set_shader_parameter("cliff_tint", HD2DGround.cliff_tint(map_type))
	top_inst.material_override = ground_mat
	ground_container.add_child(top_inst)

	# 2. Outer Diorama Perimeter Skirting Slab (follows the terrain edge)
	var st_skirt = SurfaceTool.new()
	st_skirt.begin(Mesh.PRIMITIVE_TRIANGLES)
	var skirt_bottom_y = -2.5
	var step_m := TILE_SIZE / SUB
	var max_x_pos = MAP_WIDTH * TILE_SIZE
	var max_z_pos = MAP_HEIGHT * TILE_SIZE
	# each edge: list of [top_a, top_b, normal] with the quad wound to face outwards
	for j in range(hgrid_h - 1):
		var za := j * step_m
		var zb := (j + 1) * step_m
		_skirt_quad(st_skirt, Vector3(0, _gh(0, j + 1), zb), Vector3(0, _gh(0, j), za), Vector3(-1, 0, 0), skirt_bottom_y)
		_skirt_quad(st_skirt, Vector3(max_x_pos, _gh(hgrid_w - 1, j), za), Vector3(max_x_pos, _gh(hgrid_w - 1, j + 1), zb), Vector3(1, 0, 0), skirt_bottom_y)
	for i in range(hgrid_w - 1):
		var xa := i * step_m
		var xb := (i + 1) * step_m
		_skirt_quad(st_skirt, Vector3(xa, _gh(i, 0), 0), Vector3(xb, _gh(i + 1, 0), 0), Vector3(0, 0, -1), skirt_bottom_y)
		_skirt_quad(st_skirt, Vector3(xb, _gh(i + 1, hgrid_h - 1), max_z_pos), Vector3(xa, _gh(i, hgrid_h - 1), max_z_pos), Vector3(0, 0, 1), skirt_bottom_y)

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
	var water_mat = ShaderMaterial.new()
	water_mat.shader = load("res://shaders/hd2d_water.gdshader")
	HD2DGround.apply_water_palette(water_mat, map_type)

	# One water surface over the whole wet area: the smooth ground dips under it at lakes and rivers,
	# so the shoreline follows the terrain (sloping banks) instead of square cell edges.
	var wmin := Vector2i(MAP_WIDTH, MAP_HEIGHT)
	var wmax := Vector2i(-1, -1)
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			if tiles[x][y] == TileType.WATER:
				wmin = Vector2i(mini(wmin.x, x), mini(wmin.y, y))
				wmax = Vector2i(maxi(wmax.x, x), maxi(wmax.y, y))
			elif tiles[x][y] == TileType.SHALLOW_WATER:
				_spawn_wooden_bridge(Vector2i(x, y))
	if wmax.x >= 0:
		wmin = Vector2i(maxi(wmin.x - 1, 0), maxi(wmin.y - 1, 0))
		wmax = Vector2i(mini(wmax.x + 1, MAP_WIDTH - 1), mini(wmax.y + 1, MAP_HEIGHT - 1))
		var w_mesh = PlaneMesh.new()
		w_mesh.size = Vector2((wmax.x - wmin.x + 1) * TILE_SIZE, (wmax.y - wmin.y + 1) * TILE_SIZE)
		var wi = MeshInstance3D.new()
		wi.mesh = w_mesh
		wi.position = Vector3((wmin.x + wmax.x + 1) * 0.5 * TILE_SIZE, WATER_SURFACE_Y, (wmin.y + wmax.y + 1) * 0.5 * TILE_SIZE)
		wi.material_override = water_mat
		wi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ground_container.add_child(wi)
		water_mesh_instances.append(wi)

func _spawn_wooden_bridge(cell: Vector2i) -> void:
	var bridge = Node3D.new()
	bridge.position = cell_to_world(cell) + Vector3(0, -0.03, 0)
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

	for bc in _base_cells():
		_spawn_base_cluster(bc)
	# Forest Valley: open valleys run from every base through the map centre (1v1: the middle column)
	var valley_c := Vector2(MAP_WIDTH * 0.5, MAP_HEIGHT * 0.5)
	var valley_dirs: Array[Vector2] = []
	for bc in _base_cells():
		var d := Vector2(bc) - valley_c
		valley_dirs.append(d.normalized() if d.length() > 0.01 else Vector2(0, 1))

	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var cell = Vector2i(x, y)
			if not is_cell_passable_terrain(x, y):
				continue
			if cell in trees or cell in gold_mines or cell in berry_bushes:
				continue
			if _near_any_base(cell, 4):
				continue

			var tree_noise = noise.get_noise_2d(float(x * 6.0 + 80), float(y * 6.0 + 80))
			var should_spawn = false
			if map_type == CivData.MapType.FOREST_VALLEY:
				var dist_cx := INF            # distance to the nearest valley line
				for vd in valley_dirs:
					var rel := Vector2(x, y) - valley_c
					dist_cx = minf(dist_cx, absf(rel.x * vd.y - rel.y * vd.x))
				should_spawn = (dist_cx > 4.5 and tree_noise > -0.12) or tree_noise > 0.30
			elif map_type == CivData.MapType.DESERT_OASIS:
				var dist_center = Vector2(x, y).distance_to(Vector2(MAP_WIDTH * 0.5, MAP_HEIGHT * 0.5))
				should_spawn = dist_center >= 5.0 and dist_center <= 8.5 and map_rng.randf() < 0.4
			else:
				should_spawn = tree_noise > (0.46 - tree_density)

			if should_spawn:
				_spawn_3d_tree(cell)

	var total_gold = cfg.get("gold_nodes", 7)
	for i in range(total_gold):
		var spot = _find_random_empty_spot(Vector2i(3, 8), Vector2i(MAP_WIDTH - 4, MAP_HEIGHT - 9))
		if spot != Vector2i(-1, -1):
			_spawn_resource_cluster(spot, "gold", map_rng.randi_range(2, 3))

	var total_stone = cfg.get("stone_nodes", 6)
	for i in range(total_stone):
		var spot = _find_random_empty_spot(Vector2i(3, 8), Vector2i(MAP_WIDTH - 4, MAP_HEIGHT - 9))
		if spot != Vector2i(-1, -1):
			_spawn_resource_cluster(spot, "stone", map_rng.randi_range(2, 3))

	var total_food = cfg.get("food_nodes", 7)
	for i in range(total_food):
		var spot = _find_random_empty_spot(Vector2i(3, 8), Vector2i(MAP_WIDTH - 4, MAP_HEIGHT - 9))
		if spot != Vector2i(-1, -1):
			_spawn_resource_cluster(spot, "food", map_rng.randi_range(2, 3))

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

		if is_cell_passable_terrain(curr.x, curr.y) and not _is_in_base_keepout(curr) and not (curr in trees or curr in gold_mines or curr in stone_mines or curr in berry_bushes):
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

## Adds the Blender-pipeline environment model as child "Visual" (random yaw/scale so forests
## don't look stamped); in 2D sprite mode the Blender-rendered sprite of the same prop. Returns false
## only when neither exists -> caller adds the old hand-drawn sprite.
func _add_env_model(parent: Node3D, asset_id: String, min_scale: float, max_scale: float) -> bool:
	var m = FactionArtManager.instantiate_environment_model(asset_id)
	if m == null and "/" in asset_id:
		# biome variant missing/disabled -> same prop from the temperate set
		m = FactionArtManager.instantiate_environment_model(asset_id.get_slice("/", 1))
	var yaw := map_rng.randf() * TAU    # drawn even in 2D mode so seeded maps stay identical
	if m == null:
		# 2D sprite mode: the same prop rendered in Blender; mirrored at random instead of rotated
		m = FactionArtManager.instantiate_environment_sprite(asset_id, yaw > PI)
	if m == null:
		return false
	m.name = "Visual"
	if not m.has_node("SpritePlane"):
		m.rotation.y = yaw
	var s := map_rng.randf_range(min_scale, max_scale)
	m.scale = Vector3(s, s, s)
	m.set_meta("base_scale", s)
	parent.add_child(m)
	return true

## Mines shrink as they are depleted (100% -> 55% size) so remaining amount is readable at a glance.
func _update_deposit_visual(entry: Dictionary, remaining: int) -> void:
	var node = entry.get("node", null)
	if not is_instance_valid(node):
		return
	var vis = node.get_node_or_null("Visual")
	if vis == null:
		return
	var frac: float = clamp(float(remaining) / float(max(1, entry.get("max_amount", 1))), 0.0, 1.0)
	var s: float = float(vis.get_meta("base_scale", 1.0)) * lerp(0.55, 1.0, frac)
	vis.scale = Vector3(s, s, s)
	var sort_plane = vis.get_node_or_null("SpritePlane")
	if sort_plane != null and sort_plane.has_method("apply"):
		sort_plane.apply()                 # 2D style: keep the painter's-order height after rescaling

func _spawn_3d_tree(cell: Vector2i) -> void:
	var tree_node = Node3D.new()
	tree_node.position = cell_to_world(cell)   # includes the ground height

	# species from the map biome; exactly one map_rng draw so seeded maps stay reproducible
	var species: Array = CivData.get_biome_props(map_type)["trees"]
	var roll := map_rng.randf()
	var pick: Array = species[species.size() - 1]
	var acc := 0.0
	for sp in species:
		acc += float(sp[2])
		if roll < acc:
			pick = sp
			break
	var is_pine = (pick == species[0])
	if not _add_env_model(tree_node, pick[0], 0.85, 1.15):
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
		"name": pick[1],
		"type": "wood"
	}

func _spawn_3d_gold(cell: Vector2i) -> void:
	var gold_node = Node3D.new()
	gold_node.position = cell_to_world(cell)   # includes the ground height

	if not _add_env_model(gold_node, CivData.get_biome_props(map_type)["gold"][0], 0.95, 1.05):
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
		"name": CivData.get_biome_props(map_type)["gold"][1],
		"type": "gold"
	}

func _spawn_3d_stone(cell: Vector2i) -> void:
	var stone_node = Node3D.new()
	stone_node.position = cell_to_world(cell)   # includes the ground height

	if not _add_env_model(stone_node, CivData.get_biome_props(map_type)["stone"][0], 0.95, 1.05):
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
		"name": CivData.get_biome_props(map_type)["stone"][1],
		"type": "stone"
	}

func _spawn_3d_berry(cell: Vector2i) -> void:
	var berry_node = Node3D.new()
	berry_node.position = cell_to_world(cell)   # includes the ground height

	if not _add_env_model(berry_node, CivData.get_biome_props(map_type)["food"][0], 0.9, 1.1):
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
		"name": CivData.get_biome_props(map_type)["food"][1],
		"type": "food"
	}

## Cells too close to a start position (Town Center footprint + its courtyard). Random resource
## clusters (and their flood-fill growth) used to land here: in 7/12 sampled maps a gold/stone/berry
## node sat INSIDE a Town Center footprint, hijacking taps on the TC and blocking its cells.
const BASE_KEEPOUT_RADIUS: float = 4.0

func _is_in_base_keepout(c: Vector2i) -> bool:
	return _near_any_base(c, BASE_KEEPOUT_RADIUS)

func _find_random_empty_spot(min_b: Vector2i, max_b: Vector2i) -> Vector2i:
	for attempt in range(40):
		var rx = map_rng.randi_range(min_b.x, max_b.x)
		var ry = map_rng.randi_range(min_b.y, max_b.y)
		var c = Vector2i(rx, ry)
		if is_cell_passable_terrain(rx, ry) and not _is_in_base_keepout(c) and not (c in trees or c in gold_mines or c in stone_mines or c in berry_bushes):
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

func mark_resource_unreachable(cell: Vector2i) -> void:
	unreachable_resource_cells[cell] = true

func is_resource_marked_unreachable(cell: Vector2i) -> bool:
	return unreachable_resource_cells.has(cell)

func update_cell_walkability(cell: Vector2i) -> void:
	unreachable_resource_cells.clear()
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

## Save / load: what is left of every resource node, by type ("wood", "gold", "stone", "food").
func get_resource_state() -> Dictionary:
	var out := {}
	for t in [["wood", trees, "hp"], ["gold", gold_mines, "gold"], ["stone", stone_mines, "stone"], ["food", berry_bushes, "food"]]:
		var list := []
		for cell in t[1].keys():
			var e: Dictionary = t[1][cell]
			list.append([cell.x, cell.y, int(e.get(t[2], e.get("amount", 0)))])
		out[t[0]] = list
	return out

## After regenerating the same map from its seed: nodes used up before the save are removed, partly
## used ones get their remaining amount back (through the normal harvest path, so walkability and the
## shrinking mine visuals update too).
func apply_resource_state(state: Dictionary) -> void:
	for t in [["wood", trees, "hp", harvest_tree], ["gold", gold_mines, "gold", harvest_gold], ["stone", stone_mines, "stone", harvest_stone], ["food", berry_bushes, "food", harvest_food]]:
		if not state.has(t[0]):
			continue
		var left := {}
		for e in state[t[0]]:
			left[Vector2i(int(e[0]), int(e[1]))] = int(e[2])
		for cell in t[1].keys():
			var e: Dictionary = t[1][cell]
			var cur: int = int(e.get(t[2], e.get("amount", 0)))
			var keep: int = left.get(cell, 0)
			if keep < cur:
				t[3].call(cell, cur - keep)

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
	_update_deposit_visual(g, cur)
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
	_update_deposit_visual(s, cur)
	if cur <= 0:
		if is_instance_valid(s.get("node", null)):
			s["node"].queue_free()
		stone_mines.erase(cell)
		update_cell_walkability(cell)
	return harvested

func harvest_food(cell: Vector2i, amount: int) -> int:
	if farm_fields.has(cell):
		return amount   # fields never deplete
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
	HD2DScatter.hide_cells(scatter_cell_index, origin_cell, size)

## Buildable = walkable and not covered by a farm field (fields can be walked over, not built on).
func is_cell_buildable(cell: Vector2i) -> bool:
	return is_cell_walkable(cell) and not field_cells.has(cell)

func register_field_cells(origin_cell: Vector2i, size: Vector2i) -> void:
	field_tops[origin_cell] = get_footprint_height_range(origin_cell, size).y
	for dx in range(size.x):
		for dy in range(size.y):
			field_cells[origin_cell + Vector2i(dx, dy)] = origin_cell
	HD2DScatter.hide_cells(scatter_cell_index, origin_cell, size)

func unregister_field(origin_cell: Vector2i, size: Vector2i) -> void:
	for dx in range(size.x):
		for dy in range(size.y):
			field_cells.erase(origin_cell + Vector2i(dx, dy))
	farm_fields.erase(origin_cell)
	field_tops.erase(origin_cell)

## Called when a field finishes construction (and again after a save is restored): idempotent.
func register_field_resource(field: Node3D) -> void:
	var origin: Vector2i = field.origin_cell
	if farm_fields.has(origin):
		farm_fields[origin]["building"] = field
		return
	farm_fields[origin] = {"building": field, "team": field.team, "farmer": null}

## Origin of the field covering `cell`, or (-1,-1).
func field_origin_at(cell: Vector2i) -> Vector2i:
	return field_cells.get(cell, Vector2i(-1, -1))

## True when `cell` still holds something a food gatherer can harvest (berry bush or active field).
func has_food_source(cell: Vector2i) -> bool:
	return cell in berry_bushes or farm_fields.has(cell)

## A field is free for `unit` when nobody else is actively farming it (1 farmer per field).
## Lazy check: a farmer that walked off to do something else frees the field automatically.
func is_field_free_for(origin: Vector2i, unit: Node) -> bool:
	if not farm_fields.has(origin):
		return false
	var f = farm_fields[origin]["farmer"]
	if f == null or not is_instance_valid(f) or f == unit or f.hp <= 0:
		return true
	return not (f.resource_type == "food" and f.target_cell == origin and f.state in [Unit3D.State.GATHERING, Unit3D.State.RETURNING_RESOURCES])

func claim_field(origin: Vector2i, unit: Node) -> bool:
	if not is_field_free_for(origin, unit):
		return false
	farm_fields[origin]["farmer"] = unit
	return true

## Nearest completed field of `team` that `unit` may farm, within max_world_distance (or -1,-1).
func find_free_field(from_pos: Vector3, team: int, unit: Node, max_world_distance: float = 9999.0) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := max_world_distance * max_world_distance
	for origin in farm_fields.keys():
		var e: Dictionary = farm_fields[origin]
		if e["team"] != team or not is_field_free_for(origin, unit):
			continue
		var d := from_pos.distance_squared_to(cell_to_world(origin))
		if d < best_d:
			best_d = d
			best = origin
	return best

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
		if amt <= 0 or unreachable_resource_cells.has(cell):
			continue
		var w_pos = cell_to_world(cell)
		var d_sq = from_pos.distance_squared_to(w_pos)
		if d_sq < min_dist_sq:
			min_dist_sq = d_sq
			best_cell = cell
	return best_cell
