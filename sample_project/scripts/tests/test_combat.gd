extends SceneTree
## Real combat simulation on the actual Main3D scene (no mocks):
##  1. Spearman vs enemy Cavalry: the counter bonus (x2.5) is applied per hit and the fight resolves.
##  2. Archer vs enemy Villager: a projectile is spawned, travels, and kills the target.
##  3. Swordsman vs enemy building: the building takes damage (armor applied).

const GameController3D = preload("res://scripts/GameController3D.gd")
const Unit3D = preload("res://scripts/Unit3D.gd")
const Building3D = preload("res://scripts/Building3D.gd")

var failures := 0
var game: GameController3D

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _simulate(seconds: float, stop_cond: Callable = Callable()) -> float:
	var t := 0.0
	while t < seconds:
		await physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		if stop_cond.is_valid() and stop_cond.call():
			break
	return t

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	game = scene as GameController3D
	game.start_match()
	# Isolate the duel from bot decisions and tower fire.
	game.enemy_ai.set_process(false)
	game.enemy_ai.set_physics_process(false)

	var arena: Vector3 = game.map_gen.player_start_pos + Vector3(0, 0, 9.0)

	# --- 1. Spearman vs Cavalry ---------------------------------------------------
	var spear: Unit3D = game.spawn_unit(Unit3D.UnitType.SPEARMAN, 0, arena)
	var cav: Unit3D = game.spawn_unit(Unit3D.UnitType.CAVALRY, 1, arena + Vector3(1.0, 0, 0))
	await physics_frame
	var cav_hp0 := cav.hp
	var expected_hit: float = max(1.0, spear.attack_dmg * 2.5 - cav.armor)
	spear.attack_timer = 0.0
	spear.command_attack(cav)
	cav.command_attack(spear)
	var cav_ref = weakref(cav)
	var spear_ref = weakref(spear)
	await _simulate(0.3, func(): return cav_ref.get_ref() == null or cav_ref.get_ref().hp < cav_hp0)
	_check(cav.hp < cav_hp0, "Spearman damaged cavalry")
	_check(absf((cav_hp0 - cav.hp) - expected_hit) < 0.01, "First spear hit = %.1f (expected counter-bonus hit %.1f)" % [cav_hp0 - cav.hp, expected_hit])
	await _simulate(40.0, func(): return cav_ref.get_ref() == null or spear_ref.get_ref() == null)
	_check(not is_instance_valid(cav) or not is_instance_valid(spear), "Spear-vs-cavalry duel resolved (one unit died)")
	_check(is_instance_valid(spear) and not is_instance_valid(cav), "Spearman (counter unit) wins vs cavalry")

	# --- 2. Archer vs Villager (projectiles) --------------------------------------
	var archer: Unit3D = game.spawn_unit(Unit3D.UnitType.ARCHER, 0, arena + Vector3(-4, 0, 2))
	var victim: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 1, arena + Vector3(-4, 0, -2))
	await physics_frame
	victim.set_physics_process(false) # stand still
	var units_before := game.units.size()
	archer.command_attack(victim)
	var proj_seen := false
	var t := 0.0
	while t < 30.0 and is_instance_valid(victim):
		await physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		for c in game.get_children():
			if c.get_script() != null and str(c.get_script().resource_path).ends_with("Projectile3D.gd"):
				proj_seen = true
	_check(proj_seen, "Archer spawned a projectile")
	_check(not is_instance_valid(victim), "Archer killed the villager in %.1fs" % t)
	_check(game.units.size() < units_before, "Dead unit removed from game.units")

	# --- 3. Swordsman vs enemy building --------------------------------------------
	var enemy_tc: Building3D = null
	for b in game.buildings:
		if b.team == 1:
			enemy_tc = b
	var sword: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, enemy_tc.global_position + Vector3(0, 0, 4.0))
	enemy_tc.set_process(false) # disable TC arrows so the swordsman survives
	await physics_frame
	var b_hp0 := enemy_tc.hp
	sword.command_attack(enemy_tc)
	await _simulate(15.0, func(): return enemy_tc.hp < b_hp0)
	_check(enemy_tc.hp < b_hp0, "Swordsman damaged enemy Town Center (%.0f -> %.0f)" % [b_hp0, enemy_tc.hp])

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
