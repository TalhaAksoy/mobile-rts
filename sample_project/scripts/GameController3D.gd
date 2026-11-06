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
signal age_changed(team: int, age: int)     # after every building / unit of the team took its new age look
var team_techs: Dictionary = {
	0: {"iron_weapons": false, "scale_armor": false, "bodkin_arrows": false, "wheelbarrow": false},
	1: {"iron_weapons": false, "scale_armor": false, "bodkin_arrows": false, "wheelbarrow": false}
}

var units: Array[Unit3D] = []
var buildings: Array[Building3D] = []

var selected_units: Array[Unit3D] = []
## "attack" / "defend" after the SALDIR / SAVUN button: the next map tap becomes that order ("" = normal taps)
var pending_army_command: String = ""
var selected_building: Building3D = null

var is_game_active: bool = false
var game_start_time: float = 0.0
var match_time: float = 0.0          # game seconds played (follows the speed button and pause, unlike the wall clock)
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
## Long press (finger held still): released on one of our units it selects every unit of that type on screen;
## dragged on, it draws a selection box (no mode button needed). Plain taps keep their single-unit behaviour
## (a fast double tap is deliberately NOT a mass select: in a tight cluster it fired by accident).
const LONG_PRESS_MS := 450
var _long_press_box := false
## Control groups 1-4 (kept / recalled with the group buttons on the right).
const GROUP_COUNT := 4
var control_groups: Array = [[], [], [], []]
const DRAG_THRESHOLD: float = 26.0

var last_clicked_unit: Unit3D = null
var last_click_time_msec: int = 0
var tutorial_mgr: TutorialManager = null
## Enemy bot difficulty for the next match (picked on the civ select screen; EnemyAI3D.PROFILES).
var ai_difficulty: int = EnemyAI3D.Difficulty.NORMAL
## Map size and number of bots for the next match (new-game screen). Small fits 1 bot, Medium 3,
## Large 5 (MapGenerator3D.MAP_SIZE_MAX_BOTS). Bot civs: bot_civs[i] for bot i+1 when set, else
## enemy_civ for the first bot and a random civ nobody else plays for the others.
var map_size: int = MapGenerator3D.MapSize.SMALL
var bot_count: int = 1
var bot_civs: Array = []
## Civ of every team in the running match (0 = player).
var team_civs: Dictionary = {}
## One EnemyAI3D per bot; bot_ais[0] is the scene's $EnemyAI3D (= enemy_ai, team 1).
var bot_ais: Array[EnemyAI3D] = []

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
	ui_manager.cancel_placement_requested.connect(cancel_building_placement)
	ui_manager.add_builder_requested.connect(func():
		if is_instance_valid(selected_building) and selected_building.team == 0:
			if add_builder_to_site(selected_building) == null:
				ui_manager.notify_banner("Gönderilecek köylü yok" if get_site_builders(selected_building).size() < MAX_BUILDERS else "İnşaatçı sınırı dolu (%d)" % MAX_BUILDERS, Color(1.0, 0.6, 0.4))
			ui_manager.set_selected_entity(selected_building))
	ui_manager.cancel_construction_requested.connect(func():
		if is_instance_valid(selected_building) and selected_building.team == 0:
			cancel_construction(selected_building))
	# Escape / Android Back first leave building placement, then open the pause menu
	ui_manager.pause_menu.back_handler = cancel_building_placement
	ui_manager.select_all_military_requested.connect(_on_select_all_military)
	ui_manager.group_tapped.connect(func(i: int):
		if _group_members(i).is_empty():
			assign_control_group(i)               # empty group + a selection: tap saves it too
		else:
			select_control_group(i))
	ui_manager.group_held.connect(assign_control_group)
	ui_manager.group_double_tapped.connect(func(i: int):
		select_control_group(i)
		jump_to_control_group(i))
	ui_manager.type_filter_requested.connect(filter_selection_to_type)
	ui_manager.army_command_requested.connect(_on_army_command)
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
	ui_manager.difficulty_selected.connect(func(d: int): ai_difficulty = d)
	ui_manager.match_setup_selected.connect(func(sz: int, n: int, civs: Array):
		map_size = sz
		bot_count = n
		bot_civs = civs.duplicate())
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
	layer.visible = int(GraphicsSettings.values.get("effects", 2)) >= 1      # off on the Düşük preset
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

	bot_count = clampi(bot_count, 1, MapGenerator3D.max_bots_for(map_size))
	_init_team_tables()
	_assign_team_civs()
	kills_count = 0
	trained_count = 0
	gathered_count = 0
	game_start_time = Time.get_ticks_msec() / 1000.0

	# 1. Generate 3D Map
	map_gen.set_map_size(map_size)
	map_gen.generate(selected_map_type, -1, bot_count)
	camera.setup_bounds(map_gen.MAP_WIDTH * MapGenerator3D.TILE_SIZE, map_gen.MAP_HEIGHT * MapGenerator3D.TILE_SIZE)
	camera.terrain = map_gen

	# 2. Player Base (South)
	var player_base_cell = map_gen.world_to_cell(map_gen.player_start_pos)
	var _player_tc = place_building(Building3D.BuildingType.TOWN_CENTER, 0, player_base_cell - Vector2i(1, 1), false)

	var p_civ_cfg = CivData.get_civ(player_civ)
	var start_vills = 3 + p_civ_cfg.get("start_villager_bonus", 0)
	for i in range(start_vills):
		var offset = Vector3(cos(i * 1.5) * 3.5, 0, sin(i * 1.5) * 3.5 + 2.5)
		spawn_unit(Unit3D.UnitType.VILLAGER, 0, map_gen.player_start_pos + offset)

	# 3. Bot bases (one bot: north; more: round the map). Villagers stand behind the TC, away from
	# the map centre (the first bot of a 1v1: north of it, as before).
	var map_centre := Vector3(map_gen.MAP_WIDTH * MapGenerator3D.TILE_SIZE * 0.5, 0, map_gen.MAP_HEIGHT * MapGenerator3D.TILE_SIZE * 0.5)
	for t in range(1, bot_count + 1):
		var sp: Vector3 = map_gen.get_start_pos(t)
		place_building(Building3D.BuildingType.TOWN_CENTER, t, map_gen.world_to_cell(sp) - Vector2i(1, 1), false)
		var back := Vector3(0, 0, -1) if bot_count == 1 else Vector3(sp.x - map_centre.x, 0, sp.z - map_centre.z).normalized()
		for i in range(3):
			var offset = Vector3(cos(i * 1.5) * 3.5, 0, sin(i * 1.5) * 3.5) + back * 2.5
			spawn_unit(Unit3D.UnitType.VILLAGER, t, sp + offset)

	_setup_bot_ais()

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

## Resources / age / techs for the player and every bot.
func _init_team_tables() -> void:
	team_resources = {}
	team_age = {}
	team_techs = {}   # tech id -> true once researched (see TechData)
	for t in range(bot_count + 1):
		team_resources[t] = {"food": 200, "wood": 200, "gold": 100, "stone": 100}
		team_age[t] = 1
		team_techs[t] = {}

func _assign_team_civs() -> void:
	team_civs = {0: player_civ}
	var used := [player_civ]
	for t in range(1, bot_count + 1):
		var c = null
		if t - 1 < bot_civs.size() and bot_civs[t - 1] != null and int(bot_civs[t - 1]) >= 0:
			c = int(bot_civs[t - 1])
		elif t == 1:
			c = enemy_civ
		else:
			var free: Array = []
			for civ in CivData.CivType.values():
				if not used.has(civ):
					free.append(civ)
			c = free[randi() % free.size()] if not free.is_empty() else CivData.CivType.values()[randi() % CivData.CivType.size()]
		team_civs[t] = c
		used.append(c)
	enemy_civ = team_civs[1]

func civ_of(team: int) -> CivData.CivType:
	if team == 0:
		return player_civ
	return team_civs.get(team, enemy_civ)

## bot_ais[0] is the scene's EnemyAI3D (team 1); bots 2..5 get their own node.
func _setup_bot_ais() -> void:
	for i in range(1, bot_ais.size()):
		if is_instance_valid(bot_ais[i]):
			bot_ais[i].queue_free()
	bot_ais = [enemy_ai]
	for t in range(2, bot_count + 1):
		var ai := EnemyAI3D.new()
		ai.name = "EnemyAI3D_team%d" % t
		add_child(ai)
		bot_ais.append(ai)
	for i in bot_ais.size():
		bot_ais[i].setup_ai(team_civs[i + 1], map_gen, self, ai_difficulty, i + 1)

func get_bot_ai(team: int) -> EnemyAI3D:
	return bot_ais[team - 1] if team >= 1 and team - 1 < bot_ais.size() else null

## Every unit / building that is not the player's (fog of war hides them out of sight).
func _hostile_units() -> Array:
	return units.filter(func(u): return is_instance_valid(u) and u.team != 0)

func _hostile_buildings() -> Array:
	return buildings.filter(func(b): return is_instance_valid(b) and b.team != 0)

func _process(delta: float) -> void:
	if not is_game_active:
		return

	match_time += delta
	_update_hud()
	_check_long_press()

	if tutorial_mgr != null:
		tutorial_mgr.check_progress()

	fog_timer -= delta
	if fog_timer <= 0.0:
		fog_timer = 0.2
		map_gen.update_fog_of_war(get_team_units(0), get_team_buildings(0), _hostile_units(), _hostile_buildings())

	if is_placing_building:
		var mouse_pos = get_viewport().get_mouse_position()
		var hit_ground = camera.raycast_ground(mouse_pos)
		update_ghost(map_gen.world_to_cell(hit_ground))

func _update_hud() -> void:
	var res = team_resources[0]
	var pop = get_team_population(0)
	var max_pop = get_team_max_population(0)
	ui_manager.update_resources(res["food"], res["wood"], res["gold"], res.get("stone", 0), pop, max_pop)
	if ui_manager.has_method("set_age"):
		ui_manager.set_age(int(team_age.get(0, 1)))

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
			_long_press_box = false
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
			if _long_press_box:
				_long_press_box = false
				ui_manager.hide_drag_box()
				var held = _get_entity_at_position(drag_start_pos, camera.raycast_ground(drag_start_pos))
				if held is Unit3D and held.team == 0:
					select_same_type_on_screen(held.unit_type)
				return                                     # held without dragging: never a move order
			
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
			if is_box_select_mode or _long_press_box:
				is_drag_box_selecting = true
				ui_manager.draw_drag_box(drag_start_pos, cur_pos)
			else:
				var delta = cur_pos - drag_last_pos
				camera.pan_by_screen_delta(delta)
		drag_last_pos = cur_pos

func _handle_3d_click(screen_pos: Vector2, ground_pos: Vector3) -> void:
	var clicked_entity = _get_entity_at_position(screen_pos, ground_pos)
	var cell = map_gen.world_to_cell(ground_pos)


	# 0. Armed army order (SALDIR / SAVUN button, then this tap)
	if pending_army_command != "" and selected_units.size() > 0:
		_issue_army_command(pending_army_command, clicked_entity, ground_pos)
		pending_army_command = ""
		return

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
				if has_vill:
					assign_builders(clicked_entity, selected_units)
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
	pending_army_command = ""
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

## Screen box of a building's model: its footprint (as drawn, 90 %) from the ground up to the model's
## height, projected through the camera.
func _building_screen_rect(b: Building3D) -> Rect2:
	var hw: float = b.grid_size.x * MapGenerator3D.TILE_SIZE * 0.45
	var hl: float = b.grid_size.y * MapGenerator3D.TILE_SIZE * 0.45
	var h: float = maxf(1.0, b.model_height)
	var r := Rect2(camera.unproject_position(b.global_position), Vector2.ZERO)
	for x in [-hw, hw]:
		for z in [-hl, hl]:
			for y in [0.0, h]:
				r = r.expand(camera.unproject_position(b.global_position + Vector3(x, y, z)))
	return r

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

	# 2. A tap on the ground of a farm field picks that field. Fields are flat, so the tapped ground
	#    point is exact; the screen boxes below are built for tall buildings, and the Mill's box
	#    reached over the field behind it (tapping that field selected the Mill).
	#    A building whose model covers the tap on screen (a Mill roof drawn over the field behind it)
	#    still wins over the field.
	var g_cell: Vector2i = map_gen.world_to_cell(ground_pos)
	var field_origin: Vector2i = map_gen.field_origin_at(g_cell)
	if field_origin != Vector2i(-1, -1):
		var cover: Building3D = null
		var cover_d := INF
		for b in buildings:
			if is_instance_valid(b) and b.hp > 0 and b.building_type != Building3D.BuildingType.FARM:
				var r := _building_screen_rect(b)
				if r.has_point(screen_pos):
					var d := screen_pos.distance_to(r.get_center())
					if d < cover_d:
						cover_d = d
						cover = b
		if cover != null:
			return cover
		for b in buildings:
			if is_instance_valid(b) and b.hp > 0 and b.building_type == Building3D.BuildingType.FARM and b.origin_cell == field_origin:
				return b

	# 3. Check buildings in screen-space (handles 3D roofs, towers, and facades). When boxes overlap,
	#    the building whose centre is closest to the tap wins (not simply the first in the list).
	var best_b: Building3D = null
	var best_score := INF
	for b in buildings:
		if is_instance_valid(b) and b.hp > 0 and b.building_type != Building3D.BuildingType.FARM:
			var b_center = b.global_position + Vector3(0, 1.8, 0)
			var s_center = camera.unproject_position(b_center)
			var half_w = (b.grid_size.x * MapGenerator3D.TILE_SIZE * 0.5)
			var half_l = (b.grid_size.y * MapGenerator3D.TILE_SIZE * 0.5)
			var s_right = camera.unproject_position(b_center + Vector3(half_w, 0, 0))
			var s_top = camera.unproject_position(b_center + Vector3(0, 2.2, -half_l))
			var rx = max(36.0, abs(s_right.x - s_center.x) + 4.0)
			var ry = max(36.0, abs(s_top.y - s_center.y) + 6.0)
			var nx: float = abs(screen_pos.x - s_center.x) / rx
			var ny: float = abs(screen_pos.y - s_center.y) / ry
			if nx <= 1.0 and ny <= 1.0:
				var score := nx * nx + ny * ny
				if score < best_score:
					best_score = score
					best_b = b
	if best_b != null:
		return best_b

	# 4. Ground footprint proximity fallback
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

	_select_units(found)

func _check_long_press() -> void:
	if not is_touch_active or has_dragged_significantly or _long_press_box or is_placing_building or is_box_select_mode:
		return
	if Time.get_ticks_msec() - drag_start_time_msec < LONG_PRESS_MS:
		return
	_long_press_box = true
	ui_manager.draw_drag_box(drag_start_pos, drag_start_pos + Vector2(2, 2))    # a dot: "now drag"
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(25)

## Replace the selection with `found` (own units). Empty -> nothing changes.
func _select_units(found: Array) -> void:
	if found.is_empty():
		return
	_clear_selection()
	for u in found:
		selected_units.append(u)
		u.set_selected(true)
	ui_manager.set_selected_entity(found[0])
	SoundManager.play_sound("click")

## Every living unit of ours of this type whose feet are on screen.
func select_same_type_on_screen(u_type: int) -> void:
	var rect := get_viewport().get_visible_rect()
	var found: Array = []
	for u in units:
		if is_instance_valid(u) and u.team == 0 and u.hp > 0 and int(u.unit_type) == u_type \
				and not camera.is_position_behind(u.global_position) and rect.has_point(camera.unproject_position(u.global_position)):
			found.append(u)
	_select_units(found)
	if found.size() > 1:
		ui_manager.notify_banner("%d %s seçildi" % [found.size(), ui_manager._unit_type_name(found[0])], Color(0.85, 0.95, 1.0))

## Keep only the selected units of this type (the type buttons in the group panel).
func filter_selection_to_type(u_type: int) -> void:
	_select_units(selected_units.filter(func(u): return is_instance_valid(u) and u.hp > 0 and int(u.unit_type) == u_type))

func _group_members(i: int) -> Array:
	control_groups[i] = control_groups[i].filter(func(u): return is_instance_valid(u) and u.hp > 0)
	return control_groups[i]

func assign_control_group(i: int) -> void:
	var picked: Array = selected_units.filter(func(u): return is_instance_valid(u) and u.team == 0 and u.hp > 0)
	if picked.is_empty():
		return
	for g in GROUP_COUNT:                          # a unit belongs to one group
		if g != i:
			control_groups[g] = control_groups[g].filter(func(u): return not picked.has(u))
	control_groups[i] = picked.duplicate()
	ui_manager.notify_banner("Grup %d: %d birim kaydedildi" % [i + 1, picked.size()], Color(0.7, 1.0, 0.7))
	SoundManager.play_sound("click")

func select_control_group(i: int) -> void:
	_select_units(_group_members(i).duplicate())

func jump_to_control_group(i: int) -> void:
	var m := _group_members(i)
	if m.is_empty():
		return
	var c := Vector3.ZERO
	for u in m:
		c += u.global_position
	camera.jump_to(c / m.size())

func spawn_unit(u_type: Unit3D.UnitType, team: int, pos: Vector3) -> Unit3D:
	var civ = civ_of(team)
	var unit = Unit3D.new()
	unit.age_look = int(team_age.get(team, 1))
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
	var civ = civ_of(team)
	var b = Building3D.new()
	b.age_look = int(team_age.get(team, 1))
	var b_size = _get_building_size(b_type)
	# buildings stand on the lowest ground (their walls hide the rise); a flat field on the highest,
	# with a soil bank under its low side (Building3D), so it never sinks into a slope
	var ground_y: float = map_gen.get_footprint_height_range(cell, b_size).y if b_type == Building3D.BuildingType.FARM else map_gen.get_footprint_height(cell, b_size)
	var world_center = Vector3((cell.x + b_size.x * 0.5) * MapGenerator3D.TILE_SIZE, ground_y, (cell.y + b_size.y * 0.5) * MapGenerator3D.TILE_SIZE)

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
	var civ_cfg = CivData.get_civ(civ_of(team))
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
	if ui_manager.has_method("show_placement_bar"):
		ui_manager.show_placement_bar(true, b_type)

func _attempt_place_building(ground_pos: Vector3) -> void:
	var cell = map_gen.world_to_cell(ground_pos)
	update_ghost(cell)
	var reason := placement_block_reason(placing_building_type, cell)
	if reason != "":
		SoundManager.play_sound("hit")
		ui_manager.notify_banner(reason, Color(1.0, 0.45, 0.35))
		return

	var cost = _get_building_cost(placing_building_type)
	team_resources[0]["wood"] -= cost["wood"]
	team_resources[0]["gold"] -= cost["gold"]
	team_resources[0]["stone"] -= cost["stone"]

	var new_b = place_building(placing_building_type, 0, cell, true)
	_end_placement()

	# The selected villagers (up to MAX_BUILDERS, nearest first) start building right away
	assign_builders(new_b, selected_units)

	SoundManager.play_sound("build")

# ---- Placement rules (the ghost turns red where a building can't go) ---------------------------
const GHOST_OK := Color(0.2, 0.95, 0.3)
const GHOST_BAD := Color(0.85, 0.02, 0.02)
var _ghost_cell := Vector2i(-9999, -9999)
var _ghost_type := -1
var ghost_reason := ""

## Why a `b_type` building can't go with its corner at `cell` ("" = it can):
##  * every cell free (no tree, mine, bush, building, field or water) - "Burada ağaç ya da kaynak var"
##  * level ground                                                     - "Zemin çok eğimli"
##  * the player's villagers can walk up to it                          - "Köylüler buraya ulaşamaz"
func placement_block_reason(b_type: Building3D.BuildingType, cell: Vector2i, team: int = 0) -> String:
	var size := _get_building_size(b_type)
	for x in range(cell.x, cell.x + size.x):
		for y in range(cell.y, cell.y + size.y):
			var c := Vector2i(x, y)
			if not map_gen.is_valid_cell(x, y):
				return "Harita dışı"
			if not map_gen.is_cell_buildable(c):
				if map_gen.trees.has(c) or map_gen.gold_mines.has(c) or map_gen.stone_mines.has(c) or map_gen.berry_bushes.has(c):
					return "Burada ağaç ya da kaynak var"
				return "Burası dolu"
	if not map_gen.is_area_level(cell, size):
		return "Zemin çok eğimli"
	if not _site_reachable(cell, size, team):
		return "Köylüler buraya ulaşamaz"
	return ""

## A villager of `team` (the selected ones first, else the nearest one) can walk to within building reach
## of the footprint (Unit3D builds from next to the walls, or from 1.3 cells out when it can't get closer).
func _site_reachable(cell: Vector2i, size: Vector2i, team: int) -> bool:
	var target := Vector3((cell.x + size.x * 0.5) * MapGenerator3D.TILE_SIZE, 0.0, (cell.y + size.y * 0.5) * MapGenerator3D.TILE_SIZE)
	var walker: Unit3D = null
	for u in selected_units:
		if is_instance_valid(u) and u.team == team and u.unit_type == Unit3D.UnitType.VILLAGER:
			walker = u
			break
	if walker == null:
		var best := INF
		for u in units:
			if is_instance_valid(u) and u.hp > 0 and u.team == team and u.unit_type == Unit3D.UnitType.VILLAGER:
				var d: float = u.global_position.distance_squared_to(target)
				if d < best:
					best = d
					walker = u
	if walker == null:
		return true          # nobody to send yet: do not block the player on this
	var reach: float = MapGenerator3D.TILE_SIZE * 1.3
	if Unit3D._dist_to_cells(walker.global_position, cell, size) <= reach:
		return true
	var path: Array = map_gen.get_path_to_target(walker.global_position, target)
	return not path.is_empty() and Unit3D._dist_to_cells(path[-1], cell, size) <= reach

## Moves the placement ghost to `cell` and colours it: green where the building can go, red where not
## (the reason shows in the placement bar). The check runs only when the cell or building changes.
func update_ghost(cell: Vector2i) -> void:
	var size = _get_building_size(placing_building_type)
	ghost_preview.global_position = Vector3((cell.x + size.x * 0.5) * MapGenerator3D.TILE_SIZE, map_gen.get_footprint_height(cell, size) + 0.5, (cell.y + size.y * 0.5) * MapGenerator3D.TILE_SIZE)
	if cell == _ghost_cell and int(placing_building_type) == _ghost_type:
		return
	_ghost_cell = cell
	_ghost_type = int(placing_building_type)
	ghost_reason = placement_block_reason(placing_building_type, cell)
	var col: Color = GHOST_OK if ghost_reason == "" else GHOST_BAD
	var mat := ghost_preview.material_override as StandardMaterial3D
	mat.albedo_color = Color(col.r, col.g, col.b, 0.45 if ghost_reason == "" else 0.6)
	mat.emission = col
	if ui_manager.has_method("set_placement_reason"):
		ui_manager.set_placement_reason(placing_building_type, ghost_reason)

# ---- Construction crews and cancelling --------------------------------------------------------
## At most this many villagers work on one construction site (each one adds its own build speed).
const MAX_BUILDERS: int = 5

## Villagers of the site's team building it now.
func get_site_builders(site: Building3D) -> Array:
	var out: Array = []
	for u in units:
		if is_instance_valid(u) and u.hp > 0 and u.team == site.team and u.unit_type == Unit3D.UnitType.VILLAGER \
				and u.state == Unit3D.State.BUILDING and u.target_entity == site:
			out.append(u)
	return out

## Sends villagers from `candidates` (nearest first) to the site until it has MAX_BUILDERS.
## Returns how many were sent; the rest keep their orders.
func assign_builders(site: Building3D, candidates: Array) -> int:
	if not is_instance_valid(site) or site.is_completed:
		return 0
	var crew := get_site_builders(site)
	var free_slots := MAX_BUILDERS - crew.size()
	var pool: Array = candidates.filter(func(u): return is_instance_valid(u) and u.hp > 0 and u.team == site.team \
		and u.unit_type == Unit3D.UnitType.VILLAGER and not crew.has(u))
	pool.sort_custom(func(a, b): return a.global_position.distance_squared_to(site.global_position) < b.global_position.distance_squared_to(site.global_position))
	var sent := 0
	for u in pool:
		if sent >= free_slots:
			break
		u.command_build(site)
		sent += 1
	if pool.size() > sent and site.team == 0:
		ui_manager.notify_banner("Bir inşaatta en fazla %d köylü çalışabilir" % MAX_BUILDERS, Color(1.0, 0.85, 0.4))
	return sent

## "+ Köylü Ekle" on a selected construction site: the nearest idle villager, otherwise the nearest one
## that is gathering or walking (not one already building something). Null when none or the crew is full.
func add_builder_to_site(site: Building3D) -> Unit3D:
	if not is_instance_valid(site) or site.is_completed or get_site_builders(site).size() >= MAX_BUILDERS:
		return null
	var best: Unit3D = null
	var best_score := INF
	for u in units:
		if not is_instance_valid(u) or u.hp <= 0 or u.team != site.team or u.unit_type != Unit3D.UnitType.VILLAGER:
			continue
		if u.state == Unit3D.State.BUILDING:
			continue
		var d: float = u.global_position.distance_to(site.global_position)
		var score: float = d if u.state == Unit3D.State.IDLE else d + 1000.0   # idle hands first
		if score < best_score:
			best_score = score
			best = u
	if best != null:
		best.command_build(site)
	return best

## What cancelling a site gives back: the cost of the part not built yet (all of it before work starts).
func construction_refund(site: Building3D) -> Dictionary:
	var cost := _get_building_cost(site.building_type, site.team)
	var left: float = clampf(1.0 - site.construction_progress / 100.0, 0.0, 1.0)
	var out := {}
	for k in ["wood", "gold", "stone"]:
		out[k] = int(ceil(float(cost.get(k, 0)) * left))
	return out

## Removes an unfinished building of `site.team`, refunds construction_refund(), frees its builders.
func cancel_construction(site: Building3D) -> bool:
	if not is_instance_valid(site) or site.is_completed or site.building_type == Building3D.BuildingType.TOWN_CENTER:
		return false
	var refund := construction_refund(site)
	for k in refund.keys():
		team_resources[site.team][k] += refund[k]
	for u in get_site_builders(site):
		u.command_stop()
	if selected_building == site:
		selected_building = null
		ui_manager.set_selected_entity(null)
	site.die()
	if site.team == 0:
		ui_manager.notify_banner("İnşaat iptal edildi, kaynaklar iade edildi", Color(0.95, 0.85, 0.45))
	return true

## Leaves building placement without placing anything (the "İptal" button, Escape, Android Back).
func cancel_building_placement() -> bool:
	if not is_placing_building:
		return false
	_end_placement()
	SoundManager.play_sound("click")
	return true

func _end_placement() -> void:
	is_placing_building = false
	_ghost_cell = Vector2i(-9999, -9999)
	if ghost_preview != null:
		ghost_preview.visible = false
	if ui_manager != null and ui_manager.has_method("show_placement_bar"):
		ui_manager.show_placement_bar(false)

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

	var civ_cfg = CivData.get_civ(civ_of(team))
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

## Stops the running research of `b` and gives its cost back.
## Cancels the research waiting or running at `b` (refund through the shared queue cancel).
func cancel_research(b: Building3D) -> bool:
	if not is_instance_valid(b):
		return false
	var i: int = b.find_research_index()
	return i >= 0 and cancel_unit_production(b, i)

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
		if is_instance_valid(other) and other.team == team and other.has_queued_research(tech_id):
			return "Araştırılıyor" if other.is_researching and other.current_research_tech == tech_id else "Sırada"
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
	b.start_research(tech_id, float(t["time"]), t["cost"])     # waits behind the building's queue
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
				_apply_age_looks(team, int(e["to"]))
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
			pass                                     # _apply_age_looks -> ui_manager.show_age_up (card + flash)
		else:
			ui_manager.notify_banner("%s GELİŞTİRİLDİ!" % String(t["name"]).to_upper(), Color(0.95, 0.85, 0.3))
	if selected_building != null and is_instance_valid(selected_building):
		ui_manager.set_selected_entity(selected_building)

## Age-up: every building and soldier of the team switches to the new age look, each with a short dust-and-
## sparkle burst; for the player also a gold screen flash and the age chip in the top bar (UIManager3D).
func _apply_age_looks(team: int, age: int) -> void:
	for b in buildings:
		if is_instance_valid(b) and b.team == team and b.building_type != Building3D.BuildingType.FARM:
			b.set_age_look(age)
			if team == 0:
				_age_burst(b.global_position, maxf(b.grid_size.x, b.grid_size.y) * MapGenerator3D.TILE_SIZE * 0.5)
	for u in units:
		if is_instance_valid(u) and u.team == team and u.hp > 0:
			u.set_age_look(age)
			if team == 0 and u.unit_type != Unit3D.UnitType.VILLAGER:
				_age_burst(u.global_position, 0.8)
	if team == 0 and ui_manager.has_method("show_age_up"):
		ui_manager.show_age_up(age)
	age_changed.emit(team, age)

func _age_burst(pos: Vector3, radius: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 18 if radius > 1.0 else 8
	p.lifetime = 1.1
	p.explosiveness = 0.85
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3.UP
	p.spread = 35.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -3.0, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.0
	var dot := SphereMesh.new()                    # small round gold sparks
	dot.radius = 0.07
	dot.height = 0.14
	dot.radial_segments = 6
	dot.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.render_priority = 10
	dot.material = m
	p.mesh = dot
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.92, 0.45, 1.0))
	g.set_color(1, Color(1.0, 0.75, 0.25, 0.0))
	p.color_ramp = g
	add_child(p)
	p.global_position = Vector3(pos.x, FactionArtManager.oblique_sort_y(pos.z) + 1.0, pos.z) if FactionArtManager.top_down() else pos + Vector3(0, 1.2, 0)
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)

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

## Closest living enemy unit or building of `team` within `max_range`. Units come from a spatial grid rebuilt at most
## once per physics tick (every idle soldier, ordered soldier and tower asks this; a full scan of all units per
## asker made the cost grow with the square of the army size).
const ENEMY_GRID_CELL := 4.0
var _enemy_grid := {}
var _enemy_grid_tick := -1

func _enemy_grid_cell(p: Vector3) -> Vector2i:
	return Vector2i(int(floor(p.x / ENEMY_GRID_CELL)), int(floor(p.z / ENEMY_GRID_CELL)))

func _rebuild_enemy_grid() -> void:
	var tick := Engine.get_physics_frames()
	if tick == _enemy_grid_tick:
		return
	_enemy_grid_tick = tick
	_enemy_grid.clear()
	for u in units:
		if is_instance_valid(u) and u.hp > 0:
			var k := _enemy_grid_cell(u.global_position)
			var bucket = _enemy_grid.get(k)
			if bucket == null:
				bucket = []
				_enemy_grid[k] = bucket
			bucket.append(u)

func get_closest_enemy_entity(from_pos: Vector3, team: int, max_range: float) -> Node3D:
	_rebuild_enemy_grid()
	var best_node = null
	var min_dist = max_range * max_range
	var c := _enemy_grid_cell(from_pos)
	var r := int(ceil(max_range / ENEMY_GRID_CELL))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var bucket = _enemy_grid.get(c + Vector2i(dx, dy))
			if bucket == null:
				continue
			for u in bucket:
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
	if u.team != 0:
		kills_count += 1
	units.erase(u)
	selected_units.erase(u)

func _on_building_destroyed(b: Building3D) -> void:
	buildings.erase(b)
	if selected_building == b:
		selected_building = null
		ui_manager.set_selected_entity(null)

	if b.building_type == Building3D.BuildingType.TOWN_CENTER:
		if b.team == 0:
			_game_over(false)
		elif not _team_has_town_center(b.team):
			# that bot is out; the last bot out = victory
			var ai := get_bot_ai(b.team)
			if ai != null:
				ai.eliminated = true
			if bots_alive() == 0:
				_game_over(true)

func _team_has_town_center(team: int) -> bool:
	for o in buildings:
		if is_instance_valid(o) and o.team == team and o.building_type == Building3D.BuildingType.TOWN_CENTER and o.hp > 0 and not o.is_queued_for_deletion():
			return true
	return false

## Bots that still have a Town Center.
func bots_alive() -> int:
	var n := 0
	for ai in bot_ais:
		if is_instance_valid(ai) and not ai.eliminated:
			n += 1
	return n

func _game_over(victory: bool) -> void:
	is_game_active = false
	var dur_sec = int(match_time)
	var dur_str = "%02d:%02d" % [int(float(dur_sec) / 60.0), dur_sec % 60]
	ui_manager.show_game_over(victory, {
		"duration": dur_str,
		"kills": kills_count,
		"trained": trained_count,
		"gathered": gathered_count
	})

## SALDIR / SAVUN arm the next map tap; DUR stops every selected unit at once.
func _on_army_command(mode: String) -> void:
	if mode == "stop":
		pending_army_command = ""
		for u in selected_units:
			if is_instance_valid(u):
				u.command_stop()
		SoundManager.play_sound("click")
		return
	if selected_units.is_empty():
		return
	if pending_army_command == mode:
		pending_army_command = ""                   # second press cancels
		ui_manager.notify_banner("Emir iptal edildi", Color(0.9, 0.85, 0.7))
		return
	pending_army_command = mode                     # the order card stays up until the tap (UIManager3D)
	SoundManager.play_sound("click")

## Ring formation around the ordered point so a group does not stack on one spot.
func _formation_offset(i: int, n: int) -> Vector3:
	if n <= 1:
		return Vector3.ZERO
	var ring := 0 if i == 0 else int(floor(sqrt(float(i))))
	var angle := i * 2.399963                       # golden angle: even spread for any group size
	return Vector3(cos(angle), 0, sin(angle)) * (1.3 * ring + (0.0 if i == 0 else 1.0))

func _issue_army_command(mode: String, clicked_entity: Node3D, ground_pos: Vector3) -> void:
	var soldiers: Array = selected_units.filter(func(u): return is_instance_valid(u) and u.unit_type != Unit3D.UnitType.VILLAGER)
	var others: Array = selected_units.filter(func(u): return is_instance_valid(u) and u.unit_type == Unit3D.UnitType.VILLAGER)
	var target_enemy: Node3D = clicked_entity if (clicked_entity != null and clicked_entity.team != 0 and clicked_entity.hp > 0) else null
	var where: Vector3 = ground_pos
	if clicked_entity != null and target_enemy == null:
		where = clicked_entity.global_position         # defend / attack-move around a friendly building
	if mode == "attack":
		_spawn_click_marker(target_enemy.global_position if target_enemy != null else where, "attack")
		for i in soldiers.size():
			var u: Unit3D = soldiers[i]
			if target_enemy != null:
				u.command_attack_order(target_enemy)
			else:
				u.command_attack_move(where + _formation_offset(i, soldiers.size()))
		SoundManager.play_sound("attack")
	else:
		_spawn_click_marker(where, "move")
		for i in soldiers.size():
			(soldiers[i] as Unit3D).command_defend(where + _formation_offset(i, soldiers.size()))
		SoundManager.play_sound("click")
	for i in others.size():                              # villagers in the group just walk along
		(others[i] as Unit3D).command_move(where + _formation_offset(soldiers.size() + i, soldiers.size() + others.size()))

## Unit spacing: two units may overlap by up to half their body radius, never more. Pairs that are closer are
## pushed apart (each half the way), never onto an unwalkable cell. Spatial hash with 2 m buckets.
const SEPARATION_CELL := 2.0
const SEPARATION_PASSES := 2
var separation_enabled := true   # debug / capture comparison switch only
## One separation tick (all SEPARATION_PASSES passes). Units are read once into flat arrays (position, radius) and
## bucketed once into an integer-keyed grid; the passes then work on the arrays. The old version rebuilt a
## Vector2i-keyed grid every pass and read global_position / get_body_radius() for every pair it looked at, which made
## it the most expensive per-tick system (3.5 ms with 100 units a side on desktop). Behaviour is unchanged: overlap
## above half the radii is pushed apart, never onto a blocked cell (sliding along walls), and a unit walking into an
## arrived crowd at its goal stops (Unit3D.stop_if_crowded_near_goal).
func _separate_units() -> void:
	var live: Array = []
	var px := PackedFloat32Array()
	var py := PackedFloat32Array()
	var pz := PackedFloat32Array()
	var rad := PackedFloat32Array()
	for u in units:
		if is_instance_valid(u) and u.hp > 0 and u.is_inside_tree():
			var p: Vector3 = u.global_position
			live.append(u)
			px.append(p.x)
			py.append(p.y)
			pz.append(p.z)
			rad.append(u.get_body_radius())
	var n := live.size()
	if n < 2:
		return
	var grid := {}
	for i in n:
		var k := _sep_key(floori(px[i] / SEPARATION_CELL), floori(pz[i] / SEPARATION_CELL))
		var b = grid.get(k)
		if b == null:
			b = PackedInt32Array()
		b.append(i)
		grid[k] = b
	for _pass in SEPARATION_PASSES:
		for i in n:
			var cx := floori(px[i] / SEPARATION_CELL)
			var cz := floori(pz[i] / SEPARATION_CELL)
			var ri := rad[i]
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var b = grid.get(_sep_key(cx + dx, cz + dz))
					if b == null:
						continue
					for j in b:
						if j <= i:
							continue                     # each pair once
						var ddx := px[j] - px[i]
						var ddz := pz[j] - pz[i]
						var min_d := 0.5 * (ri + rad[j])
						var d2 := ddx * ddx + ddz * ddz
						if d2 >= min_d * min_d:
							continue
						var u = live[i]
						var o = live[j]
						# crowd arrival: a unit walking to a spot that bumps into one already standing there stops
						u.stop_if_crowded_near_goal(o)
						o.stop_if_crowded_near_goal(u)
						var dist := sqrt(d2)
						var dir := Vector2(ddx, ddz) / dist if dist > 0.001 else Vector2(cos(u.get_instance_id() * 0.7), sin(u.get_instance_id() * 0.7))
						var push := (min_d - dist) * 0.5
						var nu := _nudge_to(px[i], pz[i], -dir * push)
						if nu.x != INF:
							px[i] = nu.x; pz[i] = nu.y
							u.global_position = Vector3(nu.x, py[i], nu.y)
						var no := _nudge_to(px[j], pz[j], dir * push)
						if no.x != INF:
							px[j] = no.x; pz[j] = no.y
							o.global_position = Vector3(no.x, py[j], no.y)
						if nu.x == INF and no.x != INF:
							no = _nudge_to(px[j], pz[j], dir * push)     # u is against a wall: o takes the whole push
							if no.x != INF:
								px[j] = no.x; pz[j] = no.y
								o.global_position = Vector3(no.x, py[j], no.y)
						elif no.x == INF and nu.x != INF:
							nu = _nudge_to(px[i], pz[i], -dir * push)
							if nu.x != INF:
								px[i] = nu.x; pz[i] = nu.y
								u.global_position = Vector3(nu.x, py[i], nu.y)

static func _sep_key(cx: int, cz: int) -> int:
	return (cx + 4096) * 8192 + (cz + 4096)

## Where a unit at (x, z) ends up when pushed by `d`: never on an unwalkable cell; against a wall it slides along it
## (x-only, then z-only). Vector2(INF, INF) when every option is blocked.
func _nudge_to(x: float, z: float, d: Vector2) -> Vector2:
	for step in [d, Vector2(d.x, 0.0), Vector2(0.0, d.y)]:
		if step.length_squared() < 0.000001:
			continue
		var nx: float = x + step.x
		var nz: float = z + step.y
		if map_gen.is_cell_walkable(Vector2i(int(nx / MapGenerator3D.TILE_SIZE), int(nz / MapGenerator3D.TILE_SIZE))):
			return Vector2(nx, nz)
	return Vector2(INF, INF)

func _physics_process(_delta: float) -> void:
	if is_game_active and separation_enabled:
		_separate_units()

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
	control_groups = [[], [], [], []]
	if is_instance_valid(ui_manager) and ui_manager.has_method("hide_hint"):
		ui_manager.hide_hint()
	match_time = 0.0
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
	_end_placement()

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
