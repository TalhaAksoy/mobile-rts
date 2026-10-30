class_name SaveManager
extends RefCounted

const SAVE_DIR = "user://saves/"
const AUTO_SAVE_FILE = "user://saves/quicksave.json"

static func save_game(game: GameController3D, file_path: String = AUTO_SAVE_FILE) -> bool:
	if game == null or not game.is_game_active:
		return false

	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

	var save_dict: Dictionary = {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"player_civ": game.player_civ,
		"enemy_civ": game.enemy_civ,
		"map_type": game.selected_map_type,
		"seed_val": game.map_gen.seed_val,
		"kills_count": game.kills_count,
		"trained_count": game.trained_count,
		"gathered_count": game.gathered_count,
		"camera_pos": [game.camera.global_position.x, game.camera.global_position.y, game.camera.global_position.z],
		"team_resources": {
			"0": game.team_resources[0],
			"1": game.team_resources[1]
		},
		"team_age": {
			"0": game.team_age.get(0, 1),
			"1": game.team_age.get(1, 1)
		},
		"team_techs": {
			"0": game.team_techs.get(0, {}),
			"1": game.team_techs.get(1, {})
		},
		"units": [],
		"buildings": []
	}

	for u in game.units:
		if is_instance_valid(u) and u.hp > 0:
			save_dict["units"].append({
				"team": u.team,
				"unit_type": u.unit_type,
				"hp": u.hp,
				"pos": [u.global_position.x, u.global_position.y, u.global_position.z],
				"resource_type": u.resource_type,
				"carried_resource": u.carried_resource
			})

	for b in game.buildings:
		if is_instance_valid(b) and b.hp > 0:
			save_dict["buildings"].append({
				"team": b.team,
				"building_type": b.building_type,
				"cell": [b.origin_cell.x, b.origin_cell.y],
				"hp": b.hp,
				"is_completed": b.is_completed,
				"construction_progress": b.construction_progress
			})

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(save_dict, "\t"))
	file.close()
	return true

static func has_saved_game(file_path: String = AUTO_SAVE_FILE) -> bool:
	return FileAccess.file_exists(file_path)

static func load_game(game: GameController3D, file_path: String = AUTO_SAVE_FILE) -> bool:
	if not FileAccess.file_exists(file_path):
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(content) != OK:
		return false
	var data = json.get_data() as Dictionary
	if data == null:
		return false

	# Clean existing match state
	for u in game.units:
		if is_instance_valid(u):
			u.queue_free()
	game.units.clear()
	for b in game.buildings:
		if is_instance_valid(b):
			b.queue_free()
	game.buildings.clear()
	game.selected_units.clear()
	game.selected_building = null

	# Restore Game setup
	game.player_civ = data.get("player_civ", CivData.CivType.OTTOMANS)
	game.enemy_civ = data.get("enemy_civ", CivData.CivType.BYZANTINES)
	game.selected_map_type = data.get("map_type", CivData.MapType.FOREST_VALLEY)
	var map_seed = data.get("seed_val", 1337)

	# Generate same map
	game.map_gen.generate(game.selected_map_type, map_seed)

	# Restore Meta & Resources
	game.kills_count = data.get("kills_count", 0)
	game.trained_count = data.get("trained_count", 0)
	game.gathered_count = data.get("gathered_count", 0)

	var res_dict = data.get("team_resources", {})
	if res_dict.has("0"): game.team_resources[0] = res_dict["0"]
	if res_dict.has("1"): game.team_resources[1] = res_dict["1"]

	var age_dict = data.get("team_age", {})
	if age_dict.has("0"): game.team_age[0] = int(age_dict["0"])
	if age_dict.has("1"): game.team_age[1] = int(age_dict["1"])

	var tech_dict = data.get("team_techs", {})
	if tech_dict.has("0"): game.team_techs[0] = tech_dict["0"]
	if tech_dict.has("1"): game.team_techs[1] = tech_dict["1"]

	# Restore Buildings
	for b_data in data.get("buildings", []):
		var b_type = int(b_data["building_type"])
		var b_team = int(b_data["team"])
		var cell_arr = b_data["cell"]
		var cell = Vector2i(int(cell_arr[0]), int(cell_arr[1]))
		var is_comp = bool(b_data.get("is_completed", true))
		var b = game.place_building(b_type, b_team, cell, not is_comp)
		if b != null:
			b.hp = float(b_data.get("hp", b.max_hp))
			b.is_completed = is_comp
			b.construction_progress = float(b_data.get("construction_progress", 100.0))

	# Restore Units
	for u_data in data.get("units", []):
		var u_type = int(u_data["unit_type"])
		var u_team = int(u_data["team"])
		var p_arr = u_data["pos"]
		var pos = Vector3(p_arr[0], p_arr[1], p_arr[2])
		var u = game.spawn_unit(u_type, u_team, pos)
		if u != null:
			u.hp = float(u_data.get("hp", u.max_hp))
			u.resource_type = u_data.get("resource_type", "")
			u.carried_resource = int(u_data.get("carried_resource", 0))

	# Camera pos
	var cam_arr = data.get("camera_pos", [])
	if cam_arr.size() == 3:
		game.camera.global_position = Vector3(cam_arr[0], cam_arr[1], cam_arr[2])

	# Setup AI
	game.enemy_ai.setup_ai(game.enemy_civ, game.map_gen, game)

	game.is_game_active = true
	game.ui_manager.menu_root.visible = false
	game.ui_manager.hud_root.visible = true
	game.ui_manager.game_over_modal.visible = false
	game.ui_manager.notify_banner("KAYITLI OYUN YÜKLENDİ!", Color(0.2, 0.95, 0.4))
	return true
