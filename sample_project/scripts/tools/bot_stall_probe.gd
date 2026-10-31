extends SceneTree
## Reproducible bot-economy probe: for each seed, generates the map with a fixed global RNG
## seed, runs the same 300 x 1 s simulation as test_bot_300s_simulations.gd, and on a stall
## dumps what every bot villager is doing.
## Usage: godot --headless --path . --script res://scripts/tools/bot_stall_probe.gd -- --civ=9 --seeds=20
const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
var civ := 9
var seeds := 20
var first := 1
func _init():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--civ="): civ = int(a.substr(6))
		elif a.begins_with("--seeds="): seeds = int(a.substr(8))
		elif a.begins_with("--first="): first = int(a.substr(8))
	call_deferred("_run")
func _run():
	var stalls := 0
	for s in range(first, first + seeds):
		seed(s)
		var scene = load("res://scenes/Main3D.tscn").instantiate()
		root.add_child(scene)
		var game = scene as GameController3D
		game.player_civ = CivData.CivType.OTTOMANS
		game.enemy_civ = civ
		game.selected_map_type = CivData.MapType.FOREST_VALLEY if s % 2 == 0 else CivData.MapType.DESERT_OASIS
		game.start_match()
		for t in range(300):
			game.enemy_ai._process(1.0)
			for u in game.units:
				if is_instance_valid(u): u._physics_process(1.0)
			for b in game.buildings:
				if is_instance_valid(b): b._process(1.0)
		var vills = []
		for u in game.get_team_units(1):
			if u.unit_type == Unit3D.UnitType.VILLAGER: vills.append(u)
		var pop = game.get_team_population(1)
		var r = game.team_resources[1]
		var stalled = pop < 8 or vills.size() < 6 or (r["gold"] > 1800 and r["food"] < 50)
		var unfinished := []
		for bb in game.get_team_buildings(1):
			if not bb.is_completed:
				unfinished.append("%s@%s %.0f%%" % [bb.building_type, bb.origin_cell, bb.construction_progress])
		var builders := 0
		for v in vills:
			if v.state == Unit3D.State.BUILDING: builders += 1
		print("seed=%d map=%d pop=%d vills=%d F=%d W=%d G=%d S=%d %s unfinished=%s builders=%d" % [s, game.selected_map_type, pop, vills.size(), r["food"], r["wood"], r["gold"], r["stone"], "STALL" if stalled else "ok", str(unfinished), builders])
		var p_tc_alive := false
		for pb in game.get_team_buildings(0):
			if pb.building_type == 0:
				p_tc_alive = true
		print("    outcome: game_active=%s player_TC_alive=%s" % [game.is_game_active, p_tc_alive])
		if stalled:
			stalls += 1
			var states := {}
			for v in vills:
				var k = "%s/%s" % [Unit3D.State.keys()[v.state], v.resource_type]
				states[k] = states.get(k, 0) + 1
			print("    villager states: ", states)
			for v in vills:
				var tgt = v.target_cell
				var info = game.map_gen.get_resource_at_cell(tgt, v.resource_type) if tgt != Vector2i(-1, -1) else {}
				var dist = v.global_position.distance_to(game.map_gen.cell_to_world(tgt)) if tgt != Vector2i(-1, -1) else -1.0
				print("      vill state=%s res=%s carried=%d target=%s target_amount=%s dist=%.1f path=%d/%d" % [Unit3D.State.keys()[v.state], v.resource_type, v.carried_resource, str(tgt), str(info.get("amount", "-")), dist, v.path_idx, v.current_path.size()])
			var food_bldgs = []
			for b in game.get_team_buildings(1):
				food_bldgs.append("%s%s" % [b.building_type, "" if b.is_completed else "(uc %.0f%%)" % b.construction_progress])
			print("      bot buildings: ", food_bldgs, "  berries left: ", game.map_gen.berry_bushes.size())
		scene.queue_free()
		await process_frame
	print("STALLS: %d / %d" % [stalls, seeds])
	quit()
