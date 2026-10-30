class_name GameController3D
extends Node3D

const SaveManager = preload("res://scripts/SaveManager.gd")
const TutorialManager = preload("res://scripts/TutorialManager.gd")

@export var player_civ: CivData.CivType = CivData.CivType.OTTOMANS
@export var enemy_civ: CivData.CivType = CivData.CivType.BYZANTINES
@export var selected_map_type: CivData.MapType = CivData.MapType.FOREST_VALLEY
@export var auto_start_for_testing: bool = false

@onready var map_gen: MapGenerator3D = $MapGenerator3D
@onready var camera: MobileCamera3D = $MobileCamera3D
@onready var ui_manager: UIManager3D = $UIManager3D
@onready var enemy_ai: EnemyAI3D = $EnemyAI3D

var team_resources: Dictionary = {
	0: {"food": 200, "wood": 200, "gold": 100, "stone": 100},
	1: {"food": 200, "wood": 200, "gold": 100, "stone": 100}
}

var team_age: Dictionary = {0: 1, 1: 1}
var team_techs: Dictionary = {
	0: {"iron_weapons": false, "scale_armor": false, "bodkin_arrows": false, "wheelbarrow": false},
	1: {"iron_weapons": false, "scale_armor": false, "bodkin_arrows": false, "wheelbarrow": false}
}

var units: Array[Unit3D] = []
var buildings: Array[Building3D] = []

var selected_units: Array[Unit3D] = []
var selected_building: Building3D = null

var is_game_active: bool = false
var game_start_time: float = 0.0
var kills_count: int = 0
var trained_count: int = 0
var gathered_count: int = 0

# Building placement
var is_placing_building: bool = false
var placing_building_type: Building3D.BuildingType = Building3D.BuildingType.HOUSE
var ghost_preview: MeshInstance3D = null
var fog_timer: float = 0.0

var drag_start_pos: Vector2 = Vector2.ZERO
var is_drag_box_selecting: bool = false
var last_clicked_unit: Unit3D = null
var last_click_time_msec: int = 0
var tutorial_mgr: TutorialManager = null

func _ready() -> void:
	if SoundManager.instance == null:
		var sm = SoundManager.new()
		add_child(sm)

	tutorial_mgr = TutorialManager.new()
	add_child(tutorial_mgr)

	ui_manager.game_controller = self
	ui_manager.start_game_requested.connect(_on_start_game_requested)
	ui_manager.build_selected.connect(_on_build_selected)
	ui_manager.train_unit_requested.connect(_on_train_unit_requested)
	ui_manager.research_requested.connect(_on_research_requested)
	ui_manager.select_all_military_requested.connect(_on_select_all_military)
	ui_manager.jump_to_base_requested.connect(_on_jump_to_base)
	ui_manager.find_idle_villager_requested.connect(_on_find_idle_villager)
	ui_manager.clear_selection_requested.connect(_on_clear_selection_requested)
	ui_manager.toggle_speed_requested.connect(_on_toggle_speed)
	ui_manager.restart_requested.connect(_on_restart_requested)
	ui_manager.zoom_in_requested.connect(func(): camera.zoom_in())
	ui_manager.zoom_out_requested.connect(func(): camera.zoom_out())

	# Ghost Preview 3D
	ghost_preview = MeshInstance3D.new()
	var g_mesh = BoxMesh.new()
	ghost_preview.mesh = g_mesh
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.2, 0.95, 0.3, 0.45)
	g_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g_mat.emission_enabled = true
	g_mat.emission = Color(0.2, 0.95, 0.3)
	ghost_preview.material_override = g_mat
	ghost_preview.visible = false
	add_child(ghost_preview)

	var minimap = ui_manager.get_node_or_null("HUDRoot/Minimap") as Minimap3D
	if minimap != null:
		minimap.map_gen = map_gen
		minimap.camera = camera
		minimap.game_controller = self

	if auto_start_for_testing:
		get_tree().create_timer(0.2).timeout.connect(func():
			_on_start_game_requested(player_civ, enemy_civ, selected_map_type)
		)

func _on_start_game_requested(p_civ: CivData.CivType, e_civ: CivData.CivType, m_type: CivData.MapType) -> void:
	player_civ = p_civ
	enemy_civ = e_civ
	selected_map_type = m_type
	start_match()

func start_match() -> void:
	for u in units:
		if is_instance_valid(u):
			u.queue_free()
	units.clear()
	for b in buildings:
		if is_instance_valid(b):
			b.queue_free()
	buildings.clear()
	selected_units.clear()
	selected_building = null

	team_resources = {
		0: {"food": 200, "wood": 200, "gold": 100, "stone": 100},
		1: {"food": 200, "wood": 200, "gold": 100, "stone": 100}
	}
	team_age = {0: 1, 1: 1}
	team_techs = {
		0: {"iron_weapons": false, "scale_armor": false, "bodkin_arrows": false, "wheelbarrow": false},
		1: {"iron_weapons": false, "scale_armor": false, "bodkin_arrows": false, "wheelbarrow": false}
	}
	kills_count = 0
	trained_count = 0
	gathered_count = 0
	game_start_time = Time.get_ticks_msec() / 1000.0

	# 1. Generate 3D Map
	map_gen.generate(selected_map_type)
	camera.setup_bounds(MapGenerator3D.MAP_WIDTH * MapGenerator3D.TILE_SIZE, MapGenerator3D.MAP_HEIGHT * MapGenerator3D.TILE_SIZE)

	# 2. Player Base (South)
	var player_base_cell = map_gen.world_to_cell(map_gen.player_start_pos)
	var _player_tc = place_building(Building3D.BuildingType.TOWN_CENTER, 0, player_base_cell - Vector2i(1, 1), false)

	var p_civ_cfg = CivData.get_civ(player_civ)
	var start_vills = 3 + p_civ_cfg.get("start_villager_bonus", 0)
	for i in range(start_vills):
		var offset = Vector3(cos(i * 1.5) * 3.5, 0, sin(i * 1.5) * 3.5 + 2.5)
		spawn_unit(Unit3D.UnitType.VILLAGER, 0, map_gen.player_start_pos + offset)

	# 3. Enemy Base (North)
	var enemy_base_cell = map_gen.world_to_cell(map_gen.enemy_start_pos)
	var _enemy_tc = place_building(Building3D.BuildingType.TOWN_CENTER, 1, enemy_base_cell - Vector2i(1, 1), false)

	for i in range(3):
		var offset = Vector3(cos(i * 1.5) * 3.5, 0, sin(i * 1.5) * 3.5 - 2.5)
		spawn_unit(Unit3D.UnitType.VILLAGER, 1, map_gen.enemy_start_pos + offset)

	enemy_ai.setup_ai(enemy_civ, map_gen, self)

	# Jump camera to player base
	camera.jump_to(map_gen.player_start_pos, false)

	is_game_active = true
	ui_manager.menu_root.visible = false
	ui_manager.hud_root.visible = true
	ui_manager.game_over_modal.visible = false

	ui_manager.set_player_civ(player_civ)
	_update_hud()

	if tutorial_mgr != null:
		tutorial_mgr.start_tutorial(self)

func _process(delta: float) -> void:
	if not is_game_active:
		return

	_update_hud()

	if tutorial_mgr != null:
		tutorial_mgr.check_progress()

	fog_timer -= delta
	if fog_timer <= 0.0:
		fog_timer = 0.2
		map_gen.update_fog_of_war(get_team_units(0), get_team_buildings(0), get_team_units(1), get_team_buildings(1))

	if is_placing_building:
		var mouse_pos = get_viewport().get_mouse_position()
		var hit_ground = camera.raycast_ground(mouse_pos)
		var cell = map_gen.world_to_cell(hit_ground)
		var size = _get_building_size(placing_building_type)
		var snapped_pos = Vector3((cell.x + size.x * 0.5) * MapGenerator3D.TILE_SIZE, 0.5, (cell.y + size.y * 0.5) * MapGenerator3D.TILE_SIZE)
		ghost_preview.global_position = snapped_pos

func _update_hud() -> void:
	var res = team_resources[0]
	var pop = get_team_population(0)
	var max_pop = get_team_max_population(0)
	ui_manager.update_resources(res["food"], res["wood"], res["gold"], res.get("stone", 0), pop, max_pop)

	var idle_vills = 0
	for u in units:
		if is_instance_valid(u) and u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER and u.state == Unit3D.State.IDLE:
			idle_vills += 1
	ui_manager.update_idle_villager_count(idle_vills)

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			if SaveManager.save_game(self):
				ui_manager.notify_banner("OYUN KAYDEDİLDİ (F5)", Color(0.2, 0.95, 0.4))
			return
		elif event.keycode == KEY_F9:
			if SaveManager.has_saved_game():
				SaveManager.load_game(self)
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_start_pos = event.position
			is_drag_box_selecting = false
		else:
			if is_drag_box_selecting:
				is_drag_box_selecting = false
				ui_manager.hide_drag_box()
				var min_x = min(drag_start_pos.x, event.position.x)
				var max_x = max(drag_start_pos.x, event.position.x)
				var min_y = min(drag_start_pos.y, event.position.y)
				var max_y = max(drag_start_pos.y, event.position.y)
				var box_rect = Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
				_select_units_in_screen_rect(box_rect)
				return
			else:
				var mouse_pos = event.position
				var hit_ground = camera.raycast_ground(mouse_pos)
				if is_placing_building:
					_attempt_place_building(hit_ground)
					return
				_handle_3d_click(mouse_pos, hit_ground)

	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if not is_placing_building:
			if not is_drag_box_selecting and (event.position - drag_start_pos).length() > 22.0:
				is_drag_box_selecting = true
			if is_drag_box_selecting:
				ui_manager.draw_drag_box(drag_start_pos, event.position)

func _handle_3d_click(screen_pos: Vector2, ground_pos: Vector3) -> void:
	var clicked_entity = _get_entity_at_position(screen_pos, ground_pos)
	var cell = map_gen.world_to_cell(ground_pos)

	var now = Time.get_ticks_msec()
	if clicked_entity is Unit3D and clicked_entity.team == 0:
		if last_clicked_unit == clicked_entity and (now - last_click_time_msec) < 380:
			_select_all_matching_units_on_screen(clicked_entity.unit_type)
			last_clicked_unit = null
			last_click_time_msec = 0
			return
		else:
			last_clicked_unit = clicked_entity
			last_click_time_msec = now

	if selected_units.size() > 0:
		# 1. Click on ally unit -> toggle off if same single unit, or switch selection
		if clicked_entity is Unit3D and clicked_entity.team == 0:
			if clicked_entity in selected_units and selected_units.size() == 1:
				# Tapping the already selected single unit -> DESELECT!
				_clear_selection()
				ui_manager.set_selected_entity(null)
				SoundManager.play_sound("click")
				return
			else:
				# Switch selection immediately to clicked unit
				_clear_selection()
				selected_units.append(clicked_entity)
				clicked_entity.set_selected(true)
				ui_manager.set_selected_entity(clicked_entity)
				SoundManager.play_sound("click")
				return

		# 2. Click on ally building -> SELECT THAT BUILDING! (Town Center, Barracks, etc.)
		if clicked_entity is Building3D and clicked_entity.team == 0:
			if not clicked_entity.is_completed:
				var has_vill = false
				for u in selected_units:
					if u.unit_type == Unit3D.UnitType.VILLAGER:
						has_vill = true
						u.command_build(clicked_entity)
				if has_vill:
					_spawn_click_marker(clicked_entity.global_position, "build")
					SoundManager.play_sound("build")
					return
			# Switch selection to ally building so user can train units or upgrade
			_clear_selection()
			selected_building = clicked_entity
			clicked_entity.set_selected(true)
			ui_manager.set_selected_entity(clicked_entity)
			SoundManager.play_sound("click")
			return

		# 3. Attack enemy entity
		if clicked_entity != null and clicked_entity.team != 0:
			_spawn_click_marker(clicked_entity.global_position, "attack")
			for u in selected_units:
				u.command_attack(clicked_entity)
			SoundManager.play_sound("attack")
			return

		# 4. Villager resource gathering
		var has_villager = false
		for u in selected_units:
			if u.unit_type == Unit3D.UnitType.VILLAGER:
				has_villager = true
				break

		if has_villager:
			var res_info = _find_resource_at_click(screen_pos, ground_pos)
			if res_info.has("type") and res_info.has("cell"):
				var r_cell = res_info["cell"] as Vector2i
				var r_type = res_info["type"] as String
				_spawn_click_marker(map_gen.cell_to_world(r_cell), "gather")
				for u in selected_units:
					if u.unit_type == Unit3D.UnitType.VILLAGER:
						u.command_gather(r_cell, r_type)
				SoundManager.play_sound("click")
				return

		# 5. Ground move command
		if clicked_entity == null:
			_spawn_click_marker(ground_pos, "move")
			for i in range(selected_units.size()):
				var u = selected_units[i]
				var offset = Vector3.ZERO
				if selected_units.size() > 1:
					var angle = i * (TAU / selected_units.size())
					offset = Vector3(cos(angle), 0, sin(angle)) * 1.5
				u.command_move(ground_pos + offset)
			SoundManager.play_sound("click")
			return

	elif selected_building != null:
		# If tapping the already selected building again -> DESELECT!
		if clicked_entity == selected_building:
			_clear_selection()
			ui_manager.set_selected_entity(null)
			SoundManager.play_sound("click")
			return
		# If clicking an ally unit or another building -> SELECT IT!
		elif clicked_entity is Unit3D and clicked_entity.team == 0:
			_clear_selection()
			selected_units.append(clicked_entity)
			clicked_entity.set_selected(true)
			ui_manager.set_selected_entity(clicked_entity)
			SoundManager.play_sound("click")
			return
		elif clicked_entity is Building3D and clicked_entity.team == 0:
			_clear_selection()
			selected_building = clicked_entity
			clicked_entity.set_selected(true)
			ui_manager.set_selected_entity(clicked_entity)
			SoundManager.play_sound("click")
			return
		# If clicking ground: set building rally point
		elif clicked_entity == null and ground_pos != Vector3.ZERO:
			selected_building.rally_point = ground_pos
			_spawn_click_marker(ground_pos, "move")
			SoundManager.play_sound("click")
			return

	# Selection
	_clear_selection()

	if clicked_entity is Unit3D:
		selected_units.append(clicked_entity)
		clicked_entity.set_selected(true)
		ui_manager.set_selected_entity(clicked_entity)
		SoundManager.play_sound("click")
	elif clicked_entity is Building3D:
		selected_building = clicked_entity
		clicked_entity.set_selected(true)
		ui_manager.set_selected_entity(clicked_entity)
		SoundManager.play_sound("click")
	else:
		ui_manager.set_selected_entity(null)

func _clear_selection() -> void:
	for u in selected_units:
		if is_instance_valid(u):
			u.set_selected(false)
	selected_units.clear()

	if is_instance_valid(selected_building):
		selected_building.set_selected(false)
	selected_building = null

const ClickMarkerScript = preload("res://scripts/ClickMarker3D.gd")

func _spawn_click_marker(pos: Vector3, type: String) -> void:
	var marker = ClickMarkerScript.new()
	add_child(marker)
	marker.setup(pos, type)

func _find_unit_near_screen(screen_pos: Vector2, max_screen_dist: float = 56.0) -> Unit3D:
	var best_unit: Unit3D = null
	var best_dist: float = max_screen_dist
	for u in units:
		if not is_instance_valid(u) or u.hp <= 0:
			continue
		var u_screen = camera.unproject_position(u.global_position + Vector3(0, 1.76, 0))
		var d = screen_pos.distance_to(u_screen)
		if d < best_dist:
			best_dist = d
			best_unit = u
	return best_unit

func _find_resource_at_click(screen_pos: Vector2, ground_pos: Vector3) -> Dictionary:
	# 1. Screen-space billboard click on Trees (generous 44px radius)
	var best_tree = Vector2i(-1, -1)
	var best_tree_dist = 44.0
	for cell in map_gen.trees.keys():
		var w_pos = map_gen.cell_to_world(cell) + Vector3(0, 1.7, 0)
		var s_pos = camera.unproject_position(w_pos)
		var d = screen_pos.distance_to(s_pos)
		if d < best_tree_dist:
			best_tree_dist = d
			best_tree = cell

	if best_tree != Vector2i(-1, -1):
		return {"type": "wood", "cell": best_tree}

	# 2. Screen-space billboard click on Gold
	var best_gold = Vector2i(-1, -1)
	var best_gold_dist = 44.0
	for cell in map_gen.gold_mines.keys():
		var w_pos = map_gen.cell_to_world(cell) + Vector3(0, 0.95, 0)
		var s_pos = camera.unproject_position(w_pos)
		var d = screen_pos.distance_to(s_pos)
		if d < best_gold_dist:
			best_gold_dist = d
			best_gold = cell

	if best_gold != Vector2i(-1, -1):
		return {"type": "gold", "cell": best_gold}

	# 3. Screen-space billboard click on Stone
	var best_stone = Vector2i(-1, -1)
	var best_stone_dist = 44.0
	for cell in map_gen.stone_mines.keys():
		var w_pos = map_gen.cell_to_world(cell) + Vector3(0, 0.95, 0)
		var s_pos = camera.unproject_position(w_pos)
		var d = screen_pos.distance_to(s_pos)
		if d < best_stone_dist:
			best_stone_dist = d
			best_stone = cell

	if best_stone != Vector2i(-1, -1):
		return {"type": "stone", "cell": best_stone}

	# 4. Screen-space billboard click on Berry Bushes
	var best_berry = Vector2i(-1, -1)
	var best_berry_dist = 44.0
	for cell in map_gen.berry_bushes.keys():
		var w_pos = map_gen.cell_to_world(cell) + Vector3(0, 0.95, 0)
		var s_pos = camera.unproject_position(w_pos)
		var d = screen_pos.distance_to(s_pos)
		if d < best_berry_dist:
			best_berry_dist = d
			best_berry = cell

	if best_berry != Vector2i(-1, -1):
		return {"type": "food", "cell": best_berry}

	# 5. Ground cell fallback
	var cell = map_gen.world_to_cell(ground_pos)
	if cell in map_gen.trees:
		return {"type": "wood", "cell": cell}
	if cell in map_gen.gold_mines:
		return {"type": "gold", "cell": cell}
	if cell in map_gen.stone_mines:
		return {"type": "stone", "cell": cell}
	if cell in map_gen.berry_bushes:
		return {"type": "food", "cell": cell}

	# 6. Adjacent ground proximity fallback
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var nc = cell + Vector2i(dx, dy)
			if nc in map_gen.trees and ground_pos.distance_to(map_gen.cell_to_world(nc)) < 1.7:
				return {"type": "wood", "cell": nc}
			if nc in map_gen.gold_mines and ground_pos.distance_to(map_gen.cell_to_world(nc)) < 1.7:
				return {"type": "gold", "cell": nc}
			if nc in map_gen.stone_mines and ground_pos.distance_to(map_gen.cell_to_world(nc)) < 1.7:
				return {"type": "stone", "cell": nc}
			if nc in map_gen.berry_bushes and ground_pos.distance_to(map_gen.cell_to_world(nc)) < 1.7:
				return {"type": "food", "cell": nc}

	return {}

func _get_entity_at_position(screen_pos: Vector2, ground_pos: Vector3) -> Node3D:
	# 1. Units ALWAYS have absolute priority over buildings!
	var unit_by_screen = _find_unit_near_screen(screen_pos, 46.0)
	if unit_by_screen != null:
		return unit_by_screen

	for u in units:
		if is_instance_valid(u) and u.hp > 0:
			if u.global_position.distance_to(ground_pos) < 1.6:
				return u

	# 2. Check buildings in screen-space (handles 3D roofs, towers, and facades)
	for b in buildings:
		if is_instance_valid(b) and b.hp > 0:
			var b_center = b.global_position + Vector3(0, 1.8, 0)
			var s_center = camera.unproject_position(b_center)
			var half_w = (b.grid_size.x * MapGenerator3D.TILE_SIZE * 0.5)
			var half_l = (b.grid_size.y * MapGenerator3D.TILE_SIZE * 0.5)
			var s_right = camera.unproject_position(b_center + Vector3(half_w, 0, 0))
			var s_top = camera.unproject_position(b_center + Vector3(0, 2.2, -half_l))
			var rx = max(42.0, abs(s_right.x - s_center.x) + 14.0)
			var ry = max(42.0, abs(s_top.y - s_center.y) + 16.0)
			if abs(screen_pos.x - s_center.x) <= rx and abs(screen_pos.y - s_center.y) <= ry:
				return b

	# 3. Ground footprint proximity fallback
	for b in buildings:
		if is_instance_valid(b) and b.hp > 0:
			var w = b.grid_size.x * MapGenerator3D.TILE_SIZE * 0.5 + 0.8
			var l = b.grid_size.y * MapGenerator3D.TILE_SIZE * 0.5 + 0.8
			var bp = b.global_position
			if abs(ground_pos.x - bp.x) <= w and abs(ground_pos.z - bp.z) <= l:
				return b
	return null

func _select_all_matching_units_on_screen(u_type: Unit3D.UnitType) -> void:
	_clear_selection()
	var vp_rect = get_viewport().get_visible_rect()
	for u in units:
		if is_instance_valid(u) and u.team == 0 and u.unit_type == u_type and u.hp > 0:
			var s_pos = camera.unproject_position(u.global_position)
			if vp_rect.has_point(s_pos):
				selected_units.append(u)
				u.set_selected(true)
	if selected_units.size() > 0:
		ui_manager.set_selected_entity(selected_units[0])
		SoundManager.play_sound("click")

func _select_units_in_screen_rect(rect: Rect2) -> void:
	var found = []
	for u in units:
		if is_instance_valid(u) and u.team == 0 and u.hp > 0:
			var s_pos = camera.unproject_position(u.global_position)
			if rect.has_point(s_pos):
				found.append(u)

	if found.size() > 0:
		_clear_selection()
		for u in found:
			selected_units.append(u)
			u.set_selected(true)
		ui_manager.set_selected_entity(found[0])
		SoundManager.play_sound("click")

func spawn_unit(u_type: Unit3D.UnitType, team: int, pos: Vector3) -> Unit3D:
	var civ = player_civ if team == 0 else enemy_civ
	var unit = Unit3D.new()
	add_child(unit)
	unit.global_position = pos
	unit.setup_unit(u_type, team, civ, map_gen, self)
	unit.died.connect(_on_unit_died)
	units.append(unit)
	if team == 0:
		trained_count += 1

	# Apply active researched techs
	if team_techs.has(team):
		var techs = team_techs[team]
		if techs.get("iron_weapons", false) and unit.is_infantry():
			unit.attack_dmg += 3.0
		if techs.get("scale_armor", false):
			unit.armor += 2.0
		if techs.get("bodkin_arrows", false) and unit.is_ranged():
			unit.attack_dmg += 3.0
		if techs.get("wheelbarrow", false) and unit.unit_type == Unit3D.UnitType.VILLAGER:
			unit.max_carry = 20
			unit.move_speed *= 1.15
	return unit

func place_building(b_type: Building3D.BuildingType, team: int, cell: Vector2i, under_construction: bool = false) -> Building3D:
	var civ = player_civ if team == 0 else enemy_civ
	var b = Building3D.new()
	var b_size = _get_building_size(b_type)
	var world_center = Vector3((cell.x + b_size.x * 0.5) * MapGenerator3D.TILE_SIZE, 0.0, (cell.y + b_size.y * 0.5) * MapGenerator3D.TILE_SIZE)

	add_child(b)
	b.global_position = world_center
	b.setup_building(b_type, team, civ, cell, map_gen, self, under_construction)
	b.destroyed.connect(_on_building_destroyed)
	b.unit_trained.connect(_on_building_unit_trained)
	b.research_completed.connect(_on_building_research_completed)

	map_gen.register_building_cells(cell, b_size, b)
	buildings.append(b)
	return b

func _get_building_size(b_type: Building3D.BuildingType) -> Vector2i:
	match b_type:
		Building3D.BuildingType.TOWN_CENTER: return Vector2i(3, 3)
		Building3D.BuildingType.HOUSE: return Vector2i(2, 2)
		Building3D.BuildingType.BARRACKS: return Vector2i(3, 3)
		Building3D.BuildingType.ARCHERY_RANGE: return Vector2i(3, 3)
		Building3D.BuildingType.STABLE: return Vector2i(3, 3)
		Building3D.BuildingType.CASTLE: return Vector2i(4, 4)
		Building3D.BuildingType.TOWER: return Vector2i(2, 2)
		Building3D.BuildingType.FARM: return Vector2i(2, 2)
		Building3D.BuildingType.BLACKSMITH: return Vector2i(2, 2)
		_: return Vector2i(2, 2)

func _get_building_cost(b_type: Building3D.BuildingType) -> Dictionary:
	var civ_cfg = CivData.get_civ(player_civ)
	var cost_mult = civ_cfg.get("building_cost_mult", 1.0)

	var cost = {"wood": 0, "gold": 0, "stone": 0}
	match b_type:
		Building3D.BuildingType.TOWN_CENTER: cost = {"wood": 275, "gold": 0, "stone": 100}
		Building3D.BuildingType.HOUSE: cost = {"wood": 30, "gold": 0, "stone": 0}
		Building3D.BuildingType.BARRACKS: cost = {"wood": 150, "gold": 0, "stone": 0}
		Building3D.BuildingType.ARCHERY_RANGE: cost = {"wood": 150, "gold": 0, "stone": 0}
		Building3D.BuildingType.STABLE: cost = {"wood": 175, "gold": 0, "stone": 0}
		Building3D.BuildingType.CASTLE: cost = {"wood": 200, "gold": 150, "stone": 350}
		Building3D.BuildingType.TOWER: cost = {"wood": 75, "gold": 0, "stone": 125}
		Building3D.BuildingType.FARM: cost = {"wood": 60, "gold": 0, "stone": 0}
		Building3D.BuildingType.BLACKSMITH: cost = {"wood": 150, "gold": 0, "stone": 25}

	cost["wood"] = int(cost["wood"] * cost_mult)
	cost["stone"] = int(cost["stone"] * cost_mult)
	return cost

func _on_build_selected(b_type: Building3D.BuildingType) -> void:
	if b_type == Building3D.BuildingType.CASTLE and team_age.get(0, 1) < 2:
		ui_manager.notify_banner("KALE İÇİN HİSAR ÇAĞI GEREKLİDİR!", Color(1.0, 0.35, 0.35))
		SoundManager.play_sound("hit")
		return

	var cost = _get_building_cost(b_type)
	if team_resources[0]["wood"] < cost["wood"] or team_resources[0]["gold"] < cost["gold"] or team_resources[0]["stone"] < cost["stone"]:
		SoundManager.play_sound("hit")
		return

	is_placing_building = true
	placing_building_type = b_type
	var size = _get_building_size(b_type)
	(ghost_preview.mesh as BoxMesh).size = Vector3(size.x * MapGenerator3D.TILE_SIZE, 1.5, size.y * MapGenerator3D.TILE_SIZE)
	ghost_preview.visible = true

func _attempt_place_building(ground_pos: Vector3) -> void:
	var cell = map_gen.world_to_cell(ground_pos)
	var size = _get_building_size(placing_building_type)

	var clear = true
	for x in range(cell.x, cell.x + size.x):
		for y in range(cell.y, cell.y + size.y):
			if not map_gen.is_valid_cell(x, y) or not map_gen.is_cell_walkable(Vector2i(x, y)):
				clear = false
				break

	if not clear:
		SoundManager.play_sound("hit")
		return

	var cost = _get_building_cost(placing_building_type)
	team_resources[0]["wood"] -= cost["wood"]
	team_resources[0]["gold"] -= cost["gold"]
	team_resources[0]["stone"] -= cost["stone"]

	var new_b = place_building(placing_building_type, 0, cell, true)
	is_placing_building = false
	ghost_preview.visible = false

	for u in selected_units:
		if u.unit_type == Unit3D.UnitType.VILLAGER:
			u.command_build(new_b)
			break

	SoundManager.play_sound("build")

func _on_train_unit_requested(u_type: Unit3D.UnitType) -> void:
	if selected_building == null or selected_building.team != 0:
		return
	try_train_unit(selected_building, u_type, 0)

func try_train_unit(b: Building3D, u_type: Unit3D.UnitType, team: int) -> bool:
	var res = team_resources[team]
	var pop = get_team_population(team)
	var max_pop = get_team_max_population(team)

	if pop >= max_pop:
		return false

	var food_cost = 50
	var wood_cost = 0
	var gold_cost = 0
	var duration = 4.0

	match u_type:
		Unit3D.UnitType.VILLAGER:
			food_cost = 50
			duration = 3.5
		Unit3D.UnitType.SWORDSMAN:
			food_cost = 60
			gold_cost = 20
			duration = 4.5
		Unit3D.UnitType.SPEARMAN:
			food_cost = 50
			wood_cost = 35
			duration = 4.0
		Unit3D.UnitType.ARCHER:
			wood_cost = 45
			gold_cost = 40
			duration = 5.0
		Unit3D.UnitType.CAVALRY:
			food_cost = 75
			gold_cost = 60
			duration = 6.0
		_:
			food_cost = 80
			gold_cost = 60
			duration = 7.0

	var civ_cfg = CivData.get_civ(player_civ if team == 0 else enemy_civ)
	if civ_cfg.has("cost_discount_mult"):
		food_cost = int(food_cost * civ_cfg["cost_discount_mult"])
		wood_cost = int(wood_cost * civ_cfg["cost_discount_mult"])
		gold_cost = int(gold_cost * civ_cfg["cost_discount_mult"])

	if res["food"] < food_cost or res["wood"] < wood_cost or res["gold"] < gold_cost:
		return false

	res["food"] -= food_cost
	res["wood"] -= wood_cost
	res["gold"] -= gold_cost

	b.queue_unit_production(u_type, duration)
	return true

func _on_building_unit_trained(u_type: Unit3D.UnitType, team: int, spawn_pos: Vector3) -> void:
	spawn_unit(u_type, team, spawn_pos)

func _on_research_requested(tech_id: String) -> void:
	if selected_building == null or selected_building.team != 0:
		return
	try_start_research(selected_building, tech_id, 0)

func try_start_research(b: Building3D, tech_id: String, team: int) -> bool:
	if b.is_researching or not b.is_completed:
		return false

	var res = team_resources[team]
	var food_cost = 0
	var wood_cost = 0
	var gold_cost = 0
	var stone_cost = 0
	var duration = 15.0

	match tech_id:
		"AGE_2":
			food_cost = 500
			gold_cost = 200
			duration = 20.0
		"iron_weapons":
			food_cost = 100
			gold_cost = 40
			duration = 12.0
		"scale_armor":
			food_cost = 100
			gold_cost = 40
			duration = 12.0
		"bodkin_arrows":
			wood_cost = 100
			gold_cost = 50
			duration = 12.0
		"wheelbarrow":
			wood_cost = 100
			food_cost = 50
			duration = 12.0

	if res["food"] < food_cost or res["wood"] < wood_cost or res["gold"] < gold_cost or res["stone"] < stone_cost:
		if team == 0:
			SoundManager.play_sound("hit")
		return false

	res["food"] -= food_cost
	res["wood"] -= wood_cost
	res["gold"] -= gold_cost
	res["stone"] -= stone_cost

	b.start_research(tech_id, duration)
	if team == 0:
		SoundManager.play_sound("build")
	return true

func _on_building_research_completed(tech_id: String, team: int) -> void:
	if tech_id == "AGE_2":
		team_age[team] = 2
		if team == 0:
			SoundManager.play_sound("horn")
			ui_manager.notify_banner("HİSAR ÇAĞINA ULAŞILDI!", Color(0.2, 0.95, 0.4))
	elif tech_id in ["iron_weapons", "scale_armor", "bodkin_arrows", "wheelbarrow"]:
		if not team_techs.has(team):
			team_techs[team] = {}
		team_techs[team][tech_id] = true
		_apply_tech_bonus(tech_id, team)
		if team == 0:
			SoundManager.play_sound("horn")
			var t_name = "Demir Silahlar" if tech_id == "iron_weapons" else ("Takviyeli Zırh" if tech_id == "scale_armor" else ("Demir Oklar" if tech_id == "bodkin_arrows" else "El Arabası"))
			ui_manager.notify_banner("%s GELİŞTİRİLDİ!" % t_name.to_upper(), Color(0.95, 0.85, 0.3))

	if selected_building != null and is_instance_valid(selected_building):
		ui_manager.set_selected_entity(selected_building)

func _apply_tech_bonus(tech_id: String, team: int) -> void:
	for u in units:
		if is_instance_valid(u) and u.team == team:
			if tech_id == "iron_weapons" and u.is_infantry():
				u.attack_dmg += 3.0
			elif tech_id == "scale_armor":
				u.armor += 2.0
			elif tech_id == "bodkin_arrows" and u.is_ranged():
				u.attack_dmg += 3.0
			elif tech_id == "wheelbarrow" and u.unit_type == Unit3D.UnitType.VILLAGER:
				u.max_carry = 20
				u.move_speed *= 1.15

func spawn_projectile(start: Vector3, target: Node3D, dmg: float, team: int, bullet: bool = false) -> void:
	var proj = Projectile3D.new()
	add_child(proj)
	proj.setup(start, target, dmg, team, bullet)

func deposit_resource(team: int, type: String, amount: int) -> void:
	if team_resources.has(team) and team_resources[team].has(type):
		team_resources[team][type] += amount
		if team == 0:
			gathered_count += amount

func get_closest_dropoff(from_pos: Vector3, team: int) -> Building3D:
	var best_b = null
	var min_dist = 999999.0
	for b in buildings:
		if is_instance_valid(b) and b.team == team and b.is_completed and (b.building_type in [Building3D.BuildingType.TOWN_CENTER, Building3D.BuildingType.CASTLE]):
			var d = from_pos.distance_squared_to(b.global_position)
			if d < min_dist:
				min_dist = d
				best_b = b
	return best_b

func get_closest_enemy_entity(from_pos: Vector3, team: int, max_range: float) -> Node3D:
	var best_node = null
	var min_dist = max_range * max_range

	for u in units:
		if is_instance_valid(u) and u.team != team and u.hp > 0:
			var d = from_pos.distance_squared_to(u.global_position)
			if d < min_dist:
				min_dist = d
				best_node = u

	for b in buildings:
		if is_instance_valid(b) and b.team != team and b.hp > 0:
			var d = from_pos.distance_squared_to(b.global_position)
			if d < min_dist:
				min_dist = d
				best_node = b

	return best_node

func get_team_units(team: int) -> Array[Unit3D]:
	var res: Array[Unit3D] = []
	for u in units:
		if is_instance_valid(u) and u.team == team:
			res.append(u)
	return res

func get_team_buildings(team: int) -> Array[Building3D]:
	var res: Array[Building3D] = []
	for b in buildings:
		if is_instance_valid(b) and b.team == team:
			res.append(b)
	return res

func get_team_resources(team: int) -> Dictionary:
	return team_resources.get(team, {"food": 0, "wood": 0, "gold": 0})

func get_team_population(team: int) -> int:
	var count = 0
	for u in units:
		if is_instance_valid(u) and u.team == team:
			count += 1
	return count

func get_team_max_population(team: int) -> int:
	var max_pop = 10
	for b in buildings:
		if is_instance_valid(b) and b.team == team and b.is_completed:
			if b.building_type == Building3D.BuildingType.HOUSE:
				max_pop += 5
			elif b.building_type == Building3D.BuildingType.TOWN_CENTER:
				max_pop += 5
	return min(max_pop, 70)

func _on_unit_died(u: Unit3D) -> void:
	if u.team == 1:
		kills_count += 1
	units.erase(u)
	selected_units.erase(u)

func _on_building_destroyed(b: Building3D) -> void:
	buildings.erase(b)
	if selected_building == b:
		selected_building = null
		ui_manager.set_selected_entity(null)

	if b.building_type == Building3D.BuildingType.TOWN_CENTER:
		if b.team == 1:
			_game_over(true)
		elif b.team == 0:
			_game_over(false)

func _game_over(victory: bool) -> void:
	is_game_active = false
	var dur_sec = int((Time.get_ticks_msec() / 1000.0) - game_start_time)
	var dur_str = "%02d:%02d" % [int(float(dur_sec) / 60.0), dur_sec % 60]
	ui_manager.show_game_over(victory, {
		"duration": dur_str,
		"kills": kills_count,
		"trained": trained_count,
		"gathered": gathered_count
	})

func _on_select_all_military() -> void:
	_clear_selection()
	for u in units:
		if is_instance_valid(u) and u.team == 0 and u.unit_type != Unit3D.UnitType.VILLAGER:
			selected_units.append(u)
			u.set_selected(true)
	if selected_units.size() > 0:
		ui_manager.set_selected_entity(selected_units[0])
		SoundManager.play_sound("click")

func _on_jump_to_base() -> void:
	_clear_selection()
	var player_tc: Building3D = null
	for b in buildings:
		if is_instance_valid(b) and b.team == 0 and b.building_type == Building3D.BuildingType.TOWN_CENTER and b.hp > 0:
			player_tc = b
			break
	if player_tc != null:
		selected_building = player_tc
		player_tc.set_selected(true)
		ui_manager.set_selected_entity(player_tc)
		camera.jump_to(player_tc.global_position)
	else:
		camera.jump_to(map_gen.player_start_pos)
	SoundManager.play_sound("click")

func _on_clear_selection_requested() -> void:
	_clear_selection()
	ui_manager.set_selected_entity(null)
	SoundManager.play_sound("click")

func _on_find_idle_villager() -> void:
	for u in units:
		if is_instance_valid(u) and u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER and u.state == Unit3D.State.IDLE:
			_clear_selection()
			selected_units.append(u)
			u.set_selected(true)
			ui_manager.set_selected_entity(u)
			camera.jump_to(u.global_position)
			SoundManager.play_sound("click")
			break

func _on_toggle_speed() -> void:
	if Engine.time_scale == 1.0:
		Engine.time_scale = 2.0
		ui_manager.speed_btn.text = "Hız: 2x"
	else:
		Engine.time_scale = 1.0
		ui_manager.speed_btn.text = "Hız: 1x"

func _on_restart_requested() -> void:
	Engine.time_scale = 1.0
	start_match()
