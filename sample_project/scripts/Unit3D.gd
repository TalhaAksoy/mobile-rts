class_name Unit3D
extends CharacterBody3D

const PixelArtTextures = preload("res://scripts/PixelArtTextures.gd")
const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

const SPRITE_PIXEL_SIZE: float = 0.022
## 3D units and their 2D sheets are shown 25 % larger than life (2.25 m villager) so they read on screen as
## big as the gallery sprites they replace; buildings and the gameplay footprint are unchanged.
const UNIT_VISUAL_SCALE: float = 1.25
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

## Army orders (SALDIR / SAVUN buttons). NONE = plain behaviour: a move ignores enemies, an idle soldier
## attacks what comes close. ATTACK_MOVE: walk to order_pos and fight everything met on the way and there.
## DEFEND: hold order_pos, fight enemies that come within DEFEND_RADIUS of it, walk back after the fight.
enum Order { NONE, ATTACK_MOVE, DEFEND }
var order: int = Order.NONE
var order_pos: Vector3 = Vector3.ZERO
var _order_scan_t: float = 0.0
const DEFEND_RADIUS := 9.0          # enemies this close to the post are engaged
const DEFEND_LEASH := 13.0          # a chase further than this from the post is given up
const ORDER_ARRIVE := 1.6

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
## What a villager carries before walking back. Techs add to it (TechData "carry").
var max_carry: int = 5
const AUTO_GATHER_SEARCH_RADIUS: float = 16.0
## Every harvest swing takes exactly 1 resource; this is the time between swings, in seconds.
## Civ and tech gather bonuses make the swings faster, never bigger, so the load counts up 1 by 1.
const GATHER_INTERVAL := {"wood": 0.4, "food": 0.4, "gold": 0.5, "stone": 0.5, "field": 0.5}
var last_resource_pos: Vector3 = Vector3.ZERO

var attack_timer: float = 0.0
var swing_progress: float = 0.0
var walk_timer: float = 0.0
## Gatherers work right next to the node and unload right next to the drop-off building: the A* path
## ends in the neighbouring cell, then the villager walks the last metre straight in. If it is blocked
## for longer than APPROACH_TIMEOUT (another unit in the way), it works from where it stands.
const GATHER_REACH: float = 0.6     # metres from the resource cell's edge
const DROPOFF_REACH: float = 0.8    # metres from the building footprint's edge
const APPROACH_TIMEOUT: float = 1.5
var approach_time: float = 0.0
var _dropoff_repathed := false
var regen_rate: float = 0.0

var map_gen: MapGenerator3D = null
var main_game: Node = null

# 3D Node references for animation
var model_root: Node3D
var unit_sprite: Sprite3D
## Occlusion silhouette: team-coloured copy drawn without depth test BEFORE the real sprite
## (transparent pass ordering), so units hidden behind 3D trees/buildings stay visible/selectable.
var occlusion_silhouette: Sprite3D
var weapon_node: Node3D
var selection_ring: MeshInstance3D
var hp_bar_mesh: MeshInstance3D
var hp_fill_mesh: MeshInstance3D
var resource_sack: MeshInstance3D
var status_label: Label3D
## Always-on activity badge over the player's villagers (VillagerBadge.gd); null for everyone else.
var badge: VillagerBadge = null
const BADGE_Y: float = 2.75

# Articulated Limbs & Anatomy
var leg_left_pivot: Node3D
var leg_right_pivot: Node3D
var arm_left_pivot: Node3D
var arm_right_pivot: Node3D
var torso_pivot: Node3D
var head_pivot: Node3D
var horse_legs: Array[Node3D] = []

# Rigged 3D character (FactionArtManager.instantiate_unit_model). null -> the sprite path below is used.
var unit_model: Node3D = null
var unit_anim: AnimationPlayer = null
var _anim_name := ""
var _last_swing := 0.0
var _cargo_props: Dictionary = {}     # resource type -> PROP_cargo_* node
## 2D style: sprite sheet rendered from the 3D unit (FactionArtManager.get_unit_sheet_entry); {} -> old sprite
var sheet: Dictionary = {}
var _sheet_time := 0.0

# Villager tools & backpack basket
var tool_axe: Node3D
var tool_pickaxe: Node3D
var tool_hammer: Node3D
var basket_node: Node3D
var basket_wood: Node3D
var basket_gold: Node3D
var basket_food: Node3D

## Age look (1 Köy / 2 Hisar / 3 İmparatorluk): set by the game before setup_unit and on age-up (set_age_look).
## 2 = the base art, used by tools and tests that make a unit on its own. Villagers look the same in every age.
var age_look: int = 2

func _ready() -> void:
	_init_stats()
	_build_3d_model()

## Age-up: soldiers on the field change into the new age's kit (the whole visual is rebuilt in place).
func set_age_look(age: int) -> void:
	if age == age_look:
		return
	age_look = age
	if unit_type == UnitType.VILLAGER or hp <= 0.0 or not is_inside_tree():
		return
	var was_selected := is_selected
	_build_3d_model()
	if was_selected:
		set_selected(true)

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

	# 0. Rigged 3D character when the visual style is 3D and this civ/role has one
	unit_model = FactionArtManager.instantiate_unit_model(civ_type, unit_type, team, age_look)
	unit_anim = null
	_cargo_props.clear()
	_anim_name = ""
	if unit_model != null:
		unit_model.name = "UnitModel"
		unit_model.scale = Vector3.ONE * UNIT_VISUAL_SCALE
		add_child(unit_model)            # not under model_root: the procedural sprite bob must not move it
		unit_anim = unit_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		for n in unit_model.find_children("PROP_cargo_*", "", true, false):
			_cargo_props[String(n.name).trim_prefix("PROP_cargo_")] = n
			n.visible = false
		_play_anim("idle")
	else:
		_build_unit_sprite()

	_build_selection_and_bars()

func _build_unit_sprite() -> void:
	# 1. Authentic Faction Art Billboard Sprite (Shaded HD-2D)
	unit_sprite = Sprite3D.new()
	sheet = FactionArtManager.get_unit_sheet_entry(civ_type, unit_type, age_look) if not FactionArtManager.use_3d_building_models else {}
	if not sheet.is_empty() and ResourceLoader.exists(sheet.get("t%d" % clampi(team, 0, 1), "")):
		_setup_sheet_sprite()
		return
	sheet = {}
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
	# Real sprite renders in the transparent pass (with a depth prepass so it still sorts/occludes
	# correctly) AFTER the silhouette below; where the unit is visible it fully covers the silhouette.
	unit_sprite.alpha_cut = Sprite3D.ALPHA_CUT_OPAQUE_PREPASS
	unit_sprite.render_priority = 2
	model_root.add_child(unit_sprite)

	_add_sprite_silhouette()

## Billboard showing one frame of the unit's sprite sheet, feet (sheet anchor) on the ground.
## Oblique sheets ("view": "oblique", 2D style seen from straight above) lie flat instead, see below.
func _setup_sheet_sprite() -> void:
	unit_sprite.texture = load(sheet["t%d" % clampi(team, 0, 1)])
	unit_sprite.hframes = int(sheet["hframes"])
	unit_sprite.vframes = int(sheet["vframes"])
	if sheet.get("view", "") == "oblique":
		_setup_oblique_sheet_sprite()
		return
	unit_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	unit_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	unit_sprite.shaded = false
	unit_sprite.pixel_size = UNIT_VISUAL_SCALE / float(sheet.get("px_per_m", 32))
	var w: float = sheet["w"]
	var h: float = sheet["h"]
	var anchor: Array = sheet["anchor"]
	unit_sprite.offset = Vector2(w * 0.5 - float(anchor[0]), float(anchor[1]) - h * 0.5)
	unit_sprite.alpha_cut = Sprite3D.ALPHA_CUT_OPAQUE_PREPASS
	unit_sprite.render_priority = 2
	model_root.add_child(unit_sprite)
	_add_sprite_silhouette()
	_anim_name = ""
	_set_sheet_anim("idle")

## 2D style seen from straight above: the 3/4-view frame lies flat (image-up = north) with the feet (sheet
## anchor) on the unit's position. It does not turn with the unit (the sheet faces front-left and is mirrored
## when walking right) and sits at its painter's-order height every frame (FactionArtManager.oblique_sort_y).
## No X-ray silhouette: the sort order already draws a unit in front of what is north of it.
func _setup_oblique_sheet_sprite() -> void:
	unit_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	unit_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	unit_sprite.shaded = false
	unit_sprite.pixel_size = UNIT_VISUAL_SCALE / float(sheet.get("px_per_m", 20))
	var w: float = sheet["w"]
	var h: float = sheet["h"]
	var anchor: Array = sheet["anchor"]
	unit_sprite.offset = Vector2(w * 0.5 - float(anchor[0]), float(anchor[1]) - h * 0.5)
	unit_sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	unit_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model_root.add_child(unit_sprite)
	_anim_name = ""
	_set_sheet_anim("idle")
	_place_oblique_visuals()

## Every frame: flat, unrotated sprite at the sort height; hp bar, status label and badge float above the head
## (north on screen), flat to the camera.
func _place_oblique_visuals() -> void:
	if not is_inside_tree() or not is_instance_valid(unit_sprite):
		return
	var gp := global_position
	unit_sprite.global_rotation = Vector3(-PI * 0.5, 0, 0)
	unit_sprite.global_position = Vector3(gp.x, FactionArtManager.oblique_sort_y(gp.z), gp.z)
	var head_north: float = float(sheet["anchor"][1]) / float(sheet.get("px_per_m", 20)) * UNIT_VISUAL_SCALE
	var holder: Node3D = hp_bar_mesh.get_parent() as Node3D if is_instance_valid(hp_bar_mesh) else null
	for n in [holder, status_label, badge]:
		if n == null or not is_instance_valid(n):
			continue
		if not n.top_level:
			n.top_level = true
			n.set_meta("td_y", n.position.y)
		# keep the 3D stacking order on screen: higher in 3D -> further north here
		var north: float = head_north + 0.25 + maxf(0.0, float(n.get_meta("td_y")) - 2.7) * 0.5
		n.global_position = Vector3(gp.x, 11.0, gp.z - north)
	if holder != null and is_instance_valid(holder):
		holder.global_rotation = Vector3(-PI * 0.5, 0, 0)
	# selection ring on the ground under the feet: below every unit sprite, above fields and ground decals
	if is_instance_valid(selection_ring):
		if not selection_ring.top_level:
			selection_ring.top_level = true
			var m := selection_ring.material_override as StandardMaterial3D
			if m != null:
				m.no_depth_test = false
				m.render_priority = 0
			var tm := selection_ring.mesh as TorusMesh
			if tm != null:                       # thinner flat ring in pixel-art scale
				var r := get_body_radius() * 0.6 + 0.3
				tm.outer_radius = r
				tm.inner_radius = r - 0.12
		selection_ring.global_position = Vector3(gp.x, FactionArtManager.OBLIQUE_SORT_BASE - 0.3, gp.z)
		selection_ring.global_rotation = Vector3.ZERO

## Stencil X-Ray for billboards (the built-in STENCIL_MODE_XRAY pass ignores the texture alpha and would tint the
## whole quad): the sprite marks only its opaque pixels in the stencil buffer, the next pass draws the sprite
## shape in the team tint where something is in front (inverted depth) and no unit sprite is (stencil).
## So the tint shows only behind buildings and trees, never over the visible sprite or another unit.
static var _sprite_mat_cache: Dictionary = {}
const SPRITE_STENCIL_REF := 7

func _add_sprite_silhouette() -> void:
	var key := "%s_%d_%s" % [unit_sprite.texture.resource_path, team, unit_sprite.shaded]
	if not _sprite_mat_cache.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = unit_sprite.texture
		mat.vertex_color_use_as_albedo = true            # keeps Sprite3D.modulate
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if unit_sprite.shaded else BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 0.5
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
		mat.stencil_flags = BaseMaterial3D.STENCIL_FLAG_WRITE
		mat.stencil_compare = BaseMaterial3D.STENCIL_COMPARE_ALWAYS
		mat.stencil_reference = SPRITE_STENCIL_REF
		var xray := StandardMaterial3D.new()
		xray.albedo_texture = unit_sprite.texture
		xray.albedo_color = FactionArtManager.team_xray_color(team)
		xray.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		xray.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		xray.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		xray.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		xray.depth_test = BaseMaterial3D.DEPTH_TEST_INVERTED
		xray.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
		xray.stencil_flags = BaseMaterial3D.STENCIL_FLAG_READ
		xray.stencil_compare = BaseMaterial3D.STENCIL_COMPARE_NOT_EQUAL
		xray.stencil_reference = SPRITE_STENCIL_REF
		xray.render_priority = 1
		mat.next_pass = xray
		_sprite_mat_cache[key] = mat
	unit_sprite.material_override = _sprite_mat_cache[key]

func _set_sheet_anim(n: String, restart: bool = false) -> void:
	if not sheet.get("anims", {}).has(n):
		return
	if n == _anim_name and not restart:
		return
	_anim_name = n
	_sheet_time = 0.0

## Advances the sheet animation (same choice of animation as the 3D model) and mirrors it to the walking side.
func _update_sheet_animation(delta: float) -> void:
	var pick := _pick_anim()
	if pick[0] != "":
		_set_sheet_anim(pick[0], pick[1])
	var a: Dictionary = sheet["anims"][_anim_name]
	var speed := clampf(move_speed / 3.2, 0.7, 1.8) if _anim_name == "walk" else 1.0
	_sheet_time += delta * speed
	var n: int = int(a["frames"])
	var i := int(_sheet_time * float(a["fps"]))
	if a.get("loop", false):
		i = i % n
	else:
		i = mini(i, n - 1)
	unit_sprite.frame = int(a["row"]) * int(sheet["hframes"]) + i
	if velocity.x > 0.15:
		unit_sprite.flip_h = true          # the sheet faces front-left; mirror when walking to the right
	elif velocity.x < -0.15:
		unit_sprite.flip_h = false
	if is_instance_valid(occlusion_silhouette):
		occlusion_silhouette.frame = unit_sprite.frame
		occlusion_silhouette.flip_h = unit_sprite.flip_h

func _build_selection_and_bars() -> void:
	# mounted 3D models (cataphract, knight, camel ...) stand ~1 m taller: lift the bars, widen the ring
	var mounted: bool = unit_model != null and FactionArtManager.get_unit_model_entry(civ_type, unit_type).get("mount", "") != ""
	# 2. Diorama Ground Selection Ring
	selection_ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = SELECTION_RING_INNER * (1.35 if mounted else 1.0)
	ring_mesh.outer_radius = SELECTION_RING_OUTER * (1.35 if mounted else 1.0)
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
	_build_3d_hp_bar(0.9 if mounted else 0.0)

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

	# rebuilt with the model: a unit is added to the tree (as a default team-0 villager) before setup_unit()
	if badge != null:
		badge.queue_free()
		badge = null
	if team == 0 and unit_type == UnitType.VILLAGER:
		badge = VillagerBadge.new()
		badge.position = Vector3(0, mount_y + BADGE_Y, 0)
		add_child(badge)
		_update_badge()

func _physics_process(delta: float) -> void:
	if regen_rate > 0.0 and hp < max_hp and hp > 0.0:
		hp = min(max_hp, hp + regen_rate * delta)
		_update_hp_bar()

	if attack_timer > 0.0:
		attack_timer -= delta

	if swing_progress > 0.0:
		swing_progress = max(0.0, swing_progress - delta * 3.5)

	# Procedural HD-2D Sprite Animation / rigged model animation
	if unit_model != null:
		_update_model_animation()
	elif not sheet.is_empty() and is_instance_valid(unit_sprite):
		_update_sheet_animation(delta)
	else:
		_update_hd2d_sprite_animation(delta)

	_update_order(delta)
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

	_snap_to_ground()
	if sheet.get("view", "") == "oblique":
		_place_oblique_visuals()

	if is_selected:
		_update_status_label()
	_update_badge()

## What the badge over a player villager shows: activity colour, icon and load.
func _update_badge() -> void:
	if badge == null:
		return
	badge.visible = not is_selected and hp > 0
	if not badge.visible:
		return
	var res_glyph: String = resource_type if resource_type in ["wood", "gold", "stone", "food"] else "move"
	var load_text: String = "%d/%d" % [carried_resource, max_carry]
	match state:
		State.IDLE:
			badge.show_state("idle", "idle", load_text if carried_resource > 0 else "")
		State.GATHERING:
			badge.show_state("gather", res_glyph, load_text)
		State.RETURNING_RESOURCES:
			badge.show_state("return", res_glyph, load_text)
		State.BUILDING:
			var pct := ""
			if is_instance_valid(target_entity) and target_entity is Building3D:
				pct = "%%%d" % int(target_entity.construction_progress)
			badge.show_state("build", "build", pct)
		State.ATTACKING:
			badge.show_state("attack", "attack", "")
		_:
			badge.show_state("move", "move", load_text if carried_resource > 0 else "")

## Ground distance (ignores height: on hills a target can be a little above or below the unit).
static func _hdist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

## Ground distance from `p` to the edge of the cell block `origin` .. `origin + size` (0 inside it).
static func _dist_to_cells(p: Vector3, origin: Vector2i, size: Vector2i) -> float:
	var t := MapGenerator3D.TILE_SIZE
	var dx := maxf(maxf(origin.x * t - p.x, p.x - (origin.x + size.x) * t), 0.0)
	var dz := maxf(maxf(origin.y * t - p.z, p.z - (origin.y + size.y) * t), 0.0)
	return Vector2(dx, dz).length()

func _reset_approach() -> void:
	approach_time = 0.0
	_dropoff_repathed = false

## Walks straight towards `pt` (the last metre to a resource or a drop-off). False once it gave up.
func _approach(pt: Vector3, delta: float) -> bool:
	approach_time += delta
	if approach_time > APPROACH_TIMEOUT:
		return false
	var dir := pt - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return false
	dir = dir.normalized()
	walk_timer += delta
	if is_instance_valid(model_root):
		model_root.position.y = sin(walk_timer * 16.0) * 0.08
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 12.0)
	velocity = dir * move_speed
	move_and_slide()
	return true

## Feet on the terrain surface (hills are smooth slopes, so the height changes continuously).
func _snap_to_ground() -> void:
	if map_gen != null and is_instance_valid(map_gen):
		global_position.y = map_gen.get_height_at(global_position)

func _handle_idle_scanning() -> void:
	if unit_type == UnitType.VILLAGER or order != Order.NONE:
		return                             # ordered soldiers scan in _update_order()
	var scan_range = 6.5 if not is_ranged() else attack_range + 2.0
	var enemy = _find_closest_enemy(scan_range)
	if enemy:
		command_attack(enemy)

const WAYPOINT_SLACK := 0.7
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
	if dist > move_dist and dist < WAYPOINT_SLACK and path_idx < current_path.size() - 1:
		path_idx += 1                              # close enough to a corner: spacing may keep it from the exact point
		return
	if dist <= move_dist:
		global_position = target_pt
		path_idx += 1
		if path_idx >= current_path.size():
			if state == State.MOVING:
				crowd_goal = target_pt
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

	var dist = _distance_to_attack_target(target_entity)
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

## Distance used for attack-range checks. Buildings block their whole grid footprint,
## so measuring to their center made melee units (range ~2 m) unable to ever reach a
## 2x2+ building (edge >= 1.8 m from center plus unit radius). Measure to the footprint edge.
func _distance_to_attack_target(entity: Node3D) -> float:
	if entity is Building3D:
		var b := entity as Building3D
		var half := Vector2(b.grid_size.x, b.grid_size.y) * MapGenerator3D.TILE_SIZE * 0.5
		var d := Vector2(global_position.x - b.global_position.x, global_position.z - b.global_position.z)
		var outside := Vector2(maxf(absf(d.x) - half.x, 0.0), maxf(absf(d.y) - half.y, 0.0))
		return outside.length()
	return _hdist(global_position, entity.global_position)

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
	var on_field: bool = resource_type == "food" and map_gen.farm_fields.has(target_cell)
	if on_field and not map_gen.claim_field(target_cell, self):
		# someone else farms this field (1 farmer per field) -> another free field / berries
		_find_next_resource("food")
		return
	if not (target_cell in dict) and not on_field:
		if carried_resource > 0:
			command_return_resources()
		else:
			_find_next_resource(resource_type)
		return

	var my_cell = map_gen.world_to_cell(global_position)
	var cell_dist = max(abs(my_cell.x - target_cell.x), abs(my_cell.y - target_cell.y))
	var res_pos = map_gen.cell_to_world(target_cell)
	if on_field:
		# fields are walkable 2x2 plots: work standing inside them, around the plot centre
		res_pos = _field_work_pos(target_cell)
	var world_dist = _hdist(global_position, res_pos)
	var far: bool = (map_gen.field_origin_at(my_cell) != target_cell and world_dist > 1.6) if on_field else (cell_dist > 1 and world_dist > 2.8)

	# If further than adjacent tile and further than 2.8 meters -> pathfind to adjacent cell
	if far:
		if current_path.is_empty() or path_idx >= current_path.size():
			_calculate_path(res_pos)
			if current_path.is_empty():
				# No route at all: the unit and the node are in disconnected regions (it may be the
				# UNIT that is trapped), so do not poison the shared unreachable marks - just drop it.
				state = State.IDLE
				target_cell = Vector2i(-1, -1)
				velocity = Vector3.ZERO
				return
			if path_idx >= current_path.size():
				# A* found a route but it is already exhausted and we are still out of range: the
				# node is boxed in (A* fell back to the nearest free cell 2+ cells away). Previously the
				# villager recalculated the same finished path forever -> bot food starvation deadlock.
				map_gen.mark_resource_unreachable(target_cell)
				_find_next_resource(resource_type)
				return
		_process_path_movement(delta)
		return

	# In the next cell: walk the last bit up to the node (fields are worked from inside)
	if not on_field and _dist_to_cells(global_position, target_cell, Vector2i.ONE) > GATHER_REACH:
		current_path.clear()
		if _approach(res_pos, delta):
			return
	approach_time = 0.0

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
		var civ_cfg = CivData.get_civ(civ_type)
		var kind: String = "field" if on_field else resource_type
		var team_mult: float = main_game.get_gather_mult(team, kind) if main_game != null and main_game.has_method("get_gather_mult") else 1.0
		var mult: float = maxf(0.1, float(civ_cfg.get(resource_type + "_gather_mult", 1.0)) * team_mult)
		attack_timer = float(GATHER_INTERVAL.get(kind, 0.8)) / mult
		swing_progress = 1.0
		SoundManager.play_sound("gather")
		var harvest_amt := 1
		var got = 0
		if resource_type == "wood":
			got = map_gen.harvest_tree(target_cell, harvest_amt)
		elif resource_type == "gold":
			got = map_gen.harvest_gold(target_cell, harvest_amt)
		elif resource_type == "stone":
			got = map_gen.harvest_stone(target_cell, harvest_amt)
		elif resource_type == "food":
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
	# the dropoff can be destroyed and freed while we walk to it: casting a freed object is an error
	# (it was raised every frame for every villager on its way), so check before casting
	var dropoff: Building3D = (target_entity as Building3D) if is_instance_valid(target_entity) else null
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
	var edge_dist := _dist_to_cells(global_position, o_cell, g_size)
	var arrived := edge_dist <= DROPOFF_REACH
	if not arrived and not is_adjacent:
		if current_path.is_empty() or path_idx >= current_path.size():
			if not _dropoff_repathed:
				_dropoff_repathed = true
				_calculate_path(dropoff.global_position)
			if current_path.is_empty() or path_idx >= current_path.size():
				# the path ended short of the building (cells around it blocked): walk straight in,
				# and unload from here if even that does not get closer
				if _approach(dropoff.global_position, delta):
					return
				arrived = true
		if not arrived:
			_process_path_movement(delta)
			return
	if not arrived and is_adjacent:
		# in the ring of cells around the building: walk the last bit up to its wall
		current_path.clear()
		if _approach(dropoff.global_position, delta):
			return
		arrived = true
	if arrived:
		approach_time = 0.0
		_dropoff_repathed = false
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
		if target_cell in dict or (resource_type == "food" and map_gen.farm_fields.has(target_cell)):
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
	var dist = _hdist(global_position, target_entity.global_position)

	var in_reach: bool = is_adjacent or dist <= (b_radius + 2.8)
	if not in_reach:
		if current_path.is_empty() or path_idx >= current_path.size():
			_calculate_path(target_entity.global_position)
			if current_path.is_empty() or path_idx >= current_path.size():
				# The path cannot get any closer. One cell short of the walls (the cells right next to
				# the site are taken, e.g. by the Town Center or other builders): build from here.
				# Further away the site is unreachable from here: give up so the owner can re-task.
				if _dist_to_cells(global_position, o_cell, g_size) <= MapGenerator3D.TILE_SIZE * 1.3:
					in_reach = true
				else:
					state = State.IDLE
					target_entity = null
					velocity = Vector3.ZERO
					return
		if not in_reach:
			_process_path_movement(delta)
	if in_reach:
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
			target_entity.contribute_construction(target_entity.build_swing_progress(8.0) if target_entity.has_method("build_swing_progress") else 8.0)
			if target_entity.is_completed:
				var done = target_entity
				state = State.IDLE
				target_entity = null
				# the builder of a field starts farming it right away (unless someone already is)
				if done is Building3D and done.building_type == Building3D.BuildingType.FARM and map_gen != null \
						and map_gen.is_field_free_for(done.origin_cell, self):
					command_gather(done.origin_cell, "food")

func _find_next_resource(type: String = "") -> void:
	if type == "":
		type = resource_type
	if map_gen == null:
		state = State.IDLE
		return

	var search_origin = last_resource_pos if last_resource_pos != Vector3.ZERO else global_position
	var nearest_cell := Vector2i(-1, -1)
	var was_farming: bool = type == "food" and map_gen.farm_fields.has(target_cell)
	if was_farming:
		# a farmer keeps farming: next free field of our team first
		nearest_cell = map_gen.find_free_field(search_origin, team, self, AUTO_GATHER_SEARCH_RADIUS)
	if nearest_cell == Vector2i(-1, -1):
		nearest_cell = map_gen.find_nearest_resource_node(search_origin, type, AUTO_GATHER_SEARCH_RADIUS)
	if nearest_cell == Vector2i(-1, -1) and type == "food" and not was_farming:
		# berries ran out nearby -> a free field of our team
		nearest_cell = map_gen.find_free_field(search_origin, team, self, AUTO_GATHER_SEARCH_RADIUS)

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
	crowd_goal = Vector3.INF
	if map_gen != null:
		current_path = map_gen.get_path_to_target(global_position, target_pos)
		path_idx = 0
		if current_path.size() > 0 and _hdist(global_position, current_path[0]) < 0.6:
			path_idx = 1

func _find_closest_enemy(max_dist: float) -> Node3D:
	if main_game == null:
		return null
	return main_game.get_closest_enemy_entity(global_position, team, max_dist)

## Body radius used to keep units from standing inside each other (GameController3D._separate_units):
## two units may overlap by up to half of it, never more.
func get_body_radius() -> float:
	return 1.1 if is_cavalry() else 0.6

## ---- army orders ------------------------------------------------------------------------------
func command_attack_move(dest: Vector3) -> void:
	command_move(dest)
	order = Order.ATTACK_MOVE
	order_pos = dest
	_order_scan_t = 0.0

func command_defend(pos: Vector3) -> void:
	command_move(pos)
	order = Order.DEFEND
	order_pos = pos
	_order_scan_t = 0.0

## Attack this target, then keep fighting around where it stood (like an attack-move ending there).
func command_attack_order(entity: Node3D) -> void:
	if not is_instance_valid(entity):
		return
	command_attack(entity)
	order = Order.ATTACK_MOVE
	order_pos = entity.global_position
	_order_scan_t = 0.0

func _update_order(delta: float) -> void:
	if order == Order.NONE or unit_type == UnitType.VILLAGER or hp <= 0.0:
		return
	_order_scan_t -= delta
	match state:
		State.MOVING:
			if _order_scan_t <= 0.0:
				_order_scan_t = 0.25
				var e := _order_enemy()
				if e != null:
					command_attack(e)                  # keeps the order: resumed when the fight ends
		State.ATTACKING:
			if order == Order.DEFEND and is_instance_valid(target_entity) \
					and _hdist(target_entity.global_position, order_pos) > DEFEND_LEASH:
				_resume_order()                        # do not chase away from the post
		State.IDLE:
			if _order_scan_t <= 0.0:
				_order_scan_t = 0.25
				var e := _order_enemy()
				if e != null:
					command_attack(e)
				elif _hdist(global_position, order_pos) > ORDER_ARRIVE + 0.5:
					_resume_order()
				elif order == Order.ATTACK_MOVE:
					order = Order.NONE                 # arrived and nothing left to fight

## The enemy this ordered soldier should fight now, or null.
func _order_enemy() -> Node3D:
	var r: float = (attack_range + 2.0) if is_ranged() else 6.5
	if order == Order.DEFEND:
		r = maxf(r, 8.0)
	var e := _find_closest_enemy(r)
	if e != null and order == Order.DEFEND and _hdist(e.global_position, order_pos) > DEFEND_RADIUS:
		return null
	return e

func _resume_order() -> void:
	_reset_approach()
	target_entity = null
	state = State.MOVING
	_calculate_path(order_pos)
	if current_path.is_empty() and _hdist(global_position, order_pos) > ORDER_ARRIVE + 0.5:
		order = Order.NONE                         # the spot cannot be reached (water, walls): drop the order
		state = State.IDLE

## Separation hook: walking to a spot, blocked near it by a unit that already stands there -> count as arrived.
## Plain moves only: army orders (SALDIR / SAVUN, AI attack waves) keep their own logic and formation spots.
## Only a blocker that already arrived at (about) the same goal counts, so a unit never stops short beside a
## stranger that just happens to stand near its destination.
const CROWD_ARRIVE := 3.5
const CROWD_CORE := 1.2
const CROWD_MAX := 8.0
var crowd_goal := Vector3.INF                   # the goal this unit arrived at (INF while walking / other work)
func stop_if_crowded_near_goal(blocker: Unit3D) -> void:
	if state != State.MOVING or current_path.is_empty() or blocker.team != team or order != Order.NONE:
		return
	var goal: Vector3 = current_path[current_path.size() - 1]
	var my_d := _hdist(global_position, goal)
	if blocker.crowd_goal != Vector3.INF:
		if _hdist(blocker.crowd_goal, goal) > 1.0:
			return                                 # blocker stands at a different spot
		# the crowd grows outward: just outside an arrived unit counts as arrived too (up to CROWD_MAX)
		var reach := maxf(CROWD_ARRIVE, _hdist(blocker.global_position, goal) + 1.5)
		if my_d > minf(reach, CROWD_MAX):
			return
	elif blocker.state == State.MOVING and not blocker.current_path.is_empty():
		# both still walking to the same spot and already jostling at its centre: the inner one has arrived
		if my_d > CROWD_CORE or _hdist(blocker.current_path[blocker.current_path.size() - 1], goal) > 1.0:
			return
	else:
		return
	current_path.clear()
	crowd_goal = goal
	state = State.IDLE
	velocity = Vector3.ZERO
	walk_timer = 0.0
	if is_instance_valid(model_root):
		model_root.position.y = 0.0

# Commands
func command_move(dest: Vector3) -> void:
	order = Order.NONE
	_reset_approach()
	state = State.MOVING
	target_entity = null
	target_cell = Vector2i(-1, -1)
	_calculate_path(dest)

func command_attack(entity: Node3D) -> void:
	_reset_approach()
	if not is_instance_valid(entity):
		return
	state = State.ATTACKING
	target_entity = entity
	_calculate_path(entity.global_position)

func command_gather(cell: Vector2i, type: String) -> void:
	order = Order.NONE
	_reset_approach()
	state = State.GATHERING
	target_cell = cell
	resource_type = type
	target_entity = null
	if map_gen != null:
		last_resource_pos = _field_work_pos(cell) if (type == "food" and map_gen.farm_fields.has(cell)) else map_gen.cell_to_world(cell)
		_calculate_path(last_resource_pos)

## Where a farmer stands on a 2x2 field (origin = top-left cell): the plot centre.
func _field_work_pos(origin: Vector2i) -> Vector3:
	return Vector3((origin.x + 1.0) * MapGenerator3D.TILE_SIZE, global_position.y, (origin.y + 1.0) * MapGenerator3D.TILE_SIZE)

func command_build(building: Node3D) -> void:
	order = Order.NONE
	_reset_approach()
	state = State.BUILDING
	target_entity = building
	_calculate_path(building.global_position)

func command_return_resources(dropoff: Node3D = null) -> void:
	order = Order.NONE
	_reset_approach()
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
	order = Order.NONE
	_reset_approach()
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
	_leave_corpse()
	queue_free()

## The unit leaves the game at once; its model stays behind in the world for the death animation, then
## sinks into the ground and is freed.
func _leave_corpse() -> void:
	if not is_inside_tree() or get_parent() == null:
		return
	if (unit_model == null or not is_instance_valid(unit_model)) and not sheet.is_empty() and is_instance_valid(unit_sprite):
		_leave_sprite_corpse()
		return
	if unit_model == null or not is_instance_valid(unit_model):
		return
	var corpse := unit_model
	var xf := corpse.global_transform
	remove_child(corpse)
	get_parent().add_child(corpse)
	corpse.global_transform = xf
	unit_model = null
	if unit_anim != null and unit_anim.has_animation("death"):
		unit_anim.speed_scale = 1.0
		unit_anim.play("death")
	unit_anim = null
	var tw := corpse.create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(corpse, "position:y", corpse.position.y - 0.7, 1.2)
	tw.tween_callback(corpse.queue_free)

## 2D: the sprite stays behind and plays the sheet's death row, then fades out.
func _leave_sprite_corpse() -> void:
	var corpse := unit_sprite
	var xf := corpse.global_transform
	corpse.get_parent().remove_child(corpse)
	get_parent().add_child(corpse)
	corpse.global_transform = xf
	unit_sprite = null
	if is_instance_valid(occlusion_silhouette):
		occlusion_silhouette.queue_free()
	var a: Dictionary = sheet["anims"]["death"]
	var first: int = int(a["row"]) * int(sheet["hframes"])
	corpse.frame = first
	var tw := corpse.create_tween()
	tw.tween_property(corpse, "frame", first + int(a["frames"]) - 1, float(a["frames"]) / float(a["fps"]))
	tw.tween_interval(2.5)
	tw.tween_property(corpse, "modulate:a", 0.0, 1.0)
	tw.tween_callback(corpse.queue_free)

func set_selected(sel: bool) -> void:
	is_selected = sel
	if is_instance_valid(selection_ring):
		selection_ring.visible = sel
	if is_instance_valid(status_label):
		status_label.visible = sel
	_update_badge()
	_update_hp_bar()
	_update_status_label()
	selected_changed.emit(self, sel)

func _play_anim(n: String, restart: bool = false) -> void:
	if unit_anim == null or not unit_anim.has_animation(n):
		return
	if n == _anim_name and not restart and unit_anim.is_playing():
		return
	_anim_name = n
	unit_anim.play(n, 0.12)
	if restart:
		unit_anim.seek(0.0, true)

## What the unit is doing -> [animation, restart]. ["", false] = keep the current one (an attack swing
## plays to its end unless the unit starts moving). Shared by the 3D model and the 2D sprite sheet.
func _pick_anim() -> Array:
	var new_swing := swing_progress > _last_swing + 0.5
	_last_swing = swing_progress
	var moving := velocity.length_squared() > 0.01 or (current_path.size() > 0 and path_idx < current_path.size())
	if new_swing and state == State.ATTACKING:
		return ["attack", true]
	if _anim_name == "attack" and not moving and _attack_running():
		return ["", false]
	if moving:
		return ["walk", false]
	if state == State.GATHERING:
		return ["gather", false]
	if state == State.BUILDING:
		return ["build", false]
	return ["idle", false]

func _attack_running() -> bool:
	if unit_anim != null:
		return unit_anim.is_playing() and unit_anim.current_animation == "attack"
	if not sheet.is_empty():
		var a: Dictionary = sheet["anims"]["attack"]
		return _sheet_time * float(a["fps"]) < float(a["frames"])
	return false

## Plays the model's animation for what the unit is doing; walking speeds up with move speed.
func _update_model_animation() -> void:
	if unit_anim == null:
		return
	var pick := _pick_anim()
	if pick[0] != "":
		_play_anim(pick[0], pick[1])
	unit_anim.speed_scale = clampf(move_speed / 3.2, 0.7, 1.8) if _anim_name == "walk" else 1.0
	for k in _cargo_props:
		_cargo_props[k].visible = carried_resource > 0 and resource_type == k

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
		if is_instance_valid(occlusion_silhouette):
			occlusion_silhouette.flip_h = unit_sprite.flip_h
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
