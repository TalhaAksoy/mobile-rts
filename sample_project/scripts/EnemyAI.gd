class_name EnemyAI
extends Node

var civ_type: CivData.CivType = CivData.CivType.BYZANTINES
var map_gen: MapGenerator = null
var main_game: Node = null

var ai_timer: float = 0.0
var attack_wave_timer: float = 0.0
var wave_interval: float = 45.0 # Attack every 45-60s
var wave_count: int = 0

func setup_ai(civ: CivData.CivType, map: MapGenerator, game: Node) -> void:
	civ_type = civ
	map_gen = map
	main_game = game
	ai_timer = 2.0
	attack_wave_timer = wave_interval

func _process(delta: float) -> void:
	if main_game == null or not main_game.is_game_active:
		return
		
	ai_timer -= delta
	if ai_timer <= 0.0:
		ai_timer = 2.5 # AI tick every 2.5s
		_think()
		
	attack_wave_timer -= delta
	if attack_wave_timer <= 0.0:
		attack_wave_timer = max(30.0, wave_interval - wave_count * 2.0)
		wave_count += 1
		_launch_attack_wave()

func _think() -> void:
	var enemy_units = main_game.get_team_units(1)
	var enemy_buildings = main_game.get_team_buildings(1)
	var resources = main_game.get_team_resources(1)
	
	# 1. Manage Villagers (Idle workers)
	var villagers = []
	var military = []
	for u in enemy_units:
		if u.unit_type == Unit.UnitType.VILLAGER:
			villagers.append(u)
		else:
			military.append(u)
			
	var tc = null
	for b in enemy_buildings:
		if b.building_type == Building.BuildingType.TOWN_CENTER and b.is_completed:
			tc = b
			break
			
	# If no villagers or under 8, produce villagers from TC
	if tc != null and villagers.size() < 12 and tc.train_queue.size() < 2:
		if resources["food"] >= 50:
			main_game.try_train_unit(tc, Unit.UnitType.VILLAGER, 1)

	# Assign idle villagers
	var wood_needed = resources["wood"] < 150
	var gold_needed = resources["gold"] < 120
	
	for v in villagers:
		if v.state == Unit.State.IDLE:
			if wood_needed:
				_send_to_resource(v, "wood")
			elif gold_needed:
				_send_to_resource(v, "gold")
			else:
				_send_to_resource(v, "food")

	# 2. Base Expansion / Building construction
	var pop = main_game.get_team_population(1)
	var max_pop = main_game.get_team_max_population(1)
	
	# Build House if pop headroom <= 2
	if (max_pop - pop) <= 2 and resources["wood"] >= 30 and not _is_building_in_progress(Building.BuildingType.HOUSE):
		_build_structure(Building.BuildingType.HOUSE, villagers)
		return

	# Build Barracks if none
	if not _has_building(Building.BuildingType.BARRACKS) and resources["wood"] >= 150:
		_build_structure(Building.BuildingType.BARRACKS, villagers)
		return
		
	# Build Archery or Stable
	if not _has_building(Building.BuildingType.ARCHERY_RANGE) and resources["wood"] >= 150:
		_build_structure(Building.BuildingType.ARCHERY_RANGE, villagers)
		return

	# Build Castle if rich
	if not _has_building(Building.BuildingType.CASTLE) and resources["wood"] >= 250 and resources["gold"] >= 200:
		_build_structure(Building.BuildingType.CASTLE, villagers)
		return

	# 3. Train Military Units
	for b in enemy_buildings:
		if not b.is_completed or b.train_queue.size() >= 2:
			continue
			
		match b.building_type:
			Building.BuildingType.BARRACKS:
				if resources["food"] >= 60 and resources["gold"] >= 20:
					main_game.try_train_unit(b, Unit.UnitType.SWORDSMAN, 1)
				elif resources["food"] >= 50 and resources["wood"] >= 35:
					main_game.try_train_unit(b, Unit.UnitType.SPEARMAN, 1)
			Building.BuildingType.ARCHERY_RANGE:
				if resources["wood"] >= 45 and resources["gold"] >= 40:
					main_game.try_train_unit(b, Unit.UnitType.ARCHER, 1)
			Building.BuildingType.STABLE:
				if resources["food"] >= 75 and resources["gold"] >= 60:
					main_game.try_train_unit(b, Unit.UnitType.CAVALRY, 1)
			Building.BuildingType.CASTLE:
				# Train Unique Civ Unit!
				var unique_type = _get_civ_unique_unit()
				if resources["food"] >= 80 and resources["gold"] >= 60:
					main_game.try_train_unit(b, unique_type, 1)

func _get_civ_unique_unit() -> Unit.UnitType:
	match civ_type:
		CivData.CivType.OTTOMANS: return Unit.UnitType.JANISSARY
		CivData.CivType.BYZANTINES: return Unit.UnitType.CATAPHRACT
		CivData.CivType.BRITONS: return Unit.UnitType.LONGBOWMAN
		CivData.CivType.FRANKS: return Unit.UnitType.PALADIN
		CivData.CivType.MONGOLS: return Unit.UnitType.MANGUDAI
		CivData.CivType.TEUTONS: return Unit.UnitType.TEUTONIC_KNIGHT
		CivData.CivType.JAPANESE: return Unit.UnitType.SAMURAI
		CivData.CivType.SARACENS: return Unit.UnitType.MAMELUKE
		CivData.CivType.VIKINGS: return Unit.UnitType.BERSERKER
		CivData.CivType.CHINESE: return Unit.UnitType.CHUKONU
		_: return Unit.UnitType.SWORDSMAN

func _send_to_resource(v: Unit, type: String) -> void:
	if map_gen == null:
		return
	var dict = map_gen.trees if type == "wood" else (map_gen.gold_mines if type == "gold" else map_gen.berry_bushes)
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

func _build_structure(b_type: Building.BuildingType, villagers: Array) -> void:
	if map_gen == null or villagers.is_empty():
		return
		
	# Find a clear spot near enemy base (North)
	var start_cell = Vector2i(int(MapGenerator.MAP_WIDTH * 0.5), 10)
	var found_cell = _find_build_spot(start_cell, Vector2i(3, 3))
	if found_cell == Vector2i(-1, -1):
		return
		
	var free_worker = null
	for v in villagers:
		if v.state != Unit.State.BUILDING:
			free_worker = v
			break
			
	if free_worker != null:
		var b = main_game.place_building(b_type, 1, found_cell, true)
		if b != null:
			free_worker.command_build(b)

func _find_build_spot(center: Vector2i, size: Vector2i) -> Vector2i:
	for radius in range(3, 15):
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

func _has_building(b_type: Building.BuildingType) -> bool:
	for b in main_game.get_team_buildings(1):
		if b.building_type == b_type:
			return true
	return false

func _is_building_in_progress(b_type: Building.BuildingType) -> bool:
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
		
	# Find primary target (Player Town Center or nearest building)
	var target_target: Node2D = null
	for b in player_buildings:
		if b.building_type == Building.BuildingType.TOWN_CENTER:
			target_target = b
			break
	if target_target == null and not player_buildings.is_empty():
		target_target = player_buildings[0]
	elif target_target == null and not player_units.is_empty():
		target_target = player_units[0]
		
	if target_target == null:
		return
		
	# Command all military units to march and attack!
	for u in enemy_units:
		if u.unit_type != Unit.UnitType.VILLAGER:
			u.command_attack(target_target)
