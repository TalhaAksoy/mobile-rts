class_name Building3D
extends StaticBody3D

const PixelArtTextures = preload("res://scripts/PixelArtTextures.gd")

signal destroyed(building)
signal completed(building)
signal unit_trained(unit_type, team, spawn_pos)
signal research_completed(tech_id, team)

enum BuildingType {
	TOWN_CENTER,
	HOUSE,
	BARRACKS,
	ARCHERY_RANGE,
	STABLE,
	CASTLE,
	TOWER,
	FARM,
	BLACKSMITH
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
var construction_progress: float = 100.0

var is_selected: bool = false
var rally_point: Vector3

var train_queue: Array = []
var current_train_timer: float = 0.0
var current_train_duration: float = 5.0

var is_researching: bool = false
var current_research_tech: String = ""
var current_research_timer: float = 0.0
var current_research_duration: float = 1.0

var shoot_timer: float = 0.0
var shoot_cooldown: float = 1.5
var shoot_range: float = 11.0
var shoot_damage: float = 12.0

var map_gen: MapGenerator3D = null
var main_game: Node = null

var model_root: Node3D
var scaffold_node: Node3D
var selection_mesh: MeshInstance3D
var hp_bar_holder: Node3D
var hp_fill_mesh: MeshInstance3D
var flag_sprites: Array[Sprite3D] = []
var anim_time: float = 0.0

func _ready() -> void:
	rally_point = global_position + Vector3(0, 0, grid_size.y * MapGenerator3D.TILE_SIZE * 0.5 + 2.0)

func setup_building(b_type: BuildingType, t: int, civ: CivData.CivType, cell: Vector2i, map: MapGenerator3D, game: Node, start_under_construction: bool = false) -> void:
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

	rally_point = global_position + Vector3(0, 0, grid_size.y * MapGenerator3D.TILE_SIZE * 0.5 + 2.0)
	_build_3d_structure()

func _init_building_stats() -> void:
	var civ_cfg = CivData.get_civ(civ_type)

	match building_type:
		BuildingType.TOWN_CENTER:
			grid_size = Vector2i(3, 3)
			max_hp = 2400.0
			armor = 6.0
			shoot_range = 13.0
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
			shoot_range = 15.0
			shoot_damage = 18.0
			shoot_cooldown = 1.0
		BuildingType.TOWER:
			grid_size = Vector2i(2, 2)
			max_hp = 1000.0
			armor = 5.0
			shoot_range = 12.0
			shoot_damage = 14.0
			shoot_cooldown = 1.3
		BuildingType.FARM:
			grid_size = Vector2i(2, 2)
			max_hp = 400.0
			armor = 0.0
		BuildingType.BLACKSMITH:
			grid_size = Vector2i(2, 2)
			max_hp = 1100.0
			armor = 4.0

	if civ_cfg.has("building_hp_mult"):
		max_hp *= civ_cfg["building_hp_mult"]
	if civ_cfg.has("tower_damage_mult") and (building_type == BuildingType.TOWER or building_type == BuildingType.TOWN_CENTER):
		shoot_damage *= civ_cfg["tower_damage_mult"]

func _create_flag_sprite(pos: Vector3, p_size: float = 0.05) -> Sprite3D:
	var flag = Sprite3D.new()
	flag.texture = PixelArtTextures.get_civ_flag_texture(civ_type)
	flag.pixel_size = p_size
	flag.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	flag.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	flag.shaded = false
	flag.render_priority = 16
	flag.position = pos
	model_root.add_child(flag)
	flag_sprites.append(flag)
	return flag

func _build_3d_structure() -> void:
	flag_sprites.clear()
	for child in get_children():
		child.queue_free()

	model_root = Node3D.new()
	add_child(model_root)

	var team_col = Color(0.18, 0.52, 0.95) if team == 0 else Color(0.92, 0.22, 0.22)
	var civ_cfg = CivData.get_civ(civ_type)
	var civ_flag = civ_cfg.get("flag_color", team_col)

	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_texture = PixelArtTextures.get_stone_brick_texture()
	stone_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	stone_mat.uv1_scale = Vector3(2, 2, 2)
	stone_mat.roughness = 0.85

	var dark_stone_mat = StandardMaterial3D.new()
	dark_stone_mat.albedo_texture = PixelArtTextures.get_stone_brick_texture()
	dark_stone_mat.albedo_color = Color(0.70, 0.70, 0.75)
	dark_stone_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	dark_stone_mat.uv1_scale = Vector3(1.5, 2, 1.5)
	dark_stone_mat.roughness = 0.9

	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_texture = PixelArtTextures.get_roof_tile_texture()
	roof_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	roof_mat.uv1_scale = Vector3(3, 3, 3)
	roof_mat.roughness = 0.7

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_texture = PixelArtTextures.get_wood_plank_texture()
	wood_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	wood_mat.uv1_scale = Vector3(2, 2, 2)
	wood_mat.roughness = 0.85

	var timber_mat = StandardMaterial3D.new()
	timber_mat.albedo_texture = PixelArtTextures.get_timber_wall_texture()
	timber_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	timber_mat.uv1_scale = Vector3(1, 1, 1)
	timber_mat.roughness = 0.85

	var straw_mat = StandardMaterial3D.new()
	straw_mat.albedo_color = Color(0.78, 0.65, 0.35)
	straw_mat.roughness = 0.9

	var flag_mat = StandardMaterial3D.new()
	flag_mat.albedo_texture = PixelArtTextures.get_civ_flag_texture(civ_type)
	flag_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	flag_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	flag_mat.roughness = 0.85

	var window_mat = StandardMaterial3D.new()
	window_mat.albedo_color = Color(1.0, 0.88, 0.42)
	window_mat.emission_enabled = true
	window_mat.emission = Color(1.0, 0.82, 0.35)
	window_mat.emission_energy_multiplier = 1.35

	var w = grid_size.x * MapGenerator3D.TILE_SIZE * 0.9
	var l = grid_size.y * MapGenerator3D.TILE_SIZE * 0.9

	# 3D Scaffolding frame (shown when under construction)
	scaffold_node = Node3D.new()
	var scaf_mesh = BoxMesh.new()
	scaf_mesh.size = Vector3(w, 2.0, l)
	var scaf_inst = MeshInstance3D.new()
	scaf_inst.mesh = scaf_mesh
	scaf_inst.position = Vector3(0, 1.0, 0)
	var scaf_mat = StandardMaterial3D.new()
	scaf_mat.albedo_color = Color(0.4, 0.28, 0.16, 0.5)
	scaf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scaf_inst.material_override = scaf_mat
	scaffold_node.add_child(scaf_inst)
	add_child(scaffold_node)
	scaffold_node.visible = not is_completed

	# Completed Architecture
	match building_type:
		BuildingType.TOWN_CENTER:
			# Main Keep
			var keep = MeshInstance3D.new()
			var k_mesh = BoxMesh.new()
			k_mesh.size = Vector3(w * 0.75, 2.4, l * 0.75)
			keep.mesh = k_mesh
			keep.position = Vector3(0, 1.2, 0)
			keep.material_override = stone_mat
			model_root.add_child(keep)

			# Glowing warm lantern windows
			for wx in [-0.5, 0.5]:
				var win = MeshInstance3D.new()
				var win_m = BoxMesh.new()
				win_m.size = Vector3(0.35, 0.45, 0.04)
				win.mesh = win_m
				win.position = Vector3(wx * (w * 0.3), 1.3, l * 0.38)
				win.material_override = window_mat
				model_root.add_child(win)

			# Grand Wooden Entrance Door on Front
			var door = MeshInstance3D.new()
			var d_mesh = BoxMesh.new()
			d_mesh.size = Vector3(1.1, 1.4, 0.08)
			door.mesh = d_mesh
			door.position = Vector3(0, 0.7, l * 0.38)
			door.material_override = wood_mat
			model_root.add_child(door)

			# Roof
			var roof = MeshInstance3D.new()
			var rf_mesh = PrismMesh.new()
			rf_mesh.size = Vector3(w * 0.8, 1.2, l * 0.8)
			roof.mesh = rf_mesh
			roof.position = Vector3(0, 3.0, 0)
			roof.material_override = roof_mat
			model_root.add_child(roof)

			# 4 Corner Battlement Towers
			for dx in [-1, 1]:
				for dz in [-1, 1]:
					var tower = MeshInstance3D.new()
					var tw_mesh = BoxMesh.new()
					tw_mesh.size = Vector3(0.9, 3.2, 0.9)
					tower.mesh = tw_mesh
					tower.position = Vector3(dx * (w * 0.4), 1.6, dz * (l * 0.4))
					tower.material_override = dark_stone_mat
					model_root.add_child(tower)

			# Center Flag Pole & Fluttering Royal Civ Flag
			var pole = MeshInstance3D.new()
			var pl_mesh = CylinderMesh.new()
			pl_mesh.top_radius = 0.05
			pl_mesh.bottom_radius = 0.05
			pl_mesh.height = 2.2
			pole.mesh = pl_mesh
			pole.position = Vector3(0, 4.4, 0)
			pole.material_override = dark_stone_mat
			model_root.add_child(pole)

			_create_flag_sprite(Vector3(0.65, 4.8, 0), 0.052)

		BuildingType.HOUSE:
			var cottage = MeshInstance3D.new()
			var c_mesh = BoxMesh.new()
			c_mesh.size = Vector3(w * 0.75, 1.4, l * 0.75)
			cottage.mesh = c_mesh
			cottage.position = Vector3(0, 0.7, 0)
			cottage.material_override = timber_mat
			model_root.add_child(cottage)

			# Glowing warm window
			var h_win = MeshInstance3D.new()
			var hw_m = BoxMesh.new()
			hw_m.size = Vector3(0.28, 0.32, 0.04)
			h_win.mesh = hw_m
			h_win.position = Vector3(0, 0.8, l * 0.38)
			h_win.material_override = window_mat
			model_root.add_child(h_win)

			var roof = MeshInstance3D.new()
			var rf_mesh = PrismMesh.new()
			rf_mesh.size = Vector3(w * 0.85, 0.9, l * 0.85)
			roof.mesh = rf_mesh
			roof.position = Vector3(0, 1.85, 0)
			roof.material_override = roof_mat
			model_root.add_child(roof)

		BuildingType.BARRACKS:
			var hall = MeshInstance3D.new()
			var h_mesh = BoxMesh.new()
			h_mesh.size = Vector3(w * 0.8, 1.8, l * 0.7)
			hall.mesh = h_mesh
			hall.position = Vector3(0, 0.9, 0)
			hall.material_override = stone_mat
			model_root.add_child(hall)

			var b_roof = MeshInstance3D.new()
			var br_mesh = PrismMesh.new()
			br_mesh.size = Vector3(w * 0.85, 0.9, l * 0.75)
			b_roof.mesh = br_mesh
			b_roof.position = Vector3(0, 2.25, 0)
			b_roof.material_override = roof_mat
			model_root.add_child(b_roof)

			_create_flag_sprite(Vector3(0, 2.7, l * 0.38), 0.042)

		BuildingType.ARCHERY_RANGE:
			var range_box = MeshInstance3D.new()
			var r_mesh = BoxMesh.new()
			r_mesh.size = Vector3(w * 0.75, 1.4, l * 0.75)
			range_box.mesh = r_mesh
			range_box.position = Vector3(0, 0.7, 0)
			range_box.material_override = wood_mat
			model_root.add_child(range_box)

			# Archery Target
			var target = MeshInstance3D.new()
			var t_mesh = CylinderMesh.new()
			t_mesh.top_radius = 0.4
			t_mesh.bottom_radius = 0.4
			t_mesh.height = 0.1
			target.mesh = t_mesh
			target.position = Vector3(0, 0.8, l * 0.42)
			target.rotation_degrees = Vector3(90, 0, 0)
			var tg_mat = StandardMaterial3D.new()
			tg_mat.albedo_color = Color(0.95, 0.2, 0.2)
			target.material_override = tg_mat
			model_root.add_child(target)

		BuildingType.STABLE:
			var barn = MeshInstance3D.new()
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(w * 0.8, 1.6, l * 0.7)
			barn.mesh = b_mesh
			barn.position = Vector3(0, 0.8, 0)
			barn.material_override = timber_mat
			model_root.add_child(barn)

			var s_roof = MeshInstance3D.new()
			var sr_mesh = PrismMesh.new()
			sr_mesh.size = Vector3(w * 0.85, 0.8, l * 0.75)
			s_roof.mesh = sr_mesh
			s_roof.position = Vector3(0, 2.0, 0)
			s_roof.material_override = roof_mat
			model_root.add_child(s_roof)

			# Hay Bale
			var hay = MeshInstance3D.new()
			var hy_mesh = BoxMesh.new()
			hy_mesh.size = Vector3(0.9, 0.6, 0.9)
			hay.mesh = hy_mesh
			hay.position = Vector3(-w * 0.35, 0.3, l * 0.25)
			hay.material_override = straw_mat
			model_root.add_child(hay)

		BuildingType.CASTLE:
			# High Citadel Fortress
			var keep = MeshInstance3D.new()
			var k_mesh = BoxMesh.new()
			k_mesh.size = Vector3(w * 0.8, 3.5, l * 0.8)
			keep.mesh = k_mesh
			keep.position = Vector3(0, 1.75, 0)
			keep.material_override = stone_mat
			model_root.add_child(keep)

			# 4 High Battlement Turrets
			for dx in [-1, 1]:
				for dz in [-1, 1]:
					var turret = MeshInstance3D.new()
					var tr_mesh = CylinderMesh.new()
					tr_mesh.top_radius = 0.7
					tr_mesh.bottom_radius = 0.8
					tr_mesh.height = 4.8
					turret.mesh = tr_mesh
					turret.position = Vector3(dx * (w * 0.42), 2.4, dz * (l * 0.42))
					turret.material_override = dark_stone_mat
					model_root.add_child(turret)

			# Grand Keep Flag Pole & Royal Civ Flag
			var pole = MeshInstance3D.new()
			var pl_mesh = CylinderMesh.new()
			pl_mesh.top_radius = 0.06
			pl_mesh.bottom_radius = 0.06
			pl_mesh.height = 2.6
			pole.mesh = pl_mesh
			pole.position = Vector3(0, 5.2, 0)
			pole.material_override = dark_stone_mat
			model_root.add_child(pole)

			_create_flag_sprite(Vector3(0.85, 5.8, 0), 0.068)

		BuildingType.TOWER:
			var tower = MeshInstance3D.new()
			var tw_mesh = BoxMesh.new()
			tw_mesh.size = Vector3(w * 0.65, 3.8, l * 0.65)
			tower.mesh = tw_mesh
			tower.position = Vector3(0, 1.9, 0)
			tower.material_override = dark_stone_mat
			model_root.add_child(tower)

			# Parapet Top
			var top = MeshInstance3D.new()
			var tp_mesh = BoxMesh.new()
			tp_mesh.size = Vector3(w * 0.8, 0.6, l * 0.8)
			top.mesh = tp_mesh
			top.position = Vector3(0, 4.0, 0)
			top.material_override = stone_mat
			model_root.add_child(top)

			# Tower Pennant Pole & Flag
			var pole = MeshInstance3D.new()
			var pl_mesh = CylinderMesh.new()
			pl_mesh.top_radius = 0.04
			pl_mesh.bottom_radius = 0.04
			pl_mesh.height = 1.6
			pole.mesh = pl_mesh
			pole.position = Vector3(0, 4.8, 0)
			pole.material_override = dark_stone_mat
			model_root.add_child(pole)

			_create_flag_sprite(Vector3(0.5, 5.2, 0), 0.045)

		BuildingType.FARM:
			var soil = MeshInstance3D.new()
			var sl_mesh = BoxMesh.new()
			sl_mesh.size = Vector3(w * 0.95, 0.2, l * 0.95)
			soil.mesh = sl_mesh
			soil.position = Vector3(0, 0.1, 0)
			var sl_mat = StandardMaterial3D.new()
			sl_mat.albedo_color = Color(0.38, 0.25, 0.15)
			soil.material_override = sl_mat
			model_root.add_child(soil)

			# Wheat Crop Rows
			for i in range(-2, 3):
				var crop = MeshInstance3D.new()
				var cp_mesh = BoxMesh.new()
				cp_mesh.size = Vector3(w * 0.85, 0.45, 0.3)
				crop.mesh = cp_mesh
				crop.position = Vector3(0, 0.35, i * (l * 0.18))
				var cp_mat = StandardMaterial3D.new()
				cp_mat.albedo_color = Color(0.85, 0.75, 0.2)
				crop.material_override = cp_mat
				model_root.add_child(crop)

		BuildingType.BLACKSMITH:
			# Workshop Base
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(w * 0.85, 1.4, l * 0.85)
			var base_inst = MeshInstance3D.new()
			base_inst.mesh = b_mesh
			base_inst.position = Vector3(0, 0.7, 0)
			base_inst.material_override = stone_mat
			model_root.add_child(base_inst)

			# Tiled Workshop Roof
			var r_mesh = PrismMesh.new()
			r_mesh.size = Vector3(w * 0.95, 0.9, l * 0.95)
			var roof = MeshInstance3D.new()
			roof.mesh = r_mesh
			roof.position = Vector3(0, 1.85, 0)
			roof.material_override = roof_mat
			model_root.add_child(roof)

			# Stone Chimney
			var ch_mesh = BoxMesh.new()
			ch_mesh.size = Vector3(0.5, 2.0, 0.5)
			var chimney = MeshInstance3D.new()
			chimney.mesh = ch_mesh
			chimney.position = Vector3(w * 0.28, 1.5, l * 0.28)
			chimney.material_override = stone_mat
			model_root.add_child(chimney)

			# Glowing Forge Fire
			var f_mesh = BoxMesh.new()
			f_mesh.size = Vector3(0.6, 0.5, 0.6)
			var forge = MeshInstance3D.new()
			forge.mesh = f_mesh
			forge.position = Vector3(-w * 0.25, 0.3, l * 0.35)
			var f_mat = StandardMaterial3D.new()
			f_mat.albedo_color = Color(1.0, 0.35, 0.05)
			f_mat.emission_enabled = true
			f_mat.emission = Color(1.0, 0.45, 0.1)
			f_mat.emission_energy_multiplier = 2.0
			forge.material_override = f_mat
			model_root.add_child(forge)

			# Anvil
			var an_mesh = BoxMesh.new()
			an_mesh.size = Vector3(0.35, 0.4, 0.55)
			var anvil = MeshInstance3D.new()
			anvil.mesh = an_mesh
			anvil.position = Vector3(-w * 0.25, 0.2, -l * 0.32)
			var an_mat = StandardMaterial3D.new()
			an_mat.albedo_color = Color(0.2, 0.22, 0.25)
			an_mat.metallic = 0.8
			an_mat.roughness = 0.3
			anvil.material_override = an_mat
			model_root.add_child(anvil)

	# Representative Heraldic Building Signboard (Visual icon in 3D world)
	var signboard = Sprite3D.new()
	signboard.texture = PixelArtTextures.get_building_icon_texture(building_type)
	signboard.pixel_size = 0.040
	signboard.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	signboard.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	signboard.no_depth_test = true
	signboard.render_priority = 25
	var sign_y = 3.6 if building_type in [BuildingType.TOWN_CENTER, BuildingType.CASTLE] else 2.5
	if building_type == BuildingType.TOWER:
		sign_y = 4.4
	elif building_type == BuildingType.FARM:
		sign_y = 1.8
	var sign_z = 0.0 if building_type in [BuildingType.TOWER, BuildingType.FARM] else l * 0.44
	signboard.position = Vector3(0, sign_y, sign_z)
	model_root.add_child(signboard)

	# 3D Selection Box
	selection_mesh = MeshInstance3D.new()
	var sb_mesh = BoxMesh.new()
	sb_mesh.size = Vector3(w * 1.05, 0.1, l * 1.05)
	selection_mesh.mesh = sb_mesh
	selection_mesh.position = Vector3(0, 0.05, 0)
	var sm_mat = StandardMaterial3D.new()
	sm_mat.albedo_color = Color(0.2, 0.95, 0.3, 0.7)
	sm_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm_mat.emission_enabled = true
	sm_mat.emission = Color(0.2, 0.95, 0.3)
	selection_mesh.material_override = sm_mat
	selection_mesh.visible = false
	add_child(selection_mesh)

	# 3D Health Bar
	_build_3d_hp_bar(4.6 if building_type in [BuildingType.CASTLE, BuildingType.TOWER, BuildingType.TOWN_CENTER] else 2.6)

func _build_3d_hp_bar(height_y: float) -> void:
	hp_bar_holder = Node3D.new()
	hp_bar_holder.position = Vector3(0, height_y, 0)
	add_child(hp_bar_holder)

	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(1.6, 0.14, 0.05)
	var bg = MeshInstance3D.new()
	bg.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.1, 0.1, 0.1, 0.85)
	bg.material_override = bg_mat
	hp_bar_holder.add_child(bg)

	hp_fill_mesh = MeshInstance3D.new()
	var fill_mesh = BoxMesh.new()
	fill_mesh.size = Vector3(1.54, 0.11, 0.06)
	hp_fill_mesh.mesh = fill_mesh
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.2, 0.9, 0.2)
	hp_fill_mesh.material_override = fill_mat
	hp_bar_holder.add_child(hp_fill_mesh)

	hp_bar_holder.rotation_degrees = Vector3(-56, 0, 0)
	hp_bar_holder.visible = false

func _process(delta: float) -> void:
	anim_time += delta
	for f in flag_sprites:
		if is_instance_valid(f):
			f.rotation.z = sin(anim_time * 3.4 + global_position.x) * 0.08
			f.scale.x = 1.0 + sin(anim_time * 4.2 + global_position.z) * 0.04

	if not is_completed:
		return

	if can_shoot():
		if shoot_timer > 0.0:
			shoot_timer -= delta
		else:
			_check_and_shoot_enemies()

	if train_queue.size() > 0:
		current_train_timer += delta
		if current_train_timer >= current_train_duration:
			var trained = train_queue.pop_front()
			current_train_timer = 0.0
			_spawn_unit(trained)
			if train_queue.size() > 0:
				current_train_duration = train_queue[0]["duration"]

	if is_researching:
		current_research_timer += delta
		if current_research_timer >= current_research_duration:
			is_researching = false
			var completed_tech = current_research_tech
			current_research_tech = ""
			research_completed.emit(completed_tech, team)

func start_research(tech_id: String, duration: float) -> bool:
	if is_researching or not is_completed:
		return false
	is_researching = true
	current_research_tech = tech_id
	current_research_timer = 0.0
	current_research_duration = duration
	return true

func get_research_progress() -> float:
	if not is_researching or current_research_duration <= 0.0:
		return 0.0
	return clamp((current_research_timer / current_research_duration) * 100.0, 0.0, 100.0)

func can_shoot() -> bool:
	return building_type in [BuildingType.TOWN_CENTER, BuildingType.TOWER, BuildingType.CASTLE]

func _check_and_shoot_enemies() -> void:
	if main_game == null:
		return
	var target = main_game.get_closest_enemy_entity(global_position, team, shoot_range)
	if target != null:
		shoot_timer = shoot_cooldown
		SoundManager.play_sound("shoot")
		main_game.spawn_projectile(global_position + Vector3(0, 2.5, 0), target, shoot_damage, team, false)

func queue_unit_production(u_type: Unit3D.UnitType, duration: float) -> bool:
	var civ_cfg = CivData.get_civ(civ_type)
	var final_duration = duration * civ_cfg.get("train_speed_mult", 1.0)
	train_queue.append({"type": u_type, "duration": final_duration})
	if train_queue.size() == 1:
		current_train_timer = 0.0
		current_train_duration = final_duration
	return true

func _spawn_unit(item: Dictionary) -> void:
	var u_type = item["type"]
	unit_trained.emit(u_type, team, rally_point)
	SoundManager.play_sound("train")

func contribute_construction(amt: float) -> void:
	if is_completed:
		return
	construction_progress += amt
	hp = max_hp * clamp(construction_progress / 100.0, 0.1, 1.0)
	_update_hp_bar()

	if construction_progress >= 100.0:
		construction_progress = 100.0
		is_completed = true
		hp = max_hp
		if is_instance_valid(scaffold_node):
			scaffold_node.visible = false
		completed.emit(self)
		SoundManager.play_sound("build")

func take_damage(amount: float, _attacker_team: int) -> void:
	var actual_dmg = max(1.0, amount - armor)
	hp -= actual_dmg
	_update_hp_bar()
	if hp <= 0:
		hp = 0
		die()

func die() -> void:
	destroyed.emit(self)
	if map_gen != null:
		map_gen.unregister_building_cells(origin_cell, grid_size)
	SoundManager.play_sound("hit")
	queue_free()

func set_selected(sel: bool) -> void:
	is_selected = sel
	if is_instance_valid(selection_mesh):
		selection_mesh.visible = sel
	_update_hp_bar()

func _update_hp_bar() -> void:
	if not is_instance_valid(hp_bar_holder) or not is_instance_valid(hp_fill_mesh):
		return
	var show_bar = is_selected or hp < max_hp
	hp_bar_holder.visible = show_bar

	if show_bar:
		var pct = clamp(hp / max_hp, 0.0, 1.0)
		hp_fill_mesh.scale.x = pct
		hp_fill_mesh.position.x = -(1.54 * (1.0 - pct)) * 0.5
