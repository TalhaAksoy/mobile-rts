extends SceneTree

## Verifies every building sprite listed in the v2 building art manifest exists,
## loads as a Texture2D, and matches the manifest's declared size_px.
## (v1 of this test assumed a fixed 384x384 / 14-type sheet; the v2 "atlas-exact"
## pack uses per-building crops with variable size and 13 types per faction.)

const MANIFEST_PATH := "res://data/building_art_manifest.json"

func _init() -> void:
	call_deferred("_test_imports")

func _test_imports() -> void:
	var f := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if f == null:
		printerr("Missing manifest: " + MANIFEST_PATH)
		quit(1)
		return
	var manifest = JSON.parse_string(f.get_as_text())
	var expected_per_faction: int = int(manifest.get("buildings_per_faction", 13))

	var loaded_count := 0
	var total := 0
	var problems: Array[String] = []

	for faction in manifest["factions"].keys():
		var blds: Dictionary = manifest["factions"][faction]["buildings"]
		if blds.size() != expected_per_faction:
			problems.append("%s: %d buildings in manifest, expected %d" % [faction, blds.size(), expected_per_faction])
		for b in blds.keys():
			total += 1
			var entry: Dictionary = blds[b]
			var path := "res://" + str(entry["path"])
			if not ResourceLoader.exists(path):
				problems.append("Missing: " + path)
				continue
			var tex := load(path) as Texture2D
			var want: Array = entry.get("size_px", [])
			if tex == null:
				problems.append("Failed loading: " + path)
			elif want.size() == 2 and (tex.get_width() != int(want[0]) or tex.get_height() != int(want[1])):
				problems.append("Size mismatch %s: got %dx%d, manifest says %dx%d" % [path, tex.get_width(), tex.get_height(), int(want[0]), int(want[1])])
			else:
				loaded_count += 1

	print("LOADED %d / %d BUILDING SPRITES" % [loaded_count, total])
	if problems.size() > 0:
		for m in problems:
			printerr(m)
		print("RESULT: FAIL (%d problems)" % problems.size())
		quit(1)
	else:
		print("RESULT: PASS - all %d manifest building sprites load with declared sizes" % total)
		quit(0)
