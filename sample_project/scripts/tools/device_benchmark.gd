extends SceneTree
## Frame cost on the real Main3D scene for the mobile presets, meant to run under an emulated slow CPU
## (scripts/tools/device_tiers.sh limits the process to one core and a share of it). Needs a display.
##
##   godot --path . --resolution 720x1280 --script res://scripts/tools/device_benchmark.gd -- \
##       --out=<file.csv> [--tier=desktop] [--units=0,30,60] [--seconds=6]
##
## For each look (2D on the "Düşük" preset, 3D on the "Orta" preset - the mobile defaults), one match on a fixed
## map with a 10-building base; then two armies (N per team) march into each other and fight while the frame
## times are sampled. Uncapped (vsync off, no fps cap): the numbers show the headroom against 33 / 16.7 ms.

const GameController3D = preload("res://scripts/GameController3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")

var out_path := "user://device.csv"
var tier := "desktop"
var unit_steps: Array = [0, 30, 60]
var seconds := 6.0

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_path = a.substr(6)
		elif a.begins_with("--tier="): tier = a.substr(7)
		elif a.begins_with("--units="): unit_steps = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--seconds="): seconds = float(a.substr(10))
	call_deferred("_run")

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _sample(secs: float) -> Dictionary:
	var ft: Array = []
	var t := 0.0
	var dc := 0.0
	var prim := 0.0
	var phys := 0.0
	var t0 := Time.get_ticks_usec()
	while t < secs:
		await process_frame
		var now := Time.get_ticks_usec()
		var d := (now - t0) / 1000.0           # wall-clock ms per frame (not scaled game time)
		t0 = now
		ft.append(d)
		t += d / 1000.0
		dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prim += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var n := ft.size()
	var sorted := ft.duplicate()
	sorted.sort()
	var avg := 0.0
	for v in ft:
		avg += v
	avg /= maxf(n, 1)
	return {"fps": 1000.0 / avg, "avg_ms": avg, "p95_ms": sorted[int(n * 0.95)], "p99_ms": sorted[mini(n - 1, int(n * 0.99))],
		"draw_calls": dc / n, "primitives": prim / n, "physics_ms": phys / n, "frames": n}

func _run() -> void:
	var lines := ["tier,look,preset,units_per_team,alive_units,fps,avg_ms,p95_ms,p99_ms,physics_ms,draw_calls,primitives"]
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for look in [["2d", GraphicsSettings.Preset.LOW], ["3d", GraphicsSettings.Preset.MEDIUM]]:
		var t_load := Time.get_ticks_msec()
		var scene = load("res://scenes/Main3D.tscn").instantiate()
		root.add_child(scene)
		await _frames(3)
		var game = scene as GameController3D
		GraphicsSettings.set_preset(look[1])
		GraphicsSettings.values["style"] = 1 if look[0] == "2d" else 0
		FactionArtManager.use_3d_building_models = look[0] == "3d"
		GraphicsSettings.apply(root.get_viewport(), scene.get_node_or_null("DirectionalLight3D"))
		Engine.max_fps = 0                         # measure the headroom, not the preset's cap
		seed(4242)
		game.map_size = 1
		game.bot_count = 1
		game._on_start_game_requested(0, 1, CivData.MapType.FOREST_VALLEY)
		if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
			game.tutorial_mgr.stop_tutorial()
		game.enemy_ai.set_process(false)
		await _frames(5)
		print("[device] %s %s: match ready in %.1f s" % [tier, look[0], (Time.get_ticks_msec() - t_load) / 1000.0])
		var base_cell: Vector2i = game.map_gen.world_to_cell(game.map_gen.player_start_pos)
		var kinds := [Building3D.BuildingType.HOUSE, Building3D.BuildingType.BARRACKS, Building3D.BuildingType.HOUSE,
			Building3D.BuildingType.ARCHERY_RANGE, Building3D.BuildingType.BLACKSMITH, Building3D.BuildingType.HOUSE,
			Building3D.BuildingType.LUMBER_CAMP, Building3D.BuildingType.MINING_CAMP, Building3D.BuildingType.HOUSE]
		var offs := [Vector2i(-7, -2), Vector2i(4, -3), Vector2i(-7, 3), Vector2i(4, 2), Vector2i(-3, 6), Vector2i(1, 6),
			Vector2i(-8, 8), Vector2i(6, 7), Vector2i(-11, -1)]
		for i in kinds.size():
			game.place_building(kinds[i], 0, base_cell + offs[i], false)
		var cam = game.camera
		cam.target_height = 24.0
		cam.position.y = 24.0
		var front: Vector3 = game.map_gen.player_start_pos + Vector3(0, 0, -10.0)
		cam.jump_to(front, false)
		var spawned := 0
		var types := [Unit3D.UnitType.SWORDSMAN, Unit3D.UnitType.ARCHER, Unit3D.UnitType.SPEARMAN, Unit3D.UnitType.CAVALRY, Unit3D.UnitType.VILLAGER]
		for n in unit_steps:
			# top both armies up to n per team, 14 m apart, and send them into each other
			var add: int = n - spawned
			for team in [0, 1]:
				var origin: Vector3 = front + Vector3(0, 0, 7.0 if team == 0 else -7.0)
				for i in add:
					var u = game.spawn_unit(types[(spawned + i) % types.size()], team, origin + Vector3(randf_range(-8, 8), 0, randf_range(-2.5, 2.5)))
					if u != null and team == 1:
						u.command_attack_move(front + Vector3(randf_range(-6, 6), 0, 7.0))
					elif u != null:
						u.command_attack_move(front + Vector3(randf_range(-6, 6), 0, -7.0))
			spawned = n
			await _sample(1.0)                     # settle
			var r := await _sample(seconds)
			var alive := 0
			for u in game.units:
				if is_instance_valid(u) and u.hp > 0:
					alive += 1
			var line := "%s,%s,%s,%d,%d,%.1f,%.2f,%.2f,%.2f,%.2f,%.0f,%.0f" % [tier, look[0], ["low", "medium", "high"][look[1]], n, alive,
				r["fps"], r["avg_ms"], r["p95_ms"], r["p99_ms"], r["physics_ms"], r["draw_calls"], r["primitives"]]
			print("[device] ", line)
			lines.append(line)
		scene.queue_free()
		await _frames(3)
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	quit(0)
