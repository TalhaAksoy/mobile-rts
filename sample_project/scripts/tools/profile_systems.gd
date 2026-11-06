extends SceneTree
## Where the CPU time of one frame goes, per game system, with N units per team on the real Main3D scene.
##   godot --path . --resolution 540x960 --script res://scripts/tools/profile_systems.gd -- [--n=60] [--style=2d]
## Prints microseconds per call for: HUD update, fog of war, unit separation, all units' physics step, the
## idle soldiers' enemy scan, buildings' _process, the UI _process and the bots' _process.

const Unit3D = preload("res://scripts/Unit3D.gd")
var n := 60
var style := "2d"

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="): n = int(a.substr(4))
		elif a.begins_with("--style="): style = a.substr(8)
	call_deferred("_run")

func _frames(k: int) -> void:
	for i in k:
		await process_frame

func _time(label: String, reps: int, f: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	for i in reps:
		f.call()
	var us := float(Time.get_ticks_usec() - t0) / reps
	print("[profile] %-34s %8.0f us" % [label, us])

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	await _frames(3)
	var game = scene
	GraphicsSettings.set_value("style", 1 if style == "2d" else 0)
	FactionArtManager.use_3d_building_models = style != "2d"
	game.map_size = 1
	game.bot_count = 1
	game._on_start_game_requested(0, 1, CivData.MapType.FOREST_VALLEY)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	game.enemy_ai.set_process(false)
	await _frames(5)
	var kinds := [Unit3D.UnitType.SWORDSMAN, Unit3D.UnitType.SPEARMAN, Unit3D.UnitType.ARCHER, Unit3D.UnitType.CAVALRY]
	for team in [0, 1]:
		var base: Vector3 = game.map_gen.player_start_pos if team == 0 else game.map_gen.enemy_start_pos
		for i in n:
			var p := base + Vector3((i % 10) * 1.6 - 8.0, 0, (i / 10) * 1.6 + 6.0)
			game.spawn_unit(kinds[i % kinds.size()], team, p)
	await _frames(30)
	print("[profile] units %d, buildings %d, style %s" % [game.units.size(), game.buildings.size(), style])
	var units: Array = game.units.filter(func(u): return is_instance_valid(u))
	var idle_soldiers: Array = units.filter(func(u): return u.unit_type != Unit3D.UnitType.VILLAGER and u.state == Unit3D.State.IDLE)
	print("[profile] idle soldiers scanning: %d" % idle_soldiers.size())
	_time("HUD update (_update_hud)", 50, func(): game._update_hud())
	_time("fog of war (every 0.2 s)", 10, func(): game.map_gen.update_fog_of_war(game.get_team_units(0), game.get_team_buildings(0), game._hostile_units(), game._hostile_buildings()))
	_time("separation (2 passes, every tick)", 20, func():
		for k in game.SEPARATION_PASSES:
			game._separate_units())
	_time("idle enemy scan, all idle soldiers", 20, func():
		for u in idle_soldiers:
			u._find_closest_enemy(6.5))
	_time("all units _physics_process", 10, func():
		for u in units:
			if is_instance_valid(u):
				u._physics_process(1.0 / 60.0))
	_time("all buildings _process", 20, func():
		for b in game.buildings:
			if is_instance_valid(b):
				b._process(1.0 / 60.0))
	_time("UI _process", 50, func(): game.ui_manager._process(1.0 / 60.0))
	quit(0)
