extends SceneTree
## Long full-match playtest on the REAL Main3D scene (needs a display; do NOT run with --headless).
## The player's side is played by an EnemyAI3D on team 0, so a whole match unfolds (economy, ages, armies,
## fights) against the real bots. Every second it logs performance and the match state; at milestones it
## screenshots the portrait screen, including the player-facing army UI (select all, group summary, armed
## attack order, box select).
##
##   godot --path . --resolution 540x960 --script res://scripts/tools/playtest.gd -- \
##       --out=<dir> [--style=2d|3d] [--minutes=14] [--speed=2] [--bots=2] [--size=1] [--civ=0]
## Output: <dir>/<style>_metrics.csv, <dir>/<style>_events.txt, <dir>/<style>_*.png

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")

var out_dir := "user://playtest"
var style := "2d"
var minutes := 14.0
var speed := 2.0
var bots := 2
var size := 1
var civ := 0
var map_seed := -1                     # --seed=N: same map every run (before / after comparisons)
var army_ui := true                     # --army_ui=0: skip the army UI screenshots (pure performance runs)
var game: GameController3D
var events: PackedStringArray = []
var csv: FileAccess

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_dir = a.substr(6)
		elif a.begins_with("--style="): style = a.substr(8)
		elif a.begins_with("--minutes="): minutes = float(a.substr(10))
		elif a.begins_with("--speed="): speed = float(a.substr(8))
		elif a.begins_with("--bots="): bots = int(a.substr(7))
		elif a.begins_with("--size="): size = int(a.substr(7))
		elif a.begins_with("--civ="): civ = int(a.substr(6))
		elif a.begins_with("--army_ui="): army_ui = a.substr(10) != "0"
		elif a.begins_with("--seed="): map_seed = int(a.substr(7))
	call_deferred("_run")

func _log(s: String) -> void:
	var line := "[%5.1f min] %s" % [_game_min(), s]
	events.append(line)
	print("[playtest] ", line)

func _game_min() -> float:
	return game.ai_clock_for_player / 60.0 if game != null and "ai_clock_for_player" in game else _clock / 60.0

var _clock := 0.0          # game seconds (scaled)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _shot(name: String) -> void:
	await _frames(3)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s/%s_%s.png" % [out_dir, style, name])
	_log("screenshot " + name)

func _count(team: int, mil: bool) -> int:
	var n := 0
	for u in game.units:
		if is_instance_valid(u) and u.team == team and u.hp > 0 and ((u.unit_type != Unit3D.UnitType.VILLAGER) == mil):
			n += 1
	return n

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	await _frames(3)
	game = scene as GameController3D
	GraphicsSettings.set_value("style", 1 if style == "2d" else 0)
	# uncapped, so the numbers show the headroom (a phone at 60 Hz has the same budget: 16.7 ms)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	FactionArtManager.use_3d_building_models = style != "2d"

	# --- the new-game screen, as a player would use it
	var menu = game.ui_manager.menu_root
	menu._on_new_game_pressed()
	await _frames(2)
	menu.civ_buttons[civ].emit_signal("pressed")
	menu.map_size_option.select(size); menu.map_size_option.item_selected.emit(size)
	menu._set_bot_count(bots, false)
	menu.difficulty_option.select(1); menu.difficulty_option.item_selected.emit(1)
	await _frames(2)
	await _shot("00_new_game")
	if map_seed >= 0:
		seed(map_seed)
	menu.start_btn.emit_signal("pressed")
	await _frames(5)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	await _frames(5)
	await _shot("01_match_start")
	_log("match: civ %d, %d bots, map size %d (%dx%d), style %s" % [civ, bots, size, game.map_gen.MAP_WIDTH, game.map_gen.MAP_HEIGHT, style])

	# --- the player's side is played by a bot (team 0)
	var pilot := EnemyAI3D.new()
	pilot.name = "PlayerPilot"
	game.add_child(pilot)
	pilot.setup_ai(game.player_civ, game.map_gen, game, EnemyAI3D.Difficulty.NORMAL, 0)

	csv = FileAccess.open("%s/%s_metrics.csv" % [out_dir, style], FileAccess.WRITE)
	csv.store_line("game_s,fps,frame_ms_worst,process_ms,physics_ms,draw_calls,primitives,objects,nodes,mem_mb,p_vill,p_mil,p_bld,e_units,e_bld,player_age,speed")

	Engine.time_scale = speed
	var shots := {1.0: "02_min01", 3.0: "03_min03", 6.0: "05_min06", 9.0: "07_min09", 12.0: "09_min12"}
	var ui_moments := {7.0: false, 11.0: false} if army_ui else {}
	var next_sample := 1.0
	var worst := 0.0
	var frames := 0
	var t_real := 0.0
	var last_age := 1
	while _clock < minutes * 60.0:
		await process_frame
		var d := root.get_process_delta_time()        # game seconds (already scaled by Engine.time_scale)
		var real_d := d / maxf(Engine.time_scale, 0.001)
		t_real += real_d
		_clock += d
		frames += 1
		worst = maxf(worst, real_d * 1000.0)
		if not game.is_game_active:
			_log("match ended (game over screen)")
			await _shot("99_game_over")
			break
		if int(game.team_age.get(0, 1)) != last_age:
			last_age = int(game.team_age.get(0, 1))
			_log("player reached age %d" % last_age)
		if t_real >= next_sample / 1.0 and frames > 0:
			_sample(frames, worst, t_real)
			frames = 0
			worst = 0.0
			next_sample = t_real + 1.0
		for m in shots.keys():
			if _clock >= m * 60.0:
				var nm: String = shots[m]
				shots.erase(m)
				await _shot(nm)
		for m in ui_moments.keys():
			if not ui_moments[m] and _clock >= m * 60.0:
				ui_moments[m] = true
				await _army_ui(m)

	# --- true-speed late game measurement (time scale 1, 20 s)
	Engine.time_scale = 1.0
	_log("late game at 1x: %d player units, %d enemy units, %d buildings total" % [_count(0, false) + _count(0, true), game.units.filter(func(u): return is_instance_valid(u) and u.team != 0).size(), game.buildings.size()])
	var fr := 0
	var tt := 0.0
	var w := 0.0
	var ft: Array = []
	while tt < 20.0:
		await process_frame
		var d := root.get_process_delta_time()
		tt += d; fr += 1; w = maxf(w, d * 1000.0); ft.append(d * 1000.0)
	ft.sort()
	_log("1x late game: avg %.1f fps, p95 frame %.1f ms, worst %.1f ms, draw calls %d" % [fr / tt, ft[int(ft.size() * 0.95)], w, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	await _shot("10_late_game_overview")
	game.camera.target_height = game.camera.max_height
	game.camera.position.y = game.camera.max_height
	await _frames(20)
	await _shot("11_late_game_zoomed_out")
	csv.close()
	var f := FileAccess.open("%s/%s_events.txt" % [out_dir, style], FileAccess.WRITE)
	f.store_string("\n".join(events))
	f.close()
	quit(0)

func _sample(frames: int, worst: float, t_real: float) -> void:
	var fps := Engine.get_frames_per_second()
	var e_units := 0
	var e_bld := 0
	for u in game.units:
		if is_instance_valid(u) and u.team != 0:
			e_units += 1
	var p_bld := 0
	for b in game.buildings:
		if is_instance_valid(b):
			if b.team == 0: p_bld += 1
			else: e_bld += 1
	csv.store_line("%.0f,%.1f,%.1f,%.2f,%.2f,%d,%d,%d,%d,%.0f,%d,%d,%d,%d,%d,%d,%.1f" % [
		_clock, fps, worst,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		_count(0, false), _count(0, true), p_bld, e_units, e_bld, int(game.team_age.get(0, 1)), Engine.time_scale])

## The player's army UI at a moment of the match: select all soldiers (group summary), arm SALDIR,
## then box-select mode with a drag box, then one soldier.
func _army_ui(m: float) -> void:
	var tag := "%02d" % int(m)
	var mil: Array = game.units.filter(func(u): return is_instance_valid(u) and u.team == 0 and u.unit_type != Unit3D.UnitType.VILLAGER)
	_log("army UI check: %d soldiers" % mil.size())
	if mil.is_empty():
		return
	var prev := Engine.time_scale
	Engine.time_scale = 0.05                                   # freeze-ish while we look
	game._on_select_all_military()
	await _frames(4)
	game.camera.jump_to(mil[0].global_position, false)
	await _frames(6)
	await _shot("%s_a_select_all_military" % tag)
	game.ui_manager.army_command_requested.emit("attack")
	await _frames(4)
	await _shot("%s_b_armed_attack" % tag)
	game.pending_army_command = ""
	game._clear_selection()
	game.ui_manager.set_selected_entity(null)
	# box select over the soldiers' screen area
	game.ui_manager.box_select_toggled.emit(true)
	var vp := root.get_viewport().get_visible_rect().size
	game.ui_manager.draw_drag_box(Vector2(vp.x * 0.15, vp.y * 0.30), Vector2(vp.x * 0.85, vp.y * 0.62))
	await _frames(3)
	await _shot("%s_c_box_select" % tag)
	game.ui_manager.hide_drag_box()
	game._select_units_in_screen_rect(Rect2(vp.x * 0.15, vp.y * 0.30, vp.x * 0.7, vp.y * 0.32))
	await _frames(4)
	await _shot("%s_d_box_selected" % tag)
	# control group + type buttons
	game._select_units(mil)
	game.assign_control_group(0)
	if mil.size() > 3:
		game._select_units(mil.slice(0, 3))
		game.assign_control_group(1)
	game._select_units(mil)
	await _frames(4)
	await _shot("%s_e_groups_and_type_buttons" % tag)
	_log("box select picked %d units" % game.selected_units.size())
	game.ui_manager.box_select_toggled.emit(false)
	game._clear_selection()
	game.ui_manager.set_selected_entity(null)
	Engine.time_scale = prev
