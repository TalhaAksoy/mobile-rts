extends SceneTree
## Map sizes and more bots (new-game screen: Küçük = 1 bot, Orta = up to 3, Büyük = up to 5):
##  * every size generates at its dimensions with one base per team, far apart, on dry level ground,
##    each with a Town Center, 3 villagers and its own civ; every bot base can be walked to
##  * Small with one bot is the original 1v1 layout (player bottom centre, bot top centre)
##  * the bot count is capped by the map size; the new-game screen follows it and passes the setup on
##  * every team has its own colour (3D team trim, minimap)
##  * a bot that loses its Town Center is out; the match is won when the last bot is out
##  * a saved game brings back the map size, every bot (civ, resources, age, clock, out or not)
##  * five bots on the large map build up their economy and armies for 150 game seconds
## The player's quick save is backed up and restored.
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

func _start(game, size: int, bots: int, map_type: int = CivData.MapType.FOREST_VALLEY, civs: Array = []) -> void:
	game.map_size = size
	game.bot_count = bots
	game.bot_civs = civs
	game._on_start_game_requested(CivData.CivType.OTTOMANS, CivData.CivType.BYZANTINES, map_type)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()

func _tc_of(game, team: int) -> Building3D:
	for b in game.buildings:
		if is_instance_valid(b) and b.team == team and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			return b
	return null

func _check_layout(game, size: int, bots: int, label: String) -> void:
	var mg: MapGenerator3D = game.map_gen
	var dims: Vector2i = MapGenerator3D.MAP_SIZE_DIMS[size]
	_check(mg.MAP_WIDTH == dims.x and mg.MAP_HEIGHT == dims.y and mg.tiles.size() == dims.x and mg.tiles[0].size() == dims.y,
		"%s: map is %dx%d" % [label, dims.x, dims.y])
	_check(mg.start_positions.size() == bots + 1 and game.bot_ais.size() == bots, "%s: %d bases, %d bot AIs" % [label, bots + 1, bots])
	var min_d := INF
	for i in mg.start_positions.size():
		for j in range(i + 1, mg.start_positions.size()):
			min_d = minf(min_d, Vector2(mg.world_to_cell(mg.start_positions[i])).distance_to(Vector2(mg.world_to_cell(mg.start_positions[j]))))
	_check(min_d >= 24.0, "%s: bases at least 24 cells apart (closest %.1f)" % [label, min_d])
	var civs := {}
	var all_ok := true
	var reach_ok := true
	for t in range(bots + 1):
		var tc := _tc_of(game, t)
		var vills := 0
		for u in game.units:
			if is_instance_valid(u) and u.team == t and u.unit_type == Unit3D.UnitType.VILLAGER:
				vills += 1
		var dry := true
		if tc != null:
			for dx in tc.grid_size.x:
				for dy in tc.grid_size.y:
					var c: Vector2i = tc.origin_cell + Vector2i(dx, dy)
					dry = dry and mg.tiles[c.x][c.y] != MapGenerator3D.TileType.WATER and mg.tiles[c.x][c.y] != MapGenerator3D.TileType.SHALLOW_WATER
		all_ok = all_ok and tc != null and vills == 3 and dry and tc.civ_type == game.civ_of(t)
		civs[game.civ_of(t)] = true
		if t > 0 and tc != null:
			var ai: EnemyAI3D = game.get_bot_ai(t)
			all_ok = all_ok and ai != null and ai.team == t and ai.civ_type == game.civ_of(t) and not ai.eliminated
			# a soldier from the player's base can walk next to this bot's Town Center
			var path: Array = mg.get_path_to_target(mg.player_start_pos + Vector3(0, 0, 4), tc.global_position + Vector3(0, 0, 4.5))
			reach_ok = reach_ok and not path.is_empty() and Vector2(path[-1].x, path[-1].z).distance_to(Vector2(tc.global_position.x, tc.global_position.z + 4.5)) < 4.5
	_check(all_ok, "%s: every team has a Town Center on dry ground, 3 villagers, its civ and its own AI" % label)
	_check(civs.size() == bots + 1, "%s: every team plays a different civ" % label)
	_check(reach_ok, "%s: every bot base can be walked to from the player's base" % label)

func _run() -> void:
	var save_text = null
	if FileAccess.file_exists(SaveManager.AUTO_SAVE_FILE):
		save_text = FileAccess.get_file_as_string(SaveManager.AUTO_SAVE_FILE)

	var cfg_text = null
	if FileAccess.file_exists(GraphicsSettings.PATH):
		cfg_text = FileAccess.get_file_as_string(GraphicsSettings.PATH)

	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	await _frames(2)
	var game = scene as GameController3D

	# --- new-game screen: map size sets the opponent limit, the match gets what was picked
	var menu = game.ui_manager.menu_root
	menu._on_new_game_pressed()
	await _frames(2)
	menu.map_size_buttons[MapGenerator3D.MapSize.LARGE].emit_signal("pressed")
	await _frames(1)
	var rows_shown := 0
	for r in menu.bots_box.get_children():
		if r.visible:
			rows_shown += 1
	_check(menu.selected_map_size == 2 and menu.selected_bot_count == 5 and rows_shown == 5 and menu.bot_plus_btn.disabled,
		"Büyük: 5 opponents, 5 rows with a civ picker each, + disabled")
	menu.bot_minus_btn.emit_signal("pressed")
	await _frames(1)
	menu.bot_civ_options[1].select(menu.bot_civ_options[1].get_item_index(CivData.CivType.MONGOLS))
	_check(menu.selected_bot_count == 4 and menu.bot_count_label.text == "4" and not menu.bots_box.get_child(4).visible, "− makes it 4 opponents")
	menu.map_size_buttons[MapGenerator3D.MapSize.SMALL].emit_signal("pressed")
	await _frames(1)
	_check(menu.selected_bot_count == 1 and menu.bot_minus_btn.disabled and menu.bot_plus_btn.disabled, "Küçük: 1 opponent, the stepper is locked")
	menu.map_size_buttons[MapGenerator3D.MapSize.MEDIUM].emit_signal("pressed")
	menu.bot_minus_btn.emit_signal("pressed")
	await _frames(1)
	menu.bot_civ_options[1].select(menu.bot_civ_options[1].get_item_index(CivData.CivType.MONGOLS))
	menu.start_btn.emit_signal("pressed")
	await _frames(3)
	_check(game.is_game_active and game.map_size == MapGenerator3D.MapSize.MEDIUM and game.bot_count == 2 and game.map_gen.MAP_WIDTH == 48
		and game.bot_ais.size() == 2 and game.civ_of(2) == CivData.CivType.MONGOLS,
		"Seferi Başlat: medium map, 2 bots, bot 2 plays the Mongols")
	var cfg := ConfigFile.new()
	cfg.load(GraphicsSettings.PATH)
	_check(int(cfg.get_value("game", "map_size", -1)) == 1 and int(cfg.get_value("game", "bot_count", -1)) == 2, "map size and opponent count are remembered")

	# --- sizes and bases
	seed(4242)
	_start(game, MapGenerator3D.MapSize.SMALL, 1)
	_check(game.map_gen.world_to_cell(game.map_gen.player_start_pos) == Vector2i(16, 48) and game.map_gen.world_to_cell(game.map_gen.enemy_start_pos) == Vector2i(16, 10),
		"Küçük, 1 bot: the original layout (player 16,48 / bot 16,10)")
	_check_layout(game, MapGenerator3D.MapSize.SMALL, 1, "Küçük 1 bot")
	_start(game, MapGenerator3D.MapSize.SMALL, 4)
	_check(game.bot_count == 1 and game.bot_ais.size() == 1, "Küçük: asking for 4 bots gives 1 (the size's limit)")
	for mt in [CivData.MapType.FOREST_VALLEY, CivData.MapType.RIVER_CROSSING, CivData.MapType.DESERT_OASIS]:
		_start(game, MapGenerator3D.MapSize.MEDIUM, 3, mt)
		_check_layout(game, MapGenerator3D.MapSize.MEDIUM, 3, "Orta 3 bot, %s" % CivData.get_map_config(mt).get("name", str(mt)))
	_start(game, MapGenerator3D.MapSize.MEDIUM, 2)
	_check_layout(game, MapGenerator3D.MapSize.MEDIUM, 2, "Orta 2 bot")
	for mt in [CivData.MapType.HIGHLAND_PLAINS, CivData.MapType.GOLD_RUSH, CivData.MapType.FOREST_VALLEY]:
		_start(game, MapGenerator3D.MapSize.LARGE, 5, mt)
		_check_layout(game, MapGenerator3D.MapSize.LARGE, 5, "Büyük 5 bot, %s" % CivData.get_map_config(mt).get("name", str(mt)))
	_check(MapGenerator3D.max_bots_for(0) == 1 and MapGenerator3D.max_bots_for(1) == 3 and MapGenerator3D.max_bots_for(2) == 5, "bot limits: Küçük 1, Orta 3, Büyük 5")

	# chosen bot civs are used, the rest random
	_start(game, MapGenerator3D.MapSize.MEDIUM, 3, CivData.MapType.FOREST_VALLEY, [CivData.CivType.VIKINGS, -1, CivData.CivType.JAPANESE])
	_check(game.civ_of(1) == CivData.CivType.VIKINGS and game.civ_of(3) == CivData.CivType.JAPANESE and game.enemy_civ == CivData.CivType.VIKINGS,
		"bot civs picked on the new-game screen are used (bot 1 Vikingler, bot 3 Japonlar)")

	# --- team colours
	var cols := {}
	for t in 6:
		cols[FactionArtManager.team_color(t).to_html()] = true
	_check(cols.size() == 6, "six different team colours")
	var tc3 := _tc_of(game, 3)
	var trim_ok := false
	if tc3 != null and FactionArtManager.use_3d_building_models:
		for mi in tc3.find_children("*", "MeshInstance3D", true, false):
			for i in (mi as MeshInstance3D).get_surface_override_material_count():
				var m = (mi as MeshInstance3D).get_surface_override_material(i)
				if m is StandardMaterial3D and String(m.resource_name).begins_with("TEAM_Trim"):
					trim_ok = trim_ok or (m as StandardMaterial3D).albedo_color.is_equal_approx(FactionArtManager.TEAM_COLORS[3])
	_check(trim_ok, "bot 3's Town Center wears team colour 3 (%s)" % FactionArtManager.TEAM_COLOR_NAMES[3])

	# --- elimination and victory
	for ai in game.bot_ais:
		ai.set_process(false)
	_tc_of(game, 1).take_damage(1e9, 0)
	await _frames(3)
	_check(game.is_game_active and game.get_bot_ai(1).eliminated and game.bots_alive() == 2, "bot 1 loses its Town Center: it is out, the match goes on")
	_tc_of(game, 2).take_damage(1e9, 0)
	await _frames(3)
	_check(game.is_game_active and game.bots_alive() == 1, "bot 2 out: one bot left, still playing")
	_tc_of(game, 3).take_damage(1e9, 0)
	await _frames(3)
	_check(not game.is_game_active and game.ui_manager.game_over_modal.visible, "last bot out: victory screen")

	# --- save / load
	seed(77)
	_start(game, MapGenerator3D.MapSize.MEDIUM, 3)
	for ai in game.bot_ais:
		ai.set_process(false)
	var civs_before: Dictionary = game.team_civs.duplicate()
	var seed_before: int = game.map_gen.seed_val
	var bases_before: Array = game.map_gen.start_positions.duplicate()
	game.team_resources[3]["gold"] = 777
	game.team_age[2] = 2
	game.bot_ais[2].ai_clock = 123.0
	_tc_of(game, 1).take_damage(1e9, 0)
	await _frames(3)
	_check(SaveManager.save_game(game), "saved a medium map with 3 bots")
	_start(game, MapGenerator3D.MapSize.SMALL, 1)
	_check(game.map_gen.MAP_WIDTH == 32, "(another match on a small map in between)")
	_check(SaveManager.load_game(game), "loaded it")
	await _frames(2)   # (the loaded bots play on: their clocks move a few frames)
	_check(game.map_size == MapGenerator3D.MapSize.MEDIUM and game.map_gen.MAP_WIDTH == 48 and game.map_gen.seed_val == seed_before
		and game.map_gen.start_positions == bases_before, "map size, seed and bases are back")
	var civ_ok: bool = game.bot_count == 3 and game.bot_ais.size() == 3
	for t in range(4):
		civ_ok = civ_ok and game.civ_of(t) == civs_before[t]
	for t in range(1, 4):
		civ_ok = civ_ok and game.get_bot_ai(t).team == t and game.get_bot_ai(t).civ_type == civs_before[t]
	_check(civ_ok, "3 bots with their civs and AIs are back")
	_check(int(game.team_resources[3]["gold"]) == 777 and game.team_age[2] == 2 and absf(game.bot_ais[2].ai_clock - 123.0) < 1.0,
		"bot 3's gold, bot 2's age and bot 3's clock are back (%s / %s / %s)" % [game.team_resources[3]["gold"], game.team_age[2], game.bot_ais[2].ai_clock])
	_check(game.get_bot_ai(1).eliminated and _tc_of(game, 1) == null and game.bots_alive() == 2, "the bot that was out stays out")

	# --- five bots play on the large map
	seed(5150)
	game.ai_difficulty = EnemyAI3D.Difficulty.NORMAL
	_start(game, MapGenerator3D.MapSize.LARGE, 5, CivData.MapType.HIGHLAND_PLAINS)
	game.enemy_ai.set_process(true)   # the scene's bot node was paused for the checks above
	Engine.time_scale = 8.0
	var t0 := Time.get_ticks_msec()
	while game.bot_ais[0].ai_clock < 150.0 and game.is_game_active and Time.get_ticks_msec() - t0 < 600000:
		await physics_frame
	Engine.time_scale = 1.0
	var grew := 0
	var built := 0
	var report := []
	for t in range(1, 6):
		var n_units := 0
		var n_b := 0
		for u in game.units:
			if is_instance_valid(u) and u.team == t:
				n_units += 1
		for b in game.buildings:
			if is_instance_valid(b) and b.team == t:
				n_b += 1
		if n_units > 3:
			grew += 1
		if n_b > 1:
			built += 1
		report.append("%d:%du/%db" % [t, n_units, n_b])
	_check(game.bot_ais[0].ai_clock >= 150.0, "150 game seconds with 5 bots ran (%.0f s)" % game.bot_ais[0].ai_clock)
	_check(grew == 5 and built == 5, "every bot trained units and built (%s)" % ", ".join(report))

	scene.queue_free()
	await _frames(2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GraphicsSettings.PATH))
	if cfg_text != null:
		var cf := FileAccess.open(GraphicsSettings.PATH, FileAccess.WRITE)
		cf.store_string(cfg_text)
		cf.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.AUTO_SAVE_FILE))
	if save_text != null:
		var f := FileAccess.open(SaveManager.AUTO_SAVE_FILE, FileAccess.WRITE)
		f.store_string(save_text)
		f.close()
	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)
