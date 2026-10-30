class_name MenuRoot
extends Control

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

signal start_game(player_civ, enemy_civ, map_type)

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

var selected_player_civ: CivData.CivType = CivData.CivType.OTTOMANS
var selected_enemy_civ: CivData.CivType = CivData.CivType.BYZANTINES
var selected_map_type: CivData.MapType = CivData.MapType.FOREST_VALLEY

var civ_buttons: Dictionary = {}

func _ready() -> void:
	if main_menu_view == null or btn_new_game == null:
		return
	if has_node("BattleBg"):
		var bg = get_node("BattleBg") as TextureRect
		var img_path = "res://assets/battle_bg.png"
		var img = Image.load_from_file(ProjectSettings.globalize_path(img_path))
		if img and not img.is_empty():
			bg.texture = ImageTexture.create_from_image(img)

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

	for b in [btn_new_game, btn_settings, btn_gallery, btn_exit]:
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

	_populate_maps()
	_populate_enemy_civs()
	_populate_player_civs()
	_update_civ_preview()

func _show_main_menu() -> void:
	main_menu_view.visible = true
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
