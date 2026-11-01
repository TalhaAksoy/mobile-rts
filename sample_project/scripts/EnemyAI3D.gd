class_name EnemyAI3D
extends Node

enum Difficulty { EASY, NORMAL, HARD }

## Picked before the match (Krallık seçimi > Zorluk). Before this existed every match ran one fixed
## setting: the first attack wave fired 40 s into the match with every soldier the bot had, so a
## passive new player lost the Town Center before minute 4 on Highland.
##   think          seconds between economy / build decisions
##   first_attack   no attack before this much game time (time to set up the economy)
##   wave_interval  seconds between waves (shrinks 3 s per wave, down to 70 %)
##   min_wave       a wave waits until the army has at least this many soldiers
##   wave_share     part of the army sent; the rest stays home to defend
##   max_vills / max_army   population the bot aims for
const DIFFICULTY_NAMES := ["Kolay", "Orta", "Zor"]
const DIFFICULTY_HINTS := [
	"Yeni başlayanlar için. İlk saldırı yaklaşık 8. dakikada, küçük ordularla.",
	"Dengeli. İlk saldırı yaklaşık 5. dakikada.",
	"Deneyimli oyuncular için. İlk saldırı 3. dakikada, büyük ve sık dalgalar.",
]
const PROFILES := {
	Difficulty.EASY: {"think": 4.0, "first_attack": 480.0, "wave_interval": 150.0, "min_wave": 4, "wave_share": 0.5, "max_vills": 10, "max_army": 8},
	Difficulty.NORMAL: {"think": 2.5, "first_attack": 300.0, "wave_interval": 90.0, "min_wave": 5, "wave_share": 0.6, "max_vills": 14, "max_army": 14},
	Difficulty.HARD: {"think": 1.5, "first_attack": 180.0, "wave_interval": 55.0, "min_wave": 5, "wave_share": 1.0, "max_vills": 20, "max_army": 40},
}
const WAVE_RETRY: float = 15.0   # army too small at wave time: look again this much later

@export var difficulty: Difficulty = Difficulty.NORMAL
var profile: Dictionary = PROFILES[Difficulty.NORMAL]
var civ_type: CivData.CivType = CivData.CivType.BYZANTINES
var map_gen: MapGenerator3D = null
var main_game: Node = null

var ai_timer: float = 0.0
var next_attack_at: float = 0.0
var wave_count: int = 0
## Game-time clock + construction-site watchdog: a site with no progress for SITE_STALL_TIMEOUT
## seconds is cancelled and refunded (it was unreachable / sealed off), so the bot can rebuild it
## elsewhere instead of _is_building_in_progress() blocking that building type forever.
const SITE_STALL_TIMEOUT: float = 60.0
var ai_clock: float = 0.0
var site_watch: Dictionary = {}

func setup_ai(civ: CivData.CivType, map: MapGenerator3D, game: Node, diff: Difficulty = Difficulty.NORMAL) -> void:
	civ_type = civ
	map_gen = map
	main_game = game
	difficulty = diff
	profile = PROFILES.get(diff, PROFILES[Difficulty.NORMAL])
	ai_clock = 0.0
	wave_count = 0
	site_watch.clear()
	ai_timer = 1.0
	next_attack_at = profile["first_attack"]

## Save / load: the match clock and wave count, so a loaded game does not get a fresh grace period
## (or lose its next wave).
func get_state() -> Dictionary:
	return {"clock": ai_clock, "waves": wave_count, "next_attack_at": next_attack_at}

func set_state(st: Dictionary) -> void:
	ai_clock = float(st.get("clock", ai_clock))
	wave_count = int(st.get("waves", wave_count))
	next_attack_at = float(st.get("next_attack_at", next_attack_at))

func _process(delta: float) -> void:
	if main_game == null or not main_game.is_game_active:
		return

	ai_clock += delta
	ai_timer -= delta
	if ai_timer <= 0.0:
		ai_timer = profile["think"]
		_cancel_stalled_sites()
		_think()

	if ai_clock >= next_attack_at:
		if _launch_attack_wave():
			wave_count += 1
			var iv: float = profile["wave_interval"]
			next_attack_at = ai_clock + maxf(iv * 0.7, iv - wave_count * 3.0)
		else:
			next_attack_at = ai_clock + WAVE_RETRY

func _cancel_stalled_sites() -> void:
	for site in site_watch.keys():
		if not is_instance_valid(site) or site.is_completed:
			site_watch.erase(site)
	for site in main_game.get_team_buildings(1):
		if not is_instance_valid(site) or site.is_completed or site.building_type == Building3D.BuildingType.TOWN_CENTER:
			continue
		if not site_watch.has(site):
			site_watch[site] = {"t": ai_clock, "p": site.construction_progress}
		elif site.construction_progress > site_watch[site]["p"]:
			site_watch[site] = {"t": ai_clock, "p": site.construction_progress}
		elif ai_clock - site_watch[site]["t"] > SITE_STALL_TIMEOUT:
			var cost = main_game._get_building_cost(site.building_type, 1)
			var res = main_game.get_team_resources(1)
			for k in ["wood", "gold", "stone"]:
				res[k] += cost.get(k, 0)
			site_watch.erase(site)
			site.die()

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

	var max_vills: int = profile["max_vills"]
	if tc != null and villagers.size() < max_vills and tc.train_queue.size() < 2:
		if resources["food"] >= 50:
			main_game.try_train_unit(tc, Unit3D.UnitType.VILLAGER, 1)

	# Age advancement
	if my_age == 1 and tc != null and not tc.has_queued_research():
		if resources["food"] >= 500 and resources["gold"] >= 200:
			main_game.try_start_research(tc, "AGE_2", 1)
	elif my_age == 2 and tc != null and not tc.has_queued_research() and ai_clock > 420.0:
		if resources["food"] >= 1000 and resources["gold"] >= 600:
			main_game.try_start_research(tc, "AGE_3", 1)

	# Dynamic Workforce Balancing
	_balance_workforce(villagers, resources, my_age)

	var pop = main_game.get_team_population(1)
	var max_pop = main_game.get_team_max_population(1)

	if (max_pop - pop) <= 2 and resources["wood"] >= 30 and not _is_building_in_progress(Building3D.BuildingType.HOUSE):
		if _build_structure(Building3D.BuildingType.HOUSE, villagers):
			return

	# Drop-off camps to shorten walk times
	if resources["wood"] >= 100 and not _has_building(Building3D.BuildingType.LUMBER_CAMP) and not _is_building_in_progress(Building3D.BuildingType.LUMBER_CAMP):
		if _build_structure(Building3D.BuildingType.LUMBER_CAMP, villagers):
			return

	if resources["wood"] >= 100 and not _has_building(Building3D.BuildingType.MINING_CAMP) and not _is_building_in_progress(Building3D.BuildingType.MINING_CAMP):
		if _build_structure(Building3D.BuildingType.MINING_CAMP, villagers):
			return

	if not _has_building(Building3D.BuildingType.BARRACKS) and resources["wood"] >= 150:
		if _build_structure(Building3D.BuildingType.BARRACKS, villagers):
			return

	# Farming: once the berries near home run low, a Mill (farm centre) and fields around it
	if _manage_farms(villagers, resources, tc):
		return

	if not _has_building(Building3D.BuildingType.ARCHERY_RANGE) and resources["wood"] >= 150:
		if _build_structure(Building3D.BuildingType.ARCHERY_RANGE, villagers):
			return

	if not _has_building(Building3D.BuildingType.STABLE) and resources["wood"] >= 175:
		if _build_structure(Building3D.BuildingType.STABLE, villagers):
			return

	if not _has_building(Building3D.BuildingType.BLACKSMITH) and resources["wood"] >= 150:
		if _build_structure(Building3D.BuildingType.BLACKSMITH, villagers):
			return

	if my_age >= 2 and not _has_building(Building3D.BuildingType.CASTLE) and resources["wood"] >= 200 and resources["stone"] >= 350 and resources["gold"] >= 150:
		if _build_structure(Building3D.BuildingType.CASTLE, villagers):
			return

	# Research: one new technology per think-tick, economy first, keeping a reserve for units
	_research_next(enemy_buildings, resources, my_age)

	# Military training (up to the difficulty's army size, counting soldiers already in training)
	var army_size := military.size()
	for b in enemy_buildings:
		if is_instance_valid(b) and b.building_type != Building3D.BuildingType.TOWN_CENTER:
			army_size += b.train_queue.size()
	if army_size >= int(profile["max_army"]):
		return
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

	# Unfinished construction sites without a builder (e.g. the builder died or gave up because it
	# could not reach the site): send the nearest idle villager, otherwise the site stays at 0%
	# forever and _is_building_in_progress() blocks that building type for the rest of the match.
	var busy_sites := {}
	for v in villagers:
		if is_instance_valid(v) and v.state == Unit3D.State.BUILDING and is_instance_valid(v.target_entity):
			busy_sites[v.target_entity] = true
	for site in main_game.get_team_buildings(1):
		if is_instance_valid(site) and not site.is_completed and not busy_sites.has(site):
			# Prefer an idle villager; otherwise borrow one from the largest gathering group.
			var pool: Array = idle_vills
			if pool.is_empty():
				var biggest := ""
				for r in active_by_res.keys():
					if biggest == "" or active_by_res[r].size() > active_by_res[biggest].size():
						biggest = r
				if biggest == "" or active_by_res[biggest].size() < 2:
					continue
				pool = active_by_res[biggest]
			var best: Unit3D = null
			var best_d := INF
			for v in pool:
				var d = v.global_position.distance_squared_to(site.global_position)
				if d < best_d:
					best_d = d
					best = v
			if best != null:
				pool.erase(best)
				best.command_build(site)
				busy_sites[site] = true

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
	if type == "food":
		# a free field of ours beats a long walk to far-away berries
		var field: Vector2i = map_gen.find_free_field(v.global_position, 1, v)
		if field != Vector2i(-1, -1):
			var near_berry := false
			for c in map_gen.berry_bushes.keys():
				if v.global_position.distance_to(map_gen.cell_to_world(c)) < 14.0:
					near_berry = true
					break
			if not near_berry:
				map_gen.claim_field(field, v)
				v.command_gather(field, "food")
				return
	var dict = map_gen.trees if type == "wood" else (map_gen.gold_mines if type == "gold" else (map_gen.stone_mines if type == "stone" else map_gen.berry_bushes))
	var my_cell = map_gen.world_to_cell(v.global_position)
	var best_cell = Vector2i(-1, -1)
	var best_dist = 999999.0

	for cell in dict.keys():
		if map_gen.is_resource_marked_unreachable(cell):
			continue
		var d = my_cell.distance_squared_to(cell)
		if d < best_dist:
			best_dist = d
			best_cell = cell

	if best_cell != Vector2i(-1, -1):
		v.command_gather(best_cell, type)

func _build_structure(b_type: Building3D.BuildingType, villagers: Array) -> bool:
	if map_gen == null or villagers.is_empty():
		return false

	var tc = null
	for b in main_game.get_team_buildings(1):
		if is_instance_valid(b) and b.building_type == Building3D.BuildingType.TOWN_CENTER:
			tc = b
			break

	var start_cell = map_gen.world_to_cell(tc.global_position) if tc != null else map_gen.world_to_cell(map_gen.enemy_start_pos)
	var b_size = main_game._get_building_size(b_type) if main_game != null else Vector2i(2, 2)

	var free_worker = null
	for v in villagers:
		if is_instance_valid(v) and v.hp > 0 and v.state != Unit3D.State.BUILDING:
			free_worker = v
			break
	if free_worker == null:
		return false

	# Search around the TC, but validate reachability from the WORKER's position: pathing from the
	# (blocked) TC centre escapes into whatever pocket the candidate is in, so sealed pockets passed.
	var found_cell := Vector2i(-1, -1)
	if b_type == Building3D.BuildingType.MILL:
		# leave a ring for fields: the 6x6 block around the 2x2 mill must be free
		found_cell = _find_build_spot(start_cell, b_size, map_gen.world_to_cell(free_worker.global_position), 2)
	if found_cell == Vector2i(-1, -1):
		found_cell = _find_build_spot(start_cell, b_size, map_gen.world_to_cell(free_worker.global_position))
	if found_cell == Vector2i(-1, -1):
		return false

	if free_worker != null:
		var cost = main_game._get_building_cost(b_type, 1) if main_game != null else {"wood": 0, "gold": 0, "stone": 0}
		var res = main_game.get_team_resources(1)
		if res["wood"] >= cost["wood"] and res["gold"] >= cost["gold"] and res["stone"] >= cost["stone"]:
			res["wood"] -= cost["wood"]
			res["gold"] -= cost["gold"]
			res["stone"] -= cost["stone"]
			var b = main_game.place_building(b_type, 1, found_cell, true)
			if b != null:
				free_worker.command_build(b)
				return true
	return false

func _find_build_spot(center: Vector2i, size: Vector2i, reach_from: Vector2i = Vector2i(-1, -1), margin: int = 0) -> Vector2i:
	var from_cell = reach_from if reach_from != Vector2i(-1, -1) else center
	for radius in range(3, 14):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var c = center + Vector2i(dx, dy)
				if margin > 0 and not _is_area_clear(c - Vector2i(margin, margin), size + Vector2i(margin * 2, margin * 2)):
					continue
				if _is_area_clear(c, size) and not _touches_building(c, size) and _is_site_reachable(from_cell, c, size) \
						and _keeps_ring_connected(c, size, from_cell):
					return c
	return Vector2i(-1, -1)

## A clear spot is useless if villagers cannot walk to it (e.g. a pocket sealed by trees):
## the site then sat at 0% forever and, via _is_building_in_progress, blocked that building type.
func _is_site_reachable(from_cell: Vector2i, site: Vector2i, size: Vector2i) -> bool:
	var target_cell = site + Vector2i(size.x / 2, size.y / 2)
	var path = map_gen.get_path_to_target(map_gen.cell_to_world(from_cell), map_gen.cell_to_world(target_cell))
	if path.is_empty():
		return false
	var end_cell = map_gen.world_to_cell(path[path.size() - 1])
	return end_cell.x >= site.x - 1 and end_cell.x <= site.x + size.x and end_cell.y >= site.y - 1 and end_cell.y <= site.y + size.y

## Keep a 1-cell lane between buildings. Packing them edge to edge around the TC (plus a tree line)
## sealed the TC off: villagers could no longer reach the drop-off and the bot economy froze
## (seen in a 600 s simulation: 14 of 15 villagers stuck in RETURNING_RESOURCES).
func _touches_building(c: Vector2i, size: Vector2i) -> bool:
	for x in range(c.x - 1, c.x + size.x + 1):
		for y in range(c.y - 1, c.y + size.y + 1):
			if map_gen.occupied_cells.has(Vector2i(x, y)):
				return true
	return false

## A 1-cell lane is not enough when trees or mines close its ends: a 600 s simulation showed 12 of
## 15 villagers sealed in a pocket between a house, the barracks, a tree and a mine. So: pretend the
## site is built and require every walkable cell around it to still reach the worker's area.
func _keeps_ring_connected(site: Vector2i, size: Vector2i, hub: Vector2i) -> bool:
	var ids: Array = []
	for x in range(site.x, site.x + size.x):
		for y in range(site.y, site.y + size.y):
			var id: int = map_gen._cell_to_id(x, y)
			if not map_gen.astar.is_point_disabled(id):
				map_gen.astar.set_point_disabled(id, true)
				ids.append(id)
	var ok := true
	for x in range(site.x - 1, site.x + size.x + 1):
		for y in range(site.y - 1, site.y + size.y + 1):
			if x >= site.x and x < site.x + size.x and y >= site.y and y < site.y + size.y:
				continue
			var c := Vector2i(x, y)
			if not map_gen.is_valid_cell(x, y) or not map_gen.is_cell_walkable(c):
				continue
			var path = map_gen.get_path_to_target(map_gen.cell_to_world(c), map_gen.cell_to_world(hub))
			if path.is_empty() or Vector2(map_gen.world_to_cell(path[path.size() - 1])).distance_to(Vector2(hub)) > 1.5:
				ok = false
				break
		if not ok:
			break
	for id in ids:
		map_gen.astar.set_point_disabled(id, false)
	return ok

func _is_area_clear(c: Vector2i, size: Vector2i) -> bool:
	if map_gen == null:
		return false
	for x in range(c.x, c.x + size.x):
		for y in range(c.y, c.y + size.y):
			if not map_gen.is_valid_cell(x, y) or not map_gen.is_cell_buildable(Vector2i(x, y)):
				return false
	return map_gen.is_area_level(c, size)

## Builds a Mill when wild food near the TC is running out, then keeps adding fields (one villager
## each) while there is wood. Returns true when it spent this think-tick on farming.
func _manage_farms(villagers: Array, resources: Dictionary, tc) -> bool:
	if tc == null or villagers.is_empty():
		return false
	var tc_cell: Vector2i = map_gen.world_to_cell(tc.global_position)
	var wild_food := 0
	for c in map_gen.berry_bushes.keys():
		if Vector2(c).distance_to(Vector2(tc_cell)) <= 14.0:
			wild_food += int(map_gen.berry_bushes[c].get("food", 0))
	var mill = null
	for b in main_game.get_team_buildings(1):
		if is_instance_valid(b) and b.building_type == Building3D.BuildingType.MILL:
			mill = b
			break
	if mill == null:
		if (wild_food < 700 or ai_clock > 240.0) and resources["wood"] >= 100:
			# only "spend the tick" when a mill was really placed: with no free spot the bot must
			# keep training/researching instead of retrying the mill forever
			return _build_structure(Building3D.BuildingType.MILL, villagers)
		return false
	if not mill.is_completed:
		return false
	var fields: int = main_game.get_mill_fields(mill).size()
	var want: int = clampi(int(villagers.size() * 0.45) - (1 if wild_food > 500 else 0), 1, main_game.MAX_FIELDS_PER_MILL)
	if fields < want and resources["wood"] >= 50 + (30 if fields > 0 else 0) and main_game.field_block_reason(mill, 1) == "":
		var builder = null
		var best_d := INF
		for v in villagers:
			if is_instance_valid(v) and v.hp > 0 and v.state != Unit3D.State.BUILDING:
				var d: float = v.global_position.distance_squared_to(mill.global_position)
				if v.resource_type == "food":
					d *= 0.5   # prefer someone already on food
				if d < best_d:
					best_d = d
					builder = v
		if builder != null:
			main_game.try_add_field(mill, 1, [builder])
			return true
	return false

const _RESEARCH_PRIORITY := [Building3D.BuildingType.MILL, Building3D.BuildingType.LUMBER_CAMP,
	Building3D.BuildingType.MINING_CAMP, Building3D.BuildingType.BLACKSMITH, Building3D.BuildingType.HOUSE,
	Building3D.BuildingType.BARRACKS, Building3D.BuildingType.ARCHERY_RANGE, Building3D.BuildingType.STABLE,
	Building3D.BuildingType.TOWER, Building3D.BuildingType.TOWN_CENTER, Building3D.BuildingType.CASTLE]

func _research_next(enemy_buildings: Array, resources: Dictionary, _my_age: int) -> void:
	for b_type in _RESEARCH_PRIORITY:
		for b in enemy_buildings:
			if not is_instance_valid(b) or b.building_type != b_type or not b.is_completed or b.has_queued_research():
				continue
			for id in TechData.techs_for_building(b_type):
				if id.begins_with("AGE_") or main_game.research_block_reason(b, id, 1) != "":
					continue
				# keep enough food/gold behind for villagers and the next age
				# reserve only applies to what the tech actually spends (a wood/food tech must not be
				# blocked just because gold is low)
				var cost: Dictionary = TechData.get_tech(id)["cost"]
				if int(cost.get("food", 0)) > 0 and resources["food"] - int(cost["food"]) < 100:
					continue
				if int(cost.get("gold", 0)) > 0 and resources["gold"] - int(cost["gold"]) < 50:
					continue
				if main_game.try_start_research(b, id, 1):
					return

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

## Sends part of the army (wave_share) at the player's Town Center, once the army is big enough
## (min_wave). Returns false when no wave went out.
func _launch_attack_wave() -> bool:
	var enemy_units = main_game.get_team_units(1)
	var player_buildings = main_game.get_team_buildings(0)
	var player_units = main_game.get_team_units(0)

	if player_buildings.is_empty() and player_units.is_empty():
		return false

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
		return false

	var army: Array = []
	for u in enemy_units:
		if is_instance_valid(u) and u.hp > 0 and u.unit_type != Unit3D.UnitType.VILLAGER:
			army.append(u)
	if army.size() < int(profile["min_wave"]):
		return false
	# the soldiers nearest the target go; the rest stay home
	army.sort_custom(func(a, b): return a.global_position.distance_squared_to(target.global_position) < b.global_position.distance_squared_to(target.global_position))
	var n := clampi(int(ceil(army.size() * float(profile["wave_share"]))), 1, army.size())
	for i in n:
		army[i].command_attack(target)
	return true
