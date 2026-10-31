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
var drag_last_pos: Vector2 = Vector2.ZERO
var drag_start_time_msec: int = 0
var is_touch_active: bool = false
var has_dragged_significantly: bool = false
var is_drag_box_selecting: bool = false
var is_box_select_mode: bool = false
const DRAG_THRESHOLD: float = 26.0

var last_clicked_unit: Unit3D = null
var last_click_time_msec: int = 0
var tutorial_mgr: TutorialManager = null

func _ready() -> void:
	GraphicsSettings.apply(get_viewport(), get_node_or_null("DirectionalLight3D") as DirectionalLight3D)
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
	ui_manager.field_requested.connect(_on_field_requested)
	ui_manager.select_all_military_requested.connect(_on_select_all_military)
	ui_manager.jump_to_base_requested.connect(_on_jump_to_base)
	ui_manager.find_idle_villager_requested.connect(_on_find_idle_villager)
	ui_manager.clear_selection_requested.connect(_on_clear_selection_requested)
	ui_manager.toggle_speed_requested.connect(_on_toggle_speed)
	ui_manager.restart_requested.connect(_on_restart_requested)
	ui_manager.pause_menu_requested.connect(open_pause_menu)
	ui_manager.resume_requested.connect(close_pause_menu)
	ui_manager.save_requested.connect(_on_save_from_menu)
	ui_manager.main_menu_requested.connect(return_to_main_menu)
	ui_manager.quit_requested.connect(func(): get_tree().quit())
	ui_manager.load_game_requested.connect(load_saved_game)
	ui_manager.zoom_in_requested.connect(func(): camera.zoom_in())
	ui_manager.zoom_out_requested.connect(func(): camera.zoom_out())
	ui_manager.box_select_toggled.connect(func(enabled: bool): is_box_select_mode = enabled)

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

	_add_hd2d_vignette()

	var minimap = ui_manager.get_node_or_null("HUDRoot/Minimap") as Minimap3D
	if minimap != null:
		minimap.map_gen = map_gen
		minimap.camera = camera
		minimap.game_controller = self

	if auto_start_for_testing:
		get_tree().create_timer(0.2).timeout.connect(func():
			_on_start_game_requested(player_civ, enemy_civ, selected_map_type)
		)

## HD-2D framing vignette on a CanvasLayer below the HUD (layer -1). MOUSE_FILTER_IGNORE so the
## fullscreen rect never swallows taps/clicks meant for the 3D world.
func _add_hd2d_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HD2DVignette"
	layer.layer = -1
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/hd2d_vignette.gdshader")
	rect.material = sm
	layer.add_child(rect)
	add_child(layer)

func _on_start_game_requested(p_civ: CivData.CivType, e_civ: CivData.CivType, m_type: CivData.MapType) -> void:
	player_civ = p_civ
	enemy_civ = e_civ
	selected_map_type = m_type
	start_match()

func start_match() -> void:
	_clear_match()

	team_resources = {
		0: {"food": 200, "wood": 200, "gold": 100, "stone": 100},
		1: {"food": 200, "wood": 200, "gold": 100, "stone": 100}
	}
	team_age = {0: 1, 1: 1}
	team_techs = {0: {}, 1: {}}   # tech id -> true once researched (see TechData)
	kills_count = 0
	trained_count = 0
	gathered_count = 0
	game_start_time = Time.get_ticks_msec() / 1000.0

	# 1. Generate 3D Map
	map_gen.generate(selected_map_type)
	camera.setup_bounds(MapGenerator3D.MAP_WIDTH * MapGenerator3D.TILE_SIZE, MapGenerator3D.MAP_HEIGHT * MapGenerator3D.TILE_SIZE)
	camera.terrain = map_gen

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
	_set_match_running(true)

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
		var snapped_pos = Vector3((cell.x + size.x * 0.5) * MapGenerator3D.TILE_SIZE, map_gen.get_footprint_height(cell, size) + 0.5, (cell.y + size.y * 0.5) * MapGenerator3D.TILE_SIZE)
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
	# The project emulates touch from mouse AND mouse from touch (project.godot, input_devices/pointing),
	# so every real tap/click arrives twice: the real event plus an emulated copy. Handling both ran
	# _handle_3d_click twice per tap, and the second run toggled the just-selected building (or unit)
	# off again -> buildings could not be selected. Only the real device's events are handled here.
	if (event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventScreenTouch \
			or event is InputEventScreenDrag) and event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			if SaveManager.save_game(self):
				ui_manager.notify_banner("OYUN KAYDEDİLDİ (F5)", Color(0.2, 0.95, 0.4))
			return
		elif event.keycode == KEY_F9:
			load_saved_game()
			return

	# Mouse / Touch press
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.index == 0):
		if event.pressed:
			drag_start_pos = event.position
			drag_last_pos = event.position
			drag_start_time_msec = Time.get_ticks_msec()
			is_touch_active = true
			has_dragged_significantly = false
			is_drag_box_selecting = false
		else:
			is_touch_active = false
			var elapsed_ms = Time.get_ticks_msec() - drag_start_time_msec
			var total_move = event.position.distance_to(drag_start_pos)
			# Fast taps (< 350ms and < 28px movement) are ALWAYS treated as taps/clicks
			if elapsed_ms < 350 and total_move < 28.0:
				has_dragged_significantly = false

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
			if has_dragged_significantly:
				# Concluded camera pan, ignore release to prevent unintended orders
				return
			
			var mouse_pos = event.position
			var hit_ground = camera.raycast_ground(mouse_pos)
			if is_placing_building:
				_attempt_place_building(hit_ground)
				return
			_handle_3d_click(mouse_pos, hit_ground)

	elif ((event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0) or (event is InputEventScreenDrag and event.index == 0)):
		var cur_pos = event.position
		if not has_dragged_significantly and (cur_pos - drag_start_pos).length() > DRAG_THRESHOLD:
			has_dragged_significantly = true

		if has_dragged_significantly:
			if is_box_select_mode:
				is_drag_box_selecting = true
				ui_manager.draw_drag_box(drag_start_pos, cur_pos)
			else:
				var delta = cur_pos - drag_last_pos
				camera.pan_by_screen_delta(delta)
		drag_last_pos = cur_pos

func _handle_3d_click(screen_pos: Vector2, ground_pos: Vector3) -> void:
	var clicked_entity = _get_entity_at_position(screen_pos, ground_pos)
	var cell = map_gen.world_to_cell(ground_pos)

	if selected_units.size() > 0:
		# 1. Attack enemy entity (Unit or Building)
		if clicked_entity != null and clicked_entity.team != 0:
			_spawn_click_marker(clicked_entity.global_position, "attack")
			for u in selected_units:
				u.command_attack(clicked_entity)
			SoundManager.play_sound("attack")
			return

		# 2. Friendly unit tap. Runs BEFORE resource interaction because _get_entity_at_position()
		# gives units absolute priority: tapping a villager that happens to stand near a tree/mine
		# must select it, not turn into a gather order (map-dependent bug seen on Linux test runs).
		if clicked_entity is Unit3D and clicked_entity.team == 0:
			if clicked_entity in selected_units and selected_units.size() == 1:
				var s_pos = camera.unproject_position(clicked_entity.global_position + Vector3(0, 1.0, 0))
				if screen_pos.distance_to(s_pos) <= 24.0 and ground_pos.distance_to(clicked_entity.global_position) <= 0.8:
					# Precise tap on the single selected unit -> toggle deselect
					_clear_selection()
					ui_manager.set_selected_entity(null)
					SoundManager.play_sound("click")
					return
				# Imprecise tap next to the single selected unit: fall through, so a nearby
				# resource is gathered or the ground receives a move order (branch 5).
			else:
				# Switch selection to this unit (also isolates one unit out of a group)
				_clear_selection()
				selected_units.append(clicked_entity)
				clicked_entity.set_selected(true)
				ui_manager.set_selected_entity(clicked_entity)
				SoundManager.play_sound("click")
				return

		# 3. Resource Gathering / Interaction (Wood, Gold, Stone, Food)
		# When the tap already resolved to one of our own buildings (e.g. a cargo villager tapping the
		# Town Center), only a PRECISE resource hit (exact cell / collider ray) may override it; the fuzzy
		# 48 px screen search would otherwise grab a base-cluster bush/mine next to the TC.
		var ally_building_tapped = clicked_entity is Building3D and clicked_entity.team == 0
		var res_info = _find_resource_at_click(screen_pos, ground_pos, ally_building_tapped)
		if res_info.has("type") and res_info.has("cell") and res_info.get("amount", 0) > 0:
			var r_cell = res_info["cell"] as Vector2i
			var r_type = res_info["type"] as String
			var has_vill = false
			for u in selected_units:
				if u.unit_type == Unit3D.UnitType.VILLAGER:
					has_vill = true
					u.command_gather(r_cell, r_type)
			if has_vill:
				_spawn_click_marker(map_gen.cell_to_world(r_cell), "gather")
				SoundManager.play_sound("click")
				return
			else:
				# Selected military units move to resource location
				_spawn_click_marker(map_gen.cell_to_world(r_cell), "move")
				for u in selected_units:
					u.command_move(map_gen.cell_to_world(r_cell))
				SoundManager.play_sound("click")
				return

		# 4. Ally Building Interactions (Construct, Return Resources, or Inspect)
		if clicked_entity is Building3D and clicked_entity.team == 0:
			# 3a. Construct uncompleted building
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

			# 3a2. Farm fields: villagers farm the tapped field (1 per field, the rest spread to free
			# fields); anyone else just walks there (fields are walkable ground).
			if clicked_entity.building_type == Building3D.BuildingType.FARM and clicked_entity.is_completed:
				var vills: Array = selected_units.filter(func(u): return u.unit_type == Unit3D.UnitType.VILLAGER)
				var others: Array = selected_units.filter(func(u): return u.unit_type != Unit3D.UnitType.VILLAGER)
				if not vills.is_empty():
					var first = vills[0]
					if map_gen.claim_field(clicked_entity.origin_cell, first):
						first.command_gather(clicked_entity.origin_cell, "food")
						vills.remove_at(0)
					send_villagers_to_fields(vills, 0, clicked_entity.global_position)
					_spawn_click_marker(clicked_entity.global_position, "gather")
				for u in others:
					u.command_move(ground_pos)
				SoundManager.play_sound("click")
				return

			# 3a3. Empty-handed villagers tapping a finished Mill go to its free fields
			if clicked_entity.building_type == Building3D.BuildingType.MILL and clicked_entity.is_completed:
				var idle_hands: Array = selected_units.filter(func(u): return u.unit_type == Unit3D.UnitType.VILLAGER and u.carried_resource == 0)
				if not idle_hands.is_empty() and send_villagers_to_fields(idle_hands, 0, clicked_entity.global_position) > 0:
					_spawn_click_marker(clicked_entity.global_position, "gather")
					SoundManager.play_sound("click")
					return

			# 3b. Drop off resources if villager is carrying cargo
			var has_carrying_vill = false
			for u in selected_units:
				if u.unit_type == Unit3D.UnitType.VILLAGER and u.carried_resource > 0:
					has_carrying_vill = true
					u.command_return_resources(clicked_entity)
			if has_carrying_vill:
				_spawn_click_marker(clicked_entity.global_position, "gather")
				SoundManager.play_sound("click")
				return

			# 3c. Direct center click on completed building -> switch selection to building
			var b_center = clicked_entity.global_position + Vector3(0, 1.8, 0)
			var s_center = camera.unproject_position(b_center)
			if screen_pos.distance_to(s_center) <= 24.0:
				_clear_selection()
				selected_building = clicked_entity
				clicked_entity.set_selected(true)
				ui_manager.set_selected_entity(clicked_entity)
				SoundManager.play_sound("click")
				return
			else:
				# Click on outer footprint or ground near building -> move units there!
				_spawn_click_marker(ground_pos, "move")
				for u in selected_units:
					u.command_move(ground_pos)
				SoundManager.play_sound("click")
				return

		# 5. Ground move command (Default fallback for all selected units)
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
		var res_info = _find_resource_at_click(screen_pos, ground_pos)
		if res_info.has("type") and res_info.has("cell") and res_info.get("amount", 0) > 0:
			ui_manager.set_selected_resource(res_info)
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

static func _dist_to_segment_2d(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var l2 = ab.length_squared()
	if l2 < 0.0001:
		return p.distance_to(a)
	var t = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	var projection = a + t * ab
	return p.distance_to(projection)

func _find_unit_near_screen(screen_pos: Vector2, max_screen_dist: float = 36.0) -> Unit3D:
	var best_unit: Unit3D = null
	var best_dist: float = max_screen_dist
	for u in units:
		if not is_instance_valid(u) or u.hp <= 0:
			continue
		var s_feet = camera.unproject_position(u.global_position)
		var s_head = camera.unproject_position(u.global_position + Vector3(0, 1.8, 0))
		var d = _dist_to_segment_2d(screen_pos, s_feet, s_head)
		if d < best_dist:
			best_dist = d
			best_unit = u
	return best_unit

func _find_resource_at_click(screen_pos: Vector2, ground_pos: Vector3, precise_only: bool = false) -> Dictionary:
	# 1. Exact ground cell match (Highest precision when user taps on a cell)
	var cell = map_gen.world_to_cell(ground_pos)
	for r_type in ["gold", "stone", "food", "wood"]:
		var r_data = map_gen.get_resource_at_cell(cell, r_type)
		if not r_data.is_empty() and r_data.get("amount", 0) > 0:
			return r_data

	# 2. 3D Physics Raycast on dedicated Resource layer (mask 4 | 8)
	var space_state = get_world_3d().direct_space_state
	if space_state != null and camera != null:
		var from = camera.project_ray_origin(screen_pos)
		var to = from + camera.project_ray_normal(screen_pos) * 1000.0
		var query = PhysicsRayQueryParameters3D.create(from, to, 12) # 4 | 8
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var result = space_state.intersect_ray(query)
		if result and result.has("collider") and is_instance_valid(result.collider):
			var area = result.collider as Area3D
			if area != null:
				var r_cell = area.get_meta("cell", area.get_meta("res_cell", Vector2i(-1, -1)))
				var r_type = area.get_meta("resource_type", area.get_meta("res_type", ""))
				if r_cell != Vector2i(-1, -1) and r_type != "":
					var r_cur = map_gen.get_resource_at_cell(r_cell, r_type)
					if r_cur.get("amount", 0) > 0:
						return r_cur

	if precise_only:
		return {}

	# 3. Balanced screen-space closest resource search (accounts for terrain height)
	var best_res: Dictionary = {}
	var min_screen_dist: float = 48.0

	for c in map_gen.gold_mines.keys():
		var w_pos = map_gen.cell_to_world(c) + Vector3(0, 0.9, 0)   # cell_to_world includes the ground height
		var s_pos = camera.unproject_position(w_pos)
		var d = screen_pos.distance_to(s_pos)
		if d < min_screen_dist:
			var info = map_gen.get_resource_at_cell(c, "gold")
			if info.get("amount", 0) > 0:
				min_screen_dist = d
				best_res = info

	for c in map_gen.stone_mines.keys():
		var w_pos = map_gen.cell_to_world(c) + Vector3(0, 0.9, 0)   # cell_to_world includes the ground height
		var s_pos = camera.unproject_position(w_pos)
		var d = screen_pos.distance_to(s_pos)
		if d < min_screen_dist:
			var info = map_gen.get_resource_at_cell(c, "stone")
			if info.get("amount", 0) > 0:
				min_screen_dist = d
				best_res = info

	for c in map_gen.berry_bushes.keys():
		var w_pos = map_gen.cell_to_world(c) + Vector3(0, 0.9, 0)   # cell_to_world includes the ground height
		var s_pos = camera.unproject_position(w_pos)
		var d = screen_pos.distance_to(s_pos)
		if d < min_screen_dist:
			var info = map_gen.get_resource_at_cell(c, "food")
			if info.get("amount", 0) > 0:
				min_screen_dist = d
				best_res = info

	for c in map_gen.trees.keys():
		var w_pos = map_gen.cell_to_world(c) + Vector3(0, 1.6, 0)
		var s_pos = camera.unproject_position(w_pos)
		var d = screen_pos.distance_to(s_pos)
		if d < min_screen_dist:
			var info = map_gen.get_resource_at_cell(c, "wood")
			if info.get("amount", 0) > 0:
				min_screen_dist = d
				best_res = info

	if not best_res.is_empty():
		return best_res

	# 4. Adjacent ground cell fallback
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var nc = cell + Vector2i(dx, dy)
			for r_type in ["gold", "stone", "food", "wood"]:
				var r_data = map_gen.get_resource_at_cell(nc, r_type)
				if not r_data.is_empty() and r_data.get("amount", 0) > 0:
					if ground_pos.distance_to(map_gen.cell_to_world(nc)) < 2.0:
						return r_data

	return {}

func _get_entity_at_position(screen_pos: Vector2, ground_pos: Vector3) -> Node3D:
	# 1. Units ALWAYS have absolute priority over buildings!
	var unit_by_screen = _find_unit_near_screen(screen_pos, 36.0)
	if unit_by_screen != null:
		return unit_by_screen

	var best_ground_unit: Unit3D = null
	var min_g_dist: float = 1.3
	for u in units:
		if is_instance_valid(u) and u.hp > 0:
			var gd = u.global_position.distance_to(ground_pos)
			if gd < min_g_dist:
				min_g_dist = gd
				best_ground_unit = u
	if best_ground_unit != null:
		return best_ground_unit

	# 2. Check buildings in screen-space (handles 3D roofs, towers, and facades)
	for b in buildings:
		if is_instance_valid(b) and b.hp > 0:
			var b_center = b.global_position + Vector3(0, 1.8, 0)
			var s_center = camera.unproject_position(b_center)
			var half_w = (b.grid_size.x * MapGenerator3D.TILE_SIZE * 0.5)
			var half_l = (b.grid_size.y * MapGenerator3D.TILE_SIZE * 0.5)
			var s_right = camera.unproject_position(b_center + Vector3(half_w, 0, 0))
			var s_top = camera.unproject_position(b_center + Vector3(0, 2.2, -half_l))
			var rx = max(36.0, abs(s_right.x - s_center.x) + 4.0)
			var ry = max(36.0, abs(s_top.y - s_center.y) + 6.0)
			if abs(screen_pos.x - s_center.x) <= rx and abs(screen_pos.y - s_center.y) <= ry:
				return b

	# 3. Ground footprint proximity fallback
	for b in buildings:
		if is_instance_valid(b) and b.hp > 0:
			var w = b.grid_size.x * MapGenerator3D.TILE_SIZE * 0.5 + 0.3
			var l = b.grid_size.y * MapGenerator3D.TILE_SIZE * 0.5 + 0.3
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
	unit.global_position = Vector3(pos.x, map_gen.get_height_at(pos) if map_gen != null else pos.y, pos.z)
	unit.setup_unit(u_type, team, civ, map_gen, self)
	unit.died.connect(_on_unit_died)
	units.append(unit)
	if team == 0:
		trained_count += 1

	apply_unit_techs(unit)
	return unit

func place_building(b_type: Building3D.BuildingType, team: int, cell: Vector2i, under_construction: bool = false) -> Building3D:
	var civ = player_civ if team == 0 else enemy_civ
	var b = Building3D.new()
	var b_size = _get_building_size(b_type)
	var world_center = Vector3((cell.x + b_size.x * 0.5) * MapGenerator3D.TILE_SIZE, map_gen.get_footprint_height(cell, b_size), (cell.y + b_size.y * 0.5) * MapGenerator3D.TILE_SIZE)

	add_child(b)
	b.global_position = world_center
	b.setup_building(b_type, team, civ, cell, map_gen, self, under_construction)
	apply_building_techs(b)
	b.destroyed.connect(_on_building_destroyed)
	b.unit_trained.connect(_on_building_unit_trained)
	b.research_completed.connect(_on_building_research_completed)

	if b_type == Building3D.BuildingType.FARM:
		map_gen.register_field_cells(cell, b_size)   # walkable plot: nobody needs ejecting
		if not under_construction:
			b.refresh_construction_state()
	else:
		map_gen.register_building_cells(cell, b_size, b)
		_eject_units_from_footprint(cell, b_size)
	buildings.append(b)
	return b

# ---- Farm fields (placed from a Mill; the Mill is the farm centre and food drop-off) ----------
const MAX_FIELDS_PER_MILL: int = 6
## 2x2 slots around a 2x2 mill: sides first, then corners
const FIELD_SLOTS: Array = [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, 2), Vector2i(0, -2),
	Vector2i(-2, 2), Vector2i(2, 2), Vector2i(-2, -2), Vector2i(2, -2)]

## Fields belonging to this mill: same team, within FIELD_REACH cells of it (works for restored
## saves too, no stored link needed).
const FIELD_REACH: int = 5
func get_mill_fields(mill: Building3D) -> Array:
	var out: Array = []
	for b in buildings:
		if is_instance_valid(b) and b.building_type == Building3D.BuildingType.FARM and b.team == mill.team:
			var d: Vector2i = (b.origin_cell - mill.origin_cell).abs()
			if max(d.x, d.y) <= FIELD_REACH:
				out.append(b)
	return out

func _field_fits(origin: Vector2i) -> bool:
	for dx in 2:
		for dy in 2:
			var c := origin + Vector2i(dx, dy)
			if not map_gen.is_valid_cell(c.x, c.y) or not map_gen.is_cell_buildable(c) \
					or not map_gen.get_resource_at_cell(c).is_empty():
				return false
	return map_gen.is_area_level(origin, Vector2i(2, 2))

## Free spot for a field: the 8 tidy slots around the mill first; when trees/buildings block them
## (dense forest maps), the nearest free 2x2 plot within 4 cells of the mill.
func find_field_slot(mill: Building3D) -> Vector2i:
	for off in FIELD_SLOTS:
		if _field_fits(mill.origin_cell + off):
			return mill.origin_cell + off
	var best := Vector2i(-1, -1)
	var best_d := INF
	for dx in range(-4, 5):
		for dy in range(-4, 5):
			var origin: Vector2i = mill.origin_cell + Vector2i(dx, dy)
			if dx > -2 and dx < 2 and dy > -2 and dy < 2:
				continue                          # would overlap the mill itself
			if _field_fits(origin):
				var d := Vector2(dx, dy).length()
				if d < best_d:
					best_d = d
					best = origin
	return best

## Why a field can't be added right now ("" = it can).
func field_block_reason(mill: Building3D, team: int) -> String:
	if not is_instance_valid(mill) or mill.building_type != Building3D.BuildingType.MILL or not mill.is_completed:
		return "Değirmen hazır değil"
	if get_mill_fields(mill).size() >= MAX_FIELDS_PER_MILL:
		return "Tarla sınırı dolu"
	if find_field_slot(mill) == Vector2i(-1, -1):
		return "Çevrede boş yer yok"
	if team_resources[team]["wood"] < _get_building_cost(Building3D.BuildingType.FARM, team)["wood"]:
		return "Yetersiz odun"
	return ""

## Adds a field next to the mill (pays wood, places it under construction) and sends the nearest
## idle villager - or, for the player, the selected villagers - to prepare it; the builder then farms it.
func try_add_field(mill: Building3D, team: int, builders: Array = []) -> Building3D:
	if field_block_reason(mill, team) != "":
		return null
	var origin := find_field_slot(mill)
	var cost := _get_building_cost(Building3D.BuildingType.FARM, team)
	team_resources[team]["wood"] -= cost["wood"]
	var field := place_building(Building3D.BuildingType.FARM, team, origin, true)
	var crew: Array = builders.filter(func(u): return is_instance_valid(u) and u.unit_type == Unit3D.UnitType.VILLAGER)
	if crew.is_empty():
		var best: Unit3D = null
		var best_d := INF
		for u in units:
			if is_instance_valid(u) and u.team == team and u.hp > 0 and u.unit_type == Unit3D.UnitType.VILLAGER and u.state == Unit3D.State.IDLE:
				var d := u.global_position.distance_squared_to(field.global_position)
				if d < best_d:
					best_d = d
					best = u
		if best != null:
			crew = [best]
	for u in crew:
		u.command_build(field)
	return field

func _on_field_requested() -> void:
	if selected_building == null or selected_building.team != 0:
		return
	var reason := field_block_reason(selected_building, 0)
	if reason != "":
		ui_manager.notify_banner(reason.to_upper(), Color(1.0, 0.45, 0.35))
		SoundManager.play_sound("hit")
		return
	try_add_field(selected_building, 0)
	SoundManager.play_sound("build")
	ui_manager.set_selected_entity(selected_building)

## Sends villagers to free fields of `team` near `near_pos`; returns how many were assigned.
func send_villagers_to_fields(vills: Array, team: int, near_pos: Vector3) -> int:
	var n := 0
	for u in vills:
		if not is_instance_valid(u) or u.unit_type != Unit3D.UnitType.VILLAGER:
			continue
		var origin: Vector2i = map_gen.find_free_field(near_pos, team, u, 30.0)
		if origin == Vector2i(-1, -1):
			break
		map_gen.claim_field(origin, u)
		u.command_gather(origin, "food")
		n += 1
	return n

## Team-wide gather-rate multiplier from researched technologies ("field" = farm fields).
func get_gather_mult(team: int, kind: String) -> float:
	return _team_effect_product(team, "gather", "kind", kind)

## Units standing on cells a new building just occupied were trapped inside its blocked footprint
## (A* then returned empty paths for them: stuck builders/gatherers seen in bot simulations).
## Move each one to the nearest walkable cell just outside the footprint.
func _eject_units_from_footprint(origin: Vector2i, size: Vector2i) -> void:
	for u in units:
		if not is_instance_valid(u) or u.hp <= 0:
			continue
		var uc: Vector2i = map_gen.world_to_cell(u.global_position)
		if uc.x < origin.x or uc.x >= origin.x + size.x or uc.y < origin.y or uc.y >= origin.y + size.y:
			continue
		var best := Vector2i(-1, -1)
		var best_d := INF
		for x in range(origin.x - 1, origin.x + size.x + 1):
			for y in range(origin.y - 1, origin.y + size.y + 1):
				var c := Vector2i(x, y)
				if x >= origin.x and x < origin.x + size.x and y >= origin.y and y < origin.y + size.y:
					continue
				if map_gen.is_valid_cell(x, y) and map_gen.is_cell_walkable(c):
					var d: float = Vector2(c).distance_squared_to(Vector2(uc))
					if d < best_d:
						best_d = d
						best = c
		if best != Vector2i(-1, -1):
			var p := map_gen.cell_to_world(best)
			u.global_position = Vector3(p.x, u.global_position.y, p.z)
			u.current_path.clear()

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
		Building3D.BuildingType.LUMBER_CAMP: return Vector2i(2, 2)
		Building3D.BuildingType.MINING_CAMP: return Vector2i(2, 2)
		Building3D.BuildingType.MILL: return Vector2i(2, 2)
		_: return Vector2i(2, 2)

func _get_building_cost(b_type: Building3D.BuildingType, team: int = 0) -> Dictionary:
	var civ_cfg = CivData.get_civ(player_civ if team == 0 else enemy_civ)
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
		Building3D.BuildingType.FARM: cost = {"wood": 50, "gold": 0, "stone": 0}   # one field (added from a Mill)
		Building3D.BuildingType.BLACKSMITH: cost = {"wood": 150, "gold": 0, "stone": 25}
		Building3D.BuildingType.LUMBER_CAMP: cost = {"wood": 100, "gold": 0, "stone": 0}
		Building3D.BuildingType.MINING_CAMP: cost = {"wood": 100, "gold": 0, "stone": 0}
		Building3D.BuildingType.MILL: cost = {"wood": 100, "gold": 0, "stone": 0}

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
			if not map_gen.is_valid_cell(x, y) or not map_gen.is_cell_buildable(Vector2i(x, y)):
				clear = false
				break
	if clear and not map_gen.is_area_level(cell, size):
		clear = false   # too steep: buildings go on level ground

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

	# All selected villagers immediately construct the new building
	for u in selected_units:
		if is_instance_valid(u) and u.unit_type == Unit3D.UnitType.VILLAGER:
			u.command_build(new_b)

	SoundManager.play_sound("build")

func _on_train_unit_requested(u_type: Unit3D.UnitType) -> void:
	if selected_building == null or selected_building.team != 0:
		return
	try_train_unit(selected_building, u_type, 0)

func try_train_unit(b: Building3D, u_type: Unit3D.UnitType, team: int) -> bool:
	if not is_instance_valid(b) or not b.is_completed:
		return false
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

	var cost_dict = {"food": food_cost, "wood": wood_cost, "gold": gold_cost, "stone": 0}
	b.queue_unit_production(u_type, duration * get_train_speed_mult(team, b.building_type), cost_dict)
	return true

func cancel_unit_production(b: Building3D, index: int) -> bool:
	if not is_instance_valid(b) or b.hp <= 0:
		return false
	var item = b.cancel_train_queue_item(index)
	if item.is_empty():
		return false

	var team = b.team
	if team_resources.has(team):
		team_resources[team]["food"] += item.get("food", 0)
		team_resources[team]["wood"] += item.get("wood", 0)
		team_resources[team]["gold"] += item.get("gold", 0)
		team_resources[team]["stone"] += item.get("stone", 0)

	SoundManager.play_sound("click")
	_update_hud()
	if selected_building == b:
		ui_manager.set_selected_entity(b)
	return true

func _on_building_unit_trained(u_type: Unit3D.UnitType, team: int, spawn_pos: Vector3) -> void:
	spawn_unit(u_type, team, spawn_pos)

func _on_research_requested(tech_id: String) -> void:
	if selected_building == null or selected_building.team != 0:
		return
	try_start_research(selected_building, tech_id, 0)

## Why `team` cannot start `tech_id` at building `b` right now ("" = it can).
func research_block_reason(b: Building3D, tech_id: String, team: int) -> String:
	var t: Dictionary = TechData.get_tech(tech_id)
	if t.is_empty() or not is_instance_valid(b) or b.building_type != t["building"]:
		return "Bilinmeyen geliştirme"
	if not b.is_completed:
		return "Bina tamamlanmadı"
	if has_tech(team, tech_id):
		return "Zaten geliştirildi"
	var age: int = team_age.get(team, 1)
	if age < int(t.get("age", 1)):
		return "%s gerekli" % TechData.age_name(int(t["age"]))
	if t.has("max_age") and age > int(t["max_age"]):
		return "Zaten geçildi"
	for req in t.get("requires", []):
		if not has_tech(team, req):
			return "Önce: %s" % TechData.get_tech(req).get("name", req)
	for other in buildings:
		if is_instance_valid(other) and other.team == team and other.is_researching and other.current_research_tech == tech_id:
			return "Araştırılıyor"
	if b.is_researching:
		return "Bina meşgul"
	var res = team_resources[team]
	for k in t["cost"].keys():
		if res.get(k, 0) < int(t["cost"][k]):
			return "Yetersiz kaynak"
	return ""

func try_start_research(b: Building3D, tech_id: String, team: int) -> bool:
	if research_block_reason(b, tech_id, team) != "":
		if team == 0:
			SoundManager.play_sound("hit")
		return false
	var t: Dictionary = TechData.get_tech(tech_id)
	var res = team_resources[team]
	for k in t["cost"].keys():
		res[k] -= int(t["cost"][k])
	b.start_research(tech_id, float(t["time"]))
	if team == 0:
		SoundManager.play_sound("build")
	return true

func has_tech(team: int, tech_id: String) -> bool:
	return bool(team_techs.get(team, {}).get(tech_id, false))

func _on_building_research_completed(tech_id: String, team: int) -> void:
	var t: Dictionary = TechData.get_tech(tech_id)
	if t.is_empty():
		return
	if not team_techs.has(team):
		team_techs[team] = {}
	team_techs[team][tech_id] = true
	for e in t["effects"]:
		match e["type"]:
			"age":
				team_age[team] = int(e["to"])
			"unit":
				for u in units:
					if is_instance_valid(u) and u.team == team:
						_apply_unit_effect(u, e)
			"carry":
				for u in units:
					if is_instance_valid(u) and u.team == team and u.unit_type == Unit3D.UnitType.VILLAGER:
						u.max_carry += int(e["add"])
			"building", "level":
				for b in buildings:
					if is_instance_valid(b) and b.team == team:
						_apply_building_effect(b, e)
	if team == 0:
		SoundManager.play_sound("horn")
		if tech_id.begins_with("AGE_"):
			ui_manager.notify_banner("%s ULAŞILDI!" % TechData.age_name(team_age[team]).to_upper(), Color(0.2, 0.95, 0.4))
		else:
			ui_manager.notify_banner("%s GELİŞTİRİLDİ!" % String(t["name"]).to_upper(), Color(0.95, 0.85, 0.3))
	if selected_building != null and is_instance_valid(selected_building):
		ui_manager.set_selected_entity(selected_building)

func _apply_unit_effect(u: Unit3D, e: Dictionary) -> void:
	if not TechData.unit_matches(u, e["filter"]):
		return
	var stat: String = e["stat"]
	var before: float = float(u.get(stat))
	var after: float = before + float(e["add"]) if e.has("add") else before * float(e["mult"])
	u.set(stat, after)
	if stat == "max_hp":
		u.hp += after - before

func _apply_building_effect(b: Building3D, e: Dictionary) -> void:
	if b.building_type != e["building"]:
		return
	if e["type"] == "level":
		b.set_upgrade_level(2)
		return
	var stat: String = e["stat"]
	var before: float = float(b.get(stat))
	var after: float = before + float(e["add"]) if e.has("add") else before * float(e["mult"])
	b.set(stat, after)
	if stat == "max_hp":
		b.hp += after - before

## Every researched unit effect (+ carry bonus) on a freshly spawned unit.
func apply_unit_techs(u: Unit3D) -> void:
	for id in team_techs.get(u.team, {}).keys():
		if not has_tech(u.team, id):
			continue
		for e in TechData.get_tech(id).get("effects", []):
			if e["type"] == "unit":
				_apply_unit_effect(u, e)
			elif e["type"] == "carry" and u.unit_type == Unit3D.UnitType.VILLAGER:
				u.max_carry += int(e["add"])

## Every researched building effect / upgraded look on a freshly placed (or restored) building.
func apply_building_techs(b: Building3D) -> void:
	for id in team_techs.get(b.team, {}).keys():
		if not has_tech(b.team, id):
			continue
		for e in TechData.get_tech(id).get("effects", []):
			if e["type"] in ["building", "level"]:
				_apply_building_effect(b, e)

func _team_effect_product(team: int, effect_type: String, match_key: String, match_val) -> float:
	var m := 1.0
	for id in team_techs.get(team, {}).keys():
		if not has_tech(team, id):
			continue
		for e in TechData.get_tech(id).get("effects", []):
			if e["type"] == effect_type and e.get(match_key) == match_val:
				m *= float(e["mult"])
	return m

func get_train_speed_mult(team: int, b_type: int) -> float:
	return _team_effect_product(team, "train_speed", "building", b_type)

func get_house_pop(team: int) -> int:
	var pop := 5
	for id in team_techs.get(team, {}).keys():
		if has_tech(team, id):
			for e in TechData.get_tech(id).get("effects", []):
				if e["type"] == "house_pop":
					pop += int(e["add"])
	return pop

func spawn_projectile(start: Vector3, target: Node3D, dmg: float, team: int, bullet: bool = false) -> void:
	var proj = Projectile3D.new()
	add_child(proj)
	proj.setup(start, target, dmg, team, bullet)

func deposit_resource(team: int, type: String, amount: int) -> void:
	if team_resources.has(team) and team_resources[team].has(type):
		team_resources[team][type] += amount
		if team == 0:
			gathered_count += amount

func get_closest_dropoff_for_resource(from_pos: Vector3, team: int, res_type: String) -> Building3D:
	var allowed_types = [Building3D.BuildingType.TOWN_CENTER, Building3D.BuildingType.CASTLE]
	match res_type:
		"wood":
			allowed_types.append(Building3D.BuildingType.LUMBER_CAMP)
		"gold", "stone":
			allowed_types.append(Building3D.BuildingType.MINING_CAMP)
		"food":
			allowed_types.append(Building3D.BuildingType.MILL)

	var best_b: Building3D = null
	var min_dist = 999999.0
	for b in buildings:
		if is_instance_valid(b) and b.team == team and b.is_completed and b.hp > 0:
			if b.building_type in allowed_types:
				var d = from_pos.distance_squared_to(b.global_position)
				if d < min_dist:
					min_dist = d
					best_b = b
	return best_b

func get_closest_dropoff(from_pos: Vector3, team: int, res_type: String = "") -> Building3D:
	if res_type != "":
		return get_closest_dropoff_for_resource(from_pos, team, res_type)
	var best_b = null
	var min_dist = 999999.0
	for b in buildings:
		if is_instance_valid(b) and b.team == team and b.is_completed and b.hp > 0 and (b.building_type in [Building3D.BuildingType.TOWN_CENTER, Building3D.BuildingType.CASTLE, Building3D.BuildingType.LUMBER_CAMP, Building3D.BuildingType.MINING_CAMP, Building3D.BuildingType.MILL]):
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
				max_pop += get_house_pop(team)
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

## Removes the match's units and buildings and leaves any placement / pause state.
func _clear_match() -> void:
	if get_tree() != null:
		get_tree().paused = false
	if ui_manager != null and ui_manager.pause_menu != null:
		ui_manager.pause_menu.close()
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
	is_placing_building = false
	if ghost_preview != null:
		ghost_preview.visible = false

## A match is running: Escape / Android Back open the in-match menu instead of quitting the app.
func _set_match_running(running: bool) -> void:
	if ui_manager != null and ui_manager.pause_menu != null:
		ui_manager.pause_menu.match_running = running
	if get_tree() != null:
		get_tree().quit_on_go_back = not running

## In-match menu: the match is paused while it is open.
func open_pause_menu() -> void:
	if not is_game_active or ui_manager.game_over_modal.visible:
		return
	get_tree().paused = true
	ui_manager.pause_menu.open()

func close_pause_menu() -> void:
	get_tree().paused = false
	ui_manager.pause_menu.close()

func _on_save_from_menu() -> void:
	if SaveManager.save_game(self):
		ui_manager.pause_menu.show_status("Oyun kaydedildi. Ana menüden \"KAYITLI OYUN\" ile devam edebilirsin.")
	else:
		ui_manager.pause_menu.show_status("Kaydedilemedi!")

## Leaves the match (pause menu or game-over modal) and shows the main menu.
func return_to_main_menu() -> void:
	_clear_match()
	is_game_active = false
	_set_match_running(false)
	Engine.time_scale = 1.0
	ui_manager.speed_btn.text = "Hız: 1x"
	ui_manager.set_selected_entity(null)
	ui_manager.build_panel.visible = false
	ui_manager.game_over_modal.visible = false
	ui_manager.hud_root.visible = false
	ui_manager.menu_root.visible = true
	if ui_manager.menu_root.has_method("_show_main_menu"):
		ui_manager.menu_root._show_main_menu()

## Main menu "KAYITLI OYUN": continue the quick-saved match.
func load_saved_game() -> void:
	if not SaveManager.has_saved_game():
		return
	_clear_match()
	if SaveManager.load_game(self):
		Engine.time_scale = 1.0
		ui_manager.speed_btn.text = "Hız: 1x"
		_set_match_running(true)

func _on_restart_requested() -> void:
	Engine.time_scale = 1.0
	start_match()
