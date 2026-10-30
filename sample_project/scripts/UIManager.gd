class_name UIManager
extends CanvasLayer

signal start_game_requested(player_civ, enemy_civ, map_type)
signal build_selected(building_type)
signal train_unit_requested(unit_type)
signal select_all_military_requested
signal jump_to_base_requested
signal find_idle_villager_requested
signal toggle_speed_requested
signal restart_requested

@onready var menu_root: Control = $MenuRoot
@onready var hud_root: Control = $HUDRoot
@onready var game_over_modal: Control = $GameOverModal

# HUD Top Bar Elements
@onready var food_label: Label = $HUDRoot/TopBar/HBox/ResContainer/FoodLabel
@onready var wood_label: Label = $HUDRoot/TopBar/HBox/ResContainer/WoodLabel
@onready var gold_label: Label = $HUDRoot/TopBar/HBox/ResContainer/GoldLabel
@onready var pop_label: Label = $HUDRoot/TopBar/HBox/ResContainer/PopLabel
@onready var civ_label: Label = $HUDRoot/TopBar/HBox/CivLabel
@onready var speed_btn: Button = $HUDRoot/TopBar/HBox/SpeedButton
@onready var idle_villager_btn: Button = $HUDRoot/TopBar/HBox/IdleVillagerButton

# HUD Bottom Deck
@onready var bottom_deck: PanelContainer = $HUDRoot/BottomDeck
@onready var selection_info: VBoxContainer = $HUDRoot/BottomDeck/HBox/SelectionInfo
@onready var entity_name_label: Label = $HUDRoot/BottomDeck/HBox/SelectionInfo/EntityNameLabel
@onready var entity_hp_bar: ProgressBar = $HUDRoot/BottomDeck/HBox/SelectionInfo/HPBar
@onready var entity_stats_label: Label = $HUDRoot/BottomDeck/HBox/SelectionInfo/StatsLabel
@onready var action_buttons_grid: GridContainer = $HUDRoot/BottomDeck/HBox/ActionGrid

# Build Menu Overlay
@onready var build_panel: PanelContainer = $HUDRoot/BuildPanel
@onready var build_grid: GridContainer = $HUDRoot/BuildPanel/VBox/BuildGrid

# Quick floating utility buttons
@onready var army_btn: Button = $HUDRoot/QuickButtons/ArmyButton
@onready var base_btn: Button = $HUDRoot/QuickButtons/BaseButton

# Restart modal button
@onready var restart_btn: Button = $GameOverModal/VBox/RestartButton

var selected_entity: Node2D = null

func _ready() -> void:
	hud_root.visible = false
	game_over_modal.visible = false
	menu_root.visible = true
	build_panel.visible = false
	bottom_deck.visible = false
	
	if menu_root.has_signal("start_game"):
		menu_root.start_game.connect(func(p, e, m): start_game_requested.emit(p, e, m))
		
	speed_btn.pressed.connect(func(): toggle_speed_requested.emit())
	idle_villager_btn.pressed.connect(func(): find_idle_villager_requested.emit())
	army_btn.pressed.connect(func(): select_all_military_requested.emit())
	base_btn.pressed.connect(func(): jump_to_base_requested.emit())
	restart_btn.pressed.connect(func(): restart_requested.emit())
	
	_setup_build_grid()

func _setup_build_grid() -> void:
	for child in build_grid.get_children():
		child.queue_free()
		
	var buildings_list = [
		{"type": Building.BuildingType.HOUSE, "label": "🏠 Ev\n(30🪵)", "desc": "+5 Nüfus"},
		{"type": Building.BuildingType.BARRACKS, "label": "⚔️ Kışla\n(150🪵)", "desc": "Piyade"},
		{"type": Building.BuildingType.ARCHERY_RANGE, "label": "🏹 Okçu\n(150🪵)", "desc": "Menzilli"},
		{"type": Building.BuildingType.STABLE, "label": "🐎 Ahır\n(175🪵)", "desc": "Süvari"},
		{"type": Building.BuildingType.CASTLE, "label": "🏰 Kale\n(350🪵 250🪙)", "desc": "Özel Birim"},
		{"type": Building.BuildingType.TOWER, "label": "🗼 Kule\n(125🪵 50🪙)", "desc": "Savunma"},
		{"type": Building.BuildingType.FARM, "label": "🌾 Çiftlik\n(60🪵)", "desc": "Sonsuz Besin"}
	]
	
	for item in buildings_list:
		var btn = Button.new()
		btn.text = item["label"]
		btn.custom_minimum_size = Vector2(90, 52)
		btn.pressed.connect(func():
			build_selected.emit(item["type"])
		)
		build_grid.add_child(btn)

func update_resources(food: int, wood: int, gold: int, pop: int, max_pop: int) -> void:
	food_label.text = "🌾 %d" % food
	wood_label.text = "🪵 %d" % wood
	gold_label.text = "🪙 %d" % gold
	pop_label.text = "👥 %d/%d" % [pop, max_pop]

func update_idle_villager_count(count: int) -> void:
	idle_villager_btn.visible = count > 0
	idle_villager_btn.text = "⚠️ Boşta: %d" % count

func set_selected_entity(entity: Node2D) -> void:
	selected_entity = entity
	build_panel.visible = false
	
	for child in action_buttons_grid.get_children():
		child.queue_free()
		
	if not is_instance_valid(entity):
		bottom_deck.visible = false
		return
		
	bottom_deck.visible = true
	
	if entity is Unit:
		_display_unit_ui(entity)
	elif entity is Building:
		_display_building_ui(entity)

func _display_unit_ui(unit: Unit) -> void:
	var type_name = "Birim"
	match unit.unit_type:
		Unit.UnitType.VILLAGER: type_name = "İşçi (Köylü)"
		Unit.UnitType.SWORDSMAN: type_name = "Kılıçlı Asker"
		Unit.UnitType.ARCHER: type_name = "Okçu"
		Unit.UnitType.SPEARMAN: type_name = "Mızrakçı"
		Unit.UnitType.CAVALRY: type_name = "Akıncı Süvari"
		_:
			var civ_cfg = CivData.get_civ(unit.civ_type)
			type_name = civ_cfg.get("unique_unit_name", "Elit Asker")

	entity_name_label.text = "%s [%s]" % [type_name, "Dost" if unit.team == 0 else "Düşman"]
	entity_hp_bar.max_value = unit.max_hp
	entity_hp_bar.value = unit.hp
	entity_stats_label.text = "⚔️ %d | 🛡️ %d | 🏃 %d" % [int(unit.attack_dmg), int(unit.armor), int(unit.move_speed)]

	if unit.team == 0:
		var stop_btn = Button.new()
		stop_btn.text = "🛑 Dur"
		stop_btn.custom_minimum_size = Vector2(75, 42)
		stop_btn.pressed.connect(func(): unit.command_stop())
		action_buttons_grid.add_child(stop_btn)
		
		if unit.unit_type == Unit.UnitType.VILLAGER:
			var build_btn = Button.new()
			build_btn.text = "🔨 Yap"
			build_btn.custom_minimum_size = Vector2(85, 42)
			build_btn.pressed.connect(func():
				build_panel.visible = not build_panel.visible
			)
			action_buttons_grid.add_child(build_btn)

func _display_building_ui(b: Building) -> void:
	var name_str = "Bina"
	match b.building_type:
		Building.BuildingType.TOWN_CENTER: name_str = "Ana Merkez"
		Building.BuildingType.HOUSE: name_str = "Ev (+5 Pop)"
		Building.BuildingType.BARRACKS: name_str = "Kışla"
		Building.BuildingType.ARCHERY_RANGE: name_str = "Okçu Alanı"
		Building.BuildingType.STABLE: name_str = "Ahır"
		Building.BuildingType.CASTLE: name_str = "Büyük Kale"
		Building.BuildingType.TOWER: name_str = "Kule"
		Building.BuildingType.FARM: name_str = "Çiftlik"

	entity_name_label.text = "%s [%s]" % [name_str, "Dost" if b.team == 0 else "Düşman"]
	entity_hp_bar.max_value = b.max_hp
	entity_hp_bar.value = b.hp
	entity_stats_label.text = "🛡️ Zırh: %d | %s" % [int(b.armor), "Hazır" if b.is_completed else "İnşaatta..."]

	if b.team == 0 and b.is_completed:
		match b.building_type:
			Building.BuildingType.TOWN_CENTER:
				_add_train_button("👨‍🌾 İşçi (50🌾)", Unit.UnitType.VILLAGER)
			Building.BuildingType.BARRACKS:
				_add_train_button("🗡️ Kılıçlı (60🌾 20🪙)", Unit.UnitType.SWORDSMAN)
				_add_train_button("🔱 Mızrak (50🌾 35🪵)", Unit.UnitType.SPEARMAN)
			Building.BuildingType.ARCHERY_RANGE:
				_add_train_button("🏹 Okçu (45🪵 40🪙)", Unit.UnitType.ARCHER)
			Building.BuildingType.STABLE:
				_add_train_button("🐎 Süvari (75🌾 60🪙)", Unit.UnitType.CAVALRY)
			Building.BuildingType.CASTLE:
				var civ_cfg = CivData.get_civ(b.civ_type)
				var u_name = civ_cfg.get("unique_unit_name", "Özel Asker")
				var u_type_str = civ_cfg.get("unique_unit_type", "JANISSARY")
				var u_enum = Unit.UnitType.JANISSARY
				match u_type_str:
					"JANISSARY": u_enum = Unit.UnitType.JANISSARY
					"CATAPHRACT": u_enum = Unit.UnitType.CATAPHRACT
					"LONGBOWMAN": u_enum = Unit.UnitType.LONGBOWMAN
					"PALADIN": u_enum = Unit.UnitType.PALADIN
					"MANGUDAI": u_enum = Unit.UnitType.MANGUDAI
					"TEUTONIC_KNIGHT": u_enum = Unit.UnitType.TEUTONIC_KNIGHT
					"SAMURAI": u_enum = Unit.UnitType.SAMURAI
					"MAMELUKE": u_enum = Unit.UnitType.MAMELUKE
					"BERSERKER": u_enum = Unit.UnitType.BERSERKER
					"CHUKONU": u_enum = Unit.UnitType.CHUKONU
				_add_train_button("⭐ %s (80🌾 60🪙)" % u_name, u_enum)

func _add_train_button(label: String, u_type: Unit.UnitType) -> void:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(120, 42)
	btn.pressed.connect(func():
		train_unit_requested.emit(u_type)
	)
	action_buttons_grid.add_child(btn)

func show_game_over(victory: bool, stats: Dictionary) -> void:
	game_over_modal.visible = true
	var title = game_over_modal.get_node("VBox/TitleLabel") as Label
	var desc = game_over_modal.get_node("VBox/DescLabel") as Label
	
	if victory:
		title.text = "🏆 ZAFER!"
		title.modulate = Color(0.2, 0.95, 0.3)
	else:
		title.text = "💀 BOZGUN!"
		title.modulate = Color(0.95, 0.25, 0.25)
		
	desc.text = "Süre: %s\nYok Edilen Düşman: %d\nEğitilen Asker: %d\nToplanan Kaynak: %d" % [
		stats.get("duration", "02:15"),
		stats.get("kills", 0),
		stats.get("trained", 0),
		stats.get("gathered", 0)
	]
