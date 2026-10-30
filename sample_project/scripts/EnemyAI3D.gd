class_name EnemyAI3D
extends Node

enum Difficulty { EASY, NORMAL, HARD }

@export var difficulty: Difficulty = Difficulty.NORMAL
var civ_type: CivData.CivType = CivData.CivType.BYZANTINES
var map_gen: MapGenerator3D = null
var main_game: Node = null

var ai_timer: float = 0.0
var attack_wave_timer: float = 0.0
var wave_interval: float = 40.0
var wave_count: int = 0

func setup_ai(civ: CivData.CivType, map: MapGenerator3D, game: Node, diff: Difficulty = Difficulty.NORMAL) -> void:
	civ_type = civ
	map_gen = map
	main_game = game
	difficulty = diff
	
	match difficulty:
		Difficulty.EASY:
			ai_timer = 3.5
			wave_interval = 55.0
		Difficulty.NORMAL:
			ai_timer = 2.0
			wave_interval = 40.0
		Difficulty.HARD:
			ai_timer = 1.0
			wave_interval = 28.0
			
	attack_wave_timer = wave_interval

func _process(delta: float) -> void:
	if main_game == null or not main_game.is_game_active:
		return

	ai_timer -= delta
	if ai_timer <= 0.0:
		ai_timer = 2.5
		_think()

	attack_wave_timer -= delta
	if attack_wave_timer <= 0.0:
		attack_wave_timer = max(28.0, wave_interval - wave_count * 2.0)
		wave_count += 1
		_launch_attack_wave()

func _think() -> void:
	var enemy_units = main_game.get_team_units(1)
	var enemy_buildings = main_game.get_team_buildings(1)
	var resources = main_game.get_team_resources(1)
	var my_age = main_game.team_age.get(1, 1)

	var villagers: Array[Unit3D] = []
	var military: Array[Unit3D] = []
	for u in enemy_units:
		if not is_instance_valid(u) or u.hp <= 0:
			continue
		if u.unit_type == Unit3D.UnitType.VILLAGER:
			villagers.append(u)
		else:
			military.append(u)

	var tc = null
	for b in enemy_buildings:
		if is_instance_valid(b) and b.building_type == Building3D.BuildingType.TOWN_CENTER and b.is_completed:
			tc = b
			break

	var max_vills = 8 if difficulty == Difficulty.EASY else (14 if difficulty == Difficulty.NORMAL else 18)
	if tc != null and villagers.size() < max_vills and tc.train_queue.size() < 2:
		if resources["food"] >= 50:
			main_game.try_train_unit(tc, Unit3D.UnitType.VILLAGER, 1)

	# Age II Advancement
	if my_age == 1 and tc != null and not tc.is_researching:
		if resources["food"] >= 500 and resources["gold"] >= 200:
			main_game.try_start_research(tc, "AGE_2", 1)

	# Dynamic Workforce Balancing
	_balance_workforce(villagers, resources, my_age)

	var pop = main_game.get_team_population(1)
	var max_pop = main_game.get_team_max_population(1)

	if (max_pop - pop) <= 2 and resources["wood"] >= 30 and not _is_building_in_progress(Building3D.BuildingType.HOUSE):
		_build_structure(Building3D.BuildingType.HOUSE, villagers)
		return

	# Drop-off camps to shorten walk times
	if resources["wood"] >= 100 and not _has_building(Building3D.BuildingType.LUMBER_CAMP) and not _is_building_in_progress(Building3D.BuildingType.LUMBER_CAMP):
		_build_structure(Building3D.BuildingType.LUMBER_CAMP, villagers)
		return

	if resources["wood"] >= 100 and not _has_building(Building3D.BuildingType.MINING_CAMP) and not _is_building_in_progress(Building3D.BuildingType.MINING_CAMP):
		_build_structure(Building3D.BuildingType.MINING_CAMP, villagers)
		return

	if not _has_building(Building3D.BuildingType.BARRACKS) and resources["wood"] >= 150:
		_build_structure(Building3D.BuildingType.BARRACKS, villagers)
		return

	if not _has_building(Building3D.BuildingType.ARCHERY_RANGE) and resources["wood"] >= 150:
		_build_structure(Building3D.BuildingType.ARCHERY_RANGE, villagers)
		return

	if not _has_building(Building3D.BuildingType.STABLE) and resources["wood"] >= 175:
		_build_structure(Building3D.BuildingType.STABLE, villagers)
		return

	if not _has_building(Building3D.BuildingType.BLACKSMITH) and resources["wood"] >= 150:
		_build_structure(Building3D.BuildingType.BLACKSMITH, villagers)
		return

	if my_age >= 2 and not _has_building(Building3D.BuildingType.CASTLE) and resources["wood"] >= 200 and resources["stone"] >= 350 and resources["gold"] >= 150:
		_build_structure(Building3D.BuildingType.CASTLE, villagers)
		return

	# Research Blacksmith Technologies
	for b in enemy_buildings:
		if b.building_type == Building3D.BuildingType.BLACKSMITH and b.is_completed and not b.is_researching:
			var techs = main_game.team_techs.get(1, {})
			if not techs.get("scale_armor", false) and resources["food"] >= 100 and resources["gold"] >= 40:
				main_game.try_start_research(b, "scale_armor", 1)
			elif not techs.get("iron_weapons", false) and resources["food"] >= 100 and resources["gold"] >= 40:
				main_game.try_start_research(b, "iron_weapons", 1)
			elif not techs.get("bodkin_arrows", false) and resources["wood"] >= 100 and resources["gold"] >= 50:
				main_game.try_start_research(b, "bodkin_arrows", 1)

	# Military training
	for b in enemy_buildings:
		if not b.is_completed or b.train_queue.size() >= 2:
			continue

		match b.building_type:
			Building3D.BuildingType.BARRACKS:
				if resources["food"] >= 60 and resources["gold"] >= 20:
					main_game.try_train_unit(b, Unit3D.UnitType.SWORDSMAN, 1)
				elif resources["food"] >= 50 and resources["wood"] >= 35:
					main_game.try_train_unit(b, Unit3D.UnitType.SPEARMAN, 1)
			Building3D.BuildingType.ARCHERY_RANGE:
				if resources["wood"] >= 45 and resources["gold"] >= 40:
					main_game.try_train_unit(b, Unit3D.UnitType.ARCHER, 1)
			Building3D.BuildingType.STABLE:
				if my_age >= 2 and resources["food"] >= 90 and resources["gold"] >= 75:
					main_game.try_train_unit(b, Unit3D.UnitType.PALADIN, 1)
				elif resources["food"] >= 75 and resources["gold"] >= 60:
					main_game.try_train_unit(b, Unit3D.UnitType.CAVALRY, 1)
			Building3D.BuildingType.CASTLE:
				var unique_type = _get_civ_unique_unit()
				if resources["food"] >= 80 and resources["gold"] >= 60:
					main_game.try_train_unit(b, unique_type, 1)

func _balance_workforce(villagers: Array[Unit3D], resources: Dictionary, my_age: int) -> void:
	var total_vills = villagers.size()
	if total_vills == 0:
		return

	var active_by_res = {"food": [], "wood": [], "gold": [], "stone": []}
	var idle_vills: Array[Unit3D] = []

	for v in villagers:
		if not is_instance_valid(v) or v.hp <= 0:
			continue
		if v.state == Unit3D.State.BUILDING:
			continue
		elif v.state == Unit3D.State.IDLE:
			idle_vills.append(v)
		else:
			var r = v.resource_type
			if active_by_res.has(r):
				active_by_res[r].append(v)
			else:
				idle_vills.append(v)

	var cur_food = resources.get("food", 0)
	var cur_wood = resources.get("wood", 0)
	var cur_gold = resources.get("gold", 0)
	var cur_stone = resources.get("stone", 0)

	# Prevent Gold glut / Food starvation
	if cur_gold > 200 and cur_food < 80 and active_by_res["gold"].size() > 1:
		var reassign_v = active_by_res["gold"].pop_back() as Unit3D
		_send_to_resource(reassign_v, "food")
		active_by_res["food"].append(reassign_v)

	if cur_gold > 300 and active_by_res["gold"].size() > 1:
		var target_res = "food" if cur_food < cur_wood else "wood"
		var reassign_v = active_by_res["gold"].pop_back() as Unit3D
		_send_to_resource(reassign_v, target_res)
		active_by_res[target_res].append(reassign_v)

	if cur_stone > 200 and my_age == 1 and active_by_res["stone"].size() > 0:
		var reassign_v = active_by_res["stone"].pop_back() as Unit3D
		_send_to_resource(reassign_v, "food")
		active_by_res["food"].append(reassign_v)

	# Assign idle villagers
	for v in idle_vills:
		var needed = "food"
		if cur_food < 80:
			needed = "food"
		elif cur_wood < 60:
			needed = "wood"
		elif my_age == 1 and cur_food < 500 and active_by_res["food"].size() < int(total_vills * 0.55 + 1):
			needed = "food"
		elif my_age == 1 and cur_wood < 200 and active_by_res["wood"].size() < int(total_vills * 0.35 + 1):
			needed = "wood"
		elif my_age == 1 and cur_gold < 200 and active_by_res["gold"].size() < 2:
			needed = "gold"
		elif my_age >= 2:
			if cur_food < 150:
				needed = "food"
			elif cur_wood < 150:
				needed = "wood"
			elif cur_gold < 150:
				needed = "gold"
			elif cur_stone < 350 and not _has_building(Building3D.BuildingType.CASTLE):
				needed = "stone"
			else:
				var min_val = 999999
				for res_key in ["food", "wood", "gold", "stone"]:
					if resources.get(res_key, 0) < min_val:
						min_val = resources.get(res_key, 0)
						needed = res_key
		else:
			needed = "food" if cur_food < cur_wood else "wood"

		_send_to_resource(v, needed)
		active_by_res[needed].append(v)

func _get_civ_unique_unit() -> Unit3D.UnitType:
	match civ_type:
		CivData.CivType.OTTOMANS: return Unit3D.UnitType.JANISSARY
		CivData.CivType.BYZANTINES: return Unit3D.UnitType.CATAPHRACT
		CivData.CivType.BRITONS: return Unit3D.UnitType.LONGBOWMAN
		CivData.CivType.FRANKS: return Unit3D.UnitType.PALADIN
		CivData.CivType.MONGOLS: return Unit3D.UnitType.MANGUDAI
		CivData.CivType.TEUTONS: return Unit3D.UnitType.TEUTONIC_KNIGHT
		CivData.CivType.JAPANESE: return Unit3D.UnitType.SAMURAI
		CivData.CivType.SARACENS: return Unit3D.UnitType.MAMELUKE
		CivData.CivType.VIKINGS: return Unit3D.UnitType.BERSERKER
		CivData.CivType.CHINESE: return Unit3D.UnitType.CHUKONU
		_: return Unit3D.UnitType.SWORDSMAN

func _send_to_resource(v: Unit3D, type: String) -> void:
	if map_gen == null:
		return
	var dict = map_gen.trees if type == "wood" else (map_gen.gold_mines if type == "gold" else (map_gen.stone_mines if type == "stone" else map_gen.berry_bushes))
	var my_cell = map_gen.world_to_cell(v.global_position)
	var best_cell = Vector2i(-1, -1)
	var best_dist = 999999.0

	for cell in dict.keys():
		var d = my_cell.distance_squared_to(cell)
		if d < best_dist:
			best_dist = d
			best_cell = cell

	if best_cell != Vector2i(-1, -1):
		v.command_gather(best_cell, type)

func _build_structure(b_type: Building3D.BuildingType, villagers: Array) -> void:
	if map_gen == null or villagers.is_empty():
		return

	var tc = null
	for b in main_game.get_team_buildings(1):
		if is_instance_valid(b) and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			tc = b
			break

	var start_cell = map_gen.world_to_cell(tc.global_position) if tc != null else map_gen.world_to_cell(map_gen.enemy_start_pos)
	var b_size = main_game._get_building_size(b_type) if main_game != null else Vector2i(2, 2)
	var found_cell = _find_build_spot(start_cell, b_size)
	if found_cell == Vector2i(-1, -1):
		return

	var free_worker = null
	for v in villagers:
		if is_instance_valid(v) and v.hp > 0 and v.state != Unit3D.State.BUILDING:
			free_worker = v
			break

	if free_worker != null:
		var cost = main_game._get_building_cost(b_type) if main_game != null else {"wood": 0, "gold": 0, "stone": 0}
		var res = main_game.get_team_resources(1)
		if res["wood"] >= cost["wood"] and res["gold"] >= cost["gold"] and res["stone"] >= cost["stone"]:
			res["wood"] -= cost["wood"]
			res["gold"] -= cost["gold"]
			res["stone"] -= cost["stone"]
			var b = main_game.place_building(b_type, 1, found_cell, true)
			if b != null:
				free_worker.command_build(b)

func _find_build_spot(center: Vector2i, size: Vector2i) -> Vector2i:
	for radius in range(3, 14):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var c = center + Vector2i(dx, dy)
				if _is_area_clear(c, size):
					return c
	return Vector2i(-1, -1)

func _is_area_clear(c: Vector2i, size: Vector2i) -> bool:
	if map_gen == null:
		return false
	for x in range(c.x, c.x + size.x):
		for y in range(c.y, c.y + size.y):
			if not map_gen.is_valid_cell(x, y) or not map_gen.is_cell_walkable(Vector2i(x, y)):
				return false
	return true

func _has_building(b_type: Building3D.BuildingType) -> bool:
	for b in main_game.get_team_buildings(1):
		if b.building_type == b_type:
			return true
	return false

func _is_building_in_progress(b_type: Building3D.BuildingType) -> bool:
	for b in main_game.get_team_buildings(1):
		if b.building_type == b_type and not b.is_completed:
			return true
	return false

func _launch_attack_wave() -> void:
	var enemy_units = main_game.get_team_units(1)
	var player_buildings = main_game.get_team_buildings(0)
	var player_units = main_game.get_team_units(0)

	if player_buildings.is_empty() and player_units.is_empty():
		return

	var target: Node3D = null
	for b in player_buildings:
		if b.building_type == Building3D.BuildingType.TOWN_CENTER:
			target = b
			break
	if target == null and not player_buildings.is_empty():
		target = player_buildings[0]
	elif target == null and not player_units.is_empty():
		target = player_units[0]

	if target == null:
		return

	for u in enemy_units:
		if u.unit_type != Unit3D.UnitType.VILLAGER:
			u.command_attack(target)
