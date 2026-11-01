extends SceneTree
## Production / research queue above the bottom panel (ProductionQueueBar), taps through the real
## input pipeline:
##  * hidden while the selected building has nothing in production
##  * one square slot per queued unit with its picture; the first one has a progress ring that fills
##    and a countdown that goes down while the game runs (no re-selecting needed); waiting units are
##    numbered
##  * units and research share ONE queue: an upgrade asked for after villagers waits behind them,
##    jobs finish one at a time in the order asked (never an upgrade and a villager together)
##  * the line on top says what is made, how long it still takes and how many wait
##  * tapping a slot cancels that job and gives its resources back (units and research)
##  * not shown for enemy buildings, units or resources, nor while the build panel is open
##  * disabled panel buttons ("Çağ II gerekli", ...) have readable text (they were blank grey boxes)
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

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _physics(n: int) -> void:
	for i in n:
		await physics_frame

func _tap(c: Control) -> void:
	var pos: Vector2 = root.get_final_transform() * c.get_global_rect().get_center()
	var d := InputEventMouseButton.new()
	d.button_index = MOUSE_BUTTON_LEFT
	d.position = pos
	d.global_position = pos
	d.pressed = true
	Input.parse_input_event(d)
	await process_frame
	var u := d.duplicate()
	u.pressed = false
	Input.parse_input_event(u)
	await _frames(3)

func _run() -> void:
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var game = scene as GameController3D
	seed(21)
	game._on_start_game_requested(0, 1, 0)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	game.enemy_ai.set_process(false)
	var ui = game.ui_manager
	var bar: ProductionQueueBar = ui.queue_bar
	game.team_resources[0] = {"food": 3000, "wood": 3000, "gold": 3000, "stone": 3000}
	var tc = null
	var etc = null
	for b in game.buildings:
		if b.building_type == Building3D.BuildingType.TOWN_CENTER:
			if b.team == 0: tc = b
			else: etc = b
	game.selected_building = tc
	ui.set_selected_entity(tc)
	await _frames(3)
	_check(bar != null and not bar.visible, "nothing in production: no queue bar")

	# --- three villagers
	for i in 3:
		game.try_train_unit(tc, Unit3D.UnitType.VILLAGER, 0)
	await _frames(2)
	_check(bar.visible and bar.is_visible_in_tree(), "training: the queue bar shows up without re-selecting the building")
	_check(bar._slots.size() == 3 and bar._slots.all(func(s): return s["kind"] == "train"), "one slot per queued villager (%d)" % bar._slots.size())
	var first = bar._slots[0]
	_check(first["ring"].visible and not bar._slots[1]["ring"].visible and bar._slots[1]["time"].text == "2" and bar._slots[2]["time"].text == "3",
		"first slot has the ring, the waiting ones are numbered 2, 3")
	var icon: TextureRect = first["button"].get_child(0)
	_check(icon.texture != null, "slots show the unit's picture")
	_check(bar.global_position.y + bar.size.y <= ui.bottom_bar.global_position.y + 1.0, "the bar sits above the bottom panel")
	var p0: float = first["ring"].progress
	var t0: String = first["time"].text
	await _physics(45)
	await _frames(1)
	var p1: float = bar._slots[0]["ring"].progress
	_check(p1 > p0, "the ring fills while the game runs (%.2f -> %.2f)" % [p0, p1])
	_check(int(bar._slots[0]["time"].text.split(" ")[0]) <= int(t0.split(" ")[0]) and bar._slots[0]["time"].text.ends_with("sn"), "countdown in seconds (%s -> %s)" % [t0, bar._slots[0]["time"].text])
	_check(bar.header.text.contains("İşçi eğitiliyor") and bar.header.text.contains("sırada"), "top line: what is made, time left, how many wait (%s)" % bar.header.text.replace("\n", " / "))
	var old_list := false
	for c in ui.action_flow.get_children():
		if c is Label and c.text.contains("ÜRETİM SIRASI"):
			old_list = true
	_check(not old_list, "the old text list in the panel is gone")

	# --- research joins the SAME queue, behind the villagers (it does not run next to them)
	var n_units: int = tc.train_queue.size()
	game.try_start_research(tc, "AGE_2", 0)
	await _frames(2)
	var rs = bar._slots[bar._slots.size() - 1]
	_check(tc.train_queue.size() == n_units + 1 and rs["kind"] == "research" and rs["index"] == n_units and not rs["ring"].visible,
		"an upgrade asked for after the villagers waits at the end of the queue (slot %d)" % (rs["index"] + 1))
	_check(not tc.is_researching and bar.header.text.contains("İşçi eğitiliyor"), "the villager keeps going, the upgrade does not start yet")
	var ui_btn_txt := ""
	ui.set_selected_entity(tc)
	await _frames(1)
	for c in ui.action_flow.get_children():
		if c is Button and c.text.begins_with(TechData.get_tech("AGE_2")["name"]):
			ui_btn_txt = c.text
	_check(ui_btn_txt.contains("Sırada"), "its button in the panel says Sırada (%s)" % ui_btn_txt.replace("\n", " / "))
	_check(not game.try_start_research(tc, "AGE_2", 0), "the same upgrade cannot be queued twice")

	# --- disabled buttons are readable
	var blank := 0
	var n_dis := 0
	for c in ui.action_flow.get_children():
		if c is Button and c.disabled:
			n_dis += 1
			if not c.has_theme_color_override("font_disabled_color") or c.get_theme_color("font_disabled_color").a < 0.9 or c.text.strip_edges() == "":
				blank += 1
	_check(n_dis > 0 and blank == 0, "disabled panel buttons have readable text (%d buttons)" % n_dis)


	# --- tap a waiting villager: cancelled, food back, order kept
	var food_before: int = game.team_resources[0]["food"]
	var n_before: int = tc.train_queue.size()
	await _tap(bar._slots[1]["button"])
	await _frames(2)
	_check(tc.train_queue.size() == n_before - 1 and game.team_resources[0]["food"] == food_before + 50, "tapping a waiting villager cancels it, 50 food back (%d -> %d)" % [food_before, game.team_resources[0]["food"]])
	_check(tc.train_queue[tc.train_queue.size() - 1].get("kind") == "research", "the upgrade is still last in line")

	# --- tap the waiting upgrade: cancelled, its cost back
	var gold_before: int = game.team_resources[0]["gold"]
	var food2: int = game.team_resources[0]["food"]
	await _tap(bar._slots[bar._slots.size() - 1]["button"])
	await _frames(2)
	_check(not tc.has_queued_research() and game.team_resources[0]["gold"] == gold_before + 200 and game.team_resources[0]["food"] == food2 + 500,
		"tapping the waiting upgrade cancels it, 500 food + 200 gold back")
	_check(bar._slots.all(func(s): return s["kind"] == "train"), "its slot is gone")

	# --- one job at a time, in the order asked: villager, upgrade, villager
	for i in tc.train_queue.size():
		game.cancel_unit_production(tc, 0)
	var events: Array = []
	var clock := [0.0]
	tc.unit_trained.connect(func(_t, _team, _p): events.append(["unit", clock[0]]))
	tc.research_completed.connect(func(id, _team): events.append([id, clock[0]]))
	game.try_train_unit(tc, Unit3D.UnitType.VILLAGER, 0)
	game.try_start_research(tc, "tc_fortify" if game.team_age[0] >= 2 else "AGE_2", 0)
	game.try_train_unit(tc, Unit3D.UnitType.VILLAGER, 0)
	var r_time: float = tc.train_queue[1]["duration"]
	var both_running := false
	var r_count: Array = []
	Engine.time_scale = 4.0
	while not tc.train_queue.is_empty() and clock[0] < 120.0:
		await physics_frame
		clock[0] += 1.0 / Engine.physics_ticks_per_second * Engine.time_scale
		if tc.is_researching and tc.train_queue[0].get("kind") != "research":
			both_running = true
		# read the running upgrade's countdown 1 s and 4 s into it
		if tc.is_researching and r_count.size() < 2 and tc.current_train_timer > (1.0 if r_count.is_empty() else 4.0):
			await process_frame
			r_count.append([tc.current_train_timer, int(bar._slots[0]["time"].text.split(" ")[0])])
	Engine.time_scale = 1.0
	var kinds: Array = events.map(func(e): return "unit" if e[0] == "unit" else "research")
	print("  events: ", events)
	_check(kinds == ["unit", "research", "unit"], "jobs finish one by one in the order asked: %s" % str(kinds))
	_check(events.size() == 3 and events[1][1] - events[0][1] >= r_time * 0.95 and events[2][1] - events[1][1] > 1.0,
		"the upgrade starts only after the first villager, the next villager only after the upgrade (finished at %.1f / %.1f / %.1f s)" % [events[0][1] if events.size() > 0 else -1.0, events[1][1] if events.size() > 1 else -1.0, events[2][1] if events.size() > 2 else -1.0])
	_check(not both_running, "never a research running next to a unit")
	_check(r_count.size() == 2 and r_count[1][1] < r_count[0][1], "the running upgrade shows its countdown going down (%s)" % str(r_count))

	# --- not for others / build panel
	ui.build_panel.visible = true
	await _frames(2)
	_check(not bar.visible, "hidden while the build panel is open")
	ui.build_panel.visible = false
	game.try_train_unit(etc, Unit3D.UnitType.VILLAGER, 1)
	ui.set_selected_entity(etc)
	await _frames(2)
	_check(not bar.visible, "not shown for an enemy building's production")
	var v = null
	for u in game.units:
		if u.team == 0:
			v = u
	ui.set_selected_entity(v)
	await _frames(2)
	_check(not bar.visible, "not shown when a unit is selected")

	# --- the queue runs out: bar goes away by itself
	ui.set_selected_entity(tc)
	game.try_train_unit(tc, Unit3D.UnitType.VILLAGER, 0)
	game.try_train_unit(tc, Unit3D.UnitType.VILLAGER, 0)
	await _frames(2)
	_check(bar.visible, "bar back for new villagers")
	var n: int = tc.train_queue.size()
	for k in 900:
		await physics_frame
		if tc.train_queue.is_empty():
			break
	await _frames(2)
	_check(tc.train_queue.is_empty() and not bar.visible, "when the last unit is out, the bar disappears (%d trained)" % n)

	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
