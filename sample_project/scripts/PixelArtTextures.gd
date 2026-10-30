class_name PixelArtTextures
extends RefCounted

# Cache generated textures so they are created once
static var _texture_cache: Dictionary = {}

# Standard retro palette colors
const COL_BLACK = Color(0.08, 0.06, 0.05, 1.0)
const COL_DARK_GRAY = Color(0.24, 0.22, 0.24, 1.0)
const COL_MED_GRAY = Color(0.48, 0.46, 0.48, 1.0)
const COL_LIGHT_GRAY = Color(0.78, 0.80, 0.84, 1.0)
const COL_WHITE = Color(0.96, 0.96, 0.98, 1.0)

const COL_SKIN = Color(0.94, 0.76, 0.60, 1.0)
const COL_SKIN_SHADOW = Color(0.78, 0.58, 0.44, 1.0)

const COL_WOOD_DARK = Color(0.32, 0.20, 0.12, 1.0)
const COL_WOOD = Color(0.50, 0.32, 0.18, 1.0)
const COL_WOOD_LIGHT = Color(0.68, 0.48, 0.28, 1.0)

const COL_LEAF_DARK = Color(0.12, 0.34, 0.16, 1.0)
const COL_LEAF_MED = Color(0.22, 0.52, 0.24, 1.0)
const COL_LEAF_LIGHT = Color(0.38, 0.72, 0.32, 1.0)
const COL_LEAF_HIGHLIGHT = Color(0.62, 0.86, 0.44, 1.0)

const COL_GOLD_DARK = Color(0.65, 0.48, 0.10, 1.0)
const COL_GOLD_MED = Color(0.92, 0.74, 0.18, 1.0)
const COL_GOLD_LIGHT = Color(1.0, 0.90, 0.42, 1.0)

const COL_BERRY = Color(0.88, 0.18, 0.24, 1.0)
const COL_BERRY_LIGHT = Color(1.0, 0.42, 0.48, 1.0)

static func create_image_texture(img: Image) -> ImageTexture:
	var tex = ImageTexture.create_from_image(img)
	return tex

# -------------------------------------------------------------
# 1. PIXEL ART NATURE & PROPS
# -------------------------------------------------------------

static func get_oak_tree_texture() -> Texture2D:
	if _texture_cache.has("oak_tree"):
		return _texture_cache["oak_tree"]

	var w = 48
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Trunk
	for y in range(40, 62):
		var tw = 5 if y < 55 else int(5 + (y - 54) * 0.8)
		for x in range(24 - tw, 24 + tw):
			var col = COL_WOOD if (x + y) % 3 != 0 else COL_WOOD_DARK
			if x == 24 - tw or x == 24 + tw - 1:
				col = COL_BLACK
			img.set_pixel(x, y, col)

	# Roots
	for i in range(4):
		img.set_pixel(24 - 5 - i, 61, COL_WOOD_DARK)
		img.set_pixel(24 + 5 + i, 61, COL_WOOD_DARK)

	# Layered Canopy Foliage (3 tiered overlapping clusters)
	var clusters = [
		{"cx": 24, "cy": 22, "rx": 18, "ry": 16},
		{"cx": 18, "cy": 32, "rx": 14, "ry": 12},
		{"cx": 30, "cy": 30, "rx": 15, "ry": 13},
		{"cx": 24, "cy": 36, "rx": 16, "ry": 11}
	]

	for cl in clusters:
		var cx = cl.cx
		var cy = cl.cy
		var rx = cl.rx
		var ry = cl.ry
		for y in range(cy - ry, cy + ry + 1):
			for x in range(cx - rx, cx + rx + 1):
				var dx = float(x - cx) / float(rx)
				var dy = float(y - cy) / float(ry)
				var d2 = dx * dx + dy * dy
				if d2 <= 1.0:
					var edge = d2 > 0.82
					var highlight = dy < -0.35 and dx < 0.2
					var shadow = dy > 0.35
					var col = COL_LEAF_MED
					if edge:
						col = COL_BLACK
					elif highlight:
						col = COL_LEAF_HIGHLIGHT if (x + y) % 2 == 0 else COL_LEAF_LIGHT
					elif shadow:
						col = COL_LEAF_DARK
					else:
						col = COL_LEAF_MED if (x * 3 + y * 7) % 5 != 0 else COL_LEAF_LIGHT
					img.set_pixel(x, y, col)

	var tex = create_image_texture(img)
	_texture_cache["oak_tree"] = tex
	return tex

static func get_pine_tree_texture() -> Texture2D:
	if _texture_cache.has("pine_tree"):
		return _texture_cache["pine_tree"]

	var w = 40
	var h = 64
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Trunk
	for y in range(46, 62):
		for x in range(18, 23):
			img.set_pixel(x, y, COL_WOOD_DARK if x == 18 or x == 22 else COL_WOOD)

	# 4 Stepped Conical Needle Tiers
	var tiers = [
		{"top_y": 6, "bot_y": 20, "max_w": 9},
		{"top_y": 16, "bot_y": 32, "max_w": 13},
		{"top_y": 28, "bot_y": 44, "max_w": 16},
		{"top_y": 38, "bot_y": 52, "max_w": 18}
	]

	for t in tiers:
		for y in range(t.top_y, t.bot_y):
			var pct = float(y - t.top_y) / float(t.bot_y - t.top_y)
			var cur_w = int(pct * t.max_w)
			for x in range(20 - cur_w, 20 + cur_w + 1):
				var is_edge = (x == 20 - cur_w or x == 20 + cur_w or y == t.bot_y - 1)
				var is_light = (x < 20 and y < t.top_y + (t.bot_y - t.top_y) * 0.6)
				var col = COL_LEAF_MED
				if is_edge:
					col = COL_BLACK
				elif is_light:
					col = COL_LEAF_LIGHT if (x + y) % 2 == 0 else COL_LEAF_HIGHLIGHT
				elif y > t.bot_y - 3:
					col = COL_LEAF_DARK
				img.set_pixel(x, y, col)

	var tex = create_image_texture(img)
	_texture_cache["pine_tree"] = tex
	return tex

static func get_gold_node_texture() -> Texture2D:
	if _texture_cache.has("gold_node"):
		return _texture_cache["gold_node"]

	var w = 36
	var h = 36
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Dark boulder foundation
	for y in range(12, 34):
		for x in range(6, 30):
			var dx = float(x - 18) / 11.0
			var dy = float(y - 23) / 10.0
			if dx * dx + dy * dy <= 1.0:
				var col = COL_MED_GRAY if (x + y) % 3 != 0 else COL_DARK_GRAY
				if dx * dx + dy * dy > 0.80:
					col = COL_BLACK
				img.set_pixel(x, y, col)

	# Glistening Golden Crystal Clusters
	var crystals = [
		{"cx": 14, "cy": 18, "r": 5},
		{"cx": 22, "cy": 16, "r": 6},
		{"cx": 17, "cy": 24, "r": 5},
		{"cx": 25, "cy": 23, "r": 4}
	]

	for c in crystals:
		for y in range(c.cy - c.r, c.cy + c.r + 1):
			for x in range(c.cx - c.r, c.cx + c.r + 1):
				var dist = abs(x - c.cx) + abs(y - c.cy)
				if dist <= c.r:
					var col = COL_GOLD_MED
					if dist == c.r:
						col = COL_GOLD_DARK
					elif x <= c.cx and y <= c.cy:
						col = COL_GOLD_LIGHT
					img.set_pixel(x, y, col)
		# Shiny glint star
		img.set_pixel(c.cx - 1, c.cy - 1, COL_WHITE)

	var tex = create_image_texture(img)
	_texture_cache["gold_node"] = tex
	return tex

static func get_stone_node_texture() -> Texture2D:
	if _texture_cache.has("stone_node"):
		return _texture_cache["stone_node"]

	var w = 36
	var h = 36
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Heavy Granite Stone Boulder Quarry
	for y in range(10, 34):
		for x in range(5, 31):
			var dx = float(x - 18) / 12.0
			var dy = float(y - 22) / 11.0
			if dx * dx + dy * dy <= 1.0:
				var col = Color(0.52, 0.53, 0.56)
				# Rock strata bands
				if (x + y * 2) % 7 == 0:
					col = Color(0.38, 0.39, 0.42)
				elif (x * 3 + y) % 8 == 0:
					col = Color(0.68, 0.69, 0.72)
				if dx * dx + dy * dy > 0.82:
					col = Color(0.18, 0.18, 0.20)
				elif x < 18 and y < 22:
					col = Color(0.74, 0.75, 0.78)
				img.set_pixel(x, y, col)

	# Chiseled facets
	for y in range(14, 28):
		img.set_pixel(15, y, Color(0.24, 0.25, 0.28))
		img.set_pixel(22, y, Color(0.28, 0.29, 0.32))

	var tex = create_image_texture(img)
	_texture_cache["stone_node"] = tex
	return tex

static func get_berry_bush_texture() -> Texture2D:
	if _texture_cache.has("berry_bush"):
		return _texture_cache["berry_bush"]

	var w = 36
	var h = 36
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Shrub foliage
	for y in range(10, 32):
		for x in range(5, 31):
			var dx = float(x - 18) / 12.0
			var dy = float(y - 21) / 10.0
			if dx * dx + dy * dy <= 1.0:
				var col = COL_LEAF_MED
				if dx * dx + dy * dy > 0.82:
					col = COL_BLACK
				elif dy < -0.3 and dx < 0.2:
					col = COL_LEAF_LIGHT
				elif dy > 0.3:
					col = COL_LEAF_DARK
				img.set_pixel(x, y, col)

	# Ripe red berry clusters
	var berry_spots = [
		Vector2i(12, 16), Vector2i(18, 14), Vector2i(24, 17),
		Vector2i(14, 22), Vector2i(21, 21), Vector2i(16, 26),
		Vector2i(26, 23), Vector2i(10, 20)
	]
	for p in berry_spots:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if abs(dx) + abs(dy) <= 1:
					img.set_pixel(p.x + dx, p.y + dy, COL_BERRY)
		img.set_pixel(p.x, p.y, COL_BERRY_LIGHT)

	var tex = create_image_texture(img)
	_texture_cache["berry_bush"] = tex
	return tex

# -------------------------------------------------------------
# 2. PIXEL ART UNITS
# -------------------------------------------------------------

static func get_unit_pixel_sprite(u_type: int, team: int, action: String = "idle", step_phase: float = 0.0) -> Texture2D:
	var cache_key = "unit_%d_%d_%s_%d" % [u_type, team, action, int(step_phase * 4.0)]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var w = 32
	var h = 36
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var team_col = Color(0.20, 0.55, 0.95) if team == 0 else Color(0.95, 0.22, 0.22)
	var team_dark = Color(0.10, 0.30, 0.65) if team == 0 else Color(0.60, 0.12, 0.12)
	var team_light = Color(0.50, 0.75, 1.0) if team == 0 else Color(1.0, 0.45, 0.45)

	var walk_offset = int(sin(step_phase * TAU) * 1.5) if action == "move" else 0
	var swing_frame = (action in ["gather", "attack", "build"])

	# Shadow on ground
	for sx in range(10, 22):
		for sy in range(32, 35):
			if float((sx - 16) * (sx - 16)) / 30.0 + float((sy - 33) * (sy - 33)) / 2.0 <= 1.0:
				img.set_pixel(sx, sy, Color(0.05, 0.04, 0.03, 0.45))

	# Legs / Boots
	var l_leg_y = 26 + walk_offset
	var r_leg_y = 26 - walk_offset
	for y in range(24, 30):
		for x in range(12, 15):
			img.set_pixel(x, y + (walk_offset if y >= 26 else 0), COL_BLACK if y == 29 else COL_DARK_GRAY)
		for x in range(17, 20):
			img.set_pixel(x, y - (walk_offset if y >= 26 else 0), COL_BLACK if y == 29 else COL_DARK_GRAY)

	# Torso & Tunic
	for y in range(16, 24):
		for x in range(11, 21):
			var is_edge = (x == 11 or x == 20 or y == 16 or y == 23)
			var col = team_col
			if is_edge:
				col = COL_BLACK
			elif y == 22:
				col = COL_WOOD_DARK # Belt
			elif y == 22 and x in [15, 16]:
				col = COL_GOLD_MED # Belt buckle
			elif x <= 14:
				col = team_light
			elif x >= 18:
				col = team_dark
			img.set_pixel(x, y, col)

	# Arms
	# Left arm
	for y in range(17, 23):
		for x in range(9, 12):
			img.set_pixel(x, y, COL_BLACK if x == 9 or y == 22 else team_col)
	img.set_pixel(10, 23, COL_SKIN)

	# Right arm (Weapon hand)
	var r_arm_y_off = -4 if swing_frame else 0
	for y in range(17 + r_arm_y_off, 23 + r_arm_y_off):
		for x in range(20, 23):
			img.set_pixel(x, y, COL_BLACK if x == 22 or y == 22 + r_arm_y_off else team_col)
	img.set_pixel(21, 23 + r_arm_y_off, COL_SKIN)

	# Head & Face
	for y in range(9, 16):
		for x in range(12, 20):
			var is_edge = (x == 12 or x == 19 or y == 9 or y == 15)
			var col = COL_SKIN
			if is_edge:
				col = COL_BLACK
			elif x >= 17:
				col = COL_SKIN_SHADOW
			img.set_pixel(x, y, col)

	# Eyes
	img.set_pixel(14, 12, COL_BLACK)
	img.set_pixel(17, 12, COL_BLACK)

	# Headwear & Tools based on Unit Type
	match u_type:
		0: # VILLAGER
			# Broad Brimmed Straw Peasant Hat
			for x in range(8, 24):
				img.set_pixel(x, 9, COL_BLACK)
				img.set_pixel(x, 8, COL_GOLD_MED if (x + 8) % 2 == 0 else COL_GOLD_LIGHT)
			for y in range(5, 8):
				for x in range(12, 20):
					var is_e = (x == 12 or x == 19 or y == 5)
					img.set_pixel(x, y, COL_BLACK if is_e else COL_GOLD_MED)

			# Backpack wicker basket
			for by in range(15, 23):
				for bx in range(6, 11):
					var col = COL_WOOD if (bx + by) % 2 == 0 else COL_WOOD_DARK
					if bx == 6 or by == 22: col = COL_BLACK
					img.set_pixel(bx, by, col)

			# Woodcutter Axe / Pickaxe in hand
			var ax_rot_y = -6 if swing_frame else 0
			# Wooden handle
			for hy in range(14 + ax_rot_y, 25 + ax_rot_y):
				img.set_pixel(23, hy, COL_WOOD)
			# Steel axe blade
			for ay in range(13 + ax_rot_y, 18 + ax_rot_y):
				for ax in range(24, 28):
					img.set_pixel(ax, ay, COL_LIGHT_GRAY if ax == 27 else COL_MED_GRAY)
				img.set_pixel(28, ay, COL_WHITE)

		1, 10: # SWORDSMAN, PALADIN
			# Crusader Greathelm with Visor Slit
			for y in range(6, 11):
				for x in range(11, 21):
					var is_edge = (x == 11 or x == 20 or y == 6)
					img.set_pixel(x, y, COL_BLACK if is_edge else COL_LIGHT_GRAY)
			for vx in range(13, 19):
				img.set_pixel(vx, 10, COL_BLACK) # Visor slit
			# Red Plume feather
			for py in range(2, 6):
				img.set_pixel(16, py, COL_BERRY)

			# Heater Shield on left arm
			for sy in range(17, 26):
				for sx in range(6, 12):
					var col = team_col if sx in [8, 9] or sy in [20, 21] else COL_WHITE
					if sx == 6 or sx == 11 or sy == 25: col = COL_BLACK
					img.set_pixel(sx, sy, col)

			# Steel Broadsword on right
			for by in range(6, 24):
				img.set_pixel(24, by, COL_WHITE if by < 16 else COL_LIGHT_GRAY)
			for gx in range(22, 27):
				img.set_pixel(gx, 19, COL_GOLD_MED) # Crossguard

		2, 7: # ARCHER, LONGBOWMAN
			# Feathered archer cap
			for y in range(6, 10):
				for x in range(11, 21):
					img.set_pixel(x, y, COL_LEAF_DARK if x == 11 or x == 20 else COL_LEAF_MED)
			img.set_pixel(19, 5, COL_BERRY)
			img.set_pixel(20, 4, COL_WHITE)

			# Wooden Bow
			for by in range(10, 28):
				var bx = 24 + int(abs(by - 19) * 0.4)
				img.set_pixel(bx, by, COL_WOOD_DARK)
			# Bowstring
			for sy in range(12, 26):
				img.set_pixel(23, sy, COL_LIGHT_GRAY)

		_: # Generic Elite Warrior (Spear, Janissary, Samurai, etc.)
			# Conical / ornate helmet
			for y in range(5, 10):
				var hw = int((10 - y) * 1.4)
				for x in range(16 - hw, 16 + hw):
					img.set_pixel(x, y, COL_LIGHT_GRAY if x < 16 else COL_MED_GRAY)

			# Spear or Halberd
			for py in range(2, 30):
				img.set_pixel(24, py, COL_WOOD)
			# Steel Spearhead
			for ty in range(0, 5):
				img.set_pixel(24, ty, COL_WHITE)
				if ty >= 2:
					img.set_pixel(23, ty, COL_LIGHT_GRAY)
					img.set_pixel(25, ty, COL_LIGHT_GRAY)

	var tex = create_image_texture(img)
	_texture_cache[cache_key] = tex
	return tex

# -------------------------------------------------------------
# 3. DIORAMA TERRAIN TILES
# -------------------------------------------------------------

static func get_diorama_grass_texture() -> Texture2D:
	if _texture_cache.has("diorama_grass"):
		return _texture_cache["diorama_grass"]

	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var base_green = Color(0.28, 0.58, 0.24)
	var light_green = Color(0.36, 0.68, 0.28)
	var dark_green = Color(0.20, 0.46, 0.18)

	for y in range(size):
		for x in range(size):
			var n = (x * 7 + y * 13) % 11
			var col = base_green
			if n == 0 or n == 1:
				col = light_green
			elif n == 7 or n == 8:
				col = dark_green
			# Pixel grass blades
			if (x % 6 == 0 and y % 4 == 0):
				col = Color(0.44, 0.78, 0.32)
			# Occasional tiny wildflower
			if (x == 12 and y == 14) or (x == 26 and y == 22):
				col = Color(0.95, 0.85, 0.30)
			img.set_pixel(x, y, col)

	var tex = create_image_texture(img)
	_texture_cache["diorama_grass"] = tex
	return tex

static func get_stepped_cliff_texture() -> Texture2D:
	if _texture_cache.has("stepped_cliff"):
		return _texture_cache["stepped_cliff"]

	var w = 32
	var h = 32
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var stone_base = Color(0.44, 0.40, 0.36)
	var stone_dark = Color(0.28, 0.24, 0.22)
	var stone_light = Color(0.60, 0.56, 0.50)
	var earth_strata = Color(0.38, 0.28, 0.20)

	for y in range(h):
		var is_strata_line = (y % 8 == 0 or y % 8 == 1)
		for x in range(w):
			var col = stone_base
			if is_strata_line:
				col = earth_strata if (x + y) % 3 != 0 else stone_dark
			elif (x + y * 2) % 7 == 0:
				col = stone_light
			elif (x * 3 + y) % 9 == 0:
				col = stone_dark
			# Top grass overhang fringe
			if y <= 2:
				col = Color(0.24, 0.52, 0.20) if (x + y) % 2 == 0 else COL_BLACK
			img.set_pixel(x, y, col)

	var tex = create_image_texture(img)
	_texture_cache["stepped_cliff"] = tex
	return tex

static func get_cobblestone_path_texture() -> Texture2D:
	if _texture_cache.has("cobblestone_path"):
		return _texture_cache["cobblestone_path"]

	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var mortar_col = Color(0.28, 0.24, 0.20)
	var paver_base = Color(0.55, 0.52, 0.48)
	var paver_light = Color(0.68, 0.64, 0.60)
	var paver_dark = Color(0.42, 0.38, 0.35)

	for y in range(size):
		for x in range(size):
			var bx = x % 8
			var by = y % 8
			var is_mortar = (bx == 0 or by == 0)
			var col = paver_base
			if is_mortar:
				col = mortar_col
			elif bx == 1 or by == 1:
				col = paver_light
			elif bx == 7 or by == 7:
				col = paver_dark
			img.set_pixel(x, y, col)

	var tex = create_image_texture(img)
	_texture_cache["cobblestone_path"] = tex
	return tex

static func get_diorama_wood_base_texture() -> Texture2D:
	if _texture_cache.has("diorama_wood_base"):
		return _texture_cache["diorama_wood_base"]

	var w = 16
	var h = 32
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var dark_walnut = Color(0.18, 0.12, 0.08)
	var grain_light = Color(0.28, 0.18, 0.12)
	var brass_trim = Color(0.85, 0.70, 0.25)

	for y in range(h):
		for x in range(w):
			var col = dark_walnut
			if y <= 1 or y >= h - 2:
				col = brass_trim if (x + y) % 3 != 0 else Color(0.45, 0.35, 0.12)
			elif (y % 4 == 0):
				col = grain_light
			img.set_pixel(x, y, col)

	var tex = create_image_texture(img)
	_texture_cache["diorama_wood_base"] = tex
	return tex

static func get_stone_brick_texture() -> Texture2D:
	if _texture_cache.has("stone_brick"):
		return _texture_cache["stone_brick"]

	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var mortar = Color(0.28, 0.26, 0.25)
	var stone_base = Color(0.58, 0.59, 0.62)
	var stone_dark = Color(0.46, 0.47, 0.50)
	var stone_light = Color(0.72, 0.73, 0.76)

	for y in range(size):
		var row = y / 8
		var row_y = y % 8
		var x_shift = 8 if (row % 2 == 1) else 0

		for x in range(size):
			var col = stone_base
			var cur_x = (x + x_shift) % 16
			# Mortar lines
			if row_y == 0 or cur_x == 0:
				col = mortar
			elif row_y == 1 or cur_x == 1:
				col = stone_light
			elif row_y == 7 or cur_x == 15:
				col = stone_dark
			elif (x * 7 + y * 13) % 9 == 0:
				col = stone_light
			elif (x * 11 + y * 5) % 8 == 0:
				col = stone_dark

			img.set_pixel(x, y, col)

	var tex = create_image_texture(img)
	_texture_cache["stone_brick"] = tex
	return tex

static func get_roof_tile_texture() -> Texture2D:
	if _texture_cache.has("roof_tile"):
		return _texture_cache["roof_tile"]

	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var tile_base = Color(0.72, 0.28, 0.20)
	var tile_dark = Color(0.50, 0.16, 0.10)
	var tile_light = Color(0.86, 0.40, 0.30)
	var mortar = Color(0.32, 0.12, 0.08)

	for y in range(size):
		var row = y / 8
		var row_y = y % 8
		var x_shift = 8 if (row % 2 == 1) else 0

		for x in range(size):
			var cur_x = (x + x_shift) % 16
			var col = tile_base
			if row_y == 0 or cur_x == 0:
				col = mortar
			elif row_y == 1:
				col = tile_light
			elif row_y == 7 or cur_x == 15:
				col = tile_dark
			img.set_pixel(x, y, col)

	var tex = create_image_texture(img)
	_texture_cache["roof_tile"] = tex
	return tex

static func get_timber_wall_texture() -> Texture2D:
	if _texture_cache.has("timber_wall"):
		return _texture_cache["timber_wall"]

	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var plaster = Color(0.88, 0.84, 0.74)
	var plaster_shadow = Color(0.76, 0.72, 0.62)
	var beam_dark = Color(0.24, 0.14, 0.08)
	var beam_wood = Color(0.42, 0.26, 0.15)
	var beam_light = Color(0.58, 0.38, 0.22)

	for y in range(size):
		for x in range(size):
			var is_beam = (x < 3 or x >= size - 3 or y < 3 or y >= size - 3 or x == y or x == (size - 1 - y))
			var col = plaster
			if is_beam:
				col = beam_wood
				if x == 0 or y == 0 or x == (size - 1) or y == (size - 1):
					col = beam_dark
				elif (x + y) % 5 == 0:
					col = beam_light
			else:
				if (x * 3 + y * 7) % 7 == 0:
					col = plaster_shadow
			img.set_pixel(x, y, col)

	var tex = create_image_texture(img)
	_texture_cache["timber_wall"] = tex
	return tex

static func get_wood_plank_texture() -> Texture2D:
	if _texture_cache.has("wood_plank"):
		return _texture_cache["wood_plank"]

	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var plank_base = Color(0.50, 0.34, 0.20)
	var plank_dark = Color(0.32, 0.20, 0.10)
	var plank_light = Color(0.66, 0.46, 0.28)
	var nail = Color(0.20, 0.20, 0.22)

	for y in range(size):
		var row_y = y % 8
		for x in range(size):
			var col = plank_base
			if row_y == 0:
				col = plank_dark
			elif row_y == 1:
				col = plank_light
			elif (x == 4 or x == 20) and (row_y == 4):
				col = nail
			elif (x * 13 + y) % 9 == 0:
				col = plank_dark
			img.set_pixel(x, y, col)

	var tex = create_image_texture(img)
	_texture_cache["wood_plank"] = tex
	return tex

# -------------------------------------------------------------
# 4. CIVILIZATION HERALDIC FLAGS (32x22 Pixel Art)
# -------------------------------------------------------------

static func get_civ_flag_texture(civ_type: int) -> Texture2D:
	var cache_key = "civ_flag_%d" % civ_type
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var w = 32
	var h = 22
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var border_col = Color(0.12, 0.10, 0.08, 1.0)
	var fringe_col = Color(0.95, 0.82, 0.25, 1.0)

	# 1. Base Field by Civilization
	var base_col = Color(0.82, 0.15, 0.15)
	match civ_type:
		0: base_col = Color(0.85, 0.12, 0.12) # Ottomans Crimson
		1: base_col = Color(0.52, 0.12, 0.42) # Byzantines Imperial Purple
		2: base_col = Color(0.95, 0.95, 0.95) # Britons White
		3: base_col = Color(0.14, 0.28, 0.72) # Franks Royal Blue
		4: base_col = Color(0.18, 0.56, 0.88) # Mongols Steppe Sky Blue
		5: base_col = Color(0.92, 0.92, 0.94) # Teutons White
		6: base_col = Color(0.96, 0.96, 0.96) # Japanese White
		7: base_col = Color(0.10, 0.55, 0.22) # Saracens Emerald Green
		8: base_col = Color(0.20, 0.22, 0.28) # Vikings Charcoal Navy
		9: base_col = Color(0.95, 0.80, 0.15) # Chinese Imperial Gold

	img.fill(base_col)

	# 2. Heraldic Insignia & Crosses
	match civ_type:
		0: # Ottomans: Gold fringe + Golden Crescent & 8-point Star
			var c_col = Color(0.98, 0.88, 0.32)
			for x in range(w):
				for y in range(h):
					var cx = x - 13.0
					var cy = y - 11.0
					var d1 = sqrt(cx * cx + cy * cy)
					var d2 = sqrt((cx - 2.8) * (cx - 2.8) + cy * cy)
					if d1 <= 5.8 and d2 >= 4.5:
						img.set_pixel(x, y, c_col)
					# Star
					if abs(x - 20) <= 2 and abs(y - 11) <= 2:
						if (abs(x - 20) + abs(y - 11)) <= 2:
							img.set_pixel(x, y, c_col)

		1: # Byzantines: Gold double-cross + 4 Firesteels (B's)
			var g_col = Color(0.95, 0.85, 0.25)
			for x in range(w):
				for y in range(h):
					if abs(x - 16) <= 1 or abs(y - 11) <= 1:
						img.set_pixel(x, y, g_col)
					if (x in [8, 24]) and (y in [5, 17]):
						img.set_pixel(x, y, g_col)

		2: # Britons: Bold Red St. George Cross
			var r_col = Color(0.85, 0.15, 0.15)
			for x in range(w):
				for y in range(h):
					if abs(x - 14) <= 2 or abs(y - 11) <= 2:
						img.set_pixel(x, y, r_col)

		3: # Franks: 3 Golden Fleurs-de-lis
			var f_col = Color(0.98, 0.85, 0.22)
			for pos in [Vector2i(10, 8), Vector2i(22, 8), Vector2i(16, 15)]:
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						if abs(dx) + abs(dy) <= 2:
							img.set_pixel(pos.x + dx, pos.y + dy, f_col)
				img.set_pixel(pos.x, pos.y - 3, f_col)

		4: # Mongols: Golden Soyombo Sun & Flame
			var m_col = Color(0.98, 0.86, 0.20)
			for x in range(w):
				for y in range(h):
					if x >= 6 and x <= 12 and y >= 6 and y <= 16:
						if y == 6 or y == 16 or x == 6 or x == 12 or y == 11:
							img.set_pixel(x, y, m_col)
					if x >= 20 and x <= 26 and (y in [8, 11, 14]):
						img.set_pixel(x, y, m_col)

		5: # Teutons: Black Teutonic Cross with Gold inner core
			var b_col = Color(0.12, 0.12, 0.14)
			var c_gold = Color(0.95, 0.82, 0.25)
			for x in range(w):
				for y in range(h):
					if abs(x - 16) <= 3 or abs(y - 11) <= 3:
						img.set_pixel(x, y, b_col)
					if abs(x - 16) <= 1 and abs(y - 11) <= 1:
						img.set_pixel(x, y, c_gold)

		6: # Japanese: Radiant Crimson Sun Disc with Gold Rim
			var s_col = Color(0.88, 0.12, 0.16)
			for x in range(w):
				for y in range(h):
					var d = sqrt((x - 16.0) * (x - 16.0) + (y - 11.0) * (y - 11.0))
					if d <= 6.0:
						img.set_pixel(x, y, s_col)

		7: # Saracens: Golden Scimitar and Crescent
			var s_gold = Color(0.96, 0.86, 0.24)
			for x in range(w):
				for y in range(h):
					# Scimitar blade curve
					if abs(y - 13 - int(sin(x * 0.18) * 3.0)) <= 1 and x >= 6 and x <= 25:
						img.set_pixel(x, y, s_gold)
					if x == 7 and abs(y - 13) <= 3:
						img.set_pixel(x, y, s_gold)

		8: # Vikings: Raven Banner Emblem
			var r_raven = Color(0.10, 0.10, 0.12)
			for x in range(w):
				for y in range(h):
					var cx = x - 16
					var cy = y - 11
					if (abs(cx) * 0.7 + abs(cy)) <= 5:
						img.set_pixel(x, y, r_raven)
					if (cx in [-4, 4]) and cy >= -3 and cy <= 2:
						img.set_pixel(x, y, r_raven)

		9: # Chinese: Imperial Crimson Dragon Silhouette
			var d_col = Color(0.85, 0.14, 0.14)
			for x in range(w):
				for y in range(h):
					if (x + y) % 6 == 0 and x >= 6 and x <= 26 and y >= 5 and y <= 17:
						img.set_pixel(x, y, d_col)
					if abs(x - 16) <= 4 and abs(y - 11) <= 2:
						img.set_pixel(x, y, d_col)

	# 3. Embroidered Border Frame & Gold Fringe
	for x in range(w):
		img.set_pixel(x, 0, fringe_col)
		img.set_pixel(x, h - 1, fringe_col)
		img.set_pixel(x, 1, border_col)
		img.set_pixel(x, h - 2, border_col)
	for y in range(h):
		img.set_pixel(0, y, fringe_col)
		img.set_pixel(w - 1, y, fringe_col)
		img.set_pixel(1, y, border_col)
		img.set_pixel(w - 2, y, border_col)

	var tex = create_image_texture(img)
	_texture_cache[cache_key] = tex
	return tex

# -------------------------------------------------------------
# 5. REPRESENTATIVE BUILDING ICONS (36x36 Pixel Art Cards)
# -------------------------------------------------------------

static func get_building_icon_texture(b_type: int) -> Texture2D:
	var cache_key = "b_icon_%d" % b_type
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var size = 36
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	# Parchment Card Base
	img.fill(Color(0.92, 0.86, 0.72))

	# Card Border
	var border = Color(0.35, 0.22, 0.12)
	for i in range(size):
		img.set_pixel(i, 0, border); img.set_pixel(i, size - 1, border)
		img.set_pixel(0, i, border); img.set_pixel(size - 1, i, border)

	# Draw Distinct Representative Icon
	match b_type:
		0: # TOWN_CENTER: Grand Castle Keep with Towers & Gate
			var stone = Color(0.65, 0.65, 0.70)
			var roof = Color(0.85, 0.32, 0.22)
			var door = Color(0.42, 0.26, 0.14)
			# Wall
			for x in range(8, 28):
				for y in range(16, 31):
					img.set_pixel(x, y, stone)
			# Roof
			for y in range(8, 16):
				var span = (y - 8) * 1.3
				for x in range(int(18 - span), int(18 + span)):
					img.set_pixel(x, y, roof)
			# Door & Towers
			for x in range(15, 21):
				for y in range(23, 31):
					img.set_pixel(x, y, door)
			for y in range(10, 31):
				img.set_pixel(6, y, stone); img.set_pixel(7, y, stone)
				img.set_pixel(28, y, stone); img.set_pixel(29, y, stone)

		1: # HOUSE: Cozy Cottage with Thatched Roof & Chimney
			var timber = Color(0.88, 0.82, 0.68)
			var thatch = Color(0.78, 0.58, 0.24)
			var chim = Color(0.55, 0.55, 0.58)
			for x in range(10, 26):
				for y in range(18, 30):
					img.set_pixel(x, y, timber)
			for y in range(10, 18):
				var span = (y - 10) * 1.2
				for x in range(int(18 - span), int(18 + span)):
					img.set_pixel(x, y, thatch)
			for x in range(21, 25):
				for y in range(6, 14):
					img.set_pixel(x, y, chim)

		2: # BARRACKS: Crossed Steel Swords
			var steel = Color(0.85, 0.88, 0.94)
			var hilt = Color(0.92, 0.72, 0.20)
			for i in range(-10, 11):
				var p1 = Vector2i(18 + i, 18 + i)
				var p2 = Vector2i(18 - i, 18 + i)
				if p1.x >= 2 and p1.x < size - 2 and p1.y >= 2 and p1.y < size - 2:
					img.set_pixel(p1.x, p1.y, steel)
					img.set_pixel(p1.x + 1, p1.y, steel)
				if p2.x >= 2 and p2.x < size - 2 and p2.y >= 2 and p2.y < size - 2:
					img.set_pixel(p2.x, p2.y, steel)
					img.set_pixel(p2.x + 1, p2.y, steel)
			# Hilts
			for x in range(6, 12):
				img.set_pixel(x, 26, hilt); img.set_pixel(34 - x, 26, hilt)

		3: # ARCHERY_RANGE: Bow & Aiming Arrow
			var wood = Color(0.55, 0.35, 0.18)
			var arrow = Color(0.92, 0.25, 0.25)
			var fletch = Color(0.95, 0.95, 0.95)
			for y in range(8, 28):
				var bow_x = int(12 + sin((y - 8) / 20.0 * PI) * 6.0)
				img.set_pixel(bow_x, y, wood)
				img.set_pixel(18, y, Color(0.8, 0.8, 0.8, 0.7)) # String
			for x in range(10, 27):
				img.set_pixel(x, 18, arrow)
			img.set_pixel(27, 18, Color(0.3, 0.3, 0.35))
			img.set_pixel(10, 17, fletch); img.set_pixel(10, 19, fletch)

		4: # STABLE: Golden Horseshoe
			var gold = Color(0.95, 0.78, 0.18)
			var inner = Color(0.92, 0.86, 0.72)
			for x in range(size):
				for y in range(size):
					var d = sqrt((x - 18.0) * (x - 18.0) + (y - 18.0) * (y - 18.0))
					if d >= 7.0 and d <= 11.0 and (y <= 24 or abs(x - 18) >= 5):
						img.set_pixel(x, y, gold)

		5: # CASTLE: Fortified Grand Castle
			var stone = Color(0.60, 0.62, 0.68)
			var dark_s = Color(0.40, 0.42, 0.46)
			var flag = Color(0.88, 0.18, 0.18)
			for x in range(6, 30):
				for y in range(14, 30):
					img.set_pixel(x, y, stone)
			# Battlements
			for x in range(6, 30, 4):
				img.set_pixel(x, 12, dark_s); img.set_pixel(x + 1, 12, dark_s)
			# Portcullis Gate
			for x in range(14, 22):
				for y in range(22, 30):
					if x % 2 == 0 or y % 2 == 0:
						img.set_pixel(x, y, Color(0.2, 0.2, 0.2))
			# Banner
			for x in range(18, 24):
				for y in range(6, 11):
					img.set_pixel(x, y, flag)

		6: # TOWER: Tall Stone Watchtower
			var stone = Color(0.68, 0.70, 0.75)
			var wood = Color(0.48, 0.32, 0.18)
			for x in range(13, 23):
				for y in range(10, 31):
					img.set_pixel(x, y, stone)
			# Machicolations
			for x in range(11, 25):
				for y in range(8, 12):
					img.set_pixel(x, y, wood)
			# Arrow slit
			for y in range(16, 22):
				img.set_pixel(18, y, Color(0.15, 0.15, 0.18))

		7: # FARM: Golden Wheat Bundle with Sickle
			var wheat = Color(0.95, 0.82, 0.22)
			var iron = Color(0.72, 0.74, 0.78)
			for i in range(-5, 6):
				var wx = 18 + i
				for y in range(14, 29):
					if abs(wx - 18) <= (y - 14) * 0.4:
						img.set_pixel(wx, y, wheat)
			# Sickle curve
			for a in range(12):
				var sx = int(14 + cos(a * 0.3) * 6.0)
				var sy = int(14 + sin(a * 0.3) * 6.0)
				if sx >= 2 and sx < size - 2 and sy >= 2 and sy < size - 2:
					img.set_pixel(sx, sy, iron)

		8: # BLACKSMITH: Iron Anvil & Blazing Fire
			var iron = Color(0.35, 0.38, 0.44)
			var fire = Color(1.0, 0.45, 0.10)
			# Fire
			for x in range(14, 22):
				for y in range(6, 16):
					if abs(x - 18) <= (16 - y) * 0.5:
						img.set_pixel(x, y, fire)
			# Anvil
			for x in range(8, 28):
				for y in range(18, 22):
					img.set_pixel(x, y, iron)
			for x in range(14, 22):
				for y in range(22, 27):
					img.set_pixel(x, y, iron)
			for x in range(11, 25):
				for y in range(27, 30):
					img.set_pixel(x, y, iron)

	var tex = create_image_texture(img)
	_texture_cache[cache_key] = tex
	return tex
