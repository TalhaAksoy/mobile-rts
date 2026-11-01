class_name MenuRoot
extends Control

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

signal start_game(player_civ, enemy_civ, map_type)
signal load_game_requested      # "Kayıtlı oyun": continue the quick-saved match
signal difficulty_selected(difficulty: int)   # sent right before start_game
## Map size, number of bots and each bot's civ (-1 = random); sent right before start_game.
signal match_setup_selected(map_size: int, bot_count: int, bot_civs: Array)

## Enemy bot difficulty (Kolay / Orta / Zor). First launch: Kolay, so a new player gets time to learn;
## afterwards the last choice (settings.cfg, section "game").
var selected_difficulty: int = EnemyAI3D.Difficulty.EASY
var difficulty_buttons: Array = []
var difficulty_hint: Label = null

## Map size (Küçük / Orta / Büyük) and how many bots (1 .. MapGenerator3D.MAP_SIZE_MAX_BOTS[size]).
var selected_map_size: int = MapGenerator3D.MapSize.SMALL
var selected_bot_count: int = 1
var map_size_buttons: Array = []
var bot_count_label: Label = null
var bot_minus_btn: Button = null
var bot_plus_btn: Button = null
var bot_limit_label: Label = null
var bots_box: VBoxContainer = null
## One civ picker per bot ("Rastgele" = id -1); [0] is the scene's EnemyCivOption.
var bot_civ_options: Array = []
var map_desc_label: Label = null

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

# Civ Select Elements (scene nodes, moved into the new-game layout built in code)
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
## Five portraits of the selected civ's army (villager, swordsman, spearman, archer, unique unit).
var roster_preview_box: BoxContainer = null
var civ_grid: GridContainer = null

# Settings Elements
@onready var close_settings_btn: Button = get_node_or_null("SettingsView/Panel/VBox/CloseSettingsButton")
@onready var volume_slider: HSlider = get_node_or_null("SettingsView/Panel/VBox/VolumeSlider")
@onready var cam_speed_slider: HSlider = get_node_or_null("SettingsView/Panel/VBox/CamSpeedSlider")
var volume_value_label: Label = null
var cam_value_label: Label = null
var settings_content: VBoxContainer = null

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
var _layout_built := false
const _MOVED_REFS := ["map_option_button", "enemy_civ_option", "start_btn", "back_btn", "civ_title_label",
	"civ_perks_label", "unique_unit_label", "close_settings_btn", "volume_slider", "cam_speed_slider"]
var _saved_refs: Dictionary = {}

const PT = preload("res://scripts/ParchmentTheme.gd")
const SIDE_MARGIN := 14

func _ready() -> void:
	if main_menu_view == null or btn_new_game == null:
		return
	if has_node("BattleBg"):
		var bg = get_node("BattleBg") as TextureRect
		# load the IMPORTED texture: the raw .png is not packed into exported builds (Android showed no background)
		var tex = load("res://assets/battle_bg.png") as Texture2D
		if tex != null:
			bg.texture = tex
	if has_node("Vignette"):
		(get_node("Vignette") as ColorRect).color = Color(0.07, 0.05, 0.035, 0.72)

	if not _layout_built:
		_layout_built = true
		_load_game_settings()
		_build_main_menu_layout()
		_build_new_game_layout()
		_build_settings_layout()
		for k in _MOVED_REFS:
			_saved_refs[k] = get(k)
	else:
		# a second _ready (re-entering the tree, tests) re-resolves the @onready paths, but the layout
		# above moved those nodes: put the real references back
		for k in _saved_refs:
			set(k, _saved_refs[k])

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

	if is_instance_valid(art_preview) and art_preview.has_signal("back_requested"):
		if not art_preview.back_requested.is_connected(_show_main_menu):
			art_preview.back_requested.connect(_show_main_menu)

	if not start_btn.pressed.is_connected(_on_start_pressed):
		start_btn.pressed.connect(_on_start_pressed)
	if not back_btn.pressed.is_connected(_show_main_menu):
		back_btn.pressed.connect(_show_main_menu)
	if not map_option_button.item_selected.is_connected(_on_map_selected):
		map_option_button.item_selected.connect(_on_map_selected)
	if not enemy_civ_option.item_selected.is_connected(_on_enemy_selected):
		enemy_civ_option.item_selected.connect(_on_enemy_selected)

	if is_instance_valid(close_settings_btn) and not close_settings_btn.pressed.is_connected(_show_main_menu):
		close_settings_btn.pressed.connect(_show_main_menu)
	if is_instance_valid(volume_slider) and not volume_slider.value_changed.is_connected(_on_volume_changed):
		volume_slider.value_changed.connect(_on_volume_changed)
	if is_instance_valid(cam_speed_slider) and not cam_speed_slider.value_changed.is_connected(_on_cam_speed_changed):
		cam_speed_slider.value_changed.connect(_on_cam_speed_changed)
	if is_instance_valid(close_settings_btn) and not close_settings_btn.pressed.is_connected(_save_settings):
		close_settings_btn.pressed.connect(_save_settings)
	_load_audio_settings()
	_build_graphics_settings()

	_populate_maps()
	_populate_enemy_civs()
	_populate_player_civs()
	_update_civ_preview()
	_refresh_match_setup()

# ------------------------------------------------------------------------------------------------
# Layout helpers
# ------------------------------------------------------------------------------------------------
## Full-screen paper sheet with a header row (back button, title) and a scrolling body.
## Returns {"sheet", "header", "body", "footer"}.
func _make_sheet(parent: Control, title: String, back: Button) -> Dictionary:
	var sheet := PanelContainer.new()
	sheet.name = "Sheet"
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 10
	sheet.offset_right = -10
	sheet.offset_top = 14
	sheet.offset_bottom = -12
	sheet.add_theme_stylebox_override("panel", PT.panel_style(0.98, 12, 0))
	parent.add_child(sheet)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	sheet.add_child(col)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 56)
	header.add_theme_constant_override("separation", 4)
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 6)
	hm.add_theme_constant_override("margin_right", SIDE_MARGIN)
	hm.add_child(header)
	col.add_child(hm)
	if back != null:
		_reparent(back, header)
		PT.apply_ghost_button(back, 16)
		back.custom_minimum_size = Vector2(0, 44)
		back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var t := PT.heading_label(title, 22)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(t)
	col.add_child(PT.rule())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var bm := MarginContainer.new()
	bm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		bm.add_theme_constant_override("margin_" + side, SIDE_MARGIN + 4)
	bm.add_theme_constant_override("margin_top", 14)
	bm.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(bm)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	bm.add_child(body)

	var footer := MarginContainer.new()
	for side in ["left", "right"]:
		footer.add_theme_constant_override("margin_" + side, SIDE_MARGIN)
	footer.add_theme_constant_override("margin_top", 10)
	footer.add_theme_constant_override("margin_bottom", 14)
	col.add_child(PT.rule())
	col.add_child(footer)
	return {"sheet": sheet, "header": header, "body": body, "footer": footer}

func _section(body: VBoxContainer, title: String, first: bool = false) -> void:
	if not first:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 8)
		body.add_child(gap)
	body.add_child(PT.section_label(title))

## A row of toggle buttons (one active); `on_pick(index)` is called when the user taps one.
func _segmented(names: Array, on_pick: Callable, height: int = 42) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var buttons: Array = []
	for i in names.size():
		var b := Button.new()
		b.text = names[i]
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, height)
		PT.apply_parchment_button(b, 15)
		b.pressed.connect(func(): on_pick.call(i))
		row.add_child(b)
		buttons.append(b)
	_gfx_rows.append(row)
	return buttons

func _value_row(text: String) -> Array:
	var row := HBoxContainer.new()
	var l := PT.body_label(text, 15)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := PT.body_label("", 15, true)
	v.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	return [row, v]

# ------------------------------------------------------------------------------------------------
# Main menu
# ------------------------------------------------------------------------------------------------
func _build_main_menu_layout() -> void:
	var header := get_node_or_null("MainMenuView/HeaderBox") as VBoxContainer
	if header != null:
		header.set_anchors_preset(Control.PRESET_TOP_WIDE)
		header.offset_left = 24
		header.offset_right = -24
		header.offset_top = 150
		header.offset_bottom = 290
		header.add_theme_constant_override("separation", 6)
	if is_instance_valid(title_label):
		title_label.text = "POCKET EMPIRES"
		title_label.add_theme_font_override("font", PT.get_cinzel_font())
		title_label.add_theme_font_size_override("font_size", 46)
		title_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.76))
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		title_label.add_theme_constant_override("shadow_offset_x", 0)
		title_label.add_theme_constant_override("shadow_offset_y", 2)
	if is_instance_valid(subtitle_label):
		subtitle_label.text = "Krallıklar çağında bir cep stratejisi"
		subtitle_label.add_theme_font_override("font", PT.get_medieval_font())
		subtitle_label.add_theme_font_size_override("font_size", 15)
		subtitle_label.add_theme_color_override("font_color", Color(0.86, 0.80, 0.68, 0.9))
		subtitle_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		if header != null and header.get_node_or_null("TitleRule") == null:
			var rule := ColorRect.new()
			rule.name = "TitleRule"
			rule.color = Color(0.86, 0.66, 0.30, 0.8)
			rule.custom_minimum_size = Vector2(56, 2)
			rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			header.add_child(rule)
			header.move_child(rule, subtitle_label.get_index())

	var vbox := btn_new_game.get_parent() as VBoxContainer
	vbox.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	vbox.offset_left = -150
	vbox.offset_right = 150
	vbox.offset_top = -360
	vbox.offset_bottom = -64
	vbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	vbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_theme_constant_override("separation", 10)

	if btn_continue == null:
		btn_continue = Button.new()
		btn_continue.name = "ContinueButton"
		vbox.add_child(btn_continue)
		vbox.move_child(btn_continue, btn_new_game.get_index() + 1)
		btn_continue.pressed.connect(func():
			SoundManager.play_sound("click")
			load_game_requested.emit())
	btn_new_game.text = "Yeni Oyun"
	btn_continue.text = "Kayıtlı Oyuna Devam Et"
	btn_settings.text = "Ayarlar"
	if is_instance_valid(btn_gallery):
		btn_gallery.text = "Sanat Galerisi"
	btn_exit.text = "Oyundan Çık"
	PT.apply_primary_button(btn_new_game, 20)
	btn_new_game.custom_minimum_size = Vector2(0, 58)
	for b in [btn_continue, btn_settings, btn_gallery]:
		if is_instance_valid(b):
			PT.apply_parchment_button(b, 16)
			b.custom_minimum_size = Vector2(0, 50)
	PT.apply_ghost_button(btn_exit, 15)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn_exit.add_theme_color_override(st, Color(0.90, 0.84, 0.72))
	btn_exit.custom_minimum_size = Vector2(0, 44)

	if main_menu_view.get_node_or_null("VersionLabel") == null:
		var ver := Label.new()
		ver.name = "VersionLabel"
		var v_str := str(ProjectSettings.get_setting("application/config/version", ""))
		ver.text = "Sürüm %s" % (v_str if v_str != "" else "0.9")
		ver.add_theme_font_override("font", PT.get_medieval_font())
		ver.add_theme_font_size_override("font_size", 11)
		ver.add_theme_color_override("font_color", Color(0.86, 0.80, 0.68, 0.5))
		ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		ver.offset_top = -30
		ver.offset_bottom = -12
		ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		main_menu_view.add_child(ver)

# ------------------------------------------------------------------------------------------------
# New game: one column for portrait phones - kingdom, map, opponents, difficulty, start
# ------------------------------------------------------------------------------------------------
func _build_new_game_layout() -> void:
	for n in ["Panel", "HBox"]:
		var old := civ_select_view.get_node_or_null(n) as Control
		if old != null:
			old.visible = false
	back_btn.text = "‹  Geri"
	var s := _make_sheet(civ_select_view, "Yeni Oyun", back_btn)
	var body: VBoxContainer = s["body"]

	# -- kingdom
	_section(body, "Krallığın", true)
	civ_grid = GridContainer.new()
	civ_grid.columns = 5
	civ_grid.add_theme_constant_override("h_separation", 6)
	civ_grid.add_theme_constant_override("v_separation", 6)
	body.add_child(civ_grid)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", PT._sb(PT.PARCHMENT_LIGHT, PT.HAIRLINE, 1, 10, 14, 12))
	body.add_child(card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	card.add_child(cv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	cv.add_child(top)
	civ_flag_banner = TextureRect.new()
	civ_flag_banner.name = "CivFlagBanner"
	civ_flag_banner.custom_minimum_size = Vector2(54, 38)
	civ_flag_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	civ_flag_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	civ_flag_banner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	civ_flag_banner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(civ_flag_banner)
	_reparent(civ_title_label, top)
	civ_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	civ_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	civ_title_label.add_theme_font_override("font", PT.get_cinzel_font())
	civ_title_label.add_theme_font_size_override("font_size", 19)
	civ_title_label.add_theme_color_override("font_color", PT.INK_DARK)
	civ_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reparent(civ_perks_label, cv)
	_reparent(unique_unit_label, cv)
	for l in [civ_perks_label, unique_unit_label]:
		l.add_theme_font_override("font", PT.get_medieval_font())
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", PT.INK_DARK)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unique_unit_label.add_theme_color_override("font_color", PT.INK_MUTED)
	roster_preview_box = HBoxContainer.new()
	roster_preview_box.name = "Roster"
	roster_preview_box.add_theme_constant_override("separation", 4)
	cv.add_child(PT.rule())
	cv.add_child(roster_preview_box)

	# -- map
	_section(body, "Harita")
	_reparent(map_option_button, body)
	map_option_button.custom_minimum_size = Vector2(0, 46)
	map_option_button.add_theme_font_override("font", PT.get_body_bold_font())
	map_option_button.add_theme_font_size_override("font_size", 15)
	PT.apply_parchment_popup(map_option_button.get_popup(), 16)
	map_desc_label = PT.body_label("", 13, true)
	body.add_child(map_desc_label)
	var size_names: Array = []
	for i in MapGenerator3D.MAP_SIZE_NAMES.size():
		var mx := MapGenerator3D.MAP_SIZE_MAX_BOTS[i]
		size_names.append("%s\n%s" % [MapGenerator3D.MAP_SIZE_NAMES[i], "1 rakip" if mx == 1 else "en çok %d rakip" % mx])
	map_size_buttons = _segmented(size_names, _on_map_size_picked, 56)
	var size_row: Control = map_size_buttons[0].get_parent()
	_gfx_rows.erase(size_row)
	size_row.name = "MapSizeRow"
	body.add_child(size_row)
	for b in map_size_buttons:
		b.add_theme_font_size_override("font_size", 14)

	# -- opponents
	_section(body, "Rakipler")
	var step := HBoxContainer.new()
	step.add_theme_constant_override("separation", 8)
	body.add_child(step)
	var sl := PT.body_label("Rakip sayısı", 15)
	sl.autowrap_mode = TextServer.AUTOWRAP_OFF
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	step.add_child(sl)
	bot_minus_btn = Button.new()
	bot_minus_btn.text = "−"
	bot_count_label = PT.heading_label("1", 20)
	bot_count_label.custom_minimum_size = Vector2(40, 0)
	bot_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot_count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bot_plus_btn = Button.new()
	bot_plus_btn.text = "+"
	for b in [bot_minus_btn, bot_plus_btn]:
		PT.apply_parchment_button(b, 20)
		b.custom_minimum_size = Vector2(48, 44)
	step.add_child(bot_minus_btn)
	step.add_child(bot_count_label)
	step.add_child(bot_plus_btn)
	bot_minus_btn.pressed.connect(func(): _set_bot_count(selected_bot_count - 1, true))
	bot_plus_btn.pressed.connect(func(): _set_bot_count(selected_bot_count + 1, true))
	bot_limit_label = PT.body_label("", 13, true)
	body.add_child(bot_limit_label)
	bots_box = VBoxContainer.new()
	bots_box.name = "BotRows"
	bots_box.add_theme_constant_override("separation", 6)
	body.add_child(bots_box)
	for i in MapGenerator3D.MAP_SIZE_MAX_BOTS[-1]:
		var opt: OptionButton = enemy_civ_option if i == 0 else OptionButton.new()
		bot_civ_options.append(opt)
		bots_box.add_child(_bot_row(i, opt))

	# -- difficulty
	_section(body, "Zorluk")
	difficulty_buttons = _segmented(EnemyAI3D.DIFFICULTY_NAMES, _on_difficulty_picked)
	var drow: Control = difficulty_buttons[0].get_parent()
	drow.name = "DifficultyRow"
	_gfx_rows.erase(drow)
	body.add_child(drow)
	difficulty_hint = PT.body_label("", 13, true)
	difficulty_hint.name = "DifficultyHint"
	body.add_child(difficulty_hint)
	_refresh_difficulty()

	# -- start
	_reparent(start_btn, s["footer"])
	start_btn.text = "Seferi Başlat"
	PT.apply_primary_button(start_btn, 20)
	start_btn.custom_minimum_size = Vector2(0, 56)

	for n in [map_label, enemy_label]:
		if is_instance_valid(n):
			n.visible = false

func _bot_row(i: int, opt: OptionButton) -> Control:
	var row := HBoxContainer.new()
	row.name = "Bot%d" % (i + 1)
	row.add_theme_constant_override("separation", 10)
	var sw := Panel.new()
	sw.custom_minimum_size = Vector2(14, 14)
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sw.add_theme_stylebox_override("panel", PT._sb(FactionArtManager.team_color(i + 1), Color(0, 0, 0, 0.35), 1, 7, 0, 0))
	row.add_child(sw)
	var l := PT.body_label("Rakip %d" % (i + 1), 15)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.custom_minimum_size = Vector2(72, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	_reparent(opt, row)
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.custom_minimum_size = Vector2(0, 44)
	opt.add_theme_font_override("font", PT.get_body_bold_font())
	opt.add_theme_font_size_override("font_size", 15)
	opt.expand_icon = false
	PT.apply_parchment_popup(opt.get_popup(), 16)
	if i > 0:
		opt.item_selected.connect(func(_idx): SoundManager.play_sound("click"))
	return row

func _reparent(n: Node, to: Node) -> void:
	if n == null:
		return
	n.owner = null      # built-in-scene nodes moved into code-built containers
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	to.add_child(n)

# ------------------------------------------------------------------------------------------------
# Settings: Ses / Kontroller / Grafik / Görünüm
# ------------------------------------------------------------------------------------------------
func _build_settings_layout() -> void:
	if not is_instance_valid(close_settings_btn):
		return
	var old := settings_view.get_node_or_null("Panel") as Control
	close_settings_btn.text = "‹  Kaydet ve dön"
	var s := _make_sheet(settings_view, "Ayarlar", close_settings_btn)
	settings_content = s["body"]
	_section(settings_content, "Ses", true)
	var vr := _value_row("Genel ses")
	volume_value_label = vr[1]
	settings_content.add_child(vr[0])
	_reparent(volume_slider, settings_content)
	_section(settings_content, "Kontroller")
	var cr := _value_row("Kamera kaydırma hızı")
	cam_value_label = cr[1]
	settings_content.add_child(cr[0])
	_reparent(cam_speed_slider, settings_content)
	for sl in [volume_slider, cam_speed_slider]:
		sl.custom_minimum_size = Vector2(0, 32)
	(s["footer"] as Control).visible = false
	if old != null:
		old.visible = false

func _build_graphics_settings() -> void:
	if settings_content == null or gfx_scale_slider != null:
		return
	GraphicsSettings.ensure_loaded()
	var body := settings_content
	_section(body, "Grafik")
	body.add_child(PT.body_label("Kalite", 14, true))
	gfx_preset_buttons = _segmented(GraphicsSettings.PRESET_NAMES, _on_gfx_preset_picked)
	body.add_child(_gfx_rows[-1])
	var sr := _value_row("3D çözünürlük")
	gfx_scale_label = sr[1]
	body.add_child(sr[0])
	gfx_scale_slider = HSlider.new()
	gfx_scale_slider.min_value = GraphicsSettings.SCALE_MIN
	gfx_scale_slider.max_value = GraphicsSettings.SCALE_MAX
	gfx_scale_slider.step = GraphicsSettings.SCALE_STEP
	gfx_scale_slider.custom_minimum_size = Vector2(0, 32)
	gfx_scale_slider.value_changed.connect(_on_gfx_scale_changed)
	body.add_child(gfx_scale_slider)
	body.add_child(PT.body_label("Kenar yumuşatma (MSAA)", 14, true))
	gfx_msaa_buttons = _segmented(GraphicsSettings.MSAA_NAMES, func(i): _on_gfx_option("msaa", GraphicsSettings.MSAA_OPTIONS[i]))
	body.add_child(_gfx_rows[-1])
	body.add_child(PT.body_label("Gölgeler", 14, true))
	gfx_shadow_buttons = _segmented(GraphicsSettings.SHADOW_NAMES, func(i): _on_gfx_option("shadows", i))
	body.add_child(_gfx_rows[-1])
	body.add_child(PT.body_label("Kare sınırı", 14, true))
	gfx_fps_buttons = _segmented(GraphicsSettings.FPS_OPTIONS.map(func(f): return "%d FPS" % f), func(i): _on_gfx_option("fps", GraphicsSettings.FPS_OPTIONS[i]))
	body.add_child(_gfx_rows[-1])
	_section(body, "Görünüm")
	gfx_style_buttons = _segmented(GraphicsSettings.STYLE_NAMES, func(i): _on_gfx_option("style", i))
	body.add_child(_gfx_rows[-1])
	body.add_child(PT.body_label("3D modeller veya onlardan çizilmiş 2D sprite'lar. Yeni maçta geçerli olur.", 13, true))
	body.add_child(PT.rule())
	gfx_summary_label = PT.body_label("", 12, true)
	body.add_child(gfx_summary_label)
	_sync_gfx_controls()
	_apply_graphics()

# ------------------------------------------------------------------------------------------------
# Navigation
# ------------------------------------------------------------------------------------------------
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
	if volume_value_label != null:
		volume_value_label.text = "%%%d" % int(val)

func _on_cam_speed_changed(val: float) -> void:
	if cam_value_label != null:
		cam_value_label.text = "%%%d" % int(val)

# ------------------------------------------------------------------------------------------------
# New game: data
# ------------------------------------------------------------------------------------------------
func _populate_maps() -> void:
	map_option_button.clear()
	for m_type in CivData.MAP_CONFIGS.keys():
		var cfg = CivData.get_map_config(m_type)
		map_option_button.add_item(str(cfg.get("name")), m_type)
	var idx := map_option_button.get_item_index(selected_map_type)
	if idx >= 0:
		map_option_button.select(idx)
	_update_map_desc()

func _update_map_desc() -> void:
	if map_desc_label != null:
		map_desc_label.text = str(CivData.get_map_config(selected_map_type).get("desc", ""))

func _populate_enemy_civs() -> void:
	for i in bot_civ_options.size():
		var opt: OptionButton = bot_civ_options[i]
		var keep: int = opt.get_selected_id() if opt.item_count > 0 else (int(CivData.CivType.BYZANTINES) if i == 0 else -1)
		opt.clear()
		opt.add_item("Rastgele", -1)
		for c_type in CivData.CIVS.keys():
			opt.add_icon_item(PixelArtTextures.get_civ_flag_texture(c_type), str(CivData.get_civ(c_type).get("name")), c_type)
		var at := opt.get_item_index(keep)
		opt.select(at if at >= 0 else 0)
	if bot_civ_options.is_empty():
		enemy_civ_option.clear()
		for c_type in CivData.CIVS.keys():
			enemy_civ_option.add_icon_item(PixelArtTextures.get_civ_flag_texture(c_type), str(CivData.get_civ(c_type).get("name")), c_type)
		enemy_civ_option.select(CivData.CivType.BYZANTINES)

func _populate_player_civs() -> void:
	var holder: Container = civ_grid if civ_grid != null else civ_list_container
	for child in holder.get_children():
		child.queue_free()
	civ_buttons.clear()
	for c_type in CivData.CIVS.keys():
		var c = CivData.get_civ(c_type)
		var btn = Button.new()
		btn.name = "Civ%d" % c_type
		btn.text = str(c.get("name"))
		btn.tooltip_text = str(c.get("title", ""))
		btn.icon = PixelArtTextures.get_civ_flag_texture(c_type)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.clip_text = true
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 74)
		btn.toggle_mode = true
		PT.apply_parchment_button(btn, 11)
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_constant_override("icon_max_width", 46)
		btn.pressed.connect(func():
			selected_player_civ = c_type
			_highlight_selected_button()
			_update_civ_preview()
			SoundManager.play_sound("click")
		)
		civ_buttons[c_type] = btn
		holder.add_child(btn)
	_highlight_selected_button()

func _highlight_selected_button() -> void:
	for c_type in civ_buttons.keys():
		var btn = civ_buttons[c_type] as Button
		btn.set_pressed_no_signal(false)
		var on: bool = c_type == selected_player_civ
		var sb: StyleBoxFlat = PT._sb(PT.PARCHMENT_LIGHT, PT.INK_DARK, 2, 8, 4, 6) if on else PT._sb(PT.PARCHMENT_DARK, PT.HAIRLINE, 1, 8, 4, 6)
		for st in ["normal", "hover", "pressed", "hover_pressed"]:
			btn.add_theme_stylebox_override(st, sb)
		for st in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			btn.add_theme_color_override(st, PT.INK_DARK if on else PT.INK_MUTED)
		btn.modulate = Color(1, 1, 1)

func _update_civ_preview() -> void:
	var c = CivData.get_civ(selected_player_civ)
	if civ_flag_banner:
		civ_flag_banner.texture = PixelArtTextures.get_civ_flag_texture(selected_player_civ)
	civ_title_label.text = "%s" % c.get("title", "")
	civ_perks_label.text = str(c.get("bonus_desc", ""))
	unique_unit_label.text = "Özel birim: %s. %s" % [c.get("unique_unit_name", ""), c.get("unique_unit_desc", "")]

	if roster_preview_box != null:
		for child in roster_preview_box.get_children():
			roster_preview_box.remove_child(child)
			child.queue_free()
		var roles = [
			{"type": Unit3D.UnitType.VILLAGER, "name": "Köylü"},
			{"type": Unit3D.UnitType.SWORDSMAN, "name": "Kılıçlı"},
			{"type": Unit3D.UnitType.SPEARMAN, "name": "Mızrakçı"},
			{"type": Unit3D.UnitType.ARCHER, "name": "Okçu"},
			{"type": _get_unique_unit_type(selected_player_civ), "name": str(c.get("unique_unit_name", "Özel"))},
		]
		for r in roles:
			var item := VBoxContainer.new()
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item.add_theme_constant_override("separation", 2)
			var icon_rect = TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(0, 52)
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture = FactionArtManager.get_unit_texture(selected_player_civ, r["type"], "pose_01")
			item.add_child(icon_rect)
			var n_lbl := PT.body_label(r["name"], 11, true)
			n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			n_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			n_lbl.clip_text = true
			n_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			item.add_child(n_lbl)
			roster_preview_box.add_child(item)

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
	_update_map_desc()
	SoundManager.play_sound("click")

func _on_enemy_selected(idx: int) -> void:
	var id := enemy_civ_option.get_item_id(idx)
	if id >= 0:
		selected_enemy_civ = id as CivData.CivType
	SoundManager.play_sound("click")

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
		bot_limit_label.text = "%s haritada en çok %d rakip olabilir. Herkes herkese karşı savaşır." % [MapGenerator3D.MAP_SIZE_NAMES[selected_map_size], mx] if mx > 1 \
			else "Küçük harita bire bir oynanır. Daha çok rakip için Orta veya Büyük haritayı seç."
	if bots_box != null:
		for i in bots_box.get_child_count():
			bots_box.get_child(i).visible = i < selected_bot_count

## Civ of every bot for the next match; -1 = random. Bot 1 "Rastgele" is resolved here (not the player's civ).
func _bot_civ_choices() -> Array:
	var out: Array = []
	for i in selected_bot_count:
		var id: int = bot_civ_options[i].get_selected_id() if i < bot_civ_options.size() else -1
		out.append(id)
	if out.is_empty():
		out.append(selected_enemy_civ)
	if out[0] < 0:
		var pool: Array = CivData.CIVS.keys().filter(func(c): return c != selected_player_civ and not out.has(c))
		out[0] = pool[randi() % pool.size()]
	return out

func _on_start_pressed() -> void:
	SoundManager.play_sound("victory")
	var civs := _bot_civ_choices()
	selected_enemy_civ = civs[0] as CivData.CivType
	difficulty_selected.emit(selected_difficulty)
	match_setup_selected.emit(selected_map_size, selected_bot_count, civs)
	start_game.emit(selected_player_civ, selected_enemy_civ, selected_map_type)

func _load_game_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(GraphicsSettings.PATH) == OK:
		selected_difficulty = clampi(int(cfg.get_value("game", "difficulty", selected_difficulty)), 0, 2)
		selected_map_size = clampi(int(cfg.get_value("game", "map_size", selected_map_size)), 0, MapGenerator3D.MAP_SIZE_DIMS.size() - 1)
		selected_bot_count = int(cfg.get_value("game", "bot_count", selected_bot_count))

func _save_game_setting(key: String, v) -> void:
	var cfg := ConfigFile.new()
	cfg.load(GraphicsSettings.PATH)
	cfg.set_value("game", key, v)
	cfg.save(GraphicsSettings.PATH)

## Kept for older callers: the difficulty row is part of the new-game layout now.
func _build_difficulty_row() -> void:
	_refresh_difficulty()

func _on_difficulty_picked(i: int) -> void:
	SoundManager.play_sound("click")
	selected_difficulty = i
	_refresh_difficulty()
	_save_game_setting("difficulty", i)

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
	if cfg.load(GraphicsSettings.PATH) == OK:
		if is_instance_valid(volume_slider) and cfg.has_section_key("audio", "volume"):
			volume_slider.value = cfg.get_value("audio", "volume")
		if is_instance_valid(cam_speed_slider) and cfg.has_section_key("controls", "camera_speed"):
			cam_speed_slider.value = cfg.get_value("controls", "camera_speed")
	if is_instance_valid(volume_slider):
		_on_volume_changed(volume_slider.value)
	if is_instance_valid(cam_speed_slider):
		_on_cam_speed_changed(cam_speed_slider.value)

func _gfx_label(text: String, size: int = 15) -> Label:
	return PT.body_label(text, size)

## Kept for older callers; see _segmented.
func _gfx_button_row(names: Array, on_pick: Callable) -> Array:
	return _segmented(names, on_pick)

var _gfx_rows: Array = []

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
	gfx_scale_label.text = "%%%d" % vals["scale"]
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
