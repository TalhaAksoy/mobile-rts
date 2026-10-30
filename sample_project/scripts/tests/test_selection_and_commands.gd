extends SceneTree

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("==================================================")
	print("--- TEST UNIT SELECTION & PLAYABLE COMMANDS ---")
	print("==================================================")

	var main_scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(main_scene)
	var game = main_scene as GameController3D
	game.start_match()

	var p_vills: Array[Unit3D] = []
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			p_vills.append(u)
	assert(p_vills.size() >= 3, "Must have at least 3 starter villagers")

	var tc: Building3D = null
	for b in game.buildings:
		if b.team == 0 and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			tc = b
			break
	assert(tc != null, "Must have player Town Center")

	# Test 1: Single Villager Selection
	print("[1/8] Selecting Villager 0...")
	var s_pos0 = game.camera.unproject_position(p_vills[0].global_position)
	game._handle_3d_click(s_pos0, p_vills[0].global_position)
	assert(game.selected_units.size() == 1 and game.selected_units[0] == p_vills[0], "Villager 0 must be selected alone")
	print("-> Villager 0 selected alone successfully.")

	# Test 2: Move Order Near Base (Ground Move)
	print("[2/8] Issuing Ground Move command near base...")
	var move_dest = game.map_gen.player_start_pos + Vector3(0.0, 0, -6.0)
	var move_screen = game.camera.unproject_position(move_dest)
	game._handle_3d_click(move_screen, move_dest)
	print("Selected units: ", game.selected_units.size(), " Villager state: ", p_vills[0].state, " (0=IDLE, 1=MOVING)")
	assert(game.selected_units.size() == 1 and game.selected_units[0] == p_vills[0], "Selection must be preserved during move order")
	assert(p_vills[0].state == Unit3D.State.MOVING, "Villager must enter MOVING state")
	print("-> Ground move command executed successfully.")

	# Test 3: Gather Wood Command (Clicking Tree)
	print("[3/8] Issuing Gather Wood command on nearest tree...")
	var tree_cell = game.map_gen.trees.keys()[0]
	var tree_pos = game.map_gen.cell_to_world(tree_cell) + Vector3(0, 1.6, 0)
	var tree_screen = game.camera.unproject_position(tree_pos)
	game._handle_3d_click(tree_screen, game.map_gen.cell_to_world(tree_cell))
	assert(p_vills[0].state == Unit3D.State.GATHERING, "Villager must enter GATHERING state")
	assert(p_vills[0].resource_type == "wood", "Resource type must be wood")
	print("-> Gather wood command executed successfully.")

	# Test 4: Gather Gold Command (Clicking Gold Mine)
	print("[4/8] Issuing Gather Gold command on gold mine...")
	var gold_cell = game.map_gen.gold_mines.keys()[0]
	var gh = game.map_gen.height_map[gold_cell.x][gold_cell.y]
	var gold_pos = game.map_gen.cell_to_world(gold_cell) + Vector3(0, gh + 0.9, 0)
	var gold_screen = game.camera.unproject_position(gold_pos)
	var r_info = game._find_resource_at_click(gold_screen, game.map_gen.cell_to_world(gold_cell))
	print("Gold r_info: ", r_info)
	game._handle_3d_click(gold_screen, game.map_gen.cell_to_world(gold_cell))
	print("Villager res type: ", p_vills[0].resource_type, " state: ", p_vills[0].state)
	assert(p_vills[0].state == Unit3D.State.GATHERING, "Villager must enter GATHERING state")
	assert(p_vills[0].resource_type == "gold", "Resource type must be gold")
	print("-> Gather gold command executed successfully.")

	# Test 5: Click Empty Ground Near Villager (Must Move, Not Deselect)
	print("[5/8] Clicking empty ground in courtyard...")
	var empty_ground = game.map_gen.cell_to_world(game.map_gen.world_to_cell(game.map_gen.player_start_pos) + Vector2i(0, -2))
	var empty_screen = game.camera.unproject_position(empty_ground)
	game._handle_3d_click(empty_screen, empty_ground)
	assert(game.selected_units.size() == 1 and game.selected_units[0] == p_vills[0], "Clicking empty ground must NOT deselect unit")
	assert(p_vills[0].state == Unit3D.State.MOVING, "Villager must enter MOVING state to empty ground")
	print("-> Empty ground tap moved unit successfully!")

	# Test 6: Villager with Cargo Clicking TC to Drop Off
	print("[6/8] Villager with cargo clicking Town Center to deposit...")
	p_vills[0].carried_resource = 15
	p_vills[0].resource_type = "wood"
	var tc_screen = game.camera.unproject_position(tc.global_position + Vector3(0, 1.8, 0))
	game._handle_3d_click(tc_screen, tc.global_position)
	assert(game.selected_units.size() == 1 and game.selected_units[0] == p_vills[0], "Villager remains selected when depositing")
	assert(p_vills[0].state == Unit3D.State.RETURNING_RESOURCES, "Villager must enter RETURNING_RESOURCES state")
	print("-> Deposit cargo command executed successfully on Town Center!")

	# Test 7: Military Unit Attack Command
	print("[7/8] Spawning swordsman and issuing attack command on enemy...")
	var soldier = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, game.map_gen.player_start_pos)
	var enemy = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 1, game.map_gen.player_start_pos + Vector3(5.0, 0, 0))
	game._clear_selection()
	var soldier_screen = game.camera.unproject_position(soldier.global_position)
	game._handle_3d_click(soldier_screen, soldier.global_position)
	assert(game.selected_units.size() == 1 and game.selected_units[0] == soldier, "Soldier must be selected")

	var enemy_screen = game.camera.unproject_position(enemy.global_position)
	game._handle_3d_click(enemy_screen, enemy.global_position)
	assert(soldier.state == Unit3D.State.ATTACKING, "Soldier must enter ATTACKING state")
	assert(soldier.target_entity == enemy, "Soldier target must be enemy")
	print("-> Attack command executed successfully on enemy!")

	# Test 8: Deselect via HUD Button [✖ Bırak]
	print("[8/8] Testing UI [✖ Bırak] button deselect...")
	game.ui_manager.clear_selection_requested.emit()
	assert(game.selected_units.is_empty(), "Selection must be cleanly cleared by [✖ Bırak]")
	print("-> Selection cleanly cleared via HUD.")

	print("==================================================")
	print("ALL UNIT SELECTION & PLAYABLE COMMAND TESTS PASSED!")
	print("==================================================")
	quit(0)
