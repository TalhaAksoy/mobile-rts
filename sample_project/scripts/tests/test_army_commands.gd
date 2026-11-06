extends SceneTree
## Army orders and unit spacing on the real Main3D scene:
##  1. Spacing: units never overlap more than half their body radius (stacked units are pushed apart).
##  2. Attack-move (SALDIR on the ground): marching soldiers engage an enemy they meet, then carry on to the spot.
##  3. Attack order on a target (SALDIR on an enemy): kill it, then attack the next enemy nearby.
##  4. Defend (SAVUN): hold the spot, attack enemies that come close, walk back after the fight; ignore enemies
##     far from the spot.
##  5. UI: selecting soldiers shows SALDIR / SAVUN / DUR; the buttons arm the next tap.
##  6. 2D style: fields lie under units (a farmer is drawn on top of its field), trees do not sway.

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")

var failures := 0
var game: GameController3D

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _simulate(seconds: float, stop_cond: Callable = Callable()) -> float:
	var t := 0.0
	while t < seconds:
		await physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		if stop_cond.is_valid() and stop_cond.call():
			break
	return t

func _hd(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

## an open walkable spot near the player's base, shifted by `off` cells
func _spot(off: Vector2i) -> Vector3:
	var c: Vector2i = game.map_gen.world_to_cell(game.map_gen.player_start_pos) + off
	for r in range(0, 12):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var cc := c + Vector2i(dx, dy)
				if game.map_gen.is_cell_walkable(cc):
					return game.map_gen.cell_to_world(cc)
	return game.map_gen.cell_to_world(c)

## centre of a walkable (2r+1)x(2r+1) block near the base, shifted by `off` cells
func _open_spot(off: Vector2i, r0: int) -> Vector3:
	var c: Vector2i = game.map_gen.world_to_cell(game.map_gen.player_start_pos) + off
	for r in range(0, 16):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var cc := c + Vector2i(dx, dy)
				var ok := true
				for yy in range(-r0, r0 + 1):
					for xx in range(-r0, r0 + 1):
						if not game.map_gen.is_cell_walkable(cc + Vector2i(xx, yy)):
							ok = false
				if ok:
					return game.map_gen.cell_to_world(cc)
	return _spot(off)

## a walkable spot `off` cells from `from` that a unit standing at `from` can walk to
func _reach(from: Vector3, off: Vector2i) -> Vector3:
	var c: Vector2i = game.map_gen.world_to_cell(from) + off
	for r in range(0, 14):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var cc := c + Vector2i(dx, dy)
				if game.map_gen.is_cell_walkable(cc):
					var p: Vector3 = game.map_gen.cell_to_world(cc)
					if game.map_gen.get_path_to_target(from, p).size() > 0:
						return p
	return from

func _clear_units() -> void:
	for u in game.units.duplicate():
		if is_instance_valid(u):
			game.units.erase(u)
			u.queue_free()
	await physics_frame

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	game = scene as GameController3D
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed(int(a.substr(7)))                 # reproduce one map (debugging)
	game.start_match()
	game.enemy_ai.set_process(false)
	game.enemy_ai.set_physics_process(false)
	for b in game.buildings:
		if is_instance_valid(b) and b.team != 0:
			b.set_process(false)
			b.set_physics_process(false)
	await _clear_units()

	# --- 1. spacing ---------------------------------------------------------------------------------
	var p0 := _spot(Vector2i(0, 7))
	var pile: Array = []
	for i in 6:
		pile.append(game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, p0 + Vector3(0.01 * i, 0, 0.01 * i)))
	await _simulate(1.5)
	var worst := 99.0
	for i in pile.size():
		for j in range(i + 1, pile.size()):
			var a: Unit3D = pile[i]
			var b: Unit3D = pile[j]
			worst = minf(worst, _hd(a.global_position, b.global_position) / (0.5 * (a.get_body_radius() + b.get_body_radius())))
	_check(worst >= 0.97, "6 stacked swordsmen pushed apart to at least half their combined body radius (worst %.2f)" % worst)
	var all_walkable := true
	for u in pile:
		if not game.map_gen.is_cell_walkable(game.map_gen.world_to_cell(u.global_position)):
			all_walkable = false
	_check(all_walkable, "spacing never pushes a unit onto an unwalkable cell")
	var mover: Unit3D = pile[0]
	var out_dest := _reach(p0, Vector2i(6, 0))
	mover.command_move(out_dest)
	await _simulate(8.0, func(): return mover.state == Unit3D.State.IDLE)
	_check(_hd(mover.global_position, out_dest) < 1.6, "a unit still walks out of a crowd to its destination")
	await _clear_units()

	# 12 mixed soldiers all sent to the exact same point: they settle around it, none deeper than the limit
	var goal := _open_spot(Vector2i(6, -6), 2)             # room for a crowd (a hemmed-in pocket cannot hold 12)
	var c0 := _reach(goal, Vector2i(-4, 0))
	var kinds := [Unit3D.UnitType.SWORDSMAN, Unit3D.UnitType.SPEARMAN, Unit3D.UnitType.ARCHER, Unit3D.UnitType.CAVALRY]
	var crowd: Array = []
	for i in 12:
		crowd.append(game.spawn_unit(kinds[i % 4], 0, c0 + Vector3((i % 4) * 0.4 - 0.6, 0, (i / 4) * 0.4 - 0.4)))
	await physics_frame
	for u in crowd:
		(u as Unit3D).command_move(goal)
	await _simulate(10.0, func(): return crowd.all(func(u): return u.state == Unit3D.State.IDLE))
	await _simulate(1.0, func(): return false)
	var cw := 99.0
	for i in crowd.size():
		for j in range(i + 1, crowd.size()):
			cw = minf(cw, _hd(crowd[i].global_position, crowd[j].global_position) / (0.5 * (crowd[i].get_body_radius() + crowd[j].get_body_radius())))
	_check(crowd.all(func(u): return u.state == Unit3D.State.IDLE), "12 soldiers sent to one point all come to rest")
	_check(cw >= 0.97, "12 soldiers sent to one point never overlap more than half their body radius (worst %.2f)" % cw)
	await _clear_units()

	# --- 2. attack-move -----------------------------------------------------------------------------
	var a0 := _spot(Vector2i(-6, 8))
	var dest := _reach(a0, Vector2i(10, 0))
	var sw: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, a0)
	var foe: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 1, _reach(a0, Vector2i(5, 1)))
	foe.set_physics_process(false)
	await physics_frame
	sw.command_attack_move(dest)
	var foe_ref = weakref(foe)
	await _simulate(25.0, func(): return foe_ref.get_ref() == null)
	_check(foe_ref.get_ref() == null, "attack-move: the swordsman engaged and killed the enemy on its way")
	# arrival = the game's own ORDER_ARRIVE + 0.5 (spacing may nudge a unit that already stands at its spot)
	var arrive := Unit3D.ORDER_ARRIVE + 0.5
	await _simulate(15.0, func(): return _hd(sw.global_position, dest) < arrive and sw.state == Unit3D.State.IDLE)
	_check(_hd(sw.global_position, dest) < arrive, "attack-move: after the fight it carried on to the ordered spot")
	# plain move ignores the same kind of enemy
	var foe2: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 1, _reach(a0, Vector2i(5, 1)))
	foe2.set_physics_process(false)
	await physics_frame
	sw.command_move(a0)
	await _simulate(12.0, func(): return sw.state == Unit3D.State.IDLE)
	_check(is_instance_valid(foe2) and foe2.hp >= foe2.max_hp, "plain move: the swordsman walked past without fighting")
	await _clear_units()

	# an order to a spot nobody can reach is dropped instead of retried forever
	var lost: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, a0)
	await physics_frame
	lost.command_attack_move(Vector3(-50, 0, -50))
	await _simulate(1.0)
	_check(lost.order == Unit3D.Order.NONE and lost.state == Unit3D.State.IDLE, "an unreachable attack-move is dropped (no endless retry)")
	await _clear_units()

	# --- 3. attack a target, then the next one ------------------------------------------------------
	var t0 := _spot(Vector2i(0, 9))
	var hit: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, t0)
	var tgt: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 1, _reach(t0, Vector2i(2, 0)))
	var nxt: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 1, _reach(t0, Vector2i(3, 1)))
	tgt.set_physics_process(false); nxt.set_physics_process(false)
	await physics_frame
	hit.command_attack_order(tgt)
	var tgt_ref = weakref(tgt)
	var nxt_ref = weakref(nxt)
	await _simulate(25.0, func(): return tgt_ref.get_ref() == null)
	_check(tgt_ref.get_ref() == null, "attack order: the tapped target was destroyed")
	await _simulate(25.0, func(): return nxt_ref.get_ref() == null)
	_check(nxt_ref.get_ref() == null, "attack order: then it went on to the next enemy nearby")
	await _clear_units()

	# --- 4. defend -----------------------------------------------------------------------------------
	var post := _spot(Vector2i(0, 10))
	var guard: Unit3D = game.spawn_unit(Unit3D.UnitType.SPEARMAN, 0, post + Vector3(-5, 0, 0))
	guard.command_defend(post)
	await _simulate(10.0, func(): return _hd(guard.global_position, post) < 1.6 and guard.state == Unit3D.State.IDLE)
	_check(_hd(guard.global_position, post) < 2.1, "defend: the spearman walked to its post")
	var far_foe: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 1, post + Vector3(0, 0, 14))
	far_foe.set_physics_process(false)
	await _simulate(3.0)
	_check(guard.state != Unit3D.State.ATTACKING and is_instance_valid(far_foe) and far_foe.hp >= far_foe.max_hp,
		"defend: an enemy far from the post is ignored")
	far_foe.queue_free()
	game.units.erase(far_foe)
	var raider: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 1, post + Vector3(5, 0, 0))
	raider.set_physics_process(false)
	var raider_ref = weakref(raider)
	await _simulate(20.0, func(): return raider_ref.get_ref() == null)
	_check(raider_ref.get_ref() == null, "defend: an enemy that came close to the post was attacked and killed")
	await _simulate(10.0, func(): return _hd(guard.global_position, post) < 2.1 and guard.state == Unit3D.State.IDLE)
	_check(_hd(guard.global_position, post) < 2.1, "defend: back at the post after the fight")
	await _clear_units()

	# --- 5. UI buttons arm the next tap ------------------------------------------------------------
	var s1: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, _spot(Vector2i(-2, 7)))
	var s2: Unit3D = game.spawn_unit(Unit3D.UnitType.ARCHER, 0, _spot(Vector2i(2, 7)))
	await physics_frame
	game._on_select_all_military()
	await process_frame
	var labels: Array = []
	for c in game.ui_manager.action_flow.get_children():
		if c is Button:
			labels.append((c as Button).text)
	var joined := " ".join(labels)
	_check("SALDIR" in joined and "SAVUN" in joined and "DUR" in joined, "selected army shows SALDIR / SAVUN / DUR (%s)" % joined)
	game.ui_manager.army_command_requested.emit("attack")
	_check(game.pending_army_command == "attack", "SALDIR arms the next tap")
	var spot := _spot(Vector2i(0, 12))
	game._handle_3d_click(game.camera.unproject_position(spot), spot)
	_check(game.pending_army_command == "" and s1.order == Unit3D.Order.ATTACK_MOVE and s2.order == Unit3D.Order.ATTACK_MOVE,
		"the next ground tap became an attack-move for every selected soldier")
	game.ui_manager.army_command_requested.emit("defend")
	game._handle_3d_click(game.camera.unproject_position(spot), spot)
	_check(s1.order == Unit3D.Order.DEFEND and s2.order == Unit3D.Order.DEFEND, "SAVUN + tap = defend order")
	game.ui_manager.army_command_requested.emit("stop")
	_check(s1.order == Unit3D.Order.NONE and s1.state == Unit3D.State.IDLE and s2.state == Unit3D.State.IDLE, "DUR stops every selected unit")
	await _clear_units()

	# --- 6. 2D style: fields under units, no tree sway --------------------------------------------
	var fe: Dictionary = FactionArtManager.get_sprite_entry("fields", "field")
	_check(fe.get("ground", false) == true, "field sprites are flagged as ground (always under units)")
	var plane := Node3D.new()
	plane.set_script(load("res://scripts/ObliqueSort.gd"))
	plane.set_meta("ground", true)
	root.add_child(plane)
	plane.global_position = Vector3(10, 0, 200)          # far south: a normal sprite would sort high
	plane.apply()
	_check(plane.global_position.y < FactionArtManager.oblique_sort_y(0.0), "a ground sprite sorts below any unit, wherever it is")
	plane.queue_free()

	# trees keep still in the 2D style (the wind sway is for the 3D models only)
	var tree_node: Node3D = null
	for td in game.map_gen.trees.values():
		if is_instance_valid(td.get("node")):
			tree_node = td["node"]
			break
	var was_3d := FactionArtManager.use_3d_building_models
	FactionArtManager.use_3d_building_models = false
	if tree_node != null:
		tree_node.rotation.z = 0.0
		for i in 5:
			game.map_gen._process(0.37)
		_check(tree_node.rotation.z == 0.0, "2D style: trees do not sway")
	FactionArtManager.use_3d_building_models = true
	if tree_node != null:
		game.map_gen._process(0.37)
		_check(tree_node.rotation.z != 0.0, "3D style: trees still sway in the wind")
	FactionArtManager.use_3d_building_models = was_3d

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
