extends SceneTree

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("========================================")
	print("--- TEST SELECTION & TOWN CENTER PRODUCTION ---")
	print("========================================")

	var main_scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(main_scene)

	var game = main_scene as GameController3D
	game.start_match()

	# 1. Find player villager and Town Center
	var vill: Unit3D = null
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vill = u
			break
	assert(vill != null, "Must find player villager")

	var tc: Building3D = null
	for b in game.buildings:
		if b.team == 0 and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			tc = b
			break
	assert(tc != null, "Must find player Town Center")

	# Test A: Select villager
	print("[1/5] Selecting villager...")
	var vill_screen = game.camera.unproject_position(vill.global_position)
	game._handle_3d_click(vill_screen, vill.global_position)
	assert(game.selected_units.size() == 1 and game.selected_units[0] == vill, "Villager must be selected")
	print("-> Villager selected successfully.")

	# Test B: Deselect villager by clicking it again (after double-click window)
	print("[2/5] Deselecting villager by clicking it again (toggle)...")
	game.last_click_time_msec = 0 # reset double-click window
	game._handle_3d_click(vill_screen, vill.global_position)
	assert(game.selected_units.is_empty(), "Villager must be deselected")
	assert(game.ui_manager.selected_entity == null, "UI selection must be cleared")
	print("-> Toggle deselect verified!")

	# Test C: Select villager, then click Town Center
	print("[3/5] Selecting villager, then clicking Town Center...")
	game.last_click_time_msec = 0
	game._handle_3d_click(vill_screen, vill.global_position)
	assert(game.selected_units.size() == 1, "Villager re-selected")

	var tc_screen = game.camera.unproject_position(tc.global_position + Vector3(0, 1.8, 0))
	game._handle_3d_click(tc_screen, tc.global_position)
	assert(game.selected_units.is_empty(), "Unit selection must be cleared when clicking TC")
	assert(game.selected_building == tc, "Town Center must be selected")
	assert(game.ui_manager.selected_entity == tc, "UI manager must show Town Center")
	print("-> Town Center clicked and selected successfully while villager was active!")

	# Test D: Deselect via clear_selection_requested
	print("[4/5] Testing [✖ Bırak] (Deselect) signal...")
	game.ui_manager.clear_selection_requested.emit()
	assert(game.selected_building == null, "Building selection must be cleared")
	assert(game.selected_units.is_empty(), "Unit selection must be empty")
	print("-> [✖ Bırak] cleared selection successfully!")

	# Test E: Jump to Base button selects Town Center and trains villager
	print("[5/5] Testing ANA ÜS button selection & Villager training...")
	game._on_jump_to_base()
	assert(game.selected_building == tc, "ANA ÜS button must automatically select Town Center")

	var initial_food = game.team_resources[0]["food"]
	var initial_queue = tc.train_queue.size()
	game._on_train_unit_requested(Unit3D.UnitType.VILLAGER)
	assert(tc.train_queue.size() == initial_queue + 1, "Villager must be added to production queue")
	assert(game.team_resources[0]["food"] == initial_food - 50, "50 food must be deducted for villager")
	print("-> Villager trained successfully from Town Center! Queue size: %d, New Food: %d" % [tc.train_queue.size(), game.team_resources[0]["food"]])

	print("========================================")
	print("ALL SELECTION & TC TESTS PASSED!")
	print("========================================")
	quit(0)
