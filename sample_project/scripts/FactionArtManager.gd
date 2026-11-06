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
## Team colours: 0 = the player (blue), 1..5 = bots (red, yellow, green, purple, teal).
## The 2D pixel-art sheets (art_source/aseprite) exist in the first two (t0 / t1).
const TEAM_COLORS: Array[Color] = [Color(0.18, 0.52, 0.95), Color(0.92, 0.22, 0.22), Color(0.96, 0.78, 0.12),
	Color(0.22, 0.72, 0.28), Color(0.62, 0.32, 0.86), Color(0.10, 0.76, 0.72)]
const TEAM_COLOR_NAMES: Array[String] = ["Mavi", "Kırmızı", "Sarı", "Yeşil", "Mor", "Turkuaz"]

static func team_color(team: int) -> Color:
	return TEAM_COLORS[clampi(team, 0, TEAM_COLORS.size() - 1)]

## Occlusion tint (silhouette behind buildings): the team colour, lightened, half transparent.
static func team_xray_color(team: int) -> Color:
	var c := team_color(team).lerp(Color.WHITE, 0.25)
	c.a = 0.5
	return c

## Global switch: false -> every building uses the HD-2D sprite path (reversible fallback).
static var use_3d_building_models: bool = true

## The 2D sprite style is played from straight above (orthographic, 90 deg) with sprites drawn in a 3/4 "oblique"
## view lying flat on the ground, like a classic 2D RTS; the 3D style keeps the 45 deg perspective camera.
static func top_down() -> bool:
	return not use_3d_building_models

## Painter's order for the flat oblique sprites: height grows to the south (see ObliqueSort.gd). Kept well above
## the highest hill and below the lowest camera (12 m) on the largest map (192 m deep).
const OBLIQUE_SORT_BASE := 3.5
const OBLIQUE_SORT_K := 0.03
static func oblique_sort_y(z: float) -> float:
	return OBLIQUE_SORT_BASE + z * OBLIQUE_SORT_K

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

## 3D buildings by age (the Blender models are the Age II look): Age I swaps the masonry and the tiled / slate
## roofs for the village materials (plaster, thatch, plain wood instead of gilding); Age III adds tall team
## standards at the front corners (see add_age_dressing). Mongol felt, domes, lacquer and banners stay as they are.
const AGE1_MATERIALS := {
	"PE_StoneWarm": "PE_PlasterCream", "PE_StoneGrey": "PE_PlasterCream", "PE_StoneBrick": "PE_PlasterCream",
	"PE_Sandstone": "PE_Soil", "PE_SlateDark": "PE_WoodDark",
	"PE_RoofRed": "PE_Thatch", "PE_RoofSlate": "PE_Thatch", "PE_RoofDark": "PE_Thatch", "PE_RoofTeal": "PE_Thatch",
	"PE_TileTeal": "PE_Thatch", "PE_Shingle": "PE_Thatch", "PE_Gold": "PE_WoodDark",
}
## Per-civ Age I overrides on top of AGE1_MATERIALS: thatch is not the village roof everywhere. Byzantine villages
## kept clay tiles; Anatolian and Saracen villages are mud brick under earthen roofs; Norse farmsteads are turf-roofed.
const AGE1_CIV_MATERIALS := {
	# Anatolian village: mud-brick walls under earthen roofs (as the 2D Age I look), timber instead of ashlar
	"ottomans": {"PE_RoofRed": "PE_MudRoof", "PE_RoofTeal": "PE_MudRoof", "PE_TileTeal": "PE_MudRoof", "PE_RoofDark": "PE_MudRoof",
		"PE_RoofSlate": "PE_MudRoof", "PE_StoneWarm": "PE_MudBrick", "PE_StoneGrey": "PE_MudBrick", "PE_StoneBrick": "PE_MudBrick",
		"PE_PlasterWhite": "PE_MudBrick", "PE_Sandstone": "PE_MudBrick"},
	"byzantines": {"PE_RoofRed": "PE_RoofRed", "PE_RoofTeal": "PE_RoofRed", "PE_TileTeal": "PE_RoofRed", "PE_RoofDark": "PE_RoofRed",
		"PE_RoofSlate": "PE_RoofRed"},
	"saracens": {"PE_RoofRed": "PE_MudRoof", "PE_RoofTeal": "PE_MudRoof", "PE_TileTeal": "PE_MudRoof", "PE_RoofDark": "PE_MudRoof",
		"PE_RoofSlate": "PE_MudRoof", "PE_Shingle": "PE_MudRoof", "PE_StoneWarm": "PE_MudBrick", "PE_StoneGrey": "PE_MudBrick",
		"PE_StoneBrick": "PE_MudBrick", "PE_Sandstone": "PE_MudBrick", "PE_PlasterWhite": "PE_MudBrick", "PE_PlasterCream": "PE_MudBrick",
		"PE_ClothRed": "PE_SailCloth"},
	"vikings": {"PE_Shingle": "PE_Grass", "PE_RoofDark": "PE_Grass", "PE_RoofSlate": "PE_Grass", "PE_RoofRed": "PE_Grass"},
}
static func apply_building_age(node: Node, age: int, team: int, civ: String = "") -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src = mi.mesh.surface_get_material(i)
			var mat_name: String = src.resource_name if src != null else ""
			if mat_name == "" or mat_name.begins_with("TEAM_"):
				continue
			var want: String = mat_name
			if age == 1:
				var per: Dictionary = AGE1_CIV_MATERIALS.get(civ, {})
				want = per[mat_name] if per.has(mat_name) else AGE1_MATERIALS.get(mat_name, mat_name)
			var lib = get_library_material(want)
			if lib != null:
				mi.set_surface_override_material(i, lib)
	for c in node.get_children():
		apply_building_age(c, age, team, civ)

## Age III dressing for a 3D building: two tall standards (pole, team-coloured banner, gilded finial) on the front
## corners of the footprint (w x l metres, front = +z). Returned node is named "AgeDressing".
static func make_age_dressing(w: float, l: float, team: int, civ: String = "") -> Node3D:
	var root := Node3D.new()
	root.name = "AgeDressing"
	var specs: Array = AGE3_STANDARDS.get(civ, [{"form": "flag", "field": "TEAM"}, {"form": "flag", "field": "TEAM"}])
	# one standard on small footprints (houses, camps), two on the big ones; height follows the footprint
	var small := w <= 4.5
	var h := 2.8 if small else 3.4
	var sides: Array = [-1.0] if small else [-1.0, 1.0]
	for k in sides.size():
		var sx: float = sides[k]
		var spec: Dictionary = specs[min(k, specs.size() - 1)]
		var std := _make_standard(spec, h, team)
		std.position = Vector3(sx * (w * 0.5 - 0.3), 0.0, l * 0.5 - 0.3)
		root.add_child(std)
	return root

## Civ war standards for the Age III dressing (mirrors DRESS3 in art_source/aseprite/ages.lua). Historical standards,
## not modern national flags; every one keeps one team-coloured part (tassels, header, hoist or tails).
const AGE3_STANDARDS := {
	"ottomans": [{"form": "sancak", "field": "#B3202A", "ec": "#F3EFE6"}, {"form": "sancak", "field": "#3D6B3A", "ec": "#F3EFE6"}],
	"byzantines": [{"form": "labarum", "field": "#A7262B", "ec": "#E3B341", "emblem": "chirho"}, {"form": "labarum", "field": "#6E2A6A", "ec": "#E3B341", "emblem": "cross"}],
	"saracens": [{"form": "alam", "field": "#D6A62B", "field2": "#F3EFE6", "ec": "#2A2234"}],
	"mongols": [{"form": "sulde", "field": "#2B2622"}, {"form": "sulde", "field": "#EDE6D6"}],
	"chinese": [{"form": "qi", "field": "#C8382F", "ec": "#1D1A19"}],
	"japanese": [{"form": "nobori", "field": "#F0EEE8", "ec": "#1D1A19"}],
	"franks": [{"form": "oriflamme", "field": "#A33B2E"}, {"form": "gonfanon", "field": "#3E5486", "ec": "#E1B53B", "emblem": "fleur"}],
	"britons": [{"form": "pennon", "field": "#F2EFE6", "ec": "#B3282D"}, {"form": "gonfanon", "field": "#B3282D", "ec": "#E2B437", "emblem": "lions"}],
	"teutons": [{"form": "gonfanon", "field": "#F0EEE8", "ec": "#1D1A19", "emblem": "cross"}, {"form": "gonfanon", "field": "#E2B437", "ec": "#1D1A19", "emblem": "eagle"}],
	"vikings": [{"form": "raven", "field": "#F0EEE8", "ec": "#1D1A19"}, {"form": "raven", "field": "#E2C04A", "ec": "#1D1A19"}],
}

static var _cloth_cache := {}
static func _cloth(hex: String) -> Material:
	if not _cloth_cache.has(hex):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(hex)
		m.roughness = 0.9
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_cloth_cache[hex] = m
	return _cloth_cache[hex]

static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot_z: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.z = rot_z
	parent.add_child(mi)
	return mi

static func _make_standard(spec: Dictionary, h: float, team: int) -> Node3D:
	var n := Node3D.new()
	var wood = get_library_material("PE_WoodDark")
	var gold = get_library_material("PE_Gold")
	var tm = get_team_trim_material(team)
	var form: String = spec.get("form", "flag")
	var field: Material = tm if spec.get("field", "TEAM") == "TEAM" else _cloth(spec["field"])
	var ec: Material = _cloth(spec.get("ec", "#F3EFE6"))
	var f2: Material = _cloth(spec.get("field2", "#F3EFE6"))
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04; cm.bottom_radius = 0.055; cm.height = h; cm.radial_segments = 6
	pole.mesh = cm
	pole.material_override = wood
	pole.position.y = h * 0.5
	n.add_child(pole)
	var top := h
	var D := 0.04                                                      # cloth thickness; cloth faces south (+z)
	match form:
		"sulde":
			var tip := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0; cone.bottom_radius = 0.07; cone.height = 0.35; cone.radial_segments = 6
			tip.mesh = cone; tip.material_override = _cloth("#B8C0CC")
			tip.position.y = top + 0.17
			n.add_child(tip)
			var hair := MeshInstance3D.new()
			var hm := CylinderMesh.new()
			hm.top_radius = 0.12; hm.bottom_radius = 0.32; hm.height = 0.8; hm.radial_segments = 10
			hair.mesh = hm; hair.material_override = field
			hair.position.y = top - 0.45
			n.add_child(hair)
			_box(n, Vector3(0.05, 0.45, 0.05), Vector3(0.1, top - 1.05, 0.05), tm)
			_box(n, Vector3(0.05, 0.38, 0.05), Vector3(-0.1, top - 1.0, 0.05), tm)
		"sancak":
			_ball(n, gold, top + 0.08, 0.1)
			var tail := MeshInstance3D.new()
			var tc := CylinderMesh.new()
			tc.top_radius = 0.07; tc.bottom_radius = 0.16; tc.height = 0.45; tc.radial_segments = 8
			tail.mesh = tc; tail.material_override = _cloth("#2A2026"); tail.position.y = top - 0.25
			n.add_child(tail)
			var fy := top - 0.85
			_box(n, Vector3(0.8, 0.55, D), Vector3(0.45, fy, 0), field)
			_box(n, Vector3(0.28, 0.2, D), Vector3(0.95, fy + 0.15, 0), field, 0.25)        # swallowtail
			_box(n, Vector3(0.28, 0.2, D), Vector3(0.95, fy - 0.15, 0), field, -0.25)
			_disc(n, ec, Vector3(0.38, fy, D), 0.17)                                         # crescent: two discs
			_disc(n, field, Vector3(0.44, fy + 0.03, D * 1.6), 0.14)
			_box(n, Vector3(0.06, 0.55, D * 1.2), Vector3(0.07, fy, 0), tm)                   # team hoist
		"labarum", "gonfanon":
			_ball(n, gold, top + 0.06, 0.08)
			_box(n, Vector3(0.85, 0.05, 0.05), Vector3(0, top - 0.12, 0.05), wood)
			var cy := top - 0.62
			var cloth_m: Material = field
			_box(n, Vector3(0.72, 0.85, D), Vector3(0, cy, 0.08), cloth_m)
			_emblem(n, spec.get("emblem", "cross"), ec, Vector3(0, cy + 0.04, 0.08 + D))
			if form == "labarum":
				_box(n, Vector3(0.72, 0.05, D * 1.2), Vector3(0, cy + 0.36, 0.08), gold)
				for t in 5:
					_box(n, Vector3(0.06, 0.14, D), Vector3(-0.3 + t * 0.15, cy - 0.5, 0.08), tm)
			else:
				for t in 3:
					_box(n, Vector3(0.14, 0.32 - (t % 2) * 0.08, D), Vector3(-0.26 + t * 0.26, cy - 0.55, 0.08), tm)
		"nobori":
			_box(n, Vector3(0.5, 0.04, 0.04), Vector3(0.25, top - 0.05, 0), wood)
			var cy2 := top - 0.95
			_box(n, Vector3(0.42, 1.7, D), Vector3(0.28, cy2, 0), field)
			_box(n, Vector3(0.42, 0.22, D * 1.2), Vector3(0.28, top - 0.2, 0), tm)              # team header
			_disc(n, ec, Vector3(0.28, top - 0.55, D), 0.15)                                    # mon
			_disc(n, field, Vector3(0.28, top - 0.55, D * 1.6), 0.07)
		"qi":
			_ball(n, gold, top + 0.06, 0.08)
			var cy3 := top - 0.62
			_box(n, Vector3(0.62, 1.05, D), Vector3(0.36, cy3, 0), field)
			_box(n, Vector3(0.24, 0.06, D * 1.3), Vector3(0.36, cy3 + 0.2, 0), ec)              # the character
			_box(n, Vector3(0.06, 0.5, D * 1.3), Vector3(0.36, cy3, 0), ec)
			_box(n, Vector3(0.3, 0.06, D * 1.3), Vector3(0.36, cy3 - 0.12, 0), ec)
			_box(n, Vector3(0.08, 1.05, D * 1.2), Vector3(0.7, cy3, 0), tm)                     # team flame border
			_box(n, Vector3(0.62, 0.08, D * 1.2), Vector3(0.36, cy3 - 0.55, 0), tm)
		"oriflamme":
			_ball(n, gold, top + 0.06, 0.07)
			var cy4 := top - 0.35
			_box(n, Vector3(0.5, 0.5, D), Vector3(0.3, cy4, 0), field)
			for t in 3:
				_box(n, Vector3(0.55, 0.11, D), Vector3(0.78, cy4 + 0.18 - t * 0.18, 0), field, -0.08 * (t - 1))
			_box(n, Vector3(0.07, 0.5, D * 1.2), Vector3(0.07, cy4, 0), tm)
		"pennon":
			_ball(n, gold, top + 0.05, 0.06)
			var cy5 := top - 0.3
			_box(n, Vector3(0.6, 0.45, D), Vector3(0.34, cy5, 0), field)
			_box(n, Vector3(0.6, 0.09, D * 1.3), Vector3(0.34, cy5, 0), ec)
			_box(n, Vector3(0.09, 0.45, D * 1.3), Vector3(0.28, cy5, 0), ec)
			_box(n, Vector3(0.35, 0.14, D), Vector3(0.8, cy5 + 0.12, 0), tm, 0.25)             # team swallowtail
			_box(n, Vector3(0.35, 0.14, D), Vector3(0.8, cy5 - 0.12, 0), tm, -0.25)
		"raven":
			var cy6 := top - 0.45
			var pr := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(0.8, 0.8, D); pm.left_to_right = 0.0
			pr.mesh = pm; pr.material_override = f2 if spec.has("field2") else field
			pr.rotation.z = PI                                                                   # right angle at the top hoist
			pr.position = Vector3(0.42, cy6, 0)
			n.add_child(pr)
			_box(n, Vector3(0.22, 0.12, D * 1.4), Vector3(0.24, cy6 + 0.22, 0), ec)            # raven
			_box(n, Vector3(0.1, 0.07, D * 1.4), Vector3(0.38, cy6 + 0.26, 0), ec)
			_box(n, Vector3(0.95, 0.06, D * 1.2), Vector3(0.42, cy6, 0), tm, -PI / 4)           # team fringe on the curved edge
		"alam":
			_ball(n, gold, top + 0.06, 0.08)
			var cy7 := top - 0.4
			_box(n, Vector3(0.8, 0.62, D), Vector3(0.46, cy7, 0), field)
			_box(n, Vector3(0.8, 0.16, D * 1.3), Vector3(0.46, cy7 + 0.05, 0), f2)              # tiraz inscription band
			for t in 5:
				_box(n, Vector3(0.07, 0.06, D * 1.6), Vector3(0.18 + t * 0.14, cy7 + 0.05, 0), ec)
			_box(n, Vector3(0.07, 0.62, D * 1.2), Vector3(0.07, cy7, 0), tm)
		_:
			_ball(n, gold, top + 0.06, 0.08)
			_box(n, Vector3(0.7, 0.5, D), Vector3(0.38, top - 0.35, 0), field)
	return n

static func _ball(parent: Node3D, mat: Material, y: float, r: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r; sm.height = r * 2; sm.radial_segments = 8; sm.rings = 4
	mi.mesh = sm; mi.material_override = mat; mi.position.y = y
	parent.add_child(mi)

static func _disc(parent: Node3D, mat: Material, pos: Vector3, r: float) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r; c.bottom_radius = r; c.height = 0.02; c.radial_segments = 12
	mi.mesh = c; mi.material_override = mat
	mi.rotation.x = PI / 2
	mi.position = pos
	parent.add_child(mi)

static func _emblem(parent: Node3D, kind: String, mat: Material, pos: Vector3) -> void:
	var z := Vector3(0, 0, 0.0)
	match kind:
		"cross", "chirho":
			_box(parent, Vector3(0.09, 0.5, 0.03), pos, mat)
			_box(parent, Vector3(0.38, 0.09, 0.03), pos + Vector3(0, 0.08, 0), mat)
			if kind == "chirho":
				_disc(parent, mat, pos + Vector3(0.08, 0.2, 0), 0.07)
		"fleur":
			_box(parent, Vector3(0.08, 0.36, 0.03), pos, mat)
			_box(parent, Vector3(0.1, 0.22, 0.03), pos + Vector3(-0.1, 0.02, 0), mat, 0.5)
			_box(parent, Vector3(0.1, 0.22, 0.03), pos + Vector3(0.1, 0.02, 0), mat, -0.5)
			_box(parent, Vector3(0.3, 0.06, 0.03), pos + Vector3(0, -0.06, 0), mat)
		"lions":
			for t in 3:
				_box(parent, Vector3(0.36, 0.1, 0.03), pos + Vector3(0, 0.22 - t * 0.22, 0), mat)
				_box(parent, Vector3(0.08, 0.06, 0.03), pos + Vector3(0.18, 0.27 - t * 0.22, 0), mat)
		"eagle":
			_box(parent, Vector3(0.12, 0.34, 0.03), pos, mat)
			_box(parent, Vector3(0.44, 0.1, 0.03), pos + Vector3(0, 0.05, 0), mat)
			_box(parent, Vector3(0.12, 0.1, 0.03), pos + Vector3(0, 0.22, 0), mat)
		_:
			_disc(parent, mat, pos, 0.14)

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
# 2D sprite mode: pixel-art sprites generated in Aseprite (art_source/aseprite, assets/sprites_px/)
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
	if entry.get("view", "") == "oblique":
		return _make_oblique_sprite(root, tex, entry, p, w, h, ax, ay, flip)
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

## Oblique sprite (2D style): the 3/4-view image lies flat (image-up = north) with its anchor - the front centre
## of the footprint, a unit's feet, a tree's foot - on the ground point plane_z metres in front of the node origin,
## so the drawn front face and roof extend northwards over the footprint like in a 2D game. ObliqueSort lifts it
## to its painter's-order height. Same node names as the upright sprite ("SpritePlane/Sprite").
const ObliqueSortScript = preload("res://scripts/ObliqueSort.gd")
static func _make_oblique_sprite(root: Node3D, tex: Texture2D, entry: Dictionary, p: float, w: float, h: float,
		ax: float, ay: float, flip: bool) -> Node3D:
	var plane: Node3D = ObliqueSortScript.new()
	plane.name = "SpritePlane"
	plane.position = Vector3(0, 0, float(entry.get("plane_z", 0.0)))
	plane.rotation_degrees = Vector3(-90, 0, 0)
	if entry.get("ground", false):
		plane.set_meta("ground", true)              # fields: under everything that stands on them
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

## Age looks (art_source/aseprite/ages.lua): an entry may carry "ages": {"1": {...}, "3": {...}} with the fields
## that differ (texture paths, size, anchor). Age II is the base entry itself; a missing age falls back to it.
static func for_age(entry: Dictionary, age: int) -> Dictionary:
	var ages: Dictionary = entry.get("ages", {})
	var key := str(age)
	if age == 2 or not ages.has(key):
		return entry
	var e := entry.duplicate()
	e.merge(ages[key], true)
	e.erase("ages")
	return e

static func instantiate_building_sprite(civ_type: CivData.CivType, b_type: Building3D.BuildingType, team: int, age: int = 2) -> Node3D:
	var e := get_sprite_entry("buildings", "%s/%s" % [get_faction_id_from_civ(civ_type), get_building_id_from_type(b_type)])
	return make_sprite_node(for_age(e, age), team)

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


# ---- 3D units (art_source/blender/units -> data/art/unit_model_manifest.json) ---------------------
## Rigged character GLBs (shared 20-bone rig, actions idle / walk / attack / gather / build / death).
## Used when the visual style is 3D (use_3d_building_models); a civ/role without a model keeps its sprite.
const UNIT_MANIFEST_PATH: String = "res://data/art/unit_model_manifest.json"
static var _unit_manifest: Dictionary = {}
static var _unit_manifest_loaded := false
static var _unit_mat_cache: Dictionary = {}

static func _load_unit_manifest() -> void:
	if _unit_manifest_loaded:
		return
	_unit_manifest_loaded = true
	if FileAccess.file_exists(UNIT_MANIFEST_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(UNIT_MANIFEST_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			_unit_manifest = parsed.get("units", {})

## Roles to try for a unit's 3D model / sheet, best first. The gallery role (get_unit_role_id), then for the
## mounted types the civ's own mounted unit (cataphract / knight / horse archer / mamluk) or its generic "cavalry"
## (the civ's swordsman on a horse), finally the civ's swordsman.
static func unit_model_roles(unit_type: Unit3D.UnitType, faction_id: String) -> Array:
	var role := get_unit_role_id(unit_type, faction_id)
	const MOUNTED := ["cataphract", "knight", "horse_archer", "mamluk", "cavalry"]
	if unit_type in [Unit3D.UnitType.CAVALRY, Unit3D.UnitType.PALADIN, Unit3D.UnitType.CATAPHRACT,
			Unit3D.UnitType.MANGUDAI, Unit3D.UnitType.MAMELUKE]:
		var roles: Array = [role] if role in MOUNTED else []
		roles.append_array(MOUNTED)
		roles.append("swordsman")
		return roles
	return [role] if unit_type == Unit3D.UnitType.VILLAGER else [role, "swordsman"]

static func _pick_unit_role(table: Dictionary, unit_type: Unit3D.UnitType, faction_id: String) -> Dictionary:
	for r in unit_model_roles(unit_type, faction_id):
		if table.has(r):
			return table[r]
	return {}

## The manifest entry for this civ's unit (see unit_model_roles for the fallbacks).
static func get_unit_model_entry(civ_type: CivData.CivType, unit_type: Unit3D.UnitType) -> Dictionary:
	_load_unit_manifest()
	var faction_id = get_faction_id_from_civ(civ_type)
	var e := _pick_unit_role(_unit_manifest.get(faction_id, {}), unit_type, faction_id)
	if e.is_empty() or not e.get("enabled", false):
		return {}
	return e

static func instantiate_unit_model(civ_type: CivData.CivType, unit_type: Unit3D.UnitType, team: int, age: int = 2) -> Node3D:
	if not use_3d_building_models:
		return null
	var e := for_age(get_unit_model_entry(civ_type, unit_type), age)
	if e.is_empty():
		return null
	var path: String = e["model"]
	if not _model_cache.has(path):
		_model_cache[path] = load(path) if ResourceLoader.exists(path) else null
	var ps: PackedScene = _model_cache[path]
	if ps == null:
		_log_once(path, "FactionArtManager: unit model missing: %s (using sprite)" % path)
		return null
	var inst := ps.instantiate() as Node3D
	_apply_unit_materials(inst, team)
	return inst

## ---- team colour on the unit palette ---------------------------------------------------------------------
## Unit models carry ONE material, PE_UnitPalette: faces in the team colour are UV-mapped onto a reserved swatch
## (art_source/blender/units/charkit.py TEAM_SWATCH, bottom-right 8x8 px). Each team gets a palette copy with its
## colour in that swatch, so a unit body is one surface: one draw call plus its X-ray and shadow passes.
## (Models exported before this still have a TEAM_Trim surface; it keeps working through get_unit_material.)
const TEAM_SWATCH := Rect2i(248, 248, 8, 8)
static var _team_palette_cache := {}         # team -> StandardMaterial3D

static func team_palette_material(team: int) -> Material:
	if _team_palette_cache.has(team):
		return _team_palette_cache[team]
	var base := get_library_material("PE_UnitPalette") as StandardMaterial3D
	var m := (base.duplicate() if base != null else StandardMaterial3D.new()) as StandardMaterial3D
	m.resource_name = "PE_UnitPalette"
	var tex := m.albedo_texture
	if tex != null:
		var img := tex.get_image()
		if img != null:
			img = img.duplicate()
			if img.is_compressed():
				img.decompress()
			img.fill_rect(TEAM_SWATCH, (get_team_trim_material(team) as StandardMaterial3D).albedo_color)
			m.albedo_texture = ImageTexture.create_from_image(img)
	m.stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
	m.stencil_color = team_xray_color(team)
	_team_palette_cache[team] = m
	return m

## Palette + team-colour surfaces, each with a see-through pass: where buildings or trees hide the unit
## it shows as a flat team-coloured silhouette (depth test inverted), like the sprites' occlusion silhouette.
static func get_unit_material(mat_name: String, team: int) -> Material:
	var key := "%s_%d" % [mat_name, team]
	if _unit_mat_cache.has(key):
		return _unit_mat_cache[key]
	var base: Material = get_team_trim_material(team) if mat_name.begins_with("TEAM_") else get_library_material(mat_name)
	var m: StandardMaterial3D = (base.duplicate() if base != null else StandardMaterial3D.new()) as StandardMaterial3D
	# stencil "X-Ray": the material marks the unit's own pixels, the x-ray pass draws only where something
	# else (a building, a tree) is in front - overlapping parts of the model itself never show it
	m.stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
	m.stencil_color = team_xray_color(team)
	_unit_mat_cache[key] = m
	return m

static func _apply_unit_materials(node: Node, team: int) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for i in mi.mesh.get_surface_count():
			var src = mi.mesh.surface_get_material(i)
			var mat_name: String = src.resource_name if src != null else ""
			if mat_name == "PE_UnitPalette":
				mi.set_surface_override_material(i, team_palette_material(team))
			elif mat_name != "":
				mi.set_surface_override_material(i, get_unit_material(mat_name, team))
	for c in node.get_children():
		_apply_unit_materials(c, team)


# ---- 2D units: pixel-art sprite sheets from Aseprite (art_source/aseprite/units.lua) -------------
const UNIT_SPRITE_MANIFEST_PATH: String = "res://data/art/unit_sprite_manifest.json"
static var _unit_sprite_manifest: Dictionary = {}
static var _unit_sprite_manifest_loaded := false

## Sheet entry for this civ's unit (same swordsman fallback as the models): w, h, anchor, hframes,
## vframes, anims {name: {row, frames, fps, loop}}, t0 / t1 texture paths. {} -> the old gallery sprite.
static func get_unit_sheet_entry(civ_type: CivData.CivType, unit_type: Unit3D.UnitType, age: int = 2) -> Dictionary:
	if not _unit_sprite_manifest_loaded:
		_unit_sprite_manifest_loaded = true
		if FileAccess.file_exists(UNIT_SPRITE_MANIFEST_PATH):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(UNIT_SPRITE_MANIFEST_PATH))
			if typeof(parsed) == TYPE_DICTIONARY:
				_unit_sprite_manifest = parsed.get("units", {})
	var faction_id = get_faction_id_from_civ(civ_type)
	return for_age(_pick_unit_role(_unit_sprite_manifest.get(faction_id, {}), unit_type, faction_id), age)
