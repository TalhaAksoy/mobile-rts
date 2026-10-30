class_name ParchmentPanel
extends PanelContainer

@export var corner_filigree: bool = true
@export var header_banner: bool = false
@export var banner_title: String = ""

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var r = Rect2(Vector2.ZERO, size)
	
	# 1. Base aged parchment background
	draw_rect(r, ParchmentTheme.PARCHMENT_BG)
	
	# 2. Weathered vignette / burnt edge shading
	var border_inset = 6.0
	draw_rect(Rect2(0, 0, size.x, border_inset), Color(0.78, 0.68, 0.52, 0.6))
	draw_rect(Rect2(0, size.y - border_inset, size.x, border_inset), Color(0.78, 0.68, 0.52, 0.6))
	draw_rect(Rect2(0, 0, border_inset, size.y), Color(0.78, 0.68, 0.52, 0.6))
	draw_rect(Rect2(size.x - border_inset, 0, border_inset, size.y), Color(0.78, 0.68, 0.52, 0.6))
	
	# 3. Outer Dark Leather / Wood Border
	draw_rect(r, ParchmentTheme.LEATHER_BORDER, false, 3.5)
	
	# 4. Inner Fine Gold Inlay Fillet Line
	var inner_r = r.grow(-5.0)
	draw_rect(inner_r, ParchmentTheme.BRONZE_GOLD, false, 1.5)
	
	# 5. Medieval Corner Studs / Filigrees
	if corner_filigree:
		var corners = [
			Vector2(8, 8),
			Vector2(size.x - 8, 8),
			Vector2(8, size.y - 8),
			Vector2(size.x - 8, size.y - 8)
		]
		for c in corners:
			# Bronze rivet stud
			draw_circle(c, 3.5, ParchmentTheme.BRONZE_GOLD)
			draw_circle(c, 2.0, ParchmentTheme.BRONZE_DARK)
			# Diagonal flourish tick
			var dir = (Vector2(size.x * 0.5, size.y * 0.5) - c).normalized()
			draw_line(c, c + dir * 6.0, ParchmentTheme.BRONZE_GOLD, 1.5)
			
	# 6. Header ribbon banner if enabled
	if header_banner and banner_title != "":
		var banner_h = 32.0
		var banner_r = Rect2(10, 8, size.x - 20, banner_h)
		draw_rect(banner_r, ParchmentTheme.PARCHMENT_DARK)
		draw_rect(banner_r, ParchmentTheme.BRONZE_GOLD, false, 2.0)
		var font = ParchmentTheme.get_title_font()
		draw_string(font, Vector2(10, 30), banner_title, HORIZONTAL_ALIGNMENT_CENTER, size.x - 20, 18, ParchmentTheme.INK_DARK)
