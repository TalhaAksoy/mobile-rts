extends SceneTree
## Regression: on dense Forest Valley maps the bot built a house across the mouth of a berry pocket.
## The ring check measured from the worker, who stood inside the future house, so 7-10 villagers were
## trapped carrying food for the rest of the match. Later builders were picked from the trapped
## villagers, so no site was reachable and the bot never got a barracks: 0 soldiers in 8 minutes with
## 2,600+ wood (seed 900).
## Now: against a passive player on several Forest Valley seeds (Orta), the bot
##  * builds an army
##  * never seals its own villagers away from its Town Center (every villager can walk home)
##  * keeps its food coming in (no villager stuck carrying food for minutes)
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

## A walkable cell right next to the bot's Town Center (computed here, independent of the bot code).
func _home(mg, tc) -> Vector2i:
	for r in range(1, 4):
		for x in range(tc.origin_cell.x - r, tc.origin_cell.x + tc.grid_size.x + r):
			for y in range(tc.origin_cell.y - r, tc.origin_cell.y + tc.grid_size.y + r):
				var c := Vector2i(x, y)
				if mg.is_valid_cell(x, y) and mg.is_cell_walkable(c) and not mg.berry_bushes.has(c):
					return c
	return mg.world_to_cell(tc.global_position)

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var game = scene as GameController3D
	for sd in [900, 905, 911]:
		seed(sd)
		game.ai_difficulty = EnemyAI3D.Difficulty.NORMAL
		game._on_start_game_requested(0, 1, CivData.MapType.FOREST_VALLEY)
		if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
			game.tutorial_mgr.stop_tutorial()
		for u in game.units:
			if u.team == 0:
				u.set_physics_process(false)     # passive player
		var mg = game.map_gen
		var ai = game.enemy_ai
		Engine.time_scale = 8.0
		var max_army := 0
		var sealed_max := 0
		var food_carry_since := {}       # villager -> game time it started carrying food home
		var longest_carry := 0.0
		var next_check := 30.0
		while ai.ai_clock < 360.0 and game.is_game_active:
			await physics_frame
			var army := 0
			for u in game.units:
				if not is_instance_valid(u) or u.team != 1:
					continue
				if u.unit_type != Unit3D.UnitType.VILLAGER:
					army += 1
				elif u.state == Unit3D.State.RETURNING_RESOURCES and u.resource_type == "food":
					if not food_carry_since.has(u):
						food_carry_since[u] = ai.ai_clock
					longest_carry = maxf(longest_carry, ai.ai_clock - food_carry_since[u])
				else:
					food_carry_since.erase(u)
			max_army = maxi(max_army, army)
			if ai.ai_clock >= next_check:
				next_check += 30.0
				var tc = null
				for b in game.buildings:
					if is_instance_valid(b) and b.team == 1 and b.building_type == Building3D.BuildingType.TOWN_CENTER:
						tc = b
				if tc == null:
					continue
				var home: Vector2i = _home(mg, tc)
				var sealed := 0
				for u in game.units:
					if is_instance_valid(u) and u.team == 1 and u.unit_type == Unit3D.UnitType.VILLAGER and u.state != Unit3D.State.BUILDING:
						var path: Array = mg.get_path_to_target(u.global_position, mg.cell_to_world(home))
						var vc: Vector2i = mg.world_to_cell(u.global_position)
						if vc != home and (path.is_empty() or Vector2(mg.world_to_cell(path[path.size() - 1])).distance_to(Vector2(home)) > 1.5):
							sealed += 1
				sealed_max = maxi(sealed_max, sealed)
		Engine.time_scale = 1.0
		_check(max_army >= 5, "seed %d: the bot builds an army (%d soldiers within 6 min)" % [sd, max_army])
		_check(sealed_max == 0, "seed %d: no bot villager is sealed away from its Town Center (worst check: %d)" % [sd, sealed_max])
		_check(longest_carry < 60.0, "seed %d: no villager carries food home for a minute or more (longest %.0f s)" % [sd, longest_carry])
	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
