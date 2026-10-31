extends SceneTree
## Validates the Blender -> GLB -> Godot building model pipeline.
##  * every enabled manifest entry loads, sits on the ground, fits its gameplay footprint,
##    and has every surface mapped to the shared material library (no stray imported materials)
##  * TEAM_* surfaces use the owning team's colour (blue / red)
##  * gameplay collision stays the simple footprint box (not derived from render geometry)
##  * construction visual (rising model + scaffold), completion, and save/load of an
##    unfinished model building
##  * fallbacks: global toggle off -> sprite; civ without a model -> sprite

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")
const Building3D = preload("res://scripts/Building3D.gd")
const GameController3D = preload("res://scripts/GameController3D.gd")
const SaveManager = preload("res://scripts/SaveManager.gd")

var failures := 0
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	checks += 1
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _type_for_id(b_id: String) -> int:
	for t in Building3D.BuildingType.values():
		if FactionArtManager.get_building_id_from_type(t) == b_id:
			return t
	return -1

func _make(b_type: int, civ: int, team: int, under_construction := false) -> Building3D:
	var b = Building3D.new()
	root.add_child(b)
	b.setup_building(b_type, team, civ, Vector2i(10, 10), null, null, under_construction)
	return b

func _run() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://data/art/building_model_manifest.json"))
	_check(typeof(manifest) == TYPE_DICTIONARY, "Model manifest parses")
	var tested := 0
	for civ_id in manifest["buildings"].keys():
		for b_id in manifest["buildings"][civ_id].keys():
			var entry: Dictionary = manifest["buildings"][civ_id][b_id]
			if not entry.get("enabled", false):
				continue
			tested += 1
			var tag := "%s/%s" % [civ_id, b_id]
			var b_type := _type_for_id(b_id)
			_check(b_type >= 0, tag + ": building id maps to a BuildingType")
			var civ := FactionArtManager.get_civ_from_faction_id(civ_id)
			var b := _make(b_type, civ, 0)
			_check(is_instance_valid(b.building_model), tag + ": 3D model instantiated")
			_check(not is_instance_valid(b.building_sprite), tag + ": sprite path not used when model exists")
			if not is_instance_valid(b.building_model):
				b.queue_free()
				continue
			var aabb := FactionArtManager.compute_visual_aabb(b.building_model)
			var half_fp := Vector2(b.grid_size.x, b.grid_size.y) * 2.0 * 0.5
			_check(absf(aabb.position.y) < 0.05, tag + ": base rests on ground (min y = %.3f)" % aabb.position.y)
			_check(aabb.position.x >= -half_fp.x - 0.05 and aabb.end.x <= half_fp.x + 0.05 and aabb.position.z >= -half_fp.y - 0.05 and aabb.end.z <= half_fp.y + 0.05,
				tag + ": fits %dx%d footprint (aabb %s)" % [b.grid_size.x, b.grid_size.y, str(aabb)])
			var col_box := b.collision_shape.shape as BoxShape3D
			_check(col_box != null and is_equal_approx(col_box.size.x, b.grid_size.x * 2.0 * 0.9), tag + ": collision is the simple footprint box")
			var bad_surfaces := []
			var team_ok := true
			var team_surfaces := 0
			for mi in b.building_model.find_children("*", "MeshInstance3D", true, false):
				for i in mi.mesh.get_surface_count():
					var m = mi.get_surface_override_material(i)
					var src_name: String = mi.mesh.surface_get_material(i).resource_name
					if src_name.begins_with("TEAM_"):
						team_surfaces += 1
						team_ok = team_ok and m != null and (m as StandardMaterial3D).albedo_color.is_equal_approx(FactionArtManager.TEAM_COLORS[0])
					elif m == null or not m.resource_path.begins_with("res://assets/3d/materials/"):
						bad_surfaces.append(src_name)
			_check(bad_surfaces.is_empty(), tag + ": all surfaces use shared library materials %s" % str(bad_surfaces))
			_check(team_surfaces > 0, tag + ": has a TEAM_* ownership surface (needed when both players share a civ)")
			_check(team_ok, tag + ": TEAM trim is team-0 blue")
			var b1 := _make(b_type, civ, 1)
			var red_ok := false
			for mi in b1.building_model.find_children("*", "MeshInstance3D", true, false):
				for i in mi.mesh.get_surface_count():
					if mi.mesh.surface_get_material(i).resource_name.begins_with("TEAM_"):
						red_ok = (mi.get_surface_override_material(i) as StandardMaterial3D).albedo_color.is_equal_approx(FactionArtManager.TEAM_COLORS[1])
			_check(red_ok, tag + ": TEAM trim is team-1 red")
			b.queue_free()
			b1.queue_free()

			# construction visuals
			var c := _make(b_type, civ, 0, true)
			_check(c.scaffold_node.visible, tag + ": scaffold visible while under construction")
			_check(absf(c.building_model.scale.y - 0.15) < 0.01, tag + ": model starts low (scale.y=%.2f)" % c.building_model.scale.y)
			c.contribute_construction(50.0)
			_check(absf(c.building_model.scale.y - 0.575) < 0.01, tag + ": model rises with progress (scale.y=%.2f at 50%%)" % c.building_model.scale.y)
			c.contribute_construction(60.0)
			_check(c.is_completed and is_equal_approx(c.building_model.scale.y, 1.0) and not c.scaffold_node.visible, tag + ": completed -> full height, scaffold hidden")
			c.queue_free()
	_check(tested > 0, "At least one enabled model in manifest (tested %d)" % tested)

	# Fallbacks
	var franks_tc := _make(Building3D.BuildingType.TOWN_CENTER, CivData.CivType.FRANKS, 0)
	var franks_entry := FactionArtManager.get_building_model_entry(CivData.CivType.FRANKS, Building3D.BuildingType.TOWN_CENTER)
	if franks_entry.is_empty() or not franks_entry.get("enabled", false):
		_check(not is_instance_valid(franks_tc.building_model) and is_instance_valid(franks_tc.building_sprite), "Civ without a model falls back to sprite")
	franks_tc.queue_free()
	FactionArtManager.use_3d_building_models = false
	var off := _make(Building3D.BuildingType.TOWN_CENTER, CivData.CivType.OTTOMANS, 0)
	_check(not is_instance_valid(off.building_model) and is_instance_valid(off.building_sprite), "Global toggle off -> sprite fallback")
	off.queue_free()
	FactionArtManager.use_3d_building_models = true

	# Save / load of an unfinished model building in the real game scene
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	var game = scene as GameController3D
	game.player_civ = CivData.CivType.OTTOMANS
	game.start_match()
	var cell = game.map_gen.world_to_cell(game.map_gen.player_start_pos) + Vector2i(5, 0)
	var site: Building3D = game.place_building(Building3D.BuildingType.TOWN_CENTER, 0, cell, true)
	_check(site != null, "Placed an unfinished Ottoman TC in a real match")
	if site != null:
		site.contribute_construction(40.0)
		_check(SaveManager.save_game(game, "user://test_models_save.json"), "Saved match with unfinished model building")
		_check(SaveManager.load_game(game, "user://test_models_save.json"), "Loaded match")
		await process_frame
		var restored: Building3D = null
		for b in game.buildings:
			if is_instance_valid(b) and not b.is_completed and b.origin_cell == cell:
				restored = b
		_check(restored != null and is_instance_valid(restored.building_model), "Unfinished building restored with its 3D model")
		if restored != null and is_instance_valid(restored.building_model):
			var want: float = lerp(0.15, 1.0, restored.construction_progress / 100.0)
			_check(absf(restored.building_model.scale.y - want) < 0.01 and restored.scaffold_node.visible,
				"Restored construction visual matches progress %.0f%% (scale.y=%.2f, want %.2f)" % [restored.construction_progress, restored.building_model.scale.y, want])

	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
