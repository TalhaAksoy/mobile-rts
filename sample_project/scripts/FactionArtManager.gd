class_name FactionArtManager
extends RefCounted

const MANIFEST_PATH: String = "res://data/faction_art_manifest.json"

static var _manifest_data: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _is_initialized: bool = false

static func _ensure_initialized() -> void:
	if _is_initialized:
		return
	_is_initialized = true

	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("FactionArtManager: Manifest not found at " + MANIFEST_PATH)
		return

	var file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			_manifest_data = parsed

static func get_faction_id_from_civ(c_type: CivData.CivType) -> String:
	match c_type:
		CivData.CivType.OTTOMANS: return "ottomans"
		CivData.CivType.BYZANTINES: return "byzantines"
		CivData.CivType.BRITONS: return "britons"
		CivData.CivType.FRANKS: return "franks"
		CivData.CivType.MONGOLS: return "mongols"
		CivData.CivType.TEUTONS: return "teutons"
		CivData.CivType.JAPANESE: return "japanese"
		CivData.CivType.SARACENS: return "saracens"
		CivData.CivType.VIKINGS: return "vikings"
		CivData.CivType.CHINESE: return "chinese"
	return "ottomans"

static func get_civ_from_faction_id(f_id: String) -> CivData.CivType:
	match f_id:
		"ottomans": return CivData.CivType.OTTOMANS
		"byzantines": return CivData.CivType.BYZANTINES
		"britons": return CivData.CivType.BRITONS
		"franks": return CivData.CivType.FRANKS
		"mongols": return CivData.CivType.MONGOLS
		"teutons": return CivData.CivType.TEUTONS
		"japanese": return CivData.CivType.JAPANESE
		"saracens": return CivData.CivType.SARACENS
		"vikings": return CivData.CivType.VIKINGS
		"chinese": return CivData.CivType.CHINESE
	return CivData.CivType.OTTOMANS

static func get_unit_role_id(u_type: Unit3D.UnitType, faction_id: String) -> String:
	match u_type:
		Unit3D.UnitType.VILLAGER: return "villager"
		Unit3D.UnitType.SWORDSMAN: return "swordsman"
		Unit3D.UnitType.SPEARMAN: return "spearman"
		Unit3D.UnitType.ARCHER: return "archer"
		Unit3D.UnitType.JANISSARY: return "janissary"
		Unit3D.UnitType.CATAPHRACT: return "cataphract"
		Unit3D.UnitType.LONGBOWMAN: return "longbowman"
		Unit3D.UnitType.PALADIN: return "knight"
		Unit3D.UnitType.MANGUDAI: return "horse_archer"
		Unit3D.UnitType.TEUTONIC_KNIGHT: return "teutonic_knight"
		Unit3D.UnitType.SAMURAI: return "samurai"
		Unit3D.UnitType.MAMELUKE: return "mamluk"
		Unit3D.UnitType.BERSERKER: return "berserker"
		Unit3D.UnitType.CHUKONU: return "chu_ko_nu"
		Unit3D.UnitType.CAVALRY:
			match faction_id:
				"byzantines": return "cataphract"
				"franks": return "knight"
				"mongols": return "horse_archer"
				"saracens": return "mamluk"
				_: return "swordsman"
	return "villager"

static func get_unit_texture(civ_type: CivData.CivType, unit_type: Unit3D.UnitType, pose: String = "pose_01") -> Texture2D:
	_ensure_initialized()
	var faction_id = get_faction_id_from_civ(civ_type)
	var role_id = get_unit_role_id(unit_type, faction_id)
	var cache_key = "unit_tex_%s_%s_%s" % [faction_id, role_id, pose]

	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var res_path = "res://art/units/%s/%s/%s.png" % [faction_id, role_id, pose]
	if ResourceLoader.exists(res_path):
		var tex = load(res_path) as Texture2D
		if tex != null:
			_texture_cache[cache_key] = tex
			return tex

	# Fallback to pose_01 if requested pose doesn't exist
	if pose != "pose_01":
		var fallback_path = "res://art/units/%s/%s/pose_01.png" % [faction_id, role_id]
		if ResourceLoader.exists(fallback_path):
			var tex = load(fallback_path) as Texture2D
			if tex != null:
				_texture_cache[cache_key] = tex
				return tex

	# Safe procedural fallback from PixelArtTextures
	var procedural_fallback = PixelArtTextures.get_unit_pixel_sprite(unit_type, 0, "idle", 0.0)
	_texture_cache[cache_key] = procedural_fallback
	return procedural_fallback

static func get_concept_sheet_texture(civ_type: CivData.CivType) -> Texture2D:
	var faction_id = get_faction_id_from_civ(civ_type)
	var cache_key = "concept_%s" % faction_id
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var res_path = "res://art/concept_sheets/%s.png" % faction_id
	if ResourceLoader.exists(res_path):
		var tex = load(res_path) as Texture2D
		if tex != null:
			_texture_cache[cache_key] = tex
			return tex
	return null

static func get_flag_reference_texture(civ_type: CivData.CivType) -> Texture2D:
	var faction_id = get_faction_id_from_civ(civ_type)
	var cache_key = "flag_ref_%s" % faction_id
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var res_path = "res://art/flags/%s_reference.png" % faction_id
	if ResourceLoader.exists(res_path):
		var tex = load(res_path) as Texture2D
		if tex != null:
			_texture_cache[cache_key] = tex
			return tex
	return null

static func get_manifest_unit_data(faction_id: String, role_id: String) -> Dictionary:
	_ensure_initialized()
	for f in _manifest_data.get("factions", []):
		if f.get("id") == faction_id:
			var units_dict = f.get("units", {})
			if units_dict.has(role_id):
				return units_dict[role_id]
	return {}

static func get_building_id_from_type(b_type: Building3D.BuildingType) -> String:
	match b_type:
		Building3D.BuildingType.TOWN_CENTER: return "town_center"
		Building3D.BuildingType.HOUSE: return "house"
		Building3D.BuildingType.BARRACKS: return "barracks"
		Building3D.BuildingType.ARCHERY_RANGE: return "archery_range"
		Building3D.BuildingType.STABLE: return "stable"
		Building3D.BuildingType.CASTLE: return "castle"
		Building3D.BuildingType.TOWER: return "watch_tower"
		Building3D.BuildingType.FARM: return "farm"
		Building3D.BuildingType.BLACKSMITH: return "blacksmith"
		Building3D.BuildingType.LUMBER_CAMP: return "lumber_camp"
		Building3D.BuildingType.MINING_CAMP: return "mining_camp"
		Building3D.BuildingType.MILL: return "mill"
	return "town_center"

static func get_building_texture(civ_type: CivData.CivType, b_type: Building3D.BuildingType) -> Texture2D:
	_ensure_initialized()
	var faction_id = get_faction_id_from_civ(civ_type)
	var b_id = get_building_id_from_type(b_type)
	var cache_key = "building_tex_%s_%s" % [faction_id, b_id]

	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var res_path = "res://art/buildings/%s/%s.png" % [faction_id, b_id]
	if ResourceLoader.exists(res_path):
		var tex = load(res_path) as Texture2D
		if tex != null:
			_texture_cache[cache_key] = tex
			return tex
	return null

static func get_building_texture_by_id(faction_id: String, building_id: String) -> Texture2D:
	var cache_key = "building_tex_%s_%s" % [faction_id, building_id]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var res_path = "res://art/buildings/%s/%s.png" % [faction_id, building_id]
	if ResourceLoader.exists(res_path):
		var tex = load(res_path) as Texture2D
		if tex != null:
			_texture_cache[cache_key] = tex
			return tex
	return null

# =====================================================================================
# 3D building models (Blender -> GLB pipeline, see docs/art/BLENDER_PIPELINE.md)
# =====================================================================================
const MODEL_MANIFEST_PATH: String = "res://data/art/building_model_manifest.json"
const MATERIAL_LIB_DIR: String = "res://assets/3d/materials/"
const TEAM_COLORS: Array[Color] = [Color(0.18, 0.52, 0.95), Color(0.92, 0.22, 0.22)]

## Global switch: false -> every building uses the HD-2D sprite path (reversible fallback).
static var use_3d_building_models: bool = true

static var _model_manifest: Dictionary = {}
static var _model_manifest_loaded: bool = false
static var _model_cache: Dictionary = {}
static var _lib_material_cache: Dictionary = {}
static var _team_material_cache: Dictionary = {}
static var _logged_problems: Dictionary = {}

static func _load_model_manifest() -> void:
	if _model_manifest_loaded:
		return
	_model_manifest_loaded = true
	if not FileAccess.file_exists(MODEL_MANIFEST_PATH):
		push_warning("FactionArtManager: 3D model manifest missing at " + MODEL_MANIFEST_PATH)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MODEL_MANIFEST_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_model_manifest = parsed
	else:
		push_error("FactionArtManager: could not parse " + MODEL_MANIFEST_PATH)

static func _log_once(key: String, msg: String) -> void:
	if not _logged_problems.has(key):
		_logged_problems[key] = true
		push_warning(msg)

static func get_building_model_entry(civ_type: CivData.CivType, b_type: Building3D.BuildingType) -> Dictionary:
	_load_model_manifest()
	var civ_id = get_faction_id_from_civ(civ_type)
	var b_id = get_building_id_from_type(b_type)
	return _model_manifest.get("buildings", {}).get(civ_id, {}).get(b_id, {})

static func get_building_model(civ_type: CivData.CivType, b_type: Building3D.BuildingType) -> PackedScene:
	if not use_3d_building_models:
		return null
	var entry = get_building_model_entry(civ_type, b_type)
	if entry.is_empty() or not entry.get("enabled", false):
		return null
	var path: String = entry.get("model", "")
	if _model_cache.has(path):
		return _model_cache[path]
	if not ResourceLoader.exists(path):
		_log_once(path, "FactionArtManager: model listed in manifest but missing: %s (using sprite fallback)" % path)
		_model_cache[path] = null
		return null
	var ps = load(path) as PackedScene
	if ps == null:
		_log_once(path, "FactionArtManager: failed to load model %s (using sprite fallback)" % path)
	_model_cache[path] = ps
	return ps

static func get_library_material(mat_name: String) -> Material:
	if _lib_material_cache.has(mat_name):
		return _lib_material_cache[mat_name]
	var path = MATERIAL_LIB_DIR + mat_name + ".tres"
	var mat: Material = null
	if ResourceLoader.exists(path):
		mat = load(path)
	else:
		_log_once("mat_" + mat_name, "FactionArtManager: material '%s' not in shared library %s" % [mat_name, MATERIAL_LIB_DIR])
	_lib_material_cache[mat_name] = mat
	return mat

static func get_team_trim_material(team: int) -> Material:
	if _team_material_cache.has(team):
		return _team_material_cache[team]
	var base = get_library_material("TEAM_Trim")
	var m: StandardMaterial3D = (base.duplicate() if base != null else StandardMaterial3D.new()) as StandardMaterial3D
	m.resource_name = "TEAM_Trim_team%d" % team
	m.albedo_color = TEAM_COLORS[clampi(team, 0, TEAM_COLORS.size() - 1)]
	_team_material_cache[team] = m
	return m

## Instantiates the building's GLB and remaps every surface to the shared material library
## (GLBs carry material NAMES only). TEAM_* surfaces get the owning team's colour.
static func instantiate_building_model(civ_type: CivData.CivType, b_type: Building3D.BuildingType, team: int) -> Node3D:
	var ps = get_building_model(civ_type, b_type)
	if ps == null:
		return null
	var inst = ps.instantiate() as Node3D
	if inst == null:
		return null
	_apply_library_materials(inst, team)
	return inst

static func _apply_library_materials(node: Node, team: int) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for i in mi.mesh.get_surface_count():
			var src = mi.mesh.surface_get_material(i)
			var mat_name: String = src.resource_name if src != null else ""
			if mat_name.begins_with("TEAM_"):
				mi.set_surface_override_material(i, get_team_trim_material(team))
			elif mat_name != "":
				var lib = get_library_material(mat_name)
				if lib != null:
					mi.set_surface_override_material(i, lib)
	for c in node.get_children():
		_apply_library_materials(c, team)

## Union of all mesh AABBs under `node`, in `node`'s local space (works outside the tree).
static func compute_visual_aabb(node: Node3D) -> AABB:
	var acc := {"aabb": AABB(), "first": true}
	_accumulate_aabb(node, Transform3D.IDENTITY, acc)
	return acc["aabb"]

static func _accumulate_aabb(n: Node, xf: Transform3D, acc: Dictionary) -> void:
	for c in n.get_children():
		var cxf := xf
		if c is Node3D:
			cxf = xf * (c as Node3D).transform
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var box: AABB = cxf * (c as MeshInstance3D).get_aabb()
			acc["aabb"] = box if acc["first"] else (acc["aabb"] as AABB).merge(box)
			acc["first"] = false
		_accumulate_aabb(c, cxf, acc)


# ---- Environment props (trees, mines) from the same manifest -------------------------------
static func get_environment_model(asset_id: String) -> PackedScene:
	if not use_3d_building_models:
		return null
	_load_model_manifest()
	var entry: Dictionary = _model_manifest.get("environment", {}).get(asset_id, {})
	if entry.is_empty() or not entry.get("enabled", false):
		return null
	var path: String = entry.get("model", "")
	if _model_cache.has(path):
		return _model_cache[path]
	var ps: PackedScene = null
	if ResourceLoader.exists(path):
		ps = load(path) as PackedScene
	if ps == null:
		_log_once(path, "FactionArtManager: environment model missing/invalid: %s (sprite fallback)" % path)
	_model_cache[path] = ps
	return ps

## Environment instance with library materials; returns null -> caller keeps its sprite.
static func instantiate_environment_model(asset_id: String, team: int = 0) -> Node3D:
	var ps = get_environment_model(asset_id)
	if ps == null:
		return null
	var inst = ps.instantiate() as Node3D
	if inst != null:
		_apply_library_materials(inst, team)
	return inst

## Civilisation-themed "upgraded building" dressing (manifest section "upgrade_kits"), or null.
static func instantiate_upgrade_kit(civ: int, team: int) -> Node3D:
	if not use_3d_building_models:
		return null
	_load_model_manifest()
	var civ_id: String = CivData.get_civ(civ).get("id", "")
	var entry: Dictionary = _model_manifest.get("upgrade_kits", {}).get(civ_id, {})
	if entry.is_empty() or not entry.get("enabled", false):
		return null
	var path: String = entry.get("model", "")
	if not _model_cache.has(path):
		_model_cache[path] = load(path) if ResourceLoader.exists(path) else null
	var ps = _model_cache[path]
	if ps == null:
		return null
	var inst = ps.instantiate() as Node3D
	_apply_library_materials(inst, team)
	return inst

## Farm field model for the map's biome ("field", "desert/field", ...), team-coloured pennant.
## Falls back to the temperate field, then null (Building3D then uses its procedural plot).
static func instantiate_field_model(map_type: int, team: int) -> Node3D:
	var biome := CivData.get_biome(map_type)
	var m := instantiate_environment_model("field" if biome == "temperate" else biome + "/field", team)
	if m == null and biome != "temperate":
		m = instantiate_environment_model("field", team)
	return m


# =====================================================================================
# 2D sprite mode: sprites rendered in Blender from the SAME models (art_source/blender/render_sprites.py)
# Used when use_3d_building_models is false (Ayarlar > Görünüm: 2D Sprite).
# =====================================================================================
const SPRITE_MANIFEST_PATH: String = "res://data/art/sprite_manifest.json"
static var _sprite_manifest: Dictionary = {}
static var _sprite_manifest_loaded: bool = false
static var _sprite_tex_cache: Dictionary = {}

static func _load_sprite_manifest() -> void:
	if _sprite_manifest_loaded:
		return
	_sprite_manifest_loaded = true
	if not FileAccess.file_exists(SPRITE_MANIFEST_PATH):
		push_warning("FactionArtManager: sprite manifest missing at " + SPRITE_MANIFEST_PATH)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SPRITE_MANIFEST_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_sprite_manifest = parsed

static func get_sprite_entry(section: String, key: String) -> Dictionary:
	_load_sprite_manifest()
	var sec: Dictionary = _sprite_manifest.get(section, {})
	if section == "buildings":
		var parts := key.split("/")
		return sec.get(parts[0], {}).get(parts[1], {}) if parts.size() == 2 else {}
	return sec.get(key, {})

static func _sprite_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if not _sprite_tex_cache.has(path):
		_sprite_tex_cache[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
		if _sprite_tex_cache[path] == null:
			_log_once(path, "FactionArtManager: sprite missing: %s" % path)
	return _sprite_tex_cache[path]

## Builds the camera-facing sprite for a manifest entry. Returned node: origin = the model's origin on the
## ground; child "SpritePlane" stands at the model's front-most depth (plane_z) and is stretched by
## 1/cos(pitch) vertically, so the 45 deg game camera sees the render undistorted. `flip` mirrors it.
static func make_sprite_node(entry: Dictionary, team: int = -1, flip: bool = false) -> Node3D:
	if entry.is_empty():
		return null
	var path: String = entry.get("t%d" % clampi(team, 0, 1), "") if entry.has("t0") else entry.get("img", "")
	var tex := _sprite_texture(path)
	if tex == null:
		return null
	var p: float = 1.0 / float(entry.get("px_per_m", 32))
	var w: float = float(entry["w"])
	var h: float = float(entry["h"])
	var ax: float = float(entry["anchor"][0])
	var ay: float = float(entry["anchor"][1])
	if flip:
		ax = w - ax
	var root := Node3D.new()
	root.name = "SpriteVisual"
	var plane := Node3D.new()
	plane.name = "SpritePlane"
	plane.position = Vector3(0, 0, float(entry.get("plane_z", 0.0)))
	plane.scale = Vector3(1, 1.0 / cos(deg_to_rad(float(entry.get("pitch_deg", 45.0)))), 1)
	root.add_child(plane)
	var s := Sprite3D.new()
	s.name = "Sprite"
	s.texture = tex
	s.pixel_size = p
	s.flip_h = flip
	s.centered = true
	s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	s.shaded = false
	s.double_sided = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.position = Vector3((w * 0.5 - ax) * p, (ay - h * 0.5) * p, 0)
	plane.add_child(s)
	return root

static func instantiate_building_sprite(civ_type: CivData.CivType, b_type: Building3D.BuildingType, team: int) -> Node3D:
	return make_sprite_node(get_sprite_entry("buildings", "%s/%s" % [get_faction_id_from_civ(civ_type), get_building_id_from_type(b_type)]), team)

static func instantiate_environment_sprite(asset_id: String, flip: bool = false) -> Node3D:
	var e := get_sprite_entry("environment", asset_id)
	if e.is_empty() and "/" in asset_id:
		e = get_sprite_entry("environment", asset_id.get_slice("/", 1))
	return make_sprite_node(e, -1, flip)

static func instantiate_field_sprite(map_type: int, team: int) -> Node3D:
	var biome := CivData.get_biome(map_type)
	var e := get_sprite_entry("fields", "field" if biome == "temperate" else biome + "/field")
	if e.is_empty():
		e = get_sprite_entry("fields", "field")
	return make_sprite_node(e, team)

## Upgrade kit as two sprites: the back half stands behind the building sprite, the front half in front.
static func instantiate_upgrade_kit_sprite(civ: int, team: int) -> Node3D:
	var halves: Dictionary = get_sprite_entry("upgrade_kits", CivData.get_civ(civ).get("id", ""))
	if halves.is_empty():
		return null
	var root := Node3D.new()
	for half in ["back", "front"]:
		var n := make_sprite_node(halves.get(half, {}), team)
		if n != null:
			n.name = "Kit_" + half
			root.add_child(n)
	return root if root.get_child_count() > 0 else null
