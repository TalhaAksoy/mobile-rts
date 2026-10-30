class_name ParchmentTheme
extends RefCounted

static var medieval_font: Font
static var cinzel_font: Font
static var fallback_font: SystemFont

static func get_medieval_font() -> Font:
	if medieval_font == null:
		var ff = FontFile.new()
		var p = ProjectSettings.globalize_path("res://assets/MedievalSharp.ttf")
		if FileAccess.file_exists(p) or FileAccess.file_exists("res://assets/MedievalSharp.ttf"):
			var err = ff.load_dynamic_font(p)
			if err == OK:
				medieval_font = ff
		if medieval_font == null:
			medieval_font = get_serif_fallback()
	return medieval_font

static func get_cinzel_font() -> Font:
	if cinzel_font == null:
		var ff = FontFile.new()
		var p = ProjectSettings.globalize_path("res://assets/Cinzel.ttf")
		if FileAccess.file_exists(p) or FileAccess.file_exists("res://assets/Cinzel.ttf"):
			var err = ff.load_dynamic_font(p)
			if err == OK:
				cinzel_font = ff
		if cinzel_font == null:
			cinzel_font = get_medieval_font()
	return cinzel_font

static func get_title_font() -> Font:
	return get_cinzel_font()

static func get_serif_font(_size: int = 16, _bold: bool = false) -> Font:
	return get_medieval_font()

static func get_serif_fallback() -> Font:
	if fallback_font == null:
		fallback_font = SystemFont.new()
		fallback_font.font_names = PackedStringArray([
			"Palatino", "Georgia", "Baskerville", "Times New Roman", "serif"
		])
	return fallback_font

# Parchment Palette
const PARCHMENT_BG: Color = Color(0.91, 0.83, 0.68) # Antique parchment paper
const PARCHMENT_DARK: Color = Color(0.80, 0.70, 0.54) # Weathered edges
const PARCHMENT_LIGHT: Color = Color(0.95, 0.89, 0.76)
const INK_DARK: Color = Color(0.18, 0.10, 0.04) # Deep iron-gall manuscript ink
const INK_MUTED: Color = Color(0.38, 0.26, 0.16)
const LEATHER_BORDER: Color = Color(0.36, 0.20, 0.08) # Embossed leather trim
const BRONZE_GOLD: Color = Color(0.78, 0.55, 0.18) # Antique guild gold
const BRONZE_DARK: Color = Color(0.24, 0.14, 0.06)

static func create_theme() -> Theme:
	var t = Theme.new()
	var base_font = get_medieval_font()
	t.default_font = base_font
	t.default_font_size = 17

	# 1. Panel Container (Parchment scroll look)
	var panel_sb = StyleBoxFlat.new()
	panel_sb.bg_color = PARCHMENT_BG
	panel_sb.border_color = LEATHER_BORDER
	panel_sb.set_border_width_all(3)
	panel_sb.corner_radius_top_left = 6
	panel_sb.corner_radius_top_right = 6
	panel_sb.corner_radius_bottom_left = 6
	panel_sb.corner_radius_bottom_right = 6
	panel_sb.shadow_color = Color(0, 0, 0, 0.45)
	panel_sb.shadow_size = 5
	panel_sb.shadow_offset = Vector2(0, 3)
	panel_sb.content_margin_left = 14
	panel_sb.content_margin_top = 12
	panel_sb.content_margin_right = 14
	panel_sb.content_margin_bottom = 12
	t.set_stylebox("panel", "PanelContainer", panel_sb)

	# 2. Buttons (Wax & Parchment placard style)
	var btn_normal = get_button_style("normal")
	var btn_hover = get_button_style("hover")
	var btn_pressed = get_button_style("pressed")

	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("focus", "Button", btn_hover)

	t.set_font("font", "Button", base_font)
	t.set_font_size("font_size", "Button", 18)

	t.set_color("font_color", "Button", INK_DARK)
	t.set_color("font_hover_color", "Button", Color(0.08, 0.04, 0.01))
	t.set_color("font_pressed_color", "Button", Color(0.02, 0.01, 0.0))

	# 3. Labels
	t.set_font("font", "Label", base_font)
	t.set_color("font_color", "Label", INK_DARK)
	t.set_color("font_shadow_color", "Label", Color(1, 1, 1, 0.3))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)

	# 4. Progress Bar (HP Bar with antique brass casing)
	var prog_bg = StyleBoxFlat.new()
	prog_bg.bg_color = Color(0.20, 0.14, 0.09)
	prog_bg.border_color = LEATHER_BORDER
	prog_bg.set_border_width_all(2)
	prog_bg.corner_radius_top_left = 3
	prog_bg.corner_radius_top_right = 3
	prog_bg.corner_radius_bottom_left = 3
	prog_bg.corner_radius_bottom_right = 3

	var prog_fill = StyleBoxFlat.new()
	prog_fill.bg_color = Color(0.20, 0.65, 0.25)
	prog_fill.corner_radius_top_left = 2
	prog_fill.corner_radius_top_right = 2
	prog_fill.corner_radius_bottom_left = 2
	prog_fill.corner_radius_bottom_right = 2

	t.set_stylebox("background", "ProgressBar", prog_bg)
	t.set_stylebox("fill", "ProgressBar", prog_fill)

	return t

static func get_button_style(state: String) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 5
	sb.corner_radius_top_right = 5
	sb.corner_radius_bottom_left = 5
	sb.corner_radius_bottom_right = 5
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10

	match state:
		"hover":
			sb.bg_color = Color(0.96, 0.90, 0.77) # Illuminated gold parchment
			sb.border_color = BRONZE_GOLD
			sb.set_border_width_all(3)
			sb.shadow_color = Color(0.2, 0.12, 0.04, 0.5)
			sb.shadow_size = 5
			sb.shadow_offset = Vector2(0, 3)
		"pressed":
			sb.bg_color = Color(0.79, 0.69, 0.53) # Indented darker vellum
			sb.border_color = BRONZE_DARK
			sb.set_border_width_all(3)
			sb.shadow_size = 0
		_: # normal
			sb.bg_color = Color(0.89, 0.80, 0.65) # Warm aged parchment
			sb.border_color = LEATHER_BORDER
			sb.set_border_width_all(3)
			sb.shadow_color = Color(0.08, 0.04, 0.02, 0.45)
			sb.shadow_size = 4
			sb.shadow_offset = Vector2(0, 3)

	return sb

static func apply_parchment_button(btn: Button, font_size: int = 20) -> void:
	if btn == null:
		return
	btn.add_theme_font_override("font", get_medieval_font())
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", INK_DARK)
	btn.add_theme_color_override("font_hover_color", Color(0.08, 0.04, 0.01))
	btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.01, 0.0))
	btn.add_theme_stylebox_override("normal", get_button_style("normal"))
	btn.add_theme_stylebox_override("hover", get_button_style("hover"))
	btn.add_theme_stylebox_override("pressed", get_button_style("pressed"))
	btn.add_theme_stylebox_override("focus", get_button_style("hover"))

static func apply_parchment_popup(popup: PopupMenu, font_size: int = 15) -> void:
	if popup == null:
		return
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.12, 0.08, 0.98) # Dark antique leather
	sb.border_color = BRONZE_GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	popup.add_theme_stylebox_override("panel", sb)

	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.32, 0.24, 0.16, 0.95)
	sb_hover.border_color = BRONZE_GOLD
	sb_hover.set_border_width_all(1)
	sb_hover.set_corner_radius_all(4)
	popup.add_theme_stylebox_override("hover", sb_hover)

	popup.add_theme_font_override("font", get_medieval_font())
	popup.add_theme_font_size_override("font_size", font_size)
	popup.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72))
	popup.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.40))
	popup.add_theme_constant_override("icon_max_width", 38)
	popup.add_theme_constant_override("h_separation", 12)
	popup.add_theme_constant_override("v_separation", 8)

