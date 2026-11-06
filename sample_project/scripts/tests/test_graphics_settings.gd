extends SceneTree
## Graphics settings: Low / Medium / High presets, single options, CUSTOM on a manual change,
## applying to the viewport / light / fps cap, the settings menu controls, and save -> load.
## The user's own user://settings.cfg is backed up and restored.

var failures := 0

func _check(cond: bool, msg: String) -> void:
	print(("[PASS] " if cond else "[FAIL] ") + msg)
	if not cond:
		failures += 1

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := ProjectSettings.globalize_path(GraphicsSettings.PATH)
	var backup := ""
	if FileAccess.file_exists(GraphicsSettings.PATH):
		backup = FileAccess.get_file_as_string(GraphicsSettings.PATH)
	DirAccess.remove_absolute(path)
	GraphicsSettings.read_saved_when_headless = true

	# --- defaults and presets
	GraphicsSettings.load_settings()
	_check(GraphicsSettings.preset == GraphicsSettings.default_preset(), "no saved file -> platform default preset (%s)" % GraphicsSettings.PRESET_NAMES[GraphicsSettings.preset])
	for p in [GraphicsSettings.Preset.LOW, GraphicsSettings.Preset.MEDIUM, GraphicsSettings.Preset.HIGH]:
		GraphicsSettings.set_preset(p)
		_check(GraphicsSettings.preset == p and GraphicsSettings.values == GraphicsSettings.PRESETS[p], "preset %s copies its values" % GraphicsSettings.PRESET_NAMES[p])
	var low: Dictionary = GraphicsSettings.PRESETS[GraphicsSettings.Preset.LOW]
	var high: Dictionary = GraphicsSettings.PRESETS[GraphicsSettings.Preset.HIGH]
	_check(low["scale"] < high["scale"] and low["msaa"] <= high["msaa"] and low["shadows"] < high["shadows"] and low["fps"] <= high["fps"], "Low is cheaper than High in every option")
	_check(low["style"] == 1 and high["style"] == 0 and GraphicsSettings.PRESETS[GraphicsSettings.Preset.MEDIUM]["style"] == 0, "Low uses 2D sprites, Medium/High 3D models")

	# --- manual change -> CUSTOM, values sanitised
	GraphicsSettings.set_preset(GraphicsSettings.Preset.HIGH)
	GraphicsSettings.set_value("scale", 83)
	_check(GraphicsSettings.preset == GraphicsSettings.Preset.CUSTOM, "changing one option makes the preset CUSTOM")
	_check(GraphicsSettings.values["scale"] == 85, "scale snaps to 5%% steps (83 -> %d)" % GraphicsSettings.values["scale"])
	GraphicsSettings.set_value("scale", 10)
	_check(GraphicsSettings.values["scale"] == GraphicsSettings.SCALE_MIN, "scale clamped to the minimum")
	GraphicsSettings.set_value("msaa", 3)
	_check(GraphicsSettings.values["msaa"] == 0, "invalid MSAA value falls back to off")

	# --- the real game scene: applied on start, menu controls
	var scene = load("res://scenes/Main3D.tscn").instantiate()
	GraphicsSettings.set_preset(GraphicsSettings.Preset.LOW)
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var vp := root.get_viewport()
	var light := scene.get_node("DirectionalLight3D") as DirectionalLight3D
	# Low uses the 2D sprite style, which always renders at 100% (pixel art); the stored scale stays 60
	_check(is_equal_approx(vp.scaling_3d_scale, 1.0) and GraphicsSettings.values["scale"] == 60 and vp.msaa_3d == Viewport.MSAA_DISABLED and not light.shadow_enabled and Engine.max_fps == 30,
		"game start applies Low (scale %.2f, msaa %d, shadows %s, fps %d)" % [vp.scaling_3d_scale, vp.msaa_3d, light.shadow_enabled, Engine.max_fps])

	var menu = scene.get_node("UIManager3D/MenuRoot")
	menu._on_settings_pressed()
	await process_frame
	_check(menu.gfx_style_buttons.size() == 2 and menu.gfx_style_buttons[1].button_pressed and not FactionArtManager.use_3d_building_models, "Low: style row shows 2D Sprite, 3D models off")
	_check(menu.gfx_preset_buttons.size() == 4 and menu.gfx_msaa_buttons.size() == 3 and menu.gfx_shadow_buttons.size() == 3 and menu.gfx_fps_buttons.size() == 2 and menu.gfx_scale_slider != null,
		"settings menu shows preset row, resolution slider, MSAA, shadows, fps cap")
	_check(menu.gfx_preset_buttons[GraphicsSettings.Preset.LOW].button_pressed, "menu shows the active preset (Low)")

	menu.gfx_preset_buttons[GraphicsSettings.Preset.HIGH].emit_signal("pressed")
	await process_frame
	_check(GraphicsSettings.preset == GraphicsSettings.Preset.HIGH and is_equal_approx(vp.scaling_3d_scale, 1.0) and vp.msaa_3d == Viewport.MSAA_2X and light.shadow_enabled and Engine.max_fps == 60,
		"tapping High applies it at once")
	_check(FactionArtManager.use_3d_building_models and menu.gfx_style_buttons[0].button_pressed, "High: 3D models on")
	_check(menu.gfx_preset_buttons[GraphicsSettings.Preset.HIGH].button_pressed and not menu.gfx_preset_buttons[GraphicsSettings.Preset.LOW].button_pressed, "only the High button is selected")
	_check(menu.gfx_scale_slider.value == 100 and menu.gfx_msaa_buttons[1].button_pressed and menu.gfx_shadow_buttons[2].button_pressed, "controls follow the preset")

	menu.gfx_scale_slider.value = 70
	await process_frame
	_check(GraphicsSettings.preset == GraphicsSettings.Preset.CUSTOM and menu.gfx_preset_buttons[GraphicsSettings.Preset.CUSTOM].button_pressed, "moving the resolution slider switches to Custom")
	_check(is_equal_approx(vp.scaling_3d_scale, 0.7) and menu.gfx_scale_label.text.contains("70"), "resolution applied and labelled (%s)" % menu.gfx_scale_label.text)

	menu.gfx_preset_buttons[GraphicsSettings.Preset.MEDIUM].emit_signal("pressed")
	menu.gfx_shadow_buttons[0].emit_signal("pressed")
	await process_frame
	_check(GraphicsSettings.preset == GraphicsSettings.Preset.CUSTOM and not light.shadow_enabled, "turning shadows off from Medium -> Custom, shadows off")
	menu.gfx_preset_buttons[GraphicsSettings.Preset.CUSTOM].emit_signal("pressed")
	await process_frame
	_check(GraphicsSettings.preset == GraphicsSettings.Preset.CUSTOM and menu.gfx_preset_buttons[GraphicsSettings.Preset.CUSTOM].button_pressed, "tapping Custom keeps the custom values")

	menu.gfx_style_buttons[1].emit_signal("pressed")
	await process_frame
	_check(GraphicsSettings.preset == GraphicsSettings.Preset.CUSTOM and GraphicsSettings.values["style"] == 1 and not FactionArtManager.use_3d_building_models, "picking 2D Sprite by hand -> Custom, 3D models off")

	# --- save -> load
	var saved: Dictionary = GraphicsSettings.values.duplicate()
	menu.close_settings_btn.emit_signal("pressed")
	await process_frame
	_check(FileAccess.file_exists(GraphicsSettings.PATH), "closing the settings saves user://settings.cfg")
	GraphicsSettings.set_preset(GraphicsSettings.Preset.HIGH)
	GraphicsSettings.load_settings()
	_check(GraphicsSettings.preset == GraphicsSettings.Preset.CUSTOM and GraphicsSettings.values == saved, "load restores the custom values %s" % str(GraphicsSettings.values))
	menu.gfx_preset_buttons[GraphicsSettings.Preset.LOW].emit_signal("pressed")
	menu._save_settings()
	GraphicsSettings.set_preset(GraphicsSettings.Preset.HIGH)
	GraphicsSettings.load_settings()
	_check(GraphicsSettings.preset == GraphicsSettings.Preset.LOW, "load restores a preset")
	var cfg := ConfigFile.new()
	cfg.load(GraphicsSettings.PATH)
	_check(cfg.has_section_key("audio", "volume"), "volume is saved with the graphics settings")

	# --- restore the user's file
	DirAccess.remove_absolute(path)
	if backup != "":
		var f := FileAccess.open(GraphicsSettings.PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	Engine.max_fps = 0
	FactionArtManager.use_3d_building_models = true
	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
