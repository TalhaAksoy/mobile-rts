extends SceneTree

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")
const CivData = preload("res://scripts/CivData.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")

func _init() -> void:
	print("========================================")
	print("--- TESTING FACTION ART PACK INTEGRATION ---")
	print("========================================")

	var all_civs = [
		CivData.CivType.OTTOMANS,
		CivData.CivType.BYZANTINES,
		CivData.CivType.BRITONS,
		CivData.CivType.FRANKS,
		CivData.CivType.MONGOLS,
		CivData.CivType.TEUTONS,
		CivData.CivType.JAPANESE,
		CivData.CivType.SARACENS,
		CivData.CivType.VIKINGS,
		CivData.CivType.CHINESE
	]

	var standard_roles = [
		Unit3D.UnitType.VILLAGER,
		Unit3D.UnitType.SWORDSMAN,
		Unit3D.UnitType.SPEARMAN,
		Unit3D.UnitType.ARCHER
	]

	var special_roles = [
		Unit3D.UnitType.JANISSARY,
		Unit3D.UnitType.CATAPHRACT,
		Unit3D.UnitType.LONGBOWMAN,
		Unit3D.UnitType.PALADIN,
		Unit3D.UnitType.MANGUDAI,
		Unit3D.UnitType.TEUTONIC_KNIGHT,
		Unit3D.UnitType.SAMURAI,
		Unit3D.UnitType.MAMELUKE,
		Unit3D.UnitType.BERSERKER,
		Unit3D.UnitType.CHUKONU
	]

	var loaded_count = 0

	# 1. Test 4 Standard roles for all 10 factions (40 units)
	print("[1/3] Verifying 4 standard roles across 10 factions...")
	for civ in all_civs:
		var f_id = FactionArtManager.get_faction_id_from_civ(civ)
		for u_type in standard_roles:
			var tex = FactionArtManager.get_unit_texture(civ, u_type, "pose_01")
			assert(tex != null, "Texture must not be null for %s - %s" % [f_id, u_type])
			assert(tex.get_width() > 0 and tex.get_height() > 0, "Texture must have valid dimensions")
			loaded_count += 1
	print("-> Verified 40 standard role textures (10 civs x 4 roles).")

	# 2. Test 10 Unique Units
	print("[2/3] Verifying 10 unique special units...")
	for i in range(all_civs.size()):
		var civ = all_civs[i]
		var spec = special_roles[i]
		var f_id = FactionArtManager.get_faction_id_from_civ(civ)
		var tex = FactionArtManager.get_unit_texture(civ, spec, "pose_01")
		assert(tex != null, "Special unit texture must not be null for %s" % f_id)
		assert(tex.get_width() > 0, "Special unit texture must have valid width")
		loaded_count += 1
		print("  -> %s special unit loaded: %dx%d" % [f_id, tex.get_width(), tex.get_height()])
	print("-> Verified 10 unique special unit textures.")

	# 3. Test Concept Sheets and Flag References
	print("[3/3] Verifying 10 Concept Sheets & Flag References...")
	for civ in all_civs:
		var f_id = FactionArtManager.get_faction_id_from_civ(civ)
		var cs = FactionArtManager.get_concept_sheet_texture(civ)
		assert(cs != null, "Concept sheet must exist for %s" % f_id)
		var fl = FactionArtManager.get_flag_reference_texture(civ)
		assert(fl != null, "Flag reference must exist for %s" % f_id)
	print("-> All 10 Concept Sheets and 10 Flag References verified on disk!")

	print("========================================")
	print("TOTAL VERIFIED ASSETS LOADED: %d / 50 UNITS" % loaded_count)
	print("FACTION ART PACK ASSETS 100% VALIDATED!")
	print("========================================")
	quit(0)
