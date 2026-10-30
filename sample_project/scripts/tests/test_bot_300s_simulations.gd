extends SceneTree

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")

func _init() -> void:
	call_deferred("_run_simulations")

func _run_simulations() -> void:
	print("================================================================")
	print("=== RUNNING 10x 300-SECOND BOT AI ECONOMIC STRESS SIMULATIONS ===")
	print("================================================================")

	var all_passed = true
	var results = []

	var civ_types = [
		CivData.CivType.BYZANTINES,
		CivData.CivType.OTTOMANS,
		CivData.CivType.BRITONS,
		CivData.CivType.FRANKS,
		CivData.CivType.MONGOLS,
		CivData.CivType.TEUTONS,
		CivData.CivType.JAPANESE,
		CivData.CivType.SARACENS,
		CivData.CivType.VIKINGS,
		CivData.CivType.CHINESE
	]

	for sim_idx in range(10):
		var enemy_civ = civ_types[sim_idx]
		var map_type = CivData.MapType.FOREST_VALLEY if sim_idx % 2 == 0 else CivData.MapType.DESERT_OASIS
		var seed_val = 1000 + sim_idx * 73

		var scene = load("res://scenes/Main3D.tscn").instantiate()
		root.add_child(scene)
		var game = scene as GameController3D
		game.player_civ = CivData.CivType.OTTOMANS
		game.enemy_civ = enemy_civ
		game.selected_map_type = map_type
		game.start_match()
		game.map_gen.seed_val = seed_val

		# Run 300 seconds of simulation
		# At 1.0s AI ticks, 300 ticks
		var sim_dt = 1.0
		for t in range(300):
			game.enemy_ai._process(sim_dt)
			for u in game.units:
				if is_instance_valid(u):
					u._physics_process(sim_dt)
			for b in game.buildings:
				if is_instance_valid(b):
					b._process(sim_dt)

		var res = game.team_resources[1]
		var enemy_units = game.get_team_units(1)
		var enemy_buildings = game.get_team_buildings(1)
		var vills = 0
		var military = 0
		for u in enemy_units:
			if u.unit_type == Unit3D.UnitType.VILLAGER:
				vills += 1
			else:
				military += 1

		var camps = 0
		for b in enemy_buildings:
			if b.building_type in [Building3D.BuildingType.LUMBER_CAMP, Building3D.BuildingType.MINING_CAMP, Building3D.BuildingType.MILL]:
				camps += 1

		var total_pop = game.get_team_population(1)
		var civ_name = CivData.get_civ(enemy_civ).get("name", "Unknown")

		var status_str = "Sim #%2d [%-11s]: Pop=%2d (Vills:%2d, Mil:%2d) | F=%4d, W=%4d, G=%4d, S=%4d | Camps=%d" % [
			sim_idx + 1,
			civ_name,
			total_pop,
			vills,
			military,
			res["food"],
			res["wood"],
			res["gold"],
			res.get("stone", 0),
			camps
		]
		print(status_str)

		# Validation rules:
		# 1. Total population must grow beyond starting 3 and not be frozen at 7
		var pop_ok = total_pop >= 8
		# 2. Gold must NOT hyper-inflate beyond 1800 while food is 0
		var no_gold_trap = not (res["gold"] > 1800 and res["food"] < 50)
		# 3. Villagers maintained
		var vill_ok = vills >= 6

		if not pop_ok or not no_gold_trap or not vill_ok:
			all_passed = false
			printerr("  -> STALL DETECTED in Sim #%d!" % (sim_idx + 1))
		else:
			print("  -> SUCCESS: Economy balanced and healthy.")

		results.append({
			"sim": sim_idx + 1,
			"civ": civ_name,
			"pop": total_pop,
			"vills": vills,
			"military": military,
			"food": res["food"],
			"wood": res["wood"],
			"gold": res["gold"],
			"stone": res.get("stone", 0),
			"camps": camps
		})

		scene.queue_free()

	print("================================================================")
	if all_passed:
		print("ALL 10x 300-SECOND BOT SIMULATIONS PASSED WITHOUT STALLS!")
	else:
		printerr("SOME SIMULATIONS FAILED CRITERIA.")
	print("================================================================")

	# Write summary log to docs
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("docs/audits/gameplay-review/evidence"):
		dir.make_dir_recursive("docs/audits/gameplay-review/evidence")

	var f = FileAccess.open("res://docs/audits/gameplay-review/evidence/phase1_bot_simulations.txt", FileAccess.WRITE)
	if f != null:
		f.store_line("=== POCKET EMPIRES 3D — 10x 300s BOT SIMULATION LOG ===")
		for r in results:
			f.store_line("Sim #%d [%s]: Pop=%d (V:%d, M:%d) | Food=%d, Wood=%d, Gold=%d, Stone=%d | Camps=%d" % [
				r["sim"], r["civ"], r["pop"], r["vills"], r["military"], r["food"], r["wood"], r["gold"], r["stone"], r["camps"]
			])
		f.close()

	quit(0 if all_passed else 1)
