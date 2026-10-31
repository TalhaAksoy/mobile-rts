extends SceneTree
## Every civ x every building type, in a real match, through the game's own functions:
##  * placed under construction -> the civ's own 3D model (manifest path for that civ/type), scaffold shown
##  * builders' progress completes it -> scaffold hidden, full HP, simple footprint collision
##  * producers queue their units (TC villager, barracks, archery range, stable, castle unique unit)
##  * drop-offs accept their resource (lumber camp wood, mining camp gold+stone, mill food)
##  * defensive buildings can shoot
##  * the selection panel shows the building's own name
##  * the building's own upgrade (level 2) attaches the civ upgrade kit
##  * destroying it frees the footprint
const GameController3D = preload("res://scripts/GameController3D.gd")
const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

var failures := 0
var checks := 0
var game
var bad: Array = []

func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		bad.append(msg)
		print("[FAIL] " + msg)

func _init() -> void:
	call_deferred("_run")

func _free_spot(size: Vector2i, near: Vector2i) -> Vector2i:
	var mg = game.map_gen
	for r in range(3, 40):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				for c in [near + Vector2i(dx, dy), near + Vector2i(dy, dx)]:
					var ok := true
					for x in size.x:
						for y in size.y:
							var cc = c + Vector2i(x, y)
							if not mg.is_valid_cell(cc.x, cc.y) or not mg.is_cell_buildable(cc) or not mg.get_resource_at_cell(cc).is_empty():
								ok = false
					if ok:
						return c
	return Vector2i(-1, -1)

const PRODUCES := {
	Building3D.BuildingType.TOWN_CENTER: [Unit3D.UnitType.VILLAGER],
	Building3D.BuildingType.BARRACKS: [Unit3D.UnitType.SWORDSMAN, Unit3D.UnitType.SPEARMAN],
	Building3D.BuildingType.ARCHERY_RANGE: [Unit3D.UnitType.ARCHER],
	Building3D.BuildingType.STABLE: [Unit3D.UnitType.CAVALRY],
}
const DROPOFF := {
	Building3D.BuildingType.LUMBER_CAMP: ["wood"],
	Building3D.BuildingType.MINING_CAMP: ["gold", "stone"],
	Building3D.BuildingType.MILL: ["food"],
}

func _unique_unit(civ: int) -> int:
	var key: String = CivData.get_civ(civ).get("unique_unit_type", "JANISSARY")
	return Unit3D.UnitType.keys().find(key)

func _run() -> void:
	seed(4242)
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	game = scene as GameController3D
	game.selected_map_type = CivData.MapType.HIGHLAND_PLAINS
	game.start_match()
	game.enemy_ai.set_process(false)
	game.enemy_ai.set_physics_process(false)
	var mg = game.map_gen
	var base: Vector2i = mg.world_to_cell(mg.player_start_pos)
	var types: Array = []
	for t in Building3D.BuildingType.values():
		if t != Building3D.BuildingType.FARM:
			types.append(t)
	var tested := 0
	for civ in CivData.CIVS.keys():
		game.player_civ = civ
		var civ_id: String = FactionArtManager.get_faction_id_from_civ(civ)
		for t in types:
			var b_id: String = FactionArtManager.get_building_id_from_type(t)
			var tag := "%s/%s" % [civ_id, b_id]
			game.team_resources[0] = {"food": 99999, "wood": 99999, "gold": 99999, "stone": 99999}
			var size: Vector2i = game._get_building_size(t)
			var cell := _free_spot(size, base)
			_check(cell != Vector2i(-1, -1), tag + ": free spot found")
			if cell == Vector2i(-1, -1):
				continue
			var b: Building3D = game.place_building(t, 0, cell, true)
			tested += 1
			# --- the civ's own model, under construction
			var entry: Dictionary = FactionArtManager.get_building_model_entry(civ, t)
			_check(entry.get("enabled", false) and String(entry.get("model", "")).contains("/%s/%s.glb" % [civ_id, b_id]), tag + ": manifest has the civ's own model")
			_check(b.civ_type == civ, tag + ": building has the player's civ")
			_check(is_instance_valid(b.building_model) and not is_instance_valid(b.building_sprite), tag + ": 3D model used, no sprite")
			if is_instance_valid(b.building_model):
				var scene_path: String = b.building_model.scene_file_path
				_check(scene_path == "" or scene_path == entry.get("model", ""), tag + ": instanced from %s" % scene_path)
				var aabb := FactionArtManager.compute_visual_aabb(b.building_model)
				_check(aabb.size.y > 0.8 and aabb.size.x > size.x * 1.2, tag + ": model has a real size %s" % str(aabb.size))
			_check(not b.is_completed and is_instance_valid(b.scaffold_node) and b.scaffold_node.visible, tag + ": starts under construction with scaffold")
			_check(not mg.is_cell_buildable(cell), tag + ": footprint occupied")
			# --- builders complete it
			var swings := 0
			while not b.is_completed and swings < 2000:
				b.contribute_construction(b.build_swing_progress())
				swings += 1
			_check(b.is_completed and is_equal_approx(b.hp, b.max_hp), tag + ": completed by builder swings (%d)" % swings)
			_check(not is_instance_valid(b.scaffold_node) or not b.scaffold_node.visible, tag + ": scaffold hidden when done")
			var col := b.collision_shape.shape as BoxShape3D if b.collision_shape != null else null
			_check(col != null and is_equal_approx(col.size.x, size.x * 2.0 * 0.9), tag + ": footprint collision box")
			# --- selection panel names the building (no generic "Bina")
			game.ui_manager._display_building_ui(b)
			_check(not String(game.ui_manager.entity_name_label.text).begins_with("Bina"), tag + ": panel name '%s'" % game.ui_manager.entity_name_label.text)
			# --- production
			var producible: Array = PRODUCES.get(t, [])
			if t == Building3D.BuildingType.CASTLE:
				producible = [_unique_unit(civ)]
			for u in producible:
				var q0: int = b.train_queue.size()
				_check(u >= 0 and game.try_train_unit(b, u, 0) and b.train_queue.size() == q0 + 1, tag + ": trains %s" % Unit3D.UnitType.keys()[max(u, 0)])
			if not producible.is_empty():
				b.train_queue.clear()
			# --- drop-off
			for res in DROPOFF.get(t, []):
				var got = game.get_closest_dropoff_for_resource(b.global_position + Vector3(0.5, 0, 0.5), 0, res)
				_check(got == b, tag + ": accepts %s" % res)
			# --- defence
			if t in [Building3D.BuildingType.TOWER, Building3D.BuildingType.CASTLE, Building3D.BuildingType.TOWN_CENTER]:
				_check(b.can_shoot() and b.shoot_damage > 0.0, tag + ": can shoot")
			# --- own upgrade look
			b.set_upgrade_level(2)
			_check(is_instance_valid(b.upgrade_node) and b.upgrade_node.get_parent() == b.model_root, tag + ": upgrade kit attached")
			# --- destroy frees the ground
			b.die()
			await process_frame
			_check(mg.is_cell_buildable(cell), tag + ": footprint free after destruction")
	print("tested %d civ/type pairs" % tested)
	_check(tested == CivData.CIVS.size() * types.size(), "all %d pairs tested" % (CivData.CIVS.size() * types.size()))
	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
