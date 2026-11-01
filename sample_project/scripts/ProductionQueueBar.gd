class_name ProductionQueueBar
extends PanelContainer
## The selected (own) building's production queue, right above the bottom panel. Units and research
## share ONE queue (Building3D.train_queue) and are made one at a time, in the order asked for:
##  * one square slot per job, left to right in queue order: a unit's portrait, or the building's
##    picture for a research / upgrade
##  * the running job (first slot) has a progress ring that fills up and a countdown of the seconds
##    left; waiting jobs are dimmed and numbered
##  * a line on top says what is being made, how long it still takes and how many wait
## Tapping a slot cancels that job (resources back). Updated every frame from the building itself, so
## the ring and the countdown move without re-opening the panel.

signal cancel_train_requested(building: Building3D, index: int)   # any job: unit or research

const SLOT := 58.0
const MAX_SLOTS := 6

var building: Building3D = null
## hidden while this control is visible (the build panel uses the same spot)
var hidden_by: Control = null
var header: Label
var row: HBoxContainer
var _layout_key := ""
var _slots: Array = []      # [{"button", "ring", "time", "kind": "train"|"research", "index"}]

func _init() -> void:
	name = "ProductionQueueBar"
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	add_child(vb)
	header = Label.new()
	header.add_theme_font_override("font", ParchmentTheme.get_medieval_font())
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", ParchmentTheme.INK_DARK)
	vb.add_child(header)
	row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	vb.add_child(row)

## Shows the queue of `b` (null hides the bar).
func set_building(b: Building3D) -> void:
	building = b
	_layout_key = ""
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

static func unit_name(u_type: int) -> String:
	match u_type:
		Unit3D.UnitType.VILLAGER: return "İşçi"
		Unit3D.UnitType.SWORDSMAN: return "Kılıçlı Asker"
		Unit3D.UnitType.SPEARMAN: return "Mızrakçı"
		Unit3D.UnitType.ARCHER: return "Okçu"
		Unit3D.UnitType.CAVALRY: return "Akıncı Süvari"
		Unit3D.UnitType.PALADIN: return "Şövalye"
	return "Özel Birlik"

## Unit sprites have lots of empty space around the figure: crop each to its visible pixels once.
static var _crop_cache: Dictionary = {}

static func cropped(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	if _crop_cache.has(tex):
		return _crop_cache[tex]
	var out: Texture2D = tex
	var img := tex.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
		var r := img.get_used_rect()
		if r.size.x > 0 and r.size.y > 0 and r.size != img.get_size():
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(r)
			out = at
	_crop_cache[tex] = out
	return out

static func _secs(s: float) -> String:
	return "%d sn" % int(ceil(maxf(s, 0.0)))

func _active() -> bool:
	return is_instance_valid(building) and building.team == 0 and building.hp > 0 and building.is_completed \
		and building.train_queue.size() > 0

static func job_name(item: Dictionary) -> String:
	if item.get("kind", "unit") == "research":
		return TechData.get_tech(item["tech"]).get("name", "Geliştirme")
	return unit_name(item["type"])

func _refresh() -> void:
	if not _active() or (hidden_by != null and hidden_by.visible):
		visible = false
		return
	visible = true
	var key := str(building.train_queue.map(func(it): return "%s:%s" % [it.get("kind", "unit"), it.get("tech", it.get("type", ""))]))
	if key != _layout_key:
		_layout_key = key
		_rebuild()
	var front: Dictionary = building.train_queue[0]
	var left: float = building.current_train_duration - building.current_train_timer
	if not _slots.is_empty():
		var s0 = _slots[0]
		s0["ring"].progress = clampf(building.current_train_timer / maxf(0.1, building.current_train_duration), 0.0, 1.0)
		s0["time"].text = _secs(left)
		s0["ring"].queue_redraw()
	var waiting: int = building.train_queue.size() - 1
	var verb := "araştırılıyor" if front.get("kind", "unit") == "research" else "eğitiliyor"
	header.text = "%s %s • %s%s" % [job_name(front), verb, _secs(left), ("  (+%d sırada)" % waiting) if waiting > 0 else ""]

func _rebuild() -> void:
	for c in row.get_children():
		c.queue_free()
	_slots.clear()
	var bld_tex = FactionArtManager.get_building_texture(building.civ_type, building.building_type)
	if bld_tex == null:
		bld_tex = PixelArtTextures.get_building_icon_texture(building.building_type)
	for i in mini(building.train_queue.size(), MAX_SLOTS):
		var it: Dictionary = building.train_queue[i]
		var research: bool = it.get("kind", "unit") == "research"
		var tex = bld_tex if research else FactionArtManager.get_unit_texture(building.civ_type, it["type"], "pose_01")
		_add_slot(cropped(tex), "research" if research else "train", i, i == 0, job_name(it))
	if building.train_queue.size() > MAX_SLOTS:
		var more := Label.new()
		more.text = "+%d" % (building.train_queue.size() - MAX_SLOTS)
		more.add_theme_font_size_override("font_size", 15)
		more.add_theme_color_override("font_color", ParchmentTheme.INK_DARK)
		row.add_child(more)

func _add_slot(tex: Texture2D, kind: String, index: int, running: bool, title: String = "") -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(SLOT, SLOT)
	b.focus_mode = Control.FOCUS_NONE
	ParchmentTheme.apply_parchment_button(b, 12)
	b.tooltip_text = "%s: iptal etmek için dokun" % title
	row.add_child(b)

	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 5; icon.offset_top = 4; icon.offset_right = -5; icon.offset_bottom = -12
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = Color(1, 1, 1) if running else Color(0.6, 0.6, 0.6, 0.85)
	b.add_child(icon)

	var ring := ProgressRing.new()
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.visible = running
	b.add_child(ring)

	var time := Label.new()
	time.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	time.offset_top = -16
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time.add_theme_font_size_override("font_size", 12)
	time.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	time.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.03))
	time.add_theme_constant_override("outline_size", 4)
	time.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time.text = "" if running else "%d" % (index + 1)
	b.add_child(time)

	if kind == "research":
		# small mark so a waiting upgrade is told apart from the building itself
		var tag := Label.new()
		tag.text = "★"
		tag.position = Vector2(3, 0)
		tag.add_theme_font_size_override("font_size", 14)
		tag.add_theme_color_override("font_color", Color(0.98, 0.82, 0.25))
		tag.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.03))
		tag.add_theme_constant_override("outline_size", 4)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tag)
	var bld := building
	b.pressed.connect(func(): cancel_train_requested.emit(bld, index))
	_slots.append({"button": b, "ring": ring, "time": time, "kind": kind, "index": index})


## Circular progress ("loading circle") drawn over a slot: a dark track and a bright arc that
## grows clockwise from the top as the job progresses.
class ProgressRing extends Control:
	var progress := 0.0

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 5.0
		draw_arc(c, r, 0.0, TAU, 48, Color(0.1, 0.06, 0.03, 0.55), 5.0, true)
		if progress > 0.0:
			draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, Color(0.98, 0.82, 0.25), 5.0, true)
