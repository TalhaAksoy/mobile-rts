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
	if not _expect(p_vills.size() >= 3, "Must have at least 3 starter villagers"): return

	var tc: Building3D = null
	for b in game.buildings:
		if b.team == 0 and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			tc = b
			break
	if not _expect(tc != null, "Must have player Town Center"): return

	# Test 1: Single Villager Selection
	print("[1/8] Selecting Villager 0...")
	var s_pos0 = game.camera.unproject_position(p_vills[0].global_position)
	game._handle_3d_click(s_pos0, p_vills[0].global_position)
	if not _expect(game.selected_units.size() == 1 and game.selected_units[0] == p_vills[0], "Villager 0 must be selected alone"): return
	print("-> Villager 0 selected alone successfully.")

	# Test 2: Move Order Near Base (Ground Move)
	print("[2/8] Issuing Ground Move command near base...")
	# Pick a ground point where the click handler itself sees no resource and no entity: a tap next to
	# a tree/mine is (by design) a gather order, so a fixed offset made this test depend on the random map.
	var move_dest = _find_clear_ground(game, game.map_gen.player_start_pos, [])
	if not _expect(move_dest != Vector3.INF, "Found a resource-free ground point near the base"): return
	var move_screen = game.camera.unproject_position(move_dest)
	game._handle_3d_click(move_screen, move_dest)
	print("Selected units: ", game.selected_units.size(), " Villager state: ", p_vills[0].state, " (0=IDLE, 1=MOVING)")
	if not _expect(game.selected_units.size() == 1 and game.selected_units[0] == p_vills[0], "Selection must be preserved during move order"): return
	if not _expect(p_vills[0].state == Unit3D.State.MOVING, "Villager must enter MOVING state"): return
	print("-> Ground move command executed successfully.")

	# Test 3: Gather Wood Command (Clicking Tree)
	print("[3/8] Issuing Gather Wood command on nearest tree...")
	var tree_cell = game.map_gen.trees.keys()[0]
	var tree_pos = game.map_gen.cell_to_world(tree_cell) + Vector3(0, 1.6, 0)
	var tree_screen = game.camera.unproject_position(tree_pos)
	game._handle_3d_click(tree_screen, game.map_gen.cell_to_world(tree_cell))
	if not _expect(p_vills[0].state == Unit3D.State.GATHERING, "Villager must enter GATHERING state"): return
	if not _expect(p_vills[0].resource_type == "wood", "Resource type must be wood"): return
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
	if not _expect(p_vills[0].state == Unit3D.State.GATHERING, "Villager must enter GATHERING state"): return
	if not _expect(p_vills[0].resource_type == "gold", "Resource type must be gold"): return
	print("-> Gather gold command executed successfully.")

	# Test 5: Click Empty Ground Near Villager (Must Move, Not Deselect)
	print("[5/8] Clicking empty ground in courtyard...")
	# Same resource-free zone as step 2 (one cell over): the cell right next to the TC is where the
	# base resource cluster spawns, so a fixed offset there randomly hit a gold/stone node.
	var empty_ground = _find_clear_ground(game, game.map_gen.player_start_pos, [move_dest])
	if not _expect(empty_ground != Vector3.INF, "Found a second resource-free ground point"): return
	var empty_screen = game.camera.unproject_position(empty_ground)
	game._handle_3d_click(empty_screen, empty_ground)
	if not _expect(game.selected_units.size() == 1 and game.selected_units[0] == p_vills[0], "Clicking empty ground must NOT deselect unit"): return
	if not _expect(p_vills[0].state == Unit3D.State.MOVING, "Villager must enter MOVING state to empty ground"): return
	print("-> Empty ground tap moved unit successfully!")

	# Test 6: Villager with Cargo Clicking TC to Drop Off
	print("[6/8] Villager with cargo clicking Town Center to deposit...")
	p_vills[0].carried_resource = 15
	p_vills[0].resource_type = "wood"
	var tc_screen = game.camera.unproject_position(tc.global_position + Vector3(0, 1.8, 0))
	game._handle_3d_click(tc_screen, tc.global_position)
	if not _expect(game.selected_units.size() == 1 and game.selected_units[0] == p_vills[0], "Villager remains selected when depositing"): return
	if not _expect(p_vills[0].state == Unit3D.State.RETURNING_RESOURCES, "Villager must enter RETURNING_RESOURCES state"): return
	print("-> Deposit cargo command executed successfully on Town Center!")

	# Test 7: Military Unit Attack Command
	print("[7/8] Spawning swordsman and issuing attack command on enemy...")
	var soldier = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, game.map_gen.player_start_pos)
	var enemy = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 1, game.map_gen.player_start_pos + Vector3(5.0, 0, 0))
	game._clear_selection()
	var soldier_screen = game.camera.unproject_position(soldier.global_position)
	game._handle_3d_click(soldier_screen, soldier.global_position)
	if not _expect(game.selected_units.size() == 1 and game.selected_units[0] == soldier, "Soldier must be selected"): return

	var enemy_screen = game.camera.unproject_position(enemy.global_position)
	game._handle_3d_click(enemy_screen, enemy.global_position)
	if not _expect(soldier.state == Unit3D.State.ATTACKING, "Soldier must enter ATTACKING state"): return
	if not _expect(soldier.target_entity == enemy, "Soldier target must be enemy"): return
	print("-> Attack command executed successfully on enemy!")

	# Test 8: Deselect via HUD Button [✖ Bırak]
	print("[8/8] Testing UI [✖ Bırak] button deselect...")
	game.ui_manager.clear_selection_requested.emit()
	if not _expect(game.selected_units.is_empty(), "Selection must be cleanly cleared by [✖ Bırak]"): return
	print("-> Selection cleanly cleared via HUD.")

	print("==================================================")
	print("ALL UNIT SELECTION & PLAYABLE COMMAND TESTS PASSED!")
	print("==================================================")
	quit(0)


## Non-halting assertion: a failed GDScript assert() stops the function before quit(), which made
## headless runs hang until the runner's timeout and hid every later test. Report and exit instead.
func _expect(cond: bool, msg: String) -> bool:
	if not cond:
		printerr("[FAIL] " + msg)
		print("RESULT: FAIL - " + msg)
		quit(1)
	return cond

## Spiral search (on screen, around `center`) for walkable ground where neither a resource nor an
## entity would be picked by GameController3D._handle_3d_click. Returns Vector3.INF if none.
func _find_clear_ground(game, center: Vector3, exclude: Array) -> Vector3:
	var c0: Vector2i = game.map_gen.world_to_cell(center)
	for r in range(3, 10):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if abs(dx) != r and abs(dy) != r:
					continue
				var cell: Vector2i = c0 + Vector2i(dx, dy)
				if not game.map_gen.is_valid_cell(cell.x, cell.y) or not game.map_gen.is_cell_walkable(cell):
					continue
				var p: Vector3 = game.map_gen.cell_to_world(cell)
				var skip := false
				for e in exclude:
					if p.distance_to(e) < 3.0:
						skip = true
				if skip:
					continue
				var scr: Vector2 = game.camera.unproject_position(p)
				if not game.get_viewport().get_visible_rect().has_point(scr):
					continue
				if game._find_resource_at_click(scr, p).is_empty() and game._get_entity_at_position(scr, p) == null:
					return p
	return Vector3.INF
