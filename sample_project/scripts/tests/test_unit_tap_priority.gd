extends SceneTree
## Regression: friendly-unit taps vs. resource taps when villagers stand next to a tree.
##  A) With villager A selected, tapping villager B (standing beside a tree) selects B,
##     it must NOT be converted into a gather order for A.
##  B) With villager A selected, tapping the tree itself (away from units) still gathers.

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _tap_point(game, u: Node3D) -> Vector2:
	return (game.camera.unproject_position(u.global_position) + game.camera.unproject_position(u.global_position + Vector3(0, 1.8, 0))) * 0.5

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	var game = scene as GameController3D
	game.start_match()

	var vills: Array = []
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			vills.append(u)

	# Pick the tree closest to the player start and stand both villagers next to it.
	var best_cell = null
	var best_d := INF
	for c in game.map_gen.trees.keys():
		var d = game.map_gen.cell_to_world(c).distance_to(game.map_gen.player_start_pos)
		if d < best_d:
			best_d = d
			best_cell = c
	_check(best_cell != null, "Map contains at least one tree")
	var tree_pos: Vector3 = game.map_gen.cell_to_world(best_cell)
	game.camera.jump_to(tree_pos, false)

	vills[0].global_position = tree_pos + Vector3(-1.6, 0, 1.4)
	vills[1].global_position = tree_pos + Vector3(1.2, 0, 1.2)

	# A) select villager 0, then tap villager 1 (beside the tree)
	game._handle_3d_click(_tap_point(game, vills[0]), vills[0].global_position)
	_check(game.selected_units.size() == 1 and game.selected_units[0] == vills[0], "Villager 0 selected")
	game._handle_3d_click(_tap_point(game, vills[1]), vills[1].global_position)
	_check(game.selected_units.size() == 1 and game.selected_units[0] == vills[1], "Tap on villager 1 next to tree switches selection")
	_check(vills[0].state != Unit3D.State.GATHERING, "Villager 0 did not receive a gather order")

	# B) tap the tree canopy itself (well away from both villagers) -> gather order
	var tree_screen = game.camera.unproject_position(tree_pos + Vector3(0, 2.4, 0))
	var nearest = game._find_unit_near_screen(tree_screen, 36.0)
	_check(nearest == null, "Tree canopy tap point is not on a unit (test precondition)")
	game._handle_3d_click(tree_screen, tree_pos)
	_check(vills[1].state == Unit3D.State.GATHERING and vills[1].target_cell == best_cell, "Tapping the tree with villager 1 selected issues gather on that tree")

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
