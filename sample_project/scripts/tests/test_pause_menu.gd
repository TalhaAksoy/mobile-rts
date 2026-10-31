extends SceneTree
## In-match menu (taps go through the real input pipeline, Input.parse_input_event):
##  * the top bar has a "Menü" button; tapping it pauses the match and opens the menu
##  * while paused nothing moves; DEVAM ET, Escape and the Android Back button close it again
##  * Escape / Back open it during a match; Back does not quit the app during a match
##  * OYUNU KAYDET writes the quick save
##  * ANA MENÜYE DÖN needs a second tap, then the match is cleared and the main menu is shown,
##    with KAYITLI OYUN to continue the saved match
##  * OYUNDAN ÇIK also asks first (only the first tap is tested: the second quits)
##  * the game-over modal has ANA MENÜ next to YENİDEN OYNA
## The player's own quick save is backed up and restored.
const GameController3D = preload("res://scripts/GameController3D.gd")

var failures := 0
var checks := 0
var game

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

func _tap_button(b: Control) -> void:
	var pos: Vector2 = root.get_final_transform() * b.get_global_rect().get_center()
	var d := InputEventMouseButton.new()
	d.button_index = MOUSE_BUTTON_LEFT
	d.position = pos
	d.global_position = pos
	d.pressed = true
	Input.parse_input_event(d)
	await process_frame
	var u := d.duplicate()
	u.pressed = false
	Input.parse_input_event(u)
	await _frames(3)

## headless process frames run uncapped: movement happens on physics ticks
func _physics(n: int) -> void:
	for i in n:
		await physics_frame

func _key(code: Key) -> void:
	var k := InputEventKey.new()
	k.keycode = code
	k.pressed = true
	Input.parse_input_event(k)
	await process_frame
	var r := k.duplicate()
	r.pressed = false
	Input.parse_input_event(r)
	await _frames(2)

func _back_button() -> void:
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames(2)

func _run() -> void:
	var save_path := ProjectSettings.globalize_path(SaveManager.AUTO_SAVE_FILE)
	var backup := ""
	var had_save := FileAccess.file_exists(SaveManager.AUTO_SAVE_FILE)
	if had_save:
		backup = FileAccess.get_file_as_string(SaveManager.AUTO_SAVE_FILE)
		DirAccess.remove_absolute(save_path)

	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	game = scene as GameController3D
	var ui = game.ui_manager
	var pm: PauseMenu = ui.pause_menu
	var menu = ui.menu_root
	_check(menu.btn_continue != null and not menu.btn_continue.visible, "main menu: no KAYITLI OYUN button without a saved game")

	seed(12)
	game._on_start_game_requested(0, 1, 0)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	game.enemy_ai.set_process(false)
	await _frames(5)
	_check(ui.menu_btn != null and ui.menu_btn.is_visible_in_tree() and ui.menu_btn.get_parent() == ui.speed_btn.get_parent(), "top bar has a visible Menü button")
	_check(not get_root().get_tree().quit_on_go_back, "during a match Android Back does not quit the app")

	# a villager walking, to see that the match really stops
	var v: Unit3D = null
	for u in game.units:
		if u.team == 0:
			v = u
			break
	var mg = game.map_gen
	var from: Vector2i = mg.world_to_cell(v.global_position)
	var dest := from
	for c in [from + Vector2i(5, 0), from + Vector2i(-5, 0), from + Vector2i(0, 5), from + Vector2i(0, -5), from + Vector2i(4, 4), from + Vector2i(-4, 4)]:
		if dest == from and mg.is_valid_cell(c.x, c.y) and mg.is_cell_walkable(c):
			dest = c
	v.command_move(mg.cell_to_world(dest))
	await _physics(5)
	_check(v.state == Unit3D.State.MOVING, "a villager is walking (to %s)" % dest)

	# --- open with the button
	await _tap_button(ui.menu_btn)
	_check(paused and pm.visible, "tapping Menü pauses the match and opens the menu")
	var p0: Vector3 = v.global_position
	await _physics(20)
	_check(v.global_position == p0, "nothing moves while paused")
	await _tap_button(pm.btn_resume)
	_check(not paused and not pm.visible, "DEVAM ET closes the menu and resumes")
	await _physics(10)
	_check(v.global_position != p0, "the villager walks on after resuming")

	# --- Escape and Android Back
	await _key(KEY_ESCAPE)
	_check(paused and pm.visible, "Escape opens the menu")
	await _key(KEY_ESCAPE)
	_check(not paused and not pm.visible, "Escape closes it again")
	await _back_button()
	_check(paused and pm.visible, "Android Back opens the menu")
	await _back_button()
	_check(not paused and not pm.visible, "Android Back closes it again")

	# --- save
	await _tap_button(ui.menu_btn)
	await _tap_button(pm.btn_save)
	_check(FileAccess.file_exists(SaveManager.AUTO_SAVE_FILE) and pm.status_label.text.contains("kaydedildi"), "OYUNU KAYDET writes the quick save (%s)" % pm.status_label.text)
	_check(paused and pm.visible, "still paused after saving")

	# --- quit asks first
	await _tap_button(pm.btn_quit)
	_check(pm.btn_quit.text == PauseMenu.CONFIRM_TEXT and paused, "OYUNDAN ÇIK asks for confirmation first")

	# --- main menu: first tap asks (and disarms quit), second leaves
	await _tap_button(pm.btn_main_menu)
	_check(pm.btn_main_menu.text == PauseMenu.CONFIRM_TEXT and pm.btn_quit.text == "OYUNDAN ÇIK" and game.is_game_active,
		"ANA MENÜYE DÖN asks for confirmation first, the match is still on")
	await _tap_button(pm.btn_main_menu)
	await _frames(3)
	_check(not game.is_game_active and not paused and not pm.visible, "second tap leaves the match, unpaused")
	_check(menu.visible and menu.main_menu_view.visible and not ui.hud_root.visible, "main menu shown, HUD hidden")
	_check(game.units.is_empty() and game.buildings.is_empty(), "the match's units and buildings are gone")
	_check(get_root().get_tree().quit_on_go_back, "in the main menu Android Back quits the app again")
	await _key(KEY_ESCAPE)
	_check(not paused and not pm.visible, "Escape in the main menu does not open the in-match menu")

	# --- continue the saved match
	_check(menu.btn_continue.visible, "main menu shows KAYITLI OYUN after saving")
	await _tap_button(menu.btn_continue)
	await _frames(3)
	var n_player := 0
	for u in game.units:
		if is_instance_valid(u) and u.team == 0:
			n_player += 1
	_check(game.is_game_active and ui.hud_root.visible and not menu.visible and n_player > 0, "KAYITLI OYUN continues the saved match (%d player units)" % n_player)
	_check(not get_root().get_tree().quit_on_go_back and pm.match_running, "back in a match: Back opens the menu again")

	# --- game over: ANA MENÜ
	game._game_over(false)
	await _frames(2)
	_check(ui.game_over_menu_btn != null and ui.game_over_menu_btn.is_visible_in_tree(), "game-over modal has ANA MENÜ")
	await _tap_button(pm.btn_resume if pm.visible else ui.menu_btn)   # the menu does not open over the game-over modal
	_check(not pm.visible and not paused, "Menü does nothing once the game is over")
	await _tap_button(ui.game_over_menu_btn)
	_check(menu.visible and not ui.game_over_modal.visible and not game.is_game_active, "ANA MENÜ on the game-over modal returns to the main menu")

	# restore the player's quick save
	DirAccess.remove_absolute(save_path)
	if had_save:
		var f := FileAccess.open(SaveManager.AUTO_SAVE_FILE, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
