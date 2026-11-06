extends SceneTree
## Where the 3D draw calls come from: a mid-game base in 3D style, then the draw-call count with each group
## of objects hidden in turn (and shadows off).
##   godot --path . --resolution 540x960 --script res://scripts/tools/drawcall_breakdown.gd -- [--style=3d]

const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")
var style := "3d"

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--style="): style = a.substr(8)
	call_deferred("_run")

func _frames(k: int) -> void:
	for i in k:
		await process_frame

func _dc() -> int:
	await _frames(4)
	return int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	await _frames(3)
	var game = scene
	GraphicsSettings.set_value("style", 1 if style == "2d" else 0)
	FactionArtManager.use_3d_building_models = style != "2d"
	seed(11)
	game.map_size = 1
	game.bot_count = 1
	game._on_start_game_requested(0, 1, CivData.MapType.FOREST_VALLEY)
	game.enemy_ai.set_process(false)
	await _frames(5)
	var start: Vector3 = game.map_gen.player_start_pos
	var cell: Vector2i = game.map_gen.world_to_cell(start)
	var kinds := [Building3D.BuildingType.HOUSE, Building3D.BuildingType.BARRACKS, Building3D.BuildingType.HOUSE,
		Building3D.BuildingType.ARCHERY_RANGE, Building3D.BuildingType.BLACKSMITH, Building3D.BuildingType.HOUSE,
		Building3D.BuildingType.LUMBER_CAMP, Building3D.BuildingType.MINING_CAMP]
	var offs := [Vector2i(-7, -2), Vector2i(4, -3), Vector2i(-7, 3), Vector2i(4, 2), Vector2i(-3, 6), Vector2i(1, 6), Vector2i(-8, 8), Vector2i(6, 7)]
	for i in kinds.size():
		game.place_building(kinds[i], 0, cell + offs[i], false)
	var ut := [Unit3D.UnitType.SWORDSMAN, Unit3D.UnitType.ARCHER, Unit3D.UnitType.SPEARMAN, Unit3D.UnitType.VILLAGER]
	for i in 30:
		game.spawn_unit(ut[i % 4], 0, start + Vector3((i % 6) * 1.6 - 4, 0, 5 + (i / 6) * 1.6))
	game.camera.jump_to(start + Vector3(0, 0, 4), false)
	await _frames(30)
	var base := await _dc()
	print("[dc] all visible: %d (prims %d)" % [base, Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	var groups := {
		"units": game.units.filter(func(u): return is_instance_valid(u)),
		"buildings": game.buildings.filter(func(b): return is_instance_valid(b)),
		"trees+resources": [],
		"scatter (grass etc)": [],
	}
	for d in [game.map_gen.trees, game.map_gen.gold_mines, game.map_gen.stone_mines, game.map_gen.berry_bushes]:
		for c in d:
			var n = d[c].get("node") if d[c] is Dictionary else d[c]
			if is_instance_valid(n):
				groups["trees+resources"].append(n)
	for n in game.map_gen.get_children():
		for m in n.find_children("*", "MultiMeshInstance3D", true, false):
			groups["scatter (grass etc)"].append(m)
	for g in groups.keys():
		var was: Array = []
		for n in groups[g]:
			was.append(n.visible)
			n.visible = false
		var dc := await _dc()
		print("[dc] without %-22s %5d  (-%d)  [%d nodes]" % [g, dc, base - dc, groups[g].size()])
		for k in groups[g].size():
			groups[g][k].visible = was[k]
	var light := scene.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if light != null:
		var sh := light.shadow_enabled
		light.shadow_enabled = false
		var dc2 := await _dc()
		print("[dc] without shadows               %5d  (-%d)" % [dc2, base - dc2])
		light.shadow_enabled = sh
	if light != null and OS.get_cmdline_user_args().has("--shadowmodes"):
		var vp := root.get_viewport()
		for m in [DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, DirectionalLight3D.SHADOW_ORTHOGONAL]:
			light.directional_shadow_mode = m
			var d := await _dc()
			print("[dc] shadow mode %d: %d" % [m, d])
			vp.get_texture().get_image().save_png("user://shadowmode_%d.png" % m)
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	# surfaces per unit / building model
	var u0 = game.units.filter(func(u): return is_instance_valid(u) and u.team == 0 and u.unit_type == Unit3D.UnitType.SWORDSMAN)[0]
	var su := 0
	for mi in u0.find_children("*", "MeshInstance3D", true, false):
		su += (mi as MeshInstance3D).mesh.get_surface_count() if mi.mesh != null else 0
	print("[dc] one swordsman: %d mesh instances, %d surfaces" % [u0.find_children("*", "MeshInstance3D", true, false).size(), su])
	for b in game.buildings:
		if is_instance_valid(b) and b.team == 0:
			var mis = b.find_children("*", "MeshInstance3D", true, false)
			var sb := 0
			for mi in mis:
				sb += (mi as MeshInstance3D).mesh.get_surface_count() if mi.mesh != null else 0
			print("[dc] building %d: %d mesh instances, %d surfaces" % [b.building_type, mis.size(), sb])
	quit(0)
