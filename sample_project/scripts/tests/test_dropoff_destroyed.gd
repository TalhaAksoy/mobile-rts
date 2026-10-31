extends SceneTree
## Regression: villagers carrying resources to a dropoff that gets destroyed (and freed) on the way.
## The return-resources step cast the freed building ("Trying to cast a freed object"), raising a
## SCRIPT ERROR every physics frame for every such villager (3630 errors in this test before the fix).
## Now they carry on to another dropoff (the Town Center) and the wood arrives. run_tests.sh fails this
## test on any SCRIPT ERROR in its log.
const GameController3D = preload("res://scripts/GameController3D.gd")

var failures := 0

func _check(cond: bool, msg: String) -> void:
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _init() -> void:
	call_deferred("_run")

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _run() -> void:
	seed(31)
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var game = scene as GameController3D
	game.selected_map_type = CivData.MapType.FOREST_VALLEY
	game.start_match()
	game.enemy_ai.set_process(false)
	game.enemy_ai.set_physics_process(false)
	var mg = game.map_gen
	var base: Vector2i = mg.world_to_cell(mg.player_start_pos)

	# a lumber camp some way from the Town Center, villagers carrying wood walk towards it
	var spot := Vector2i(-1, -1)
	for r in range(5, 20):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				var o: Vector2i = base + Vector2i(dx, dy)
				var ok := true
				for c in [o, o + Vector2i(1, 0), o + Vector2i(0, 1), o + Vector2i(1, 1)]:
					if not mg.is_valid_cell(c.x, c.y) or not mg.is_cell_buildable(c) or not mg.get_resource_at_cell(c).is_empty():
						ok = false
				if ok and spot == Vector2i(-1, -1):
					spot = o
	_check(spot != Vector2i(-1, -1), "found a spot for a lumber camp (%s)" % spot)
	var camp = game.place_building(Building3D.BuildingType.LUMBER_CAMP, 0, spot, false)
	var carriers := []
	for i in 3:
		# start on open base ground halfway between the Town Center and the camp
		var start: Vector3 = mg.player_start_pos.lerp(camp.global_position, 0.5) + Vector3(i * 0.6, 0, 0)
		var v: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, start)
		v.resource_type = "wood"
		v.carried_resource = 10
		v.command_return_resources(camp)
		carriers.append(v)
	await _frames(5)
	_check(carriers.all(func(v): return v.state == Unit3D.State.RETURNING_RESOURCES and v.target_entity == camp), "villagers are walking their wood to the camp")

	# the camp is destroyed and freed while they are on their way
	var wood_before: int = game.team_resources[0]["wood"]
	camp.die()
	await _frames(10)
	_check(not is_instance_valid(camp), "the camp is gone (freed)")
	_check(carriers.all(func(v): return not (v.state == Unit3D.State.RETURNING_RESOURCES and not is_instance_valid(v.target_entity))),
		"no carrier keeps walking to the freed camp")
	for i in 1200:
		await physics_frame
		if carriers.all(func(v): return v.carried_resource == 0):
			break
	_check(carriers.all(func(v): return v.carried_resource == 0) and game.team_resources[0]["wood"] >= wood_before + 30,
		"the wood is delivered at the Town Center (%d -> %d)" % [wood_before, game.team_resources[0]["wood"]])

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
