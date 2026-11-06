extends SceneTree
## Visual style (Ayarlar > Görünüm):
##  * 3D mode: on all five maps every tree, mine and bush is a 3D model (no sprite anywhere); every
##    civ x building type x team is its 3D model; fields are 3D on every biome.
##  * 2D mode: the same objects use the Aseprite pixel-art sprites (res://assets/sprites_px/...),
##    never the old hand-drawn art; team colours per team; construction
##    reveals the sprite from the ground up; upgrades add the kit as back + front sprites.
##  * every model in the model manifest has its sprite (and the PNG exists).
const GameController3D = preload("res://scripts/GameController3D.gd")

var failures := 0
var checks := 0

func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("[FAIL] " + msg)

func _init() -> void:
	call_deferred("_run")

func _sprites_in(n: Node) -> Array:
	return n.find_children("*", "Sprite3D", true, false)

func _meshes_in(n: Node) -> Array:
	return n.find_children("*", "MeshInstance3D", true, false)

func _check_props(game, mode: String) -> void:
	var mg = game.map_gen
	var tag := "%s map %d (%s)" % [mode, mg.map_type, CivData.get_biome(mg.map_type)]
	var n := 0
	var bad := []
	for dict in [mg.trees, mg.gold_mines, mg.stone_mines, mg.berry_bushes]:
		for cell in dict.keys():
			var node = dict[cell]["node"]
			if not is_instance_valid(node):
				continue
			n += 1
			var vis = node.get_node_or_null("Visual")
			var ok := vis != null
			if ok and mode == "3d":
				ok = _sprites_in(node).is_empty() and not _meshes_in(vis).is_empty()
			elif ok:
				var sp: Array = _sprites_in(vis)
				ok = sp.size() == 1 and String(sp[0].texture.resource_path).begins_with("res://assets/sprites_px/environment/")
			if not ok and bad.size() < 5:
				bad.append("%s %s" % [dict[cell].get("name", "?"), str(cell)])
			if not ok:
				failures += 1
	checks += 1
	print("%s: %d props checked" % [tag, n])
	_check(n > 50 and bad.is_empty(), "%s: every tree/mine/bush uses the %s look %s" % [tag, mode, str(bad)])

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	var game = scene as GameController3D
	await process_frame

	# ---- sprite manifest covers every model
	var models = JSON.parse_string(FileAccess.get_file_as_string("res://data/art/building_model_manifest.json"))
	var missing := []
	for civ_id in models["buildings"].keys():
		for b_id in models["buildings"][civ_id].keys():
			var e := FactionArtManager.get_sprite_entry("buildings", "%s/%s" % [civ_id, b_id])
			if e.is_empty() or not ResourceLoader.exists(e.get("t0", "")) or not ResourceLoader.exists(e.get("t1", "")):
				missing.append("%s/%s" % [civ_id, b_id])
	for key in models["environment"].keys():
		var section := "fields" if key.ends_with("field") else "environment"
		var e := FactionArtManager.get_sprite_entry(section, key)
		if e.is_empty() or not (ResourceLoader.exists(e.get("img", "")) or ResourceLoader.exists(e.get("t0", ""))):
			missing.append(key)
	for civ_id in models["upgrade_kits"].keys():
		var e := FactionArtManager.get_sprite_entry("upgrade_kits", civ_id)
		if e.get("back", {}).is_empty() or e.get("front", {}).is_empty():
			missing.append("kit " + civ_id)
	_check(missing.is_empty(), "every model has its Blender sprite %s" % str(missing))

	for mode in ["3d", "2d"]:
		FactionArtManager.use_3d_building_models = mode == "3d"
		# ---- environment on every map
		for m in CivData.MapType.values():
			seed(1000 + m)
			game.player_civ = CivData.CivType.BRITONS
			game.selected_map_type = m
			game.start_match()
			game.enemy_ai.set_process(false)
			await process_frame
			_check_props(game, mode)
			# a field on this biome, both teams
			for team in [0, 1]:
				var f := Building3D.new()
				root.add_child(f)
				f.setup_building(Building3D.BuildingType.FARM, team, CivData.CivType.BRITONS, Vector2i(2, 2), game.map_gen, game, false)
				if mode == "3d":
					_check(is_instance_valid(f.building_model) and _sprites_in(f).is_empty(), "3d field on map %d team %d is 3D" % [m, team])
				else:
					_check(f.sprite_is_rendered and String(f.building_sprite.texture.resource_path).ends_with("_t%d.png" % team), "2d field on map %d team %d uses its rendered sprite" % [m, team])
				f.free()
		# ---- every civ x building type x team
		for civ in CivData.CIVS.keys():
			var civ_id := FactionArtManager.get_faction_id_from_civ(civ)
			for t in Building3D.BuildingType.values():
				if t == Building3D.BuildingType.FARM:
					continue
				var b_id := FactionArtManager.get_building_id_from_type(t)
				for team in [0, 1]:
					var tag := "%s %s/%s team %d" % [mode, civ_id, b_id, team]
					var b := Building3D.new()
					root.add_child(b)
					b.setup_building(t, team, civ, Vector2i(10, 10), game.map_gen, game, true)
					if mode == "3d":
						_check(is_instance_valid(b.building_model) and not is_instance_valid(b.building_sprite), tag + ": 3D model, no sprite")
					else:
						var path: String = b.building_sprite.texture.resource_path if is_instance_valid(b.building_sprite) else ""
						var want: String = FactionArtManager.get_sprite_entry("buildings", "%s/%s" % [civ_id, b_id]).get("t%d" % team, "")
						_check(b.sprite_is_rendered and not is_instance_valid(b.building_model) and want != "" and path == want
							and path.begins_with("res://assets/sprites_px/"),
							tag + ": rendered sprite (%s)" % path)
						if b.sprite_is_rendered:
							var full: int = b.building_sprite.texture.get_height()
							_check(b.building_sprite.region_enabled and b.building_sprite.region_rect.size.y < full, tag + ": under construction shows the lower part only")
							b.contribute_construction(1000.0)
							_check(b.is_completed and not b.building_sprite.region_enabled, tag + ": completed shows the whole sprite")
							b.set_upgrade_level(2)
							_check(is_instance_valid(b.upgrade_node) and b.upgrade_node.has_node("Kit_back") and b.upgrade_node.has_node("Kit_front"), tag + ": upgrade kit as back + front sprites")
					b.free()
	FactionArtManager.use_3d_building_models = true
	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
