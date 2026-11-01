extends SceneTree
## Enemy bot difficulty (Kolay / Orta / Zor), picked on the civ select screen before the match:
##  * the screen has a Zorluk row with three buttons and a hint; first launch selects Kolay
##  * the choice is remembered (settings.cfg) and reaches the match's bot
##  * against a passive player (Highland, the map where the old bot destroyed the TC before minute 4):
##    no enemy soldier reaches the player's base before ~minute 8 (Kolay) / ~5 (Orta); Kolay's waves
##    are small and even a passive player's TC lasts past minute 9; Zor attacks hard at minute 3 and
##    takes a passive player's TC before minute 5
##  * the bot's army stays within the difficulty's size (soldiers in training counted)
##  * a saved game keeps its difficulty and the bot's clock (no fresh grace period after loading)
## The player's settings.cfg and quick save are backed up and restored.
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

func _backup(path: String) -> Variant:
	if FileAccess.file_exists(path):
		var t := FileAccess.get_file_as_string(path)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return t
	return null

func _restore(path: String, text: Variant) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if text != null:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(text)
		f.close()

## Runs a match against a passive player for `secs` game seconds. Returns the time the first enemy
## soldier came within 16 m of the player's TC, the most at once, the largest enemy army and whether
## the TC is still standing.
func _passive_match(game, diff: int, secs: float) -> Dictionary:
	seed(910)
	game.ai_difficulty = diff
	game._on_start_game_requested(0, 1, CivData.MapType.HIGHLAND_PLAINS)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	Engine.time_scale = 8.0
	var base: Vector3 = game.map_gen.player_start_pos
	var res := {"first": -1.0, "max_near": 0, "max_army": 0, "tc_alive": true, "tc_lost_at": -1.0}
	while game.enemy_ai.ai_clock < secs and game.is_game_active:
		await physics_frame
		if not game.is_game_active:
			res["tc_lost_at"] = game.enemy_ai.ai_clock
		var near := 0
		var army := 0
		for u in game.units:
			if is_instance_valid(u) and u.team == 1 and u.unit_type != Unit3D.UnitType.VILLAGER:
				army += 1
				if Vector2(u.global_position.x - base.x, u.global_position.z - base.z).length() < 16.0:
					near += 1
		if near > 0 and res["first"] < 0:
			res["first"] = game.enemy_ai.ai_clock
		res["max_near"] = maxi(res["max_near"], near)
		res["max_army"] = maxi(res["max_army"], army)
	var tc_alive := false
	for b in game.buildings:
		if is_instance_valid(b) and b.team == 0 and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			tc_alive = true
	res["tc_alive"] = tc_alive and game.is_game_active
	Engine.time_scale = 1.0
	return res

func _run() -> void:
	var cfg_text = _backup(GraphicsSettings.PATH)
	var save_text = _backup(SaveManager.AUTO_SAVE_FILE)

	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	var game = scene as GameController3D
	var menu = game.ui_manager.menu_root
	var P: Dictionary = EnemyAI3D.PROFILES

	# --- the Zorluk row
	menu._on_new_game_pressed()
	await _frames(2)
	var btns: Array = menu.difficulty_buttons
	_check(btns.size() == 3 and btns[0].text == "Kolay" and btns[1].text == "Orta" and btns[2].text == "Zor" and btns[0].is_visible_in_tree(),
		"civ select shows Zorluk: Kolay / Orta / Zor")
	_check(menu.selected_difficulty == EnemyAI3D.Difficulty.EASY and btns[0].button_pressed and not btns[2].button_pressed, "first launch selects Kolay")
	_check(menu.difficulty_hint.text == EnemyAI3D.DIFFICULTY_HINTS[0], "hint explains Kolay (%s)" % menu.difficulty_hint.text)
	btns[2].emit_signal("pressed")
	await _frames(1)
	_check(menu.selected_difficulty == EnemyAI3D.Difficulty.HARD and btns[2].button_pressed and not btns[0].button_pressed, "tapping Zor selects it (one button active)")
	var cfg := ConfigFile.new()
	cfg.load(GraphicsSettings.PATH)
	_check(int(cfg.get_value("game", "difficulty", -1)) == EnemyAI3D.Difficulty.HARD, "the choice is saved in settings.cfg")
	menu.start_btn.emit_signal("pressed")
	await _frames(3)
	_check(game.is_game_active and game.ai_difficulty == EnemyAI3D.Difficulty.HARD and game.enemy_ai.profile == P[EnemyAI3D.Difficulty.HARD],
		"SEFERİ BAŞLAT: the match's bot plays Zor")

	# a new menu (next launch) remembers Zor
	var scene2 = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene2)
	await _frames(2)
	_check(scene2.ui_manager.menu_root.selected_difficulty == EnemyAI3D.Difficulty.HARD, "next launch remembers Zor")
	scene2.free()

	# --- save / load keeps the difficulty and the bot's clock
	game.ai_difficulty = EnemyAI3D.Difficulty.EASY
	seed(5)
	game.start_match()
	game.enemy_ai.ai_clock = 200.0
	game.enemy_ai.next_attack_at = 480.0
	_check(SaveManager.save_game(game), "saved")
	game.ai_difficulty = EnemyAI3D.Difficulty.HARD
	seed(6)
	game.start_match()
	SaveManager.load_game(game)
	await _frames(2)
	_check(game.ai_difficulty == EnemyAI3D.Difficulty.EASY and game.enemy_ai.profile == P[EnemyAI3D.Difficulty.EASY], "loaded game plays its saved difficulty (Kolay)")
	_check(game.enemy_ai.ai_clock >= 200.0 and is_equal_approx(game.enemy_ai.next_attack_at, 480.0), "and keeps the bot's clock (%.0f s, next wave at %.0f s)" % [game.enemy_ai.ai_clock, game.enemy_ai.next_attack_at])

	# --- behaviour against a passive player
	var easy := await _passive_match(game, EnemyAI3D.Difficulty.EASY, 600.0)
	print("  Kolay: ", easy)
	# fixed numbers (what the on-screen hints promise), not the profile values, so a profile change
	# that makes a level harsher fails here
	_check(easy["first"] < 0 or easy["first"] >= 450.0, "Kolay: no soldier at the base before ~minute 8 (first at %.0f s)" % easy["first"])
	_check(easy["max_near"] <= 6, "Kolay: small waves (at most %d soldiers at the base at once)" % easy["max_near"])
	_check(easy["max_army"] <= 10, "Kolay: army stays small (largest %d)" % easy["max_army"])
	_check(easy["tc_lost_at"] < 0 or (easy["tc_lost_at"] >= 540.0 and easy["tc_lost_at"] - easy["first"] >= 60.0),
		"Kolay: even a passive player's Town Center stands past minute 9 and holds over a minute (lost at %.0f s)" % easy["tc_lost_at"])

	var normal := await _passive_match(game, EnemyAI3D.Difficulty.NORMAL, 330.0)
	print("  Orta: ", normal)
	_check(normal["first"] < 0 or normal["first"] >= 280.0, "Orta: no soldier at the base before ~minute 5 (first at %.0f s)" % normal["first"])
	_check(normal["max_army"] <= 16 and normal["max_near"] <= 12, "Orta: medium army and waves (largest %d, at most %d at the base)" % [normal["max_army"], normal["max_near"]])

	var hard := await _passive_match(game, EnemyAI3D.Difficulty.HARD, 300.0)   # the TC check below is "before minute 5"
	print("  Zor: ", hard)
	_check(hard["first"] >= 170.0 and hard["first"] < 230.0, "Zor: the attack comes right after minute 3 (first at %.0f s)" % hard["first"])
	_check(hard["max_near"] > easy["max_near"], "Zor: bigger waves than Kolay (%d vs %d at the base)" % [hard["max_near"], easy["max_near"]])
	_check(hard["tc_lost_at"] > 0 and hard["tc_lost_at"] < 300.0, "Zor: a passive player loses the Town Center before minute 5 (at %.0f s)" % hard["tc_lost_at"])

	_restore(GraphicsSettings.PATH, cfg_text)
	_restore(SaveManager.AUTO_SAVE_FILE, save_text)
	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
