extends SceneTree
## Regression: map generation must never put resource nodes inside / right around a Town Center.
## (Before the fix 7/12 random maps had a gold/stone/berry node inside a TC footprint, which hijacked
## taps on the TC - a cargo villager tapping its TC went gathering - and blocked TC cells.)
## Also checks each base still gets its own gold, stone and food cluster nearby.
const GameController3D = preload("res://scripts/GameController3D.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures := 0
	var maps := 30
	for i in maps:
		seed(5000 + i)
		var scene = load("res://scenes/Main3D.tscn").instantiate()
		root.add_child(scene)
		var game = scene as GameController3D
		game.selected_map_type = CivData.MapType.FOREST_VALLEY if i % 2 == 0 else CivData.MapType.DESERT_OASIS
		game.start_match()
		var mg = game.map_gen
		var problems := []
		for start in [mg.player_start_pos, mg.enemy_start_pos]:
			var sc: Vector2i = mg.world_to_cell(start)
			var near := {"gold": false, "stone": false, "food": false}
			for d in [["wood", mg.trees], ["gold", mg.gold_mines], ["stone", mg.stone_mines], ["food", mg.berry_bushes]]:
				for c in d[1].keys():
					var dist: float = Vector2(c).distance_to(Vector2(sc))
					if dist < mg.BASE_KEEPOUT_RADIUS and d[0] != "wood":
						problems.append("%s at %s (%.1f cells from start)" % [d[0], c, dist])
					if dist <= 10.0 and near.has(d[0]):
						near[d[0]] = true
			for k in near.keys():
				if not near[k]:
					problems.append("no %s within 10 cells of start %s" % [k, sc])
		for b in game.buildings:
			for dx in b.grid_size.x:
				for dy in b.grid_size.y:
					var c: Vector2i = b.origin_cell + Vector2i(dx, dy)
					if not mg.get_resource_at_cell(c).is_empty():
						problems.append("resource inside building footprint at %s" % c)
		if problems.is_empty():
			print("[PASS] map %d (type %d)" % [i, game.selected_map_type])
		else:
			failures += 1
			print("[FAIL] map %d (type %d): %s" % [i, game.selected_map_type, str(problems)])
		scene.queue_free()
		await process_frame
	print("RESULT: %s (%d/%d maps failed)" % ["PASS" if failures == 0 else "FAIL", failures, maps])
	quit(0 if failures == 0 else 1)
