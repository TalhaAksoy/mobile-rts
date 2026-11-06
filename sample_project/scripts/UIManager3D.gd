class_name UIManager3D
extends CanvasLayer

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

signal start_game_requested(player_civ, enemy_civ, map_type)
signal build_selected(building_type)
signal train_unit_requested(unit_type)
signal research_requested(tech_id)
signal field_requested
signal cancel_placement_requested
signal add_builder_requested
signal cancel_construction_requested
signal select_all_military_requested
signal army_command_requested(mode: String)     # "attack" / "defend" (arm the next tap) or "stop"
signal jump_to_base_requested
signal find_idle_villager_requested
signal clear_selection_requested
signal toggle_speed_requested
## in-match menu (PauseMenu) and leaving a match
signal pause_menu_requested
signal resume_requested
signal save_requested
signal main_menu_requested
signal quit_requested
signal load_game_requested
signal difficulty_selected(difficulty: int)
signal match_setup_selected(map_size: int, bot_count: int, bot_civs: Array)
signal restart_requested

var game_controller: Node = null

@onready var menu_root: Control = $MenuRoot
@onready var hud_root: Control = $HUDRoot
@onready var game_over_modal: Control = $GameOverModal

# HUD Top Bar
@onready var food_label: Label = $HUDRoot/TopBar.find_child("FoodLabel", true, false)
@onready var wood_label: Label = $HUDRoot/TopBar.find_child("WoodLabel", true, false)
@onready var gold_label: Label = $HUDRoot/TopBar.find_child("GoldLabel", true, false)
@onready var stone_label: Label = $HUDRoot/TopBar.find_child("StoneLabel", true, false)
@onready var pop_label: Label = $HUDRoot/TopBar.find_child("PopLabel", true, false)
@onready var civ_label: Label = $HUDRoot/TopBar.find_child("CivLabel", true, false)
@onready var civ_flag_rect: TextureRect = $HUDRoot/TopBar.find_child("CivFlagRect", true, false)
@onready var speed_btn: Button = $HUDRoot/TopBar.find_child("SpeedButton", true, false)

# Persistent Bottom Bar (Command Console)
@onready var bottom_bar: PanelContainer = $HUDRoot/BottomBar
@onready var default_bar: Control = $HUDRoot/BottomBar/BarVBox/DefaultEmpireBar
@onready var default_hint: Label = $HUDRoot/BottomBar/BarVBox/DefaultHintLabel
@onready var build_main_btn: Button = $HUDRoot/BottomBar/BarVBox/DefaultEmpireBar/BuildMainButton
@onready var army_btn: Button = $HUDRoot/BottomBar/BarVBox/DefaultEmpireBar/ArmyButton
@onready var base_btn: Button = $HUDRoot/BottomBar/BarVBox/DefaultEmpireBar/BaseButton
@onready var idle_villager_btn: Button = $HUDRoot/BottomBar/BarVBox/DefaultEmpireBar/IdleVillagerButton

# Selection Deck inside Bottom Bar
@onready var selection_deck: Control = $HUDRoot/BottomBar/BarVBox/SelectionDeck
@onready var entity_portrait_rect: TextureRect = $HUDRoot/BottomBar/BarVBox/SelectionDeck/HeaderHBox/EntityPortrait
@onready var entity_name_label: Label = $HUDRoot/BottomBar/BarVBox/SelectionDeck/HeaderHBox/InfoVBox/EntityNameLabel
@onready var entity_hp_bar: ProgressBar = $HUDRoot/BottomBar/BarVBox/SelectionDeck/HeaderHBox/InfoVBox/HPBar
@onready var entity_hp_label: Label = $HUDRoot/BottomBar/BarVBox/SelectionDeck/HeaderHBox/InfoVBox/HPLabel
@onready var entity_stats_label: Label = $HUDRoot/BottomBar/BarVBox/SelectionDeck/HeaderHBox/InfoVBox/StatsLabel
@onready var deselect_btn: Button = $HUDRoot/BottomBar/BarVBox/SelectionDeck/HeaderHBox/DeselectButton
@onready var action_flow: HFlowContainer = $HUDRoot/BottomBar/BarVBox/SelectionDeck/ActionFlowScroll/ActionFlow

# Alias for backward compatibility
var action_buttons_grid: Control:
	get: return action_flow

# Zoom Controls
@onready var zoom_in_btn: Button = $HUDRoot/ZoomBox/ZoomInButton
@onready var zoom_out_btn: Button = $HUDRoot/ZoomBox/ZoomOutButton
@onready var box_select_btn: Button = $HUDRoot/ZoomBox.get_node_or_null("BoxSelectButton")
signal zoom_in_requested
signal zoom_out_requested
signal box_select_toggled(enabled: bool)
var is_box_mode_active: bool = false
var selected_resource_info: Dictionary = {}
var player_civ_type: CivData.CivType = CivData.CivType.OTTOMANS

# Build Tray Panel
@onready var build_panel: PanelContainer = $HUDRoot/BuildPanel
@onready var build_grid: GridContainer = $HUDRoot/BuildPanel/VBox/Scroll/BuildGrid
@onready var close_build_btn: Button = $HUDRoot/BuildPanel/VBox/Header/CloseBuildButton

# Restart modal
@onready var restart_btn: Button = $GameOverModal/VBox/RestartButton

var selected_entity: Node3D = null
## "Menü" button in the top bar and the in-match menu it opens
var menu_btn: Button = null
var pause_menu: PauseMenu = null
## "ANA MENÜ" on the game-over modal (next to YENİDEN OYNA)
var game_over_menu_btn: Button = null
## training / research queue of the selected building, right above the bottom panel
var queue_bar: ProductionQueueBar = null

const BOTTOM_BAR_COMPACT_TOP: float = -105.0
const BOTTOM_BAR_EXPANDED_TOP: float = -245.0

func _ready() -> void:
	# Apply Medieval Parchment Theme
	var p_theme = ParchmentTheme.create_theme()
	menu_root.theme = p_theme
	hud_root.theme = p_theme
	game_over_modal.theme = p_theme

	hud_root.visible = false
	game_over_modal.visible = false
	menu_root.visible = true
	build_panel.visible = false

	# Apply button styling with parchment placards
	ParchmentTheme.apply_parchment_button(speed_btn, 14)
	ParchmentTheme.apply_parchment_button(build_main_btn, 13)
	ParchmentTheme.apply_parchment_button(army_btn, 13)
	ParchmentTheme.apply_parchment_button(base_btn, 13)
	ParchmentTheme.apply_parchment_button(idle_villager_btn, 13)
	ParchmentTheme.apply_parchment_button(close_build_btn, 14)
	ParchmentTheme.apply_parchment_button(restart_btn, 18)

	if is_instance_valid(deselect_btn):
		ParchmentTheme.apply_parchment_button(deselect_btn, 13)
		deselect_btn.pressed.connect(func(): clear_selection_requested.emit())
	if is_instance_valid(zoom_in_btn):
		ParchmentTheme.apply_parchment_button(zoom_in_btn, 18)
		zoom_in_btn.pressed.connect(func(): zoom_in_requested.emit())
	if is_instance_valid(zoom_out_btn):
		ParchmentTheme.apply_parchment_button(zoom_out_btn, 18)
		zoom_out_btn.pressed.connect(func(): zoom_out_requested.emit())
	if is_instance_valid(box_select_btn):
		ParchmentTheme.apply_parchment_button(box_select_btn, 18)
		box_select_btn.pressed.connect(func():
			is_box_mode_active = not is_box_mode_active
			box_select_toggled.emit(is_box_mode_active)
			if is_box_mode_active:
				box_select_btn.modulate = Color(0.3, 1.0, 0.4)
				notify_banner("KUTU SEÇİMİ: AKTİF", Color(0.3, 1.0, 0.4))
			else:
				box_select_btn.modulate = Color(1.0, 1.0, 1.0)
				notify_banner("KUTU SEÇİMİ: KAPALI", Color(0.9, 0.9, 0.9))
		)

	build_main_btn.text = "İNŞAAT"
	army_btn.text = "ORDU"
	base_btn.text = "ANA ÜS"
	idle_villager_btn.text = "BOŞTA"
	close_build_btn.text = "Kapat"
	restart_btn.text = "YENİDEN OYNA"
	speed_btn.text = "Hız: 1x"

	if menu_root.has_signal("start_game"):
		menu_root.start_game.connect(func(p, e, m): start_game_requested.emit(p, e, m))

	speed_btn.pressed.connect(func(): toggle_speed_requested.emit())
	build_main_btn.pressed.connect(func():
		build_panel.visible = not build_panel.visible
		if build_panel.visible:
			build_panel.offset_bottom = bottom_bar.offset_top - 6.0
	)
	army_btn.pressed.connect(func(): select_all_military_requested.emit())
	base_btn.pressed.connect(func(): jump_to_base_requested.emit())
	idle_villager_btn.pressed.connect(func(): find_idle_villager_requested.emit())
	restart_btn.pressed.connect(func(): restart_requested.emit())
	close_build_btn.pressed.connect(func(): build_panel.visible = false)

	_setup_build_grid()
	_reset_context_deck()
	_build_match_menu(p_theme)
	_build_queue_bar()
	_build_message_stack()
	# top-bar buttons: thumb-sized (44 px high) on the portrait screen
	speed_btn.custom_minimum_size = Vector2(72, 44)
	menu_btn.custom_minimum_size = Vector2(72, 44)
	ParchmentTheme.apply_parchment_button(speed_btn, 15)
	ParchmentTheme.apply_parchment_button(menu_btn, 15)

func _build_queue_bar() -> void:
	queue_bar = ProductionQueueBar.new()
	queue_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	queue_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	queue_bar.offset_left = 8.0
	queue_bar.hidden_by = build_panel
	hud_root.add_child(queue_bar)
	hud_root.move_child(queue_bar, bottom_bar.get_index())   # under the build panel / modals
	queue_bar.cancel_train_requested.connect(func(b, i):
		if game_controller != null and is_instance_valid(b):
			game_controller.cancel_unit_production(b, i))

## Top-bar "Menü" button + in-match pause menu; "ANA MENÜ" on the game-over modal; "KAYITLI OYUN"
## on the main menu forwarded to the game.
func _build_match_menu(p_theme: Theme) -> void:
	menu_btn = Button.new()
	menu_btn.name = "MenuButton"
	menu_btn.text = "Menü"
	menu_btn.custom_minimum_size = Vector2(64, 28)
	ParchmentTheme.apply_parchment_button(menu_btn, 14)
	speed_btn.get_parent().add_child(menu_btn)
	menu_btn.pressed.connect(func(): pause_menu_requested.emit())

	pause_menu = PauseMenu.new()
	pause_menu.build(p_theme)
	add_child(pause_menu)          # last child: drawn above the HUD and the game-over modal
	pause_menu.open_requested.connect(func(): pause_menu_requested.emit())
	pause_menu.resume_requested.connect(func(): resume_requested.emit())
	pause_menu.save_requested.connect(func(): save_requested.emit())
	pause_menu.main_menu_requested.connect(func(): main_menu_requested.emit())
	pause_menu.quit_requested.connect(func(): quit_requested.emit())

	game_over_menu_btn = Button.new()
	game_over_menu_btn.name = "MainMenuButton"
	game_over_menu_btn.text = "ANA MENÜ"
	game_over_menu_btn.custom_minimum_size = Vector2(0, 56)
	ParchmentTheme.apply_parchment_button(game_over_menu_btn, 18)
	restart_btn.get_parent().add_child(game_over_menu_btn)
	game_over_menu_btn.pressed.connect(func(): main_menu_requested.emit())

	if menu_root.has_signal("difficulty_selected"):
		menu_root.difficulty_selected.connect(func(d): difficulty_selected.emit(d))
	if menu_root.has_signal("match_setup_selected"):
		menu_root.match_setup_selected.connect(func(sz, n, civs): match_setup_selected.emit(sz, n, civs))
	if menu_root.has_signal("load_game_requested"):
		menu_root.load_game_requested.connect(func(): load_game_requested.emit())

func _setup_build_grid() -> void:
	for child in build_grid.get_children():
		child.queue_free()

	var buildings_list = [
		{"type": Building3D.BuildingType.HOUSE, "label": "EV\n30 Odun", "desc": "+5 Nüfus Limiti"},
		{"type": Building3D.BuildingType.LUMBER_CAMP, "label": "ODUNCU KAMPI\n100 Odun", "desc": "Odun Teslim Noktası"},
		{"type": Building3D.BuildingType.MINING_CAMP, "label": "MADEN KAMPI\n100 Odun", "desc": "Altın & Taş Teslim Noktası"},
		{"type": Building3D.BuildingType.MILL, "label": "DEĞİRMEN\n100 Odun", "desc": "Çiftlik Merkezi: Tarla Açar"},
		{"type": Building3D.BuildingType.BARRACKS, "label": "KIŞLA\n150 Odun", "desc": "Piyade ve Mızrakçı"},
		{"type": Building3D.BuildingType.ARCHERY_RANGE, "label": "OKÇU ALANI\n150 Odun", "desc": "Menzilli Birlikler"},
		{"type": Building3D.BuildingType.STABLE, "label": "AHIR\n175 Odun", "desc": "Hızlı Süvariler"},
		{"type": Building3D.BuildingType.BLACKSMITH, "label": "DEMİRCİ\n150 Odun", "desc": "Zırh ve Silah Geliştirmesi"},
		{"type": Building3D.BuildingType.TOWER, "label": "KULE\n75 Odun | 125 Taş", "desc": "Savunma Kulesi"},
		{"type": Building3D.BuildingType.CASTLE, "label": "BÜYÜK KALE\n200 Odun | 350 Taş | 150 Altın", "desc": "Çağ II & Krallık Elit Birimi"}
	]

	for item in buildings_list:
		var btn = Button.new()
		btn.text = " %s\n(%s)" % [item["label"], item["desc"]]
		var b_icon = FactionArtManager.get_building_texture(player_civ_type, item["type"])
		if b_icon == null:
			b_icon = PixelArtTextures.get_building_icon_texture(item["type"])
		btn.icon = b_icon
		btn.expand_icon = true
		btn.custom_minimum_size = Vector2(236, 56)
		ParchmentTheme.apply_parchment_button(btn, 12)
		btn.pressed.connect(func():
			build_selected.emit(item["type"])
			build_panel.visible = false
		)
		build_grid.add_child(btn)

func set_player_civ(c_type: CivData.CivType) -> void:
	player_civ_type = c_type
	var cfg = CivData.get_civ(c_type)
	_player_age = 1
	_refresh_civ_label()
	if civ_flag_rect:
		civ_flag_rect.texture = PixelArtTextures.get_civ_flag_texture(c_type)
	_setup_build_grid()

## Top bar: civilisation name + the current age ("Osmanlılar · Köy Çağı").
var _player_age := 1
func _refresh_civ_label() -> void:
	if civ_label:
		civ_label.text = "%s · %s" % [CivData.get_civ(player_civ_type).get("name", "Osmanlılar"), TechData.age_name(_player_age)]

func set_age(age: int) -> void:
	if age != _player_age:
		_player_age = age
		_refresh_civ_label()

## Age-up feedback: gold flash over the screen, a centred card naming the new age and what changed, and the
## age chip in the top bar pulsing. The buildings and soldiers swap to their new look at the same moment.
func show_age_up(age: int) -> void:
	set_age(age)
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.85, 0.35, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.add_child(flash)
	var ft := flash.create_tween()
	ft.tween_property(flash, "color:a", 0.38, 0.15)
	ft.tween_property(flash, "color:a", 0.0, 0.9)
	ft.tween_callback(flash.queue_free)

	var card := PanelContainer.new()
	card.name = "AgeUpCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.11, 0.07, 0.92)
	sb.border_color = Color(0.95, 0.78, 0.32)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 22; sb.content_margin_right = 22; sb.content_margin_top = 12; sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vb)
	var title := Label.new()
	title.text = "★ %s ★" % TechData.age_name(age).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ParchmentTheme.get_serif_font(26, true))
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	title.add_theme_constant_override("outline_size", 5)
	vb.add_child(title)
	var sub := Label.new()
	sub.text = "Binaların ve askerlerin gelişti!" if age < 3 else "İmparatorluk ihtişamı: ağır zırhlar, sancaklar!"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", ParchmentTheme.get_serif_font(14, false))
	sub.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	vb.add_child(sub)
	hud_root.add_child(card)
	card.reset_size()
	card.position = Vector2((hud_root.size.x - card.size.x) * 0.5, hud_root.size.y * 0.30)
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.6, 0.6)
	card.modulate.a = 0.0
	var ct := card.create_tween()
	ct.set_parallel(true)
	ct.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ct.tween_property(card, "modulate:a", 1.0, 0.25)
	ct.chain().tween_interval(2.4)
	ct.chain().tween_property(card, "modulate:a", 0.0, 0.6)
	ct.chain().tween_callback(card.queue_free)

	if civ_label:
		var lt := civ_label.create_tween()
		civ_label.pivot_offset = civ_label.size * 0.5
		lt.tween_property(civ_label, "modulate", Color(1.0, 0.85, 0.3), 0.2)
		lt.tween_property(civ_label, "modulate", Color.WHITE, 0.2)
		lt.tween_property(civ_label, "modulate", Color(1.0, 0.85, 0.3), 0.2)
		lt.tween_property(civ_label, "modulate", Color.WHITE, 0.4)

func update_resources(food: int, wood: int, gold: int, stone: int, pop: int, max_pop: int) -> void:
	if food_label: food_label.text = "🌾 %d" % food
	if wood_label: wood_label.text = "🪵 %d" % wood
	if gold_label: gold_label.text = "🪙 %d" % gold
	if stone_label: stone_label.text = "🪨 %d" % stone
	if pop_label: pop_label.text = "👥 %d/%d" % [pop, max_pop]

func update_idle_villager_count(count: int) -> void:
	idle_villager_btn.text = "Boşta: %d" % count if count > 0 else "Boşta"
	idle_villager_btn.modulate = Color(1.0, 0.95, 0.5) if count > 0 else Color(1, 1, 1)

func set_selected_entity(entity: Node3D) -> void:
	selected_entity = entity
	selected_resource_info.clear()
	build_panel.visible = false

	for child in action_flow.get_children():
		child.queue_free()

	if queue_bar != null:
		queue_bar.set_building(entity as Building3D if entity is Building3D else null)

	if not is_instance_valid(entity):
		_reset_context_deck()
		return

	if default_bar != null: default_bar.visible = false
	if default_hint != null: default_hint.visible = false
	if selection_deck != null: selection_deck.visible = true
	_update_bottom_bar_height(true)

	entity_hp_bar.visible = true
	entity_hp_label.visible = true

	if entity is Unit3D:
		_display_unit_ui(entity)
	elif entity is Building3D:
		_display_building_ui(entity)

func set_selected_resource(res_info: Dictionary) -> void:
	selected_entity = null
	if queue_bar != null:
		queue_bar.set_building(null)
	selected_resource_info = res_info
	build_panel.visible = false

	for child in action_flow.get_children():
		child.queue_free()

	if res_info.is_empty():
		_reset_context_deck()
		return

	if default_bar != null: default_bar.visible = false
	if default_hint != null: default_hint.visible = false
	if selection_deck != null: selection_deck.visible = true
	_update_bottom_bar_height(true)

	var r_type = res_info.get("type", "wood")
	var r_name = res_info.get("name", "Doğal Kaynak")
	var r_amt = res_info.get("amount", 0)
	var r_max = res_info.get("max_amount", 100)

	if entity_portrait_rect != null:
		match r_type:
			"wood": entity_portrait_rect.texture = PixelArtTextures.get_oak_tree_texture()
			"gold": entity_portrait_rect.texture = PixelArtTextures.get_gold_node_texture()
			"stone": entity_portrait_rect.texture = PixelArtTextures.get_stone_node_texture()
			"food": entity_portrait_rect.texture = PixelArtTextures.get_berry_bush_texture()
		entity_portrait_rect.visible = true

	var type_title = "Odun (Ağaç)"
	match r_type:
		"wood": type_title = "Odun (Ağaç)"
		"gold": type_title = "Altın Madeni"
		"stone": type_title = "Taş Ocağı"
		"food": type_title = "Besin (Çalı)"

	entity_name_label.text = "%s: %s" % [type_title, r_name]
	entity_hp_bar.visible = true
	entity_hp_bar.max_value = r_max
	entity_hp_bar.value = r_amt
	entity_hp_label.visible = true
	entity_hp_label.text = "Kalan: %d / %d" % [r_amt, r_max]
	entity_stats_label.text = "Doğal Kaynak • Bir köylü seçip dokunarak toplatabilirsiniz."

func _reset_context_deck() -> void:
	selected_resource_info.clear()
	if selection_deck != null: selection_deck.visible = false
	if default_bar != null: default_bar.visible = true
	if default_hint != null: default_hint.visible = true
	_update_bottom_bar_height(false)

	if entity_portrait_rect != null:
		entity_portrait_rect.visible = false
	entity_name_label.text = "Krallık Komutası"
	entity_hp_bar.visible = false
	entity_hp_label.visible = false
	entity_stats_label.text = "Bir köylü veya bina seçerek emir verebilirsiniz."

func _update_bottom_bar_height(expanded: bool) -> void:
	var target_top = BOTTOM_BAR_EXPANDED_TOP if expanded else BOTTOM_BAR_COMPACT_TOP
	bottom_bar.offset_top = target_top
	if build_panel != null and build_panel.visible:
		build_panel.offset_bottom = target_top - 6.0

func _process(_delta: float) -> void:
	_update_message_stack()
	var tb := hud_root.get_node_or_null("TopBar") as Control
	var mm := hud_root.get_node_or_null("Minimap") as Control
	var zb := hud_root.get_node_or_null("ZoomBox") as Control
	if tb != null and mm != null:
		var top := tb.position.y + tb.size.y + 8.0
		if absf(mm.offset_top - top) > 0.5:
			mm.offset_bottom = top + (mm.offset_bottom - mm.offset_top)
			mm.offset_top = top
			if zb != null:
				zb.offset_bottom = mm.offset_bottom + 8.0 + (zb.offset_bottom - zb.offset_top)
				zb.offset_top = mm.offset_bottom + 8.0
	if placement_bar != null and placement_bar.visible:
		placement_bar.offset_bottom = bottom_bar.offset_top - 6.0
		placement_bar.offset_top = placement_bar.offset_bottom - 56.0
	if queue_bar != null:
		queue_bar.offset_bottom = bottom_bar.offset_top - 6.0
		queue_bar.offset_top = queue_bar.offset_bottom - queue_bar.get_combined_minimum_size().y
	# a group selection: one summary in the panel, no per-soldier status labels over the crowd
	var grp := _group_summary() if is_instance_valid(selected_entity) and selected_entity is Unit3D and selected_entity.team == 0 else {}
	if game_controller != null and "selected_units" in game_controller:
		for su in game_controller.selected_units:
			if is_instance_valid(su) and is_instance_valid(su.status_label):
				su.status_label.visible = su.is_selected and grp.is_empty()
	if not grp.is_empty():
		_apply_group_summary(grp)
	elif is_instance_valid(selected_entity):
		if selected_entity is Unit3D:
			entity_hp_bar.value = selected_entity.hp
			entity_hp_label.text = "%d / %d CAN" % [int(selected_entity.hp), int(selected_entity.max_hp)]
			if selected_entity.unit_type == Unit3D.UnitType.VILLAGER:
				var task_str = selected_entity.get_task_description_turkish()
				var carry_str = "Çanta: Boş"
				if selected_entity.carried_resource > 0:
					carry_str = "Yük: %d / %d (%s)" % [
						selected_entity.carried_resource,
						selected_entity.max_carry,
						selected_entity.resource_type.to_upper()
					]
				entity_stats_label.text = "GÖREV: %s\n%s  |  Hız: %d" % [
					task_str,
					carry_str,
					int(selected_entity.move_speed)
				]
			else:
				entity_stats_label.text = "%s\nHasar: %d | Zırh: %d | Hız: %d" % [
					selected_entity.get_task_description_turkish(),
					int(selected_entity.attack_dmg),
					int(selected_entity.armor),
					int(selected_entity.move_speed)
				]
		elif selected_entity is Building3D:
			entity_hp_bar.value = selected_entity.hp
			entity_hp_label.text = "%d / %d CAN" % [int(selected_entity.hp), int(selected_entity.max_hp)]
			entity_stats_label.text = "Zırh: %d | %s" % [
				int(selected_entity.armor),
				"Aktif" if selected_entity.is_completed else "İnşaat Sürüyor (%%%d)..." % int(selected_entity.construction_progress)
			]
			if not selected_entity.is_completed:
				_refresh_builders_label(selected_entity)
			elif is_instance_valid(builders_label):
				set_selected_entity(selected_entity)   # finished while selected: show its real buttons
	elif not selected_resource_info.is_empty():
		if game_controller != null and is_instance_valid(game_controller.map_gen):
			var r_cell = selected_resource_info.get("cell", Vector2i(-1, -1)) as Vector2i
			var r_type = selected_resource_info.get("type", "wood") as String
			var r_max = selected_resource_info.get("max_amount", 100)
			var cur = game_controller.map_gen.get_resource_at_cell(r_cell, r_type)
			var amt = cur.get("amount", 0) if not cur.is_empty() else 0
			entity_hp_bar.max_value = r_max
			entity_hp_bar.value = amt
			if amt <= 0:
				entity_hp_label.text = "TÜKENDİ (0 / %d)" % r_max
				entity_stats_label.text = "Bu kaynak tamamen tükendi."
			else:
				entity_hp_label.text = "Kalan: %d / %d" % [amt, r_max]
				entity_stats_label.text = "Doğal Kaynak • Bir köylü seçip dokunarak toplatabilirsiniz."

func _unit_type_name(unit: Unit3D) -> String:
	match unit.unit_type:
		Unit3D.UnitType.VILLAGER: return "İşçi (Köylü)"
		Unit3D.UnitType.SWORDSMAN: return "Kılıçlı Asker"
		Unit3D.UnitType.ARCHER: return "Okçu"
		Unit3D.UnitType.SPEARMAN: return "Mızrakçı"
		Unit3D.UnitType.CAVALRY: return "Akıncı Süvari"
	return CivData.get_civ(unit.civ_type).get("unique_unit_name", "Elit Asker")

const GROUP_SHORT := {"İşçi (Köylü)": "Köylü", "Kılıçlı Asker": "Kılıçlı", "Akıncı Süvari": "Süvari"}

## Several units selected: one summary instead of the first unit's card ("12 Birim", total hp, the make-up and
## what they are doing). Empty when one unit (or none) is selected.
func _group_summary() -> Dictionary:
	if game_controller == null or not ("selected_units" in game_controller):
		return {}
	var live: Array = game_controller.selected_units.filter(func(u): return is_instance_valid(u) and u.hp > 0)
	if live.size() <= 1:
		return {}
	var kinds := {}
	var kind_order: Array = []
	var hp := 0.0
	var hp_max := 0.0
	var idle := 0
	var fighting := 0
	var moving := 0
	for u in live:
		var n: String = _unit_type_name(u)
		n = GROUP_SHORT.get(n, n)
		if not kinds.has(n):
			kinds[n] = 0
			kind_order.append(n)
		kinds[n] += 1
		hp += u.hp
		hp_max += u.max_hp
		match u.state:
			Unit3D.State.IDLE: idle += 1
			Unit3D.State.ATTACKING: fighting += 1
			Unit3D.State.MOVING: moving += 1
	var parts: Array = []
	for n in kind_order:
		parts.append("%d %s" % [kinds[n], n])
	var doing: Array = []
	if fighting > 0: doing.append("%d savaşta" % fighting)
	if moving > 0: doing.append("%d yürüyor" % moving)
	if idle > 0: doing.append("%d boşta" % idle)
	var rest: int = live.size() - fighting - moving - idle
	if rest > 0: doing.append("%d çalışıyor" % rest)
	return {"count": live.size(), "hp": hp, "hp_max": hp_max, "makeup": " · ".join(parts), "doing": ", ".join(doing)}

func _apply_group_summary(g: Dictionary) -> void:
	entity_name_label.text = "%d Birim Seçili [Dost]" % g["count"]
	entity_hp_bar.max_value = g["hp_max"]
	entity_hp_bar.value = g["hp"]
	entity_hp_label.text = "%d / %d CAN (toplam)" % [int(g["hp"]), int(g["hp_max"])]
	entity_stats_label.text = "%s\n%s" % [g["makeup"], g["doing"]]

func _display_unit_ui(unit: Unit3D) -> void:
	if entity_portrait_rect != null:
		entity_portrait_rect.texture = FactionArtManager.get_unit_texture(unit.civ_type, unit.unit_type, "pose_01")
		entity_portrait_rect.visible = true

	var type_name := _unit_type_name(unit)
	entity_name_label.text = "%s [%s]" % [type_name, "Dost" if unit.team == 0 else "Düşman"]
	entity_hp_bar.max_value = unit.max_hp
	entity_hp_bar.value = unit.hp
	entity_hp_label.text = "%d / %d CAN" % [int(unit.hp), int(unit.max_hp)]
	entity_stats_label.text = "%s | Hasar: %d | Zırh: %d | Hız: %d" % [
		unit.get_task_description_turkish(),
		int(unit.attack_dmg),
		int(unit.armor),
		int(unit.move_speed)
	]
	var grp := _group_summary()
	if not grp.is_empty() and unit.team == 0:
		_apply_group_summary(grp)

	if unit.team == 0:
		# Army orders (Age of Empires style) when the selection holds soldiers: SALDIR / SAVUN arm the next tap
		var has_soldiers := unit.unit_type != Unit3D.UnitType.VILLAGER
		if game_controller != null and "selected_units" in game_controller:
			for su in game_controller.selected_units:
				if is_instance_valid(su) and su.unit_type != Unit3D.UnitType.VILLAGER:
					has_soldiers = true
		if has_soldiers:
			for cmd in [["⚔ SALDIR", "attack"], ["🛡 SAVUN", "defend"]]:
				var b := Button.new()
				b.text = cmd[0]
				b.custom_minimum_size = Vector2(120, 48)
				ParchmentTheme.apply_parchment_button(b, 13)
				var mode: String = cmd[1]
				b.pressed.connect(func(): army_command_requested.emit(mode))
				action_flow.add_child(b)
		var stop_btn = Button.new()
		stop_btn.text = "⏹ DUR"
		stop_btn.custom_minimum_size = Vector2(100, 48)
		ParchmentTheme.apply_parchment_button(stop_btn, 13)
		stop_btn.pressed.connect(func(): army_command_requested.emit("stop"))
		action_flow.add_child(stop_btn)

		if unit.unit_type == Unit3D.UnitType.VILLAGER:
			var build_btn = Button.new()
			build_btn.text = "🔨 İNŞA ET"
			build_btn.custom_minimum_size = Vector2(120, 48)
			ParchmentTheme.apply_parchment_button(build_btn, 13)
			build_btn.pressed.connect(func():
				build_panel.visible = not build_panel.visible
				if build_panel.visible:
					build_panel.offset_bottom = bottom_bar.offset_top - 6.0
			)
			action_flow.add_child(build_btn)

## Bar shown while a building is being placed: what is placed, how, and an "İptal" button.
var placement_bar: PanelContainer = null
var placement_label: Label = null

func show_placement_bar(on: bool, b_type: int = -1) -> void:
	if placement_bar == null:
		placement_bar = PanelContainer.new()
		placement_bar.name = "PlacementBar"
		# just above the bottom bar (kept there in _process); the top is taken by the tutorial line
		placement_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		placement_bar.offset_left = 10
		placement_bar.offset_right = -10
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.93, 0.86, 0.70, 0.96)
		sb.border_color = Color(0.40, 0.26, 0.12)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 10
		sb.content_margin_right = 6
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		placement_bar.add_theme_stylebox_override("panel", sb)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		placement_bar.add_child(row)
		placement_label = Label.new()
		placement_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		placement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		placement_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
		placement_label.add_theme_font_size_override("font_size", 14)
		placement_label.add_theme_color_override("font_color", Color(0.22, 0.13, 0.05))
		placement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(placement_label)
		var cancel := Button.new()
		cancel.name = "CancelPlacementButton"
		cancel.text = "✖ İPTAL"
		cancel.custom_minimum_size = Vector2(104, 44)
		ParchmentTheme.apply_parchment_button(cancel, 15)
		cancel.pressed.connect(func(): cancel_placement_requested.emit())
		row.add_child(cancel)
		hud_root.add_child(placement_bar)
	placement_bar.visible = on
	if on:
		set_placement_reason(b_type, "")

## Placement bar text: how to place, or (red) why the building can't go where the ghost is.
func set_placement_reason(b_type: int, reason: String) -> void:
	if placement_label == null:
		return
	if reason == "":
		placement_label.text = "%s: yerleştirmek için haritaya dokun" % _building_name(b_type)
		placement_label.add_theme_color_override("font_color", Color(0.22, 0.13, 0.05))
	else:
		placement_label.text = "%s: buraya yapılamaz. %s" % [_building_name(b_type), reason]
		placement_label.add_theme_color_override("font_color", Color(0.70, 0.08, 0.05))

static func _building_name(b_type: int) -> String:
	match b_type:
		Building3D.BuildingType.TOWN_CENTER: return "Ana Merkez"
		Building3D.BuildingType.HOUSE: return "Ev"
		Building3D.BuildingType.BARRACKS: return "Kışla"
		Building3D.BuildingType.ARCHERY_RANGE: return "Okçu Alanı"
		Building3D.BuildingType.STABLE: return "Ahır"
		Building3D.BuildingType.CASTLE: return "Büyük Kale"
		Building3D.BuildingType.TOWER: return "Kule"
		Building3D.BuildingType.BLACKSMITH: return "Demirci"
		Building3D.BuildingType.FARM: return "Tarla"
		Building3D.BuildingType.LUMBER_CAMP: return "Oduncu Kampı"
		Building3D.BuildingType.MINING_CAMP: return "Maden Kampı"
		Building3D.BuildingType.MILL: return "Değirmen"
	return "Bina"

## Construction site panel: crew size (updated live in _process), add a villager, cancel with refund.
var builders_label: Label = null

func _add_construction_controls(b: Building3D) -> void:
	if game_controller == null or not game_controller.has_method("get_site_builders"):
		return
	builders_label = Label.new()
	builders_label.name = "BuildersLabel"
	builders_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	builders_label.add_theme_font_size_override("font_size", 14)
	builders_label.add_theme_color_override("font_color", Color(0.22, 0.13, 0.05))
	builders_label.custom_minimum_size = Vector2(120, 48)
	builders_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_refresh_builders_label(b)
	action_flow.add_child(builders_label)
	var add := Button.new()
	add.name = "AddBuilderButton"
	add.text = "+ Köylü Ekle\n(en fazla %d)" % game_controller.MAX_BUILDERS
	add.custom_minimum_size = Vector2(150, 48)
	ParchmentTheme.apply_parchment_button(add, 13)
	add.pressed.connect(func(): add_builder_requested.emit())
	action_flow.add_child(add)
	var refund: Dictionary = game_controller.construction_refund(b)
	var parts: Array = []
	for k in ["wood", "stone", "gold"]:
		if int(refund.get(k, 0)) > 0:
			parts.append("%d %s" % [refund[k], {"wood": "Odun", "stone": "Taş", "gold": "Altın"}[k]])
	var cancel := Button.new()
	cancel.name = "CancelConstructionButton"
	cancel.text = "✖ İnşaatı İptal Et\n(iade: %s)" % (", ".join(parts) if not parts.is_empty() else "yok")
	cancel.custom_minimum_size = Vector2(190, 48)
	ParchmentTheme.apply_parchment_button(cancel, 12)
	cancel.pressed.connect(func(): cancel_construction_requested.emit())
	action_flow.add_child(cancel)

func _refresh_builders_label(b: Building3D) -> void:
	if is_instance_valid(builders_label) and game_controller != null:
		builders_label.text = "İnşaatçı: %d/%d" % [game_controller.get_site_builders(b).size(), game_controller.MAX_BUILDERS]

func _display_building_ui(b: Building3D) -> void:
	if entity_portrait_rect != null:
		var tex = FactionArtManager.get_building_texture(b.civ_type, b.building_type)
		if tex == null:
			tex = PixelArtTextures.get_building_icon_texture(b.building_type)
		entity_portrait_rect.texture = tex
		entity_portrait_rect.visible = true

	var name_str = "Bina"
	match b.building_type:
		Building3D.BuildingType.TOWN_CENTER: name_str = "Ana Merkez (Town Center)"
		Building3D.BuildingType.HOUSE: name_str = "Ev (+5 Nüfus)"
		Building3D.BuildingType.BARRACKS: name_str = "Kışla"
		Building3D.BuildingType.ARCHERY_RANGE: name_str = "Okçu Alanı"
		Building3D.BuildingType.STABLE: name_str = "Ahır"
		Building3D.BuildingType.CASTLE: name_str = "Büyük Kale"
		Building3D.BuildingType.TOWER: name_str = "Kule"
		Building3D.BuildingType.BLACKSMITH: name_str = "Demirci"
		Building3D.BuildingType.FARM: name_str = "Tarla"
		Building3D.BuildingType.LUMBER_CAMP: name_str = "Oduncu Kampı"
		Building3D.BuildingType.MINING_CAMP: name_str = "Maden Kampı"
		Building3D.BuildingType.MILL: name_str = "Değirmen (Çiftlik Merkezi)"

	if b.upgrade_level >= 2:
		name_str += " ★"
	entity_name_label.text = "%s [%s]" % [name_str, "Dost" if b.team == 0 else "Düşman"]
	entity_hp_bar.max_value = b.max_hp
	entity_hp_bar.value = b.hp
	entity_hp_label.text = "%d / %d CAN" % [int(b.hp), int(b.max_hp)]
	entity_stats_label.text = "Zırh: %d  |  %s" % [int(b.armor), "Aktif" if b.is_completed else "İnşaat Sürüyor..."]

	builders_label = null
	if b.team == 0 and not b.is_completed and b.building_type != Building3D.BuildingType.TOWN_CENTER:
		_add_construction_controls(b)

	if b.team == 0 and b.is_completed:
		match b.building_type:
			Building3D.BuildingType.TOWN_CENTER:
				_add_train_button("İşçi Eğit\n(50 Besin)", Unit3D.UnitType.VILLAGER)

			Building3D.BuildingType.MILL:
				if game_controller != null and game_controller.has_method("field_block_reason"):
					var n_fields: int = game_controller.get_mill_fields(b).size()
					var reason: String = game_controller.field_block_reason(b, 0)
					var cost: int = game_controller._get_building_cost(Building3D.BuildingType.FARM, 0)["wood"]
					if reason == "" or reason == "Yetersiz odun":
						_add_field_button("Tarla Aç (%d Odun)\nTarlalar %d/%d" % [cost, n_fields, game_controller.MAX_FIELDS_PER_MILL])
					else:
						_add_disabled_button("Tarla Aç\n%s (%d/%d)" % [reason, n_fields, game_controller.MAX_FIELDS_PER_MILL])

			Building3D.BuildingType.FARM:
				var farmer_txt := "Boş"
				if game_controller != null and game_controller.map_gen.farm_fields.has(b.origin_cell) \
						and not game_controller.map_gen.is_field_free_for(b.origin_cell, null):
					farmer_txt = "Çiftçi çalışıyor"
				_add_disabled_button("Tükenmez Besin\n%s" % farmer_txt)

			Building3D.BuildingType.BARRACKS:
				_add_train_button("Kılıçlı Asker\n(60 Besin, 20 Altın)", Unit3D.UnitType.SWORDSMAN)
				_add_train_button("Mızrakçı\n(50 Besin, 35 Odun)", Unit3D.UnitType.SPEARMAN)

			Building3D.BuildingType.ARCHERY_RANGE:
				_add_train_button("Okçu\n(45 Odun, 40 Altın)", Unit3D.UnitType.ARCHER)

			Building3D.BuildingType.STABLE:
				_add_train_button("Akıncı Süvari\n(75 Besin, 60 Altın)", Unit3D.UnitType.CAVALRY)
				var player_age = game_controller.team_age[0] if game_controller != null and game_controller.team_age.has(0) else 1
				if player_age >= 2:
					_add_train_button("Şövalye\n(90 Besin, 75 Altın)", Unit3D.UnitType.PALADIN)

			Building3D.BuildingType.CASTLE:
				var civ_cfg = CivData.get_civ(b.civ_type)
				var u_name = civ_cfg.get("unique_unit_name", "Özel Asker")
				var u_type_str = civ_cfg.get("unique_unit_type", "JANISSARY")
				var u_enum = Unit3D.UnitType.JANISSARY
				match u_type_str:
					"JANISSARY": u_enum = Unit3D.UnitType.JANISSARY
					"CATAPHRACT": u_enum = Unit3D.UnitType.CATAPHRACT
					"LONGBOWMAN": u_enum = Unit3D.UnitType.LONGBOWMAN
					"PALADIN": u_enum = Unit3D.UnitType.PALADIN
					"MANGUDAI": u_enum = Unit3D.UnitType.MANGUDAI
					"TEUTONIC_KNIGHT": u_enum = Unit3D.UnitType.TEUTONIC_KNIGHT
					"SAMURAI": u_enum = Unit3D.UnitType.SAMURAI
					"MAMELUKE": u_enum = Unit3D.UnitType.MAMELUKE
					"BERSERKER": u_enum = Unit3D.UnitType.BERSERKER
					"CHUKONU": u_enum = Unit3D.UnitType.CHUKONU
				_add_train_button("%s\n(80 Besin, 60 Altın)" % u_name, u_enum)

		# This building's own technologies / upgrades (TechData)
		_add_tech_buttons(b)

		# the training / research queue is shown live in queue_bar (ProductionQueueBar) above the panel

func _add_train_button(label: String, u_type: Unit3D.UnitType) -> void:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(145, 48)
	ParchmentTheme.apply_parchment_button(btn, 13)
	btn.pressed.connect(func():
		train_unit_requested.emit(u_type)
	)
	action_flow.add_child(btn)

func _add_research_button(label: String, tech_id: String) -> void:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(215, 48)
	ParchmentTheme.apply_parchment_button(btn, 12)
	btn.pressed.connect(func():
		research_requested.emit(tech_id)
		# Re-render UI after clicking
		if is_instance_valid(selected_entity) and selected_entity is Building3D:
			set_selected_entity(selected_entity)
	)
	action_flow.add_child(btn)

func _add_tech_buttons(b: Building3D) -> void:
	if game_controller == null or not game_controller.has_method("research_block_reason"):
		return
	for id in TechData.techs_for_building(b.building_type):
		var t: Dictionary = TechData.get_tech(id)
		var reason: String = game_controller.research_block_reason(b, id, 0)
		if reason == "Zaten geçildi":
			continue                                  # e.g. Age II once in Age III
		if reason == "Zaten geliştirildi":
			if not id.begins_with("AGE_"):
				_add_disabled_button("%s ✓\n%s" % [t["name"], t["desc"]])
			elif int(game_controller.team_age.get(0, 1)) >= 3:
				_add_disabled_button("%s ✓" % TechData.age_name(3))
			continue
		if b.is_researching and b.current_research_tech == id:
			_add_disabled_button("%s\nAraştırılıyor (süre üstte)" % t["name"])
		elif reason == "" or reason == "Yetersiz kaynak":
			_add_research_button("%s\n%s (%s)" % [t["name"], t["desc"], TechData.cost_text(id)], id)
		else:
			_add_disabled_button("%s\n%s" % [t["name"], reason])

func _add_field_button(label: String) -> void:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(215, 48)
	ParchmentTheme.apply_parchment_button(btn, 12)
	btn.pressed.connect(func(): field_requested.emit())
	action_flow.add_child(btn)

func _add_disabled_button(label: String) -> void:
	var btn = Button.new()
	btn.text = label
	btn.disabled = true
	btn.custom_minimum_size = Vector2(150, 48)
	ParchmentTheme.apply_parchment_button(btn, 12)
	btn.modulate = Color(0.7, 0.7, 0.7, 0.7)
	action_flow.add_child(btn)

var drag_box_panel: Panel = null

func draw_drag_box(p1: Vector2, p2: Vector2) -> void:
	if drag_box_panel == null:
		drag_box_panel = Panel.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.6, 1.0, 0.18)
		sb.border_color = Color(0.95, 0.85, 0.4, 0.85)
		sb.set_border_width_all(2)
		drag_box_panel.add_theme_stylebox_override("panel", sb)
		drag_box_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud_root.add_child(drag_box_panel)

	var min_x = min(p1.x, p2.x)
	var max_x = max(p1.x, p2.x)
	var min_y = min(p1.y, p2.y)
	var max_y = max(p1.y, p2.y)
	drag_box_panel.position = Vector2(min_x, min_y)
	drag_box_panel.size = Vector2(max_x - min_x, max_y - min_y)
	drag_box_panel.visible = true

func hide_drag_box() -> void:
	if drag_box_panel != null:
		drag_box_panel.visible = false

## ---- messages ----------------------------------------------------------------------------------------
## One stack under the top bar, left of the minimap, so nothing runs off the portrait screen or overlaps:
##   hint card   - the tutorial step (stays until the step changes)
##   order card  - "SALDIR / SAVUN: tap a spot" while an army order is armed (stays until it is used)
##   toast       - short notices (one at a time, the newest replaces the old one, fades after ~3 s)
var msg_stack: VBoxContainer = null
var hint_card: PanelContainer = null
var hint_title: Label = null
var hint_body: Label = null
var order_card: PanelContainer = null
var order_label: Label = null
var toast_card: PanelContainer = null
var toast_label: Label = null
var _toast_tween: Tween = null

func _msg_panel(bg: Color, border: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10; sb.content_margin_right = 10
	sb.content_margin_top = 6; sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.visible = false
	return p

func _msg_label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _build_message_stack() -> void:
	if msg_stack != null:
		return
	msg_stack = VBoxContainer.new()
	msg_stack.name = "MessageStack"
	msg_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg_stack.add_theme_constant_override("separation", 6)
	msg_stack.anchor_left = 0.0; msg_stack.anchor_right = 1.0
	msg_stack.offset_left = 10; msg_stack.offset_right = -128      # the minimap column stays clear
	msg_stack.offset_top = 80
	hud_root.add_child(msg_stack)
	hint_card = _msg_panel(Color(0.16, 0.11, 0.06, 0.88), Color(0.86, 0.66, 0.30))
	hint_card.name = "HintCard"
	var hv := VBoxContainer.new()
	hv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hv.add_theme_constant_override("separation", 2)
	hint_title = _msg_label(15, Color(1.0, 0.86, 0.45))
	hint_body = _msg_label(13, Color(0.95, 0.90, 0.80))
	hv.add_child(hint_title)
	hv.add_child(hint_body)
	hint_card.add_child(hv)
	msg_stack.add_child(hint_card)
	order_card = _msg_panel(Color(0.30, 0.06, 0.05, 0.90), Color(1.0, 0.55, 0.45))
	order_card.name = "OrderCard"
	order_label = _msg_label(15, Color(1.0, 0.93, 0.88))
	order_card.add_child(order_label)
	msg_stack.add_child(order_card)
	toast_card = _msg_panel(Color(0.08, 0.07, 0.06, 0.85), Color(0.55, 0.45, 0.30))
	toast_card.name = "ToastCard"
	toast_label = _msg_label(14, Color.WHITE)
	toast_card.add_child(toast_label)
	msg_stack.add_child(toast_card)

## Short notice; the newest replaces the one on screen.
func notify_banner(message: String, col: Color = Color.WHITE) -> void:
	_build_message_stack()
	toast_label.text = message
	toast_label.add_theme_color_override("font_color", col)
	toast_card.visible = true
	toast_card.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = toast_card.create_tween()
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(toast_card, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(func(): toast_card.visible = false)

## Persistent hint card (tutorial step). The first line is the title, the rest the body. Empty hides it.
func show_hint(text: String) -> void:
	_build_message_stack()
	if text == "":
		hint_card.visible = false
		return
	var parts := text.split("\n", true, 1)
	hint_title.text = parts[0]
	hint_body.text = parts[1] if parts.size() > 1 else ""
	hint_body.visible = hint_body.text != ""
	hint_card.visible = true

func hide_hint() -> void:
	if hint_card != null:
		hint_card.visible = false

func _update_message_stack() -> void:
	if msg_stack == null:
		return
	var tb := hud_root.get_node_or_null("TopBar") as Control
	if tb != null:
		msg_stack.offset_top = tb.position.y + tb.size.y + 6
	var mode := ""
	if game_controller != null and "pending_army_command" in game_controller:
		mode = game_controller.pending_army_command
	order_card.visible = mode != ""
	if mode == "attack":
		order_label.text = "SALDIR: bir yere ya da bir düşmana dokun"
	elif mode == "defend":
		order_label.text = "SAVUN: savunulacak yere dokun"

func show_game_over(victory: bool, stats: Dictionary) -> void:
	game_over_modal.visible = true
	var title = game_over_modal.get_node("VBox/TitleLabel") as Label
	var desc = game_over_modal.get_node("VBox/DescLabel") as Label

	if victory:
		title.text = "ZAFER KAZANDIN!"
		title.modulate = Color(0.25, 0.95, 0.35)
	else:
		title.text = "BOZGUNA UĞRADIN!"
		title.modulate = Color(0.95, 0.25, 0.25)

	desc.text = "Geçen Süre: %s\nYok Edilen Düşman: %d\nEğitilen Asker: %d\nToplanan Kaynak: %d" % [
		stats.get("duration", "02:15"),
		stats.get("kills", 0),
		stats.get("trained", 0),
		stats.get("gathered", 0)
	]
