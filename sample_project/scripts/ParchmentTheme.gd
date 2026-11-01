class_name ParchmentTheme
extends RefCounted

static var cinzel_font: Font

## Fonts. Headings: Cinzel (engraved capitals). Everything else: the device's sans-serif (Roboto on
## Android) - easy to read at phone sizes; the old MedievalSharp body font made every label look like a
## fantasy poster. Fonts are loaded as imported resources so they also exist in exported builds (the old
## load_dynamic_font(globalize_path(...)) fell back to a system font on Android).
static var body_font: SystemFont
static var body_bold_font: SystemFont

static func _load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		var f = load(path)
		if f is Font:
			return f
	return null

## Body text (name kept: most UI code asks for the "medieval" font).
static func get_medieval_font() -> Font:
	if body_font == null:
		body_font = SystemFont.new()
		body_font.font_names = PackedStringArray(["Roboto", "Noto Sans", "Inter", "Segoe UI", "Helvetica Neue", "Arial", "DejaVu Sans", "sans-serif"])
		body_font.font_weight = 500
		body_font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		body_font.hinting = TextServer.HINTING_LIGHT
	return body_font

static func get_body_bold_font() -> Font:
	if body_bold_font == null:
		body_bold_font = SystemFont.new()
		body_bold_font.font_names = get_medieval_font().font_names
		body_bold_font.font_weight = 700
		body_bold_font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		body_bold_font.hinting = TextServer.HINTING_LIGHT
	return body_bold_font

static func get_cinzel_font() -> Font:
	if cinzel_font == null:
		cinzel_font = _load_font("res://assets/Cinzel.ttf")
		if cinzel_font == null:
			cinzel_font = get_body_bold_font()
	return cinzel_font

static func get_title_font() -> Font:
	return get_cinzel_font()

static func get_serif_font(_size: int = 16, bold: bool = false) -> Font:
	return get_body_bold_font() if bold else get_medieval_font()

static func get_serif_fallback() -> Font:
	return get_medieval_font()

# Palette: a light paper sheet with ink text and thin ink rules; one lacquer-red accent for the main
# action, ink for the selected option. No heavy borders or drop shadows on every control.
const PARCHMENT_BG: Color = Color(0.93, 0.89, 0.80)       # paper
const PARCHMENT_DARK: Color = Color(0.86, 0.80, 0.69)     # inset / control fill
const PARCHMENT_LIGHT: Color = Color(0.97, 0.94, 0.87)
const INK_DARK: Color = Color(0.15, 0.11, 0.07)           # text
const INK_MUTED: Color = Color(0.42, 0.35, 0.27)          # secondary text
const LEATHER_BORDER: Color = Color(0.30, 0.22, 0.14)     # rules / outlines
const BRONZE_GOLD: Color = Color(0.74, 0.55, 0.22)        # small highlights
const BRONZE_DARK: Color = Color(0.24, 0.14, 0.06)
const HAIRLINE: Color = Color(0.30, 0.22, 0.14, 0.28)
const ACCENT: Color = Color(0.55, 0.16, 0.11)             # lacquer red: the one primary action
const ACCENT_HOVER: Color = Color(0.63, 0.20, 0.14)
const ON_DARK: Color = Color(0.96, 0.93, 0.86)            # text on ink / accent fills
const SCRIM: Color = Color(0.06, 0.04, 0.03, 0.62)

static func _sb(bg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, radius: int = 6, mx: int = 14, my: int = 9) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = mx
	sb.content_margin_right = mx
	sb.content_margin_top = my
	sb.content_margin_bottom = my
	sb.anti_aliasing = true
	return sb

## Paper card (menus, HUD bars, dialogs).
static func panel_style(alpha: float = 0.97, radius: int = 10, margin: int = 16) -> StyleBoxFlat:
	var c := PARCHMENT_BG
	c.a = alpha
	var sb := _sb(c, HAIRLINE, 1, radius, margin, margin - 2)
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	return sb

static func create_theme() -> Theme:
	var t = Theme.new()
	var base_font = get_medieval_font()
	t.default_font = base_font
	t.default_font_size = 16

	t.set_stylebox("panel", "PanelContainer", panel_style(0.96, 10, 12))

	t.set_stylebox("normal", "Button", get_button_style("normal"))
	t.set_stylebox("hover", "Button", get_button_style("hover"))
	t.set_stylebox("pressed", "Button", get_button_style("pressed"))
	t.set_stylebox("hover_pressed", "Button", get_button_style("pressed"))
	t.set_stylebox("disabled", "Button", get_button_style("disabled"))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", get_body_bold_font())
	t.set_font_size("font_size", "Button", 16)
	t.set_color("font_color", "Button", INK_DARK)
	t.set_color("font_hover_color", "Button", INK_DARK)
	t.set_color("font_pressed_color", "Button", ON_DARK)
	t.set_color("font_hover_pressed_color", "Button", ON_DARK)
	t.set_color("font_disabled_color", "Button", Color(0.40, 0.33, 0.26))

	t.set_font("font", "Label", base_font)
	t.set_color("font_color", "Label", INK_DARK)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))

	var prog_bg := _sb(Color(0.20, 0.15, 0.10, 0.85), Color(0, 0, 0, 0), 0, 3, 0, 0)
	var prog_fill := _sb(Color(0.30, 0.62, 0.28), Color(0, 0, 0, 0), 0, 3, 0, 0)
	t.set_stylebox("background", "ProgressBar", prog_bg)
	t.set_stylebox("fill", "ProgressBar", prog_fill)

	# sliders: thin ink track, filled part in the accent, round paper grabber
	var track := _sb(Color(0.30, 0.22, 0.14, 0.25), Color(0, 0, 0, 0), 0, 3, 0, 3)
	var fill := _sb(ACCENT, Color(0, 0, 0, 0), 0, 3, 0, 3)
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _grabber_icon(false))
	t.set_icon("grabber_highlight", "HSlider", _grabber_icon(true))

	# option buttons / popups
	t.set_stylebox("normal", "OptionButton", get_button_style("normal"))
	t.set_stylebox("hover", "OptionButton", get_button_style("hover"))
	t.set_stylebox("pressed", "OptionButton", get_button_style("hover"))
	t.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	t.set_color("font_color", "OptionButton", INK_DARK)
	t.set_color("font_hover_color", "OptionButton", INK_DARK)
	t.set_color("font_pressed_color", "OptionButton", INK_DARK)
	t.set_stylebox("panel", "PopupMenu", _sb(PARCHMENT_LIGHT, HAIRLINE, 1, 8, 8, 8))
	t.set_stylebox("hover", "PopupMenu", _sb(PARCHMENT_DARK, Color(0, 0, 0, 0), 0, 6, 8, 6))
	t.set_color("font_color", "PopupMenu", INK_DARK)
	t.set_color("font_hover_color", "PopupMenu", INK_DARK)

	# scrollbars: slim ink thumbs
	var thumb := _sb(Color(0.30, 0.22, 0.14, 0.35), Color(0, 0, 0, 0), 0, 3, 3, 3)
	t.set_stylebox("grabber", "VScrollBar", thumb)
	t.set_stylebox("grabber_highlight", "VScrollBar", thumb)
	t.set_stylebox("grabber_pressed", "VScrollBar", thumb)
	t.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	t.set_stylebox("separator", "HSeparator", _line_style())
	t.set_constant("separation", "HSeparator", 12)
	return t

static func _line_style() -> StyleBoxLine:
	var l := StyleBoxLine.new()
	l.color = HAIRLINE
	l.thickness = 1
	return l

static var _grabbers: Dictionary = {}
static func _grabber_icon(hi: bool) -> Texture2D:
	if _grabbers.has(hi):
		return _grabbers[hi]
	var n := 22
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n * 0.5 - 0.5, n * 0.5 - 0.5)
	for y in n:
		for x in n:
			var d := Vector2(x, y).distance_to(c)
			var col := Color(0, 0, 0, 0)
			if d <= 9.5:
				col = ACCENT if d > 7.0 else (PARCHMENT_LIGHT if not hi else Color(1, 1, 1))
				col.a = clampf(9.5 - d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, col)
	_grabbers[hi] = ImageTexture.create_from_image(img)
	return _grabbers[hi]

## Secondary / default buttons: a paper chip with a hairline. Toggled ("pressed") = ink fill.
static func get_button_style(state: String) -> StyleBoxFlat:
	match state:
		"hover":
			return _sb(Color(0.83, 0.77, 0.65), Color(0.30, 0.22, 0.14, 0.40), 1, 8)
		"disabled":
			return _sb(Color(0.86, 0.81, 0.72, 0.6), Color(0.30, 0.22, 0.14, 0.15), 1, 8)
		"pressed":
			return _sb(Color(0.20, 0.15, 0.10), Color(0.20, 0.15, 0.10), 1, 8)
		_:
			return _sb(PARCHMENT_DARK, Color(0.30, 0.22, 0.14, 0.30), 1, 8)

static func apply_parchment_button(btn: Button, font_size: int = 20) -> void:
	if btn == null:
		return
	btn.add_theme_font_override("font", get_body_bold_font())
	btn.add_theme_font_size_override("font_size", mini(font_size, 18))
	btn.add_theme_color_override("font_color", INK_DARK)
	btn.add_theme_color_override("font_hover_color", INK_DARK)
	btn.add_theme_color_override("font_focus_color", INK_DARK)
	btn.add_theme_color_override("font_pressed_color", ON_DARK)
	btn.add_theme_color_override("font_hover_pressed_color", ON_DARK)
	btn.add_theme_stylebox_override("normal", get_button_style("normal"))
	btn.add_theme_stylebox_override("hover", get_button_style("hover"))
	btn.add_theme_stylebox_override("pressed", get_button_style("pressed"))
	btn.add_theme_stylebox_override("hover_pressed", get_button_style("pressed"))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# disabled buttons ("Çağ II gerekli", "Araştırılıyor ...") must stay readable on the paper
	btn.add_theme_stylebox_override("disabled", get_button_style("disabled"))
	btn.add_theme_color_override("font_disabled_color", Color(0.40, 0.33, 0.26))

## The one main action of a screen (Seferi başlat, Devam et): lacquer red, paper text, Cinzel.
static func apply_primary_button(btn: Button, font_size: int = 19) -> void:
	apply_parchment_button(btn, font_size)
	btn.add_theme_font_override("font", get_cinzel_font())
	btn.add_theme_font_size_override("font_size", font_size)
	for st in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		btn.add_theme_color_override(st, ON_DARK)
	btn.add_theme_stylebox_override("normal", _sb(ACCENT, Color(0, 0, 0, 0), 0, 8, 18, 12))
	btn.add_theme_stylebox_override("hover", _sb(ACCENT_HOVER, Color(0, 0, 0, 0), 0, 8, 18, 12))
	btn.add_theme_stylebox_override("pressed", _sb(ACCENT.darkened(0.2), Color(0, 0, 0, 0), 0, 8, 18, 12))
	btn.add_theme_stylebox_override("hover_pressed", _sb(ACCENT.darkened(0.2), Color(0, 0, 0, 0), 0, 8, 18, 12))

## Text-only button (Geri, secondary links): no box, ink text.
static func apply_ghost_button(btn: Button, font_size: int = 16) -> void:
	apply_parchment_button(btn, font_size)
	var clear := _sb(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 8, 10, 8)
	btn.add_theme_stylebox_override("normal", clear)
	btn.add_theme_stylebox_override("hover", _sb(Color(0.30, 0.22, 0.14, 0.08), Color(0, 0, 0, 0), 0, 8, 10, 8))
	btn.add_theme_stylebox_override("pressed", _sb(Color(0.30, 0.22, 0.14, 0.16), Color(0, 0, 0, 0), 0, 8, 10, 8))
	btn.add_theme_color_override("font_pressed_color", INK_DARK)

## Small caps section heading with a rule under it.
static func section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_override("font", get_body_bold_font())
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", INK_MUTED)
	return l

static func body_label(text: String, size: int = 15, muted: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", get_medieval_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK_MUTED if muted else INK_DARK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func heading_label(text: String, size: int = 22) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", get_cinzel_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", INK_DARK)
	return l

static func rule() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_stylebox_override("separator", _line_style())
	return s

static func apply_parchment_popup(popup: PopupMenu, font_size: int = 15) -> void:
	if popup == null:
		return
	popup.add_theme_stylebox_override("panel", _sb(PARCHMENT_LIGHT, HAIRLINE, 1, 8, 10, 8))
	popup.add_theme_stylebox_override("hover", _sb(PARCHMENT_DARK, Color(0, 0, 0, 0), 0, 6, 8, 6))
	popup.add_theme_font_override("font", get_medieval_font())
	popup.add_theme_font_size_override("font_size", font_size)
	popup.add_theme_color_override("font_color", INK_DARK)
	popup.add_theme_color_override("font_hover_color", INK_DARK)
	popup.add_theme_constant_override("icon_max_width", 32)
	popup.add_theme_constant_override("h_separation", 10)
	popup.add_theme_constant_override("v_separation", 10)
