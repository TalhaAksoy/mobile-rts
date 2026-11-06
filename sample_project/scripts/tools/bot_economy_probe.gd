extends SceneTree
## Bot economy over a whole match (headless is fine): every game minute, per bot, the age, the stockpile and
## what the villagers are doing (food / wood / gold / stone / building / idle), plus when each age was reached.
##   godot --headless --path . --script res://scripts/tools/bot_economy_probe.gd -- [--minutes=20] [--diff=1]
##       [--bots=2] [--size=1] [--seed=3] [--speed=8]

const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")
var minutes := 20.0
var diff := 1
var bots := 2
var size := 1
var map_seed := 3
var speed := 8.0

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="): minutes = float(a.substr(10))
		elif a.begins_with("--diff="): diff = int(a.substr(7))
		elif a.begins_with("--bots="): bots = int(a.substr(7))
		elif a.begins_with("--size="): size = int(a.substr(7))
		elif a.begins_with("--seed="): map_seed = int(a.substr(7))
		elif a.begins_with("--speed="): speed = float(a.substr(8))
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	for i in 3:
		await process_frame
	var game = scene
	seed(map_seed)
	game.map_size = size
	game.bot_count = bots
	game.ai_difficulty = diff
	game._on_start_game_requested(0, 1, CivData.MapType.FOREST_VALLEY)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	# the player's side is a bot too, so every side plays
	var pilot := EnemyAI3D.new()
	pilot.name = "PlayerPilot"
	game.add_child(pilot)
	pilot.setup_ai(game.player_civ, game.map_gen, game, diff, 0)
	Engine.time_scale = speed
	# keep the simulation step as in a real match (1/60 s): more physics ticks instead of longer ones
	Engine.physics_ticks_per_second = int(60 * speed)
	Engine.max_physics_steps_per_frame = int(8 * speed)
	var reached := {}
	var last_carry := {}
	var picked := 0
	var dropped := 0
	var tally := {}
	var last_job := {}
	var switches := 0
	var regather := 0
	var last_target := {}
	var t := 0.0
	var next_log := 60.0
	while t < minutes * 60.0 and game.is_game_active:
		await process_frame
		t += root.get_process_delta_time()          # already scaled by Engine.time_scale
		for u in game.units:
			if is_instance_valid(u) and u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
				var key: String = Unit3D.State.keys()[u.state]
				if u.state == Unit3D.State.GATHERING:
					var tp: Vector3 = game.map_gen.cell_to_world(u.target_cell)
					key += "_swing" if u.swing_progress > 0.0 or u.attack_timer > 0.0 and Vector2(u.global_position.x - tp.x, u.global_position.z - tp.z).length() < 2.2 else "_walk"
				tally[key] = tally.get(key, 0) + 1
				var id: int = u.get_instance_id()
				var cr: int = u.carried_resource
				if last_carry.has(id):
					if cr > last_carry[id]: picked += cr - last_carry[id]
					elif cr < last_carry[id]: dropped += last_carry[id] - cr
				last_carry[id] = cr
				if last_job.has(id) and last_job[id] != u.resource_type and u.state != Unit3D.State.BUILDING:
					switches += 1
				last_job[id] = u.resource_type
				if last_target.has(id) and last_target[id] != u.target_cell:
					regather += 1
				last_target[id] = u.target_cell
		for team in range(0, bots + 1):
			var age := int(game.team_age.get(team, 1))
			var k := "%d_%d" % [team, age]
			if age > 1 and not reached.has(k):
				reached[k] = t
				print("[eco] %5.1f min  team %d reached age %d" % [t / 60.0, team, age])
		if t >= next_log:
			next_log += 60.0
			for team in range(0, bots + 1):
				var res: Dictionary = game.team_resources.get(team, {})
				var jobs := {"food": 0, "wood": 0, "gold": 0, "stone": 0, "build": 0, "idle": 0, "other": 0}
				var mil := 0
				for u in game.units:
					if not is_instance_valid(u) or u.team != team or u.hp <= 0:
						continue
					if u.unit_type != Unit3D.UnitType.VILLAGER:
						mil += 1
						continue
					match u.state:
						Unit3D.State.IDLE: jobs["idle"] += 1
						Unit3D.State.BUILDING: jobs["build"] += 1
						_:
							var r: String = u.resource_type
							jobs[r if jobs.has(r) else "other"] += 1
				if team == 0:
					var st := {}
					var srcs := {}
					for u in game.units:
						if is_instance_valid(u) and u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER and u.resource_type == "food":
							var sn: String = Unit3D.State.keys()[u.state]
							st[sn] = st.get(sn, 0) + 1
							var src := "field" if game.map_gen.field_origin_at(u.target_cell) != Vector2i(-1, -1) else ("berry" if game.map_gen.berry_bushes.has(u.target_cell) else "other")
							srcs[src] = srcs.get(src, 0) + 1
					var dists: Array = []
					for u in game.units:
						if is_instance_valid(u) and u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER and u.resource_type == "food":
							var best := INF
							for bb in game.buildings:
								if is_instance_valid(bb) and bb.team == 0 and bb.is_completed and bb.building_type in [0, 11]:
									best = minf(best, bb.global_position.distance_to(game.map_gen.cell_to_world(u.target_cell)))
							dists.append(snappedf(best, 1))
					var mills: int = game.buildings.filter(func(bb): return is_instance_valid(bb) and bb.team == 0 and bb.building_type == 11).size()
					var fields: int = game.buildings.filter(func(bb): return is_instance_valid(bb) and bb.team == 0 and bb.building_type == 7).size()
					var tot := 0
					for k in tally: tot += tally[k]
					var pct := {}
					for k in tally: pct[k] = "%d%%" % int(100.0 * tally[k] / maxf(tot, 1))
					print("[eco]        team 0 villager time: %s | picked %d dropped %d per min" % [str(pct), picked, dropped])
					picked = 0
					dropped = 0
					tally.clear()
					print("[eco]        team 0 job switches %d, target changes %d (last minute)" % [switches, regather])
					switches = 0
					regather = 0
					print("[eco]        food crew states %s sources %s | drop-off dist %s | mills %d fields %d | gathered total %d" % [str(st), str(srcs), str(dists), mills, fields, game.gathered_count])
				var bl := {}
				for bb in game.buildings:
					if is_instance_valid(bb) and bb.team == team:
						var nm: String = Building3D.BuildingType.keys()[bb.building_type] + ("" if bb.is_completed else "*")
						bl[nm] = bl.get(nm, 0) + 1
				print("[eco]        team %d buildings %s" % [team, str(bl)])
				print("[eco] %5.1f min  team %d age %d | F %4d W %4d G %4d S %4d | vill f%d w%d g%d s%d b%d i%d o%d | army %d" % [
					t / 60.0, team, int(game.team_age.get(team, 1)), int(res.get("food", 0)), int(res.get("wood", 0)),
					int(res.get("gold", 0)), int(res.get("stone", 0)), jobs["food"], jobs["wood"], jobs["gold"], jobs["stone"],
					jobs["build"], jobs["idle"], jobs["other"], mil])
	print("[eco] end at %.1f min, active=%s" % [t / 60.0, str(game.is_game_active)])
	Engine.time_scale = 1.0
	quit(0)
