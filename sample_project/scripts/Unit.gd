class_name Unit
extends CharacterBody2D

signal died(unit)
signal selected_changed(unit, is_sel)

enum UnitType {
	VILLAGER,
	SWORDSMAN,
	ARCHER,
	SPEARMAN,
	CAVALRY,
	JANISSARY,
	CATAPHRACT,
	LONGBOWMAN,
	PALADIN,
	MANGUDAI,
	TEUTONIC_KNIGHT,
	SAMURAI,
	MAMELUKE,
	BERSERKER,
	CHUKONU
}

enum State {
	IDLE,
	MOVING,
	ATTACKING,
	GATHERING,
	BUILDING,
	RETURNING_RESOURCES
}

@export var unit_type: UnitType = UnitType.VILLAGER
@export var team: int = 0 # 0 = Player, 1 = Enemy
@export var civ_type: CivData.CivType = CivData.CivType.OTTOMANS

var max_hp: float = 100.0
var hp: float = 100.0
var attack_dmg: float = 10.0
var armor: float = 0.0
var attack_range: float = 30.0
var attack_speed: float = 1.0 # Attacks per sec
var move_speed: float = 110.0

var state: State = State.IDLE
var is_selected: bool = false

# Pathfinding & target
var current_path: PackedVector2Array = []
var path_idx: int = 0
var target_entity: Node2D = null # Target unit or building
var target_cell: Vector2i = Vector2i(-1, -1)
var resource_type: String = "" # "wood", "gold", "food"
var carried_resource: int = 0
var max_carry: int = 15

# Combat & animation
var attack_timer: float = 0.0
var swing_progress: float = 0.0
var walk_timer: float = 0.0
var regen_rate: float = 0.0

var map_gen: MapGenerator = null
var main_game: Node = null

# Floating numbers
var float_texts: Array = []

func _ready() -> void:
	_init_stats()
	queue_redraw()

func setup_unit(u_type: UnitType, t: int, civ: CivData.CivType, map: MapGenerator, game: Node) -> void:
	unit_type = u_type
	team = t
	civ_type = civ
	map_gen = map
	main_game = game
	_init_stats()

func _init_stats() -> void:
	var civ_cfg = CivData.get_civ(civ_type)
	
	match unit_type:
		UnitType.VILLAGER:
			max_hp = 50.0
			attack_dmg = 4.0
			attack_range = 25.0
			attack_speed = 1.2
			move_speed = 105.0
			armor = 0.0
		UnitType.SWORDSMAN:
			max_hp = 110.0
			attack_dmg = 12.0
			attack_range = 28.0
			attack_speed = 1.0
			move_speed = 100.0
			armor = 2.0
		UnitType.ARCHER:
			max_hp = 60.0
			attack_dmg = 8.0
			attack_range = 160.0
			attack_speed = 0.9
			move_speed = 110.0
			armor = 0.0
		UnitType.SPEARMAN:
			max_hp = 90.0
			attack_dmg = 8.0
			attack_range = 36.0
			attack_speed = 1.1
			move_speed = 105.0
			armor = 1.0
		UnitType.CAVALRY:
			max_hp = 160.0
			attack_dmg = 14.0
			attack_range = 32.0
			attack_speed = 0.95
			move_speed = 165.0
			armor = 2.0
		# Unique Units
		UnitType.JANISSARY:
			max_hp = 85.0
			attack_dmg = 24.0
			attack_range = 190.0
			attack_speed = 0.65
			move_speed = 105.0
			armor = 2.0
		UnitType.CATAPHRACT:
			max_hp = 220.0
			attack_dmg = 18.0
			attack_range = 35.0
			attack_speed = 1.0
			move_speed = 145.0
			armor = 5.0
		UnitType.LONGBOWMAN:
			max_hp = 65.0
			attack_dmg = 11.0
			attack_range = 230.0 # Extreme range
			attack_speed = 1.1
			move_speed = 105.0
			armor = 0.0
		UnitType.PALADIN:
			max_hp = 260.0
			attack_dmg = 20.0
			attack_range = 35.0
			attack_speed = 0.9
			move_speed = 150.0
			armor = 4.0
		UnitType.MANGUDAI:
			max_hp = 95.0
			attack_dmg = 12.0
			attack_range = 160.0
			attack_speed = 1.3
			move_speed = 180.0
			armor = 1.0
		UnitType.TEUTONIC_KNIGHT:
			max_hp = 190.0
			attack_dmg = 25.0
			attack_range = 28.0
			attack_speed = 0.85
			move_speed = 80.0
			armor = 8.0 # High defense
		UnitType.SAMURAI:
			max_hp = 125.0
			attack_dmg = 16.0
			attack_range = 28.0
			attack_speed = 1.4 # Fast attack
			move_speed = 120.0
			armor = 2.0
		UnitType.MAMELUKE:
			max_hp = 165.0
			attack_dmg = 15.0
			attack_range = 75.0 # Ranged camel scimitar throw
			attack_speed = 1.1
			move_speed = 160.0
			armor = 2.0
		UnitType.BERSERKER:
			max_hp = 140.0
			attack_dmg = 19.0
			attack_range = 28.0
			attack_speed = 1.25
			move_speed = 125.0
			armor = 2.0
			regen_rate = 3.0
		UnitType.CHUKONU:
			max_hp = 70.0
			attack_dmg = 7.0 # Fires burst of 3
			attack_range = 150.0
			attack_speed = 1.2
			move_speed = 105.0
			armor = 0.0

	# Apply Civ bonuses
	if civ_cfg.has("archer_range_mult") and is_ranged():
		attack_range *= civ_cfg["archer_range_mult"]
	if civ_cfg.has("cavalry_speed_mult") and is_cavalry():
		move_speed *= civ_cfg["cavalry_speed_mult"]
	if civ_cfg.has("cavalry_hp_mult") and is_cavalry():
		max_hp *= civ_cfg["cavalry_hp_mult"]
	if civ_cfg.has("infantry_hp_mult") and is_infantry():
		max_hp *= civ_cfg["infantry_hp_mult"]
	if civ_cfg.has("infantry_atk_speed_mult") and is_infantry():
		attack_speed /= civ_cfg["infantry_atk_speed_mult"]
	if civ_cfg.has("armor_bonus"):
		armor += civ_cfg["armor_bonus"]
	if civ_cfg.has("infantry_regen") and is_infantry():
		regen_rate = max(regen_rate, civ_cfg["infantry_regen"])

	hp = max_hp

func is_ranged() -> bool:
	return unit_type in [UnitType.ARCHER, UnitType.JANISSARY, UnitType.LONGBOWMAN, UnitType.MANGUDAI, UnitType.MAMELUKE, UnitType.CHUKONU]

func is_cavalry() -> bool:
	return unit_type in [UnitType.CAVALRY, UnitType.CATAPHRACT, UnitType.PALADIN, UnitType.MANGUDAI, UnitType.MAMELUKE]

func is_infantry() -> bool:
	return unit_type in [UnitType.SWORDSMAN, UnitType.SPEARMAN, UnitType.TEUTONIC_KNIGHT, UnitType.SAMURAI, UnitType.BERSERKER]

func _physics_process(delta: float) -> void:
	# Health regen (Vikings / Berserkers)
	if regen_rate > 0.0 and hp < max_hp and hp > 0.0:
		hp = min(max_hp, hp + regen_rate * delta)
		
	# Attack cooldown
	if attack_timer > 0.0:
		attack_timer -= delta
		
	# Swing recovery
	if swing_progress > 0.0:
		swing_progress = max(0.0, swing_progress - delta * 4.0)
		queue_redraw()
		
	# Process states
	match state:
		State.IDLE:
			_handle_idle_scanning()
		State.MOVING:
			_process_path_movement(delta)
		State.ATTACKING:
			_process_attack_target(delta)
		State.GATHERING:
			_process_gathering(delta)
		State.BUILDING:
			_process_building(delta)
		State.RETURNING_RESOURCES:
			_process_return_resources(delta)

	# Update floating texts
	for i in range(float_texts.size() - 1, -1, -1):
		var ft = float_texts[i]
		ft.time -= delta
		ft.pos += Vector2(0, -35.0 * delta)
		if ft.time <= 0:
			float_texts.remove_at(i)
	if float_texts.size() > 0:
		queue_redraw()

func _handle_idle_scanning() -> void:
	if unit_type == UnitType.VILLAGER:
		return
	# Auto scan for nearby enemies within 120 pixels
	var scan_range = 140.0 if not is_ranged() else attack_range + 30.0
	var enemy = _find_closest_enemy(scan_range)
	if enemy:
		command_attack(enemy)

func _process_path_movement(delta: float) -> void:
	if current_path.is_empty() or path_idx >= current_path.size():
		state = State.IDLE
		walk_timer = 0.0
		queue_redraw()
		return
		
	var target_pt = current_path[path_idx]
	var dir = (target_pt - global_position).normalized()
	var dist = global_position.distance_to(target_pt)
	var move_dist = move_speed * delta
	
	walk_timer += delta
	
	if dist <= move_dist:
		global_position = target_pt
		path_idx += 1
		if path_idx >= current_path.size():
			current_path.clear()
			state = State.IDLE
			walk_timer = 0.0
	else:
		velocity = dir * move_speed
		move_and_slide()
		
	queue_redraw()

func _process_attack_target(delta: float) -> void:
	if not is_instance_valid(target_entity) or target_entity.hp <= 0:
		target_entity = null
		state = State.IDLE
		return
		
	var dist = global_position.distance_to(target_entity.global_position)
	if dist > attack_range:
		# Walk closer
		if current_path.is_empty() or path_idx >= current_path.size():
			_calculate_path(target_entity.global_position)
		_process_path_movement(delta)
	else:
		# In range! Stop walking and attack
		current_path.clear()
		walk_timer = 0.0
		if attack_timer <= 0.0:
			_execute_attack()

func _execute_attack() -> void:
	if not is_instance_valid(target_entity):
		return
		
	attack_timer = 1.0 / attack_speed
	swing_progress = 1.0
	
	var effective_dmg = attack_dmg
	# Bonus vs cavalry for Spearmen
	if unit_type == UnitType.SPEARMAN and target_entity is Unit and target_entity.is_cavalry():
		effective_dmg *= 2.5
	# Bonus vs archers for Cavalry
	if is_cavalry() and target_entity is Unit and target_entity.is_ranged():
		effective_dmg *= 1.5
	# Samurai critical hit
	if unit_type == UnitType.SAMURAI and randf() < 0.25:
		effective_dmg *= 1.8
		add_float_text("CRIT!", Color(1.0, 0.8, 0.1))
		
	if is_ranged():
		# Fire projectile
		SoundManager.play_sound("shoot")
		var is_musket = (unit_type == UnitType.JANISSARY)
		if main_game != null:
			if unit_type == UnitType.CHUKONU:
				# Chu-Ko-Nu fires 3 burst shots
				for i in range(3):
					get_tree().create_timer(i * 0.12).timeout.connect(func():
						if is_instance_valid(target_entity):
							main_game.spawn_projectile(global_position, target_entity, effective_dmg, team, false)
					)
			else:
				main_game.spawn_projectile(global_position, target_entity, effective_dmg, team, is_musket)
	else:
		SoundManager.play_sound("attack")
		target_entity.take_damage(effective_dmg, team)
		
	queue_redraw()

func _process_gathering(delta: float) -> void:
	if map_gen == null:
		return
	var resource_pos = map_gen.cell_to_world(target_cell)
	var dist = global_position.distance_to(resource_pos)
	
	if dist > 40.0:
		if current_path.is_empty() or path_idx >= current_path.size():
			_calculate_path(resource_pos)
		_process_path_movement(delta)
		return
		
	# In harvest range
	walk_timer = 0.0
	if attack_timer <= 0.0:
		attack_timer = 0.8
		swing_progress = 1.0
		SoundManager.play_sound("gather")
		
		var civ_cfg = CivData.get_civ(civ_type)
		var harvest_amt = 5
		if resource_type == "wood":
			harvest_amt = int(5 * civ_cfg.get("wood_gather_mult", 1.0))
			var got = map_gen.harvest_tree(target_cell, harvest_amt)
			if got > 0:
				carried_resource += got
				add_float_text("+%d 🪵" % got, Color(0.4, 0.8, 0.4))
			else:
				# Depleted, find new tree
				_find_next_resource("wood")
		elif resource_type == "gold":
			harvest_amt = int(4 * civ_cfg.get("gold_gather_mult", 1.0))
			var got = map_gen.harvest_gold(target_cell, harvest_amt)
			if got > 0:
				carried_resource += got
				add_float_text("+%d 🪙" % got, Color(1.0, 0.85, 0.2))
			else:
				_find_next_resource("gold")
		elif resource_type == "food":
			harvest_amt = int(5 * civ_cfg.get("food_gather_mult", 1.0))
			var got = map_gen.harvest_food(target_cell, harvest_amt)
			if got > 0:
				carried_resource += got
				add_float_text("+%d 🌾" % got, Color(0.9, 0.7, 0.3))
			else:
				_find_next_resource("food")
				
		if carried_resource >= max_carry:
			state = State.RETURNING_RESOURCES
			current_path.clear()
			
	queue_redraw()

func _process_return_resources(delta: float) -> void:
	if main_game == null:
		return
	var dropoff = main_game.get_closest_dropoff(global_position, team)
	if not is_instance_valid(dropoff):
		state = State.IDLE
		return
		
	var dist = global_position.distance_to(dropoff.global_position)
	if dist > 55.0:
		if current_path.is_empty() or path_idx >= current_path.size():
			_calculate_path(dropoff.global_position)
		_process_path_movement(delta)
	else:
		# Deposit!
		main_game.deposit_resource(team, resource_type, carried_resource)
		carried_resource = 0
		# Return to work
		state = State.GATHERING
		current_path.clear()

func _process_building(delta: float) -> void:
	if not is_instance_valid(target_entity) or target_entity.is_completed:
		state = State.IDLE
		target_entity = null
		return
		
	var dist = global_position.distance_to(target_entity.global_position)
	if dist > 60.0:
		if current_path.is_empty() or path_idx >= current_path.size():
			_calculate_path(target_entity.global_position)
		_process_path_movement(delta)
	else:
		walk_timer = 0.0
		if attack_timer <= 0.0:
			attack_timer = 0.5
			swing_progress = 1.0
			SoundManager.play_sound("build")
			target_entity.contribute_construction(8.0)
			if target_entity.is_completed:
				state = State.IDLE
				target_entity = null
		queue_redraw()

func _find_next_resource(type: String) -> void:
	if map_gen == null:
		state = State.IDLE
		return
	var nearest_cell = Vector2i(-1, -1)
	var min_dist = 999999.0
	var my_cell = map_gen.world_to_cell(global_position)
	
	var dict = map_gen.trees if type == "wood" else (map_gen.gold_mines if type == "gold" else map_gen.berry_bushes)
	for cell in dict.keys():
		var d = my_cell.distance_squared_to(cell)
		if d < min_dist:
			min_dist = d
			nearest_cell = cell
			
	if nearest_cell != Vector2i(-1, -1) and min_dist < 400: # Within 20 tiles
		target_cell = nearest_cell
		current_path.clear()
	else:
		state = State.IDLE

func _calculate_path(target_world_pos: Vector2) -> void:
	if map_gen != null:
		current_path = map_gen.get_path_to_target(global_position, target_world_pos)
		path_idx = 0
		if current_path.size() > 0:
			# Remove first point if already on it
			if global_position.distance_to(current_path[0]) < 8.0:
				path_idx = 1

func _find_closest_enemy(max_dist: float) -> Node2D:
	if main_game == null:
		return null
	return main_game.get_closest_enemy_entity(global_position, team, max_dist)

# Public Commands
func command_move(dest: Vector2) -> void:
	state = State.MOVING
	target_entity = null
	target_cell = Vector2i(-1, -1)
	_calculate_path(dest)

func command_attack(entity: Node2D) -> void:
	if not is_instance_valid(entity):
		return
	state = State.ATTACKING
	target_entity = entity
	_calculate_path(entity.global_position)

func command_gather(cell: Vector2i, type: String) -> void:
	state = State.GATHERING
	target_cell = cell
	resource_type = type
	target_entity = null
	if map_gen != null:
		_calculate_path(map_gen.cell_to_world(cell))

func command_build(building: Node2D) -> void:
	state = State.BUILDING
	target_entity = building
	_calculate_path(building.global_position)

func command_stop() -> void:
	state = State.IDLE
	target_entity = null
	target_cell = Vector2i(-1, -1)
	current_path.clear()
	queue_redraw()

func take_damage(amount: float, attacker_team: int) -> void:
	var actual_dmg = max(1.0, amount - armor)
	hp -= actual_dmg
	add_float_text("-%d" % int(actual_dmg), Color(1.0, 0.25, 0.25))
	
	if state == State.IDLE and attacker_team != team:
		# Auto retaliate
		var enemy = _find_closest_enemy(150.0)
		if enemy:
			command_attack(enemy)
			
	if hp <= 0:
		die()
	queue_redraw()

func die() -> void:
	died.emit(self)
	# Sound & death animation
	SoundManager.play_sound("hit")
	queue_free()

func set_selected(sel: bool) -> void:
	is_selected = sel
	selected_changed.emit(self, sel)
	queue_redraw()

func add_float_text(txt: String, col: Color) -> void:
	float_texts.append({"text": txt, "pos": Vector2(0, -22), "time": 0.8, "color": col})

func _draw() -> void:
	var civ_cfg = CivData.get_civ(civ_type)
	var team_color = Color(0.18, 0.52, 0.95) if team == 0 else Color(0.92, 0.22, 0.22)
	var civ_flag = civ_cfg.get("flag_color", team_color)
	var civ_accent = civ_cfg.get("accent_color", Color(1, 1, 1))
	
	# Selection Circle
	if is_selected:
		draw_arc(Vector2(0, 4), 14.0, 0, TAU, 32, Color(0.2, 0.95, 0.3, 0.8), 2.0)
		
	# Subtle shadow underneath
	draw_ellipse(Vector2(0, 8), 10.0, 4.0, Color(0, 0, 0, 0.28))
	
	# Walking bounce animation
	var bob = sin(walk_timer * 14.0) * 2.0 if state == State.MOVING else 0.0
	var swing = sin(swing_progress * PI) * 14.0
	
	# Base Body (Tunic / Armor)
	var body_rect = Rect2(-5, -10 + bob, 10, 14)
	draw_rect(body_rect, team_color)
	draw_rect(body_rect, Color(0, 0, 0, 0.4), false, 1.0)
	
	# Distinctive Head & Headwear by Unit Type
	var head_center = Vector2(0, -14 + bob)
	draw_circle(head_center, 5.0, Color(0.95, 0.78, 0.62)) # Skin
	
	# Character Equipment & Hats
	match unit_type:
		UnitType.VILLAGER:
			# Straw hat
			draw_polygon(PackedVector2Array([head_center + Vector2(-9, -2), head_center + Vector2(0, -8), head_center + Vector2(9, -2)]), [Color(0.85, 0.75, 0.4)])
			# Tool (Pickaxe / Axe / Bag)
			if carried_resource > 0:
				draw_circle(Vector2(-7, -4 + bob), 4.5, Color(0.55, 0.38, 0.2)) # Sack
			else:
				draw_line(Vector2(5, -6 + bob - swing), Vector2(10, 2 + bob + swing), Color(0.4, 0.25, 0.1), 2.0)
				
		UnitType.SWORDSMAN:
			# Iron Helmet
			draw_circle(head_center + Vector2(0, -2), 5.5, Color(0.7, 0.72, 0.75))
			# Shield
			draw_circle(Vector2(-7, -4 + bob), 6.0, civ_flag)
			draw_circle(Vector2(-7, -4 + bob), 3.0, civ_accent)
			# Sword
			draw_line(Vector2(6, -2 + bob - swing), Vector2(14, -8 + bob - swing * 1.5), Color(0.9, 0.9, 0.95), 2.5)
			
		UnitType.ARCHER:
			# Archer's Green / Team Hood
			draw_circle(head_center + Vector2(0, -3), 5.5, civ_flag)
			# Bow
			draw_arc(Vector2(7, -6 + bob - swing * 0.5), 8.0, -1.2, 1.2, 16, Color(0.45, 0.28, 0.12), 2.0)
			
		UnitType.SPEARMAN:
			# Conical Helm
			draw_polygon(PackedVector2Array([head_center + Vector2(-5, -2), head_center + Vector2(0, -10), head_center + Vector2(5, -2)]), [Color(0.65, 0.68, 0.72)])
			# Long Spear
			draw_line(Vector2(4, 8 + bob), Vector2(12, -22 + bob - swing), Color(0.45, 0.3, 0.15), 2.0)
			draw_polygon(PackedVector2Array([Vector2(11, -22 + bob - swing), Vector2(13, -26 + bob - swing), Vector2(15, -22 + bob - swing)]), [Color(0.9, 0.9, 0.95)])
			
		UnitType.CAVALRY, UnitType.PALADIN:
			# Horse Body underneath
			draw_ellipse(Vector2(0, 2 + bob), 14.0, 7.0, Color(0.45, 0.28, 0.15))
			draw_circle(head_center + Vector2(0, -2), 6.0, Color(0.8, 0.8, 0.85)) # Knight Visor
			# Knight Lance
			draw_line(Vector2(6, 4 + bob), Vector2(18, -16 + bob - swing), Color(0.85, 0.85, 0.9), 2.5)
			
		UnitType.JANISSARY:
			# Tall White Janissary Bork Hat with gold plume
			draw_rect(Rect2(head_center.x - 4, head_center.y - 12, 8, 10), Color(0.95, 0.95, 0.95))
			draw_circle(head_center + Vector2(0, -12), 3.0, Color(0.95, 0.8, 0.1))
			# Long Musket Rifle
			draw_line(Vector2(4, -4 + bob), Vector2(18, -10 + bob - swing), Color(0.3, 0.2, 0.1), 3.0)
			draw_line(Vector2(14, -8 + bob), Vector2(22, -12 + bob - swing), Color(0.7, 0.7, 0.7), 2.0)
			
		UnitType.CATAPHRACT:
			# Full Iron Armored Horse & Rider
			draw_ellipse(Vector2(0, 2 + bob), 15.0, 8.0, Color(0.55, 0.55, 0.6))
			draw_circle(head_center + Vector2(0, -2), 6.0, Color(0.75, 0.75, 0.8))
			# Heavy Broadsword
			draw_line(Vector2(6, -2 + bob - swing), Vector2(16, -10 + bob - swing * 1.5), Color(0.95, 0.95, 1.0), 3.5)
			
		UnitType.LONGBOWMAN:
			# Feathered cap
			draw_circle(head_center + Vector2(0, -3), 5.5, civ_flag)
			draw_line(head_center + Vector2(2, -6), head_center + Vector2(7, -12), Color(1, 1, 1), 2.0)
			# Giant English War Bow
			draw_arc(Vector2(8, -6 + bob), 13.0, -1.3, 1.3, 16, Color(0.35, 0.22, 0.1), 2.5)
			
		UnitType.MANGUDAI:
			# Steppe Horse & Fur Hat
			draw_ellipse(Vector2(0, 2 + bob), 13.0, 6.5, Color(0.6, 0.45, 0.3))
			draw_circle(head_center + Vector2(0, -3), 6.0, Color(0.4, 0.3, 0.2))
			# Recurve composite bow
			draw_arc(Vector2(7, -5 + bob), 9.0, -1.2, 1.2, 16, Color(0.85, 0.6, 0.2), 2.0)
			
		UnitType.TEUTONIC_KNIGHT:
			# Great Horned / Crested Iron Helmet
			draw_rect(Rect2(head_center.x - 6, head_center.y - 8, 12, 12), Color(0.75, 0.75, 0.78))
			# Black Cross on chest
			draw_line(Vector2(-3, -3 + bob), Vector2(3, -3 + bob), Color(0, 0, 0), 2.0)
			draw_line(Vector2(0, -6 + bob), Vector2(0, 0 + bob), Color(0, 0, 0), 2.0)
			# Giant Two-Handed Sword
			draw_line(Vector2(6, 4 + bob - swing), Vector2(14, -18 + bob - swing * 1.8), Color(0.95, 0.95, 0.95), 3.5)
			
		UnitType.SAMURAI:
			# Samurai Kabuto helmet with golden crest
			draw_arc(head_center + Vector2(0, -3), 7.0, PI * 0.8, PI * 2.2, 16, Color(0.2, 0.2, 0.2), 3.0)
			draw_polygon(PackedVector2Array([head_center + Vector2(-4, -8), head_center + Vector2(0, -12), head_center + Vector2(4, -8)]), [Color(0.95, 0.8, 0.1)])
			# Curved Katana
			draw_arc(Vector2(8, -4 + bob - swing), 12.0, -1.0, 0.8, 16, Color(0.95, 0.95, 1.0), 2.5)
			
		UnitType.MAMELUKE:
			# Arabian Camel underneath & Turban
			draw_ellipse(Vector2(0, 4 + bob), 15.0, 8.0, Color(0.72, 0.58, 0.38))
			draw_circle(head_center + Vector2(0, -3), 6.5, Color(0.95, 0.95, 0.95)) # Turban
			# Curved Scimitar
			draw_arc(Vector2(8, -6 + bob - swing), 10.0, -0.8, 1.0, 16, Color(0.9, 0.85, 0.3), 2.5)
			
		UnitType.BERSERKER:
			# Wild hair / Horned Viking Helmet
			draw_circle(head_center + Vector2(0, -3), 5.5, Color(0.5, 0.5, 0.55))
			draw_line(head_center + Vector2(-5, -4), head_center + Vector2(-9, -10), Color(0.9, 0.9, 0.8), 2.0)
			draw_line(head_center + Vector2(5, -4), head_center + Vector2(9, -10), Color(0.9, 0.9, 0.8), 2.0)
			# Dual Battle Axes
			draw_line(Vector2(6, 2 + bob - swing), Vector2(14, -10 + bob - swing), Color(0.4, 0.25, 0.1), 2.0)
			draw_polygon(PackedVector2Array([Vector2(12, -12 + bob - swing), Vector2(16, -10 + bob - swing), Vector2(12, -7 + bob - swing)]), [Color(0.85, 0.85, 0.9)])
			
		UnitType.CHUKONU:
			# Chinese Straw/Bamboo conical hat & Repeating Crossbow
			draw_polygon(PackedVector2Array([head_center + Vector2(-8, -2), head_center + Vector2(0, -9), head_center + Vector2(8, -2)]), [Color(0.85, 0.65, 0.25)])
			# Wooden Magazine Crossbow Box
			draw_rect(Rect2(6, -8 + bob - swing * 0.5, 9, 6), Color(0.4, 0.22, 0.1))
			draw_line(Vector2(6, -5 + bob), Vector2(16, -5 + bob), Color(0.7, 0.7, 0.7), 2.0)

	# Health Bar (shown when selected or damaged)
	if is_selected or hp < max_hp:
		var bar_w = 24.0
		var bar_h = 3.5
		var bar_x = -bar_w * 0.5
		var bar_y = -22.0 + bob
		# Background
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.1, 0.1, 0.1, 0.8))
		# Fill
		var hp_pct = clamp(hp / max_hp, 0.0, 1.0)
		var fill_col = Color(0.2, 0.85, 0.2) if hp_pct > 0.5 else (Color(0.9, 0.8, 0.1) if hp_pct > 0.25 else Color(0.9, 0.2, 0.2))
		draw_rect(Rect2(bar_x, bar_y, bar_w * hp_pct, bar_h), fill_col)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0, 0, 0, 0.6), false, 1.0)

	# Draw floating combat / gather text
	for ft in float_texts:
		var str_val = ft.text
		var pos = ft.pos
		var col = ft.color
		col.a = clamp(ft.time * 2.0, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, pos, str_val, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, col)
