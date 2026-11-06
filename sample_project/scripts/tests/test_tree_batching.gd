extends SceneTree
## 3D trees are drawn through chunked MultiMeshes (MapGenerator3D._batch_trees):
##  * every 3D tree has batch instances and its own mesh nodes are hidden (no double drawing)
##  * unexplored trees are hidden (zero-scaled instance), trees in sight are shown at full size
##  * a chopped-down tree disappears from its batch
##  * 2D sprite trees are not batched
const GameController3D = preload("res://scripts/GameController3D.gd")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _frames(n: int) -> void:
	for i in n:
		await process_frame

## Shown = full-size instance. Windowed runs read the MultiMesh itself; the headless renderer keeps no MultiMesh
## data, so there the batch's own record of what each instance shows is read.
func _shown(mg, t: Dictionary) -> bool:
	var headless := DisplayServer.get_name() == "headless"
	for r in t.get("batch", []):
		var b = mg._tree_batches[r[0]]
		var on: bool = b["on"][r[1]] == 1 if headless else b["mmi"].multimesh.get_instance_transform(r[1]).basis.get_scale().x > 0.01
		if not on:
			return false
	return not t.get("batch", []).is_empty()

func _start(style: int) -> GameController3D:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	await _frames(3)
	GraphicsSettings.set_value("style", style)
	FactionArtManager.use_3d_building_models = style == 0
	scene.start_match()
	scene.enemy_ai.set_process(false)
	await _frames(15)
	return scene

func _run() -> void:
	var was_3d := FactionArtManager.use_3d_building_models
	var game: GameController3D = await _start(0)
	var mg = game.map_gen
	var all_batched := true
	var own_mesh_visible := 0
	for c in mg.trees:
		var t: Dictionary = mg.trees[c]
		all_batched = all_batched and not t.get("batch", []).is_empty()
		for mi in t["node"].find_children("*", "MeshInstance3D", true, false):
			if mi.visible:
				own_mesh_visible += 1
	_check(mg.trees.size() > 100 and all_batched, "3D: all %d trees are in batches (%d batches)" % [mg.trees.size(), mg._tree_batches.size()])
	_check(own_mesh_visible == 0, "3D: the trees' own mesh nodes are hidden (%d visible)" % own_mesh_visible)
	var seen_ok := true
	var hidden_ok := true
	var n_seen := 0
	var n_hidden := 0
	for c in mg.trees:
		var st = mg.get_fog_state(c)
		if st == MapGenerator3D.FogState.UNEXPLORED:
			n_hidden += 1
			hidden_ok = hidden_ok and not _shown(mg, mg.trees[c])
		else:
			n_seen += 1
			seen_ok = seen_ok and _shown(mg, mg.trees[c])
	_check(n_seen > 0 and seen_ok, "3D: %d explored trees are drawn" % n_seen)
	_check(n_hidden > 0 and hidden_ok, "3D: %d unexplored trees are hidden" % n_hidden)
	var chop: Vector2i = Vector2i(-1, -1)
	for c in mg.trees:
		if mg.get_fog_state(c) != MapGenerator3D.FogState.UNEXPLORED:
			chop = c
			break
	var entry: Dictionary = mg.trees[chop]
	mg.harvest_tree(chop, 100000)
	_check(not mg.trees.has(chop) and not _shown(mg, entry), "3D: a chopped tree leaves its batch")
	game.queue_free()
	await _frames(3)

	var game2: GameController3D = await _start(1)
	var any_batched := false
	for c in game2.map_gen.trees:
		any_batched = any_batched or game2.map_gen.trees[c].has("batch")
	_check(not any_batched and game2.map_gen._tree_batches.is_empty(), "2D: sprite trees are not batched")
	FactionArtManager.use_3d_building_models = was_3d
	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
