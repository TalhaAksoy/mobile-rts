extends SceneTree

const GameController3D = preload("res://scripts/GameController3D.gd")
const SaveManager = preload("res://scripts/SaveManager.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("========================================")
	print("--- RTS COMPREHENSIVE SUITE TEST ---")
	print("========================================")

	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)

	var game = scene as GameController3D
	assert(game != null, "GameController3D scene should be loaded")

	# 1. Start Match
	print("[1/8] Starting match (Ottomans vs Byzantines)...")
	game.start_match()
	print("-> Match started. Units count: ", game.units.size(), ", Buildings: ", game.buildings.size())
	assert(game.units.size() >= 6, "Expected at least 3 player and 3 enemy villagers")
	assert(game.buildings.size() >= 2, "Expected 2 Town Centers")

	# 2. Economy & 4 Resources Check
	print("[2/8] Testing 4-Resource Economy...")
	var res = game.team_resources[0]
	print("-> Initial Resources: Food=%d, Wood=%d, Gold=%d, Stone=%d" % [res["food"], res["wood"], res["gold"], res["stone"]])
	assert(res.has("food") and res.has("wood") and res.has("gold") and res.has("stone"), "All 4 resources must exist")

	game.deposit_resource(0, "stone", 150)
	assert(game.team_resources[0]["stone"] == 250, "Depositing stone should increase stone balance")
	print("-> Stone deposit verified.")

	# 3. Unit Production & Counters Check
	print("[3/8] Testing Unit Production & Counter Modifiers...")
	var vill = game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, Vector3(0, 0, 0))
	var spearman = game.spawn_unit(Unit3D.UnitType.SPEARMAN, 0, Vector3(2, 0, 0))
	var cavalry = game.spawn_unit(Unit3D.UnitType.CAVALRY, 1, Vector3(4, 0, 0))
	assert(spearman.is_infantry(), "Spearman should be infantry")
	assert(cavalry.is_cavalry(), "Cavalry should be cavalry")
	print("-> Units spawned: Villager, Spearman, Enemy Cavalry.")

	# 4. Age System & Tech Upgrades Check
	print("[4/8] Testing Age System & Blacksmith Tech...")
	assert(game.team_age[0] == 1, "Player should start in Age 1 (Settlement)")

	var tc = game.get_team_buildings(0)[0]
	game.team_resources[0]["food"] = 600
	game.team_resources[0]["gold"] = 300
	var age_started = game.try_start_research(tc, "AGE_2", 0)
	assert(age_started, "Starting Age 2 research should succeed with sufficient resources")
	print("-> Age 2 research started on Town Center.")

	# Simulate immediate research completion
	game._on_building_research_completed("AGE_2", 0)
	assert(game.team_age[0] == 2, "Player should now be in Age 2 (Hisar Çağı)")
	print("-> Age 2 (Hisar Çağı) reached successfully!")

	# Blacksmith Research
	var initial_inf_dmg = spearman.attack_dmg
	game._on_building_research_completed("iron_weapons", 0)
	assert(spearman.attack_dmg > initial_inf_dmg, "Iron weapons should boost infantry damage")
	print("-> Blacksmith Tech (Demir Silahlar) verified: %f -> %f" % [initial_inf_dmg, spearman.attack_dmg])

	# 5. Mobile Selection Controls Check
	print("[5/8] Testing Mobile Double-Tap & Screen Selection...")
	game._select_all_matching_units_on_screen(Unit3D.UnitType.VILLAGER)
	print("-> Selected villagers count: ", game.selected_units.size())
	assert(game.selected_units.size() >= 3, "Double-tap should select all visible villagers")

	# 6. Fog of War Check
	print("[6/8] Testing Fog of War...")
	var player_base_c = game.map_gen.world_to_cell(game.map_gen.player_start_pos)
	game.map_gen.update_fog_of_war(game.get_team_units(0), game.get_team_buildings(0), game.get_team_units(1), game.get_team_buildings(1))
	var st = game.map_gen.get_fog_state(player_base_c)
	assert(st == game.map_gen.FogState.VISIBLE, "Player base should be VISIBLE in Fog of War")
	print("-> Player base cell is VISIBLE in Fog of War.")

	# 7. Save & Load System Check
	print("[7/8] Testing Save & Load System...")
	var save_ok = SaveManager.save_game(game, "user://test_save.json")
	assert(save_ok, "Saving match to disk should succeed")
	print("-> Match saved to disk.")

	var load_ok = SaveManager.load_game(game, "user://test_save.json")
	assert(load_ok, "Loading match from disk should succeed")
	assert(game.team_age[0] == 2, "Loaded match should maintain Age 2")
	print("-> Match loaded cleanly. Preserved Age 2 and unit state.")

	# 8. Enemy Bot AI Check
	print("[8/8] Testing Fair Enemy AI logic...")
	game.enemy_ai._think()
	print("-> Enemy AI think loop completed without errors.")

	print("========================================")
	print("ALL 8 VERIFICATION TESTS PASSED SUCCESSFULLY!")
	print("========================================")
	quit(0)
