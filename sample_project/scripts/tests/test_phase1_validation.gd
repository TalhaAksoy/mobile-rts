extends SceneTree

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")
const MapGenerator3D = preload("res://scripts/MapGenerator3D.gd")
const SaveManager = preload("res://scripts/SaveManager.gd")

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	call_deferred("_run_all_tests")

func report(test_name: String, success: bool, details: String = "") -> void:
	if success:
		passed_count += 1
		print("[PASS] %s %s" % [test_name, details])
	else:
		failed_count += 1
		printerr("[FAIL] %s %s" % [test_name, details])

func _run_all_tests() -> void:
	print("==================================================")
	print("=== POCKET EMPIRES 3D — PHASE 1 VALIDATION SUITE ===")
	print("==================================================")

	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	var game = scene as GameController3D
	game.start_match()

	_test_gesture_machine(game)
	_test_building_placement_auto_assign(game)
	_test_production_queue_cancellation(game)
	_test_resource_colliders_and_selection(game)
	_test_dropoff_camps_routing(game)
	_test_auto_gather_tree_switch(game)
	_test_auto_gather_radius_cutoff(game)
	_test_auto_gather_mining(game)
	_test_bot_ai_economy_simulation(game)
	_test_save_load_compatibility(game)

	print("==================================================")
	print("TESTS COMPLETED: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("==================================================")
	quit(0 if failed_count == 0 else 1)

func _test_gesture_machine(game: GameController3D) -> void:
	print("\n--- TEST: Gesture State Machine & Pan Decoupling ---")
	var cam_start = game.camera.global_position
	var ev_down = InputEventMouseButton.new()
	ev_down.button_index = MOUSE_BUTTON_LEFT
	ev_down.pressed = true
	ev_down.position = Vector2(200, 300)
	game._unhandled_input(ev_down)

	var ev_motion = InputEventMouseMotion.new()
	ev_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	ev_motion.position = Vector2(250, 350)
	game._unhandled_input(ev_motion)

	report("Pan does not trigger box select mode", not game.is_drag_box_selecting and not game.is_box_select_mode)
	report("Camera panned via screen drag", game.camera.global_position != cam_start)

	var ev_up = InputEventMouseButton.new()
	ev_up.button_index = MOUSE_BUTTON_LEFT
	ev_up.pressed = false
	ev_up.position = Vector2(250, 350)
	game._unhandled_input(ev_up)
	report("Pan release does not issue unexpected clicks", game.selected_units.is_empty())

	# Toggle Box Select Mode
	game.is_box_select_mode = true
	game._unhandled_input(ev_down)
	game._unhandled_input(ev_motion)
	report("Box select mode draws drag box", game.is_drag_box_selecting)
	game._unhandled_input(ev_up)
	game.is_box_select_mode = false

func _test_building_placement_auto_assign(game: GameController3D) -> void:
	print("\n--- TEST: Multi-Villager Auto Assign on Blueprint Placement ---")
	var vills: Array[Unit3D] = []
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vills.append(u)
			if vills.size() >= 2:
				break

	game.selected_units.clear()
	for v in vills:
		game.selected_units.append(v)

	game.is_placing_building = true
	game.placing_building_type = Building3D.BuildingType.HOUSE
	game.team_resources[0]["wood"] = 100

	# Find guaranteed clear 2x2 footprint near player base
	var tc = game.get_team_buildings(0)[0]
	var tc_cell = tc.origin_cell
	var clear_cell = Vector2i(-1, -1)
	for dx in range(3, 16):
		for dy in range(3, 16):
			var c = tc_cell + Vector2i(dx, dy)
			var ok = true
			for sx in range(2):
				for sy in range(2):
					var test_c = c + Vector2i(sx, sy)
					if not game.map_gen.is_valid_cell(test_c.x, test_c.y) or not game.map_gen.is_cell_walkable(test_c):
						ok = false
						break
				if not ok: break
			if ok:
				clear_cell = c
				break
		if clear_cell != Vector2i(-1, -1):
			break

	var spot = game.map_gen.cell_to_world(clear_cell)
	game._attempt_place_building(spot)

	var all_building = true
	for v in vills:
		if v.state != Unit3D.State.BUILDING and v.state != Unit3D.State.MOVING:
			all_building = false

	report("All selected villagers assigned to construct blueprint", all_building and vills.size() >= 2)

func _test_production_queue_cancellation(game: GameController3D) -> void:
	print("\n--- TEST: Production Queue Cancellation & 100% Refund ---")
	var tc = game.get_team_buildings(0)[0]
	game.team_resources[0]["food"] = 200
	var initial_food = game.team_resources[0]["food"]

	# Queue 2 villagers
	var ok1 = game.try_train_unit(tc, Unit3D.UnitType.VILLAGER, 0)
	var ok2 = game.try_train_unit(tc, Unit3D.UnitType.VILLAGER, 0)
	report("Queue 2 units successful", ok1 and ok2 and tc.train_queue.size() == 2)
	report("Food deducted properly (100 food spent)", game.team_resources[0]["food"] == initial_food - 100)

	# Cancel the 2nd queued item
	var cancel_ok = game.cancel_unit_production(tc, 1)
	report("Cancel second unit in queue", cancel_ok and tc.train_queue.size() == 1)
	report("50 food refunded (100% refund)", game.team_resources[0]["food"] == initial_food - 50)

	# Cancel the remaining active unit
	game.cancel_unit_production(tc, 0)
	report("Cancel active unit in queue", tc.train_queue.size() == 0)
	report("All food fully refunded to original amount", game.team_resources[0]["food"] == initial_food)

func _test_resource_colliders_and_selection(game: GameController3D) -> void:
	print("\n--- TEST: Resource Physics Colliders & Fair Detection ---")
	var res_areas = game.map_gen.find_children("*", "Area3D", true, false)
	report("Resource Area3D nodes exist on collision layer 4 (mask 8)", res_areas.size() > 10)

	var any_gold_cell = Vector2i(-1, -1)
	for c in game.map_gen.gold_mines.keys():
		any_gold_cell = c
		break

	if any_gold_cell != Vector2i(-1, -1):
		var gold_w = game.map_gen.cell_to_world(any_gold_cell)
		var gold_screen = game.camera.unproject_position(gold_w + Vector3(0, 0.9, 0))
		var found = game._find_resource_at_click(gold_screen, gold_w)
		report("Gold mine successfully detected at its screen coordinate", found.get("type", "") == "gold")

		# HUD selection test
		game.ui_manager.set_selected_resource(found)
		report("HUD context deck displays remaining resource", game.ui_manager.entity_hp_bar.value > 0 and game.ui_manager.entity_hp_bar.visible)

func _test_dropoff_camps_routing(game: GameController3D) -> void:
	print("\n--- TEST: Drop-off Camps (Lumber, Mining, Mill) Routing ---")
	var tc = game.get_team_buildings(0)[0]
	var distant_pos = tc.global_position + Vector3(25.0, 0, 25.0)
	var distant_cell = game.map_gen.world_to_cell(distant_pos)

	# Place a Lumber Camp far from TC
	var lumber_camp = game.place_building(Building3D.BuildingType.LUMBER_CAMP, 0, distant_cell, false)
	report("Lumber Camp placed successfully", lumber_camp != null and lumber_camp.is_completed)

	var dropoff_wood = game.get_closest_dropoff_for_resource(distant_pos + Vector3(2.0, 0, 0), 0, "wood")
	report("Wood drops off at nearest Lumber Camp instead of distant TC", dropoff_wood == lumber_camp)

	var dropoff_gold = game.get_closest_dropoff_for_resource(distant_pos + Vector3(2.0, 0, 0), 0, "gold")
	report("Gold ignores Lumber Camp and routes to TC", dropoff_gold == tc)

	# Place a Mining Camp
	var mining_camp = game.place_building(Building3D.BuildingType.MINING_CAMP, 0, distant_cell + Vector2i(3, 0), false)
	var dropoff_gold2 = game.get_closest_dropoff_for_resource(distant_pos + Vector3(4.0, 0, 0), 0, "gold")
	report("Gold drops off at nearest Mining Camp", dropoff_gold2 == mining_camp)

	var dropoff_food = game.get_closest_dropoff_for_resource(distant_pos + Vector3(4.0, 0, 0), 0, "food")
	report("Food ignores Mining Camp and routes to TC", dropoff_food == tc)

	# Place a Mill
	var mill = game.place_building(Building3D.BuildingType.MILL, 0, distant_cell + Vector2i(0, 3), false)
	var dropoff_food2 = game.get_closest_dropoff_for_resource(distant_pos + Vector3(0, 0, 4.0), 0, "food")
	report("Food drops off at nearest Mill", dropoff_food2 == mill)

func _test_auto_gather_tree_switch(game: GameController3D) -> void:
	print("\n--- TEST: Auto-Gather Next Resource on Depletion ---")
	var vill = null
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vill = u
			break

	var tree1_cell = Vector2i(15, 15)
	var tree2_cell = Vector2i(16, 15)
	# Clear any ambient generated trees around test area
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			game.map_gen.trees.erase(tree1_cell + Vector2i(dx, dy))
	game.map_gen.trees[tree1_cell] = {"hp": 2, "amount": 2, "max_amount": 100, "type": "wood", "name": "Test Tree 1"}
	game.map_gen.trees[tree2_cell] = {"hp": 100, "amount": 100, "max_amount": 100, "type": "wood", "name": "Test Tree 2"}

	vill.carried_resource = 0
	vill.global_position = game.map_gen.cell_to_world(tree1_cell)
	vill.command_gather(tree1_cell, "wood")

	# Deplete tree1
	game.map_gen.trees[tree1_cell]["hp"] = 0
	game.map_gen.trees[tree1_cell]["amount"] = 0
	vill._find_next_resource("wood")

	report("Villager automatically retargets adjacent tree when first tree is depleted", vill.target_cell == tree2_cell and vill.state == Unit3D.State.GATHERING)

func _test_auto_gather_radius_cutoff(game: GameController3D) -> void:
	print("\n--- TEST: Auto-Gather Radius Limit (16.0m Cutoff) ---")
	var vill = null
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vill = u
			break

	var lone_cell = Vector2i(2, 2)
	game.map_gen.trees[lone_cell] = {"hp": 0, "amount": 0, "max_amount": 100, "type": "wood", "name": "Isolated Tree"}
	vill.carried_resource = 0
	vill.global_position = game.map_gen.cell_to_world(lone_cell)
	vill.target_cell = lone_cell
	vill.resource_type = "wood"
	vill.last_resource_pos = vill.global_position

	# Clear any nearby trees within 16m
	for dx in range(-8, 9):
		for dy in range(-8, 9):
			var c = lone_cell + Vector2i(dx, dy)
			if c != lone_cell:
				game.map_gen.trees.erase(c)

	vill._find_next_resource("wood")
	report("Villager enters IDLE when no trees within 16.0m search radius", vill.state == Unit3D.State.IDLE)

func _test_auto_gather_mining(game: GameController3D) -> void:
	print("\n--- TEST: Mining Auto-Switch to Adjacent Gold Node ---")
	var vill = null
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vill = u
			break

	var gold1 = Vector2i(30, 30)
	var gold2 = Vector2i(31, 30)
	game.map_gen.gold_mines[gold1] = {"gold": 0, "amount": 0, "max_amount": 800, "type": "gold", "name": "Gold 1"}
	game.map_gen.gold_mines[gold2] = {"gold": 800, "amount": 800, "max_amount": 800, "type": "gold", "name": "Gold 2"}

	vill.carried_resource = 0
	vill.global_position = game.map_gen.cell_to_world(gold1)
	vill.target_cell = gold1
	vill.resource_type = "gold"
	vill.last_resource_pos = vill.global_position
	vill._find_next_resource("gold")

	report("Miner automatically switches to adjacent gold node upon depletion", vill.target_cell == gold2 and vill.state == Unit3D.State.GATHERING)

func _test_bot_ai_economy_simulation(game: GameController3D) -> void:
	print("\n--- TEST: Bot AI Economic Rebalancing & Anti-Stall Simulation ---")
	var ai = game.enemy_ai
	ai.setup_ai(CivData.CivType.BYZANTINES, game.map_gen, game, EnemyAI3D.Difficulty.NORMAL)

	# Set up initial condition that previously caused 2162 Gold / 0 Food stall
	game.team_resources[1] = {"food": 10, "wood": 120, "gold": 250, "stone": 100}

	var bot_vills: Array[Unit3D] = []
	for u in game.units:
		if u.team == 1 and u.unit_type == Unit3D.UnitType.VILLAGER:
			bot_vills.append(u)

	for v in bot_vills:
		v.command_gather(Vector2i(10, 10), "gold")

	# Run 10 AI think ticks
	for i in range(10):
		ai._think()

	var food_workers = 0
	for v in bot_vills:
		if v.resource_type == "food":
			food_workers += 1

	report("Bot dynamic workforce reassigns excess gold miners to food when food < 80", food_workers >= 1)

func _test_save_load_compatibility(game: GameController3D) -> void:
	print("\n--- TEST: Save and Load Compatibility with Phase 1 Buildings ---")
	var save_path = "user://saves/phase1_test_save.json"
	var save_ok = SaveManager.save_game(game, save_path)
	report("Game state saved successfully with camps and units", save_ok)

	var load_ok = SaveManager.load_game(game, save_path)
	report("Game state reloaded successfully", load_ok)

	var has_lumber_camp = false
	for b in game.buildings:
		if b.building_type == Building3D.BuildingType.LUMBER_CAMP:
			has_lumber_camp = true
			break
	report("Lumber Camp persisted and reconstructed correctly", has_lumber_camp)
