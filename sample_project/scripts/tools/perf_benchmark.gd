extends SceneTree
## Rendering benchmark on the REAL Main3D scene (windowed; do not use --headless: that measures
## nothing about rendering). Compares the HD-2D sprite baseline against the 3D-model pipeline.
##
## Usage: godot --path . --script res://scripts/tools/perf_benchmark.gd -- --out=<file.csv> [--civ=0]
## For each art mode (sprites | models) and unit count (0, 20, 50, 80):
##   start a fresh match, place a 10-building player base, spawn N mixed units per team that
##   walk around (pathing + combat AI active), then sample 4 s at default zoom and 4 s at max zoom-out.

const GameController3D = preload("res://scripts/GameController3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

var out_path := "user://perf.csv"
var civ := 0

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_path = a.substr(6)
		elif a.begins_with("--civ="): civ = int(a.substr(6))
	call_deferred("_run")

func _sample(seconds: float) -> Dictionary:
	var frames := 0
	var t := 0.0
	var worst := 0.0
	var dc_sum := 0.0
	var prim_sum := 0.0
	while t < seconds:
		await process_frame
		var dt := root.get_process_delta_time()
		t += dt
		worst = max(worst, dt)
		frames += 1
		dc_sum += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prim_sum += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	return {"fps": frames / t, "worst_ms": worst * 1000.0, "draw_calls": dc_sum / frames, "primitives": prim_sum / frames}

func _find_free(game, center: Vector2i, size: Vector2i, used: Dictionary):
	for r in range(3, 24):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if abs(dx) != r and abs(dy) != r:
					continue
				var o: Vector2i = center + Vector2i(dx, dy)
				var ok := true
				for yy in size.y:
					for xx in size.x:
						var c: Vector2i = o + Vector2i(xx, yy)
						if used.has(c) or not game.map_gen.is_valid_cell(c.x, c.y) or not game.map_gen.is_cell_walkable(c) or not game.map_gen.get_resource_at_cell(c).is_empty():
							ok = false
				if ok:
					for yy in size.y:
						for xx in size.x:
							used[o + Vector2i(xx, yy)] = true
					return o
	return null

func _run() -> void:
	var lines := ["mode,units_per_team,zoom,fps,worst_frame_ms,draw_calls,primitives,buildings,total_units"]
	for mode in ["sprites", "models"]:
		FactionArtManager.use_3d_building_models = (mode == "models")
		for n in [0, 20, 50, 80]:
			var scene = load("res://scenes/Main3D.tscn").instantiate()
			root.add_child(scene)
			await process_frame
			var game = scene as GameController3D
			game._on_start_game_requested(civ, 1, game.selected_map_type)
			seed(12345 + n)
			var used := {}
			var base_cell: Vector2i = game.map_gen.world_to_cell(game.map_gen.player_start_pos)
			for b_type in [Building3D.BuildingType.HOUSE, Building3D.BuildingType.HOUSE, Building3D.BuildingType.HOUSE,
					Building3D.BuildingType.BARRACKS, Building3D.BuildingType.LUMBER_CAMP, Building3D.BuildingType.HOUSE,
					Building3D.BuildingType.BARRACKS, Building3D.BuildingType.HOUSE, Building3D.BuildingType.LUMBER_CAMP]:
				var spot = _find_free(game, base_cell, game._get_building_size(b_type), used)
				if spot != null:
					game.place_building(b_type, 0, spot, false)
			var types = [Unit3D.UnitType.VILLAGER, Unit3D.UnitType.SWORDSMAN, Unit3D.UnitType.ARCHER, Unit3D.UnitType.SPEARMAN, Unit3D.UnitType.CAVALRY]
			for team in [0, 1]:
				var origin: Vector3 = game.map_gen.player_start_pos + Vector3(0, 0, -8.0 if team == 0 else -16.0)
				for i in n:
					var u = game.spawn_unit(types[i % types.size()], team, origin + Vector3(randf_range(-7, 7), 0, randf_range(-3, 3)))
					if u != null:
						u.command_move(origin + Vector3(randf_range(-9, 9), 0, randf_range(-6, 6)))
			var cam = game.camera
			for zoom in [["default", 24.0], ["far", cam.max_height]]:
				cam.target_height = zoom[1]
				cam.position.y = zoom[1]
				cam.jump_to(game.map_gen.player_start_pos + Vector3(0, 0, -8.0), false)
				await _sample(1.0)  # settle
				var r: Dictionary = await _sample(4.0)
				var line := "%s,%d,%s,%.1f,%.1f,%.0f,%.0f,%d,%d" % [mode, n, zoom[0], r["fps"], r["worst_ms"], r["draw_calls"], r["primitives"], game.buildings.size(), game.units.size()]
				print("[perf] ", line)
				lines.append(line)
			scene.queue_free()
			await process_frame
			await process_frame
	FactionArtManager.use_3d_building_models = true
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("[perf] wrote ", out_path)
	quit(0)
