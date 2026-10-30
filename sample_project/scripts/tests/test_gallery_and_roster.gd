extends SceneTree

const ArtPreview = preload("res://scripts/ArtPreview.gd")

func _init() -> void:
	print("\n========================================")
	print("--- TESTING ART GALLERY & CIV ROSTER ---")
	print("========================================")

	# 1. Test ArtPreview scene instantiation
	var preview_scene = load("res://scenes/ArtPreview.tscn")
	assert(preview_scene != null, "ArtPreview.tscn failed to load")
	var preview_inst = preview_scene.instantiate() as ArtPreview
	root.add_child(preview_inst)
	preview_inst._ready()
	assert(preview_inst != null, "ArtPreview instantiation failed")
	print("[1/3] ArtPreview instantiated and initialized.")

	# 2. Test all 10 factions preview switching in ArtPreview
	var factions_count = preview_inst.catalog.get("factions", []).size()
	assert(factions_count == 10, "Expected 10 factions in catalog, got %d" % factions_count)
	for i in range(10):
		preview_inst._show_faction(i)
		assert(preview_inst.unit_cards_container.get_child_count() == 5, "Faction %d should render 5 unit cards" % i)
	print("[2/3] All 10 factions verified in gallery (5 cards per faction = 50 unit cards rendered).")

	# 3. Test MenuRoot civ unit preview roster
	var main_scene = load("res://scenes/Main3D.tscn")
	assert(main_scene != null, "Main3D.tscn failed to load")
	var main_inst = main_scene.instantiate()
	root.add_child(main_inst)
	var menu_root = main_inst.get_node("UIManager3D/MenuRoot") as MenuRoot
	assert(menu_root != null, "MenuRoot node not found")
	menu_root._ready()

	for civ_val in CivData.CIVS.keys():
		menu_root.selected_player_civ = civ_val
		menu_root._update_civ_preview()
		assert(menu_root.roster_preview_box.get_child_count() == 5, "Civ %d roster should have 5 unit icons" % civ_val)
	print("[3/3] MenuRoot roster preview verified across all 10 civilizations.")

	print("========================================")
	print("GALLERY & CIV ROSTER TESTS PASSED!")
	print("========================================\n")
	quit(0)
