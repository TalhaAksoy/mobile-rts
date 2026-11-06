extends SceneTree
## Group handling on the portrait screen, through the real input pipeline where it matters:
##  * one tap selects one unit; a double tap on a unit selects every unit of that type on screen
##  * a long press (finger held still) then a drag box-selects without the box-mode button;
##    a long press without a drag gives no order
##  * control groups: hold = save, tap = select, double tap = select + camera; an empty group saves on tap;
##    a unit is in one group only; dead units drop out
##  * the group panel's type buttons keep only that type
const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")

var failures := 0
var game

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _wait_ms(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < ms:
		await process_frame

func _win(vp: Vector2) -> Vector2:
	return root.get_final_transform() * vp

func _touch(vp: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = _win(vp)
	t.pressed = pressed
	Input.parse_input_event(t)

func _drag(vp: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = 0
	d.position = _win(vp)
	Input.parse_input_event(d)

func _screen(u) -> Vector2:
	return game.camera.unproject_position(u.global_position)

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	await _frames(3)
	game = scene as GameController3D
	game.start_match()
	game.enemy_ai.set_process(false)
	await _frames(5)
	for u in game.units.duplicate():                       # a clean field: only the units placed here
		if u.team == 0:
			game.units.erase(u)
			u.queue_free()
	await _frames(2)
	var c: Vector3 = game.map_gen.player_start_pos + Vector3(0, 0, 8)
	game.camera.jump_to(c, false)
	await _frames(5)
	var swords: Array = []
	var archers: Array = []
	for i in 4:
		swords.append(game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, c + Vector3(-4 + i * 1.6, 0, 0)))
		archers.append(game.spawn_unit(Unit3D.UnitType.ARCHER, 0, c + Vector3(-4 + i * 1.6, 0, 2.5)))
	game.separation_enabled = false
	await _frames(10)

	# --- one tap = one unit; fast second tap toggles (no mass select); long press on a unit = its type on screen
	var p0 := _screen(swords[1]) + Vector2(0, -20)
	game._handle_3d_click(p0, swords[1].global_position)
	_check(game.selected_units.size() == 1 and game.selected_units[0] == swords[1], "one tap selects one swordsman")
	game._handle_3d_click(p0, swords[1].global_position)
	_check(game.selected_units.is_empty(), "a fast second tap on it deselects (no screen-wide selection)")
	game._handle_3d_click(_screen(swords[0]) + Vector2(0, -20), swords[0].global_position)
	game._handle_3d_click(_screen(swords[2]) + Vector2(0, -20), swords[2].global_position)
	_check(game.selected_units.size() == 1 and game.selected_units[0] == swords[2], "quick taps on two neighbours switch the single selection")
	game._clear_selection()
	_touch(p0, true)
	await _wait_ms(game.LONG_PRESS_MS + 150)
	_touch(p0, false)
	await _frames(3)
	_check(game.selected_units.size() == 4 and game.selected_units.all(func(u): return u.unit_type == Unit3D.UnitType.SWORDSMAN),
		"holding a swordsman selects the 4 swordsmen on screen (%d)" % game.selected_units.size())

	# --- long press + drag = box select (real input events)
	game._clear_selection()
	var a := _screen(swords[0]) + Vector2(-40, -60)
	var b := _screen(archers[3]) + Vector2(40, 40)
	_touch(a, true)
	await _wait_ms(game.LONG_PRESS_MS + 150)
	_check(game._long_press_box, "holding the finger still arms a box selection")
	for k in 8:
		_drag(a.lerp(b, (k + 1) / 8.0))
		await process_frame
	_touch(b, false)
	await _frames(3)
	_check(game.selected_units.size() == 8, "long press + drag selects the 8 units in the box (%d)" % game.selected_units.size())
	# long press, no drag: no order, nothing changes
	var before: Vector3 = swords[0].global_position
	var sel_before: int = game.selected_units.size()
	_touch(Vector2(270, 300), true)
	await _wait_ms(game.LONG_PRESS_MS + 150)
	_touch(Vector2(270, 300), false)
	await _frames(20)
	_check(game.selected_units.size() == sel_before and swords[0].state != Unit3D.State.MOVING,
		"a long press without a drag gives no order")

	# --- type filter in the group panel
	game.filter_selection_to_type(Unit3D.UnitType.ARCHER)
	_check(game.selected_units.size() == 4 and game.selected_units.all(func(u): return u.unit_type == Unit3D.UnitType.ARCHER),
		"type button keeps only the archers")
	game._select_units(swords + archers)
	await _frames(2)
	var filt: Node = game.ui_manager.action_flow.find_child("TypeFilter_%d" % Unit3D.UnitType.SWORDSMAN, true, false)
	_check(filt != null, "group panel shows a type button per unit type")
	if filt != null:
		filt.emit_signal("pressed")
		_check(game.selected_units.size() == 4 and game.selected_units[0].unit_type == Unit3D.UnitType.SWORDSMAN, "tapping it keeps the swordsmen")

	# --- control groups via the real buttons
	var ui = game.ui_manager
	game._select_units(swords)
	ui._group_down_ms[0] = Time.get_ticks_msec() - 600      # held 600 ms
	ui._on_group_released(0)
	_check(game.control_groups[0].size() == 4, "holding group 1 saves the 4 swordsmen")
	await _frames(2)
	_check(ui.group_buttons[0].text == "1·4", "group button shows the count (%s)" % ui.group_buttons[0].text)
	game._select_units(archers)
	ui._group_down_ms[1] = Time.get_ticks_msec()
	ui._on_group_released(1)
	_check(game.control_groups[1].size() == 4, "a tap on an empty group saves the selection")
	game._clear_selection()
	await _wait_ms(400)
	ui._group_down_ms[0] = Time.get_ticks_msec()
	ui._on_group_released(0)
	_check(game.selected_units.size() == 4 and game.selected_units[0].unit_type == Unit3D.UnitType.SWORDSMAN, "tap on group 1 selects it")
	game.camera.jump_to(c + Vector3(30, 0, 30), false)
	await _frames(3)
	var cam_before: Vector3 = game.camera.position
	ui._group_down_ms[1] = Time.get_ticks_msec()
	ui._on_group_released(1)
	await _wait_ms(100)
	ui._group_down_ms[1] = Time.get_ticks_msec()
	ui._on_group_released(1)
	await _wait_ms(500)
	_check(game.selected_units.size() == 4 and game.selected_units[0].unit_type == Unit3D.UnitType.ARCHER
		and game.camera.position.distance_to(cam_before) > 5.0, "double tap on group 2 selects it and moves the camera there")
	# one group per unit
	game._select_units([archers[0]])
	game.assign_control_group(0)
	_check(game.control_groups[0].size() == 1 and game.control_groups[1].size() == 3, "saving a unit into group 1 takes it out of group 2")
	# dead units drop out
	archers[1].hp = 0
	archers[1].die()
	await _frames(3)
	game.select_control_group(1)
	_check(game.selected_units.size() == 2, "a dead unit drops out of its group (%d left)" % game.selected_units.size())

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

