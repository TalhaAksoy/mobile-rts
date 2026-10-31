extends SceneTree
## A saved game gets its map back exactly. Loading regenerates the map from its seed, so:
##  * every map type regenerates identically from its seed: same trees (and species), gold and stone
##    mines and berry bushes in the same cells. Mines used to land elsewhere because they were placed
##    with the global random generator.
##  * after a load nothing from the previous map lingers: every resource entry has a live node. The
##    stone mine list used to keep the old map's (invisible) mines.
##  * what was used up before the save stays gone (cut trees, a mined-out stone mine, an eaten bush),
##    and partly used nodes keep what was left (a half-mined gold mine is not full again, and is still
##    drawn smaller)
const GameController3D = preload("res://scripts/GameController3D.gd")

var failures := 0
var checks := 0

func _check(cond: bool, msg: String) -> void:
	checks += 1
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _init() -> void:
	call_deferred("_run")

func _layout(mg) -> Dictionary:
	var out := {}
	for t in [["wood", mg.trees], ["gold", mg.gold_mines], ["stone", mg.stone_mines], ["food", mg.berry_bushes]]:
		var cells := {}
		for c in t[1].keys():
			cells[c] = String(t[1][c].get("name", ""))
		out[t[0]] = cells
	return out

func _stale(mg) -> Array:
	var bad := []
	for d in [mg.trees, mg.gold_mines, mg.stone_mines, mg.berry_bushes]:
		for c in d.keys():
			var n = d[c].get("node", null)
			if not is_instance_valid(n) or n.is_queued_for_deletion():
				bad.append(c)
	return bad

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var game = scene as GameController3D
	var path := "user://saves/test_save_load_map.json"

	for m in CivData.MapType.values():
		var tag := "map %d (%s)" % [m, CivData.MapType.keys()[m]]
		seed(7300 + m)
		game.selected_map_type = m
		game.start_match()
		game.enemy_ai.set_process(false)
		await process_frame
		var mg = game.map_gen
		var before := _layout(mg)

		# use some of everything: cut 3 trees, mine one stone mine out, half-mine a gold mine, eat
		# one bush and nibble another
		var cut := []
		for c in mg.trees.keys():
			if cut.size() < 3:
				cut.append(c)
		for c in cut:
			mg.harvest_tree(c, 100000)
		var stone_gone: Vector2i = mg.stone_mines.keys()[0]
		mg.harvest_stone(stone_gone, 100000)
		var stone_walk: bool = mg.is_cell_walkable(stone_gone)   # (a tree can share the cell)
		var gold_half: Vector2i = mg.gold_mines.keys()[0]
		var gold_full: int = mg.gold_mines[gold_half]["gold"]
		mg.harvest_gold(gold_half, gold_full / 2)
		var gold_left: int = mg.gold_mines[gold_half]["gold"]
		var gold_scale: float = mg.gold_mines[gold_half]["node"].get_node("Visual").scale.x
		var bushes: Array = mg.berry_bushes.keys()
		var bush_gone: Vector2i = bushes[0]
		var bush_part: Vector2i = bushes[1]
		mg.harvest_food(bush_gone, 100000)
		mg.harvest_food(bush_part, 30)
		var bush_left: int = mg.berry_bushes[bush_part]["food"]
		var expected := _layout(mg)
		await process_frame

		_check(SaveManager.save_game(game, path), "%s: saved" % tag)
		# something else happens in between (another match), then the save is loaded
		seed(99)
		game.selected_map_type = (m + 1) % CivData.MapType.size()
		game.start_match()
		await process_frame
		SaveManager.load_game(game, path)
		await process_frame
		await process_frame
		mg = game.map_gen
		var after := _layout(mg)

		_check(after == expected, "%s: loaded map has every tree / mine / bush where it was (%d trees, %d gold, %d stone, %d bushes)" % [tag,
			after["wood"].size(), after["gold"].size(), after["stone"].size(), after["food"].size()])
		var regenerated_same := true
		for k in before.keys():
			for c in before[k].keys():
				if not (c in cut or c == stone_gone or c == bush_gone) and (not after[k].has(c) or after[k][c] != before[k][c]):
					regenerated_same = false
		_check(regenerated_same, "%s: same cells and same species as before the save" % tag)
		var stale := _stale(mg)
		_check(stale.is_empty(), "%s: nothing left over from the previous map %s" % [tag, str(stale.slice(0, 4))])
		var cut_back := []
		for c in cut:
			if mg.trees.has(c):
				cut_back.append(c)
		_check(cut_back.is_empty() and not mg.stone_mines.has(stone_gone) and not mg.berry_bushes.has(bush_gone),
			"%s: cut trees, the mined-out stone mine and the eaten bush stay gone" % tag)
		_check(mg.is_cell_walkable(stone_gone) == stone_walk, "%s: the mined-out stone mine's cell is as walkable as before the save (%s)" % [tag, stone_walk])
		var g_ok: bool = mg.gold_mines.has(gold_half) and int(mg.gold_mines[gold_half]["gold"]) == gold_left
		_check(g_ok, "%s: half-mined gold keeps %d of %d" % [tag, gold_left, gold_full])
		if g_ok:
			var s: float = mg.gold_mines[gold_half]["node"].get_node("Visual").scale.x
			_check(is_equal_approx(s, gold_scale), "%s: and is still drawn smaller (scale %.2f, before save %.2f)" % [tag, s, gold_scale])
		_check(mg.berry_bushes.has(bush_part) and int(mg.berry_bushes[bush_part]["food"]) == bush_left, "%s: nibbled bush keeps %d food" % [tag, bush_left])

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
