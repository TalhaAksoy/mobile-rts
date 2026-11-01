class_name ArtPreview
extends Control

## Pocket Empires - Mobile Portrait Faction Art Gallery
## Optimized for vertical phone screens: stacked cards, touch targets, and persistent back navigation.

signal back_requested

const MANIFEST_PATH: String = "res://data/faction_art_manifest.json"
const BUILDING_MANIFEST_PATH: String = "res://data/building_art_manifest.json"
const FactionArtManager = preload("res://scripts/FactionArtManager.gd")
const ParchmentTheme = preload("res://scripts/ParchmentTheme.gd")
const PixelArtTextures = preload("res://scripts/PixelArtTextures.gd")

var catalog: Dictionary = {}
var building_catalog: Dictionary = {}
var current_faction_idx: int = 0
var current_pose: String = "pose_01"
var current_view_mode: String = "units" # "units", "buildings", "poster"

var faction_picker: OptionButton
var pose_picker: OptionButton
var mode_units_btn: Button
var mode_buildings_btn: Button
var mode_poster_btn: Button
var top_back_btn: Button
var bottom_back_btn: Button
var description_label: Label
var unit_cards_container: VBoxContainer
var cards_scroll: ScrollContainer
var poster_scroll: ScrollContainer
var concept_sheet_rect: TextureRect

func _ready() -> void:
	_load_manifest()
	_build_ui()
	_populate_pickers()
	if faction_picker != null and faction_picker.item_count > 0:
		_show_faction(0)

func _load_manifest() -> void:
	if FileAccess.file_exists(MANIFEST_PATH):
		var file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				catalog = parsed

	if FileAccess.file_exists(BUILDING_MANIFEST_PATH):
		var b_file = FileAccess.open(BUILDING_MANIFEST_PATH, FileAccess.READ)
		if b_file != null:
			var b_parsed = JSON.parse_string(b_file.get_as_text())
			if typeof(b_parsed) == TYPE_DICTIONARY:
				building_catalog = b_parsed

func _build_ui() -> void:
	# 1. Fullscreen dark medieval parchment background
	var bg = ColorRect.new()
	bg.color = Color(0.10, 0.08, 0.06, 0.98)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 2. Main vertical container filling the portrait screen
	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_left = 16.0
	root_vbox.offset_top = 16.0
	root_vbox.offset_right = -16.0
	root_vbox.offset_bottom = -16.0
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	# --- TOP STICKY BAR: Back Button + Screen Title ---
	var top_bar = HBoxContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 52)
	top_bar.add_theme_constant_override("separation", 12)
	root_vbox.add_child(top_bar)

	top_back_btn = Button.new()
	top_back_btn.text = "← ANA MENÜ"
	top_back_btn.custom_minimum_size = Vector2(130, 48)
	ParchmentTheme.apply_parchment_button(top_back_btn, 15)
	top_back_btn.pressed.connect(_on_back_pressed)
	top_bar.add_child(top_back_btn)

	var title_lbl = Label.new()
	title_lbl.text = "SANAT GALERİSİ"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_override("font", ParchmentTheme.get_cinzel_font())
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.88, 0.52))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(title_lbl)

	# --- CONTROLS: Mobile-Friendly Full-Width Pickers ---
	# Row 1: Faction Picker
	var fac_box = VBoxContainer.new()
	fac_box.add_theme_constant_override("separation", 4)
	root_vbox.add_child(fac_box)

	var fac_title = Label.new()
	fac_title.text = "Krallık Seçimi:"
	fac_title.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	fac_title.add_theme_font_size_override("font_size", 14)
	fac_title.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
	fac_box.add_child(fac_title)

	faction_picker = OptionButton.new()
	faction_picker.custom_minimum_size = Vector2(0, 48)
	faction_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ParchmentTheme.apply_parchment_button(faction_picker, 15)
	ParchmentTheme.apply_parchment_popup(faction_picker.get_popup(), 15)
	fac_box.add_child(faction_picker)

	# Row 2: Gallery Mode Switcher (Units / Buildings / Poster)
	var mode_bar = HBoxContainer.new()
	mode_bar.custom_minimum_size = Vector2(0, 44)
	mode_bar.add_theme_constant_override("separation", 8)
	root_vbox.add_child(mode_bar)

	mode_units_btn = Button.new()
	mode_units_btn.text = "⚔ BİRLİKLER"
	mode_units_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ParchmentTheme.apply_parchment_button(mode_units_btn, 13)
	mode_units_btn.pressed.connect(func(): _switch_mode("units"))
	mode_bar.add_child(mode_units_btn)

	mode_buildings_btn = Button.new()
	mode_buildings_btn.text = "🏛 BİNALAR"
	mode_buildings_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ParchmentTheme.apply_parchment_button(mode_buildings_btn, 13)
	mode_buildings_btn.pressed.connect(func(): _switch_mode("buildings"))
	mode_bar.add_child(mode_buildings_btn)

	mode_poster_btn = Button.new()
	mode_poster_btn.text = "📜 POSTER"
	mode_poster_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ParchmentTheme.apply_parchment_button(mode_poster_btn, 13)
	mode_poster_btn.pressed.connect(func(): _switch_mode("poster"))
	mode_bar.add_child(mode_poster_btn)

	# Row 3: Unit Pose Picker (Only shown when browsing units)
	pose_picker = OptionButton.new()
	pose_picker.custom_minimum_size = Vector2(0, 44)
	pose_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ParchmentTheme.apply_parchment_button(pose_picker, 14)
	ParchmentTheme.apply_parchment_popup(pose_picker.get_popup(), 14)
	root_vbox.add_child(pose_picker)

	# Description banner
	description_label = Label.new()
	description_label.text = "10 Krallık • 50 Birlik & 140 Bina Kataloğu"
	description_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	description_label.add_theme_font_size_override("font_size", 13)
	description_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.58))
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_vbox.add_child(description_label)

	# --- MAIN SCROLL AREA: Vertical Cards Stacked ("Alt Alta") ---
	cards_scroll = ScrollContainer.new()
	cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root_vbox.add_child(cards_scroll)

	unit_cards_container = VBoxContainer.new()
	unit_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_cards_container.add_theme_constant_override("separation", 18)
	cards_scroll.add_child(unit_cards_container)

	# Poster mode view (scrollable vertically)
	poster_scroll = ScrollContainer.new()
	poster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	poster_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	poster_scroll.visible = false
	root_vbox.add_child(poster_scroll)

	concept_sheet_rect = TextureRect.new()
	concept_sheet_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	concept_sheet_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	concept_sheet_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	concept_sheet_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	concept_sheet_rect.custom_minimum_size = Vector2(480, 680)
	poster_scroll.add_child(concept_sheet_rect)

	# --- BOTTOM STICKY BAR: Secondary Quick Back Button ---
	bottom_back_btn = Button.new()
	bottom_back_btn.text = "← ANA MENÜYE DÖN"
	bottom_back_btn.custom_minimum_size = Vector2(0, 52)
	bottom_back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ParchmentTheme.apply_parchment_button(bottom_back_btn, 16)
	bottom_back_btn.pressed.connect(_on_back_pressed)
	root_vbox.add_child(bottom_back_btn)

func _populate_pickers() -> void:
	faction_picker.clear()
	var factions = catalog.get("factions", [])
	var pop = faction_picker.get_popup()
	for i in range(factions.size()):
		var f = factions[i]
		var f_id = f.get("id", "")
		var tr_name = f.get("name_tr", f_id)
		var civ_type = FactionArtManager.get_civ_from_faction_id(f_id)
		var flag_tex = FactionArtManager.get_flag_reference_texture(civ_type)
		if flag_tex == null:
			flag_tex = PixelArtTextures.get_civ_flag_texture(civ_type)
		if flag_tex != null:
			faction_picker.add_icon_item(flag_tex, "%s" % tr_name, i)
		else:
			faction_picker.add_item("%s" % tr_name, i)

	# Clean up popup items: remove radio checkmark circles so only flag and kingdom name are displayed cleanly
	for i in range(pop.item_count):
		pop.set_item_as_radio_checkable(i, false)
		pop.set_item_as_checkable(i, false)

	faction_picker.item_selected.connect(func(idx: int):
		current_faction_idx = idx
		_show_faction(idx)
	)

	pose_picker.clear()
	pose_picker.add_item("Ana Duruş (pose_01)", 0)
	pose_picker.add_item("Duruş 2 (pose_02)", 1)
	pose_picker.add_item("Arka Referans (rear)", 2)
	pose_picker.add_item("Aksiyon Referans (action)", 3)

	pose_picker.item_selected.connect(func(idx: int):
		match idx:
			0: current_pose = "pose_01"
			1: current_pose = "pose_02"
			2: current_pose = "rear_reference"
			3: current_pose = "action_reference"
		_show_faction(current_faction_idx)
	)

	_switch_mode("units")

func _switch_mode(mode: String) -> void:
	current_view_mode = mode
	if mode_units_btn != null: mode_units_btn.modulate = Color(1.3, 1.2, 0.7) if mode == "units" else Color(1, 1, 1)
	if mode_buildings_btn != null: mode_buildings_btn.modulate = Color(1.3, 1.2, 0.7) if mode == "buildings" else Color(1, 1, 1)
	if mode_poster_btn != null: mode_poster_btn.modulate = Color(1.3, 1.2, 0.7) if mode == "poster" else Color(1, 1, 1)

	if mode == "poster":
		poster_scroll.visible = true
		cards_scroll.visible = false
		pose_picker.visible = false
	else:
		poster_scroll.visible = false
		cards_scroll.visible = true
		pose_picker.visible = (mode == "units")

	_show_faction(current_faction_idx)

func _show_faction(index: int) -> void:
	for child in unit_cards_container.get_children():
		unit_cards_container.remove_child(child)
		child.queue_free()

	var factions: Array = catalog.get("factions", [])
	if index < 0 or index >= factions.size():
		return

	var f: Dictionary = factions[index]
	var f_id = f.get("id", "")
	var name_tr = f.get("name_tr", f_id)
	var name_en = f.get("name_en", "")

	var poster_path = "res://" + str(f.get("concept_sheet", ""))
	if ResourceLoader.exists(poster_path):
		concept_sheet_rect.texture = load(poster_path) as Texture2D

	if current_view_mode == "units":
		description_label.text = "%s (%s) — 5 Birlik Görseli [Dikey Liste]" % [name_tr, name_en]
		var units: Dictionary = f.get("units", {})
		var role_ids: Array = f.get("unit_ids", [])
		for r_id in role_ids:
			var u_info: Dictionary = units.get(r_id, {})
			var card = _create_unit_card(f_id, r_id, u_info)
			unit_cards_container.add_child(card)
	elif current_view_mode == "buildings":
		description_label.text = "%s (%s) — 13 Krallık Binası [HD-2D Atlas Mimari]" % [name_tr, name_en]
		var f_buildings = building_catalog.get("factions", {}).get(f_id, {})
		var b_dict = f_buildings.get("buildings", f_buildings.get("textures", {}))
		var b_references = f_buildings.get("references", {})

		var b_types_meta = {}
		var raw_b_types = building_catalog.get("building_types", building_catalog.get("buildings", []))
		if typeof(raw_b_types) == TYPE_ARRAY:
			for item in raw_b_types:
				if typeof(item) == TYPE_DICTIONARY and item.has("id"):
					b_types_meta[item["id"]] = item
		elif typeof(raw_b_types) == TYPE_DICTIONARY:
			b_types_meta = raw_b_types

		var ordered_b_ids = [
			"town_center", "house", "barracks", "archery_range", "stable",
			"blacksmith", "castle", "watch_tower", "lumber_camp", "mining_camp",
			"mill", "market", "stone_wall"
		]

		for b_id in ordered_b_ids:
			var b_type_info = b_types_meta.get(b_id, {})
			var b_tex_path = "res://art/buildings/%s/%s.png" % [f_id, b_id]
			if b_dict.has(b_id):
				var b_entry = b_dict[b_id]
				if typeof(b_entry) == TYPE_DICTIONARY and b_entry.has("path"):
					b_tex_path = "res://" + str(b_entry["path"])
				elif typeof(b_entry) == TYPE_STRING:
					b_tex_path = str(b_entry)
			var b_ref_path = b_references.get(b_id, "")
			var card = _create_building_card(f_id, b_id, b_type_info, b_tex_path, b_ref_path)
			unit_cards_container.add_child(card)
	elif current_view_mode == "poster":
		description_label.text = "%s (%s) — Kültürel Konsept Atlası" % [name_tr, name_en]

	# Reset scroll to top when faction changes
	cards_scroll.scroll_vertical = 0

func _create_unit_card(f_id: String, role_id: String, u_info: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 330)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.14, 0.10, 0.95)
	style.border_color = Color(0.72, 0.58, 0.35, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var card_vbox = VBoxContainer.new()
	card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_vbox.add_theme_constant_override("separation", 8)
	card.add_child(card_vbox)

	# --- Header: Title + Badge ---
	var header_hbox = HBoxContainer.new()
	header_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_vbox.add_child(header_hbox)

	var titles_vbox = VBoxContainer.new()
	titles_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(titles_vbox)

	var name_tr = str(u_info.get("display_name_tr", role_id.capitalize()))
	var name_lbl = Label.new()
	name_lbl.text = name_tr
	name_lbl.add_theme_font_override("font", ParchmentTheme.get_cinzel_font())
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.98, 0.90, 0.60))
	titles_vbox.add_child(name_lbl)

	var en_lbl = Label.new()
	en_lbl.text = str(u_info.get("display_name_en", ""))
	en_lbl.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	en_lbl.add_theme_font_size_override("font_size", 12)
	en_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60))
	titles_vbox.add_child(en_lbl)

	# Badge Pill
	var badge_lbl = Label.new()
	var badge_text = "PİYADE"
	var badge_col = Color(0.65, 0.85, 0.65)
	if role_id == "villager":
		badge_text = "İŞÇİ / EKONOMİ"
		badge_col = Color(0.85, 0.85, 0.50)
	elif role_id == "archer":
		badge_text = "MENZİLLİ"
		badge_col = Color(0.55, 0.80, 0.95)
	elif role_id == "spearman":
		badge_text = "MIZRAKÇI"
		badge_col = Color(0.70, 0.85, 0.60)
	elif role_id not in ["villager", "swordsman", "spearman", "archer"]:
		badge_text = "★ ÖZEL BİRLİK"
		badge_col = Color(1.0, 0.85, 0.35)

	badge_lbl.text = " %s " % badge_text
	badge_lbl.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	badge_lbl.add_theme_font_size_override("font_size", 12)
	badge_lbl.add_theme_color_override("font_color", badge_col)
	header_hbox.add_child(badge_lbl)

	# --- Image Frame (High resolution centered sprite) ---
	var img_panel = PanelContainer.new()
	img_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	img_panel.custom_minimum_size = Vector2(0, 210)

	var img_style = StyleBoxFlat.new()
	img_style.bg_color = Color(0.12, 0.10, 0.08, 0.85)
	img_style.set_border_width_all(1)
	img_style.border_color = Color(0.42, 0.34, 0.22, 0.80)
	img_style.set_corner_radius_all(8)
	img_panel.add_theme_stylebox_override("panel", img_style)
	card_vbox.add_child(img_panel)

	var tex_rect = TextureRect.new()
	tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex_rect.custom_minimum_size = Vector2(0, 200)
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var poses: Dictionary = u_info.get("poses", {})
	var pose_path = "res://" + str(poses.get(current_pose, poses.get("pose_01", "")))
	if ResourceLoader.exists(pose_path):
		tex_rect.texture = load(pose_path) as Texture2D
	img_panel.add_child(tex_rect)

	# --- Bottom Specs Row ---
	var specs_lbl = Label.new()
	specs_lbl.text = _get_role_description_tr(role_id)
	specs_lbl.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	specs_lbl.add_theme_font_size_override("font_size", 12)
	specs_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
	specs_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(specs_lbl)

	return card

func _get_role_description_tr(role_id: String) -> String:
	match role_id:
		"villager": return "Odun, Besin, Altın ve Taş toplar; binaları inşa eder ve onarır."
		"swordsman": return "Yakın dövüş piyadesi. Dengeli can ve kalkan zırhına sahiptir."
		"spearman": return "Mızraklı piyade. Süvarilere karşı yüksek bonus hasar verir."
		"archer": return "Uzaktan ok atan menzilli asker. Piyadelere karşı etkilidir."
		"janissary": return "Osmanlı Özel Birliği: Ağır hasarlı tüfekçi, yüksek zırh delme."
		"cataphract": return "Bizans Özel Birliği: Zırhlı elit süvari, piyade ezici etki."
		"longbowman": return "Britanya Özel Birliği: Aşırı uzun menzilli kale okçusu."
		"knight": return "Frank Özel Birliği: Ağır zırhlı ve yüksek cana sahip Paladin süvarisi."
		"horse_archer": return "Moğol Özel Birliği (Mangudai): Hareketli ve seri menzilli atlı okçu."
		"teutonic_knight": return "Töton Özel Birliği: Geçit vermez aşırı yüksek zırh ve güç."
		"samurai": return "Japon Özel Birliği: Seri katana darbeleriyle diğer özel birliklere karşı güçlü."
		"mamluk": return "Sarazen Özel Birliği: Süvarilere kılıç fırlatan elit deve savaşçısı."
		"berserker": return "Viking Özel Birliği: Savaşta kendi canını yenileyen vahşi savaşçı."
		"chu_ko_nu": return "Çin Özel Birliği: Seri biçimde çoklu ok fırlatan arbaletçi."
	return "Krallık askeri birliği."

func _create_building_card(_f_id: String, b_id: String, b_type_info: Dictionary, b_tex_path: String, _b_ref_path: String) -> PanelContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 360)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.14, 0.10, 0.95)
	style.border_color = Color(0.72, 0.58, 0.35, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var card_vbox = VBoxContainer.new()
	card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_vbox.add_theme_constant_override("separation", 8)
	card.add_child(card_vbox)

	# --- Header: Title + Badge ---
	var header_hbox = HBoxContainer.new()
	header_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_vbox.add_child(header_hbox)

	var titles_vbox = VBoxContainer.new()
	titles_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(titles_vbox)

	var name_tr = str(b_type_info.get("display_name_tr", b_type_info.get("name_tr", b_id.capitalize())))
	var name_lbl = Label.new()
	name_lbl.text = name_tr
	name_lbl.add_theme_font_override("font", ParchmentTheme.get_cinzel_font())
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.98, 0.90, 0.60))
	titles_vbox.add_child(name_lbl)

	var en_lbl = Label.new()
	en_lbl.text = str(b_type_info.get("name_en", ""))
	en_lbl.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	en_lbl.add_theme_font_size_override("font_size", 12)
	en_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60))
	titles_vbox.add_child(en_lbl)

	# Badge Pill (Footprint)
	var tiles: Array = b_type_info.get("suggested_footprint_tiles", [2, 2])
	var badge_lbl = Label.new()
	badge_lbl.text = " [%d×%d ALAN] " % [tiles[0], tiles[1]]
	badge_lbl.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	badge_lbl.add_theme_font_size_override("font_size", 12)
	badge_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.50))
	header_hbox.add_child(badge_lbl)

	# --- Image Frame (High resolution centered sprite) ---
	var img_panel = PanelContainer.new()
	img_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	img_panel.custom_minimum_size = Vector2(0, 220)

	var img_style = StyleBoxFlat.new()
	img_style.bg_color = Color(0.12, 0.10, 0.08, 0.85)
	img_style.set_border_width_all(1)
	img_style.border_color = Color(0.42, 0.34, 0.22, 0.80)
	img_style.set_corner_radius_all(8)
	img_panel.add_theme_stylebox_override("panel", img_style)
	card_vbox.add_child(img_panel)

	var tex_rect = TextureRect.new()
	tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex_rect.custom_minimum_size = Vector2(0, 210)
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if ResourceLoader.exists(b_tex_path):
		tex_rect.texture = load(b_tex_path) as Texture2D
	img_panel.add_child(tex_rect)

	# --- Bottom Specs Row ---
	var specs_lbl = Label.new()
	var v_h = b_type_info.get("suggested_visual_height_world_units", 3.0)
	specs_lbl.text = "Görsel Boyut: %.1fm • %s" % [v_h, _get_building_description_tr(b_id)]
	specs_lbl.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	specs_lbl.add_theme_font_size_override("font_size", 12)
	specs_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
	specs_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(specs_lbl)

	return card

func _get_building_description_tr(b_id: String) -> String:
	match b_id:
		"town_center": return "Ana Üs: Köylü eğitir, çağ atlatır, tüm kaynakları kabul eder."
		"house": return "Sivil Konut: Nüfus limitini +5 artırır."
		"barracks": return "Askeri Kışla: Kılıçlı piyade ve mızrakçı eğitir."
		"archery_range": return "Okçu Alanı: Menzilli okçu birlikleri eğitir."
		"stable": return "Atlı Ahırı: Hızlı süvari birlikleri eğitir."
		"blacksmith": return "Demirci: Birlik saldırı ve zırh teknolojilerini araştırır."
		"castle": return "Büyük Kale: Savunma okları atar ve krallığın elit birliğini eğitir."
		"watch_tower": return "Gözetleme Kulesi: Yaklaşan düşmanlara otomatik ok fırlatır."
		"lumber_camp": return "Oduncu Kampı: Orman yanına kurulur, odun teslim noktasıdır."
		"mining_camp": return "Maden Kampı: Altın ve taş madenleri teslim noktasıdır."
		"mill": return "Değirmen: Meyve çalıları ve çiftlikler için besin teslim noktasıdır."
		"farm": return "Çiftlik: Sürekli ve tükenmez besin kaynağı sağlar."
		"market": return "Pazar: Kaynak takası ve ticaret sağlar."
		"stone_wall": return "Taş Duvar: Üssü koruyan savunma tahkimatı."
	return "Krallık mimari yapısı."

func _toggle_poster_view() -> void:
	if current_view_mode == "poster":
		_switch_mode("units")
	else:
		_switch_mode("poster")

func _on_back_pressed() -> void:
	SoundManager.play_sound("click")
	back_requested.emit()
	visible = false

	var parent_node = get_parent()
	if parent_node != null and parent_node.has_method("_show_main_menu"):
		parent_node._show_main_menu()
	elif get_tree() != null and get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/Main3D.tscn")
