extends SceneTree
## Playtest regressions (phone), through the REAL input pipeline in both looks (2D sprites, 3D models):
##  HUD
##   * a press on the HUD never reaches the map: a grid scan of the lower screen with the bottom menu, the build
##     menu and an armed SALDIR order, finger taps with jitter, never reaches the game's press handler
##   * a touch that slips past the GUI onto the HUD (separate touch / emulated mouse events on a phone) and a
##     release whose press never reached the game are ignored: an armed attack order stays armed, nobody walks
##  Camera
##   * every map corner can be scrolled into the part of the screen the HUD leaves free (bottom menu closed,
##     expanded, build menu open; zoomed in, default, out); closing a menu eases the view back, no jump
##  Farm fields
##   * every tap on a field (also behind the Mill, behind trees) sends the selected villager to that field
##   * with a farmer working the field, only a tap on his body selects him; the rest are orders for the field
##  Construction sites
##   * a walking villager goes round a building placed across its path, a villager ordered across a
##     construction site goes round it (no corner cutting), a villager standing where a building is placed
##     steps out
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

func _physics(n: int) -> void:
	for i in n:
		await physics_frame

func _win(p: Vector2) -> Vector2:
	return root.get_final_transform() * p

## Finger tap with a little jitter (a real finger never stays still): press, three drags, release.
func _tap(vp_pos: Vector2, jitter: bool = false) -> void:
	var pos := _win(vp_pos)
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = pos
	t.pressed = true
	Input.parse_input_event(t)
	await process_frame
	if jitter:
		for k in 3:
			var d := InputEventScreenDrag.new()
			d.index = 0
			d.position = pos + Vector2(k + 1, k)
			d.relative = Vector2(1, 1)
			Input.parse_input_event(d)
			await process_frame
	var u := t.duplicate()
	u.pressed = false
	u.position = pos + (Vector2(3, 2) if jitter else Vector2.ZERO)
	Input.parse_input_event(u)
	await _frames(3)

func _villagers() -> Array:
	return game.units.filter(func(u): return is_instance_valid(u) and u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER)

func _select(v) -> void:
	game._clear_selection()
	game.selected_units.append(v)
	v.set_selected(true)
	game.ui_manager.set_selected_entity(v)

func _start(style: String, seed_value: int) -> void:
	FactionArtManager.use_3d_building_models = style == "3d"
	GraphicsSettings.values["style"] = 1 if style == "2d" else 0
	seed(seed_value)
	game._on_start_game_requested(CivData.CivType.BRITONS, CivData.CivType.JAPANESE, 0)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	game.enemy_ai.set_process(false)
	await _frames(5)

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	game = scene as GameController3D
	Engine.physics_ticks_per_second = 60
	for style in ["2d", "3d"]:
		await _start(style, 77)
		await _hud(style)
		await _camera(style)
		await _start(style, 11)
		await _fields(style)
		await _start(style, 21)
		await _sites(style)
	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)

# ------------------------------------------------------------------------------------------------ HUD
func _hud(style: String) -> void:
	var ui = game.ui_manager
	var vs: Vector2 = root.get_visible_rect().size
	var v = _villagers()[0]
	var home: Vector3 = v.global_position
	for mode in ["bottom menu", "build menu", "armed SALDIR"]:
		var reached := 0
		var on_ui := 0
		for gy in 10:
			for gx in 7:
				var p := Vector2(16 + gx * (vs.x - 32) / 6.0, vs.y * 0.5 + gy * (vs.y * 0.5 - 6) / 9.0)
				v.global_position = home
				v.command_stop()
				_select(v)
				game.pending_army_command = "attack" if mode == "armed SALDIR" else ""
				ui.build_panel.visible = mode == "build menu"
				if ui.build_panel.visible:
					ui.build_panel.offset_bottom = ui.bottom_bar.offset_top - 6.0
				await _frames(2)
				if not game.ui_blocks_point(p):
					continue
				on_ui += 1
				game.drag_start_pos = Vector2(-999, -999)
				await _tap(p, true)
				if game.drag_start_pos != Vector2(-999, -999):
					reached += 1
		_check(on_ui > 20 and reached == 0, "%s %s: finger taps on the HUD never reach the map (%d of %d)" % [style, mode, reached, on_ui])
	ui.build_panel.visible = false
	game.pending_army_command = ""
	# a touch that got past the GUI anyway, straight into the game's handler, over the bottom menu
	var army := _villagers().slice(0, 3)
	game._clear_selection()
	for u in army:
		u.global_position = home
		u.command_stop()
		game.selected_units.append(u)
		u.set_selected(true)
	ui.set_selected_entity(army[0])
	game.pending_army_command = "attack"
	await _frames(3)
	var r: Rect2 = ui.bottom_bar.get_global_rect()
	var on_bar := r.position + Vector2(r.size.x * 0.5, 8)
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = on_bar
	down.pressed = true
	game._unhandled_input(down)
	var up := down.duplicate()
	up.pressed = false
	game._unhandled_input(up)
	await _physics(10)
	var walked := army.filter(func(u): return u.state != Unit3D.State.IDLE)
	_check(game.pending_army_command == "attack" and walked.is_empty(),
		"%s: a touch on the bottom menu that slipped past the GUI gives no order (SALDIR still armed, %d walking)" % [style, walked.size()])
	# a release whose press the game never saw (the press went to a button that was rebuilt meanwhile)
	game.is_touch_active = false
	game.drag_start_pos = game.camera.unproject_position(home + Vector3(6, 0, 6))
	var orphan := InputEventScreenTouch.new()
	orphan.index = 0
	orphan.position = game.drag_start_pos
	orphan.pressed = false
	game._unhandled_input(orphan)
	await _physics(10)
	walked = army.filter(func(u): return u.state != Unit3D.State.IDLE)
	_check(game.pending_army_command == "attack" and walked.is_empty(), "%s: a release without its press is not a tap (no order)" % style)
	game.pending_army_command = ""
	game._clear_selection()
	ui.set_selected_entity(null)

# ------------------------------------------------------------------------------------------------ camera
func _camera(style: String) -> void:
	var ui = game.ui_manager
	var cam = game.camera
	var vs: Vector2 = root.get_visible_rect().size
	var W: float = game.map_gen.MAP_WIDTH * MapGenerator3D.TILE_SIZE
	var H: float = game.map_gen.MAP_HEIGHT * MapGenerator3D.TILE_SIZE
	var v = _villagers()[0]
	var ok := 0
	var total := 0
	var bad := []
	for state in ["closed", "expanded", "build"]:
		game._clear_selection()
		ui.set_selected_entity(null)
		ui.build_panel.visible = false
		if state != "closed":
			_select(v)
		if state == "build":
			ui.build_panel.visible = true
			ui.build_panel.offset_bottom = ui.bottom_bar.offset_top - 6.0
		await _frames(4)
		var ins: Vector2 = ui.hud_screen_insets()
		for h in [12.0, 24.0, 38.0]:
			cam.target_height = h
			cam.position.y = h
			await _frames(2)
			for corner in [[Vector2(-1, 1), Vector3(0, 0, H)], [Vector2(1, 1), Vector3(W, 0, H)], [Vector2(-1, -1), Vector3(0, 0, 0)], [Vector2(1, -1), Vector3(W, 0, 0)]]:
				cam.position.x = W * 0.5
				cam.position.z = H * 0.5
				for k in 60:
					cam.pan_by_screen_delta(corner[0] * 400.0)
				var sp: Vector2 = cam.unproject_position(corner[1])
				var inside: bool = sp.x >= -1 and sp.x <= vs.x + 1 and sp.y >= ins.x - 1 and sp.y <= vs.y - ins.y + 1
				total += 1
				if inside:
					ok += 1
				else:
					bad.append("%s h%d %s->(%d,%d)" % [state, int(h), corner[0], int(sp.x), int(sp.y)])
	_check(ok == total, "%s: every map corner can be brought into the free screen above the menu (%d/%d) %s" % [style, ok, total, bad.slice(0, 4)])
	# open the build menu, scroll to the bottom edge, close it: the view eases back, never jumps
	cam.target_height = 24.0
	cam.position.y = 24.0
	_select(v)
	ui.build_panel.visible = true
	ui.build_panel.offset_bottom = ui.bottom_bar.offset_top - 6.0
	await _frames(3)
	for k in 60:
		cam.pan_by_screen_delta(Vector2(0, 400))
	var low_z: float = cam.position.z
	ui.build_panel.visible = false
	game._clear_selection()
	ui.set_selected_entity(null)
	var max_step := 0.0
	var last: float = cam.position.z
	for k in 90:
		await process_frame
		max_step = maxf(max_step, absf(cam.position.z - last))
		last = cam.position.z
	var lim: Dictionary = cam.camera_limits()
	_check(last <= lim["max"].y + 0.05 and last < low_z and max_step < 3.0,
		"%s: closing the menu eases the view back inside the limits (z %.1f -> %.1f, biggest step %.2f m)" % [style, low_z, last, max_step])
	cam.target_height = 24.0

# ------------------------------------------------------------------------------------------------ fields
## A 6x6 block for a mill and its fields near `near`, in the forest if need be: only the trees inside the
## block are cut, the ones around it stay (a row of trees in front of a field draws its canopies over it).
func _spot(size: Vector2i, near: Vector2i) -> Vector2i:
	var mg = game.map_gen
	for r in range(3, 45):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if abs(dx) != r and abs(dy) != r:
					continue
				var o := near + Vector2i(dx, dy)
				var bad := false
				for yy in size.y:
					for xx in size.x:
						var c := o + Vector2i(xx, yy)
						if not mg.is_valid_cell(c.x, c.y) or not mg.is_cell_buildable(c):
							bad = true
				if bad:
					continue
				for yy in size.y:
					for xx in size.x:
						var c := o + Vector2i(xx, yy)
						if mg.trees.has(c):
							mg.harvest_tree(c, 100000)
				return o
	return near

func _fields(style: String) -> void:
	var vs: Vector2 = root.get_visible_rect().size
	var base: Vector2i = game.map_gen.world_to_cell(game.map_gen.player_start_pos)
	var o := _spot(Vector2i(6, 6), base + Vector2i(0, 6))
	var mill = game.place_building(Building3D.BuildingType.MILL, 0, o + Vector2i(2, 2), false)
	game.team_resources[0]["wood"] = 9999
	var fields := []
	for k in 6:
		var f = game.try_add_field(mill, 0)
		if f != null:
			f.contribute_construction(200.0)
			fields.append(f)
	_check(fields.size() >= 4, "%s: a mill with %d fields" % [style, fields.size()])
	var vills := _villagers()
	var park: Vector3 = game.map_gen.cell_to_world(base + Vector2i(-10, -10))
	for u in vills:
		u.global_position = park
		u.command_stop()
	game.camera.jump_to(mill.global_position, false)
	await _frames(3)
	var v = vills[0]
	var ok := 0
	var total := 0
	var under_tree := 0
	var behind_mill := 0
	var bad := []
	for f in fields:
		for gx in [-0.7, 0.0, 0.7]:
			for gz in [-0.7, 0.0, 0.7]:
				var sp: Vector2 = game.camera.unproject_position(f.global_position + Vector3(gx * 1.6, 0, gz * 1.6))
				if sp.x < 4 or sp.x > vs.x - 4 or sp.y < 4 or sp.y > vs.y - 4 or game.ui_blocks_point(sp):
					continue
				var gp: Vector3 = game.camera.raycast_ground(sp)
				if not game._find_resource_at_click(sp, gp, true).is_empty():
					under_tree += 1                          # a tree's canopy is drawn over this point
				if game._building_screen_rect(mill).has_point(sp):
					behind_mill += 1                         # inside the Mill's screen box
				v.global_position = park
				v.command_stop()
				game.map_gen.farm_fields[f.origin_cell]["farmer"] = null
				_select(v)
				await _frames(2)
				await _tap(sp)
				total += 1
				if v.target_cell == f.origin_cell and v.resource_type == "food":
					ok += 1
				else:
					bad.append("%s %s" % [f.origin_cell - mill.origin_cell, v.resource_type])
	_check(total >= 20 and ok == total, "%s: every tap on a field sends the villager to it (%d/%d; %d of them in the Mill's screen box, %d under a tree canopy) %s" % [style, ok, total, behind_mill, under_tree, bad.slice(0, 4)])
	if style == "3d":
		_check(behind_mill > 0, "3d: the check covered taps on a field the Mill's box reaches over (%d)" % behind_mill)
	# a farmer at work: only a tap on his body selects him
	var stolen_far := 0
	var near := 0
	var far := 0
	for i in fields.size():
		var f = fields[i]
		var farmer = vills[1 + (i % (vills.size() - 1))]
		farmer.global_position = f.global_position + Vector3(0.3, 0, 0.2)
		game.map_gen.farm_fields[f.origin_cell]["farmer"] = null
		game.map_gen.claim_field(f.origin_cell, farmer)
		farmer.command_gather(f.origin_cell, "food")
		await _frames(2)
		for gx in [-0.7, 0.0, 0.7]:
			for gz in [-0.7, 0.0, 0.7]:
				var sp: Vector2 = game.camera.unproject_position(f.global_position + Vector3(gx * 1.6, 0, gz * 1.6))
				if sp.x < 4 or sp.x > vs.x - 4 or sp.y < 4 or sp.y > vs.y - 4 or game.ui_blocks_point(sp):
					continue
				var feet: Vector2 = game.camera.unproject_position(farmer.global_position)
				var head_off := Vector3(0, 0, -1.5) if FactionArtManager.top_down() else Vector3(0, 1.8, 0)
				var head: Vector2 = game.camera.unproject_position(farmer.global_position + head_off)
				var body_d: float = game._dist_to_segment_2d(sp, feet, head)
				v.global_position = park
				v.command_stop()
				_select(v)
				await _frames(2)
				await _tap(sp)
				if body_d > 20.0:
					far += 1
					if game.selected_units.size() == 1 and game.selected_units[0] == farmer:
						stolen_far += 1
				else:
					near += 1
		farmer.global_position = park
		farmer.command_stop()
	_check(far >= 15 and stolen_far == 0, "%s: with a farmer on the field, taps off his body never select him (%d of %d; %d on his body)" % [style, stolen_far, far, near])
	# every field taken, no free one: a message instead of silence
	var crew := []
	for f in fields:
		var w = game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, f.global_position)
		game.map_gen.farm_fields[f.origin_cell]["farmer"] = null
		game.map_gen.claim_field(f.origin_cell, w)
		w.command_gather(f.origin_cell, "food")
		crew.append(w)
	await _physics(2)
	v.global_position = park
	v.command_stop()
	_select(v)
	game.ui_manager.toast_card.visible = false
	var all_taken: bool = fields.all(func(f): return not game.map_gen.is_field_free_for(f.origin_cell, v))
	# a point that resolves to the field itself (not its farmer, a tree or the Mill)
	var tap_pos: Vector3 = fields[0].global_position
	for gx in [-0.7, 0.7, 0.0]:
		for gz in [-0.7, 0.7, 0.0]:
			var q: Vector3 = fields[0].global_position + Vector3(gx * 1.6, 0, gz * 1.6)
			if game._get_entity_at_position(game.camera.unproject_position(q), q) == fields[0]:
				tap_pos = q
	game._handle_3d_click(game.camera.unproject_position(tap_pos), tap_pos)
	await _frames(2)
	_check(all_taken and v.state == Unit3D.State.IDLE and game.ui_manager.toast_card.visible \
		and game.ui_manager.toast_label.text.contains("TARLA"),
		"%s: every field taken -> the villager stays and a message says why ('%s')" % [style, game.ui_manager.toast_label.text])
	for w in crew:
		w.queue_free()
		game.units.erase(w)

# ------------------------------------------------------------------------------------------------ sites
func _inside(u, o: Vector2i, sz: Vector2i) -> bool:
	var c: Vector2i = game.map_gen.world_to_cell(u.global_position)
	return c.x >= o.x and c.x < o.x + sz.x and c.y >= o.y and c.y < o.y + sz.y

func _open_line(a: Vector2i, n: int) -> bool:
	var mg = game.map_gen
	for dy in range(-2, 3):
		for dx in range(0, n):
			var c := a + Vector2i(dx, dy)
			if not mg.is_valid_cell(c.x, c.y) or not mg.is_cell_passable_terrain(c.x, c.y) or mg.occupied_cells.has(c) \
					or mg.field_cells.has(c) or c in mg.gold_mines or c in mg.stone_mines or c in mg.berry_bushes:
				return false
	for dy in range(-2, 3):
		for dx in range(0, n):
			var c := a + Vector2i(dx, dy)
			if mg.trees.has(c):
				mg.harvest_tree(c, 100000)
	return true

func _sites(style: String) -> void:
	var mg = game.map_gen
	var base: Vector2i = mg.world_to_cell(mg.player_start_pos)
	var start := Vector2i(-1, -1)
	for r in range(4, 40):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if start == Vector2i(-1, -1) and _open_line(base + Vector2i(dx, dy), 14):
					start = base + Vector2i(dx, dy)
	_check(start != Vector2i(-1, -1), "%s: an open strip for the construction-site checks" % style)
	if start == Vector2i(-1, -1):
		return
	var v = _villagers()[0]
	for u in game.units:
		if u != v and u.team == 0:
			u.global_position = mg.cell_to_world(base + Vector2i(0, 12))
			u.command_stop()
	# a building placed (under construction) across a walking villager's path
	v.global_position = mg.cell_to_world(start)
	v.command_stop()
	await _physics(2)
	var goal: Vector3 = mg.cell_to_world(start + Vector2i(13, 0))
	v.command_move(goal)
	await _physics(30)
	var o1 := start + Vector2i(7, -1)
	game.place_building(Building3D.BuildingType.BARRACKS, 0, o1, true)
	var inside1 := 0
	for k in 900:
		await physics_frame
		if _inside(v, o1, Vector2i(3, 3)):
			inside1 += 1
		if v.global_position.distance_to(goal) < 0.6:
			break
	_check(inside1 == 0 and v.global_position.distance_to(goal) < 1.0,
		"%s: a villager walking where a building is placed goes round the construction site (%d frames inside)" % [style, inside1])
	# a building placed right on a standing villager: he steps out
	var o2 := start + Vector2i(3, -1)
	v.global_position = mg.cell_to_world(o2 + Vector2i(1, 1))
	v.command_stop()
	await _physics(2)
	game.place_building(Building3D.BuildingType.HOUSE, 0, o2, true)
	await _physics(3)
	_check(not _inside(v, o2, Vector2i(2, 2)), "%s: a villager standing where a building is placed steps out of it" % style)
	# ordered across the construction site: round it, no corner cutting
	v.global_position = mg.cell_to_world(o2 + Vector2i(-2, 0))
	v.command_stop()
	await _physics(2)
	var goal3: Vector3 = mg.cell_to_world(o2 + Vector2i(3, 1))     # just past the house (the barracks starts at +4)
	v.command_move(goal3)
	var inside3 := 0
	for k in 900:
		await physics_frame
		if _inside(v, o2, Vector2i(2, 2)):
			inside3 += 1
		if v.global_position.distance_to(goal3) < 0.6:
			break
	_check(inside3 == 0 and v.global_position.distance_to(goal3) < 1.0,
		"%s: a villager ordered across a construction site walks round it (%d frames inside)" % [style, inside3])
