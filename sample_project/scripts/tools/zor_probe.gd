extends SceneTree
## Zor vs a passive player (the test_ai_difficulty setup) repeated N times: when the player's Town Center falls.
##   godot --headless --path . --script res://scripts/tools/zor_probe.gd -- [--runs=6] [--fixed_step=1] [--secs=360]
var runs := 6
var fixed_step := false
var secs := 360.0
var chain := false     # --chain=1: like test_ai_difficulty, Kolay (600 s) and Orta (330 s) first in the same scene

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--runs="): runs = int(a.substr(7))
		elif a.begins_with("--fixed_step="): fixed_step = a.substr(13) == "1"
		elif a.begins_with("--secs="): secs = float(a.substr(7))
		elif a.begins_with("--chain="): chain = a.substr(8) == "1"
	call_deferred("_run")

var _last_log := -1

func _run() -> void:
	var times: Array = []
	for r in runs:
		var scene = load("res://scenes/Main3D.tscn").instantiate()
		root.add_child(scene)
		for i in 3:
			await process_frame
		var game = scene
		if chain:
			for pre in [[EnemyAI3D.Difficulty.EASY, 600.0], [EnemyAI3D.Difficulty.NORMAL, 330.0]]:
				seed(910)
				game.ai_difficulty = pre[0]
				game._on_start_game_requested(0, 1, CivData.MapType.HIGHLAND_PLAINS)
				Engine.time_scale = 8.0
				while game.enemy_ai.ai_clock < pre[1] and game.is_game_active:
					await physics_frame
				Engine.time_scale = 1.0
		seed(910)
		game.ai_difficulty = EnemyAI3D.Difficulty.HARD
		game._on_start_game_requested(0, 1, CivData.MapType.HIGHLAND_PLAINS)
		Engine.time_scale = 8.0
		if fixed_step:
			Engine.physics_ticks_per_second = 480
			Engine.max_physics_steps_per_frame = 64
		var first := -1.0
		var base: Vector3 = game.map_gen.player_start_pos
		var lost := -1.0
		while game.enemy_ai.ai_clock < secs:
			await physics_frame
			if not game.is_game_active:
				lost = game.enemy_ai.ai_clock
				break
			if first >= 0 and int(game.enemy_ai.ai_clock) % 20 == 0 and int(game.enemy_ai.ai_clock) != _last_log:
				_last_log = int(game.enemy_ai.ai_clock)
				var tgt := {}
				var tc_hp := -1.0
				for b in game.buildings:
					if is_instance_valid(b) and b.team == 0 and b.building_type == 0:
						tc_hp = b.hp
				for u in game.units:
					if is_instance_valid(u) and u.team == 1 and u.unit_type != Unit3D.UnitType.VILLAGER:
						var t = u.target_entity
						var k: String = "none" if not is_instance_valid(t) else ("TC" if t is Building3D and t.building_type == 0 else (t.get_class() + ("_b%d" % t.building_type if t is Building3D else "_u")))
						k += "/" + Unit3D.State.keys()[u.state]
						tgt[k] = tgt.get(k, 0) + 1
				print("[zor]   t=%d TC hp %.0f, enemy soldiers: %s" % [_last_log, tc_hp, str(tgt)])
			if first < 0:
				for u in game.units:
					if is_instance_valid(u) and u.team == 1 and u.unit_type != Unit3D.UnitType.VILLAGER \
							and Vector2(u.global_position.x - base.x, u.global_position.z - base.z).length() < 16.0:
						first = game.enemy_ai.ai_clock
						break
		var army := 0
		for u in game.units:
			if is_instance_valid(u) and u.team == 1 and u.unit_type != Unit3D.UnitType.VILLAGER:
				army += 1
		print("[zor] run %d fixed_step=%s first at %.0f s, TC lost at %.0f s, enemy army now %d" % [r, str(fixed_step), first, lost, army])
		times.append(lost)
		Engine.time_scale = 1.0
		Engine.physics_ticks_per_second = 60
		Engine.max_physics_steps_per_frame = 8
		scene.queue_free()
		for i in 3:
			await process_frame
	print("[zor] summary fixed_step=%s: %s" % [str(fixed_step), str(times)])
	quit(0)
