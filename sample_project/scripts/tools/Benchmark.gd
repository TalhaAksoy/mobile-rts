extends Node
## Fixed-scenario performance run (device, emulator or desktop).
##
## Becomes the main scene in builds exported with the custom feature "benchmark"
## (project setting `application/run/main_scene.benchmark`), so the normal game is unchanged.
## Desktop: godot --path . res://scenes/Benchmark.tscn
##
## Every phase rebuilds the same match (seed, map, civs) with one of every building type,
## a mill with six farmed fields, then measures for MEASURE_S seconds after a warm-up:
## average FPS, median / 99th-percentile frame time, draw calls, primitives, memory.
## Results: one `PE_BENCH {json}` line per phase on stdout (logcat on Android, tag "godot"),
## user://benchmark.json, and an on-screen table.

const GameController3D = preload("res://scripts/GameController3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")
const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

const SEED := 5
const MAP := 0
const CIV := 2            # Britons
const ENEMY := 6          # Japanese
const WARMUP_S := 4.0
const MEASURE_S := 15.0
const SHOWCASE := ["house", "barracks", "archery_range", "stable", "blacksmith", "lumber_camp",
		"mining_camp", "watch_tower", "castle", "mill"]

## Every phase starts from a GraphicsSettings preset ("preset", default HIGH = the look before the
## settings menu existed) and may override single options. The fps cap is always lifted while measuring.
const PHASES := [
	{"name": "base_models", "models": true, "height": 24.0, "battle": false},
	{"name": "base_models_far", "models": true, "height": -1.0, "battle": false},
	{"name": "base_models_noshadow", "models": true, "height": 24.0, "battle": false, "shadows": 0},
	{"name": "base_sprites", "models": false, "height": 24.0, "battle": false},
	{"name": "base_models_scale50", "models": true, "height": 24.0, "battle": false, "scale": 50},
	{"name": "base_models_nomsaa", "models": true, "height": 24.0, "battle": false, "msaa": 0},
	{"name": "preset_low", "preset": 0, "height": 24.0, "battle": false},
	{"name": "preset_medium", "preset": 1, "height": 24.0, "battle": false},
	{"name": "preset_high", "preset": 2, "height": 24.0, "battle": false},
	{"name": "battle_models", "models": true, "height": 24.0, "battle": true},
]

var results: Array = []
var label: Label

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	label = Label.new()
	label.position = Vector2(8, 120)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	layer.add_child(label)
	_run.call_deferred()

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _run() -> void:
	var info := {"device": OS.get_model_name(), "os": OS.get_name(), "renderer": RenderingServer.get_video_adapter_name(),
		"vendor": RenderingServer.get_video_adapter_vendor(), "api": RenderingServer.get_video_adapter_api_version(),
		"cpu": OS.get_processor_name(), "cores": OS.get_processor_count(),
		"window": str(DisplayServer.window_get_size()), "vsync": DisplayServer.window_get_vsync_mode()}
	print("PE_BENCH_INFO ", JSON.stringify(info))
	for p in PHASES:
		label.text = "Benchmark: %s ..." % p["name"]
		var r: Dictionary = await _phase(p)
		results.append(r)
		print("PE_BENCH ", JSON.stringify(r))
		label.text = _table()
	FactionArtManager.use_3d_building_models = true
	GraphicsSettings.load_settings()          # back to the user's saved choice (the benchmark never saves)
	var f := FileAccess.open("user://benchmark.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"info": info, "phases": results}, "  "))
		f.close()
	print("PE_BENCH_DONE")
	label.text = _table() + "\nBİTTİ"
	await _wait(3.0)
	get_tree().quit()

func _table() -> String:
	var s := "phase                 fps   p50ms  p99ms  draws  prims\n"
	for r in results:
		s += "%-20s %5.1f %6.1f %6.1f %6d %6dk\n" % [r["name"], r["avg_fps"], r["p50_ms"], r["p99_ms"], r["draw_calls"], r["primitives"] / 1000]
	return s

func _phase(p: Dictionary) -> Dictionary:
	FactionArtManager._model_cache.clear()
	seed(SEED)
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var game = scene as GameController3D
	# graphics BEFORE the match starts: the style (3D models / 2D sprites) is read when buildings and
	# map props are created
	var light := scene.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	var vp := get_viewport()
	GraphicsSettings.set_preset(p.get("preset", GraphicsSettings.Preset.HIGH))
	for k in ["scale", "msaa", "shadows"]:
		if p.has(k):
			GraphicsSettings.set_value(k, p[k])      # a single override is a Custom setting
	if p.has("models") and int(GraphicsSettings.values["style"]) != (0 if p["models"] else 1):
		GraphicsSettings.set_value("style", 0 if p["models"] else 1)
	GraphicsSettings.apply(vp, light)
	Engine.max_fps = 0
	seed(SEED)
	game._on_start_game_requested(CIV, ENEMY, MAP)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	game.enemy_ai.set_process(false)
	game.enemy_ai.set_physics_process(false)
	Engine.max_fps = 0
	_build_base(game)
	if p["battle"]:
		_start_battle(game)
	var cam = game.camera
	var h: float = cam.max_height if p["height"] < 0.0 else p["height"]
	cam.target_height = h
	cam.position.y = h
	cam.jump_to(game.map_gen.player_start_pos, false)
	await _wait(WARMUP_S if not p["battle"] else 1.0)
	var units_start := 0
	for u in game.units:
		if is_instance_valid(u):
			units_start += 1

	var deltas: PackedFloat32Array = []
	var draws := 0.0
	var prims := 0.0
	var t := 0.0
	while t < MEASURE_S:
		await get_tree().process_frame
		var d := get_process_delta_time()
		deltas.append(d)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		t += d
	var n := deltas.size()
	var sorted := deltas.duplicate()
	sorted.sort()
	var units := 0
	for u in game.units:
		if is_instance_valid(u):
			units += 1
	var r := {
		"name": p["name"], "frames": n, "seconds": snappedf(t, 0.01),
		"avg_fps": snappedf(n / t, 0.1),
		"p50_ms": snappedf(sorted[n / 2] * 1000.0, 0.1),
		"p99_ms": snappedf(sorted[min(n - 1, int(n * 0.99))] * 1000.0, 0.1),
		"max_ms": snappedf(sorted[n - 1] * 1000.0, 0.1),
		"draw_calls": int(draws / n), "primitives": int(prims / n),
		"video_mem_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"static_mem_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"buildings": game.buildings.size(), "units_start": units_start, "units_end": units,
		"models": FactionArtManager.use_3d_building_models, "preset": GraphicsSettings.PRESET_NAMES[GraphicsSettings.preset],
		"scale": GraphicsSettings.values["scale"], "msaa": GraphicsSettings.values["msaa"],
		"shadows": GraphicsSettings.values["shadows"],
		"render_size": str(vp.get_visible_rect().size),
	}
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	return r

func _build_base(game) -> void:
	var base: Vector2i = game.map_gen.world_to_cell(game.map_gen.player_start_pos)
	var mill = null
	for b_id in SHOWCASE:
		var b_type := -1
		for t in Building3D.BuildingType.values():
			if FactionArtManager.get_building_id_from_type(t) == b_id:
				b_type = t
		var size: Vector2i = game._get_building_size(b_type)
		var spot = null
		if b_id == "mill":
			spot = _find_free_area(game, base, Vector2i(6, 6))
			if spot != null:
				spot += Vector2i(2, 2)
		else:
			spot = _find_free_area(game, base, size)
		if spot != null:
			var b = game.place_building(b_type, 0, spot, false)
			if b_id == "mill":
				mill = b
	if mill != null:
		game.team_resources[0]["wood"] += 50 * 6
		for i in 6:
			var f = game.try_add_field(mill, 0)
			if f != null:
				f.contribute_construction(200.0)
		var vills: Array = game.units.filter(func(u): return u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER)
		game.send_villagers_to_fields(vills, 0, mill.global_position)

func _start_battle(game) -> void:
	var c: Vector3 = game.map_gen.player_start_pos + Vector3(0, 0, 9)
	var types := [Unit3D.UnitType.SWORDSMAN, Unit3D.UnitType.ARCHER, Unit3D.UnitType.SPEARMAN, Unit3D.UnitType.CAVALRY]
	var reds: Array = []
	var blues: Array = []
	for i in 30:
		blues.append(game.spawn_unit(types[i % 4], 0, c + Vector3(-6 + (i % 6) * 1.2, 0, -2 - (i / 6) * 1.2)))
		reds.append(game.spawn_unit(types[i % 4], 1, c + Vector3(-6 + (i % 6) * 1.2, 0, 8 + (i / 6) * 1.2)))
	for i in reds.size():
		if is_instance_valid(reds[i]) and is_instance_valid(blues[i]):
			reds[i].command_attack(blues[i])
			blues[i].command_attack(reds[i])

func _find_free_area(game, center: Vector2i, size: Vector2i):
	for r in range(3, 22):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if abs(dx) != r and abs(dy) != r:
					continue
				var o := center + Vector2i(dx, dy)
				var ok := true
				for yy in range(0, size.y):
					for xx in range(0, size.x):
						var c := o + Vector2i(xx, yy)
						if not game.map_gen.is_valid_cell(c.x, c.y) or not game.map_gen.is_cell_buildable(c) or not game.map_gen.get_resource_at_cell(c).is_empty():
							ok = false
				if ok:
					return o
	return null
