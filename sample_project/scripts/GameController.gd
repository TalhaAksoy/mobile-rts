class_name GameController
extends Node2D

@export var player_civ: CivData.CivType = CivData.CivType.OTTOMANS
@export var enemy_civ: CivData.CivType = CivData.CivType.BYZANTINES
@export var selected_map_type: CivData.MapType = CivData.MapType.FOREST_VALLEY
@export var auto_start_for_testing: bool = false

@onready var map_gen: MapGenerator = $MapGenerator
@onready var camera: MobileCamera = $MobileCamera
@onready var ui_manager: UIManager = $UIManager
@onready var enemy_ai: EnemyAI = $EnemyAI

# Resource tracking [team 0 = player, team 1 = enemy]
var team_resources: Dictionary = {
	0: {"food": 200, "wood": 200, "gold": 100},
	1: {"food": 200, "wood": 200, "gold": 100}
}

var units: Array[Unit] = []
var buildings: Array[Building] = []

var selected_units: Array[Unit] = []
var selected_building: Building = null

var is_game_active: bool = false
var game_start_time: float = 0.0
var kills_count: int = 0
var trained_count: int = 0
var gathered_count: int = 0

# Building placement mode
var is_placing_building: bool = false
var placing_building_type: Building.BuildingType = Building.BuildingType.HOUSE
var ghost_preview: Node2D = null

func _ready() -> void:
	# Forward any legacy Main.tscn execution to the active 2.5D/3D game scene
	call_deferred("_redirect_to_main3d")
	return

func _redirect_to_main3d() -> void:
	get_tree().change_scene_to_file("res://scenes/Main3D.tscn")
	# Add SoundManager instance if not in tree
	if SoundManager.instance == null:
		var sm = SoundManager.new()
		add_child(sm)

	# Connect UI Signals
	ui_manager.start_game_requested.connect(_on_start_game_requested)
	ui_manager.build_selected.connect(_on_build_selected)
	ui_manager.train_unit_requested.connect(_on_train_unit_requested)
	ui_manager.select_all_military_requested.connect(_on_select_all_military)
	ui_manager.jump_to_base_requested.connect(_on_jump_to_base)
	ui_manager.find_idle_villager_requested.connect(_on_find_idle_villager)
	ui_manager.toggle_speed_requested.connect(_on_toggle_speed)
	ui_manager.restart_requested.connect(_on_restart_requested)

	# Initialize preview node for building placement
	ghost_preview = Node2D.new()
	ghost_preview.visible = false
	ghost_preview.draw.connect(_on_ghost_preview_draw)
	add_child(ghost_preview)

	var minimap = ui_manager.get_node_or_null("HUDRoot/Minimap")
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
	# Clean up previous entities
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
	
	# Reset resources
	team_resources = {
		0: {"food": 200, "wood": 200, "gold": 100},
		1: {"food": 200, "wood": 200, "gold": 100}
	}
	kills_count = 0
	trained_count = 0
	gathered_count = 0
	game_start_time = Time.get_ticks_msec() / 1000.0

	# 1. Generate procedural map
	map_gen.generate(selected_map_type)
	
	# Configure camera bounds
	camera.setup_bounds(MapGenerator.MAP_WIDTH * MapGenerator.TILE_SIZE, MapGenerator.MAP_HEIGHT * MapGenerator.TILE_SIZE)

	# 2. Spawn Player Base (South)
	var player_base_cell = map_gen.world_to_cell(map_gen.player_start_pos)
	var _player_tc = place_building(Building.BuildingType.TOWN_CENTER, 0, player_base_cell - Vector2i(1, 1), false)
	
	# Spawn Starting Villagers
	var p_civ_cfg = CivData.get_civ(player_civ)
	var start_vills = 3 + p_civ_cfg.get("start_villager_bonus", 0)
	for i in range(start_vills):
		var offset = Vector2(cos(i * 1.5) * 45.0, sin(i * 1.5) * 45.0 + 35.0)
		spawn_unit(Unit.UnitType.VILLAGER, 0, map_gen.player_start_pos + offset)

	# 3. Spawn Enemy Base (North)
	var enemy_base_cell = map_gen.world_to_cell(map_gen.enemy_start_pos)
	var _enemy_tc = place_building(Building.BuildingType.TOWN_CENTER, 1, enemy_base_cell - Vector2i(1, 1), false)
	
	for i in range(3):
		var offset = Vector2(cos(i * 1.5) * 45.0, sin(i * 1.5) * 45.0 - 35.0)
		spawn_unit(Unit.UnitType.VILLAGER, 1, map_gen.enemy_start_pos + offset)

	# Setup AI
	enemy_ai.setup_ai(enemy_civ, map_gen, self)

	# Jump camera to player base
	camera.jump_to(map_gen.player_start_pos, false)

	is_game_active = true
	ui_manager.menu_root.visible = false
	ui_manager.hud_root.visible = true
	ui_manager.game_over_modal.visible = false
	
	# Update UI civ info
	ui_manager.civ_label.text = "%s %s" % [p_civ_cfg.get("icon", "⚔️"), p_civ_cfg.get("name", "Osmanlılar")]
	_update_hud()

func _process(_delta: float) -> void:
	if not is_game_active:
		return
		
	_update_hud()
	
	# Update ghost preview if in building placement mode
	if is_placing_building:
		var mouse_pos = get_global_mouse_position()
		var cell = map_gen.world_to_cell(mouse_pos)
		ghost_preview.global_position = Vector2(cell.x * MapGenerator.TILE_SIZE, cell.y * MapGenerator.TILE_SIZE)
		ghost_preview.queue_redraw()

func _update_hud() -> void:
	var res = team_resources[0]
	var pop = get_team_population(0)
	var max_pop = get_team_max_population(0)
	ui_manager.update_resources(res["food"], res["wood"], res["gold"], pop, max_pop)
	
	# Count idle villagers
	var idle_vills = 0
	for u in units:
		if is_instance_valid(u) and u.team == 0 and u.unit_type == Unit.UnitType.VILLAGER and u.state == Unit.State.IDLE:
			idle_vills += 1
	ui_manager.update_idle_villager_count(idle_vills)

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_pos = get_global_mouse_position()
		
		# If in building placement mode, attempt place
		if is_placing_building:
			_attempt_place_building_at_mouse(click_pos)
			return
			
		# Handle RTS selection & commands
		_handle_world_click(click_pos)

func _handle_world_click(pos: Vector2) -> void:
	var clicked_entity = _get_entity_at_position(pos)
	var cell = map_gen.world_to_cell(pos)
	
	if selected_units.size() > 0:
		# If user tapped an enemy -> Attack!
		if clicked_entity != null and clicked_entity.team != 0:
			for u in selected_units:
				u.command_attack(clicked_entity)
			SoundManager.play_sound("attack")
			return
			
		# If user tapped ally unfinished building -> Build!
		if clicked_entity is Building and clicked_entity.team == 0 and not clicked_entity.is_completed:
			for u in selected_units:
				if u.unit_type == Unit.UnitType.VILLAGER:
					u.command_build(clicked_entity)
			SoundManager.play_sound("build")
			return
			
		# If villager selected and tapped resource -> Gather!
		var has_villager = false
		for u in selected_units:
			if u.unit_type == Unit.UnitType.VILLAGER:
				has_villager = true
				break
				
		if has_villager:
			if cell in map_gen.trees:
				for u in selected_units:
					if u.unit_type == Unit.UnitType.VILLAGER:
						u.command_gather(cell, "wood")
				SoundManager.play_sound("click")
				return
			elif cell in map_gen.gold_mines:
				for u in selected_units:
					if u.unit_type == Unit.UnitType.VILLAGER:
						u.command_gather(cell, "gold")
				SoundManager.play_sound("click")
				return
			elif cell in map_gen.berry_bushes:
				for u in selected_units:
					if u.unit_type == Unit.UnitType.VILLAGER:
						u.command_gather(cell, "food")
				SoundManager.play_sound("click")
				return

		# If clicked ground -> Move selected units!
		if clicked_entity == null:
			for i in range(selected_units.size()):
				var u = selected_units[i]
				var formation_offset = Vector2.ZERO
				if selected_units.size() > 1:
					var angle = i * (TAU / selected_units.size())
					formation_offset = Vector2(cos(angle), sin(angle)) * 24.0
				u.command_move(pos + formation_offset)
			SoundManager.play_sound("click")
			return

	# Otherwise, selection logic
	_clear_selection()
	
	if clicked_entity is Unit:
		selected_units.append(clicked_entity)
		clicked_entity.set_selected(true)
		ui_manager.set_selected_entity(clicked_entity)
		SoundManager.play_sound("click")
	elif clicked_entity is Building:
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

func _get_entity_at_position(pos: Vector2) -> Node2D:
	# Check units first (smaller collision)
	for u in units:
		if is_instance_valid(u) and u.global_position.distance_to(pos) < 22.0:
			return u
			
	# Check buildings
	for b in buildings:
		if is_instance_valid(b):
			var w = b.grid_size.x * MapGenerator.TILE_SIZE
			var h = b.grid_size.y * MapGenerator.TILE_SIZE
			var rect = Rect2(b.global_position - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
			if rect.has_point(pos):
				return b
				
	return null

func spawn_unit(u_type: Unit.UnitType, team: int, pos: Vector2) -> Unit:
	var civ = player_civ if team == 0 else enemy_civ
	var unit = Unit.new()
	unit.global_position = pos
	add_child(unit)
	unit.setup_unit(u_type, team, civ, map_gen, self)
	unit.died.connect(_on_unit_died)
	units.append(unit)
	if team == 0:
		trained_count += 1
	return unit

func place_building(b_type: Building.BuildingType, team: int, cell: Vector2i, under_construction: bool = false) -> Building:
	var civ = player_civ if team == 0 else enemy_civ
	var b = Building.new()
	var b_size = _get_building_size(b_type)
	var world_center = Vector2((cell.x + b_size.x * 0.5) * MapGenerator.TILE_SIZE, (cell.y + b_size.y * 0.5) * MapGenerator.TILE_SIZE)
	
	b.global_position = world_center
	add_child(b)
	b.setup_building(b_type, team, civ, cell, map_gen, self, under_construction)
	b.destroyed.connect(_on_building_destroyed)
	b.unit_trained.connect(_on_building_unit_trained)
	
	map_gen.register_building_cells(cell, b_size, b)
	buildings.append(b)
	return b

func _get_building_size(b_type: Building.BuildingType) -> Vector2i:
	match b_type:
		Building.BuildingType.TOWN_CENTER: return Vector2i(3, 3)
		Building.BuildingType.HOUSE: return Vector2i(2, 2)
		Building.BuildingType.BARRACKS: return Vector2i(3, 3)
		Building.BuildingType.ARCHERY_RANGE: return Vector2i(3, 3)
		Building.BuildingType.STABLE: return Vector2i(3, 3)
		Building.BuildingType.CASTLE: return Vector2i(4, 4)
		Building.BuildingType.TOWER: return Vector2i(2, 2)
		Building.BuildingType.FARM: return Vector2i(2, 2)
		_: return Vector2i(2, 2)

func _get_building_cost(b_type: Building.BuildingType) -> Dictionary:
	var civ_cfg = CivData.get_civ(player_civ)
	var cost_mult = civ_cfg.get("building_cost_mult", 1.0)
	
	var cost = {"wood": 0, "gold": 0}
	match b_type:
		Building.BuildingType.TOWN_CENTER: cost = {"wood": 275, "gold": 0}
		Building.BuildingType.HOUSE: cost = {"wood": 30, "gold": 0}
		Building.BuildingType.BARRACKS: cost = {"wood": 150, "gold": 0}
		Building.BuildingType.ARCHERY_RANGE: cost = {"wood": 150, "gold": 0}
		Building.BuildingType.STABLE: cost = {"wood": 175, "gold": 0}
		Building.BuildingType.CASTLE: cost = {"wood": 350, "gold": 250}
		Building.BuildingType.TOWER: cost = {"wood": 125, "gold": 50}
		Building.BuildingType.FARM: cost = {"wood": 60, "gold": 0}

	cost["wood"] = int(cost["wood"] * cost_mult)
	return cost

func _on_build_selected(b_type: Building.BuildingType) -> void:
	var cost = _get_building_cost(b_type)
	if team_resources[0]["wood"] < cost["wood"] or team_resources[0]["gold"] < cost["gold"]:
		# Not enough resources
		SoundManager.play_sound("hit")
		return
		
	is_placing_building = true
	placing_building_type = b_type
	ghost_preview.visible = true
	ui_manager.build_panel.visible = false

func _attempt_place_building_at_mouse(pos: Vector2) -> void:
	var cell = map_gen.world_to_cell(pos)
	var size = _get_building_size(placing_building_type)
	
	# Verify area clear
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
	
	var new_b = place_building(placing_building_type, 0, cell, true)
	is_placing_building = false
	ghost_preview.visible = false
	
	# Command selected villager to build it
	for u in selected_units:
		if u.unit_type == Unit.UnitType.VILLAGER:
			u.command_build(new_b)
			break
			
	SoundManager.play_sound("build")

func _on_ghost_preview_draw() -> void:
	if not is_placing_building:
		return
	var size = _get_building_size(placing_building_type)
	var w = size.x * MapGenerator.TILE_SIZE
	var h = size.y * MapGenerator.TILE_SIZE
	ghost_preview.draw_rect(Rect2(0, 0, w, h), Color(0.2, 0.9, 0.3, 0.45))
	ghost_preview.draw_rect(Rect2(0, 0, w, h), Color(0.2, 0.95, 0.3), false, 2.0)

func _on_train_unit_requested(u_type: Unit.UnitType) -> void:
	if selected_building == null or selected_building.team != 0:
		return
	try_train_unit(selected_building, u_type, 0)

func try_train_unit(b: Building, u_type: Unit.UnitType, team: int) -> bool:
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
		Unit.UnitType.VILLAGER:
			food_cost = 50
			duration = 3.5
		Unit.UnitType.SWORDSMAN:
			food_cost = 60
			gold_cost = 20
			duration = 4.5
		Unit.UnitType.SPEARMAN:
			food_cost = 50
			wood_cost = 35
			duration = 4.0
		Unit.UnitType.ARCHER:
			wood_cost = 45
			gold_cost = 40
			duration = 5.0
		Unit.UnitType.CAVALRY:
			food_cost = 75
			gold_cost = 60
			duration = 6.0
		_: # Unique Unit
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

func _on_building_unit_trained(u_type: Unit.UnitType, team: int, spawn_pos: Vector2) -> void:
	spawn_unit(u_type, team, spawn_pos)

func spawn_projectile(start: Vector2, target: Node2D, dmg: float, team: int, bullet: bool = false) -> void:
	var proj = Projectile.new()
	add_child(proj)
	proj.setup(start, target, dmg, team, bullet)

func deposit_resource(team: int, type: String, amount: int) -> void:
	if team_resources.has(team) and team_resources[team].has(type):
		team_resources[team][type] += amount
		if team == 0:
			gathered_count += amount

func get_closest_dropoff(from_pos: Vector2, team: int) -> Building:
	var best_b = null
	var min_dist = 999999.0
	for b in buildings:
		if is_instance_valid(b) and b.team == team and b.is_completed and b.building_type == Building.BuildingType.TOWN_CENTER:
			var d = from_pos.distance_squared_to(b.global_position)
			if d < min_dist:
				min_dist = d
				best_b = b
	return best_b

func get_closest_enemy_entity(from_pos: Vector2, team: int, max_range: float) -> Node2D:
	var best_node = null
	var min_dist = max_range * max_range
	
	# Check units
	for u in units:
		if is_instance_valid(u) and u.team != team and u.hp > 0:
			var d = from_pos.distance_squared_to(u.global_position)
			if d < min_dist:
				min_dist = d
				best_node = u
				
	# Check buildings
	for b in buildings:
		if is_instance_valid(b) and b.team != team and b.hp > 0:
			var d = from_pos.distance_squared_to(b.global_position)
			if d < min_dist:
				min_dist = d
				best_node = b
				
	return best_node

func get_team_units(team: int) -> Array[Unit]:
	var res: Array[Unit] = []
	for u in units:
		if is_instance_valid(u) and u.team == team:
			res.append(u)
	return res

func get_team_buildings(team: int) -> Array[Building]:
	var res: Array[Building] = []
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
	var max_pop = 10 # Base Town Center pop
	for b in buildings:
		if is_instance_valid(b) and b.team == team and b.is_completed:
			if b.building_type == Building.BuildingType.HOUSE:
				max_pop += 5
			elif b.building_type == Building.BuildingType.TOWN_CENTER:
				max_pop += 5
	return min(max_pop, 70) # 70 pop cap for smooth mobile performance

func _on_unit_died(u: Unit) -> void:
	if u.team == 1:
		kills_count += 1
	units.erase(u)
	selected_units.erase(u)

func _on_building_destroyed(b: Building) -> void:
	buildings.erase(b)
	if selected_building == b:
		selected_building = null
		ui_manager.set_selected_entity(null)
		
	# Check Win/Loss Condition
	if b.building_type == Building.BuildingType.TOWN_CENTER:
		if b.team == 1:
			_game_over(true) # Player Victory!
		elif b.team == 0:
			_game_over(false) # Player Defeat!

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
		if is_instance_valid(u) and u.team == 0 and u.unit_type != Unit.UnitType.VILLAGER:
			selected_units.append(u)
			u.set_selected(true)
	if selected_units.size() > 0:
		ui_manager.set_selected_entity(selected_units[0])
		SoundManager.play_sound("click")

func _on_jump_to_base() -> void:
	camera.jump_to(map_gen.player_start_pos)

func _on_find_idle_villager() -> void:
	for u in units:
		if is_instance_valid(u) and u.team == 0 and u.unit_type == Unit.UnitType.VILLAGER and u.state == Unit.State.IDLE:
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
		ui_manager.speed_btn.text = "⏩ 2x"
	else:
		Engine.time_scale = 1.0
		ui_manager.speed_btn.text = "▶️ 1x"

func _on_restart_requested() -> void:
	Engine.time_scale = 1.0
	start_match()
