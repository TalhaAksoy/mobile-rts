class_name VillagerBadge
extends Node3D
## Small always-on badge over each of the player's villagers: a coloured disc with a pixel icon of what
## the villager is doing (wood, gold, stone, food, building, walking, idle) and its load ("3/5"), so the
## player can read the whole economy at a glance without tapping every villager.
## The disc colour is the activity: green gathering, blue carrying to a drop-off, orange building,
## amber idle, grey walking, red fighting. Hidden while the villager is selected (the long status line
## shows instead).

## 10x10 glyphs, one character per pixel ("." = empty). Colours in GLYPH_COLORS.
const GLYPHS := {
	"wood": [
		"..........",
		"...####...",
		"..#oooo#..",
		".#oo##oo#.",
		".#o#oo#o#.",
		".#o#oo#o#.",
		".#oo##oo#.",
		"..#oooo#..",
		"...####...",
		"..........",
	],
	"gold": [
		"..........",
		"....kk....",
		"...kYYk...",
		"..kYyyyk..",
		".kYyyYyyk.",
		".kyyyyyyk.",
		".kyYyyyyk.",
		"..kyyyyk..",
		"...kkkk...",
		"..........",
	],
	"stone": [
		"..........",
		"...kkk....",
		"..kSSsk...",
		".kSsssskk.",
		".kssSsssk.",
		"kssssssSsk",
		"ksSsssssk.",
		".kssssssk.",
		"..kkkkkk..",
		"..........",
	],
	"food": [
		"....w.....",
		"...www.w..",
		"....w.www.",
		"..w.w..w..",
		".www.w.w..",
		"..w..w.w..",
		"..w..wwv..",
		"...w.wv...",
		"....wvv...",
		".....v....",
	],
	"build": [
		"..........",
		".kkkkkkk..",
		".kHHHHHkk.",
		".kHHHHHHk.",
		".kkkkhkkk.",
		".....hk...",
		".....hk...",
		".....hk...",
		".....hk...",
		".....kk...",
	],
	"idle": [
		"..........",
		"ZZZZZ.....",
		"...Z......",
		"..Z.......",
		".Z...zzz..",
		"ZZZZZ..z..",
		"......z...",
		".....zzz..",
		"..........",
		"..........",
	],
	"move": [
		"..........",
		"....W.....",
		"....WW....",
		"WWWWWWW...",
		"WWWWWWWW..",
		"WWWWWWW...",
		"....WW....",
		"....W.....",
		"..........",
		"..........",
	],
	"attack": [
		"..........",
		"W.......W.",
		".W.....W..",
		"..W...W...",
		"...W.W....",
		"....W.....",
		"...W.W....",
		".kW...Wk..",
		"kk.....kk.",
		"..........",
	],
}
const GLYPH_COLORS := {
	"#": Color(0.36, 0.20, 0.08), "o": Color(0.86, 0.62, 0.34),
	"k": Color(0.12, 0.08, 0.04), "Y": Color(1.0, 0.97, 0.66), "y": Color(0.98, 0.78, 0.16),
	"S": Color(0.92, 0.92, 0.94), "s": Color(0.62, 0.64, 0.68),
	"w": Color(1.0, 0.88, 0.38), "v": Color(0.55, 0.78, 0.25),
	"H": Color(0.74, 0.76, 0.80), "h": Color(0.70, 0.46, 0.22),
	"Z": Color(1.0, 1.0, 1.0), "z": Color(1.0, 1.0, 1.0), "W": Color(1.0, 1.0, 1.0),
}
const DISC_COLORS := {
	"gather": Color(0.20, 0.55, 0.22), "return": Color(0.18, 0.42, 0.75), "build": Color(0.85, 0.48, 0.12),
	"idle": Color(0.92, 0.66, 0.10), "move": Color(0.38, 0.40, 0.44), "attack": Color(0.78, 0.16, 0.14),
}
const ICON_PX := 32

static var _icons: Dictionary = {}

var icon: Sprite3D
var count: Label3D
## "<activity>/<glyph>" shown now, e.g. "gather/gold", "return/wood", "idle/idle".
var key := ""

func _init() -> void:
	name = "VillagerBadge"
	icon = Sprite3D.new()
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.no_depth_test = true
	icon.render_priority = 110
	icon.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	icon.pixel_size = 0.03
	icon.shaded = false
	add_child(icon)
	count = Label3D.new()
	count.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	count.no_depth_test = true
	count.render_priority = 111
	count.font_size = 34
	count.pixel_size = 0.011
	count.outline_size = 9
	count.outline_modulate = Color(0.02, 0.02, 0.02)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# right of the disc, in the label's own (screen-facing) plane: a world offset drifts with perspective
	count.offset = Vector2(52, 0)
	add_child(count)

## activity: gather / return / build / idle / move / attack; glyph: wood / gold / stone / food / build /
## idle / move / attack; load_text: "3/5" or "".
func show_state(activity: String, glyph: String, load_text: String) -> void:
	var k := activity + "/" + glyph
	if k != key:
		key = k
		icon.texture = icon_texture(activity, glyph)
	count.text = load_text
	count.visible = load_text != ""

static func icon_texture(activity: String, glyph: String) -> Texture2D:
	var k := activity + "/" + glyph
	if _icons.has(k):
		return _icons[k]
	var img := Image.create(ICON_PX, ICON_PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var disc: Color = DISC_COLORS.get(activity, DISC_COLORS["move"])
	var c := (ICON_PX - 1) * 0.5
	for y in ICON_PX:
		for x in ICON_PX:
			var d := Vector2(x - c, y - c).length()
			if d <= 15.0:
				img.set_pixel(x, y, Color(0.06, 0.04, 0.02) if d > 13.2 else (disc.lightened(0.18) if d > 11.8 and y < c else disc))
	var rows: Array = GLYPHS.get(glyph, GLYPHS["move"])
	var off := Vector2i(6, 6)
	for gy in rows.size():
		var row: String = rows[gy]
		for gx in row.length():
			var ch := row[gx]
			if ch == ".":
				continue
			var col: Color = GLYPH_COLORS.get(ch, Color.WHITE)
			for sy in 2:
				for sx in 2:
					img.set_pixel(off.x + gx * 2 + sx, off.y + gy * 2 + sy, col)
	var tex := ImageTexture.create_from_image(img)
	_icons[k] = tex
	return tex
