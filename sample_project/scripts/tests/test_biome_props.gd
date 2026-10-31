extends SceneTree
## Every map type must dress its trees / mines / food with the props of its own biome:
##   * every id in CivData.BIOME_PROPS resolves to an enabled 3D model in the manifest,
##   * on a generated map every resource node has a 3D "Visual" (no sprite fallback),
##   * that visual uses the biome's nature atlas (desert map -> PE_NatureAtlas_Desert, ...),
##   * the display name shown in the UI comes from the biome table.
const GameController3D = preload("res://scripts/GameController3D.gd")

var failures := 0

func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("[PASS] " + msg)
	else:
		failures += 1
		print("[FAIL] " + msg)

func _init() -> void:
	call_deferred("_run")

func _atlas_names(node: Node, out: Dictionary) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m = mi.get_surface_override_material(i)
			if m == null:
				m = mi.mesh.surface_get_material(i)
			if m != null and m.resource_name.begins_with("PE_NatureAtlas"):
				out[m.resource_name] = true
	for c in node.get_children():
		_atlas_names(c, out)

func _run() -> void:
	# 1. table -> manifest
	for biome in CivData.BIOME_PROPS.keys():
		var props: Dictionary = CivData.BIOME_PROPS[biome]
		var ids: Array = []
		for t in props["trees"]:
			ids.append(t[0])
		ids += [props["gold"][0], props["stone"][0], props["food"][0]]
		for id in ids:
			_expect(FactionArtManager.get_environment_model(id) != null, "%s: model '%s' loads" % [biome, id])

	# 2. generated maps
	for mt in CivData.MAP_CONFIGS.keys():
		seed(900 + int(mt))
		var biome := CivData.get_biome(mt)
		var props: Dictionary = CivData.get_biome_props(mt)
		var expected_atlas: String = "PE_NatureAtlas" if biome == "temperate" else "PE_NatureAtlas_" + biome.capitalize()
		var scene = load("res://scenes/Main3D.tscn").instantiate()
		root.add_child(scene)
		var game = scene as GameController3D
		game.selected_map_type = mt
		game.start_match()
		var mg = game.map_gen
		var tree_names: Array = []
		for t in props["trees"]:
			tree_names.append(t[1])
		var groups := [["wood", mg.trees], ["gold", mg.gold_mines], ["stone", mg.stone_mines], ["food", mg.berry_bushes]]
		for g in groups:
			var kind: String = g[0]
			var dict: Dictionary = g[1]
			var no_visual := 0
			var wrong_atlas := 0
			var wrong_name := 0
			for c in dict.keys():
				var e: Dictionary = dict[c]
				var vis = e["node"].get_node_or_null("Visual")
				if vis == null:
					no_visual += 1
					continue
				var atlases := {}
				_atlas_names(vis, atlases)
				# temperate gold/stone are shared with the autumn biome
				var want := expected_atlas
				var prop_id: String = props[kind][0] if kind != "wood" else ""
				if kind != "wood" and not "/" in prop_id:
					want = "PE_NatureAtlas"
				if not atlases.has(want):
					wrong_atlas += 1
				var ok_name: bool = (e["name"] in tree_names) if kind == "wood" else (e["name"] == props[kind if kind != "wood" else "food"][1])
				if not ok_name:
					wrong_name += 1
			_expect(dict.size() > 0 and no_visual == 0 and wrong_atlas == 0 and wrong_name == 0,
				"map %d (%s) %s: %d nodes, missing visual=%d, wrong atlas=%d, wrong name=%d"
				% [mt, biome, kind, dict.size(), no_visual, wrong_atlas, wrong_name])
		scene.queue_free()
		await process_frame
	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
