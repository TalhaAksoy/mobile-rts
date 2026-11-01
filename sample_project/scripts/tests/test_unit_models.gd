extends SceneTree
## 3D units (art_source/blender/units) and the 2D sheets rendered from them:
##  * every unit in the manifest: a GLB with a skeleton and the six animations (idle / walk / gather / build
##    looping; attack / death once), feet on the ground, sensible height, triangle budget, only the shared
##    palette + team materials
##  * in the 3D style a unit shows its model (no sprite) and the animation follows what it does: idle, walk,
##    attack (restarted on every swing), gather, build; a villager's log bundle shows only while it carries wood;
##    team colour on the sash; on death the model stays behind for the death animation, then goes away
##  * in the 2D style the same unit shows its sheet (team-coloured), the frame advances while walking and it
##    mirrors to the walking side; on death the sprite plays the death row and fades
##  * a civ without models yet keeps its gallery sprite in both styles
const GameController3D = preload("res://scripts/GameController3D.gd")

var failures := 0
var checks := 0
var game

func _check(cond: bool, msg: String) -> void:
	checks += 1
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _init() -> void:
	call_deferred("_run")

func _physics(n: int) -> void:
	for i in n:
		await physics_frame

func _villager_spot() -> Vector3:
	return game.map_gen.player_start_pos + Vector3(0, 0, -12)

func _run() -> void:
	# ---- every model in the manifest
	var man = JSON.parse_string(FileAccess.get_file_as_string("res://data/art/unit_model_manifest.json"))
	var n_models := 0
	for civ in man["units"]:
		for role in man["units"][civ]:
			n_models += 1
			var e: Dictionary = man["units"][civ][role]
			var tag := "%s/%s" % [civ, role]
			var ps: PackedScene = load(e["model"])
			_check(ps != null, tag + ": GLB loads")
			if ps == null:
				continue
			var inst: Node3D = ps.instantiate()
			root.add_child(inst)
			var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
			var ok_anims := ap != null
			if ap != null:
				for a in ["idle", "walk", "gather", "build"]:
					ok_anims = ok_anims and ap.has_animation(a) and ap.get_animation(a).loop_mode != Animation.LOOP_NONE
				for a in ["attack", "death"]:
					ok_anims = ok_anims and ap.has_animation(a) and ap.get_animation(a).loop_mode == Animation.LOOP_NONE
			_check(ok_anims and inst.find_children("*", "Skeleton3D", true, false).size() == 1, tag + ": skeleton + idle/walk/gather/build loops, attack/death once")
			var box: AABB = FactionArtManager.compute_visual_aabb(inst)
			var mounted: bool = e.get("mount", "") != ""
			var hi_ok: bool = (box.end.y > 2.3 and box.end.y < 3.5) if mounted else (box.end.y > 1.5 and box.end.y < 2.4)
			_check(absf(box.position.y) < 0.05 and hi_ok, tag + ": feet / hooves on the ground, %.2f m tall%s" % [box.end.y, " (mounted)" if mounted else ""])
			var tris := 0
			var mats := {}
			for mi in inst.find_children("*", "MeshInstance3D", true, false):
				for si in mi.mesh.get_surface_count():
					tris += mi.mesh.surface_get_array_index_len(si) / 3
					var m = mi.mesh.surface_get_material(si)
					mats[m.resource_name if m != null else "?"] = true
			_check(tris <= (2400 if mounted else 1600) and mats.keys().all(func(k): return k in ["PE_UnitPalette", "TEAM_Trim"]), tag + ": %d tris, materials %s" % [tris, str(mats.keys())])
			inst.free()
	_check(n_models >= 56, "manifest lists %d unit models" % n_models)
	# every civ: the gallery's five roles
	var gallery_unique := {"ottomans": "janissary", "byzantines": "cataphract", "britons": "longbowman", "franks": "knight",
		"mongols": "horse_archer", "teutons": "teutonic_knight", "japanese": "samurai", "saracens": "mamluk",
		"vikings": "berserker", "chinese": "chu_ko_nu"}
	var missing := []
	for civ in gallery_unique:
		for role in ["villager", "swordsman", "spearman", "archer", gallery_unique[civ]]:
			if not man["units"].get(civ, {}).has(role):
				missing.append("%s/%s" % [civ, role])
	_check(missing.is_empty(), "all 10 civs have the gallery's five roles %s" % str(missing))
	# game unit types -> models: mounted types find a mounted model in every civ
	var mounted_bad := []
	for civ in CivData.CIVS.keys():
		for t in [Unit3D.UnitType.CAVALRY, Unit3D.UnitType.PALADIN]:
			var e := FactionArtManager.get_unit_model_entry(civ, t)
			if e.get("mount", "") == "":
				mounted_bad.append("%s %s" % [FactionArtManager.get_faction_id_from_civ(civ), Unit3D.UnitType.keys()[t]])
	_check(mounted_bad.is_empty(), "cavalry and knights are mounted in every civ %s" % str(mounted_bad))
	_check(FactionArtManager.get_unit_model_entry(CivData.CivType.BYZANTINES, Unit3D.UnitType.CAVALRY)["model"].ends_with("cataphract.glb")
		and FactionArtManager.get_unit_model_entry(CivData.CivType.FRANKS, Unit3D.UnitType.PALADIN)["model"].ends_with("knight.glb")
		and FactionArtManager.get_unit_model_entry(CivData.CivType.SARACENS, Unit3D.UnitType.MAMELUKE)["mount"] == "camel"
		and FactionArtManager.get_unit_model_entry(CivData.CivType.OTTOMANS, Unit3D.UnitType.CAVALRY)["model"].ends_with("ottomans/cavalry.glb"),
		"civ cavalry: cataphract / knight / mamluk on a camel; the Ottoman sipahi for generic cavalry")

	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	game = scene as GameController3D

	# ---- 3D style
	FactionArtManager.use_3d_building_models = true
	seed(3)
	game._on_start_game_requested(CivData.CivType.OTTOMANS, CivData.CivType.OTTOMANS, CivData.MapType.FOREST_VALLEY)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	game.enemy_ai.set_process(false)
	var v: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, _villager_spot())
	_check(v.unit_model != null and v.unit_anim != null and not is_instance_valid(v.unit_sprite), "3D: villager shows its model, no sprite")
	await _physics(3)
	_check(v.unit_anim.current_animation == "idle", "3D: standing -> idle (%s)" % v.unit_anim.current_animation)
	v.command_move(v.global_position + Vector3(6, 0, 0))
	await _physics(10)
	_check(v.unit_anim.current_animation == "walk", "3D: moving -> walk (%s)" % v.unit_anim.current_animation)
	var cargo = v._cargo_props.get("wood")
	_check(cargo != null and not cargo.visible, "3D: no log bundle on an empty villager")
	v.resource_type = "wood"
	v.carried_resource = 10
	await _physics(2)
	_check(cargo != null and cargo.visible, "3D: log bundle on the back while carrying wood")
	v.carried_resource = 0
	v.command_stop()
	v.velocity = Vector3.ZERO
	v.current_path.clear()
	v.state = Unit3D.State.GATHERING
	v.target_cell = Vector2i(-1, -1)
	v.set_physics_process(false)
	v._update_model_animation()
	_check(v.unit_anim.current_animation == "gather", "3D: gathering -> gather (%s)" % v.unit_anim.current_animation)
	v.state = Unit3D.State.BUILDING
	v._update_model_animation()
	_check(v.unit_anim.current_animation == "build", "3D: building -> build (%s)" % v.unit_anim.current_animation)
	v.set_physics_process(true)
	v.command_stop()

	# team colour on the sash (TEAM_Trim surface) for both teams
	var sw0: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 0, _villager_spot() + Vector3(0, 0, -3))
	var sw1: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 1, _villager_spot() + Vector3(1.2, 0, -3))
	var team_cols := []
	for u in [sw0, sw1]:
		var c = null
		for mi in u.unit_model.find_children("*", "MeshInstance3D", true, false):
			for si in mi.mesh.get_surface_count():
				var m = mi.get_surface_override_material(si)
				if m != null and String(m.resource_name).begins_with("TEAM_"):
					c = m.albedo_color
		team_cols.append(c)
	_check(team_cols[0] == FactionArtManager.TEAM_COLORS[0] and team_cols[1] == FactionArtManager.TEAM_COLORS[1], "3D: sash in the team colour (%s / %s)" % [team_cols[0], team_cols[1]])
	# attack restarts on every swing
	sw0.command_attack(sw1)
	var swings := 0
	var last_pos := 9.0
	for k in 240:
		await physics_frame
		if sw0.unit_anim.current_animation == "attack" and sw0.unit_anim.current_animation_position < last_pos - 0.2:
			swings += 1
		last_pos = sw0.unit_anim.current_animation_position if sw0.unit_anim.current_animation == "attack" else 9.0
		if not is_instance_valid(sw1) or sw1.hp <= 0:
			break
	_check(swings >= 2, "3D: every swing plays the attack animation (%d swings seen)" % swings)
	# death leaves the model behind for the death animation
	var dead: Unit3D = game.spawn_unit(Unit3D.UnitType.SPEARMAN, 1, _villager_spot() + Vector3(-3, 0, -3))
	var model := dead.unit_model
	var ap: AnimationPlayer = dead.unit_anim
	dead.die()
	await process_frame
	_check(is_instance_valid(model) and model.get_parent() == game and ap.current_animation == "death", "3D: the dead unit's model stays for the death animation")
	for k in 300:
		await physics_frame
		if not is_instance_valid(model):
			break
	_check(not is_instance_valid(model), "3D: and is removed a few seconds later")
	# a role without a model (taken out of the loaded manifest for this check) falls back to the gallery sprite
	var saved: Dictionary = FactionArtManager._unit_manifest["ottomans"].duplicate()
	FactionArtManager._unit_manifest["ottomans"].erase("archer")
	FactionArtManager._unit_manifest["ottomans"].erase("swordsman")
	var bare: Unit3D = game.spawn_unit(Unit3D.UnitType.ARCHER, 0, _villager_spot() + Vector3(5, 0, -6))
	FactionArtManager._unit_manifest["ottomans"] = saved
	_check(bare.unit_model == null and is_instance_valid(bare.unit_sprite), "3D: a unit without a model keeps its gallery sprite")
	# mounted model: taller, so the HP bar is lifted and the ring is wider
	var cav: Unit3D = game.spawn_unit(Unit3D.UnitType.CAVALRY, 0, _villager_spot() + Vector3(-5, 0, -6))
	var foot: Unit3D = sw0
	_check(cav.unit_model != null and cav.hp_bar_mesh.get_parent().position.y > foot.hp_bar_mesh.get_parent().position.y + 0.5
		and (cav.selection_ring.mesh as TorusMesh).outer_radius > (foot.selection_ring.mesh as TorusMesh).outer_radius,
		"3D: a mounted unit gets a higher HP bar and a wider ring")

	# ---- 2D style
	FactionArtManager.use_3d_building_models = false
	var v2: Unit3D = game.spawn_unit(Unit3D.UnitType.VILLAGER, 0, _villager_spot() + Vector3(0, 0, 3))
	var e2: Dictionary = FactionArtManager.get_unit_sheet_entry(CivData.CivType.OTTOMANS, Unit3D.UnitType.VILLAGER)
	_check(v2.unit_model == null and not v2.sheet.is_empty() and String(v2.unit_sprite.texture.resource_path) == e2["t0"], "2D: villager shows its sheet (team 0)")
	var s1: Unit3D = game.spawn_unit(Unit3D.UnitType.SWORDSMAN, 1, _villager_spot() + Vector3(3, 0, 3))
	_check(String(s1.unit_sprite.texture.resource_path).ends_with("swordsman_t1.png"), "2D: enemy uses the team-1 sheet")
	# occlusion tint: only behind other geometry (inverted depth) and never over a unit sprite (stencil),
	# drawn with the sheet's alpha - an always-on-top copy used to tint every visible sprite
	var sm := v2.unit_sprite.material_override as StandardMaterial3D
	var xr := (sm.next_pass as StandardMaterial3D) if sm != null else null
	_check(sm != null and sm.stencil_flags & BaseMaterial3D.STENCIL_FLAG_WRITE != 0 and sm.albedo_texture == v2.unit_sprite.texture
		and xr != null and xr.depth_test == BaseMaterial3D.DEPTH_TEST_INVERTED and xr.stencil_compare == BaseMaterial3D.STENCIL_COMPARE_NOT_EQUAL
		and xr.stencil_reference == sm.stencil_reference and xr.albedo_texture == v2.unit_sprite.texture
		and xr.albedo_color.b > xr.albedo_color.r, "2D: occlusion tint only behind buildings, team-blue, sprite-shaped")
	var xr1 := (s1.unit_sprite.material_override as StandardMaterial3D).next_pass as StandardMaterial3D
	_check(xr1.albedo_color.r > xr1.albedo_color.b, "2D: enemy occlusion tint is red")
	v2.command_move(v2.global_position + Vector3(7, 0, 0))
	var frames := {}
	for k in 40:
		await physics_frame
		frames[v2.unit_sprite.frame] = true
	var walk_row: int = int(e2["anims"]["walk"]["row"])
	var in_row := frames.keys().all(func(f): return int(f) / int(e2["hframes"]) == walk_row)
	_check(frames.size() >= 3 and in_row, "2D: walking cycles through the walk row (%d frames)" % frames.size())
	_check(v2.unit_sprite.flip_h, "2D: mirrored while walking to the right")
	var spr := v2.unit_sprite
	v2.die()
	await process_frame
	var death_row: int = int(e2["anims"]["death"]["row"])
	await _physics(20)
	_check(is_instance_valid(spr) and int(spr.frame) / int(e2["hframes"]) == death_row, "2D: the dead unit's sprite plays the death row")
	FactionArtManager.use_3d_building_models = true

	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
