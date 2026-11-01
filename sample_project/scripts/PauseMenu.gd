class_name PauseMenu
extends Control
## In-match menu: opened from the "Menü" button in the top bar, with Escape, or with the Android Back
## button. GameController3D pauses the match while it is open. Choices:
##   DEVAM ET (resume) · OYUNU KAYDET (quick save) · ANA MENÜYE DÖN · OYUNDAN ÇIK
## Leaving the match (main menu or quit) asks for a second tap, because unsaved progress is lost.
## This node keeps processing while the tree is paused, so its buttons, Escape and Back still work.

signal open_requested          # Escape / Back during a match while the menu is closed
signal resume_requested
signal save_requested
signal main_menu_requested
signal quit_requested

const CONFIRM_TEXT := "Emin misin? Kaydedilmemiş ilerleme kaybolur"
const DANGER := Color(0.62, 0.14, 0.09)

## Set by the game: Escape / Back only open the menu during a match.
var match_running := false

var panel: PanelContainer
var title_label: Label
var status_label: Label
var btn_resume: Button
var btn_save: Button
var btn_main_menu: Button
var btn_quit: Button
var _armed: Button = null      # the leave-button waiting for its confirming second tap

func _init() -> void:
	name = "PauseMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP     # nothing under the menu can be tapped
	visible = false

func build(p_theme: Theme) -> void:
	theme = p_theme
	var dim := ColorRect.new()
	dim.color = ParchmentTheme.SCRIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200.0
	panel.offset_right = 200.0
	panel.offset_top = -210.0
	panel.offset_bottom = 210.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", ParchmentTheme.panel_style(0.98, 12, 22))
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	title_label = Label.new()
	title_label.text = "Duraklatıldı"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", ParchmentTheme.get_cinzel_font())
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", ParchmentTheme.INK_DARK)
	vbox.add_child(title_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	status_label.add_theme_color_override("font_color", ParchmentTheme.INK_MUTED)
	status_label.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(status_label)

	btn_resume = _button(vbox, "Devam Et")
	ParchmentTheme.apply_primary_button(btn_resume, 19)
	btn_save = _button(vbox, "Oyunu Kaydet")
	btn_main_menu = _button(vbox, "Ana Menüye Dön")
	btn_quit = _button(vbox, "Oyundan Çık")
	ParchmentTheme.apply_ghost_button(btn_quit, 16)

	btn_resume.pressed.connect(func(): resume_requested.emit())
	btn_save.pressed.connect(func(): save_requested.emit())
	btn_main_menu.pressed.connect(func(): _confirm_then(btn_main_menu, main_menu_requested))
	btn_quit.pressed.connect(func(): _confirm_then(btn_quit, quit_requested))

func _button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ParchmentTheme.apply_parchment_button(b, 16)
	b.set_meta("label", text)
	parent.add_child(b)
	return b

func open() -> void:
	_disarm()
	status_label.text = ""
	visible = true

func close() -> void:
	_disarm()
	visible = false

func show_status(text: String) -> void:
	status_label.text = text

## First tap on a leave-button arms it (asks for confirmation), the second one confirms.
func _confirm_then(btn: Button, sig: Signal) -> void:
	if _armed == btn:
		_disarm()
		sig.emit()
		return
	_disarm()
	_armed = btn
	btn.text = CONFIRM_TEXT
	for st in ["font_color", "font_hover_color", "font_focus_color"]:
		btn.add_theme_color_override(st, DANGER)

func _disarm() -> void:
	for b in [btn_main_menu, btn_quit]:
		if is_instance_valid(b):
			b.text = b.get_meta("label")
			for st in ["font_color", "font_hover_color", "font_focus_color"]:
				b.add_theme_color_override(st, ParchmentTheme.INK_DARK)
	_armed = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _handle_back():
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:     # Android Back button
		_handle_back()

func _handle_back() -> bool:
	if visible:
		resume_requested.emit()
		return true
	if match_running:
		open_requested.emit()
		return true
	return false
