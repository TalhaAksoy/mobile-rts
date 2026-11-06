extends SceneTree
## Age looks (Köy / Hisar / İmparatorluk) on the real Main3D scene:
##  1. Assets: every age variant referenced by the 2D sprite manifests and the 3D unit manifest exists on disk.
##  2. 2D style: a building and a soldier start in the Age I look; Age II / III research swaps both in place
##     (sprite textures *_a1 -> base -> *_a3), villagers keep one look, units trained later spawn in the new age.
##  3. 3D style: Age I swaps the roof material to thatch, Age III adds the standards; soldiers swap their model.
##  4. Feedback: the top bar names the age, the age-up card and the sparkle bursts appear.

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")

var failures := 0
var game: GameController3D

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _wait_frames(n: int) -> void:
	for i in n:
		await process_frame

func _sprite_path(b: Building3D) -> String:
	return b.building_sprite.texture.resource_path if b.building_sprite != null and b.building_sprite.texture != null else ""

func _unit_path(u: Unit3D) -> String:
	return u.unit_sprite.texture.resource_path if is_instance_valid(u.unit_sprite) and u.unit_sprite.texture != null else ""

func _unit_model_path(u: Unit3D) -> String:
	return u.unit_model.scene_file_path if is_instance_valid(u.unit_model) else ""

func _check_assets() -> void:
	var missing: Array = []
	var n := 0
	for path in ["res://data/art/sprite_manifest.json", "res://data/art/unit_sprite_manifest.json"]:
		var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var sec: Dictionary = m.get("buildings", m.get("units", {}))
		for civ in sec:
			for id in sec[civ]:
				for age in sec[civ][id].get("ages", {}):
					for t in ["t0", "t1"]:
						n += 1
						var p: String = sec[civ][id]["ages"][age].get(t, "")
						if p == "" or not ResourceLoader.exists(p):
							missing.append(p if p != "" else "%s/%s@a%s %s" % [civ, id, age, t])
	_check(n >= 600 and missing.is_empty(), "2D age sprites: %d referenced, missing %s" % [n, str(missing.slice(0, 4))])
	var um: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/art/unit_model_manifest.json"))["units"]
	var n3 := 0
	var miss3: Array = []
	for civ in um:
		for role in um[civ]:
			for age in um[civ][role].get("ages", {}):
				n3 += 1
				if not ResourceLoader.exists(um[civ][role]["ages"][age]["model"]):
					miss3.append(um[civ][role]["ages"][age]["model"])
	_check(n3 >= 90 and miss3.is_empty(), "3D age models: %d referenced, missing %s" % [n3, str(miss3.slice(0, 4))])

func _run() -> void:
	_check_assets()
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	game = scene as GameController3D
	var was_3d := FactionArtManager.use_3d_building_models
	FactionArtManager.use_3d_building_models = false
	GraphicsSettings.set_value("style", 1)
	game.start_match()
	game.enemy_ai.set_process(false)
	game.enemy_ai.set_physics_process(false)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	await _wait_frames(3)

	# ---- 2D ------------------------------------------------------------------------------------------
	var start: Vector3 = game.map_gen.player_start_pos
	var tc: Building3D = null
	for b in game.buildings:
		if b.team == 0 and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			tc = b
	var sw: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, start + Vector3(6, 0, 6))
	var vil: Unit3D = null
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vil = u
			break
	await _wait_frames(2)
	_check(tc != null and _sprite_path(tc).ends_with("town_center_a1_t0.png"), "2D: the Town Center starts in its Age I look (%s)" % _sprite_path(tc))
	_check(_unit_path(sw).ends_with("swordsman_a1_t0.png"), "2D: a soldier starts in the Age I kit (%s)" % _unit_path(sw))
	var vil_path := _unit_path(vil)
	_check(game.ui_manager.civ_label.text.contains(TechData.age_name(1)), "top bar names the age: '%s'" % game.ui_manager.civ_label.text)

	game._on_building_research_completed("AGE_2", 0)
	await _wait_frames(3)
	_check(_sprite_path(tc).ends_with("town_center_t0.png"), "2D: Age II research swaps the Town Center in place (%s)" % _sprite_path(tc))
	_check(is_instance_valid(sw) and _unit_path(sw).ends_with("swordsman_t0.png"), "2D: the soldier on the field changes into the Age II kit")
	_check(_unit_path(vil) == vil_path, "2D: villagers keep their look")
	_check(game.ui_manager.civ_label.text.contains(TechData.age_name(2)), "top bar shows the new age: '%s'" % game.ui_manager.civ_label.text)
	_check(game.ui_manager.hud_root.find_child("AgeUpCard", true, false) != null, "age-up card is on screen")
	var sparks := 0
	for c in game.get_children():
		if c is CPUParticles3D:
			sparks += 1
	_check(sparks >= 2, "sparkle bursts on the buildings and soldiers (%d)" % sparks)

	game._on_building_research_completed("AGE_3", 0)
	await _wait_frames(3)
	_check(_sprite_path(tc).ends_with("town_center_a3_t0.png"), "2D: Age III look on the Town Center")
	_check(_unit_path(sw).ends_with("swordsman_a3_t0.png"), "2D: Age III kit on the soldier")
	var sw2: Unit3D = game.spawn_unit(Unit3D.UnitType.SPEARMAN, 0, start + Vector3(7, 0, 5))
	await _wait_frames(2)
	_check(_unit_path(sw2).ends_with("spearman_a3_t0.png"), "2D: a soldier trained later spawns in the current age")
	var enemy_tc: Building3D = null
	for b in game.buildings:
		if b.team == 1 and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			enemy_tc = b
	_check(enemy_tc != null and _sprite_path(enemy_tc).contains("_a1_"), "2D: the enemy keeps its own age (still Age I)")

	# ---- 3D ------------------------------------------------------------------------------------------
	FactionArtManager.use_3d_building_models = true
	GraphicsSettings.set_value("style", 0)
	game.team_age[0] = 1
	var b3: Building3D = game.place_building(Building3D.BuildingType.HOUSE, 0, game.map_gen.world_to_cell(start) + Vector2i(-8, 6), false)
	var u3: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, start + Vector3(-6, 0, 8))
	await _wait_frames(2)
	var village := false
	for m in ["PE_Thatch", "PE_MudRoof", "PE_Grass"]:              # the civ's village roof (thatch / earth / turf)
		village = village or (b3.building_model != null and _uses_material(b3.building_model, m))
	_check(village, "3D: Age I house has the village roof")
	_check(_unit_model_path(u3).ends_with("swordsman_a1.glb"), "3D: Age I soldier model (%s)" % _unit_model_path(u3))
	game.team_age[0] = 2
	game._on_building_research_completed("AGE_3", 0)
	await _wait_frames(3)
	_check(not _uses_material(b3.building_model, "PE_MudRoof") and (not _uses_material(b3.building_model, "PE_Thatch") or _base_uses(b3.building_model, "PE_Thatch")), "3D: Age III restores the masonry and roof tiles")
	_check(is_instance_valid(b3.age_dressing) and b3.age_dressing.name == "AgeDressing", "3D: Age III standards on the building")
	_check(_unit_model_path(u3).ends_with("swordsman_a3.glb"), "3D: the soldier switches to the Age III model (%s)" % _unit_model_path(u3))

	FactionArtManager.use_3d_building_models = was_3d
	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _uses_material(node: Node, mat_name: String) -> bool:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var o = mi.get_surface_override_material(i)
			if o != null and o.resource_path.get_file().get_basename() == mat_name:
				return true
	for c in node.get_children():
		if _uses_material(c, mat_name):
			return true
	return false

func _base_uses(node: Node, mat_name: String) -> bool:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src = mi.mesh.surface_get_material(i)
			if src != null and src.resource_name == mat_name:
				return true
	for c in node.get_children():
		if _base_uses(c, mat_name):
			return true
	return false
