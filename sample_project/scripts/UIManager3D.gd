class_name UIManager3D
extends CanvasLayer

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")

signal start_game_requested(player_civ, enemy_civ, map_type)
signal build_selected(building_type)
signal train_unit_requested(unit_type)
signal research_requested(tech_id)
signal select_all_military_requested
signal jump_to_base_requested
signal find_idle_villager_requested
signal clear_selection_requested
signal toggle_speed_requested
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
signal zoom_in_requested
signal zoom_out_requested

# Build Tray Panel
@onready var build_panel: PanelContainer = $HUDRoot/BuildPanel
@onready var build_grid: GridContainer = $HUDRoot/BuildPanel/VBox/Scroll/BuildGrid
@onready var close_build_btn: Button = $HUDRoot/BuildPanel/VBox/Header/CloseBuildButton

# Restart modal
@onready var restart_btn: Button = $GameOverModal/VBox/RestartButton

var selected_entity: Node3D = null

const BOTTOM_BAR_COMPACT_TOP: float = -105.0
const BOTTOM_BAR_EXPANDED_TOP: float = -235.0

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

func _setup_build_grid() -> void:
	for child in build_grid.get_children():
		child.queue_free()

	var buildings_list = [
		{"type": Building3D.BuildingType.HOUSE, "label": "EV\n30 Odun", "desc": "+5 Nüfus Limiti"},
		{"type": Building3D.BuildingType.BARRACKS, "label": "KIŞLA\n150 Odun", "desc": "Piyade ve Mızrakçı"},
		{"type": Building3D.BuildingType.ARCHERY_RANGE, "label": "OKÇU ALANI\n150 Odun", "desc": "Menzilli Birlikler"},
		{"type": Building3D.BuildingType.STABLE, "label": "AHIR\n175 Odun", "desc": "Hızlı Süvariler"},
		{"type": Building3D.BuildingType.BLACKSMITH, "label": "DEMİRCİ\n150 Odun", "desc": "Zırh ve Silah Geliştirmesi"},
		{"type": Building3D.BuildingType.TOWER, "label": "KULE\n75 Odun | 125 Taş", "desc": "Savunma Kulesi"},
		{"type": Building3D.BuildingType.FARM, "label": "ÇİFTLİK\n60 Odun", "desc": "Sürekli Besin Üretimi"},
		{"type": Building3D.BuildingType.CASTLE, "label": "BÜYÜK KALE\n200 Odun | 350 Taş | 150 Altın", "desc": "Çağ II & Krallık Elit Birimi"}
	]

	for item in buildings_list:
		var btn = Button.new()
		btn.text = " %s\n(%s)" % [item["label"], item["desc"]]
		btn.icon = PixelArtTextures.get_building_icon_texture(item["type"])
		btn.expand_icon = true
		btn.custom_minimum_size = Vector2(236, 56)
		ParchmentTheme.apply_parchment_button(btn, 12)
		btn.pressed.connect(func():
			build_selected.emit(item["type"])
			build_panel.visible = false
		)
		build_grid.add_child(btn)

func set_player_civ(c_type: CivData.CivType) -> void:
	var cfg = CivData.get_civ(c_type)
	if civ_label:
		civ_label.text = cfg.get("name", "Osmanlılar")
	if civ_flag_rect:
		civ_flag_rect.texture = PixelArtTextures.get_civ_flag_texture(c_type)

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
	build_panel.visible = false

	for child in action_flow.get_children():
		child.queue_free()

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

func _reset_context_deck() -> void:
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
		entity_portrait_rect.texture = PixelArtTextures.get_building_icon_texture(b.building_type)
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
		Building3D.BuildingType.FARM: name_str = "Çiftlik"

	entity_name_label.text = "%s [%s]" % [name_str, "Dost" if b.team == 0 else "Düşman"]
	entity_hp_bar.max_value = b.max_hp
	entity_hp_bar.value = b.hp
	entity_hp_label.text = "%d / %d CAN" % [int(b.hp), int(b.max_hp)]
	entity_stats_label.text = "Zırh: %d  |  %s" % [int(b.armor), "Aktif" if b.is_completed else "İnşaat Sürüyor..."]

	if b.team == 0 and b.is_completed:
		match b.building_type:
			Building3D.BuildingType.TOWN_CENTER:
				_add_train_button("İşçi Eğit\n(50 Besin)", Unit3D.UnitType.VILLAGER)
				var player_age = game_controller.team_age[0] if game_controller != null and game_controller.team_age.has(0) else 1
				if player_age == 1:
					if b.is_researching and b.current_research_tech == "AGE_2":
						_add_disabled_button("Hisar Çağı\nAraştırılıyor (%%%d)" % int(b.get_research_progress()))
					else:
						_add_research_button("Çağ II: Hisar Çağı\n(500 Besin, 200 Altın)", "AGE_2")
				else:
					_add_disabled_button("Hisar Çağı ✓\n(Maksimum)")

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

			Building3D.BuildingType.BLACKSMITH:
				var techs = game_controller.team_techs[0] if game_controller != null and game_controller.team_techs.has(0) else {}
				if techs.get("iron_weapons", false):
					_add_disabled_button("Demir Silahlar ✓\n(+3 Piyade)")
				elif b.is_researching and b.current_research_tech == "iron_weapons":
					_add_disabled_button("Demir Silahlar\n(%%%d)" % int(b.get_research_progress()))
				else:
					_add_research_button("Demir Silahlar\n(100 Besin, 40 Altın)", "iron_weapons")

				if techs.get("scale_armor", false):
					_add_disabled_button("Takviyeli Zırh ✓\n(+2 Zırh)")
				elif b.is_researching and b.current_research_tech == "scale_armor":
					_add_disabled_button("Takviyeli Zırh\n(%%%d)" % int(b.get_research_progress()))
				else:
					_add_research_button("Takviyeli Zırh\n(100 Besin, 40 Altın)", "scale_armor")

				if techs.get("bodkin_arrows", false):
					_add_disabled_button("Demir Oklar ✓\n(+3 Okçu)")
				elif b.is_researching and b.current_research_tech == "bodkin_arrows":
					_add_disabled_button("Demir Oklar\n(%%%d)" % int(b.get_research_progress()))
				else:
					_add_research_button("Demir Oklar\n(100 Odun, 50 Altın)", "bodkin_arrows")

				if techs.get("wheelbarrow", false):
					_add_disabled_button("El Arabası ✓\n(20 Yük +%15 Hız)")
				elif b.is_researching and b.current_research_tech == "wheelbarrow":
					_add_disabled_button("El Arabası\n(%%%d)" % int(b.get_research_progress()))
				else:
					_add_research_button("El Arabası\n(100 Odun, 50 Besin)", "wheelbarrow")

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

func notify_banner(message: String, col: Color = Color.WHITE) -> void:
	var banner = Label.new()
	banner.text = message
	banner.add_theme_font_override("font", ParchmentTheme.get_serif_font(18, true))
	banner.add_theme_color_override("font_color", col)
	banner.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 0.95))
	banner.add_theme_constant_override("outline_size", 4)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position = Vector2(hud_root.size.x * 0.5 - 200, 70)
	banner.size = Vector2(400, 40)
	hud_root.add_child(banner)
	
	var tween = banner.create_tween()
	tween.tween_property(banner, "position:y", 50.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.5)
	tween.tween_property(banner, "modulate:a", 0.0, 0.6)
	tween.tween_callback(banner.queue_free)

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
