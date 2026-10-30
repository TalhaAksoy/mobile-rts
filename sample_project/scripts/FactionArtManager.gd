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
