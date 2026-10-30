extends SceneTree

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")

func _init() -> void:
	call_deferred("_run_simulation")

func _run_simulation() -> void:
	print("========================================")
	print("--- VILLAGER HARVEST & DEPOSIT TEST ---")
	print("========================================")

	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)

	var game = scene as GameController3D
	game.start_match()

	var tc = game.get_team_buildings(0)[0]
	assert(tc != null, "Player Town Center must exist")
	print("-> Town Center cell: ", tc.origin_cell, " World pos: ", tc.global_position)

	# Pick one villager
	var vill = null
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vill = u
			break
	assert(vill != null, "Player Villager must exist")

	# Find a tree
	var tree_cell = Vector2i(-1, -1)
	for c in game.map_gen.trees.keys():
		tree_cell = c
		break
	assert(tree_cell != Vector2i(-1, -1), "Must have a tree on map")
	print("-> Targeting tree at cell: ", tree_cell, " world: ", game.map_gen.cell_to_world(tree_cell))

	# Command villager to gather tree
	vill.command_gather(tree_cell, "wood")
	assert(vill.state == Unit3D.State.GATHERING, "Villager should be gathering")

	var initial_wood = game.team_resources[0]["wood"]
	print("-> Initial Wood in Depot: ", initial_wood)

	# Simulate 12 seconds of game ticks
	var deposited = false
	for frame in range(700):
		var dt = 0.033 # ~30 fps tick
		vill._physics_process(dt)

		if vill.state == Unit3D.State.RETURNING_RESOURCES:
			assert(vill.current_path.size() > 0 or vill.global_position.distance_to(tc.global_position) < 5.0, "Path to Town Center must NOT be empty!")

		if game.team_resources[0]["wood"] > initial_wood:
			deposited = true
			print("-> SUCCESS! Wood successfully deposited into Town Center at frame %d! New Wood: %d" % [frame, game.team_resources[0]["wood"]])
			break

	assert(deposited, "Villager failed to deposit wood into Town Center!")
	print("-> Villager state after deposit: ", vill.state, " (Carried: %d)" % vill.carried_resource)
	assert(vill.state == Unit3D.State.GATHERING, "Villager should automatically return to gathering!")
	assert(vill.carried_resource == 0, "Carried resource should be 0 after deposit!")

	print("========================================")
	print("VILLAGER GATHER & DEPOSIT TEST PASSED!")
	print("========================================")
	quit(0)
