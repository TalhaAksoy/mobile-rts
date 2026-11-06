extends SceneTree
## Screenshot of the menu screens (needs a display; do NOT run with --headless).
##   godot --path . --resolution 540x960 --script res://scripts/tools/capture_menu.gd -- --out=<dir> [--civ=0]
## Output: <out>/menu_new_game.png (and menu_new_game_scrolled.png when the details panel scrolls)

var out_dir := "user://captures"
var civ := 0

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_dir = a.substr(6)
		elif a.begins_with("--civ="): civ = int(a.substr(6))
	call_deferred("_run")

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _shot(name: String) -> void:
	await _frames(3)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("[menu] saved ", name)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	root.add_child(scene)
	await _frames(4)
	var menu = scene.get_node("UIManager3D/MenuRoot")
	menu._on_new_game_pressed()
	if civ != 0 and menu.civ_buttons.has(civ):
		menu.civ_buttons[civ].emit_signal("pressed")
	await _frames(4)
	await _shot("menu_new_game")
	var scroll := menu.find_child("DetailsScroll", true, false) as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 100000
		await _shot("menu_new_game_scrolled")
	quit(0)
