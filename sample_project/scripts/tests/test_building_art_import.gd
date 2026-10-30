extends SceneTree

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

func _init() -> void:
	call_deferred("_test_imports")

func _test_imports() -> void:
	var factions = [
		"ottomans", "byzantines", "britons", "franks", "mongols",
		"teutons", "japanese", "saracens", "vikings", "chinese"
	]
	var buildings = [
		"town_center", "house", "barracks", "archery_range", "stable",
		"blacksmith", "castle", "watch_tower", "lumber_camp", "mining_camp",
		"mill", "farm", "market", "stone_wall"
	]

	var loaded_count = 0
	var missing = []

	for f in factions:
		for b in buildings:
			var path = "res://art/buildings/%s/%s.png" % [f, b]
			if ResourceLoader.exists(path):
				var tex = load(path) as Texture2D
				if tex != null and tex.get_width() == 384 and tex.get_height() == 384:
					loaded_count += 1
				else:
					missing.append("Failed loading or bad size: " + path)
			else:
				missing.append("Missing: " + path)

	print("LOADED %d / 140 BUILDING SPRITES" % loaded_count)
	if missing.size() > 0:
		for m in missing:
			printerr(m)
		quit(1)
	else:
		print("ALL 140 BUILDING SPRITES LOADED PERFECTLY!")
		quit(0)
