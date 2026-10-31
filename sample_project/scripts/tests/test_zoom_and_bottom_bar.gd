extends SceneTree

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")
const ArtPreview = preload("res://scripts/ArtPreview.gd")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("\n========================================")
	print("--- TESTING ZOOM CONTROLS & BOTTOM BAR FLOW ---")
	print("========================================")

	var main_scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(main_scene)

	var game = main_scene as GameController3D
	game.start_match()

	# 1. Test In-Game Zoom In and Zoom Out
	print("[1/4] Testing Camera Zoom In / Zoom Out...")
	var initial_cam_h = game.camera.target_height
	if not _expect(initial_cam_h > 0, "Camera initial height must be positive"): return

	game.ui_manager.zoom_in_requested.emit()
	if not _expect(game.camera.target_height < initial_cam_h, "Zoom In should decrease camera height"): return

	game.ui_manager.zoom_out_requested.emit()
	game.ui_manager.zoom_out_requested.emit()
	if not _expect(game.camera.target_height > initial_cam_h, "Zoom Out should increase camera height"): return
	print("-> Zoom In and Zoom Out verified successfully.")

	# 2. Test Bottom Bar Dynamic Height & Mode Switching
	print("[2/4] Testing Bottom Bar Height Expansion on Selection...")
	var ui = game.ui_manager
	if not _expect(ui.default_bar.visible == true, "Default empire bar must be visible initially"): return
	if not _expect(ui.selection_deck.visible == false, "Selection deck must be hidden initially"): return

	var tc: Building3D = null
	for b in game.buildings:
		if b.team == 0 and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			tc = b
			break
	if not _expect(tc != null, "Player Town Center must exist"): return

	ui.set_selected_entity(tc)
	if not _expect(ui.default_bar.visible == false, "Default bar must hide on selection"): return
	if not _expect(ui.selection_deck.visible == true, "Selection deck must show on selection"): return
	if not _expect(ui.bottom_bar.offset_top <= -200.0, "BottomBar must expand height upwards (offset_top <= -200)"): return
	print("-> Bottom Bar expansion verified: offset_top is now %f" % ui.bottom_bar.offset_top)

	# 3. Test Flex-Wrap HFlowContainer Action Buttons
	print("[3/4] Testing HFlowContainer action buttons...")
	var flow = ui.action_flow
	if not _expect(flow is HFlowContainer, "Action buttons container must be an HFlowContainer"): return
	if not _expect(flow.get_child_count() >= 2, "Town Center must have at least 2 action buttons"): return
	for child in flow.get_children():
		var btn = child as Button
		if not _expect(btn != null, "Child must be a button"): return
		if not _expect(btn.custom_minimum_size.x >= 140, "Button width must be generous for mobile (>= 140px)"): return
	print("-> Action buttons in flex-wrap HFlowContainer verified (count: %d, min width >= 140px)." % flow.get_child_count())

	# Deselect and verify contraction
	ui.clear_selection_requested.emit()
	if not _expect(ui.default_bar.visible == true, "Default bar must restore on deselect"): return
	if not _expect(ui.selection_deck.visible == false, "Selection deck must hide on deselect"): return
	if not _expect(ui.bottom_bar.offset_top >= -120.0, "BottomBar must contract back down (offset_top >= -120)"): return
	print("-> Bottom Bar contraction on deselect verified.")

	# 4. Test Art Gallery Flag Icons in Faction Picker
	print("[4/4] Testing Faction Picker Flags in ArtPreview...")
	var art_scene = load("res://scenes/ArtPreview.tscn").instantiate() as ArtPreview
	root.add_child(art_scene)
	art_scene._ready()
	if not _expect(art_scene.faction_picker.item_count == 10, "Faction picker must have 10 items"): return
	for i in range(10):
		var icon = art_scene.faction_picker.get_item_icon(i)
		if not _expect(icon != null, "Faction item %d must have a valid flag icon" % i): return
	print("-> All 10 factions verified to have valid flag icons in dropdown.")

	print("========================================")
	print("ZOOM & BOTTOM BAR TESTS ALL PASSED!")
	print("========================================\n")
	quit(0)


## Non-halting assertion: a failed GDScript assert() stops the function before quit(), which made
## headless runs hang until the runner's timeout and hid every later test. Report and exit instead.
func _expect(cond: bool, msg: String) -> bool:
	if not cond:
		printerr("[FAIL] " + msg)
		print("RESULT: FAIL - " + msg)
		quit(1)
	return cond
