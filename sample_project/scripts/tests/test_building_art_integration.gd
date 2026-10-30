extends SceneTree

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")
const CivData = preload("res://scripts/CivData.gd")
const Building3D = preload("res://scripts/Building3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const MapGenerator3D = preload("res://scripts/MapGenerator3D.gd")
const GameController3D = preload("res://scripts/GameController3D.gd")
const UIManager3D = preload("res://scripts/UIManager3D.gd")
const ArtPreview = preload("res://scripts/ArtPreview.gd")

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	call_deferred("_run_all_tests")

func assert_true(condition: bool, message: String) -> void:
	if condition:
		passed_count += 1
		print("[PASS] %s" % message)
	else:
		failed_count += 1
		printerr("[FAIL] %s" % message)

func _run_all_tests() -> void:
	print("========================================================")
	print("=== POCKET EMPIRES 3D — BUILDING ART INTEGRATION TEST ===")
	print("========================================================")

	test_all_140_building_textures()
	test_building_types_mapping()
	test_all_10_factions_12_building_instances()
	test_construction_progression_visuals()
	test_enemy_civ_tint()
	test_art_preview_gallery_integration()

	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	var game = scene as GameController3D
	game.start_match()

	test_ui_manager_portrait_integration(game)
	test_gameplay_placement_and_demolition(game)

	print("========================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("========================================================")

	if failed_count == 0:
		print("SUCCESS: ALL BUILDING ART INTEGRATION TESTS PASSED!")
	else:
		push_error("FAILED: Some building art tests failed!")
	quit(0 if failed_count == 0 else 1)

func test_all_140_building_textures() -> void:
	print("\n--- TEST: 130/130 Building Sprites Inventory (v2 Atlas Exact) ---")
	var manifest_path = "res://data/building_art_manifest.json"
	assert_true(FileAccess.file_exists(manifest_path), "Manifest exists at " + manifest_path)

	var file = FileAccess.open(manifest_path, FileAccess.READ)
	var manifest: Dictionary = JSON.parse_string(file.get_as_text())
	var factions: Dictionary = manifest.get("factions", {})

	var total_checked = 0
	var missing = 0
	for f_id in factions.keys():
		var f_data = factions[f_id]
		var b_dict: Dictionary = f_data.get("buildings", f_data.get("textures", {}))
		for b_id in b_dict.keys():
			total_checked += 1
			var tex = FactionArtManager.get_building_texture_by_id(f_id, b_id)
			if tex == null or tex.get_width() <= 0 or tex.get_height() <= 0:
				missing += 1

	assert_true(total_checked == 130, "Total 130 building sprite paths checked (got %d)" % total_checked)
	assert_true(missing == 0, "All 130 building textures loaded with valid RGBA dimensions")

func test_building_types_mapping() -> void:
	print("\n--- TEST: Building Type to Manifest ID Mapping ---")
	var expected_mappings = {
		Building3D.BuildingType.TOWN_CENTER: "town_center",
		Building3D.BuildingType.HOUSE: "house",
		Building3D.BuildingType.BARRACKS: "barracks",
		Building3D.BuildingType.ARCHERY_RANGE: "archery_range",
		Building3D.BuildingType.STABLE: "stable",
		Building3D.BuildingType.CASTLE: "castle",
		Building3D.BuildingType.TOWER: "watch_tower",
		Building3D.BuildingType.FARM: "farm",
		Building3D.BuildingType.BLACKSMITH: "blacksmith",
		Building3D.BuildingType.LUMBER_CAMP: "lumber_camp",
		Building3D.BuildingType.MINING_CAMP: "mining_camp",
		Building3D.BuildingType.MILL: "mill"
	}

	for b_type in expected_mappings.keys():
		var expected_id = expected_mappings[b_type]
		var resolved_id = FactionArtManager.get_building_id_from_type(b_type)
		assert_true(resolved_id == expected_id, "Type %d maps to %s" % [b_type, expected_id])

func test_all_10_factions_12_building_instances() -> void:
	print("\n--- TEST: Instantiating 12 Buildings Across All 10 Factions (120 Nodes) ---")
	var all_civs = [
		CivData.CivType.OTTOMANS,
		CivData.CivType.BYZANTINES,
		CivData.CivType.BRITONS,
		CivData.CivType.FRANKS,
		CivData.CivType.MONGOLS,
		CivData.CivType.TEUTONS,
		CivData.CivType.JAPANESE,
		CivData.CivType.SARACENS,
		CivData.CivType.VIKINGS,
		CivData.CivType.CHINESE
	]

	var all_types = [
		Building3D.BuildingType.TOWN_CENTER,
		Building3D.BuildingType.HOUSE,
		Building3D.BuildingType.BARRACKS,
		Building3D.BuildingType.ARCHERY_RANGE,
		Building3D.BuildingType.STABLE,
		Building3D.BuildingType.CASTLE,
		Building3D.BuildingType.TOWER,
		Building3D.BuildingType.FARM,
		Building3D.BuildingType.BLACKSMITH,
		Building3D.BuildingType.LUMBER_CAMP,
		Building3D.BuildingType.MINING_CAMP,
		Building3D.BuildingType.MILL
	]

	var success_count = 0
	var dummy_parent = Node3D.new()
	root.add_child(dummy_parent)

	for civ in all_civs:
		for b_type in all_types:
			var b = Building3D.new()
			dummy_parent.add_child(b)
			b.setup_building(b_type, 0, civ, Vector2i(10, 10), null, null, false)

			var has_sprite = (is_instance_valid(b.building_sprite) and b.building_sprite.texture != null) or (b.building_type == Building3D.BuildingType.FARM and b.model_root != null and b.model_root.get_child_count() > 0)
			var has_col = is_instance_valid(b.collision_shape) and b.collision_shape.shape != null
			var has_sel = is_instance_valid(b.selection_mesh)
			var has_hp = is_instance_valid(b.hp_bar_holder)
			var correct_billboard = (b.building_type == Building3D.BuildingType.FARM) or (is_instance_valid(b.building_sprite) and b.building_sprite.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y)

			if has_sprite and has_col and has_sel and has_hp and correct_billboard:
				success_count += 1
			b.queue_free()

	assert_true(success_count == 120, "120/120 Building instances built with valid Sprite3D, collision and UI (got %d)" % success_count)
	dummy_parent.queue_free()

func test_construction_progression_visuals() -> void:
	print("\n--- TEST: Construction Progression & Opacity Transition ---")
	var b = Building3D.new()
	root.add_child(b)
	b.setup_building(Building3D.BuildingType.BARRACKS, 0, CivData.CivType.OTTOMANS, Vector2i(5, 5), null, null, true)

	assert_true(not b.is_completed, "Building starts uncompleted")
	assert_true(b.scaffold_node.visible, "Scaffold is visible during construction")
	assert_true(b.building_sprite.modulate.a < 0.6, "Sprite is semi-transparent during construction (alpha=%.2f)" % b.building_sprite.modulate.a)

	b.contribute_construction(100.0)
	assert_true(b.is_completed, "Building completes after 100 progress")
	assert_true(not b.scaffold_node.visible, "Scaffold hidden after completion")
	assert_true(b.building_sprite.modulate.a >= 0.99, "Sprite restores to full opacity on completion")
	b.queue_free()

func test_enemy_civ_tint() -> void:
	print("\n--- TEST: Enemy Faction Red Tint Visual ---")
	var b_ally = Building3D.new()
	root.add_child(b_ally)
	b_ally.setup_building(Building3D.BuildingType.TOWN_CENTER, 0, CivData.CivType.FRANKS, Vector2i(2, 2), null, null, false)

	var b_enemy = Building3D.new()
	root.add_child(b_enemy)
	b_enemy.setup_building(Building3D.BuildingType.TOWN_CENTER, 1, CivData.CivType.BYZANTINES, Vector2i(8, 8), null, null, false)

	assert_true(b_ally.building_sprite.modulate == Color(1.0, 1.0, 1.0), "Ally building has clean un-tinted modulate")
	assert_true(b_enemy.building_sprite.modulate.r > 1.0, "Enemy building has red military tint modulate")

	b_ally.queue_free()
	b_enemy.queue_free()

func test_art_preview_gallery_integration() -> void:
	print("\n--- TEST: Art Preview Gallery Building Catalog Integration ---")
	var preview = ArtPreview.new()
	root.add_child(preview)

	assert_true(preview.building_catalog.has("factions"), "ArtPreview loaded building manifest factions")
	assert_true(preview.building_catalog.has("building_types") or preview.building_catalog.has("buildings"), "ArtPreview loaded building types metadata")

	preview._switch_mode("buildings")
	assert_true(preview.current_view_mode == "buildings", "Gallery switched to Buildings mode")
	assert_true(preview.unit_cards_container.get_child_count() == 13, "Gallery shows all 13 building cards for active faction (got %d)" % preview.unit_cards_container.get_child_count())

	preview._switch_mode("units")
	assert_true(preview.current_view_mode == "units", "Gallery switched back to Units mode")
	assert_true(preview.unit_cards_container.get_child_count() == 5, "Gallery shows 5 unit cards")
	preview.queue_free()

func test_ui_manager_portrait_integration(game: GameController3D) -> void:
	print("\n--- TEST: UI Manager Building Portrait Faction Art ---")
	var b = game.place_building(Building3D.BuildingType.CASTLE, 0, Vector2i(14, 14), false)
	game.ui_manager.set_selected_entity(b)
	var expected_tex = FactionArtManager.get_building_texture(b.civ_type, Building3D.BuildingType.CASTLE)
	assert_true(game.ui_manager.entity_portrait_rect.texture == expected_tex, "Selected player Castle displays authentic faction Castle art in HUD portrait")

func test_gameplay_placement_and_demolition(game: GameController3D) -> void:
	print("\n--- TEST: In-Game Building Placement & Demolition ---")
	var b = game.place_building(Building3D.BuildingType.HOUSE, 0, Vector2i(20, 20), false)
	assert_true(b.hp == b.max_hp, "Building has full HP upon placement")
	assert_true(b in game.buildings, "Building registered in active buildings list")

	b.take_damage(b.max_hp + 50.0, 1)
	assert_true(b.hp <= 0, "Building HP drops to zero after fatal damage")
