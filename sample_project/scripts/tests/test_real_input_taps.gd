extends SceneTree
## Taps through the REAL input pipeline (Input.parse_input_event), including Godot's touch<->mouse
## emulation (both are enabled in project.godot). Earlier tests called the click handler directly and
## missed that every tap arrived twice (real + emulated event): the second one deselected the building
## that the first one had just selected, so buildings could not be selected in the game.
##  * mouse click and finger tap select every building type (3D models and 2D sprites)
##  * a second tap on the selected building deselects it (exactly one toggle per tap)
##  * tapping the Town Center's "train villager" button queues one villager
##  * tapping a villager selects it, tapping the ground moves it
##  * dragging pans the camera
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

## Input events carry WINDOW coordinates; the viewport maps them through its stretch transform
## (identity on a phone/desktop window at the design size, x15 in a headless run).
func _win(p: Vector2) -> Vector2:
	return root.get_final_transform() * p

func _tap(vp_pos: Vector2, touch: bool) -> void:
	var pos := _win(vp_pos)
	if touch:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.position = pos
		t.pressed = true
		Input.parse_input_event(t)
		await process_frame
		var u := t.duplicate()
		u.pressed = false
		Input.parse_input_event(u)
	else:
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

func _free_area(center: Vector2i, size: Vector2i):
	var mg = game.map_gen
	for r in range(3, 30):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if abs(dx) != r and abs(dy) != r:
					continue
				var o := center + Vector2i(dx, dy)
				var ok := true
				for yy in range(size.y):
					for xx in range(size.x):
						var c := o + Vector2i(xx, yy)
						if not mg.is_valid_cell(c.x, c.y) or not mg.is_cell_buildable(c) or not mg.get_resource_at_cell(c).is_empty():
							ok = false
				if ok:
					return o
	return null

func _select_target(b) -> Vector2:
	game.camera.jump_to(b.global_position, false)
	return game.camera.unproject_position(b.global_position + Vector3(0, 1.8, 0))

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	game = scene as GameController3D
	for style in ["3d", "2d"]:
		FactionArtManager.use_3d_building_models = style == "3d"
		seed(77)
		game._on_start_game_requested(CivData.CivType.BRITONS, CivData.CivType.JAPANESE, 0)
		if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
			game.tutorial_mgr.stop_tutorial()
		game.enemy_ai.set_process(false)
		await _frames(5)
		# move our villagers out of the way: units have tap priority over buildings
		for u in game.units:
			if u.team == 0:
				u.global_position = game.map_gen.player_start_pos + Vector3(30, 0, 30)
				u.command_stop()
		var base: Vector2i = game.map_gen.world_to_cell(game.map_gen.player_start_pos)
		var tc = null
		for b in game.buildings:
			if b.team == 0 and b.building_type == Building3D.BuildingType.TOWN_CENTER:
				tc = b
		for touch in [false, true]:
			var how := "%s %s" % [style, "finger" if touch else "mouse"]
			var ok := 0
			var tried := 0
			var bad := []
			for t in Building3D.BuildingType.values():
				if t == Building3D.BuildingType.FARM:
					continue
				# one building at a time (placed, tapped, removed) so neighbours never share the tap
				var b = tc
				if t != Building3D.BuildingType.TOWN_CENTER:
					var spot = _free_area(base, game._get_building_size(t))
					if spot == null:
						bad.append("no spot for %d" % t)
						continue
					b = game.place_building(t, 0, spot, false)
				tried += 1
				game._clear_selection()
				game.ui_manager.set_selected_entity(null)
				var sp := _select_target(b)
				await _frames(2)
				await _tap(sp, touch)
				if game.ui_manager.selected_entity == b and game.selected_building == b:
					ok += 1
				else:
					bad.append(FactionArtManager.get_building_id_from_type(b.building_type))
				if b != tc:
					game._clear_selection()
					b.die()
					await _frames(1)
			_check(tried == 11 and bad.is_empty(), "%s: tapping selects every building type (%d/%d) %s" % [how, ok, tried, str(bad)])
			# second tap on the selected building deselects it (one toggle per tap, not two)
			game._clear_selection()
			game.ui_manager.set_selected_entity(null)
			var sp_tc := _select_target(tc)
			await _frames(2)
			await _tap(sp_tc, touch)
			var first_ok: bool = game.selected_building == tc
			await _tap(sp_tc, touch)
			_check(first_ok and game.selected_building == null and game.ui_manager.selected_entity == null, "%s: second tap on the selected TC deselects it" % how)

		# --- the TC panel's train button, tapped with a finger
		game.team_resources[0]["food"] = 500
		game._clear_selection()
		var sp := _select_target(tc)
		await _frames(2)
		await _tap(sp, true)
		await _frames(2)
		var btn: Button = null
		for c in game.ui_manager.find_children("*", "Button", true, false):
			if c.is_visible_in_tree() and "İşçi Eğit" in c.text:
				btn = c
		_check(btn != null, "%s: TC panel shows the 'train villager' button" % style)
		if btn != null:
			var q0: int = tc.train_queue.size()
			await _tap(btn.get_global_rect().get_center(), true)
			_check(tc.train_queue.size() == q0 + 1, "%s: tapping the button queues exactly one villager (%d -> %d)" % [style, q0, tc.train_queue.size()])
			tc.train_queue.clear()

		# --- villager: tap selects, tap on ground moves
		var v: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, tc.global_position + Vector3(0, 0, 9))
		game._clear_selection()
		game.ui_manager.set_selected_entity(null)
		game.camera.jump_to(v.global_position, false)
		await _frames(3)
		await _tap(game.camera.unproject_position(v.global_position + Vector3(0, 0.9, 0)), true)
		_check(game.selected_units == [v], "%s: tapping a villager selects it" % style)
		# open ground (no resource / building / unit under the tap), otherwise a tap means gather/drop-off
		var dest: Vector3 = v.global_position + Vector3(4, 0, 0)
		for off in [Vector3(4, 0, 0), Vector3(-4, 0, 0), Vector3(0, 0, 4), Vector3(4, 0, 4), Vector3(-4, 0, 4), Vector3(6, 0, -2)]:
			var cand: Vector3 = v.global_position + off
			var csp: Vector2 = game.camera.unproject_position(cand)
			if game._find_resource_at_click(csp, cand, false).is_empty() and game._get_entity_at_position(csp, cand) == null:
				dest = cand
				break
		await _tap(game.camera.unproject_position(dest), true)
		await _frames(2)
		_check(v.state == Unit3D.State.MOVING and v.global_position.distance_to(dest) > 0.5, "%s: tapping the ground sends it walking (state %s)" % [style, Unit3D.State.keys()[v.state]])

		# --- drag pans the camera
		var cam_x: float = game.camera.position.x
		var t0 := InputEventScreenTouch.new()
		t0.index = 0
		t0.position = _win(Vector2(270, 600))
		t0.pressed = true
		Input.parse_input_event(t0)
		for i in 10:
			var dr := InputEventScreenDrag.new()
			dr.index = 0
			dr.position = _win(Vector2(270 - (i + 1) * 12, 600))
			dr.relative = _win(Vector2(-12, 0)) - _win(Vector2.ZERO)
			Input.parse_input_event(dr)
			await process_frame
		var t1 := t0.duplicate()
		t1.pressed = false
		t1.position = _win(Vector2(150, 600))
		Input.parse_input_event(t1)
		await _frames(2)
		_check(absf(game.camera.position.x - cam_x) > 1.0, "%s: dragging pans the camera (%.1f -> %.1f)" % [style, cam_x, game.camera.position.x])
	FactionArtManager.use_3d_building_models = true
	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
