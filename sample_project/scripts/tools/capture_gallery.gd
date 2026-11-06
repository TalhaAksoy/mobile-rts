extends SceneTree
## In-game art gallery capture (needs a display; do NOT run with --headless).
##
## Loads the real Main3D scene, clears an area of the map and lines up every building and every soldier of one
## civ in one age look, then screenshots it. One shot per age, so the three can be put side by side.
##
##   godot --path . --resolution 1600x1000 --script res://scripts/tools/capture_gallery.gd -- \
##       --out=<dir> --civ=0 --style=2d|3d [--ages=1,2,3]
##
## Output: <out>/gallery_<style>_<civ>_a<age>.png

const GameController3D = preload("res://scripts/GameController3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")

var out_dir := "user://captures"
var civ := 0
var style := "2d"
var ages: Array = [1, 2, 3]

const ROW1 := [Building3D.BuildingType.TOWN_CENTER, Building3D.BuildingType.CASTLE, Building3D.BuildingType.BARRACKS,
	Building3D.BuildingType.ARCHERY_RANGE, Building3D.BuildingType.STABLE]
const ROW2 := [Building3D.BuildingType.HOUSE, Building3D.BuildingType.BLACKSMITH, Building3D.BuildingType.MILL,
	Building3D.BuildingType.LUMBER_CAMP, Building3D.BuildingType.MINING_CAMP, Building3D.BuildingType.TOWER]

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_dir = a.substr(6)
		elif a.begins_with("--civ="): civ = int(a.substr(6))
		elif a.begins_with("--style="): style = a.substr(8)
		elif a.begins_with("--ages="): ages = Array(a.substr(7).split(",")).map(func(s): return int(s))
	call_deferred("_run")

func _wait(sec: float) -> void:
	var t := 0.0
	while t < sec:
		await process_frame
		t += root.get_process_delta_time()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var game = scene as GameController3D
	GraphicsSettings.set_value("style", 1 if style == "2d" else 0)
	FactionArtManager.use_3d_building_models = style != "2d"
	seed(7)
	game._on_start_game_requested(civ, civ, CivData.MapType.FOREST_VALLEY)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	for ai in game.bot_ais:
		ai.set_process(false)
		ai.set_physics_process(false)
	if game.enemy_ai != null:
		game.enemy_ai.set_process(false)
		game.enemy_ai.set_physics_process(false)
	game.separation_enabled = false
	await _wait(0.3)
	var mg = game.map_gen
	# clean stage: no fog, no resources, nothing of the match
	if mg.fog_mesh_inst != null:
		mg.fog_mesh_inst.visible = false
	for d in [mg.trees, mg.gold_mines, mg.stone_mines, mg.berry_bushes]:
		for c in d:
			var n = d[c].get("node") if d[c] is Dictionary else d[c]
			if n is Node and is_instance_valid(n):
				n.queue_free()
		d.clear()
	HD2DScatter.hide_cells(mg.scatter_cell_index, Vector2i.ZERO, Vector2i(mg.MAP_WIDTH, mg.MAP_HEIGHT))
	for u in game.units.duplicate():
		u.queue_free()
	game.units.clear()
	for b in game.buildings.duplicate():
		b.visible = false
	if game.ui_manager != null and game.ui_manager.hud_root != null:
		game.ui_manager.hud_root.visible = false
	await process_frame

	var sc: Vector2i = mg.world_to_cell(mg.player_start_pos)
	var cx: int = clampi(sc.x, 13, mg.MAP_WIDTH - 13)
	var cz: int = clampi(sc.y, 10, mg.MAP_HEIGHT - 6)
	var civ_data: Dictionary = CivData.get_civ(civ)
	var unique = Unit3D.UnitType.get(civ_data.get("unique_unit_type", ""), -1)
	var kinds := [Unit3D.UnitType.VILLAGER, Unit3D.UnitType.SPEARMAN, Unit3D.UnitType.SWORDSMAN, Unit3D.UnitType.ARCHER,
		Unit3D.UnitType.CAVALRY]
	if unique >= 0:
		kinds.append(unique)

	for age in ages:
		game.team_age[0] = age
		var made: Array = []
		var z := cz - 4
		for row in [ROW1, ROW2]:
			var widths: Array = row.map(func(t): return _slot(game, t))
			var total := 0
			for w in widths:
				total += w
			var x := cx - total / 2
			var deepest := 0
			for i in row.size():
				var sz: Vector2i = game._get_building_size(row[i])
				var b = game.place_building(row[i], 0, Vector2i(x + (widths[i] - sz.x) / 2, z - sz.y), false)
				made.append(b)
				x += widths[i]
				deepest = max(deepest, sz.y)
			z += 5
		# soldiers in front, two copies each (team 0 and team 1 colours)
		var base: Vector3 = mg.cell_to_world(Vector2i(cx, z - 3))
		var ux := base.x - (kinds.size() - 1) * 1.6
		for k in kinds:
			for team in [0, 1]:
				var p := Vector3(ux + team * 0.9, base.y, base.z + (0.0 if team == 0 else 1.4))
				game.team_age[team] = age
				var u = game.spawn_unit(k, team, p)
				made.append(u)
			ux += 3.2
		await _wait(0.5)
		var cam = game.camera
		cam.max_height = 80.0
		var h := 19.0 if style == "2d" else 17.0
		cam.target_height = h
		cam.position.y = h
		var center: Vector3 = mg.cell_to_world(Vector2i(cx, cz - (2 if style == "2d" else 0)))
		cam.jump_to(center, false)
		await _wait(0.8)
		var img := root.get_viewport().get_texture().get_image()
		var path := "%s/gallery_%s_%d_a%d.png" % [out_dir, style, civ, age]
		img.save_png(path)
		print("[gallery] saved ", path)
		for n in made:
			if is_instance_valid(n):
				if n is Unit3D:
					game.units.erase(n)
				else:
					game.buildings.erase(n)
					n.visible = false
				n.queue_free()
		await _wait(0.2)
	quit(0)

## horizontal room a building's sprite / model needs (its art is wider than its footprint)
func _slot(game, t) -> int:
	var sz: Vector2i = game._get_building_size(t)
	return sz.x + 1
