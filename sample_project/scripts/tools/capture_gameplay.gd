extends SceneTree
## Real-game screenshot capture (requires a display; do NOT run with --headless).
##
## Loads the actual Main3D scene, starts a real match, lets the simulation run,
## then captures the live viewport at several camera zoom levels.
##
## Usage:
##   godot --path . --script res://scripts/tools/capture_gameplay.gd -- \
##       --out=<dir> [--civ=0] [--enemy=1] [--seconds=6] [--tag=baseline]
##
## Output files: <out>/<tag>_<civ>_<view>.png plus <out>/<tag>_<civ>_fps.txt

const GameController3D = preload("res://scripts/GameController3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")
const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

var out_dir := "user://captures"
var civ := 0
var enemy := 1
var seconds := 6.0
var tag := "capture"
var showcase: PackedStringArray = []   # e.g. --showcase=house,barracks,lumber_camp
var look_at := ""                      # building id to centre the camera on (default: base)
var map_seed := -1                     # --seed=N: same map every run (before/after comparisons)
var upgrade_all := false               # --upgrade=1: grant every building upgrade (level 2 look) to team 0
var n_fields := 0                      # --fields=N: with --showcase=mill, add N finished fields + farmers
var map_type := -1                     # --map=0 forest valley, 1 desert oasis

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_dir = a.substr(6)
		elif a.begins_with("--civ="): civ = int(a.substr(6))
		elif a.begins_with("--enemy="): enemy = int(a.substr(8))
		elif a.begins_with("--seconds="): seconds = float(a.substr(10))
		elif a.begins_with("--tag="): tag = a.substr(6)
		elif a.begins_with("--showcase="): showcase = a.substr(11).split(",")
		elif a.begins_with("--look="): look_at = a.substr(7)
		elif a.begins_with("--seed="): map_seed = int(a.substr(7))
		elif a.begins_with("--map="): map_type = int(a.substr(6))
		elif a.begins_with("--fields="): n_fields = int(a.substr(9))
		elif a.begins_with("--upgrade="): upgrade_all = a.substr(10) == "1"
	call_deferred("_run")

func _wait(sec: float) -> void:
	var t := 0.0
	while t < sec:
		await process_frame
		t += root.get_process_delta_time()

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var path := "%s/%s_%d_%s.png" % [out_dir, tag, civ, name]
	img.save_png(path)
	print("[capture] saved ", path)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var game = scene as GameController3D
	if map_seed >= 0:
		seed(map_seed)
	game._on_start_game_requested(civ, enemy, game.selected_map_type if map_type < 0 else map_type)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()

	# Optional: place completed player buildings near the base (free cells only) for art review.
	var placed := {}
	for b_id in showcase:
		var b_type := -1
		for t in Building3D.BuildingType.values():
			if FactionArtManager.get_building_id_from_type(t) == b_id:
				b_type = t
		if b_type < 0:
			continue
		var size: Vector2i = game._get_building_size(b_type)
		var spot = null
		if b_id == "mill" and n_fields > 0:
			# a mill that will get fields needs its 6x6 ring free
			spot = _find_free_area(game, game.map_gen.world_to_cell(game.map_gen.player_start_pos), Vector2i(6, 6))
			if spot != null:
				spot += Vector2i(2, 2)
		if spot == null:
			spot = _find_free_area(game, game.map_gen.world_to_cell(game.map_gen.player_start_pos), size)
		if spot != null:
			placed[b_id] = game.place_building(b_type, 0, spot, false)
			print("[capture] placed ", b_id, " at ", spot)

	if n_fields > 0 and placed.has("mill"):
		var mill = placed["mill"]
		game.team_resources[0]["wood"] += 50 * n_fields
		for i in n_fields:
			var f = game.try_add_field(mill, 0)
			if f != null:
				f.contribute_construction(200.0)
		var vills: Array = game.units.filter(func(u): return u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER)
		print("[capture] fields=", game.get_mill_fields(mill).size(), " farmers=", game.send_villagers_to_fields(vills, 0, mill.global_position))

	if upgrade_all:
		for id in TechData.TECHS.keys():
			for e in TechData.get_tech(id)["effects"]:
				if e["type"] == "level":
					game._on_building_research_completed(id, 0)
					break

	# Let the match simulate (villagers gather, AI starts).
	await _wait(seconds)

	# FPS sample over 3 seconds at default zoom
	var frames := 0
	var t := 0.0
	while t < 3.0:
		await process_frame
		t += root.get_process_delta_time()
		frames += 1
	var fps_txt := "avg_fps=%.1f frames=%d engine_fps=%d draw_calls=%d primitives=%d\n" % [
		frames / t, frames, Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)]
	var f := FileAccess.open("%s/%s_%d_fps.txt" % [out_dir, tag, civ], FileAccess.WRITE)
	f.store_string(fps_txt)
	f.close()
	print("[capture] ", fps_txt)

	var cam = game.camera
	var base_pos = game.map_gen.player_start_pos
	if look_at != "" and placed.has(look_at):
		base_pos = placed[look_at].global_position
	for view in [["default", 24.0], ["close", cam.min_height], ["far", cam.max_height]]:
		cam.target_height = view[1]
		cam.position.y = view[1]
		cam.jump_to(base_pos, false)
		await _wait(0.6)
		await _shot(view[0])
	quit(0)


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
