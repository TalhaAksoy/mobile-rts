extends SceneTree
## Farm fields (Mill = farm centre):
##  * the Mill adds up to MAX_FIELDS_PER_MILL fields in the slots around it, paying wood each time
##  * field cells are walkable (a ring of fields never walls the Mill in) but not buildable
##  * a finished field is an infinite food source: one villager harvests well past 500 food
##  * one farmer per field; the enemy never farms the player's fields
##  * the builder of a field starts farming it by itself
##  * destroying a field removes the food source; save -> load keeps fields farmable
##  * the FARM entry is gone from the build menu (fields come only from a Mill)
##  * on sloped ground no field sinks into the terrain (it sits on its highest point, a soil bank fills
##    the low side), units on it stand on the field, and tapping any field (also the one behind the
##    Mill) picks that field while tapping the Mill still picks the Mill
const GameController3D = preload("res://scripts/GameController3D.gd")
const SaveManager = preload("res://scripts/SaveManager.gd")

var failures := 0
var game

func _expect(cond: bool, msg: String) -> void:
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _init() -> void:
	call_deferred("_run")

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _clear_spot(size: Vector2i, near: Vector2i) -> Vector2i:
	var mg = game.map_gen
	for r in range(5, 26):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				for c in [near + Vector2i(dx, dy), near + Vector2i(dy, dx)]:
					var ok := true
					for x in size.x:
						for y in size.y:
							var cc = c + Vector2i(x, y)
							if not mg.is_valid_cell(cc.x, cc.y) or not mg.is_cell_buildable(cc) or not mg.get_resource_at_cell(cc).is_empty():
								ok = false
					if ok:
						return c
	return Vector2i(-1, -1)

func _open_block(near: Vector2i) -> Vector2i:
	var mg = game.map_gen
	var best := Vector2i(-1, -1)
	var best_score := -1
	for y in range(near.y - 16, near.y + 8):
		for x in range(0, mg.MAP_WIDTH - 6):
			var c := Vector2i(x, y)
			if Vector2(c + Vector2i(3, 3)).distance_to(Vector2(near)) < 6.0:
				continue
			var score := 0
			var bad := false
			for dx in 6:
				for dy in 6:
					var cc := c + Vector2i(dx, dy)
					if not mg.is_valid_cell(cc.x, cc.y) or not mg.is_cell_passable_terrain(cc.x, cc.y) or mg.occupied_cells.has(cc) \
							or cc in mg.gold_mines or cc in mg.stone_mines:
						bad = true
					elif mg.is_cell_buildable(cc) and mg.get_resource_at_cell(cc).is_empty():
						score += 1
			# level ground where the mill and each field go (the terrain rolls gently; hills are
			# slopes, not flat tiers), the same check the game uses for fields
			for sx in [0, 2, 4]:
				for sy in [0, 2, 4]:
					if not bad and not mg.is_area_level(c + Vector2i(sx, sy), Vector2i(2, 2)):
						bad = true
			if not bad and score > best_score:
				best_score = score
				best = c
	return best

func _clear_block(origin: Vector2i, size: Vector2i) -> void:
	var mg = game.map_gen
	for dx in size.x:
		for dy in size.y:
			var c := origin + Vector2i(dx, dy)
			for d in [mg.trees, mg.berry_bushes]:
				if d.has(c):
					if is_instance_valid(d[c]["node"]):
						d[c]["node"].queue_free()
					d.erase(c)
			mg.update_cell_walkability(c)

func _villager(team: int, pos: Vector3) -> Unit3D:
	return game.spawn_unit(Unit3D.UnitType.VILLAGER, team, pos)

func _run() -> void:
	seed(777)
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	game = scene as GameController3D
	game.selected_map_type = CivData.MapType.HIGHLAND_PLAINS
	game.start_match()
	game.enemy_ai.set_process(false)
	game.enemy_ai.set_physics_process(false)
	Engine.time_scale = 6.0
	var mg = game.map_gen
	var base: Vector2i = mg.world_to_cell(mg.player_start_pos)

	# --- build menu no longer offers a stand-alone farm
	var ui = game.ui_manager
	ui._setup_build_grid()
	await process_frame
	var farm_in_menu := false
	for btn in ui.build_grid.get_children():
		if btn is Button and "ÇİFTLİK" in btn.text:
			farm_in_menu = true
	_expect(not farm_in_menu, "Build menu has no stand-alone farm (fields come from the Mill)")

	# --- mill with a free 6x6 ring: take the most open 6x6 block near the base and clear the few
	# scattered trees/bushes in it (tree scatter rarely leaves a perfectly empty 6x6 naturally)
	# the starting villagers stand aside: gathering next to the test plots, one of them would take
	# the new field before the test's builder does
	for u in game.units:
		if u.team == 0:
			u.command_stop()
			u.global_position = mg.cell_to_world(Vector2i(2, 2))
	var spot := _open_block(base)
	_expect(spot != Vector2i(-1, -1), "found a 6x6 area for a mill + fields")
	_clear_block(spot, Vector2i(6, 6))
	var mill = game.place_building(Building3D.BuildingType.MILL, 0, spot + Vector2i(2, 2), false)
	_expect(game.field_block_reason(mill, 0) == "", "finished mill can add a field")

	game.team_resources[0]["wood"] = 1000
	var fields: Array = []
	for i in game.MAX_FIELDS_PER_MILL + 1:
		var f = game.try_add_field(mill, 0)
		if f != null:
			fields.append(f)
	_expect(fields.size() == game.MAX_FIELDS_PER_MILL, "mill accepts exactly %d fields (got %d)" % [game.MAX_FIELDS_PER_MILL, fields.size()])
	_expect(game.team_resources[0]["wood"] == 1000 - 50 * fields.size(), "each field cost 50 wood (wood left %d)" % game.team_resources[0]["wood"])
	_expect(game.field_block_reason(mill, 0) == "Tarla sınırı dolu", "7th field refused: limit reached")

	var walk_ok := true
	var build_blocked := true
	for f in fields:
		for dx in 2:
			for dy in 2:
				var c: Vector2i = f.origin_cell + Vector2i(dx, dy)
				walk_ok = walk_ok and mg.is_cell_walkable(c)
				build_blocked = build_blocked and not mg.is_cell_buildable(c)
	_expect(walk_ok, "all field cells are walkable")
	_expect(build_blocked, "no field cell is buildable")
	var mill_path = mg.get_path_to_target(mg.cell_to_world(base), mill.global_position)
	_expect(not mill_path.is_empty(), "mill is still reachable through its ring of fields")
	_expect(mg.farm_fields.is_empty(), "unfinished fields are not food sources yet")

	# --- builder prepares the field and starts farming it by itself
	var f0 = fields[0]
	var v1 := _villager(0, mill.global_position + Vector3(0, 0, 3.0))
	v1.command_build(f0)
	var t := 0.0
	while not f0.is_completed and t < 40.0:
		await _wait(0.5); t += 0.5
	_expect(f0.is_completed, "villager finished preparing the field (%.1fs game time)" % t)
	_expect(mg.farm_fields.has(f0.origin_cell), "finished field registered as food source")
	await _wait(1.0)
	_expect(v1.state in [Unit3D.State.GATHERING, Unit3D.State.RETURNING_RESOURCES] and v1.target_cell == f0.origin_cell,
		"builder started farming its field (state %s)" % Unit3D.State.keys()[v1.state])

	# --- infinite food
	var food0: int = game.team_resources[0]["food"]
	t = 0.0
	while game.team_resources[0]["food"] - food0 < 520 and t < 600.0:
		await _wait(2.0); t += 2.0
	_expect(game.team_resources[0]["food"] - food0 >= 520, "one farmer delivered %d food (> a berry bush's 500) in %.0fs" % [game.team_resources[0]["food"] - food0, t])
	_expect(mg.farm_fields.has(f0.origin_cell), "field still there after that: it never depletes")

	# --- one farmer per field + enemy ignores player fields
	var v2 := _villager(0, mill.global_position + Vector3(0, 0, 3.0))
	_expect(not mg.claim_field(f0.origin_cell, v2), "second villager cannot claim an occupied field")
	var enemy_v := _villager(1, mill.global_position + Vector3(0, 0, 3.0))
	_expect(mg.find_free_field(enemy_v.global_position, 1, enemy_v) == Vector2i(-1, -1), "enemy villager finds no field of its own team")
	for f in fields:
		f.contribute_construction(200.0)
	_expect(mg.find_free_field(enemy_v.global_position, 1, enemy_v) == Vector2i(-1, -1), "enemy still ignores the player's finished fields")
	var free_for_v2: Vector2i = mg.find_free_field(v2.global_position, 0, v2)
	_expect(free_for_v2 != Vector2i(-1, -1) and free_for_v2 != f0.origin_cell, "second villager is offered a different free field")

	# --- tapping-path helper spreads villagers over free fields
	var crew: Array = []
	for i in 3:
		crew.append(_villager(0, mill.global_position + Vector3(1.0 * i, 0, 3.0)))
	var sent: int = game.send_villagers_to_fields(crew, 0, mill.global_position)
	var targets := {}
	for u in crew:
		targets[u.target_cell] = true
	_expect(sent == 3 and targets.size() == 3, "3 villagers sent to 3 different fields (sent %d)" % sent)

	# --- placing a building on a field is refused
	var placing_ok := true
	for dx in 2:
		for dy in 2:
			if not mg.is_cell_buildable(fields[1].origin_cell + Vector2i(dx, dy)):
				placing_ok = false
	_expect(not placing_ok, "a building cannot be placed over a field")

	# --- save -> load keeps fields farmable
	var path := "user://saves/test_farm_fields.json"
	_expect(SaveManager.save_game(game, path), "game saved")
	SaveManager.load_game(game, path)
	await process_frame
	var restored := 0
	for b in game.buildings:
		if is_instance_valid(b) and b.building_type == Building3D.BuildingType.FARM and b.is_completed:
			restored += 1
	_expect(restored == fields.size() and mg.farm_fields.size() == fields.size(), "after load: %d finished fields, %d food sources" % [restored, mg.farm_fields.size()])
	var restored_walk := true
	for origin in mg.farm_fields.keys():
		restored_walk = restored_walk and mg.is_cell_walkable(origin) and not mg.is_cell_buildable(origin)
	_expect(restored_walk, "after load: field cells walkable, not buildable")

	# --- destroying a field removes the food source
	var some_field = null
	for b in game.buildings:
		if is_instance_valid(b) and b.building_type == Building3D.BuildingType.FARM:
			some_field = b
			break
	var o: Vector2i = some_field.origin_cell
	some_field.die()
	await process_frame
	_expect(not mg.farm_fields.has(o) and not mg.field_cells.has(o), "destroyed field is no longer a food source")
	_expect(mg.is_cell_buildable(o), "its ground is buildable again")

	await _fields_on_slopes()

	Engine.time_scale = 1.0
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

## Mills with six fields on several maps and seeds, on whatever slope the spot has.
func _fields_on_slopes() -> void:
	var fields_seen := 0
	var sunk := 0
	var floating_without_bank := 0
	var unit_inside := 0
	var tap_miss := 0
	var mill_miss := 0
	var steepest := 0.0
	for mt in [0, 1, 2, 3]:
		for sd in [11, 22]:
			seed(sd)
			game._on_start_game_requested(0, 1, mt)
			game.enemy_ai.set_process(false)
			if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
				game.tutorial_mgr.stop_tutorial()
			var mg = game.map_gen
			var base: Vector2i = mg.world_to_cell(mg.player_start_pos)
			var mill = null
			for dx in range(-8, 9, 2):
				for dy in range(-10, 1, 2):
					if mill != null:
						break
					var o: Vector2i = base + Vector2i(dx, dy)
					var ok := true
					for cx in 2:
						for cy in 2:
							var c := o + Vector2i(cx, cy)
							if not mg.is_valid_cell(c.x, c.y) or not mg.is_cell_buildable(c) or not mg.get_resource_at_cell(c).is_empty():
								ok = false
					if ok and mg.is_area_level(o, Vector2i(2, 2)):
						mill = game.place_building(Building3D.BuildingType.MILL, 0, o, false)
			if mill == null:
				continue
			game.team_resources[0]["wood"] = 5000
			var fields: Array = []
			for i in game.MAX_FIELDS_PER_MILL:
				var f = game.try_add_field(mill, 0)
				if f == null:
					break
				f.contribute_construction(1000.0)
				fields.append(f)
			for u in game.units:
				if u.team == 0:
					u.command_stop()
					u.global_position = mg.cell_to_world(base + Vector2i(0, 6))
			game.camera.global_position.x = mill.global_position.x
			game.camera.global_position.z = mill.global_position.z + 10.0
			await process_frame
			await process_frame
			for f in fields:
				fields_seen += 1
				var r: Vector2 = mg.get_footprint_height_range(f.origin_cell, f.grid_size)
				steepest = maxf(steepest, r.y - r.x)
				if r.y > f.global_position.y + 0.01:
					sunk += 1
				if r.y - r.x > 0.03 and not is_instance_valid(f.get_node_or_null("FieldBank")):
					floating_without_bank += 1
				if mg.get_height_at(f.global_position) < f.global_position.y - 0.01:
					unit_inside += 1
				var scr: Vector2 = game.camera.unproject_position(f.global_position + Vector3(0, 0.1, 0))
				if game._get_entity_at_position(scr, game.camera.raycast_ground(scr)) != f:
					tap_miss += 1
			for hf in [0.3, 0.8]:
				var ms: Vector2 = game.camera.unproject_position(mill.global_position + Vector3(0, mill.model_height * hf, 0))
				if game._get_entity_at_position(ms, game.camera.raycast_ground(ms)) != mill:
					mill_miss += 1
	_expect(fields_seen >= 30 and steepest > 0.4, "fields placed on %d spots, steepest ground under one: %.2f m" % [fields_seen, steepest])
	_expect(sunk == 0, "no field sinks into the slope (%d sunk)" % sunk)
	_expect(floating_without_bank == 0, "every field on a slope has a soil bank under its low side (%d without)" % floating_without_bank)
	_expect(unit_inside == 0, "units on a field stand on it, not inside it (%d fields)" % unit_inside)
	_expect(tap_miss == 0, "tapping a field picks that field, also behind the Mill (%d of %d missed)" % [tap_miss, fields_seen])
	_expect(mill_miss == 0, "tapping the Mill (body or roof) still picks the Mill (%d missed)" % mill_miss)
