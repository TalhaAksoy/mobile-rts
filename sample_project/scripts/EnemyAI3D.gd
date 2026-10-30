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

	var villagers = []
	var military = []
	for u in enemy_units:
		if u.unit_type == Unit3D.UnitType.VILLAGER:
			villagers.append(u)
		else:
			military.append(u)

	var tc = null
	for b in enemy_buildings:
		if b.building_type == Building3D.BuildingType.TOWN_CENTER and b.is_completed:
			tc = b
			break

	var max_vills = 7 if difficulty == Difficulty.EASY else (12 if difficulty == Difficulty.NORMAL else 16)
	if tc != null and villagers.size() < max_vills and tc.train_queue.size() < 2:
		if resources["food"] >= 50:
			main_game.try_train_unit(tc, Unit3D.UnitType.VILLAGER, 1)

	# Age II Advancement
	if my_age == 1 and tc != null and not tc.is_researching:
		if resources["food"] >= 500 and resources["gold"] >= 200:
			main_game.try_start_research(tc, "AGE_2", 1)

	var wood_needed = resources["wood"] < 150
	var gold_needed = resources["gold"] < 120
	var stone_needed = resources["stone"] < 150 and my_age >= 2

	for v in villagers:
		if v.state == Unit3D.State.IDLE:
			if stone_needed and map_gen.stone_mines.size() > 0:
				_send_to_resource(v, "stone")
			elif wood_needed:
				_send_to_resource(v, "wood")
			elif gold_needed:
				_send_to_resource(v, "gold")
			else:
				_send_to_resource(v, "food")

	var pop = main_game.get_team_population(1)
	var max_pop = main_game.get_team_max_population(1)

	if (max_pop - pop) <= 2 and resources["wood"] >= 30 and not _is_building_in_progress(Building3D.BuildingType.HOUSE):
		_build_structure(Building3D.BuildingType.HOUSE, villagers)
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

	var start_cell = Vector2i(int(MapGenerator3D.MAP_WIDTH * 0.5), 8)
	var found_cell = _find_build_spot(start_cell, Vector2i(3, 3))
	if found_cell == Vector2i(-1, -1):
		return

	var free_worker = null
	for v in villagers:
		if v.state != Unit3D.State.BUILDING:
			free_worker = v
			break

	if free_worker != null:
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
