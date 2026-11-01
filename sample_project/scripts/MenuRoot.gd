class_name MenuRoot
extends Control

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

signal start_game(player_civ, enemy_civ, map_type)
signal load_game_requested      # "KAYITLI OYUN": continue the quick-saved match
signal difficulty_selected(difficulty: int)   # sent right before start_game
signal match_setup_selected(map_size: int, bot_count: int, bot_civs: Array)   # sent right before start_game

## Enemy bot difficulty (Kolay / Orta / Zor). First launch: Kolay, so a new player gets time to learn;
## afterwards the last choice (settings.cfg, section "game").
var selected_difficulty: int = EnemyAI3D.Difficulty.EASY
var difficulty_buttons: Array = []
var difficulty_hint: Label = null

## Map size (Küçük / Orta / Büyük) and how many bots, limited by the size (MapGenerator3D.MAP_SIZE_MAX_BOTS).
## Remembered in settings.cfg (section "game", keys map_size and bot_count).
var selected_map_size: int = MapGenerator3D.MapSize.SMALL
var selected_bot_count: int = 1
var map_size_buttons: Array = []
var bot_count_label: Label = null
var bot_minus_btn: Button = null
var bot_plus_btn: Button = null
var bot_limit_label: Label = null
var bots_box: VBoxContainer = null
## One civ picker per bot ("Rastgele" = id -1). The scene's EnemyCivOption is hidden; bot_civ_options[0] is Rakip 1.
var bot_civ_options: Array = []

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

	# 1. Main menu logo (art_source/blender/logo/render_logo.py); the text title stays as the fallback
	var logo_tex := load("res://assets/logo/logo.png") as Texture2D
	if logo_tex != null and is_instance_valid(title_label):
		var header := title_label.get_parent() as Control
		var logo_rect := header.get_node_or_null("LogoRect") as TextureRect
		if logo_rect == null:
			logo_rect = TextureRect.new()
			logo_rect.name = "LogoRect"
			logo_rect.texture = logo_tex
			logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			logo_rect.custom_minimum_size = Vector2(0, 330)
			logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			header.add_child(logo_rect)
			header.move_child(logo_rect, title_label.get_index())
			header.offset_top = 28.0
			header.offset_bottom = 392.0
		title_label.visible = false

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
		enemy_label.text = "Rakip Krallıklar:"
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
	_build_match_setup()
	_build_difficulty_row()

	_populate_maps()
	_populate_enemy_civs()
	_populate_bot_civs()
	_refresh_match_setup()
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
	var civs := _bot_civ_choices()
	selected_enemy_civ = civs[0] as CivData.CivType
	difficulty_selected.emit(selected_difficulty)
	match_setup_selected.emit(selected_map_size, selected_bot_count, civs)
	start_game.emit(selected_player_civ, selected_enemy_civ, selected_map_type)

## "Harita Boyutu" row under the map, then the opponent count (− n +) and one civ picker per opponent.
func _build_match_setup() -> void:
	if not is_instance_valid(enemy_civ_option) or not map_size_buttons.is_empty():
		return
	var cfg := ConfigFile.new()
	if cfg.load(GraphicsSettings.PATH) == OK:
		selected_map_size = clampi(int(cfg.get_value("game", "map_size", selected_map_size)), 0, MapGenerator3D.MAP_SIZE_DIMS.size() - 1)
		selected_bot_count = int(cfg.get_value("game", "bot_count", selected_bot_count))
	var vbox := enemy_civ_option.get_parent()

	# map size, right after the map picker
	var at := map_option_button.get_index() + 1
	var size_label := _setup_label("Harita Boyutu:")
	size_label.name = "MapSizeLabel"
	vbox.add_child(size_label)
	vbox.move_child(size_label, at)
	map_size_buttons = _gfx_button_row(MapGenerator3D.MAP_SIZE_NAMES, _on_map_size_picked)
	var size_row: Control = map_size_buttons[0].get_parent()
	size_row.name = "MapSizeRow"
	_gfx_rows.erase(size_row)
	vbox.add_child(size_row)
	vbox.move_child(size_row, at + 1)

	# opponents, in place of the single enemy picker
	enemy_civ_option.visible = false
	at = enemy_civ_option.get_index()
	var step := HBoxContainer.new()
	step.name = "BotCountRow"
	step.add_theme_constant_override("separation", 6)
	bot_minus_btn = Button.new()
	bot_minus_btn.text = "−"
	bot_plus_btn = Button.new()
	bot_plus_btn.text = "+"
	for b in [bot_minus_btn, bot_plus_btn]:
		ParchmentTheme.apply_parchment_button(b, 20)
		b.custom_minimum_size = Vector2(48, 42)
	bot_count_label = _setup_label("1")
	bot_count_label.add_theme_font_override("font", ParchmentTheme.get_cinzel_font())
	bot_count_label.add_theme_font_size_override("font_size", 20)
	bot_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step.add_child(bot_minus_btn)
	step.add_child(bot_count_label)
	step.add_child(bot_plus_btn)
	bot_minus_btn.pressed.connect(func(): _set_bot_count(selected_bot_count - 1, true))
	bot_plus_btn.pressed.connect(func(): _set_bot_count(selected_bot_count + 1, true))
	vbox.add_child(step)
	vbox.move_child(step, at)
	bot_limit_label = _gfx_label("", 12)
	bot_limit_label.name = "BotLimitHint"
	bot_limit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(bot_limit_label)
	vbox.move_child(bot_limit_label, at + 1)

	bots_box = VBoxContainer.new()
	bots_box.name = "BotsBox"
	bots_box.add_theme_constant_override("separation", 6)
	for i in MapGenerator3D.MAP_SIZE_MAX_BOTS.max():
		var row := HBoxContainer.new()
		row.name = "Bot%d" % (i + 1)
		row.add_theme_constant_override("separation", 6)
		var sw := ColorRect.new()
		sw.color = FactionArtManager.team_color(i + 1)
		sw.custom_minimum_size = Vector2(10, 0)
		row.add_child(sw)
		var opt := OptionButton.new()
		opt.name = "BotCivOption%d" % (i + 1)
		opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opt.custom_minimum_size = Vector2(0, 44)
		opt.fit_to_longest_item = false
		opt.item_selected.connect(func(_idx): SoundManager.play_sound("click"))
		row.add_child(opt)
		bot_civ_options.append(opt)
		bots_box.add_child(row)
	vbox.add_child(bots_box)
	vbox.move_child(bots_box, at + 2)

func _setup_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	if is_instance_valid(enemy_label):
		l.add_theme_font_size_override("font_size", enemy_label.get_theme_font_size("font_size"))
		l.add_theme_color_override("font_color", enemy_label.get_theme_color("font_color"))
	return l

func _populate_bot_civs() -> void:
	for i in bot_civ_options.size():
		var opt: OptionButton = bot_civ_options[i]
		var keep: int = opt.get_selected_id() if opt.item_count > 0 else (int(CivData.CivType.BYZANTINES) if i == 0 else -1)
		opt.clear()
		opt.add_item("Rastgele", -1)
		for c_type in CivData.CIVS.keys():
			opt.add_icon_item(PixelArtTextures.get_civ_flag_texture(c_type), str(CivData.get_civ(c_type).get("name")), c_type)
		var idx := opt.get_item_index(keep)
		opt.select(idx if idx >= 0 else 0)

func _on_map_size_picked(i: int) -> void:
	SoundManager.play_sound("click")
	selected_map_size = i
	# a bigger map starts with as many opponents as it holds; a smaller one drops the extra ones
	_set_bot_count(MapGenerator3D.max_bots_for(i) if i > MapGenerator3D.MapSize.SMALL else 1, false)
	_save_game_setting("map_size", i)

func _set_bot_count(n: int, sound: bool) -> void:
	if sound:
		SoundManager.play_sound("click")
	selected_bot_count = clampi(n, 1, MapGenerator3D.max_bots_for(selected_map_size))
	_save_game_setting("bot_count", selected_bot_count)
	_refresh_match_setup()

func _refresh_match_setup() -> void:
	var mx := MapGenerator3D.max_bots_for(selected_map_size)
	selected_bot_count = clampi(selected_bot_count, 1, mx)
	for i in map_size_buttons.size():
		map_size_buttons[i].set_pressed_no_signal(i == selected_map_size)
	if bot_count_label != null:
		bot_count_label.text = str(selected_bot_count)
		bot_minus_btn.disabled = selected_bot_count <= 1
		bot_plus_btn.disabled = selected_bot_count >= mx
		bot_limit_label.text = "En çok %d rakip, herkes herkese karşı." % mx if mx > 1 \
			else "Küçük harita bire bir. Daha çok rakip: Orta / Büyük."
	if bots_box != null:
		for i in bots_box.get_child_count():
			bots_box.get_child(i).visible = i < selected_bot_count

## Civ of every bot for the next match; -1 = random (GameController3D picks an unused civ).
## Rakip 1 on "Rastgele" is resolved here, never to the player's civ.
func _bot_civ_choices() -> Array:
	var out: Array = []
	for i in selected_bot_count:
		out.append(bot_civ_options[i].get_selected_id() if i < bot_civ_options.size() else -1)
	if out.is_empty():
		out.append(selected_enemy_civ)
	if out[0] < 0:
		var pool: Array = CivData.CIVS.keys().filter(func(c): return c != selected_player_civ and not out.has(c))
		out[0] = pool[randi() % pool.size()]
	return out

func _save_game_setting(key: String, v) -> void:
	var cfg := ConfigFile.new()
	cfg.load(GraphicsSettings.PATH)
	cfg.set_value("game", key, v)
	cfg.save(GraphicsSettings.PATH)

## "Zorluk" row on the civ select screen, under the enemy kingdom.
func _build_difficulty_row() -> void:
	if not is_instance_valid(enemy_civ_option) or not difficulty_buttons.is_empty():
		return
	var cfg := ConfigFile.new()
	if cfg.load(GraphicsSettings.PATH) == OK:
		selected_difficulty = clampi(int(cfg.get_value("game", "difficulty", selected_difficulty)), 0, 2)
	var vbox := enemy_civ_option.get_parent()
	var at := enemy_civ_option.get_index() + 1
	var label := Label.new()
	label.name = "DifficultyLabel"
	label.text = "Zorluk:"
	if is_instance_valid(enemy_label):
		label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
		label.add_theme_font_size_override("font_size", enemy_label.get_theme_font_size("font_size"))
		label.add_theme_color_override("font_color", enemy_label.get_theme_color("font_color"))
	vbox.add_child(label)
	vbox.move_child(label, at)
	difficulty_buttons = _gfx_button_row(EnemyAI3D.DIFFICULTY_NAMES, _on_difficulty_picked)
	var row: Control = difficulty_buttons[0].get_parent()
	row.name = "DifficultyRow"
	_gfx_rows.erase(row)
	vbox.add_child(row)
	vbox.move_child(row, at + 1)
	difficulty_hint = _gfx_label("", 13)
	difficulty_hint.name = "DifficultyHint"
	difficulty_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(difficulty_hint)
	vbox.move_child(difficulty_hint, at + 2)
	_refresh_difficulty()

func _on_difficulty_picked(i: int) -> void:
	SoundManager.play_sound("click")
	selected_difficulty = i
	_refresh_difficulty()
	var cfg := ConfigFile.new()
	cfg.load(GraphicsSettings.PATH)
	cfg.set_value("game", "difficulty", i)
	cfg.save(GraphicsSettings.PATH)

func _refresh_difficulty() -> void:
	for i in difficulty_buttons.size():
		difficulty_buttons[i].button_pressed = i == selected_difficulty
	if difficulty_hint != null:
		difficulty_hint.text = EnemyAI3D.DIFFICULTY_HINTS[selected_difficulty]


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
