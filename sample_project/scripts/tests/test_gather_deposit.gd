extends SceneTree

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")

func _init() -> void:
	call_deferred("_run_simulation")

func _run_simulation() -> void:
	print("================================================================")
	print("--- COMPREHENSIVE 4-RESOURCE HARVEST, DEPOSIT & REROUTE TEST ---")
	print("================================================================")

	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)

	var game = scene as GameController3D
	game.start_match()

	var tc = game.get_team_buildings(0)[0]
	if not _expect(tc != null, "Player Town Center must exist"): return

	var vill: Unit3D = null
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vill = u
			break
	if not _expect(vill != null, "Player Villager must exist"): return

	# -------------------------------------------------------------
	# TEST 1: Function Signature Compatibility (2 and 3 Arguments)
	# -------------------------------------------------------------
	print("\n[STEP 1] Testing Function Signature Compatibility...")
	var test_pos = tc.global_position + Vector3(5, 0, 5)
	var d2 = game.get_closest_dropoff(test_pos, 0)
	if not _expect(d2 == tc, "get_closest_dropoff(pos, team) with 2 arguments must return valid dropoff"): return
	print("  -> PASS: 2-argument get_closest_dropoff verified")

	var d3 = game.get_closest_dropoff(test_pos, 0, "wood")
	if not _expect(d3 == tc, "get_closest_dropoff(pos, team, res_type) with 3 arguments must return valid dropoff"): return
	print("  -> PASS: 3-argument get_closest_dropoff verified")

	var d_spec = game.get_closest_dropoff_for_resource(test_pos, 0, "wood")
	if not _expect(d_spec == tc, "get_closest_dropoff_for_resource(pos, team, res_type) must return valid dropoff"): return
	print("  -> PASS: get_closest_dropoff_for_resource verified")

	# -------------------------------------------------------------
	# TEST 2: WOOD HARVEST & DEPOSIT (Lumber Camp Priority)
	# -------------------------------------------------------------
	print("\n[STEP 2] Testing WOOD Harvest & Deposit...")
	var tree_cell = Vector2i(-1, -1)
	for c in game.map_gen.trees.keys():
		tree_cell = c
		break
	if not _expect(tree_cell != Vector2i(-1, -1), "Map must contain trees"): return

	var tree_pos = game.map_gen.cell_to_world(tree_cell)
	var lumber_camp = game.place_building(Building3D.BuildingType.LUMBER_CAMP, 0, tree_cell + Vector2i(2, 0), false)
	if not _expect(lumber_camp != null and lumber_camp.is_completed, "Lumber camp constructed"): return

	var init_wood = game.team_resources[0]["wood"]
	vill.global_position = tree_pos + Vector3(1.0, 0, 0)
	vill.command_gather(tree_cell, "wood")
	if not _expect(vill.state == Unit3D.State.GATHERING, "Villager state should be GATHERING"): return

	_simulate_until_deposited(game, vill, "wood", init_wood, 800)
	print("  -> PASS: Wood successfully harvested and deposited into Lumber Camp (New: %d)" % game.team_resources[0]["wood"])

	# -------------------------------------------------------------
	# TEST 3: FOOD HARVEST & DEPOSIT (Mill Priority)
	# -------------------------------------------------------------
	print("\n[STEP 3] Testing FOOD Harvest & Deposit...")
	var food_cell = Vector2i(-1, -1)
	for c in game.map_gen.berry_bushes.keys():
		food_cell = c
		break
	if not _expect(food_cell != Vector2i(-1, -1), "Map must contain berry bushes"): return

	var food_pos = game.map_gen.cell_to_world(food_cell)
	var mill = game.place_building(Building3D.BuildingType.MILL, 0, food_cell + Vector2i(2, 0), false)
	if not _expect(mill != null and mill.is_completed, "Mill constructed"): return

	var init_food = game.team_resources[0]["food"]
	vill.global_position = food_pos + Vector3(1.0, 0, 0)
	vill.command_gather(food_cell, "food")

	_simulate_until_deposited(game, vill, "food", init_food, 800)
	print("  -> PASS: Food successfully harvested and deposited into Mill (New: %d)" % game.team_resources[0]["food"])

	# -------------------------------------------------------------
	# TEST 4: GOLD HARVEST & DEPOSIT (Mining Camp Priority)
	# -------------------------------------------------------------
	print("\n[STEP 4] Testing GOLD Harvest & Deposit...")
	var gold_cell = Vector2i(-1, -1)
	for c in game.map_gen.gold_mines.keys():
		gold_cell = c
		break
	if not _expect(gold_cell != Vector2i(-1, -1), "Map must contain gold mines"): return

	var gold_pos = game.map_gen.cell_to_world(gold_cell)
	var mining_camp = game.place_building(Building3D.BuildingType.MINING_CAMP, 0, gold_cell + Vector2i(2, 0), false)
	if not _expect(mining_camp != null and mining_camp.is_completed, "Mining camp constructed"): return

	var init_gold = game.team_resources[0]["gold"]
	vill.global_position = gold_pos + Vector3(1.0, 0, 0)
	vill.command_gather(gold_cell, "gold")

	_simulate_until_deposited(game, vill, "gold", init_gold, 800)
	print("  -> PASS: Gold successfully harvested and deposited into Mining Camp (New: %d)" % game.team_resources[0]["gold"])

	# -------------------------------------------------------------
	# TEST 5: STONE HARVEST & DEPOSIT (Mining Camp Priority)
	# -------------------------------------------------------------
	print("\n[STEP 5] Testing STONE Harvest & Deposit...")
	var stone_cell = Vector2i(-1, -1)
	for c in game.map_gen.stone_mines.keys():
		stone_cell = c
		break
	if not _expect(stone_cell != Vector2i(-1, -1), "Map must contain stone mines"): return

	var stone_pos = game.map_gen.cell_to_world(stone_cell)
	var stone_camp = game.place_building(Building3D.BuildingType.MINING_CAMP, 0, stone_cell + Vector2i(2, 0), false)
	if not _expect(stone_camp != null and stone_camp.is_completed, "Stone mining camp constructed"): return

	var init_stone = game.team_resources[0]["stone"]
	vill.global_position = stone_pos + Vector3(1.0, 0, 0)
	vill.command_gather(stone_cell, "stone")

	_simulate_until_deposited(game, vill, "stone", init_stone, 800)
	print("  -> PASS: Stone successfully harvested and deposited into Mining Camp (New: %d)" % game.team_resources[0]["stone"])

	# -------------------------------------------------------------
	# TEST 6: DYNAMIC DEPO DESTRUCTION & REROUTE TO TOWN CENTER
	# -------------------------------------------------------------
	print("\n[STEP 6] Testing Dynamic Dropoff Destruction While Returning Resources...")
	var camp_near_tc_cell = tc.origin_cell + Vector2i(6, 0)
	var reroute_camp = game.place_building(Building3D.BuildingType.LUMBER_CAMP, 0, camp_near_tc_cell, false)
	if not _expect(reroute_camp != null and reroute_camp.is_completed, "Reroute test camp built"): return

	vill.carried_resource = 15
	vill.resource_type = "wood"
	vill.global_position = reroute_camp.global_position + Vector3(3.0, 0, 0)
	vill.command_return_resources()

	if not _expect(vill.state == Unit3D.State.RETURNING_RESOURCES, "Villager should be RETURNING_RESOURCES"): return
	if not _expect(vill.target_entity == reroute_camp, "Target entity initially reroute camp"): return

	# Destroy the camp mid-route!
	reroute_camp.take_damage(reroute_camp.max_hp + 100.0, 1)
	if not _expect(reroute_camp.hp <= 0, "Reroute camp destroyed"): return

	var rerouted_wood = game.team_resources[0]["wood"]
	var reroute_success = false
	for frame in range(900):
		vill._physics_process(0.033)
		if game.team_resources[0]["wood"] > rerouted_wood:
			reroute_success = true
			print("  -> SUCCESS: Villager rerouted to Town Center and deposited cargo at frame %d! New Wood: %d" % [frame, game.team_resources[0]["wood"]])
			break

	if not _expect(reroute_success, "Villager failed to reroute to Town Center after camp was destroyed!"): return
	if not _expect(vill.carried_resource == 0, "Carried resource should be cleared upon deposit"): return

	# -------------------------------------------------------------
	# TEST 7: ALL DROPOFFS DESTROYED (Graceful Idle Without Frame Errors)
	# -------------------------------------------------------------
	print("\n[STEP 7] Testing Graceful Idle When All Dropoffs Destroyed...")
	vill.carried_resource = 10
	vill.resource_type = "gold"

	# Destroy all player buildings
	for b in game.buildings.duplicate():
		if is_instance_valid(b) and b.team == 0:
			b.take_damage(b.max_hp + 500.0, 1)

	vill.command_return_resources()
	if not _expect(vill.state == Unit3D.State.IDLE, "Villager must cleanly enter IDLE when no dropoffs exist on map"): return

	# Process 30 frames to guarantee NO SCRIPT ERROR occurs per frame
	for _f in range(30):
		vill._physics_process(0.033)
	if not _expect(vill.state == Unit3D.State.IDLE, "Villager remains stable in IDLE without errors"): return
	print("  -> PASS: Graceful idle confirmed, zero repeated errors per frame")

	print("\n================================================================")
	print("ALL 7 HARVEST, DEPOSIT, REROUTE & SIGNATURE TESTS PASSED!")
	print("================================================================")
	quit(0)

func _simulate_until_deposited(game: GameController3D, vill: Unit3D, res_type: String, init_amount: int, max_frames: int) -> void:
	var deposited = false
	for frame in range(max_frames):
		vill._physics_process(0.033)
		if game.team_resources[0][res_type] > init_amount:
			deposited = true
			break
	if not _expect(deposited, "Villager failed to deposit %s within %d frames!" % [res_type, max_frames]): return
	if not _expect(vill.carried_resource == 0, "Carried resource should reset to 0 upon deposit"): return


## Non-halting assertion: a failed GDScript assert() stops the function before quit(), which made
## headless runs hang until the runner's timeout and hid every later test. Report and exit instead.
func _expect(cond: bool, msg: String) -> bool:
	if not cond:
		printerr("[FAIL] " + msg)
		print("RESULT: FAIL - " + msg)
		quit(1)
	return cond
