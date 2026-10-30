class_name Building
extends StaticBody2D

signal destroyed(building)
signal completed(building)
signal unit_trained(unit_type, team, spawn_pos)

enum BuildingType {
	TOWN_CENTER,
	HOUSE,
	BARRACKS,
	ARCHERY_RANGE,
	STABLE,
	CASTLE,
	TOWER,
	FARM
}

@export var building_type: BuildingType = BuildingType.TOWN_CENTER
@export var team: int = 0
@export var civ_type: CivData.CivType = CivData.CivType.OTTOMANS

var max_hp: float = 1000.0
var hp: float = 1000.0
var armor: float = 5.0
var grid_size: Vector2i = Vector2i(3, 3)
var origin_cell: Vector2i = Vector2i.ZERO

var is_completed: bool = true
var construction_progress: float = 100.0 # 0 to 100

var is_selected: bool = false
var rally_point: Vector2

# Production Queue
var train_queue: Array = []
var current_train_timer: float = 0.0
var current_train_duration: float = 5.0

# Defense / Turret
var shoot_timer: float = 0.0
var shoot_cooldown: float = 1.6
var shoot_range: float = 180.0
var shoot_damage: float = 10.0

var map_gen: MapGenerator = null
var main_game: Node = null

func _ready() -> void:
	rally_point = global_position + Vector2(0, grid_size.y * 16.0 + 20.0)
	queue_redraw()

func setup_building(b_type: BuildingType, t: int, civ: CivData.CivType, cell: Vector2i, map: MapGenerator, game: Node, start_under_construction: bool = false) -> void:
	building_type = b_type
	team = t
	civ_type = civ
	origin_cell = cell
	map_gen = map
	main_game = game
	
	_init_building_stats()
	
	if start_under_construction:
		is_completed = false
		construction_progress = 0.0
		hp = max_hp * 0.1
	else:
		is_completed = true
		construction_progress = 100.0
		hp = max_hp

	rally_point = global_position + Vector2(0, grid_size.y * 16.0 + 25.0)
	queue_redraw()

func _init_building_stats() -> void:
	var civ_cfg = CivData.get_civ(civ_type)
	
	match building_type:
		BuildingType.TOWN_CENTER:
			grid_size = Vector2i(3, 3)
			max_hp = 2400.0
			armor = 6.0
			shoot_range = 210.0
			shoot_damage = 12.0
		BuildingType.HOUSE:
			grid_size = Vector2i(2, 2)
			max_hp = 550.0
			armor = 2.0
		BuildingType.BARRACKS:
			grid_size = Vector2i(3, 3)
			max_hp = 1200.0
			armor = 4.0
		BuildingType.ARCHERY_RANGE:
			grid_size = Vector2i(3, 3)
			max_hp = 1200.0
			armor = 4.0
		BuildingType.STABLE:
			grid_size = Vector2i(3, 3)
			max_hp = 1300.0
			armor = 4.0
		BuildingType.CASTLE:
			grid_size = Vector2i(4, 4)
			max_hp = 4200.0
			armor = 10.0
			shoot_range = 240.0
			shoot_damage = 18.0
			shoot_cooldown = 1.0
		BuildingType.TOWER:
			grid_size = Vector2i(2, 2)
			max_hp = 1000.0
			armor = 5.0
			shoot_range = 190.0
			shoot_damage = 14.0
			shoot_cooldown = 1.4
		BuildingType.FARM:
			grid_size = Vector2i(2, 2)
			max_hp = 400.0
			armor = 0.0

	# Apply Civ modifiers
	if civ_cfg.has("building_hp_mult"):
		max_hp *= civ_cfg["building_hp_mult"]
	if civ_cfg.has("tower_damage_mult") and (building_type == BuildingType.TOWER or building_type == BuildingType.TOWN_CENTER):
		shoot_damage *= civ_cfg["tower_damage_mult"]

func _process(delta: float) -> void:
	if not is_completed:
		return
		
	# Defense Shooting
	if can_shoot():
		if shoot_timer > 0.0:
			shoot_timer -= delta
		else:
			_check_and_shoot_enemies()

	# Production Queue
	if train_queue.size() > 0:
		current_train_timer += delta
		if current_train_timer >= current_train_duration:
			var trained = train_queue.pop_front()
			current_train_timer = 0.0
			_spawn_unit(trained)
			if train_queue.size() > 0:
				_setup_next_train()

func can_shoot() -> bool:
	return building_type in [BuildingType.TOWN_CENTER, BuildingType.TOWER, BuildingType.CASTLE]

func _check_and_shoot_enemies() -> void:
	if main_game == null:
		return
	var target = main_game.get_closest_enemy_entity(global_position, team, shoot_range)
	if target != null:
		shoot_timer = shoot_cooldown
		SoundManager.play_sound("shoot")
		main_game.spawn_projectile(global_position + Vector2(0, -10), target, shoot_damage, team, false)

func queue_unit_production(u_type: Unit.UnitType, duration: float) -> bool:
	var civ_cfg = CivData.get_civ(civ_type)
	var final_duration = duration * civ_cfg.get("train_speed_mult", 1.0)
	
	train_queue.append({"type": u_type, "duration": final_duration})
	if train_queue.size() == 1:
		current_train_timer = 0.0
		current_train_duration = final_duration
	return true

func _setup_next_train() -> void:
	if train_queue.size() > 0:
		current_train_duration = train_queue[0]["duration"]
		current_train_timer = 0.0

func _spawn_unit(item: Dictionary) -> void:
	var u_type = item["type"]
	unit_trained.emit(u_type, team, rally_point)
	SoundManager.play_sound("train")

func contribute_construction(amt: float) -> void:
	if is_completed:
		return
	construction_progress += amt
	hp = max_hp * clamp(construction_progress / 100.0, 0.1, 1.0)
	if construction_progress >= 100.0:
		construction_progress = 100.0
		is_completed = true
		hp = max_hp
		completed.emit(self)
		SoundManager.play_sound("build")
	queue_redraw()

func take_damage(amount: float, _attacker_team: int) -> void:
	var actual_dmg = max(1.0, amount - armor)
	hp -= actual_dmg
	if hp <= 0:
		hp = 0
		die()
	queue_redraw()

func die() -> void:
	destroyed.emit(self)
	if map_gen != null:
		map_gen.unregister_building_cells(origin_cell, grid_size)
	SoundManager.play_sound("hit")
	queue_free()

func set_selected(sel: bool) -> void:
	is_selected = sel
	queue_redraw()

func _draw() -> void:
	var civ_cfg = CivData.get_civ(civ_type)
	var team_color = Color(0.18, 0.52, 0.95) if team == 0 else Color(0.92, 0.22, 0.22)
	var civ_flag = civ_cfg.get("flag_color", team_color)
	var _civ_accent = civ_cfg.get("accent_color", Color(1, 1, 1))
	
	var w = grid_size.x * MapGenerator.TILE_SIZE
	var h = grid_size.y * MapGenerator.TILE_SIZE
	var half_w = w * 0.5
	var half_h = h * 0.5
	var base_rect = Rect2(-half_w, -half_h, w, h)
	
	# Selection border
	if is_selected:
		draw_rect(base_rect.grow(4.0), Color(0.2, 0.95, 0.3, 0.8), false, 2.5)
		# Draw rally line
		if rally_point != Vector2.ZERO:
			var local_rally = to_local(rally_point)
			draw_dashed_line(Vector2.ZERO, local_rally, Color(1, 0.9, 0.2, 0.7), 2.0, 6.0)
			draw_circle(local_rally, 4.0, Color(1, 0.9, 0.2))

	# Under Construction Visuals
	if not is_completed:
		# Wooden scaffolding frame
		draw_rect(base_rect, Color(0.35, 0.25, 0.15, 0.6))
		draw_rect(base_rect, Color(0.5, 0.35, 0.2), false, 2.0)
		draw_line(base_rect.position, base_rect.end, Color(0.5, 0.35, 0.2), 2.0)
		draw_line(Vector2(base_rect.position.x, base_rect.end.y), Vector2(base_rect.end.x, base_rect.position.y), Color(0.5, 0.35, 0.2), 2.0)
		
		# Construction progress bar
		var prog_w = w * 0.8
		var prog_h = 6.0
		var prog_rect = Rect2(-prog_w * 0.5, -half_h - 14.0, prog_w, prog_h)
		draw_rect(prog_rect, Color(0.1, 0.1, 0.1, 0.8))
		draw_rect(Rect2(prog_rect.position.x, prog_rect.position.y, prog_w * (construction_progress / 100.0), prog_h), Color(0.95, 0.75, 0.2))
		draw_rect(prog_rect, Color(0, 0, 0), false, 1.0)
		return

	# Completed Building Renderings
	match building_type:
		BuildingType.TOWN_CENTER:
			# Sturdy Stone Keep with 4 corner towers and grand archway
			draw_rect(base_rect, Color(0.55, 0.55, 0.58)) # Stone walls
			draw_rect(base_rect, Color(0.3, 0.3, 0.33), false, 2.0)
			# Roof shingles
			var roof_poly = PackedVector2Array([
				Vector2(-half_w, -half_h), Vector2(0, -half_h - 18),
				Vector2(half_w, -half_h), Vector2(0, -half_h * 0.3)
			])
			draw_colored_polygon(roof_poly, Color(0.68, 0.28, 0.22))
			# Arched doorway
			draw_rect(Rect2(-10, half_h - 22, 20, 22), Color(0.2, 0.15, 0.1))
			draw_arc(Vector2(0, half_h - 22), 10.0, PI, TAU, 16, Color(0.2, 0.15, 0.1), 3.0)
			# Team Flag Banners on both sides
			draw_line(Vector2(-half_w + 6, -half_h), Vector2(-half_w + 6, -half_h - 16), Color(0.3, 0.2, 0.1), 2.0)
			draw_polygon(PackedVector2Array([Vector2(-half_w + 6, -half_h - 16), Vector2(-half_w + 20, -half_h - 12), Vector2(-half_w + 6, -half_h - 8)]), [civ_flag])

		BuildingType.HOUSE:
			# Timber-frame cottage with thatched roof
			draw_rect(base_rect, Color(0.8, 0.75, 0.65)) # Wattle and daub wall
			draw_rect(base_rect, Color(0.38, 0.25, 0.15), false, 2.0)
			# Cross timbers
			draw_line(base_rect.position, base_rect.end, Color(0.38, 0.25, 0.15), 1.5)
			# Thatched Roof
			var roof = PackedVector2Array([
				Vector2(-half_w - 4, -half_h), Vector2(0, -half_h - 12),
				Vector2(half_w + 4, -half_h), Vector2(0, -half_h * 0.2)
			])
			draw_colored_polygon(roof, Color(0.72, 0.58, 0.32))
			draw_rect(Rect2(-5, half_h - 14, 10, 14), Color(0.35, 0.2, 0.1))

		BuildingType.BARRACKS:
			# Military training camp with weapon racks & training dummy
			draw_rect(base_rect, Color(0.5, 0.48, 0.45))
			draw_rect(base_rect, Color(0.3, 0.28, 0.25), false, 2.0)
			# Red/Team military roof
			draw_rect(Rect2(-half_w + 4, -half_h + 4, w - 8, half_h), civ_flag)
			# Crossed swords symbol on wall
			draw_line(Vector2(-8, 4), Vector2(8, 16), Color(0.9, 0.9, 0.9), 2.5)
			draw_line(Vector2(-8, 16), Vector2(8, 4), Color(0.9, 0.9, 0.9), 2.5)
			# Training banner
			draw_line(Vector2(0, -half_h), Vector2(0, -half_h - 14), Color(0.2, 0.2, 0.2), 2.0)
			draw_polygon(PackedVector2Array([Vector2(0, -half_h - 14), Vector2(16, -half_h - 10), Vector2(0, -half_h - 6)]), [team_color])

		BuildingType.ARCHERY_RANGE:
			# Wooden pavilion with archery targets
			draw_rect(base_rect, Color(0.6, 0.45, 0.3))
			draw_rect(base_rect, Color(0.35, 0.22, 0.12), false, 2.0)
			# Archery targets (circles)
			draw_circle(Vector2(-12, 6), 7.0, Color(0.9, 0.85, 0.75))
			draw_circle(Vector2(-12, 6), 4.5, Color(0.9, 0.2, 0.2))
			draw_circle(Vector2(-12, 6), 2.0, Color(0.95, 0.8, 0.1))
			# Quiver & Bow emblem
			draw_arc(Vector2(12, 6), 9.0, -1.2, 1.2, 16, Color(0.2, 0.2, 0.2), 2.0)

		BuildingType.STABLE:
			# Open barn with hay bales & horse stalls
			draw_rect(base_rect, Color(0.55, 0.38, 0.22))
			draw_rect(base_rect, Color(0.3, 0.2, 0.1), false, 2.0)
			# Hay bale
			draw_rect(Rect2(-14, 4, 12, 10), Color(0.9, 0.8, 0.3))
			# Horseshoe symbol
			draw_arc(Vector2(10, 8), 6.0, PI * 0.2, PI * 1.8, 16, Color(0.85, 0.85, 0.9), 2.5)

		BuildingType.CASTLE:
			# Imposing stone citadel with 4 battlement towers & flags
			draw_rect(base_rect, Color(0.42, 0.42, 0.45))
			draw_rect(base_rect, Color(0.22, 0.22, 0.25), false, 3.0)
			# Corner towers
			var tw_size = 20.0
			for corner in [Vector2(-half_w, -half_h), Vector2(half_w - tw_size, -half_h), Vector2(-half_w, half_h - tw_size), Vector2(half_w - tw_size, half_h - tw_size)]:
				draw_rect(Rect2(corner.x, corner.y, tw_size, tw_size), Color(0.35, 0.35, 0.38))
				draw_rect(Rect2(corner.x, corner.y, tw_size, tw_size), Color(0.18, 0.18, 0.2), false, 1.5)
			# Great Portcullis Gate
			draw_rect(Rect2(-12, half_h - 26, 24, 26), Color(0.15, 0.12, 0.1))
			# Tall Center Banner
			draw_line(Vector2(0, -half_h), Vector2(0, -half_h - 24), Color(0.1, 0.1, 0.1), 3.0)
			draw_polygon(PackedVector2Array([Vector2(0, -half_h - 24), Vector2(24, -half_h - 18), Vector2(0, -half_h - 12)]), [civ_flag])

		BuildingType.TOWER:
			# Stone arrow tower with parapet
			draw_rect(base_rect, Color(0.52, 0.52, 0.55))
			draw_rect(base_rect, Color(0.3, 0.3, 0.32), false, 2.0)
			# Top battlements
			draw_rect(Rect2(-half_w - 2, -half_h - 8, w + 4, 8), Color(0.4, 0.4, 0.44))
			# Arrow slit
			draw_rect(Rect2(-2, -half_h + 8, 4, 12), Color(0.1, 0.1, 0.1))
			# Flag
			draw_line(Vector2(half_w - 4, -half_h - 8), Vector2(half_w - 4, -half_h - 20), Color(0.2, 0.2, 0.2), 2.0)
			draw_polygon(PackedVector2Array([Vector2(half_w - 4, -half_h - 20), Vector2(half_w + 10, -half_h - 16), Vector2(half_w - 4, -half_h - 12)]), [civ_flag])

		BuildingType.FARM:
			# Cultivated tilled soil with rows of wheat/crops
			draw_rect(base_rect, Color(0.42, 0.3, 0.18))
			draw_rect(base_rect, Color(0.28, 0.18, 0.1), false, 2.0)
			# Crop furrows
			for row in range(-1, 2):
				var ry = row * 8.0
				draw_line(Vector2(-half_w + 4, ry), Vector2(half_w - 4, ry), Color(0.85, 0.75, 0.25), 3.0)

	# Health Bar & Training Bar
	if is_selected or hp < max_hp or train_queue.size() > 0:
		var bar_w = w * 0.9
		var bar_h = 4.0
		var bar_x = -bar_w * 0.5
		var bar_y = -half_h - 10.0
		
		# Health
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.1, 0.1, 0.1, 0.8))
		var hp_pct = clamp(hp / max_hp, 0.0, 1.0)
		var fill_col = Color(0.2, 0.85, 0.2) if hp_pct > 0.5 else (Color(0.9, 0.8, 0.1) if hp_pct > 0.25 else Color(0.9, 0.2, 0.2))
		draw_rect(Rect2(bar_x, bar_y, bar_w * hp_pct, bar_h), fill_col)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0, 0, 0, 0.6), false, 1.0)
		
		# Training progress bar if active
		if train_queue.size() > 0 and current_train_duration > 0:
			var t_bar_y = bar_y - 6.0
			draw_rect(Rect2(bar_x, t_bar_y, bar_w, 3.0), Color(0.1, 0.1, 0.1, 0.8))
			var t_pct = clamp(current_train_timer / current_train_duration, 0.0, 1.0)
			draw_rect(Rect2(bar_x, t_bar_y, bar_w * t_pct, 3.0), Color(0.2, 0.6, 1.0))
