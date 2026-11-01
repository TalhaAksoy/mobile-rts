extends SceneTree
## Villagers gather one resource at a time:
##  * a new villager carries at most 5 (techs add to it)
##  * every swing adds exactly 1 to the load (wood, gold, stone, berries), so the "x/5" count goes up 1 by 1
##  * a full load of 5 is delivered and the team gets exactly 5
##  * a civ gather bonus makes the swings faster, never bigger (Sarazenler: gold x1.30)
##  * the villager works right next to the node and unloads right next to the drop-off building
##    (it used to stop up to 3 m short of both)

const DT := 0.033

var failures := 0
var start_pos := Vector3.ZERO

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	print("[%s] %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		failures += 1

## Gathers from `cell` until one load is delivered. Returns the load steps seen, the first and the
## last swing time, and how much the team got.
func _one_trip(game: GameController3D, vill: Unit3D, cell: Vector2i, kind: String) -> Dictionary:
	vill.carried_resource = 0
	vill.global_position = _walkable_near(game.map_gen, start_pos)
	var before: int = game.team_resources[0][kind]
	vill.command_gather(cell, kind)
	var steps: Array = []
	var last := 0
	var t := 0.0
	var first_at := -1.0
	var full_at := -1.0
	var swing_dist := 0.0
	var drop_dist := -1.0
	while t < 120.0:
		vill._physics_process(DT)
		t += DT
		var c: int = vill.carried_resource
		if c != last:
			if c > last:
				steps.append(c - last)
				swing_dist = maxf(swing_dist, _dist_to_cells(vill.global_position, cell, Vector2i.ONE))
				if first_at < 0.0:
					first_at = t
				if c >= vill.max_carry and full_at < 0.0:
					full_at = t
			last = c
		if game.team_resources[0][kind] > before:
			drop_dist = INF
			for b in game.get_team_buildings(0):
				if is_instance_valid(b) and b.is_completed:
					drop_dist = minf(drop_dist, _dist_to_cells(vill.global_position, b.origin_cell, b.grid_size))
			break
	return {"steps": steps, "first": first_at, "full": full_at, "got": game.team_resources[0][kind] - before,
		"swing_dist": swing_dist, "drop_dist": drop_dist}

## The closest source cell a villager at `to` can walk up to (the random map sometimes walls a
## stone or gold node in with trees; that one is skipped).
func _nearest(cells: Array, to: Vector3, mg) -> Vector2i:
	var sorted := cells.duplicate()
	sorted.sort_custom(func(a, b): return mg.cell_to_world(a).distance_to(to) < mg.cell_to_world(b).distance_to(to))
	var from: Vector3 = _walkable_near(mg, to)
	for c in sorted:
		var path: Array = mg.get_path_to_target(from, mg.cell_to_world(c))
		if path.is_empty():
			continue
		var end: Vector2i = mg.world_to_cell(path[-1])
		if maxi(absi(end.x - c.x), absi(end.y - c.y)) <= 1:
			return c
	return sorted[0]

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	var game = scene as GameController3D
	game.start_match()
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	game.enemy_ai.set_process(false)

	var vill: Unit3D = null
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vill = u
			break
	_check(vill != null and vill.max_carry == 5, "a new villager carries at most 5 (got %d)" % (vill.max_carry if vill else -1))
	if vill == null:
		quit(1)
		return

	var mg = game.map_gen
	start_pos = vill.global_position
	var sources := {"wood": mg.trees, "gold": mg.gold_mines, "stone": mg.stone_mines, "food": mg.berry_bushes}
	var camp := {"wood": Building3D.BuildingType.LUMBER_CAMP, "gold": Building3D.BuildingType.MINING_CAMP,
		"stone": Building3D.BuildingType.MINING_CAMP, "food": Building3D.BuildingType.MILL}
	var base_gold_time := 0.0
	for kind in ["wood", "gold", "stone", "food"]:
		var cells: Array = sources[kind].keys()
		if cells.is_empty():
			_check(false, "%s: the map has a source" % kind)
			continue
		var cell: Vector2i = _nearest(cells, start_pos, mg)
		game.place_building(camp[kind], 0, cell + Vector2i(2, 0), false)
		var r := _one_trip(game, vill, cell, kind)
		_check(r["swing_dist"] <= 0.7,
			"%s: works right next to the node (%.2f m from it at most)" % [kind, r["swing_dist"]])
		_check(r["drop_dist"] >= 0.0 and r["drop_dist"] <= 0.9,
			"%s: unloads right next to the building (%.2f m from its wall)" % [kind, r["drop_dist"]])
		var steps: Array = r["steps"]
		_check(steps.size() == 5 and steps.all(func(s): return s == 1),
			"%s: the load goes up 1 by 1 to 5 (steps %s)" % [kind, str(steps)])
		_check(r["got"] == 5, "%s: one trip delivers 5 (got %d)" % [kind, r["got"]])
		if kind == "gold":
			base_gold_time = r["full"] - r["first"]

	# civ bonus: faster swings, still 1 each
	vill.civ_type = CivData.CivType.SARACENS
	var gcell: Vector2i = _nearest(mg.gold_mines.keys(), start_pos, mg)
	var rs := _one_trip(game, vill, gcell, "gold")
	var steps_s: Array = rs["steps"]
	var t_s: float = rs["full"] - rs["first"]
	_check(steps_s.size() == 5 and steps_s.all(func(s): return s == 1), "Sarazenler gold: still 1 per swing (steps %s)" % str(steps_s))
	_check(base_gold_time > 0.0 and t_s < base_gold_time * 0.85,
		"Sarazenler gold: swings are faster (%.2fs vs %.2fs for 4 swings)" % [t_s, base_gold_time])

	# a carry tech raises the limit, the load still counts 1 by 1
	vill.civ_type = CivData.CivType.OTTOMANS
	vill.max_carry += 3
	var rt := _one_trip(game, vill, _nearest(mg.trees.keys(), start_pos, mg), "wood")
	_check(rt["got"] == 8 and (rt["steps"] as Array).all(func(s): return s == 1), "with +3 carry a trip is 8, 1 by 1 (got %d)" % rt["got"])

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

## Ground distance from `p` to the edge of the cell block `origin` .. `origin + size` (0 inside it).
static func _dist_to_cells(p: Vector3, origin: Vector2i, size: Vector2i) -> float:
	var t := MapGenerator3D.TILE_SIZE
	var dx := maxf(maxf(origin.x * t - p.x, p.x - (origin.x + size.x) * t), 0.0)
	var dz := maxf(maxf(origin.y * t - p.z, p.z - (origin.y + size.y) * t), 0.0)
	return Vector2(dx, dz).length()

## A drop-off camp placed for an earlier step may stand on the start cell: start from the nearest
## walkable cell instead (a unit inside a building footprint finds no path).
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
