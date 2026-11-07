extends SceneTree
## Finger scrolling in lists full of buttons (TouchScroll):
##  * a drag that starts ON a button scrolls the list and does not press the button
##    (build menu, the bottom action buttons, the civ list of the main menu)
##  * a tap, also one with a little finger jitter, still presses the button
##  * a drag back down scrolls back, a quick flick glides on a little after letting go
##  * the scroll bar and the gaps between buttons still work (the list's own scrolling)

var game
var checks := 0
var failures := 0

func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
	print("[%s] %s" % ["PASS" if cond else "FAIL", msg])

func _init() -> void:
	call_deferred("_run")

func _frames(n: int) -> void:
	for i in n:
		await process_frame

## Waits (real time: the glide runs on seconds, headless frames are much shorter) until the list stands still.
func _settle(sc: ScrollContainer) -> void:
	var last := -1
	var still := 0
	for k in 300:
		await create_timer(0.02).timeout
		still = still + 1 if sc.scroll_vertical == last else 0
		last = sc.scroll_vertical
		if still >= 5:
			return

func _win(p: Vector2) -> Vector2:
	return root.get_final_transform() * p

func _touch(pos: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = _win(pos)
	t.pressed = pressed
	Input.parse_input_event(t)

func _move(pos: Vector2, rel: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = 0
	d.position = _win(pos)
	d.relative = rel
	Input.parse_input_event(d)

## Finger down at `from`, moved by `by` in `steps` frames, lifted. Returns nothing; the caller looks.
func _drag(from: Vector2, by: Vector2, steps: int = 10) -> void:
	_touch(from, true)
	await process_frame
	for k in steps:
		_move(from + by * float(k + 1) / steps, by / steps)
		await process_frame
	_touch(from + by, false)
	await _frames(2)

func _tap(at: Vector2, jitter: bool) -> void:
	_touch(at, true)
	await process_frame
	if jitter:
		for k in 3:
			_move(at + Vector2(k + 1, k + 1), Vector2(1, 1))
			await process_frame
	_touch(at + (Vector2(3, 3) if jitter else Vector2.ZERO), false)
	await _frames(2)

## A button of the list that is fully on screen, near the given fraction of the list's height.
func _button_in(sc: ScrollContainer, frac: float) -> Button:
	var vis: Rect2 = sc.get_global_rect()
	var best: Button = null
	var best_d := INF
	for b in sc.find_children("*", "Button", true, false):
		if not b.is_visible_in_tree() or b.disabled:
			continue
		var r: Rect2 = b.get_global_rect()
		if not vis.has_point(r.get_center()) or r.intersection(vis).size.y < r.size.y * 0.6:
			continue                                    # mostly on screen, its centre surely tappable
		var d := absf(r.get_center().y - (vis.position.y + vis.size.y * frac))
		if d < best_d:
			best_d = d
			best = b
	return best

## Drag on a button of `sc`: the list follows, the button is not pressed; then back down.
func _list(sc: ScrollContainer, what: String) -> void:
	await _frames(3)
	var max_scroll: int = int(sc.get_v_scroll_bar().max_value - sc.get_v_scroll_bar().page)
	_check(max_scroll > 20, "%s: the list is longer than its box (%d px to scroll)" % [what, max_scroll])
	if max_scroll <= 20:
		return
	sc.scroll_vertical = 0
	await _frames(2)
	var b := _button_in(sc, 0.75)
	_check(b != null, "%s: a button to start the drag on" % what)
	if b == null:
		return
	var presses := [0]
	var count := func(): presses[0] += 1
	b.pressed.connect(count)
	var from: Vector2 = b.get_global_rect().get_center()
	var up := -minf(sc.size.y * 0.6, 160.0)
	await _drag(from, Vector2(0, up))
	var after_up: int = sc.scroll_vertical
	_check(after_up >= int(minf(-up, max_scroll)) - 4 and presses[0] == 0,
		"%s: a drag started on a button scrolls the list with the finger (%d px for %d px) and does not press it (%d)" % [what, after_up, int(-up), presses[0]])
	# the button is not stuck half-pressed: a tap on it now presses it once
	await _settle(sc)                                   # glide over
	var b2 := _button_in(sc, 0.5)
	if b2 != b:
		b.pressed.disconnect(count)
		b = b2
		b.pressed.connect(count)
	presses[0] = 0
	var s0: int = sc.scroll_vertical
	await _tap(b.get_global_rect().get_center(), true)
	_check(presses[0] == 1 and absi(sc.scroll_vertical - s0) <= 1,
		"%s: a tap with a little finger jitter still presses the button (%d) and does not scroll (%d px)" % [what, presses[0], sc.scroll_vertical - s0])
	b.pressed.disconnect(count)

func _run() -> void:
	root.size = Vector2i(540, 960)                      # the phone's portrait screen, not the headless 960 x 960
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(3)
	game = scene as GameController3D
	var ui = game.ui_manager

	# ---- main menu: the civ list
	var menu = ui.menu_root
	if menu.has_method("_on_new_game_pressed"):
		menu._on_new_game_pressed()
	await _frames(4)
	var civs: ScrollContainer = menu.civ_list_container.get_parent()
	if civs.is_visible_in_tree() and civs.get_v_scroll_bar().max_value - civs.get_v_scroll_bar().page > 20:
		var chosen = menu.get("selected_civ")
		await _list(civs, "civ list")
		print("  (civ list: selected civ before %s, after %s)" % [chosen, menu.get("selected_civ")])
	else:
		print("  (civ list fits its box on this screen, nothing to scroll - skipped)")

	# ---- in game
	FactionArtManager.use_3d_building_models = false
	GraphicsSettings.values["style"] = 1
	seed(5)
	game._on_start_game_requested(CivData.CivType.BRITONS, CivData.CivType.JAPANESE, 0)
	if game.tutorial_mgr != null and game.tutorial_mgr.has_method("stop_tutorial"):
		game.tutorial_mgr.stop_tutorial()
	game.enemy_ai.set_process(false)
	await _frames(5)
	var v = null
	for u in game.units:
		if u.team == 0 and u.unit_type == Unit3D.UnitType.VILLAGER:
			v = u
			break
	game._clear_selection()
	game.selected_units.append(v)
	v.set_selected(true)
	ui.set_selected_entity(v)
	await _frames(3)
	for b in ui.find_children("*", "Button", true, false):
		if b.text.contains("İNŞA ET") and b.is_visible_in_tree():
			b.pressed.emit()
			break
	await _frames(3)
	var build_sc: ScrollContainer = ui.build_grid.get_parent()
	await _list(build_sc, "build menu")
	# the tap above picked a building: the panel closed and placement started; that is the button working
	_check(game.is_placing_building and not ui.build_panel.visible,
		"build menu: the tapped card started placing its building (panel closed)")
	if game.is_placing_building:
		game.cancel_building_placement()

	# a flick: the list glides on after the finger is lifted
	ui.build_panel.visible = true
	ui.build_panel.offset_bottom = ui.bottom_bar.offset_top - 6.0
	await _frames(3)
	build_sc.scroll_vertical = 0
	await _frames(2)
	var fb := _button_in(build_sc, 0.8)
	var fpress := [0]
	fb.pressed.connect(func(): fpress[0] += 1)
	await _drag(fb.get_global_rect().get_center(), Vector2(0, -60), 3)
	var at_release: int = build_sc.scroll_vertical
	await _settle(build_sc)
	_check(build_sc.scroll_vertical > at_release and fpress[0] == 0,
		"build menu: a quick flick glides on after letting go (%d -> %d px), no press" % [at_release, build_sc.scroll_vertical])
	# and a drag the other way scrolls back
	var top_b := _button_in(build_sc, 0.2)
	await _drag(top_b.get_global_rect().get_center(), Vector2(0, 300))
	await _settle(build_sc)
	_check(build_sc.scroll_vertical == 0, "build menu: a drag down on a button scrolls back to the top (%d)" % build_sc.scroll_vertical)
	# sideways wobble on a vertical list is not a scroll: the button still works
	var sb := _button_in(build_sc, 0.3)
	var spress := [0]
	sb.pressed.connect(func(): spress[0] += 1)
	var s_before: int = build_sc.scroll_vertical
	_touch(sb.get_global_rect().get_center(), true)
	await process_frame
	_move(sb.get_global_rect().get_center() + Vector2(25, 2), Vector2(25, 2))
	await process_frame
	_touch(sb.get_global_rect().get_center() + Vector2(25, 2), false)
	await _frames(2)
	_check(spress[0] == 1 and build_sc.scroll_vertical == s_before,
		"build menu: a sideways slip on a card is still a tap (pressed %d, scrolled %d)" % [spress[0], build_sc.scroll_vertical - s_before])
	if game.is_placing_building:
		game.cancel_building_placement()
	ui.build_panel.visible = false

	# ---- the bottom action buttons (a building with a long list of trainings / techs)
	var act_sc: ScrollContainer = ui.action_flow.get_parent()
	var found := false
	for bld in game.buildings:
		if not is_instance_valid(bld) or bld.team != 0:
			continue
		game._clear_selection()
		ui.set_selected_entity(bld)
		await _frames(3)
		if act_sc.get_v_scroll_bar().max_value - act_sc.get_v_scroll_bar().page > 20:
			found = true
			await _list(act_sc, "action buttons of %s" % Building3D.BuildingType.keys()[bld.building_type])
			break
	if not found:
		# no long list at the start of a match: give the selected town center's list extra buttons
		# (as many as a late-game building shows) and check that list
		for bld in game.buildings:
			if is_instance_valid(bld) and bld.team == 0:
				game._clear_selection()
				ui.set_selected_entity(bld)
				break
		await _frames(3)
		for k in 10:
			var extra := Button.new()
			extra.text = "EK %d" % k
			extra.custom_minimum_size = Vector2(120, 48)
			ui.action_flow.add_child(extra)
		await _frames(3)
		await _list(act_sc, "bottom action buttons (filled)")
	print("RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)
