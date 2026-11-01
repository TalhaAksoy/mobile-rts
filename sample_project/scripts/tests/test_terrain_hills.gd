extends SceneTree
## Natural hills (smooth terrain instead of stepped block terraces), on every map type:
##  * no vertical walls: the steepest step between neighbouring grid vertices is a slope
##  * the ground mesh and MapGenerator3D.get_height_at() are the same surface (checked against the
##    mesh's own triangles), and height_map holds that surface at every cell centre
##  * real elevation: hills rise well above the lowland, the bases stay level
##  * water cells are below the water surface, dry land above it
##  * trees / mines / bushes stand on the ground (not twice their height above it)
##  * a villager walking over a hill keeps its feet on the ground the whole way
##  * buildings sit on level ground: placed at the lowest point of their footprint (never floating),
##    and a too-steep spot is refused without spending wood
##  * a tap on a hilltop lands on the hilltop (ray marched against the terrain)
const GameController3D = preload("res://scripts/GameController3D.gd")

var failures := 0
var checks := 0

func _check(cond: bool, msg: String) -> void:
	checks += 1
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _init() -> void:
	call_deferred("_run")

func _frames(n: int) -> void:
	for i in n:
		await process_frame

## Height of the ground mesh itself at (x, z): finds the triangle in the mesh arrays.
func _mesh_height(arr: Array, grid_w: int, step_m: float, x: float, z: float) -> float:
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var i := int(x / step_m)
	var j := int(z / step_m)
	var q := (j * (grid_w - 1) + i) * 6
	for t in [q, q + 3]:
		var a: Vector3 = verts[idx[t]]
		var b: Vector3 = verts[idx[t + 1]]
		var c: Vector3 = verts[idx[t + 2]]
		var p := Vector2(x, z)
		var v0 := Vector2(b.x - a.x, b.z - a.z)
		var v1 := Vector2(c.x - a.x, c.z - a.z)
		var v2 := p - Vector2(a.x, a.z)
		var den := v0.x * v1.y - v1.x * v0.y
		var u := (v2.x * v1.y - v1.x * v2.y) / den
		var w := (v0.x * v2.y - v2.x * v0.y) / den
		if u >= -1e-4 and w >= -1e-4 and u + w <= 1.0 + 1e-4:
			return a.y + u * (b.y - a.y) + w * (c.y - a.y)
	return NAN

func _ground_mesh(mg) -> MeshInstance3D:
	for c in mg.ground_container.get_children():
		if c is MeshInstance3D and c.material_override == mg.ground_mat:
			return c
	return null

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var game = scene as GameController3D
	var MG = MapGenerator3D

	for m in CivData.MapType.values():
		seed(4200 + m)
		game.selected_map_type = m
		game.start_match()
		game.enemy_ai.set_process(false)
		await process_frame
		var mg = game.map_gen
		var tag := "map %d (%s)" % [m, CivData.MapType.keys()[m]]

		# --- no walls: steepest rise between neighbouring vertices (1 m apart)
		var max_step := 0.0
		for j in mg.hgrid_h:
			for i in mg.hgrid_w - 1:
				max_step = maxf(max_step, absf(mg._gh(i + 1, j) - mg._gh(i, j)))
		for j in mg.hgrid_h - 1:
			for i in mg.hgrid_w:
				max_step = maxf(max_step, absf(mg._gh(i, j + 1) - mg._gh(i, j)))
		_check(max_step < 1.6, "%s: no vertical walls, steepest 1 m step rises %.2f m" % [tag, max_step])
		var walls := 0
		for c in mg.ground_container.get_children():
			if c is MeshInstance3D and c.mesh is ArrayMesh and c.material_override is StandardMaterial3D \
					and (c.material_override as StandardMaterial3D).albedo_texture == PixelArtTextures.get_stepped_cliff_texture():
				walls += 1
		_check(walls == 0, "%s: no stepped cliff-wall mesh" % tag)

		# --- mesh == sampler == height_map
		var gm := _ground_mesh(mg)
		_check(gm != null, "%s: ground mesh present" % tag)
		if gm != null:
			var arr: Array = gm.mesh.surface_get_arrays(0)
			var worst := 0.0
			var rng := RandomNumberGenerator.new()
			rng.seed = 99 + m
			for k in 400:
				var x := rng.randf_range(0.01, game.map_gen.MAP_WIDTH * MG.TILE_SIZE - 0.01)
				var z := rng.randf_range(0.01, game.map_gen.MAP_HEIGHT * MG.TILE_SIZE - 0.01)
				var mh := _mesh_height(arr, mg.hgrid_w, MG.TILE_SIZE / MG.SUB, x, z)
				worst = maxf(worst, absf(mh - mg.get_height_at(Vector3(x, 0, z))))
			_check(worst < 0.001, "%s: get_height_at matches the ground mesh (worst %.4f m)" % [tag, worst])
		var hm_worst := 0.0
		for x in game.map_gen.MAP_WIDTH:
			for y in game.map_gen.MAP_HEIGHT:
				hm_worst = maxf(hm_worst, absf(mg.height_map[x][y] - mg.get_height_at(mg.cell_to_world(Vector2i(x, y)))))
		_check(hm_worst < 0.001, "%s: height_map / cell_to_world are the ground at cell centres" % tag)

		# --- real elevation, level bases
		var lo := INF
		var hi := -INF
		for x in game.map_gen.MAP_WIDTH:
			for y in game.map_gen.MAP_HEIGHT:
				if mg.tiles[x][y] != MG.TileType.WATER and mg.tiles[x][y] != MG.TileType.SHALLOW_WATER:
					lo = minf(lo, mg.height_map[x][y])
					hi = maxf(hi, mg.height_map[x][y])
		_check(hi - lo > 1.2, "%s: hills rise %.2f m above the lowest dry ground" % [tag, hi - lo])
		for start in [mg.player_start_pos, mg.enemy_start_pos]:
			var sc: Vector2i = mg.world_to_cell(start)
			var r: Vector2 = mg.get_footprint_height_range(sc - Vector2i(5, 5), Vector2i(11, 11))
			_check(r.y - r.x < 0.05, "%s: base around %s is level (%.3f m)" % [tag, sc, r.y - r.x])

		# --- water below, land above the water surface
		var wet_bad := 0
		var dry_bad := 0
		for x in game.map_gen.MAP_WIDTH:
			for y in game.map_gen.MAP_HEIGHT:
				var h: float = mg.height_map[x][y]
				if mg.tiles[x][y] == MG.TileType.WATER:
					if h > MG.WATER_SURFACE_Y - 0.1: wet_bad += 1
				elif mg.tiles[x][y] != MG.TileType.SHALLOW_WATER:
					if h < MG.WATER_SURFACE_Y + 0.1: dry_bad += 1
		_check(wet_bad == 0 and dry_bad == 0, "%s: water cells under the surface (%d bad), dry cells above it (%d bad)" % [tag, wet_bad, dry_bad])

		# --- props on the ground
		var floating := []
		for dict in [mg.trees, mg.gold_mines, mg.stone_mines, mg.berry_bushes]:
			for cell in dict.keys():
				var node = dict[cell].get("node", null)
				if is_instance_valid(node) and absf(node.global_position.y - mg.get_height_at(node.global_position)) > 0.01 and floating.size() < 4:
					floating.append("%s y=%.2f ground=%.2f" % [cell, node.global_position.y, mg.get_height_at(node.global_position)])
		_check(floating.is_empty(), "%s: trees / mines / bushes stand on the ground %s" % [tag, str(floating)])

	# --- highland: villager over a hill, buildings on slopes, taps on hilltops, save / load
	seed(4203)
	game.selected_map_type = CivData.MapType.HIGHLAND_PLAINS
	game.start_match()
	game.enemy_ai.set_process(false)
	await process_frame
	var mg = game.map_gen
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()

	# a walkable path that climbs: from the base towards the highest walkable cell
	var top := Vector2i(-1, -1)
	var top_h := -INF
	for x in game.map_gen.MAP_WIDTH:
		for y in range(20, game.map_gen.MAP_HEIGHT - 4):
			if mg.is_cell_walkable(Vector2i(x, y)) and mg.height_map[x][y] > top_h:
				var path: Array = mg.get_path_to_target(mg.player_start_pos, mg.cell_to_world(Vector2i(x, y)))
				if not path.is_empty() and mg.world_to_cell(path[path.size() - 1]) == Vector2i(x, y):
					top_h = mg.height_map[x][y]
					top = Vector2i(x, y)
	_check(top_h > 1.0, "a hill the villagers can walk up (%s, %.2f m)" % [top, top_h])
	var v: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, mg.player_start_pos + Vector3(0, 0, 4))
	_check(absf(v.global_position.y - mg.get_height_at(v.global_position)) < 0.01, "spawned villager stands on the ground")
	v.command_move(mg.cell_to_world(top))
	var off := 0.0
	var y_min := INF
	var y_max := -INF
	for k in 900:
		await physics_frame
		if v.state != Unit3D.State.MOVING:
			break
		off = maxf(off, absf(v.global_position.y - mg.get_height_at(v.global_position)))
		y_min = minf(y_min, v.global_position.y)
		y_max = maxf(y_max, v.global_position.y)
	_check(mg.world_to_cell(v.global_position) == top, "villager reached the hilltop %s (at %s)" % [top, mg.world_to_cell(v.global_position)])
	_check(off < 0.02 and y_max - y_min > 0.8, "feet on the ground all the way up (max gap %.3f m, climbed %.2f m)" % [off, y_max - y_min])

	# buildings: level enough spot on sloped ground vs a too-steep spot
	var sloped = null
	var steep = null
	for x in range(0, game.map_gen.MAP_WIDTH - 2):
		for y in range(4, game.map_gen.MAP_HEIGHT - 4):
			var o := Vector2i(x, y)
			var free := true
			for dx in 2:
				for dy in 2:
					var c := o + Vector2i(dx, dy)
					if not mg.is_cell_buildable(c) or not mg.get_resource_at_cell(c).is_empty():
						free = false
			if not free:
				continue
			var r: Vector2 = mg.get_footprint_height_range(o, Vector2i(2, 2))
			if sloped == null and r.y - r.x > 0.3 and r.y - r.x <= MG.MAX_BUILD_RISE:
				sloped = o
			if steep == null and r.y - r.x > MG.MAX_BUILD_RISE + 0.1:
				steep = o
	_check(sloped != null and steep != null, "found a gently sloped spot %s and a steep one %s" % [sloped, steep])
	if sloped != null:
		var b = game.place_building(Building3D.BuildingType.HOUSE, 0, sloped, false)
		var r: Vector2 = mg.get_footprint_height_range(sloped, Vector2i(2, 2))
		_check(is_equal_approx(b.global_position.y, r.x), "house on a slope sits at the lowest corner (y %.2f, ground %.2f..%.2f): never floats" % [b.global_position.y, r.x, r.y])
	if steep != null:
		var wood_before: int = game.team_resources[0]["wood"]
		var n_before: int = game.buildings.size()
		game.placing_building_type = Building3D.BuildingType.HOUSE
		game.is_placing_building = true
		game._attempt_place_building(mg.cell_to_world(steep))
		_check(game.buildings.size() == n_before and game.team_resources[0]["wood"] == wood_before, "too steep: placement refused, no wood spent")
		game.is_placing_building = false
		_check(not game.enemy_ai._is_area_clear(steep, Vector2i(2, 2)), "the AI does not pick the steep spot either")

	# a tap on the hilltop lands on the hilltop, not on the y = 0 plane behind it
	var cam = game.camera
	cam.jump_to(mg.cell_to_world(top), false)
	await _frames(3)
	var hill_pt: Vector3 = mg.cell_to_world(top)
	var hit: Vector3 = cam.raycast_ground(cam.unproject_position(hill_pt))
	_check(Vector2(hit.x, hit.z).distance_to(Vector2(hill_pt.x, hill_pt.z)) < 0.3, "tap on the hilltop hits it (off by %.2f m)" % Vector2(hit.x, hit.z).distance_to(Vector2(hill_pt.x, hill_pt.z)))

	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
