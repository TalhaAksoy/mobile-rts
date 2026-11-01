extends SceneTree
## Building placement and construction crews:
##  * picking a building to place shows a bar with "İPTAL"; it leaves placement without spending anything
##  * Escape / Android Back first leaves placement, only the next press opens the pause menu
##  * placing with 7 villagers selected puts 5 on the site (MAX_BUILDERS); the others keep their orders
##  * a selected site shows "İnşaatçı n/5", "+ Köylü Ekle" (nearest idle villager; nothing when full)
##    and "İnşaatı İptal Et"
##  * 5 builders build about 5 times as fast as one
##  * cancelling a site refunds the part not built yet, frees its builders and its ground
##  * the placement ghost is red (with the reason in the bar) on trees, and where villagers can't walk
##    to; green on free, level, reachable ground; tapping a red spot places nothing

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	print("[%s] %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		failures += 1

func _frames(n: int) -> void:
	for i in n:
		await process_frame

## Scene tree timers already run on game time (Engine.time_scale).
func _wait_game(secs: float) -> void:
	await create_timer(secs).timeout

## Free level 2x2 spot for a house, `skip` spots away from the villagers.
func _house_spot(mg, near: Vector2i, taken: Array) -> Vector2i:
	for r in range(3, 14):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				var o: Vector2i = near + Vector2i(dx, dy)
				var ok := true
				for cx in 2:
					for cy in 2:
						var c := o + Vector2i(cx, cy)
						if not mg.is_valid_cell(c.x, c.y) or not mg.is_cell_buildable(c):
							ok = false
				for t in taken:
					if absi(o.x - t.x) < 4 and absi(o.y - t.y) < 4:
						ok = false
				if ok and mg.is_area_level(o, Vector2i(2, 2)) and _reachable(mg, near, o):
					return o
	return Vector2i(-1, -1)

## The villagers at `from` can walk next to a 2x2 site at `o` (the random map can put it behind a
## row of trees).
func _reachable(mg, from: Vector2i, o: Vector2i) -> bool:
	var path: Array = mg.get_path_to_target(mg.cell_to_world(from), mg.cell_to_world(o) + Vector3(1, 0, 1))
	if path.is_empty():
		return false
	var end: Vector2i = mg.world_to_cell(path[-1])
	return end.x >= o.x - 1 and end.x <= o.x + 2 and end.y >= o.y - 1 and end.y <= o.y + 2

func _button(ui, name: String) -> Button:
	return ui.action_flow.find_child(name, true, false) as Button

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	await _frames(2)
	var game = scene as GameController3D
	game.start_match()
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	game.enemy_ai.set_process(false)
	await _frames(2)
	var ui = game.ui_manager
	var mg = game.map_gen
	game.team_resources[0]["wood"] = 1000

	# --- placement can be cancelled
	game._on_build_selected(Building3D.BuildingType.HOUSE)
	await _frames(1)
	_check(game.is_placing_building and ui.placement_bar != null and ui.placement_bar.visible and "Ev" in ui.placement_label.text,
		"picking a House shows the placement bar (%s)" % (ui.placement_label.text if ui.placement_label else ""))
	var cancel_btn: Button = ui.placement_bar.find_child("CancelPlacementButton", true, false)
	cancel_btn.emit_signal("pressed")
	await _frames(1)
	_check(not game.is_placing_building and not ui.placement_bar.visible and not game.ghost_preview.visible and game.team_resources[0]["wood"] == 1000,
		"İPTAL leaves placement, nothing spent")

	game._on_build_selected(Building3D.BuildingType.BARRACKS)
	var pm = ui.pause_menu
	pm._handle_back()
	await _frames(1)
	_check(not game.is_placing_building and not pm.visible, "Back while placing: placement cancelled, no pause menu")
	pm._handle_back()
	await _frames(2)
	_check(pm.visible, "next Back opens the pause menu")
	pm._handle_back()
	await _frames(2)

	# --- red / green ghost
	var tree_cell: Vector2i = mg.trees.keys()[0]
	var bestd := INF
	for c in mg.trees.keys():
		var d: float = mg.cell_to_world(c).distance_to(game.get_team_buildings(0)[0].global_position)
		if d < bestd:
			bestd = d
			tree_cell = c
	game._on_build_selected(Building3D.BuildingType.HOUSE)
	game.update_ghost(tree_cell)
	var gmat := game.ghost_preview.material_override as StandardMaterial3D
	_check(game.ghost_reason == "Burada ağaç ya da kaynak var" and gmat.emission == game.GHOST_BAD and "ağaç" in ui.placement_label.text,
		"over a tree: red ghost, the bar says why (%s)" % ui.placement_label.text)
	var wood_before: int = game.team_resources[0]["wood"]
	game._attempt_place_building(mg.cell_to_world(tree_cell))
	_check(game.is_placing_building and game.team_resources[0]["wood"] == wood_before, "tapping the red spot places nothing, placement stays on")
	var ok_spot: Vector2i = _house_spot(mg, mg.world_to_cell(game.units.filter(func(u): return u.team == 0)[0].global_position), [])
	game.update_ghost(ok_spot)
	_check(game.ghost_reason == "" and gmat.emission == game.GHOST_OK and "dokun" in ui.placement_label.text, "free, level, reachable ground: green ghost")
	# wall a free spot in (a ring of blocked cells two cells out): the villagers can't walk there
	var walled := Vector2i(-1, -1)
	for o_x in range(2, mg.MAP_WIDTH - 4):
		for o_y in range(2, mg.MAP_HEIGHT - 4):
			if walled != Vector2i(-1, -1):
				break
			# any spot the house can go now, with no unit inside the ring that will wall it in
			var o := Vector2i(o_x, o_y)
			var ok := true
			for u in game.units:
				var uc: Vector2i = mg.world_to_cell(u.global_position)
				if uc.x >= o.x - 2 and uc.x <= o.x + 3 and uc.y >= o.y - 2 and uc.y <= o.y + 3:
					ok = false
			if ok and game.placement_block_reason(Building3D.BuildingType.HOUSE, o) == "":
				walled = o
	var wall_cells: Array = []
	var dummy := Node3D.new()
	for x in range(walled.x - 2, walled.x + 4):
		for y in range(walled.y - 2, walled.y + 4):
			if x == walled.x - 2 or x == walled.x + 3 or y == walled.y - 2 or y == walled.y + 3:
				wall_cells.append(Vector2i(x, y))
				mg.register_building_cells(Vector2i(x, y), Vector2i.ONE, dummy)
	_check(walled != Vector2i(-1, -1) and game.placement_block_reason(Building3D.BuildingType.HOUSE, walled) == "Köylüler buraya ulaşamaz",
		"a free spot walled in: Köylüler buraya ulaşamaz (%s)" % game.placement_block_reason(Building3D.BuildingType.HOUSE, walled))
	for c in wall_cells:
		mg.unregister_building_cells(c, Vector2i.ONE)
	dummy.free()
	_check(game.placement_block_reason(Building3D.BuildingType.HOUSE, walled) == "", "the same spot with the wall gone is fine again")
	game.cancel_building_placement()

	# --- 7 villagers selected, 5 build
	var tc = game.get_team_buildings(0)[0]
	var first = game.units.filter(func(u): return u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER)[0]
	for i in 6:
		game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, first.global_position + Vector3(0.3 * i, 0, 0.2 * i))
	var vills: Array = game.units.filter(func(u): return u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER)
	for u in vills:
		u.command_stop()
	var sel: Array = vills.slice(0, 7)
	game.selected_units.clear()
	for u in sel:
		game.selected_units.append(u)
	var spot: Vector2i = _house_spot(mg, mg.world_to_cell(first.global_position), [])
	game._on_build_selected(Building3D.BuildingType.HOUSE)
	game._attempt_place_building(mg.cell_to_world(spot))
	await _frames(1)
	var site: Building3D = null
	for b in game.buildings:
		if is_instance_valid(b) and b.team == 0 and not b.is_completed and b.origin_cell == spot:
			site = b
	_check(site != null and not game.is_placing_building and not ui.placement_bar.visible, "house placed, placement bar gone")
	var crew: Array = game.get_site_builders(site)
	_check(crew.size() == 5 and sel.filter(func(u): return u.state == Unit3D.State.BUILDING).size() == 5,
		"7 villagers selected: 5 build it (%d)" % crew.size())

	# --- site panel
	game.selected_units.clear()
	game.selected_building = site
	ui.set_selected_entity(site)
	await _frames(1)
	_check(ui.builders_label != null and ui.builders_label.text == "İnşaatçı: 5/5" and _button(ui, "AddBuilderButton") != null and _button(ui, "CancelConstructionButton") != null,
		"selected site shows İnşaatçı 5/5, + Köylü Ekle and İnşaatı İptal Et (%s)" % (ui.builders_label.text if ui.builders_label else "-"))
	_check(game.add_builder_to_site(site) == null and game.get_site_builders(site).size() == 5, "crew full: nobody else is sent")
	crew[0].command_stop()
	var idle_one: Unit3D = crew[0]
	var other_idle: Unit3D = vills[7] if vills.size() > 7 else null
	_button(ui, "AddBuilderButton").emit_signal("pressed")
	await _frames(1)
	_check(game.get_site_builders(site).size() == 5, "+ Köylü Ekle fills the free slot (%d/5)" % game.get_site_builders(site).size())
	_check(ui.builders_label != null and ui.builders_label.text == "İnşaatçı: 5/5", "panel shows the new crew size")

	# --- speed: 5 builders vs 1, both crews already standing next to their sites (no walking)
	Engine.time_scale = 4.0
	var near_cell: Vector2i = mg.world_to_cell(first.global_position)
	var spot_a: Vector2i = _house_spot(mg, near_cell, [spot])
	var site_a: Building3D = game.place_building(Building3D.BuildingType.HOUSE, 0, spot_a, true)
	var spot2: Vector2i = _house_spot(mg, near_cell, [spot, spot_a])
	var site1: Building3D = game.place_building(Building3D.BuildingType.HOUSE, 0, spot2, true)
	var crew_a: Array = []
	for i in 5:
		var v: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, _beside(mg, spot_a, i))
		crew_a.append(v)
	var solo: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, _beside(mg, spot2, 0))
	_check(game.assign_builders(site_a, crew_a) == 5, "5 fresh villagers put on a new site")
	solo.command_build(site1)
	await _wait_game(0.6)   # first swings
	var pa := site_a.construction_progress
	var p1 := site1.construction_progress
	await _wait_game(1.0)
	var rate5: float = site_a.construction_progress - pa
	var rate1: float = site1.construction_progress - p1
	_check(rate1 > 0.0 and rate5 >= rate1 * 4.0, "5 builders build about 5x as fast as one (%.1f%%/s vs %.1f%%/s)" % [rate5, rate1])
	Engine.time_scale = 1.0

	# --- cancel with refund
	var prog: float = site1.construction_progress
	var wood0: int = game.team_resources[0]["wood"]
	var expect: int = int(ceil(30.0 * (1.0 - prog / 100.0)))
	game.selected_building = site1
	ui.set_selected_entity(site1)
	await _frames(1)
	_button(ui, "CancelConstructionButton").emit_signal("pressed")
	await _frames(2)
	_check(not is_instance_valid(site1) or site1.is_queued_for_deletion(), "İnşaatı İptal Et removes the site")
	_check(not game.buildings.has(site1), "and it is no longer one of the player's buildings")
	_check(game.team_resources[0]["wood"] - wood0 == expect, "refund is the unbuilt part: +%d wood at %.0f%% (expected %d)" % [game.team_resources[0]["wood"] - wood0, prog, expect])
	_check(solo.state == Unit3D.State.IDLE, "its builder is free again")
	var free_ground := true
	for cx in 2:
		for cy in 2:
			free_ground = free_ground and mg.is_cell_buildable(spot2 + Vector2i(cx, cy))
	_check(free_ground, "its ground can be built on again")

	# untouched site: full refund
	var spot3: Vector2i = _house_spot(mg, mg.world_to_cell(first.global_position), [spot])
	var site3: Building3D = game.place_building(Building3D.BuildingType.HOUSE, 0, spot3, true)
	var w3: int = game.team_resources[0]["wood"]
	game.cancel_construction(site3)
	_check(game.team_resources[0]["wood"] - w3 == 30, "a site nobody worked on refunds its whole cost (+%d)" % (game.team_resources[0]["wood"] - w3))

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

## A walkable cell right next to the 2x2 site at `o` (the i-th one found), as a world position.
func _beside(mg, o: Vector2i, i: int) -> Vector3:
	var ring: Array = []
	for dx in range(-1, 3):
		for dy in range(-1, 3):
			if dx in [0, 1] and dy in [0, 1]:
				continue
			var c: Vector2i = o + Vector2i(dx, dy)
			if mg.is_valid_cell(c.x, c.y) and mg.is_cell_walkable(c):
				ring.append(c)
	return mg.cell_to_world(ring[i % ring.size()])
