extends SceneTree
## Every player villager shows what it is doing without being tapped (VillagerBadge):
##  * a badge on each player villager, visible while not selected; none on bot villagers or soldiers
##  * idle -> idle icon; gathering gold -> gold icon, load "n/5" counting up 1 by 1; carrying -> carry icon
##    with the full load; building -> build icon with the progress
##  * selecting the villager hides the badge (the long status line shows), deselecting brings it back
##  * every activity/resource pair has its own icon

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	print("[%s] %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		failures += 1

## One real physics frame; returns the game time it took (the test runs at Engine.time_scale 4).
func _tick() -> float:
	await physics_frame
	return 1.0 / Engine.physics_ticks_per_second * Engine.time_scale

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	var game = scene as GameController3D
	game.start_match()
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	game.enemy_ai.set_process(false)
	await process_frame

	var mine: Array = game.units.filter(func(u): return u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER)
	var bot_vills: Array = game.units.filter(func(u): return u.team != 0 and u.unit_type == Unit3D.UnitType.VILLAGER)
	_check(mine.size() >= 3 and mine.all(func(u): return u.badge != null and u.badge.visible),
		"every player villager has a visible badge without being selected (%d)" % mine.size())
	_check(not bot_vills.is_empty() and bot_vills.all(func(u): return u.badge == null), "bot villagers have no badge")
	var soldier: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, mine[0].global_position + Vector3(2, 0, 0))
	_check(soldier.badge == null, "soldiers have no badge")
	game.units.erase(soldier)
	soldier.free()   # it stood in the villager's way

	var vill: Unit3D = mine[0]
	for u in mine:
		u.command_stop()
	# only `vill` is stepped below: the others would stand still in its way, so park them aside
	for i in range(1, mine.size()):
		mine[i].global_position = game.map_gen.cell_to_world(Vector2i(1, 1 + i))
	await _tick()
	_check(vill.badge.key == "idle/idle" and not vill.badge.count.visible, "idle villager: idle icon, no load (%s)" % vill.badge.key)

	# gathering gold next to a mining camp
	var mg = game.map_gen
	var gold: Vector2i = _reachable_nearest(mg, mg.gold_mines.keys(), vill.global_position)
	# the Town Center takes the gold (a camp placed next to the node could wall it in)
	vill.command_gather(gold, "gold")
	var seen: Array = []
	var gather_key := ""
	var t := 0.0
	Engine.time_scale = 4.0
	while t < 90.0 and vill.state != Unit3D.State.RETURNING_RESOURCES:
		t += await _tick()
		if vill.state == Unit3D.State.GATHERING:
			gather_key = vill.badge.key
			var txt: String = vill.badge.count.text
			if seen.is_empty() or seen[-1] != txt:
				seen.append(txt)
	_check(gather_key == "gather/gold", "gathering gold: gold icon (%s)" % gather_key)
	_check(seen.size() >= 5 and seen.slice(seen.size() - 5) == ["0/5", "1/5", "2/5", "3/5", "4/5"],
		"the load on the badge counts up 1 by 1 (%s)" % str(seen))
	_check(vill.badge.key == "return/gold" and vill.badge.count.text == "5/5", "carrying: carry icon with 5/5 (%s %s)" % [vill.badge.key, vill.badge.count.text])

	# selection hides it, deselecting brings it back
	vill.set_selected(true)
	await _tick()
	_check(not vill.badge.visible and vill.status_label.visible, "selected: badge hidden, long status line shown")
	vill.set_selected(false)
	await _tick()
	_check(vill.badge.visible and not vill.status_label.visible, "deselected: badge back")

	# building
	var spot := Vector2i(-1, -1)
	var base: Vector2i = mg.world_to_cell(vill.global_position)
	for r in range(2, 12):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				var o: Vector2i = base + Vector2i(dx, dy)
				var ok := true
				for cx in 2:
					for cy in 2:
						var c := o + Vector2i(cx, cy)
						if not mg.is_valid_cell(c.x, c.y) or not mg.is_cell_buildable(c):
							ok = false
				if ok and spot == Vector2i(-1, -1) and mg.is_area_level(o, Vector2i(2, 2)):
					spot = o
	var house = game.place_building(Building3D.BuildingType.HOUSE, 0, spot, true)
	vill.carried_resource = 0
	vill.command_build(house)
	t = 0.0
	var build_key := ""
	var build_txt := ""
	while t < 60.0 and not house.is_completed:
		t += await _tick()
		if vill.state == Unit3D.State.BUILDING and house.construction_progress > 0.0:
			build_key = vill.badge.key
			build_txt = vill.badge.count.text
	_check(build_key == "build/build" and build_txt.begins_with("%"), "building: build icon with progress (%s %s)" % [build_key, build_txt])

	# distinct icons
	var keys := ["gather/wood", "gather/gold", "gather/stone", "gather/food", "return/food", "build/build", "idle/idle", "move/move"]
	var texes := {}
	for k in keys:
		var parts: PackedStringArray = k.split("/")
		texes[VillagerBadge.icon_texture(parts[0], parts[1]).get_rid()] = true
	_check(texes.size() == keys.size(), "every activity/resource pair has its own icon (%d of %d)" % [texes.size(), keys.size()])

	Engine.time_scale = 1.0
	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

## Closest node a villager at `from` can walk up to (the random map can wall one in with trees).
func _reachable_nearest(mg, cells: Array, from: Vector3) -> Vector2i:
	var sorted := cells.duplicate()
	sorted.sort_custom(func(a, b): return mg.cell_to_world(a).distance_to(from) < mg.cell_to_world(b).distance_to(from))
	for c in sorted:
		var path: Array = mg.get_path_to_target(from, mg.cell_to_world(c))
		if path.is_empty():
			continue
		var end: Vector2i = mg.world_to_cell(path[-1])
		if maxi(absi(end.x - c.x), absi(end.y - c.y)) <= 1:
			return c
	return sorted[0]

## A camp placed for the test may cover the villager's cell: step to the nearest walkable one.
func _walkable_near(mg, p: Vector3) -> Vector3:
	var c: Vector2i = mg.world_to_cell(p)
	if mg.is_cell_walkable(c):
		return p
	for r in range(1, 8):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if mg.is_valid_cell(n.x, n.y) and mg.is_cell_walkable(n):
					return mg.cell_to_world(n)
	return p
