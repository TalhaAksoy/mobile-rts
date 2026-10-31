class_name MenuRoot
extends Control

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

signal start_game(player_civ, enemy_civ, map_type)
signal load_game_requested      # "KAYITLI OYUN": continue the quick-saved match

@onready var main_menu_view: Control = get_node_or_null("MainMenuView")
@onready var civ_select_view: Control = get_node_or_null("CivSelectView")
@onready var settings_view: Control = get_node_or_null("SettingsView")

# Main Menu Elements
@onready var title_label: Label = get_node_or_null("MainMenuView/HeaderBox/Title")
@onready var subtitle_label: Label = get_node_or_null("MainMenuView/HeaderBox/Subtitle")
@onready var btn_new_game: Button = get_node_or_null("MainMenuView/VBox/NewGameButton")
@onready var btn_settings: Button = get_node_or_null("MainMenuView/VBox/SettingsButton")
@onready var btn_gallery: Button = get_node_or_null("MainMenuView/VBox/GalleryButton")
@onready var btn_exit: Button = get_node_or_null("MainMenuView/VBox/ExitButton")
@onready var art_preview: Control = get_node_or_null("ArtPreview")
var btn_continue: Button = null   # built in code, shown only when a saved game exists

# Civ Select Elements
@onready var civ_list_container: VBoxContainer = get_node_or_null("CivSelectView/HBox/ScrollCivs/CivList")
@onready var map_option_button: OptionButton = get_node_or_null("CivSelectView/HBox/DetailsScroll/DetailsVBox/MapOption")
@onready var enemy_civ_option: OptionButton = get_node_or_null("CivSelectView/HBox/DetailsScroll/DetailsVBox/EnemyCivOption")
@onready var start_btn: Button = get_node_or_null("CivSelectView/HBox/DetailsScroll/DetailsVBox/StartButton")
@onready var back_btn: Button = get_node_or_null("CivSelectView/HBox/DetailsScroll/DetailsVBox/BackButton")
@onready var civ_title_label: Label = get_node_or_null("CivSelectView/HBox/DetailsScroll/DetailsVBox/CivTitleLabel")
@onready var civ_perks_label: Label = get_node_or_null("CivSelectView/HBox/DetailsScroll/DetailsVBox/CivPerksLabel")
@onready var unique_unit_label: Label = get_node_or_null("CivSelectView/HBox/DetailsScroll/DetailsVBox/UniqueUnitLabel")
@onready var map_label: Label = get_node_or_null("CivSelectView/HBox/DetailsScroll/DetailsVBox/MapLabel")
@onready var enemy_label: Label = get_node_or_null("CivSelectView/HBox/DetailsScroll/DetailsVBox/EnemyLabel")
@onready var details_vbox: VBoxContainer = get_node_or_null("CivSelectView/HBox/DetailsScroll/DetailsVBox")
var civ_flag_banner: TextureRect = null
var roster_preview_box: VBoxContainer = null

# Settings Elements
@onready var close_settings_btn: Button = get_node_or_null("SettingsView/Panel/VBox/CloseSettingsButton")
@onready var volume_slider: HSlider = get_node_or_null("SettingsView/Panel/VBox/VolumeSlider")
@onready var cam_speed_slider: HSlider = get_node_or_null("SettingsView/Panel/VBox/CamSpeedSlider")

# Graphics settings (built in code, see _build_graphics_settings)
var gfx_preset_buttons: Array = []          # index = GraphicsSettings.Preset
var gfx_scale_slider: HSlider = null
var gfx_scale_label: Label = null
var gfx_msaa_buttons: Array = []
var gfx_shadow_buttons: Array = []
var gfx_fps_buttons: Array = []
var gfx_style_buttons: Array = []
var gfx_summary_label: Label = null
var _gfx_syncing := false

var selected_player_civ: CivData.CivType = CivData.CivType.OTTOMANS
var selected_enemy_civ: CivData.CivType = CivData.CivType.BYZANTINES
var selected_map_type: CivData.MapType = CivData.MapType.FOREST_VALLEY

var civ_buttons: Dictionary = {}

func _ready() -> void:
	if main_menu_view == null or btn_new_game == null:
		return
	if has_node("BattleBg"):
		var bg = get_node("BattleBg") as TextureRect
		# load the IMPORTED texture: the raw .png is not packed into exported builds (Android showed no background)
		var tex = load("res://assets/battle_bg.png") as Texture2D
		if tex != null:
			bg.texture = tex

	# 1. Main Menu Titles Typography
	if is_instance_valid(title_label):
		title_label.text = "POCKET EMPIRES"
		title_label.add_theme_font_override("font", ParchmentTheme.get_cinzel_font())
		title_label.add_theme_font_size_override("font_size", 42)
		title_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.50))
		title_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.04, 0.01, 0.95))
		title_label.add_theme_constant_override("shadow_offset_x", 3)
		title_label.add_theme_constant_override("shadow_offset_y", 3)

	if is_instance_valid(subtitle_label):
		subtitle_label.text = "KRALLIKLAR ÇAĞI • STRATEJİ VE SEFER"
		subtitle_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
		subtitle_label.add_theme_font_size_override("font_size", 16)
		subtitle_label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.68))

	# 2. Main Menu Buttons Styling (Uniform 20px size & parchment placards)
	btn_new_game.text = "YENİ OYUN"
	btn_settings.text = "AYARLAR"
	if is_instance_valid(btn_gallery):
		btn_gallery.text = "SANAT GALERİSİ"
	btn_exit.text = "OYUNDAN ÇIK"

	if btn_continue == null:
		btn_continue = Button.new()
		btn_continue.name = "ContinueButton"
		btn_new_game.get_parent().add_child(btn_continue)
		btn_new_game.get_parent().move_child(btn_continue, btn_new_game.get_index() + 1)
		btn_continue.pressed.connect(func():
			SoundManager.play_sound("click")
			load_game_requested.emit())
	btn_continue.text = "KAYITLI OYUN"

	for b in [btn_new_game, btn_continue, btn_settings, btn_gallery, btn_exit]:
		if is_instance_valid(b):
			ParchmentTheme.apply_parchment_button(b, 20)
			b.custom_minimum_size = Vector2(260, 58)

	# 3. Civ Select View Styling
	ParchmentTheme.apply_parchment_button(start_btn, 19)
	start_btn.text = "SEFERİ BAŞLAT"
	start_btn.custom_minimum_size = Vector2(0, 58)

	ParchmentTheme.apply_parchment_button(back_btn, 17)
	back_btn.text = "ANA MENÜYE DÖN"
	back_btn.custom_minimum_size = Vector2(0, 48)

	if is_instance_valid(close_settings_btn):
		ParchmentTheme.apply_parchment_button(close_settings_btn, 17)
		close_settings_btn.text = "AYARLARI KAYDET VE DÖN"

	if is_instance_valid(map_label):
		map_label.text = "Savaş Meydanı:"
		map_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	if is_instance_valid(enemy_label):
		enemy_label.text = "Düşman Krallık:"
		enemy_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())

	civ_title_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	civ_perks_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	unique_unit_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())

	if details_vbox:
		civ_flag_banner = TextureRect.new()
		civ_flag_banner.name = "CivFlagBanner"
		civ_flag_banner.custom_minimum_size = Vector2(0, 96)
		civ_flag_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		civ_flag_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		details_vbox.add_child(civ_flag_banner)
		details_vbox.move_child(civ_flag_banner, 0)

		# Unit Roster Preview Container in Civ Select
		var roster_label = Label.new()
		roster_label.text = "ORDU BİRLİKLERİ & İŞÇİLER:"
		roster_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
		roster_label.add_theme_font_size_override("font_size", 14)
		roster_label.add_theme_color_override("font_color", Color(0.38, 0.24, 0.12))
		details_vbox.add_child(roster_label)

		var roster_scroll = ScrollContainer.new()
		roster_scroll.custom_minimum_size = Vector2(0, 180)
		roster_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details_vbox.add_child(roster_scroll)

		roster_preview_box = VBoxContainer.new()
		roster_preview_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		roster_preview_box.add_theme_constant_override("separation", 6)
		roster_scroll.add_child(roster_preview_box)

	_show_main_menu()

	# Connect Main Menu (idempotent)
	if not btn_new_game.pressed.is_connected(_on_new_game_pressed):
		btn_new_game.pressed.connect(_on_new_game_pressed)
	if not btn_settings.pressed.is_connected(_on_settings_pressed):
		btn_settings.pressed.connect(_on_settings_pressed)
	if is_instance_valid(btn_gallery) and not btn_gallery.pressed.is_connected(_on_gallery_pressed):
		btn_gallery.pressed.connect(_on_gallery_pressed)
	if not btn_exit.pressed.is_connected(_on_exit_pressed):
		btn_exit.pressed.connect(_on_exit_pressed)

	# Connect Art Preview Back Button
	if is_instance_valid(art_preview) and art_preview.has_signal("back_requested"):
		if not art_preview.back_requested.is_connected(_show_main_menu):
			art_preview.back_requested.connect(_show_main_menu)

	# Connect Civ Select
	if not start_btn.pressed.is_connected(_on_start_pressed):
		start_btn.pressed.connect(_on_start_pressed)
	if not back_btn.pressed.is_connected(_show_main_menu):
		back_btn.pressed.connect(_show_main_menu)
	if not map_option_button.item_selected.is_connected(_on_map_selected):
		map_option_button.item_selected.connect(_on_map_selected)
	if not enemy_civ_option.item_selected.is_connected(_on_enemy_selected):
		enemy_civ_option.item_selected.connect(_on_enemy_selected)

	# Connect Settings
	if is_instance_valid(close_settings_btn) and not close_settings_btn.pressed.is_connected(_show_main_menu):
		close_settings_btn.pressed.connect(_show_main_menu)
	if is_instance_valid(volume_slider) and not volume_slider.value_changed.is_connected(_on_volume_changed):
		volume_slider.value_changed.connect(_on_volume_changed)
	if is_instance_valid(close_settings_btn) and not close_settings_btn.pressed.is_connected(_save_settings):
		close_settings_btn.pressed.connect(_save_settings)
	_load_audio_settings()
	_build_graphics_settings()

	_populate_maps()
	_populate_enemy_civs()
	_populate_player_civs()
	_update_civ_preview()

func _show_main_menu() -> void:
	main_menu_view.visible = true
	if is_instance_valid(btn_continue):
		btn_continue.visible = SaveManager.has_saved_game()
	civ_select_view.visible = false
	settings_view.visible = false
	if is_instance_valid(art_preview):
		art_preview.visible = false

func _on_new_game_pressed() -> void:
	SoundManager.play_sound("click")
	main_menu_view.visible = false
	civ_select_view.visible = true
	settings_view.visible = false
	if is_instance_valid(art_preview):
		art_preview.visible = false

func _on_settings_pressed() -> void:
	SoundManager.play_sound("click")
	main_menu_view.visible = false
	civ_select_view.visible = false
	settings_view.visible = true
	if is_instance_valid(art_preview):
		art_preview.visible = false

func _on_gallery_pressed() -> void:
	SoundManager.play_sound("click")
	main_menu_view.visible = false
	civ_select_view.visible = false
	settings_view.visible = false
	if is_instance_valid(art_preview):
		art_preview.visible = true


func _on_exit_pressed() -> void:
	SoundManager.play_sound("click")
	get_tree().quit()

func _on_volume_changed(val: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(val / 100.0))

func _populate_maps() -> void:
	map_option_button.clear()
	for m_type in CivData.MAP_CONFIGS.keys():
		var cfg = CivData.get_map_config(m_type)
		map_option_button.add_item("%s - %s" % [cfg.get("name"), cfg.get("subtitle")], m_type)

func _populate_enemy_civs() -> void:
	enemy_civ_option.clear()
	for c_type in CivData.CIVS.keys():
		var c = CivData.get_civ(c_type)
		var flag = PixelArtTextures.get_civ_flag_texture(c_type)
		enemy_civ_option.add_icon_item(flag, "%s" % c.get("name"), c_type)
	enemy_civ_option.select(CivData.CivType.BYZANTINES)

func _populate_player_civs() -> void:
	for child in civ_list_container.get_children():
		child.queue_free()

	for c_type in CivData.CIVS.keys():
		var c = CivData.get_civ(c_type)
		var btn = Button.new()
		btn.text = " %s" % c.get("name")
		btn.icon = PixelArtTextures.get_civ_flag_texture(c_type)
		btn.expand_icon = true
		btn.custom_minimum_size = Vector2(170, 52)
		ParchmentTheme.apply_parchment_button(btn, 15)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		btn.pressed.connect(func():
			selected_player_civ = c_type
			_highlight_selected_button()
			_update_civ_preview()
			SoundManager.play_sound("click")
		)
		civ_buttons[c_type] = btn
		civ_list_container.add_child(btn)

	_highlight_selected_button()

func _highlight_selected_button() -> void:
	for c_type in civ_buttons.keys():
		var btn = civ_buttons[c_type] as Button
		if c_type == selected_player_civ:
			btn.modulate = Color(1.0, 0.95, 0.5) # Glowing gold leaf
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)

func _update_civ_preview() -> void:
	var c = CivData.get_civ(selected_player_civ)
	if civ_flag_banner:
		civ_flag_banner.texture = PixelArtTextures.get_civ_flag_texture(selected_player_civ)
	civ_title_label.text = "%s" % c.get("title", "")
	civ_perks_label.text = "KRALİYET NİTELİKLERİ:\n%s" % c.get("bonus_desc", "")
	unique_unit_label.text = "ÖZEL BİRİM: %s\n%s" % [
		c.get("unique_unit_name", ""),
		c.get("unique_unit_desc", "")
	]

	if roster_preview_box != null:
		for child in roster_preview_box.get_children():
			roster_preview_box.remove_child(child)
			child.queue_free()

		var roles = [
			{"type": Unit3D.UnitType.VILLAGER, "name": "Köylü (İşçi)", "desc": "Kaynak toplama ve inşaat"},
			{"type": Unit3D.UnitType.SWORDSMAN, "name": "Kılıçlı Asker", "desc": "Temel yakın piyade"},
			{"type": Unit3D.UnitType.SPEARMAN, "name": "Mızrakçı", "desc": "Süvari karşıtı birlik"},
			{"type": Unit3D.UnitType.ARCHER, "name": "Okçu", "desc": "Menzilli yaylı ordu"},
			{"type": _get_unique_unit_type(selected_player_civ), "name": c.get("unique_unit_name", "Özel Birlik"), "desc": c.get("unique_unit_desc", "Krallık elit askeri")}
		]

		for r in roles:
			var card = PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.custom_minimum_size = Vector2(0, 44)

			var c_style = StyleBoxFlat.new()
			c_style.bg_color = Color(0.22, 0.17, 0.13, 0.90)
			c_style.border_color = Color(0.65, 0.52, 0.32, 0.75)
			c_style.set_border_width_all(1)
			c_style.set_corner_radius_all(6)
			c_style.content_margin_left = 6
			c_style.content_margin_right = 6
			c_style.content_margin_top = 4
			c_style.content_margin_bottom = 4
			card.add_theme_stylebox_override("panel", c_style)

			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 8)
			card.add_child(hbox)

			var icon_rect = TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(38, 38)
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture = FactionArtManager.get_unit_texture(selected_player_civ, r["type"], "pose_01")
			hbox.add_child(icon_rect)

			var txt_vbox = VBoxContainer.new()
			txt_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			txt_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_child(txt_vbox)

			var n_lbl = Label.new()
			n_lbl.text = r["name"]
			n_lbl.add_theme_font_override("font", ParchmentTheme.get_cinzel_font())
			n_lbl.add_theme_font_size_override("font_size", 12)
			n_lbl.add_theme_color_override("font_color", Color(0.96, 0.88, 0.55))
			txt_vbox.add_child(n_lbl)

			var d_lbl = Label.new()
			d_lbl.text = r["desc"]
			d_lbl.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
			d_lbl.add_theme_font_size_override("font_size", 10)
			d_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.62))
			d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			txt_vbox.add_child(d_lbl)

			roster_preview_box.add_child(card)

func _get_unique_unit_type(civ: CivData.CivType) -> Unit3D.UnitType:
	match civ:
		CivData.CivType.OTTOMANS: return Unit3D.UnitType.JANISSARY
		CivData.CivType.BYZANTINES: return Unit3D.UnitType.CATAPHRACT
		CivData.CivType.BRITONS: return Unit3D.UnitType.LONGBOWMAN
		CivData.CivType.FRANKS: return Unit3D.UnitType.PALADIN
		CivData.CivType.MONGOLS: return Unit3D.UnitType.MANGUDAI
		CivData.CivType.TEUTONS: return Unit3D.UnitType.TEUTONIC_KNIGHT
		CivData.CivType.JAPANESE: return Unit3D.UnitType.SAMURAI
		CivData.CivType.SARACENS: return Unit3D.UnitType.MAMELUKE
		CivData.CivType.VIKINGS: return Unit3D.UnitType.BERSERKER
		CivData.CivType.CHINESE: return Unit3D.UnitType.CHUKONU
	return Unit3D.UnitType.SWORDSMAN

func _on_map_selected(idx: int) -> void:
	selected_map_type = map_option_button.get_item_id(idx) as CivData.MapType
	SoundManager.play_sound("click")

func _on_enemy_selected(idx: int) -> void:
	selected_enemy_civ = enemy_civ_option.get_item_id(idx) as CivData.CivType
	SoundManager.play_sound("click")

func _on_start_pressed() -> void:
	SoundManager.play_sound("victory")
	start_game.emit(selected_player_civ, selected_enemy_civ, selected_map_type)


# ------------------------------------------------------------------------------------------------
# Settings persistence (user://settings.cfg) and the graphics section
# ------------------------------------------------------------------------------------------------
func _save_settings() -> void:
	GraphicsSettings.save_settings()
	var cfg := ConfigFile.new()
	cfg.load(GraphicsSettings.PATH)
	if is_instance_valid(volume_slider):
		cfg.set_value("audio", "volume", volume_slider.value)
	if is_instance_valid(cam_speed_slider):
		cfg.set_value("controls", "camera_speed", cam_speed_slider.value)
	cfg.save(GraphicsSettings.PATH)

func _load_audio_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(GraphicsSettings.PATH) != OK:
		return
	if is_instance_valid(volume_slider) and cfg.has_section_key("audio", "volume"):
		volume_slider.value = cfg.get_value("audio", "volume")
		_on_volume_changed(volume_slider.value)
	if is_instance_valid(cam_speed_slider) and cfg.has_section_key("controls", "camera_speed"):
		cam_speed_slider.value = cfg.get_value("controls", "camera_speed")

func _gfx_label(text: String, size: int = 15) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.28, 0.18, 0.08))
	return l

## A row of toggle buttons (one active); `on_pick(index)` is called when the user taps one.
func _gfx_button_row(names: Array, on_pick: Callable) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var buttons: Array = []
	for i in names.size():
		var b := Button.new()
		b.text = names[i]
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 42)
		ParchmentTheme.apply_parchment_button(b, 14)
		b.pressed.connect(func(): on_pick.call(i))
		row.add_child(b)
		buttons.append(b)
	_gfx_rows.append(row)
	return buttons

var _gfx_rows: Array = []

func _build_graphics_settings() -> void:
	if not is_instance_valid(close_settings_btn) or gfx_scale_slider != null:
		return
	GraphicsSettings.ensure_loaded()
	var vbox := close_settings_btn.get_parent()
	var items: Array = []
	items.append(_gfx_label("GRAFİK KALİTESİ", 18))
	gfx_preset_buttons = _gfx_button_row(GraphicsSettings.PRESET_NAMES, _on_gfx_preset_picked)
	items.append(_gfx_rows[-1])
	items.append(_gfx_label("Görünüm (yeni maçta geçerli):"))
	gfx_style_buttons = _gfx_button_row(GraphicsSettings.STYLE_NAMES, func(i): _on_gfx_option("style", i))
	items.append(_gfx_rows[-1])
	gfx_scale_label = _gfx_label("")
	items.append(gfx_scale_label)
	gfx_scale_slider = HSlider.new()
	gfx_scale_slider.min_value = GraphicsSettings.SCALE_MIN
	gfx_scale_slider.max_value = GraphicsSettings.SCALE_MAX
	gfx_scale_slider.step = GraphicsSettings.SCALE_STEP
	gfx_scale_slider.custom_minimum_size = Vector2(0, 28)
	gfx_scale_slider.value_changed.connect(_on_gfx_scale_changed)
	items.append(gfx_scale_slider)
	items.append(_gfx_label("Kenar Yumuşatma (MSAA):"))
	gfx_msaa_buttons = _gfx_button_row(GraphicsSettings.MSAA_NAMES, func(i): _on_gfx_option("msaa", GraphicsSettings.MSAA_OPTIONS[i]))
	items.append(_gfx_rows[-1])
	items.append(_gfx_label("Gölgeler:"))
	gfx_shadow_buttons = _gfx_button_row(GraphicsSettings.SHADOW_NAMES, func(i): _on_gfx_option("shadows", i))
	items.append(_gfx_rows[-1])
	items.append(_gfx_label("Kare Sınırı:"))
	gfx_fps_buttons = _gfx_button_row(GraphicsSettings.FPS_OPTIONS.map(func(f): return "%d FPS" % f), func(i): _on_gfx_option("fps", GraphicsSettings.FPS_OPTIONS[i]))
	items.append(_gfx_rows[-1])
	gfx_summary_label = _gfx_label("", 12)
	gfx_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	items.append(gfx_summary_label)
	var at := close_settings_btn.get_index()
	for it in items:
		vbox.add_child(it)
		vbox.move_child(it, at)
		at += 1
	vbox.add_theme_constant_override("separation", 8)
	_sync_gfx_controls()
	_apply_graphics()

func _on_gfx_preset_picked(i: int) -> void:
	if i == GraphicsSettings.Preset.CUSTOM:
		_sync_gfx_controls()          # "Özel" is an indicator: it is selected by changing an option
		return
	SoundManager.play_sound("click")
	GraphicsSettings.set_preset(i)
	_sync_gfx_controls()
	_apply_graphics()

func _on_gfx_option(key: String, v) -> void:
	SoundManager.play_sound("click")
	GraphicsSettings.set_value(key, v)
	_sync_gfx_controls()
	_apply_graphics()

func _on_gfx_scale_changed(v: float) -> void:
	if _gfx_syncing:
		return
	if int(v) == int(GraphicsSettings.values["scale"]):
		return
	GraphicsSettings.set_value("scale", v)
	_sync_gfx_controls()
	_apply_graphics()

func _sync_gfx_controls() -> void:
	_gfx_syncing = true
	var vals: Dictionary = GraphicsSettings.values
	for i in gfx_preset_buttons.size():
		gfx_preset_buttons[i].set_pressed_no_signal(i == GraphicsSettings.preset)
	gfx_scale_slider.value = vals["scale"]
	gfx_scale_label.text = "3D Çözünürlük: %%%d" % vals["scale"]
	for i in gfx_msaa_buttons.size():
		gfx_msaa_buttons[i].set_pressed_no_signal(GraphicsSettings.MSAA_OPTIONS[i] == vals["msaa"])
	for i in gfx_shadow_buttons.size():
		gfx_shadow_buttons[i].set_pressed_no_signal(i == vals["shadows"])
	for i in gfx_fps_buttons.size():
		gfx_fps_buttons[i].set_pressed_no_signal(GraphicsSettings.FPS_OPTIONS[i] == vals["fps"])
	for i in gfx_style_buttons.size():
		gfx_style_buttons[i].set_pressed_no_signal(i == vals["style"])
	gfx_summary_label.text = GraphicsSettings.describe()
	_gfx_syncing = false

func _apply_graphics() -> void:
	var light: DirectionalLight3D = null
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene != null:
		light = scene.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	GraphicsSettings.apply(get_viewport(), light)
