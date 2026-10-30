class_name Unit3D
extends CharacterBody3D

const PixelArtTextures = preload("res://scripts/PixelArtTextures.gd")
const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

const SPRITE_PIXEL_SIZE: float = 0.022
const SPRITE_BASE_Y: float = 1.76
const HP_BAR_Y: float = 3.65
const STATUS_LABEL_Y: float = 4.05
const SELECTION_RING_INNER: float = 0.85
const SELECTION_RING_OUTER: float = 1.10

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
@export var team: int = 0
@export var civ_type: CivData.CivType = CivData.CivType.OTTOMANS

var max_hp: float = 100.0
var hp: float = 100.0
var attack_dmg: float = 10.0
var armor: float = 0.0
var attack_range: float = 2.2
var attack_speed: float = 1.0
var move_speed: float = 6.5

var state: State = State.IDLE
var is_selected: bool = false

var current_path: Array[Vector3] = []
var path_idx: int = 0
var target_entity: Node3D = null
var target_cell: Vector2i = Vector2i(-1, -1)
var resource_type: String = ""
var carried_resource: int = 0
var max_carry: int = 15
const AUTO_GATHER_SEARCH_RADIUS: float = 16.0
var last_resource_pos: Vector3 = Vector3.ZERO

var attack_timer: float = 0.0
var swing_progress: float = 0.0
var walk_timer: float = 0.0
var regen_rate: float = 0.0

var map_gen: MapGenerator3D = null
var main_game: Node = null

# 3D Node references for animation
var model_root: Node3D
var unit_sprite: Sprite3D
var weapon_node: Node3D
var selection_ring: MeshInstance3D
var hp_bar_mesh: MeshInstance3D
var hp_fill_mesh: MeshInstance3D
var resource_sack: MeshInstance3D
var status_label: Label3D

# Articulated Limbs & Anatomy
var leg_left_pivot: Node3D
var leg_right_pivot: Node3D
var arm_left_pivot: Node3D
var arm_right_pivot: Node3D
var torso_pivot: Node3D
var head_pivot: Node3D
var horse_legs: Array[Node3D] = []

# Villager tools & backpack basket
var tool_axe: Node3D
var tool_pickaxe: Node3D
var tool_hammer: Node3D
var basket_node: Node3D
var basket_wood: Node3D
var basket_gold: Node3D
var basket_food: Node3D

func _ready() -> void:
	_init_stats()
	_build_3d_model()

func setup_unit(u_type: UnitType, t: int, civ: CivData.CivType, map: MapGenerator3D, game: Node) -> void:
	unit_type = u_type
	team = t
	civ_type = civ
	map_gen = map
	main_game = game
	_init_stats()
	_build_3d_model()

func _init_stats() -> void:
	var civ_cfg = CivData.get_civ(civ_type)

	match unit_type:
		UnitType.VILLAGER:
			max_hp = 50.0
			attack_dmg = 4.0
			attack_range = 1.8
			attack_speed = 1.2
			move_speed = 5.5
			armor = 0.0
		UnitType.SWORDSMAN:
			max_hp = 110.0
			attack_dmg = 12.0
			attack_range = 2.0
			attack_speed = 1.0
			move_speed = 5.8
			armor = 2.0
		UnitType.ARCHER:
			max_hp = 60.0
			attack_dmg = 8.0
			attack_range = 9.5
			attack_speed = 0.95
			move_speed = 6.0
			armor = 0.0
		UnitType.SPEARMAN:
			max_hp = 90.0
			attack_dmg = 8.0
			attack_range = 2.4
			attack_speed = 1.1
			move_speed = 6.0
			armor = 1.0
		UnitType.CAVALRY:
			max_hp = 160.0
			attack_dmg = 14.0
			attack_range = 2.2
			attack_speed = 0.95
			move_speed = 8.8
			armor = 2.0
		# Unique Units
		UnitType.JANISSARY:
			max_hp = 85.0
			attack_dmg = 24.0
			attack_range = 11.0
			attack_speed = 0.65
			move_speed = 5.8
			armor = 2.0
		UnitType.CATAPHRACT:
			max_hp = 220.0
			attack_dmg = 18.0
			attack_range = 2.4
			attack_speed = 1.0
			move_speed = 8.2
			armor = 5.0
		UnitType.LONGBOWMAN:
			max_hp = 65.0
			attack_dmg = 11.0
			attack_range = 13.5
			attack_speed = 1.1
			move_speed = 5.8
			armor = 0.0
		UnitType.PALADIN:
			max_hp = 260.0
			attack_dmg = 20.0
			attack_range = 2.4
			attack_speed = 0.9
			move_speed = 8.5
			armor = 4.0
		UnitType.MANGUDAI:
			max_hp = 95.0
			attack_dmg = 12.0
			attack_range = 9.5
			attack_speed = 1.3
			move_speed = 9.6
			armor = 1.0
		UnitType.TEUTONIC_KNIGHT:
			max_hp = 190.0
			attack_dmg = 25.0
			attack_range = 2.0
			attack_speed = 0.85
			move_speed = 4.8
			armor = 8.0
		UnitType.SAMURAI:
			max_hp = 125.0
			attack_dmg = 16.0
			attack_range = 2.0
			attack_speed = 1.4
			move_speed = 6.8
			armor = 2.0
		UnitType.MAMELUKE:
			max_hp = 165.0
			attack_dmg = 15.0
			attack_range = 4.5
			attack_speed = 1.1
			move_speed = 8.8
			armor = 2.0
		UnitType.BERSERKER:
			max_hp = 140.0
			attack_dmg = 19.0
			attack_range = 2.0
			attack_speed = 1.25
			move_speed = 7.0
			armor = 2.0
			regen_rate = 3.0
		UnitType.CHUKONU:
			max_hp = 70.0
			attack_dmg = 7.0
			attack_range = 9.0
			attack_speed = 1.2
			move_speed = 5.8
			armor = 0.0

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

func _build_3d_model() -> void:
	# Clear existing children if rebuild
	for child in get_children():
		child.queue_free()

	model_root = Node3D.new()
	add_child(model_root)

	# 1. Authentic Faction Art Billboard Sprite (Shaded HD-2D)
	unit_sprite = Sprite3D.new()
	unit_sprite.texture = FactionArtManager.get_unit_texture(civ_type, unit_type, "pose_01")
	unit_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	unit_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	unit_sprite.shaded = true
	unit_sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	unit_sprite.pixel_size = SPRITE_PIXEL_SIZE
	unit_sprite.position = Vector3(0, SPRITE_BASE_Y, 0)
	unit_sprite.no_depth_test = false
	unit_sprite.render_priority = 0
	if team != 0:
		unit_sprite.modulate = Color(1.08, 0.88, 0.88)
	model_root.add_child(unit_sprite)

	# 2. Diorama Ground Selection Ring
	selection_ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = SELECTION_RING_INNER
	ring_mesh.outer_radius = SELECTION_RING_OUTER
	selection_ring.mesh = ring_mesh
	selection_ring.position = Vector3(0, 0.05, 0)
	var ring_mat = StandardMaterial3D.new()
	var ring_col = Color(0.2, 0.95, 0.35) if team == 0 else Color(0.95, 0.22, 0.22)
	ring_mat.albedo_color = ring_col
	ring_mat.emission_enabled = true
	ring_mat.emission = ring_col
	ring_mat.no_depth_test = true
	ring_mat.render_priority = 4
	selection_ring.material_override = ring_mat
	selection_ring.visible = false
	add_child(selection_ring)

	# 3. Crystal Clear Floating Task Badge & HP Bar
	_build_3d_hp_bar(0.0)

func _build_3d_weapon(_mount_y: float, iron_mat: Material, wood_mat: Material, _gold_mat: Material) -> void:
	match unit_type:
		UnitType.VILLAGER:
			# Multi-Tool Setup: Lumberjack Axe, Mining Pickaxe & Carpenter Mallet
			# 1. Lumberjack Axe
			tool_axe = Node3D.new()
			weapon_node.add_child(tool_axe)

			var axe_shaft = MeshInstance3D.new()
			var as_mesh = CylinderMesh.new()
			as_mesh.top_radius = 0.03
			as_mesh.bottom_radius = 0.03
			as_mesh.height = 0.70
			axe_shaft.mesh = as_mesh
			axe_shaft.position = Vector3(0, 0.25, 0)
			axe_shaft.rotation_degrees = Vector3(35, 0, 0)
			axe_shaft.material_override = wood_mat
			tool_axe.add_child(axe_shaft)

			var axe_blade = MeshInstance3D.new()
			var ab_mesh = PrismMesh.new()
			ab_mesh.size = Vector3(0.06, 0.28, 0.26)
			axe_blade.mesh = ab_mesh
			axe_blade.position = Vector3(0, 0.52, -0.22)
			axe_blade.rotation_degrees = Vector3(35, 90, 0)
			axe_blade.material_override = iron_mat
			tool_axe.add_child(axe_blade)

			# 2. Mining Pickaxe
			tool_pickaxe = Node3D.new()
			weapon_node.add_child(tool_pickaxe)

			var pick_shaft = MeshInstance3D.new()
			pick_shaft.mesh = as_mesh
			pick_shaft.position = Vector3(0, 0.25, 0)
			pick_shaft.rotation_degrees = Vector3(35, 0, 0)
			pick_shaft.material_override = wood_mat
			tool_pickaxe.add_child(pick_shaft)

			var pick_head = MeshInstance3D.new()
			var ph_mesh = BoxMesh.new()
			ph_mesh.size = Vector3(0.06, 0.08, 0.42)
			pick_head.mesh = ph_mesh
			pick_head.position = Vector3(0, 0.54, -0.22)
			pick_head.rotation_degrees = Vector3(35, 0, 0)
			pick_head.material_override = iron_mat
			tool_pickaxe.add_child(pick_head)
			tool_pickaxe.visible = false

			# 3. Builder Hammer
			tool_hammer = Node3D.new()
			weapon_node.add_child(tool_hammer)

			var ham_shaft = MeshInstance3D.new()
			ham_shaft.mesh = as_mesh
			ham_shaft.position = Vector3(0, 0.20, 0)
			ham_shaft.rotation_degrees = Vector3(35, 0, 0)
			ham_shaft.material_override = wood_mat
			tool_hammer.add_child(ham_shaft)

			var ham_head = MeshInstance3D.new()
			var hh_mesh = BoxMesh.new()
			hh_mesh.size = Vector3(0.12, 0.16, 0.26)
			ham_head.mesh = hh_mesh
			ham_head.position = Vector3(0, 0.48, -0.20)
			ham_head.rotation_degrees = Vector3(35, 0, 0)
			ham_head.material_override = iron_mat
			tool_hammer.add_child(ham_head)
			tool_hammer.visible = false

		UnitType.SWORDSMAN, UnitType.CATAPHRACT, UnitType.PALADIN:
			# Long Steel Broadsword
			var hilt = MeshInstance3D.new()
			var h_mesh = CylinderMesh.new()
			h_mesh.top_radius = 0.03
			h_mesh.bottom_radius = 0.03
			h_mesh.height = 0.25
			hilt.mesh = h_mesh
			hilt.rotation_degrees = Vector3(30, 0, 0)
			hilt.material_override = wood_mat
			weapon_node.add_child(hilt)

			var guard = MeshInstance3D.new()
			var g_mesh = BoxMesh.new()
			g_mesh.size = Vector3(0.24, 0.04, 0.06)
			guard.mesh = g_mesh
			guard.position = Vector3(0, 0.12, -0.06)
			guard.rotation_degrees = Vector3(30, 0, 0)
			guard.material_override = iron_mat
			weapon_node.add_child(guard)

			var blade = MeshInstance3D.new()
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(0.08, 0.95, 0.03)
			blade.mesh = b_mesh
			blade.position = Vector3(0, 0.58, -0.32)
			blade.rotation_degrees = Vector3(30, 0, 0)
			blade.material_override = iron_mat
			weapon_node.add_child(blade)

		UnitType.SPEARMAN:
			# Long Spear with Steel Spearhead
			var spear = MeshInstance3D.new()
			var s_mesh = CylinderMesh.new()
			s_mesh.top_radius = 0.03
			s_mesh.bottom_radius = 0.03
			s_mesh.height = 1.90
			spear.mesh = s_mesh
			spear.position = Vector3(0, 0.65, -0.25)
			spear.rotation_degrees = Vector3(22, 0, 0)
			spear.material_override = wood_mat
			weapon_node.add_child(spear)

			var tip = MeshInstance3D.new()
			var tp_mesh = PrismMesh.new()
			tp_mesh.size = Vector3(0.08, 0.35, 0.04)
			tip.mesh = tp_mesh
			tip.position = Vector3(0, 1.55, -0.62)
			tip.rotation_degrees = Vector3(22, 0, 0)
			tip.material_override = iron_mat
			weapon_node.add_child(tip)

		UnitType.JANISSARY:
			# Historical Ottoman Musket
			var musket = MeshInstance3D.new()
			var m_mesh = CylinderMesh.new()
			m_mesh.top_radius = 0.04
			m_mesh.bottom_radius = 0.05
			m_mesh.height = 1.10
			musket.mesh = m_mesh
			musket.position = Vector3(0, 0.20, -0.35)
			musket.rotation_degrees = Vector3(75, 0, 0)
			musket.material_override = wood_mat
			weapon_node.add_child(musket)

			var barrel = MeshInstance3D.new()
			var br_mesh = CylinderMesh.new()
			br_mesh.top_radius = 0.025
			br_mesh.bottom_radius = 0.025
			br_mesh.height = 0.70
			barrel.mesh = br_mesh
			barrel.position = Vector3(0, 0.68, -0.80)
			barrel.rotation_degrees = Vector3(75, 0, 0)
			barrel.material_override = iron_mat
			weapon_node.add_child(barrel)

		UnitType.ARCHER, UnitType.LONGBOWMAN, UnitType.MANGUDAI:
			# Composite Recurve Bow
			var bow = MeshInstance3D.new()
			var bw_mesh = CylinderMesh.new()
			bw_mesh.top_radius = 0.03
			bw_mesh.bottom_radius = 0.03
			bw_mesh.height = 1.10
			bow.mesh = bw_mesh
			bow.position = Vector3(0, 0.15, -0.15)
			bow.rotation_degrees = Vector3(15, 0, 0)
			bow.material_override = wood_mat
			weapon_node.add_child(bow)

		UnitType.SAMURAI:
			# Curved Katana
			var katana = MeshInstance3D.new()
			var k_mesh = BoxMesh.new()
			k_mesh.size = Vector3(0.06, 0.95, 0.03)
			katana.mesh = k_mesh
			katana.position = Vector3(0, 0.45, -0.25)
			katana.rotation_degrees = Vector3(35, 0, 0)
			katana.material_override = iron_mat
			weapon_node.add_child(katana)

		UnitType.BERSERKER:
			# Viking Battleaxe
			var shaft = MeshInstance3D.new()
			var sh_mesh = CylinderMesh.new()
			sh_mesh.top_radius = 0.03
			sh_mesh.bottom_radius = 0.03
			sh_mesh.height = 0.85
			shaft.mesh = sh_mesh
			shaft.position = Vector3(0, 0.30, -0.15)
			shaft.rotation_degrees = Vector3(35, 0, 0)
			shaft.material_override = wood_mat
			weapon_node.add_child(shaft)

			var blade = MeshInstance3D.new()
			var bl_mesh = PrismMesh.new()
			bl_mesh.size = Vector3(0.06, 0.38, 0.32)
			blade.mesh = bl_mesh
			blade.position = Vector3(0, 0.65, -0.38)
			blade.rotation_degrees = Vector3(35, 90, 0)
			blade.material_override = iron_mat
			weapon_node.add_child(blade)

		UnitType.CHUKONU:
			# Repeating Crossbow Box
			var box = MeshInstance3D.new()
			var bx_mesh = BoxMesh.new()
			bx_mesh.size = Vector3(0.32, 0.22, 0.55)
			box.mesh = bx_mesh
			box.position = Vector3(0, 0.10, -0.25)
			box.material_override = wood_mat
			weapon_node.add_child(box)

		_:
			# Default Broadsword
			var blade = MeshInstance3D.new()
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(0.08, 0.85, 0.04)
			blade.mesh = b_mesh
			blade.position = Vector3(0, 0.38, -0.20)
			blade.rotation_degrees = Vector3(30, 0, 0)
			blade.material_override = iron_mat
			weapon_node.add_child(blade)

func _build_3d_hp_bar(mount_y: float) -> void:
	# 1. Clean billboarded HP bar placed safely below the task label
	var bar_holder = Node3D.new()
	bar_holder.position = Vector3(0, mount_y + HP_BAR_Y, 0)
	add_child(bar_holder)

	hp_bar_mesh = MeshInstance3D.new()
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(0.92, 0.10, 0.04)
	hp_bar_mesh.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.08, 0.06, 0.04, 0.90)
	bg_mat.no_depth_test = true
	bg_mat.render_priority = 10
	hp_bar_mesh.material_override = bg_mat
	bar_holder.add_child(hp_bar_mesh)

	hp_fill_mesh = MeshInstance3D.new()
	var fill_mesh = BoxMesh.new()
	fill_mesh.size = Vector3(0.88, 0.07, 0.05)
	hp_fill_mesh.mesh = fill_mesh
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.22, 0.92, 0.28)
	fill_mat.no_depth_test = true
	fill_mat.render_priority = 11
	hp_fill_mesh.material_override = fill_mat
	bar_holder.add_child(hp_fill_mesh)

	# Fixed billboard pitch towards game camera
	bar_holder.rotation_degrees = Vector3(-45, 0, 0)
	bar_holder.visible = false

	# 2. Prominent, Crystal Clear Floating Status Badge (Placed safely above unit)
	status_label = Label3D.new()
	status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_label.no_depth_test = true
	status_label.render_priority = 120
	status_label.font_size = 40
	status_label.pixel_size = 0.008
	status_label.outline_size = 10
	status_label.outline_modulate = Color(0.02, 0.02, 0.02, 1.0)
	status_label.modulate = Color(1.0, 0.95, 0.65)
	status_label.position = Vector3(0, mount_y + STATUS_LABEL_Y, 0)
	status_label.text = ""
	status_label.visible = false
	add_child(status_label)

func _physics_process(delta: float) -> void:
	if regen_rate > 0.0 and hp < max_hp and hp > 0.0:
		hp = min(max_hp, hp + regen_rate * delta)
		_update_hp_bar()

	if attack_timer > 0.0:
		attack_timer -= delta

	if swing_progress > 0.0:
		swing_progress = max(0.0, swing_progress - delta * 3.5)

	# Procedural HD-2D Sprite Animation
	_update_hd2d_sprite_animation(delta)

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

	if is_selected:
		_update_status_label()

func _handle_idle_scanning() -> void:
	if unit_type == UnitType.VILLAGER:
		return
	var scan_range = 6.5 if not is_ranged() else attack_range + 2.0
	var enemy = _find_closest_enemy(scan_range)
	if enemy:
		command_attack(enemy)

func _process_path_movement(delta: float) -> void:
	if current_path.is_empty() or path_idx >= current_path.size():
		if state == State.MOVING:
			state = State.IDLE
		walk_timer = 0.0
		velocity = Vector3.ZERO
		if is_instance_valid(model_root):
			model_root.position.y = 0.0
		return

	var target_pt = current_path[path_idx]
	var dir = (target_pt - global_position)
	dir.y = 0.0
	var dist = dir.length()
	dir = dir.normalized()

	walk_timer += delta
	# Procedural walk bounce and lean
	if is_instance_valid(model_root):
		model_root.position.y = sin(walk_timer * 16.0) * 0.08
		if dir.length_squared() > 0.01:
			var target_rot = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_rot, delta * 12.0)

	var move_dist = move_speed * delta
	if dist <= move_dist:
		global_position = target_pt
		path_idx += 1
		if path_idx >= current_path.size():
			current_path.clear()
			if state == State.MOVING:
				state = State.IDLE
			walk_timer = 0.0
			velocity = Vector3.ZERO
			if is_instance_valid(model_root):
				model_root.position.y = 0.0
	else:
		velocity = dir * move_speed
		move_and_slide()

func _process_attack_target(delta: float) -> void:
	if not is_instance_valid(target_entity) or target_entity.hp <= 0:
		target_entity = null
		state = State.IDLE
		return

	var dist = global_position.distance_to(target_entity.global_position)
	if dist > attack_range:
		if current_path.is_empty() or path_idx >= current_path.size():
			_calculate_path(target_entity.global_position)
		_process_path_movement(delta)
	else:
		current_path.clear()
		walk_timer = 0.0
		# Rotate towards target
		var dir = (target_entity.global_position - global_position).normalized()
		rotation.y = atan2(dir.x, dir.z)

		if attack_timer <= 0.0:
			_execute_attack()

func _execute_attack() -> void:
	if not is_instance_valid(target_entity):
		return

	attack_timer = 1.0 / attack_speed
	swing_progress = 1.0

	var effective_dmg = attack_dmg
	if unit_type == UnitType.SPEARMAN and target_entity is Unit3D and target_entity.is_cavalry():
		effective_dmg *= 2.5
	if is_cavalry() and target_entity is Unit3D and target_entity.is_ranged():
		effective_dmg *= 1.5
	if unit_type == UnitType.SAMURAI and randf() < 0.25:
		effective_dmg *= 1.8

	if is_ranged():
		SoundManager.play_sound("shoot")
		var is_musket = (unit_type == UnitType.JANISSARY)
		if main_game != null:
			if unit_type == UnitType.CHUKONU:
				for i in range(3):
					get_tree().create_timer(i * 0.12).timeout.connect(func():
						if is_instance_valid(target_entity):
							main_game.spawn_projectile(global_position + Vector3(0, 0.8, 0), target_entity, effective_dmg, team, false)
					)
			else:
				main_game.spawn_projectile(global_position + Vector3(0, 0.8, 0), target_entity, effective_dmg, team, is_musket)
	else:
		SoundManager.play_sound("attack")
		target_entity.take_damage(effective_dmg, team)

func _process_gathering(delta: float) -> void:
	if map_gen == null:
		state = State.IDLE
		return

	# Verify target resource still exists in map
	var dict = map_gen.trees if resource_type == "wood" else (map_gen.gold_mines if resource_type == "gold" else (map_gen.stone_mines if resource_type == "stone" else map_gen.berry_bushes))
	if not (target_cell in dict):
		if carried_resource > 0:
			command_return_resources()
		else:
			_find_next_resource(resource_type)
		return

	var my_cell = map_gen.world_to_cell(global_position)
	var cell_dist = max(abs(my_cell.x - target_cell.x), abs(my_cell.y - target_cell.y))
	var res_pos = map_gen.cell_to_world(target_cell)
	var world_dist = global_position.distance_to(res_pos)

	# If further than adjacent tile and further than 2.8 meters -> pathfind to adjacent cell
	if cell_dist > 1 and world_dist > 2.8:
		if current_path.is_empty() or path_idx >= current_path.size():
			_calculate_path(res_pos)
		_process_path_movement(delta)
		return

	# We are at the resource! Clear path and stop moving
	current_path.clear()
	velocity = Vector3.ZERO
	walk_timer = 0.0

	# Face towards the resource
	var look_dir = res_pos - global_position
	look_dir.y = 0.0
	if look_dir.length_squared() > 0.01:
		rotation.y = atan2(look_dir.x, look_dir.z)

	if attack_timer <= 0.0:
		attack_timer = 0.8
		swing_progress = 1.0
		SoundManager.play_sound("gather")

		var civ_cfg = CivData.get_civ(civ_type)
		var harvest_amt = 5
		var got = 0
		if resource_type == "wood":
			harvest_amt = int(5 * civ_cfg.get("wood_gather_mult", 1.0))
			got = map_gen.harvest_tree(target_cell, harvest_amt)
		elif resource_type == "gold":
			harvest_amt = int(4 * civ_cfg.get("gold_gather_mult", 1.0))
			got = map_gen.harvest_gold(target_cell, harvest_amt)
		elif resource_type == "stone":
			harvest_amt = int(4 * civ_cfg.get("stone_gather_mult", 1.0))
			got = map_gen.harvest_stone(target_cell, harvest_amt)
		elif resource_type == "food":
			harvest_amt = int(5 * civ_cfg.get("food_gather_mult", 1.0))
			got = map_gen.harvest_food(target_cell, harvest_amt)

		if got > 0:
			carried_resource += got
		else:
			# Resource was depleted!
			if carried_resource > 0:
				command_return_resources()
			else:
				_find_next_resource(resource_type)
			return

		if is_instance_valid(resource_sack):
			resource_sack.visible = carried_resource > 0

		if carried_resource >= max_carry:
			command_return_resources()

func _find_valid_dropoff() -> Building3D:
	if main_game == null:
		return null
	if main_game.has_method("get_closest_dropoff_for_resource"):
		var res = main_game.call("get_closest_dropoff_for_resource", global_position, team, resource_type)
		if is_instance_valid(res) and res is Building3D:
			return res as Building3D
	if main_game.has_method("get_closest_dropoff"):
		# Supports 3-argument signature and safely falls back to 2-argument legacy signature
		var res3 = main_game.call("get_closest_dropoff", global_position, team, resource_type)
		if is_instance_valid(res3) and res3 is Building3D:
			return res3 as Building3D
		var res2 = main_game.call("get_closest_dropoff", global_position, team)
		if is_instance_valid(res2) and res2 is Building3D:
			return res2 as Building3D
	return null

func _process_return_resources(delta: float) -> void:
	if main_game == null or map_gen == null:
		state = State.IDLE
		target_entity = null
		return

	# Verify currently targeted dropoff building is valid, completed, and alive
	var dropoff: Building3D = target_entity as Building3D
	if not is_instance_valid(dropoff) or dropoff.hp <= 0 or not dropoff.is_completed:
		# Target dropoff was destroyed, uncompleted, or invalid -> seek alternative dropoff
		dropoff = _find_valid_dropoff()
		if not is_instance_valid(dropoff):
			# No alternative dropoffs available on map -> halt and idle safely (prevents per-frame error spam)
			state = State.IDLE
			target_entity = null
			current_path.clear()
			velocity = Vector3.ZERO
			return
		target_entity = dropoff
		current_path.clear()
		_calculate_path(dropoff.global_position)

	var my_cell = map_gen.world_to_cell(global_position)
	var o_cell = dropoff.origin_cell
	var g_size = dropoff.grid_size
	var is_adjacent = (
		my_cell.x >= o_cell.x - 1 and my_cell.x <= o_cell.x + g_size.x and
		my_cell.y >= o_cell.y - 1 and my_cell.y <= o_cell.y + g_size.y
	)
	var b_radius = max(g_size.x, g_size.y) * MapGenerator3D.TILE_SIZE * 0.5
	var dist = global_position.distance_to(dropoff.global_position)

	if not is_adjacent and dist > (b_radius + 3.2):
		if current_path.is_empty() or path_idx >= current_path.size():
			_calculate_path(dropoff.global_position)
		_process_path_movement(delta)
	else:
		# Arrived at Depot / Town Center! Deposit cargo
		if carried_resource > 0:
			main_game.deposit_resource(team, resource_type, carried_resource)
			carried_resource = 0
		if is_instance_valid(resource_sack):
			resource_sack.visible = false
		SoundManager.play_sound("click")
		target_entity = null

		# Return back to gathering!
		current_path.clear()
		var dict = map_gen.trees if resource_type == "wood" else (map_gen.gold_mines if resource_type == "gold" else (map_gen.stone_mines if resource_type == "stone" else map_gen.berry_bushes))
		if target_cell in dict:
			state = State.GATHERING
			_calculate_path(map_gen.cell_to_world(target_cell))
		else:
			_find_next_resource(resource_type)

func _process_building(delta: float) -> void:
	if not is_instance_valid(target_entity) or target_entity.is_completed:
		state = State.IDLE
		target_entity = null
		return

	var my_cell = map_gen.world_to_cell(global_position) if map_gen != null else Vector2i(-99, -99)
	var o_cell = target_entity.origin_cell
	var g_size = target_entity.grid_size
	var is_adjacent = (
		my_cell.x >= o_cell.x - 1 and my_cell.x <= o_cell.x + g_size.x and
		my_cell.y >= o_cell.y - 1 and my_cell.y <= o_cell.y + g_size.y
	)
	var b_radius = max(g_size.x, g_size.y) * MapGenerator3D.TILE_SIZE * 0.5
	var dist = global_position.distance_to(target_entity.global_position)

	if not is_adjacent and dist > (b_radius + 2.8):
		if current_path.is_empty() or path_idx >= current_path.size():
			_calculate_path(target_entity.global_position)
		_process_path_movement(delta)
	else:
		current_path.clear()
		velocity = Vector3.ZERO
		walk_timer = 0.0

		var look_dir = target_entity.global_position - global_position
		look_dir.y = 0.0
		if look_dir.length_squared() > 0.01:
			rotation.y = atan2(look_dir.x, look_dir.z)

		if attack_timer <= 0.0:
			attack_timer = 0.5
			swing_progress = 1.0
			SoundManager.play_sound("build")
			target_entity.contribute_construction(8.0)
			if target_entity.is_completed:
				state = State.IDLE
				target_entity = null

func _find_next_resource(type: String = "") -> void:
	if type == "":
		type = resource_type
	if map_gen == null:
		state = State.IDLE
		return

	var search_origin = last_resource_pos if last_resource_pos != Vector3.ZERO else global_position
	var nearest_cell = map_gen.find_nearest_resource_node(search_origin, type, AUTO_GATHER_SEARCH_RADIUS)

	if nearest_cell != Vector2i(-1, -1):
		target_cell = nearest_cell
		resource_type = type
		state = State.GATHERING
		current_path.clear()
		last_resource_pos = map_gen.cell_to_world(nearest_cell)
		_calculate_path(last_resource_pos)
	else:
		if carried_resource > 0:
			command_return_resources()
		else:
			state = State.IDLE
			target_cell = Vector2i(-1, -1)
			current_path.clear()
			velocity = Vector3.ZERO

func _calculate_path(target_pos: Vector3) -> void:
	if map_gen != null:
		current_path = map_gen.get_path_to_target(global_position, target_pos)
		path_idx = 0
		if current_path.size() > 0 and global_position.distance_to(current_path[0]) < 0.6:
			path_idx = 1

func _find_closest_enemy(max_dist: float) -> Node3D:
	if main_game == null:
		return null
	return main_game.get_closest_enemy_entity(global_position, team, max_dist)

# Commands
func command_move(dest: Vector3) -> void:
	state = State.MOVING
	target_entity = null
	target_cell = Vector2i(-1, -1)
	_calculate_path(dest)

func command_attack(entity: Node3D) -> void:
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
		last_resource_pos = map_gen.cell_to_world(cell)
		_calculate_path(last_resource_pos)

func command_build(building: Node3D) -> void:
	state = State.BUILDING
	target_entity = building
	_calculate_path(building.global_position)

func command_return_resources(dropoff: Node3D = null) -> void:
	state = State.RETURNING_RESOURCES
	current_path.clear()
	if is_instance_valid(dropoff):
		target_entity = dropoff
		_calculate_path(dropoff.global_position)
	else:
		var d = _find_valid_dropoff()
		if is_instance_valid(d):
			target_entity = d
			_calculate_path(d.global_position)
		else:
			target_entity = null
			state = State.IDLE
			velocity = Vector3.ZERO

func command_stop() -> void:
	state = State.IDLE
	target_entity = null
	target_cell = Vector2i(-1, -1)
	current_path.clear()

func take_damage(amount: float, attacker_team: int) -> void:
	var actual_dmg = max(1.0, amount - armor)
	hp -= actual_dmg
	_update_hp_bar()

	if state == State.IDLE and attacker_team != team:
		var enemy = _find_closest_enemy(8.0)
		if enemy:
			command_attack(enemy)

	if hp <= 0:
		die()

func die() -> void:
	died.emit(self)
	SoundManager.play_sound("hit")
	queue_free()

func set_selected(sel: bool) -> void:
	is_selected = sel
	if is_instance_valid(selection_ring):
		selection_ring.visible = sel
	if is_instance_valid(status_label):
		status_label.visible = sel
	_update_hp_bar()
	_update_status_label()
	selected_changed.emit(self, sel)

func _update_hd2d_sprite_animation(_delta: float) -> void:
	if not is_instance_valid(unit_sprite):
		return

	if state in [State.MOVING, State.RETURNING_RESOURCES] or (current_path.size() > 0 and path_idx < current_path.size()):
		unit_sprite.position.y = SPRITE_BASE_Y + abs(sin(walk_timer * 13.0)) * 0.16
		unit_sprite.rotation.z = sin(walk_timer * 13.0) * 0.06
		if velocity.x < -0.15:
			unit_sprite.flip_h = true
		elif velocity.x > 0.15:
			unit_sprite.flip_h = false
	elif swing_progress > 0.0:
		unit_sprite.position.y = SPRITE_BASE_Y + sin(swing_progress * PI) * 0.18
		unit_sprite.rotation.z = (-0.22 if not unit_sprite.flip_h else 0.22) * sin(swing_progress * PI)
	else:
		unit_sprite.position.y = SPRITE_BASE_Y + sin(Time.get_ticks_msec() * 0.003) * 0.03
		unit_sprite.rotation.z = 0.0

func _update_status_label() -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = get_task_description_turkish()
	match state:
		State.IDLE:
			status_label.modulate = Color(1.0, 0.85, 0.35)
		State.GATHERING:
			status_label.modulate = Color(0.35, 1.0, 0.45)
		State.RETURNING_RESOURCES:
			status_label.modulate = Color(0.40, 0.85, 1.0)
		State.BUILDING:
			status_label.modulate = Color(1.0, 0.72, 0.30)
		State.ATTACKING:
			status_label.modulate = Color(1.0, 0.32, 0.32)
		_:
			status_label.modulate = Color(1.0, 0.95, 0.75)

func get_task_description_turkish() -> String:
	match state:
		State.IDLE:
			return "💤 [ BOŞTA ]"
		State.MOVING:
			return "🚶 İlerliyor..."
		State.ATTACKING:
			if is_instance_valid(target_entity):
				return "⚔️ Saldırıyor!"
			return "🛡️ Savaşa Hazır"
		State.GATHERING:
			if resource_type == "wood":
				return "🪵 Ağaç Kesiyor (%d/%d)" % [carried_resource, max_carry]
			elif resource_type == "gold":
				return "🪙 Altın Kazıyor (%d/%d)" % [carried_resource, max_carry]
			elif resource_type == "stone":
				return "🪨 Taş Çıkarıyor (%d/%d)" % [carried_resource, max_carry]
			elif resource_type == "food":
				return "🌾 Hasat Yapıyor (%d/%d)" % [carried_resource, max_carry]
			return "📦 Kaynak Topluyor"
		State.RETURNING_RESOURCES:
			return "📦 Depoya Taşıyor (%d/%d)" % [carried_resource, max_carry]
		State.BUILDING:
			if is_instance_valid(target_entity) and target_entity is Building3D:
				return "🔨 İnşa Ediyor (%%%d)" % int(target_entity.construction_progress)
			return "🔨 İnşaat Yapıyor"
		_:
			return "🛡️ Hazır"

func _update_hp_bar() -> void:
	if not is_instance_valid(hp_fill_mesh) or not is_instance_valid(hp_bar_mesh):
		return
	var show_bar = is_selected or hp < max_hp
	var parent_holder = hp_bar_mesh.get_parent() as Node3D
	if parent_holder:
		parent_holder.visible = show_bar

	if show_bar:
		var pct = clamp(hp / max_hp, 0.0, 1.0)
		hp_fill_mesh.scale.x = pct
		hp_fill_mesh.position.x = -(0.86 * (1.0 - pct)) * 0.5
