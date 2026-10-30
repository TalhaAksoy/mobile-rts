extends SceneTree

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("========================================")
	print("--- TEST SINGLE UNIT SELECTION & ISOLATION ---")
	print("========================================")

	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)

	var game = scene as GameController3D
	game.start_match()

	var vills: Array[Unit3D] = []
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vills.append(u)
	assert(vills.size() >= 3, "Expected at least 3 player villagers")

	# Position 3 villagers 1 meter apart near each other (clustered scenario)
	vills[0].global_position = Vector3(30.0, 0, 95.0)
	vills[1].global_position = Vector3(30.8, 0, 95.8)
	vills[2].global_position = Vector3(29.4, 0, 95.7)

	var tap0 = (game.camera.unproject_position(vills[0].global_position) + game.camera.unproject_position(vills[0].global_position + Vector3(0, 1.8, 0))) * 0.5
	var tap1 = (game.camera.unproject_position(vills[1].global_position) + game.camera.unproject_position(vills[1].global_position + Vector3(0, 1.8, 0))) * 0.5
	var tap2 = (game.camera.unproject_position(vills[2].global_position) + game.camera.unproject_position(vills[2].global_position + Vector3(0, 1.8, 0))) * 0.5

	# 1. Tap Villager 0
	print("[1/6] Selecting Villager 0...")
	game._handle_3d_click(tap0, vills[0].global_position)
	assert(game.selected_units.size() == 1 and game.selected_units[0] == vills[0], "Villager 0 must be solely selected")
	print("-> Villager 0 selected alone.")

	# 2. Tap Villager 1 directly after (switch selection)
	print("[2/6] Tapping Villager 1 (switch single selection)...")
	game._handle_3d_click(tap1, vills[1].global_position)
	assert(game.selected_units.size() == 1 and game.selected_units[0] == vills[1], "Villager 1 must be solely selected")
	assert(vills[0].is_selected == false, "Villager 0 must be unselected")
	assert(vills[1].is_selected == true, "Villager 1 must be selected")
	print("-> Switched directly to Villager 1 alone.")

	# 3. Fast double-tap on Villager 1 must NOT select all units on screen
	print("[3/6] Rapid double-tap on Villager 1...")
	# Second tap on same unit toggles deselect as per design
	game._handle_3d_click(tap1, vills[1].global_position)
	assert(game.selected_units.is_empty(), "Villager 1 deselected by toggle")
	# Re-select Villager 1
	game._handle_3d_click(tap1, vills[1].global_position)
	assert(game.selected_units.size() == 1 and game.selected_units[0] == vills[1], "Villager 1 re-selected alone")
	print("-> Rapid taps did not trigger unintended screen-wide mass selection.")

	# 4. Tap Villager 2
	print("[4/6] Tapping Villager 2...")
	game._handle_3d_click(tap2, vills[2].global_position)
	assert(game.selected_units.size() == 1 and game.selected_units[0] == vills[2], "Villager 2 must be solely selected")
	print("-> Villager 2 selected alone.")

	# 5. Box select all 3 villagers
	print("[5/6] Testing group selection via rect...")
	var min_s = Vector2(9999, 9999)
	var max_s = Vector2(-9999, -9999)
	for v in vills:
		var s = game.camera.unproject_position(v.global_position)
		min_s.x = min(min_s.x, s.x - 20)
		min_s.y = min(min_s.y, s.y - 20)
		max_s.x = max(max_s.x, s.x + 20)
		max_s.y = max(max_s.y, s.y + 20)
	game._select_units_in_screen_rect(Rect2(min_s, max_s - min_s))
	assert(game.selected_units.size() == 3, "All 3 villagers must be selected via box select")
	print("-> Group box select verified (3 units selected).")

	# 6. Tap on Villager 0 among group selection -> MUST isolate Villager 0!
	print("[6/6] Tapping Villager 0 among a 3-unit group...")
	game._handle_3d_click(tap0, vills[0].global_position)
	assert(game.selected_units.size() == 1 and game.selected_units[0] == vills[0], "Tapping single unit in group must isolate it!")
	assert(vills[0].is_selected == true, "Villager 0 is selected")
	assert(vills[1].is_selected == false, "Villager 1 is not selected")
	assert(vills[2].is_selected == false, "Villager 2 is not selected")
	print("-> Group was successfully broken down to single unit selection!")

	print("========================================")
	print("ALL SINGLE UNIT SELECTION TESTS PASSED!")
	print("========================================")
	quit(0)
