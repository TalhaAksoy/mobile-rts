class_name UIManager3D
extends CanvasLayer

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

signal start_game_requested(player_civ, enemy_civ, map_type)
signal build_selected(building_type)
signal train_unit_requested(unit_type)
signal research_requested(tech_id)
signal field_requested
signal select_all_military_requested
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
				notify_banner("Kutu seçimi açık: sürükleyerek birlik seç", Color(0.3, 0.7, 0.35))
			else:
				box_select_btn.modulate = Color(1.0, 1.0, 1.0)
				notify_banner("Kutu seçimi kapalı")
		)

	build_main_btn.text = "İnşaat"
	army_btn.text = "Ordu"
	base_btn.text = "Ana Üs"
	idle_villager_btn.text = "Boşta"
	close_build_btn.text = "Kapat"
	restart_btn.text = "Yeniden Oyna"
	var build_title := get_node_or_null("HUDRoot/BuildPanel/VBox/Header/BuildTitle") as Label
	if build_title != null:
		build_title.text = "İnşaat"
		build_title.add_theme_font_override("font", ParchmentTheme.get_cinzel_font())
		build_title.add_theme_font_size_override("font_size", 19)
		build_title.add_theme_color_override("font_color", ParchmentTheme.INK_DARK)
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
	game_over_menu_btn.text = "Ana Menü"
	game_over_menu_btn.custom_minimum_size = Vector2(0, 50)
	ParchmentTheme.apply_parchment_button(game_over_menu_btn, 16)
	restart_btn.text = "Yeniden Oyna"
	restart_btn.custom_minimum_size = Vector2(0, 54)
	ParchmentTheme.apply_primary_button(restart_btn, 19)
	game_over_modal.add_theme_stylebox_override("panel", ParchmentTheme.panel_style(0.98, 12, 24))
	game_over_modal.offset_left = -200
	game_over_modal.offset_right = 200
	(restart_btn.get_parent() as VBoxContainer).add_theme_constant_override("separation", 10)
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
		{"type": Building3D.BuildingType.HOUSE, "label": "Ev", "cost": "30 odun", "desc": "+5 nüfus"},
		{"type": Building3D.BuildingType.LUMBER_CAMP, "label": "Oduncu Kampı", "cost": "100 odun", "desc": "Odun teslim yeri"},
		{"type": Building3D.BuildingType.MINING_CAMP, "label": "Maden Kampı", "cost": "100 odun", "desc": "Altın ve taş teslim yeri"},
		{"type": Building3D.BuildingType.MILL, "label": "Değirmen", "cost": "100 odun", "desc": "Besin teslimi, tarla açar"},
		{"type": Building3D.BuildingType.BARRACKS, "label": "Kışla", "cost": "150 odun", "desc": "Kılıçlı ve mızrakçı"},
		{"type": Building3D.BuildingType.ARCHERY_RANGE, "label": "Okçu Alanı", "cost": "150 odun", "desc": "Okçular"},
		{"type": Building3D.BuildingType.STABLE, "label": "Ahır", "cost": "175 odun", "desc": "Süvariler"},
		{"type": Building3D.BuildingType.BLACKSMITH, "label": "Demirci", "cost": "150 odun", "desc": "Silah ve zırh"},
		{"type": Building3D.BuildingType.TOWER, "label": "Kule", "cost": "75 odun · 125 taş", "desc": "Savunma"},
		{"type": Building3D.BuildingType.CASTLE, "label": "Kale", "cost": "200 odun · 350 taş · 150 altın", "desc": "Çağ II, krallığın elit birimi"}
	]

	for item in buildings_list:
		var btn = Button.new()
		btn.text = "%s · %s\n%s" % [item["label"], item["cost"], item["desc"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
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
	if civ_label:
		civ_label.text = cfg.get("name", "Osmanlılar")
	if civ_flag_rect:
		civ_flag_rect.texture = PixelArtTextures.get_civ_flag_texture(c_type)
	_setup_build_grid()

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
	if queue_bar != null:
		queue_bar.offset_bottom = bottom_bar.offset_top - 6.0
		queue_bar.offset_top = queue_bar.offset_bottom - queue_bar.get_combined_minimum_size().y
	if is_instance_valid(selected_entity):
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

func _display_unit_ui(unit: Unit3D) -> void:
	if entity_portrait_rect != null:
		entity_portrait_rect.texture = FactionArtManager.get_unit_texture(unit.civ_type, unit.unit_type, "pose_01")
		entity_portrait_rect.visible = true

	var type_name = "Birim"
	match unit.unit_type:
		Unit3D.UnitType.VILLAGER: type_name = "İşçi (Köylü)"
		Unit3D.UnitType.SWORDSMAN: type_name = "Kılıçlı Asker"
		Unit3D.UnitType.ARCHER: type_name = "Okçu"
		Unit3D.UnitType.SPEARMAN: type_name = "Mızrakçı"
		Unit3D.UnitType.CAVALRY: type_name = "Akıncı Süvari"
		_:
			var civ_cfg = CivData.get_civ(unit.civ_type)
			type_name = civ_cfg.get("unique_unit_name", "Elit Asker")

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

	if unit.team == 0:
		var stop_btn = Button.new()
		stop_btn.text = "⏹ DURDUR"
		stop_btn.custom_minimum_size = Vector2(110, 48)
		ParchmentTheme.apply_parchment_button(stop_btn, 13)
		stop_btn.pressed.connect(func(): unit.command_stop())
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

## Left column under the top bar (left of the minimap): the tutorial objective card, then short
## notices. The old banner was a fixed 400 px label at y = 50-70 over the top bar: two-line tutorial
## texts overflowed it and banners fired close together were drawn on top of each other.
var hud_column: VBoxContainer = null
var objective_card: PanelContainer = null
var objective_step_label: Label = null
var objective_title_label: Label = null
var objective_desc_label: Label = null
var toast_stack: VBoxContainer = null
signal objective_dismissed
const MAX_TOASTS := 3

func _ensure_hud_column() -> void:
	if hud_column != null and is_instance_valid(hud_column):
		return
	hud_column = VBoxContainer.new()
	hud_column.name = "HudColumn"
	hud_column.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_column.offset_left = 10
	hud_column.offset_right = -128      # the minimap sits on the right
	hud_column.offset_top = 80
	hud_column.offset_bottom = 400
	hud_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_column.add_theme_constant_override("separation", 6)
	hud_root.add_child(hud_column)

	objective_card = PanelContainer.new()
	objective_card.name = "ObjectiveCard"
	objective_card.visible = false
	objective_card.mouse_filter = Control.MOUSE_FILTER_IGNORE   # taps go through to the map, except on ×
	objective_card.add_theme_stylebox_override("panel", ParchmentTheme._sb(Color(0.97, 0.94, 0.87, 0.94), ParchmentTheme.HAIRLINE, 1, 10, 12, 10))
	hud_column.add_child(objective_card)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	objective_card.add_child(row)
	var txt := VBoxContainer.new()
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.add_theme_constant_override("separation", 1)
	row.add_child(txt)
	objective_step_label = ParchmentTheme.section_label("")
	objective_step_label.add_theme_font_size_override("font_size", 10)
	txt.add_child(objective_step_label)
	objective_title_label = Label.new()
	objective_title_label.add_theme_font_override("font", ParchmentTheme.get_body_bold_font())
	objective_title_label.add_theme_font_size_override("font_size", 15)
	objective_title_label.add_theme_color_override("font_color", ParchmentTheme.INK_DARK)
	objective_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.add_child(objective_title_label)
	objective_desc_label = ParchmentTheme.body_label("", 13, true)
	txt.add_child(objective_desc_label)
	var close := Button.new()
	close.name = "DismissObjective"
	close.text = "×"
	close.tooltip_text = "Öğreticiyi gizle"
	ParchmentTheme.apply_ghost_button(close, 20)
	close.custom_minimum_size = Vector2(36, 36)
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.pressed.connect(func():
		hide_objective()
		objective_dismissed.emit())
	row.add_child(close)

	toast_stack = VBoxContainer.new()
	toast_stack.name = "ToastStack"
	toast_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_stack.add_theme_constant_override("separation", 4)
	hud_column.add_child(toast_stack)

## Tutorial step card ("GÖREV 2/8", title, what to do). Stays until the next step or dismissed.
func show_objective(step_text: String, title: String, desc: String) -> void:
	_ensure_hud_column()
	objective_step_label.text = step_text.to_upper()
	objective_title_label.text = title
	objective_desc_label.text = desc
	objective_desc_label.visible = desc != ""
	objective_card.visible = true

func hide_objective() -> void:
	if objective_card != null and is_instance_valid(objective_card):
		objective_card.visible = false

## Short notice under the objective card; fades after a few seconds. `col` tints the left accent.
func notify_banner(message: String, col: Color = Color.WHITE) -> void:
	_ensure_hud_column()
	while toast_stack.get_child_count() >= MAX_TOASTS:
		var old := toast_stack.get_child(0)
		toast_stack.remove_child(old)
		old.queue_free()
	var toast := PanelContainer.new()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := ParchmentTheme._sb(Color(0.13, 0.10, 0.07, 0.88), Color(0, 0, 0, 0), 0, 8, 12, 7)
	sb.border_width_left = 3
	sb.border_color = col if col != Color.WHITE else ParchmentTheme.BRONZE_GOLD
	toast.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = message
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_override("font", ParchmentTheme.get_body_bold_font())
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", ParchmentTheme.ON_DARK)
	toast.add_child(lbl)
	toast_stack.add_child(toast)
	toast.modulate.a = 0.0
	var tween = toast.create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.18)
	tween.tween_interval(2.6)
	tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(toast.queue_free)

func show_game_over(victory: bool, stats: Dictionary) -> void:
	game_over_modal.visible = true
	var title = game_over_modal.get_node("VBox/TitleLabel") as Label
	var desc = game_over_modal.get_node("VBox/DescLabel") as Label

	title.add_theme_font_override("font", ParchmentTheme.get_cinzel_font())
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color(1, 1, 1)
	if victory:
		title.text = "Zafer"
		title.add_theme_color_override("font_color", Color(0.20, 0.42, 0.18))
	else:
		title.text = "Yenilgi"
		title.add_theme_color_override("font_color", Color(0.55, 0.16, 0.11))
	desc.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", ParchmentTheme.INK_DARK)
	desc.add_theme_constant_override("line_spacing", 4)

	desc.text = "Süre  %s\nYok edilen düşman  %d\nEğitilen birim  %d\nToplanan kaynak  %d" % [
		stats.get("duration", "02:15"),
		stats.get("kills", 0),
		stats.get("trained", 0),
		stats.get("gathered", 0)
	]
