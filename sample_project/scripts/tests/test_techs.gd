extends SceneTree
## Data-driven research (TechData): ages I -> II -> III, per-building upgrades, economy lines,
## gating (age / prerequisites / queued twice / resources), effects on existing and new
## units & buildings, the upgraded (civ) dressing, and save/load.
const GameController3D = preload("res://scripts/GameController3D.gd")
const SaveManager = preload("res://scripts/SaveManager.gd")

var failures := 0
var game

func _expect(cond: bool, msg: String) -> void:
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _init() -> void:
	call_deferred("_run")

func _rich() -> void:
	game.team_resources[0] = {"food": 99999, "wood": 99999, "gold": 99999, "stone": 99999}

func _place(t: int, cell: Vector2i) -> Building3D:
	return game.place_building(t, 0, cell, false)

## Researches instantly (completion handler), after checking it was allowed to start.
func _research(b: Building3D, id: String) -> bool:
	var ok: bool = game.try_start_research(b, id, 0)
	if ok:
		# take the job out of the building's production queue, then apply it
		b.cancel_train_queue_item(b.find_research_index(id))
		game._on_building_research_completed(id, 0)
	return ok

func _run() -> void:
	seed(99)
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	game = scene as GameController3D
	game.selected_map_type = CivData.MapType.DESERT_OASIS
	game.start_match()
	game.enemy_ai.set_process(false)
	var mg = game.map_gen
	var tc: Building3D = null
	for b in game.buildings:
		if b.team == 0 and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			tc = b

	# every tech's building has a panel entry and valid data
	var bad := []
	for id in TechData.TECHS.keys():
		var t: Dictionary = TechData.get_tech(id)
		if not t.has("name") or not t.has("cost") or not t.has("effects") or not t.has("time"):
			bad.append(id)
		for r in t.get("requires", []):
			if not TechData.TECHS.has(r):
				bad.append(id + "->" + r)
	_expect(bad.is_empty(), "all %d techs have name/cost/time/effects and valid prerequisites %s" % [TechData.TECHS.size(), str(bad)])

	# every civ has a Blender upgrade kit that loads and carries a team-coloured surface
	var kit_bad := []
	for civ in CivData.CIVS.keys():
		var kit = FactionArtManager.instantiate_upgrade_kit(civ, 1)
		if kit == null:
			kit_bad.append(CivData.get_civ(civ)["id"])
			continue
		var has_team := [false]
		var stack: Array = [kit]
		while not stack.is_empty():
			var n = stack.pop_back()
			if n is MeshInstance3D:
				for i in n.mesh.get_surface_count():
					var m = n.get_surface_override_material(i)
					if m != null and m == FactionArtManager.get_team_trim_material(1):
						has_team[0] = true
			stack.append_array(n.get_children())
		if not has_team[0]:
			kit_bad.append(CivData.get_civ(civ)["id"] + "(no team surface)")
		kit.free()
	_expect(kit_bad.is_empty(), "all %d civ upgrade kits load with a team surface %s" % [CivData.CIVS.size(), str(kit_bad)])

	# ---- gating
	game.team_resources[0] = {"food": 0, "wood": 0, "gold": 0, "stone": 0}
	_expect(game.research_block_reason(tc, "AGE_2", 0) == "Yetersiz kaynak", "Age II needs resources")
	_rich()
	_expect(game.research_block_reason(tc, "AGE_3", 0) == "Hisar Çağı gerekli", "Age III needs Age II first")
	_expect(game.research_block_reason(tc, "tc_fortify", 0) == "Hisar Çağı gerekli", "TC upgrade gated by age")
	var free := Vector2i(4, 30)
	var mill := _place(Building3D.BuildingType.MILL, Vector2i(2, 26))
	var lumber := _place(Building3D.BuildingType.LUMBER_CAMP, Vector2i(6, 26))
	var house := _place(Building3D.BuildingType.HOUSE, Vector2i(10, 26))
	var tower := _place(Building3D.BuildingType.TOWER, Vector2i(14, 26))
	var barracks := _place(Building3D.BuildingType.BARRACKS, Vector2i(2, 30))
	_expect(game.research_block_reason(mill, "heavy_plough", 0) == "Hisar Çağı gerekli", "Heavy plough gated by Age II")

	# ---- Age I economy tech: irrigation boosts fields and berries
	_expect(is_equal_approx(game.get_gather_mult(0, "field"), 1.0), "no field bonus before research")
	_expect(_research(mill, "irrigation"), "Irrigation researched at the Mill")
	_expect(is_equal_approx(game.get_gather_mult(0, "field"), 1.15) and is_equal_approx(game.get_gather_mult(0, "food"), 1.10), "Irrigation: field x1.15, berries x1.10")
	_expect(game.research_block_reason(mill, "irrigation", 0) == "Zaten geliştirildi", "cannot research twice")
	_expect(is_equal_approx(game.get_gather_mult(1, "field"), 1.0), "enemy team unaffected")

	# ---- ages
	_expect(_research(tc, "AGE_2"), "Age II")
	_expect(game.team_age[0] == 2, "team is in Age II")
	_expect(game.research_block_reason(tc, "AGE_2", 0) in ["Zaten geliştirildi", "Zaten geçildi"], "Age II not offered again")
	_expect(game.research_block_reason(mill, "heavy_plough", 0) == "", "Heavy plough unlocked in Age II")
	_expect(game.research_block_reason(lumber, "saw_pit", 0) == "Önce: Keskin Baltalar", "Saw pit requires Sharp axes")

	# ---- per-building upgrades and levels
	var pop0: int = game.get_team_max_population(0)
	var house_hp0: float = house.max_hp
	_expect(_research(house, "stone_houses"), "Stone houses")
	var houses := 0
	for b in game.buildings:
		if b.team == 0 and b.building_type == Building3D.BuildingType.HOUSE and b.is_completed:
			houses += 1
	_expect(game.get_team_max_population(0) == min(pop0 + 3 * houses, 70), "every house +3 population (%d -> %d)" % [pop0, game.get_team_max_population(0)])
	_expect(is_equal_approx(house.max_hp, house_hp0 + 350.0), "house +350 HP")
	_expect(house.upgrade_level == 2 and is_instance_valid(house.upgrade_node), "house shows its upgraded dressing")
	var house2 := _place(Building3D.BuildingType.HOUSE, Vector2i(10, 30))
	_expect(house2.upgrade_level == 2 and is_equal_approx(house2.max_hp, house_hp0 + 350.0), "a house built AFTER the upgrade is upgraded too")

	var t_dmg: float = tower.shoot_damage
	var t_rng: float = tower.shoot_range
	_expect(_research(tower, "stone_tower"), "Stone tower")
	_expect(is_equal_approx(tower.shoot_damage, t_dmg + 4.0) and is_equal_approx(tower.shoot_range, t_rng + 1.5), "tower +4 damage, +1.5 range")

	# ---- unit techs on existing and new units, train speed
	var sw_old: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, barracks.global_position + Vector3(5, 0, 0))
	var hp_old: float = sw_old.max_hp
	_expect(_research(barracks, "drill_yard"), "Drill yard")
	_expect(is_equal_approx(sw_old.max_hp, hp_old + 20.0), "existing infantry +20 HP")
	var sw_new: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, barracks.global_position + Vector3(6, 0, 0))
	_expect(is_equal_approx(sw_new.max_hp, hp_old + 20.0), "newly trained infantry +20 HP")
	_expect(is_equal_approx(game.get_train_speed_mult(0, Building3D.BuildingType.BARRACKS), 0.8), "barracks trains 20% faster")
	game.try_train_unit(barracks, Unit3D.UnitType.SWORDSMAN, 0)
	_expect(barracks.train_queue.size() > 0 and barracks.train_queue[-1]["duration"] < 4.5 * CivData.get_civ(barracks.civ_type).get("train_speed_mult", 1.0), "queued swordsman uses the faster time (%.2fs)" % barracks.train_queue[-1]["duration"])

	# ---- carry bonus
	var v: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, mill.global_position + Vector3(3, 0, 0))
	var carry0: int = v.max_carry
	_expect(_research(lumber, "sharp_axes") and _research(lumber, "saw_pit"), "Sharp axes -> Saw pit chain")
	_expect(v.max_carry == carry0 + 3, "existing villager +3 carry")
	_expect(is_equal_approx(game.get_gather_mult(0, "wood"), 1.15 * 1.15), "wood x1.3225 after both")

	# ---- Age III
	_expect(_research(tc, "AGE_3"), "Age III")
	_expect(game.team_age[0] == 3, "team is in Age III")
	_expect(_research(mill, "heavy_plough") and _research(mill, "crop_rotation"), "Age III mill line completes")
	_expect(mill.upgrade_level == 2, "mill upgraded look after Heavy plough")

	# ---- one research at a time per building: a second one waits in the building's queue (it used to
	# be refused as "Bina meşgul"); the same tech is never queued twice
	var bs := _place(Building3D.BuildingType.BLACKSMITH, Vector2i(14, 30))
	_expect(game.try_start_research(bs, "iron_weapons", 0), "Blacksmith starts Iron weapons")
	_expect(game.try_start_research(bs, "scale_armor", 0) and bs.train_queue.size() == 2 and bs.current_research_tech == "iron_weapons",
		"a second research waits behind the running one (queue %d, running %s)" % [bs.train_queue.size(), bs.current_research_tech])
	_expect(game.research_block_reason(bs, "scale_armor", 0) == "Sırada" and game.research_block_reason(bs, "iron_weapons", 0) == "Araştırılıyor",
		"the same research cannot be queued twice (Sırada / Araştırılıyor)")
	bs.train_queue.clear()
	bs._sync_research_state()

	# ---- save -> load keeps techs, levels and stats
	var path := "user://saves/test_techs.json"
	_expect(SaveManager.save_game(game, path), "saved")
	SaveManager.load_game(game, path)
	await process_frame
	var house_ok := false
	var tower_ok := false
	for b in game.buildings:
		if is_instance_valid(b) and b.team == 0:
			if b.building_type == Building3D.BuildingType.HOUSE and b.upgrade_level == 2 and is_equal_approx(b.max_hp, house_hp0 + 350.0):
				house_ok = true
			if b.building_type == Building3D.BuildingType.TOWER and is_equal_approx(b.shoot_damage, t_dmg + 4.0):
				tower_ok = true
	_expect(game.team_age[0] == 3 and game.has_tech(0, "crop_rotation"), "after load: Age III and techs kept")
	_expect(house_ok and tower_ok, "after load: building upgrades re-applied (house look+HP, tower damage)")
	_expect(is_equal_approx(game.get_gather_mult(0, "field"), 1.15 * 1.20 * 1.25), "after load: field bonus %.3f" % game.get_gather_mult(0, "field"))

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
