class_name HD2DGround
extends RefCounted
## Builds the terrain control texture for shaders/hd2d_ground.gdshader.
##   R = road / path   G = bare dirt   B = alternate ground   A = macro light variation
## Roads follow real A* routes (base -> base, base -> its gold/stone/food clusters), so they bend
## around trees and water like worn paths. Called after MapGenerator3D has built A*.

const RES: int = 4                 # control pixels per map cell (cell = 2 m)
const ROAD_HALF_W: float = 0.55    # in cells
const SPUR_HALF_W: float = 0.38
const COURTYARD_R: float = 2.7

const TEX_DIR := "res://assets/3d/materials/textures/"
## [base ground, alternate patches] per biome (dirt / path textures are shared)
const BIOME_GROUND := {
	"temperate": ["GR_GrassLush.png", "GR_GrassDry.png"],
	"desert": ["GR_Sand.png", "GR_SandDark.png"],
	"steppe": ["GR_GrassSteppe.png", "GR_GrassDry.png"],
	"autumn": ["GR_GrassAutumn.png", "GR_GrassDry.png"],
}
## water palette per biome: [deep, mid, light]
const BIOME_WATER := {
	"temperate": [Color(0.05, 0.17, 0.26), Color(0.09, 0.29, 0.38), Color(0.28, 0.55, 0.62)],
	"desert": [Color(0.04, 0.22, 0.30), Color(0.07, 0.40, 0.46), Color(0.36, 0.72, 0.70)],
	"steppe": [Color(0.06, 0.14, 0.24), Color(0.12, 0.25, 0.36), Color(0.36, 0.50, 0.60)],
	"autumn": [Color(0.05, 0.15, 0.20), Color(0.10, 0.26, 0.30), Color(0.32, 0.50, 0.50)],
}

## multiplies the procedural cliff texture so plateau edges match the biome's rock
const BIOME_CLIFF_TINT := {
	"temperate": Color(1, 1, 1),
	"desert": Color(1.0, 0.84, 0.62),
	"steppe": Color(0.9, 0.93, 1.0),
	"autumn": Color(1.0, 0.9, 0.8),
}

static func cliff_tint(map_type: int) -> Color:
	return BIOME_CLIFF_TINT.get(CivData.get_biome(map_type), Color(1, 1, 1))

static func apply_water_palette(mat: ShaderMaterial, map_type: int) -> void:
	var w: Array = BIOME_WATER.get(CivData.get_biome(map_type), BIOME_WATER["temperate"])
	mat.set_shader_parameter("deep_color", w[0])
	mat.set_shader_parameter("mid_color", w[1])
	mat.set_shader_parameter("light_color", w[2])

static func make_material(map_type: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/hd2d_ground.gdshader")
	var tex: Array = BIOME_GROUND.get(CivData.get_biome(map_type), BIOME_GROUND["temperate"])
	m.set_shader_parameter("tex_base", load(TEX_DIR + tex[0]))
	m.set_shader_parameter("tex_alt", load(TEX_DIR + tex[1]))
	m.set_shader_parameter("tex_dirt", load(TEX_DIR + "GR_Dirt.png"))
	m.set_shader_parameter("tex_path", load(TEX_DIR + "GR_Path.png"))
	return m

static func build_control_image(mg) -> Image:
	var w: int = mg.MAP_WIDTH * RES
	var h: int = mg.MAP_HEIGHT * RES
	var road := PackedFloat32Array(); road.resize(w * h)
	var dirt := PackedFloat32Array(); dirt.resize(w * h)

	var bases: Array[Vector2i] = []
	for sp in mg.start_positions:
		bases.append(mg.world_to_cell(sp))
	if bases.size() <= 2:
		# main road between the bases, leaving each TC from its front door
		var p_front: Vector3 = mg.player_start_pos + Vector3(0, 0, -3.5 * mg.TILE_SIZE)
		var e_front: Vector3 = mg.enemy_start_pos + Vector3(0, 0, 3.5 * mg.TILE_SIZE)
		_stamp_path(road, w, h, mg, mg.get_path_to_target(p_front, e_front), ROAD_HALF_W)
	else:
		# more bots: a road from every base, out of the side facing the map centre, to the centre
		var centre: Vector3 = mg.cell_to_world(Vector2i(int(mg.MAP_WIDTH * 0.5), int(mg.MAP_HEIGHT * 0.5)))
		for sp in mg.start_positions:
			var dir: Vector3 = (centre - sp)
			dir.y = 0.0
			var front: Vector3 = sp + dir.normalized() * 3.5 * mg.TILE_SIZE
			_stamp_path(road, w, h, mg, mg.get_path_to_target(front, centre), ROAD_HALF_W)
	# spurs from each base to its resource clusters (same offsets as MapGenerator3D._spawn_base_cluster)
	for bc in bases:
		var dir_y := 1 if bc.y > int(mg.MAP_HEIGHT * 0.5) else -1
		var from: Vector3 = mg.cell_to_world(bc)
		for off in [Vector2i(-5, 0), Vector2i(-6, 3 * dir_y), Vector2i(5, 0)]:
			_stamp_path(road, w, h, mg, mg.get_path_to_target(from, mg.cell_to_world(bc + off)), SPUR_HALF_W)

	var edge := FastNoiseLite.new()
	edge.seed = mg.seed_val + 11
	edge.frequency = 0.25
	# worn courtyard around each Town Center
	for bc in bases:
		_stamp_disc(dirt, w, h, Vector2(bc) + Vector2(0.5, 0.5), COURTYARD_R, edge)
	# rocky ground around mines
	for c in mg.gold_mines.keys() + mg.stone_mines.keys():
		_stamp_disc(dirt, w, h, Vector2(c) + Vector2(0.5, 0.5), 1.15, edge)

	var dry := FastNoiseLite.new()
	dry.seed = mg.seed_val + 4242
	dry.frequency = 0.045
	var light := FastNoiseLite.new()
	light.seed = mg.seed_val + 9001
	light.frequency = 0.02
	var patches := FastNoiseLite.new()
	patches.seed = mg.seed_val + 313
	patches.frequency = 0.12

	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for py in h:
		for px in w:
			var i := py * w + px
			var cx := float(px) / RES
			var cy := float(py) / RES
			var b := clampf(dry.get_noise_2d(cx * RES, cy * RES) * 1.3 + 0.22, 0.0, 1.0)
			var g := maxf(dirt[i], clampf((patches.get_noise_2d(cx * RES, cy * RES) - 0.42) * 3.0, 0.0, 1.0))
			var a := clampf(light.get_noise_2d(cx * RES, cy * RES) * 0.9 + 0.5, 0.0, 1.0)
			img.set_pixel(px, py, Color(road[i], g, b, a))
	return img

static func _stamp_path(buf: PackedFloat32Array, w: int, h: int, mg, pts: Array, half_w: float) -> void:
	if pts.size() < 2:
		return
	var cells: Array[Vector2] = []
	for p in pts:
		cells.append(Vector2(p.x, p.z) / mg.TILE_SIZE)
	cells = _chaikin(_chaikin(cells))
	for k in cells.size() - 1:
		var a: Vector2 = cells[k]
		var b: Vector2 = cells[k + 1]
		var x0 := int(floor((minf(a.x, b.x) - half_w - 1.0) * RES))
		var x1 := int(ceil((maxf(a.x, b.x) + half_w + 1.0) * RES))
		var y0 := int(floor((minf(a.y, b.y) - half_w - 1.0) * RES))
		var y1 := int(ceil((maxf(a.y, b.y) + half_w + 1.0) * RES))
		for py in range(maxi(y0, 0), mini(y1, h)):
			for px in range(maxi(x0, 0), mini(x1, w)):
				var p := Vector2(px + 0.5, py + 0.5) / RES
				var dist := _seg_dist(p, a, b)
				var v := clampf((half_w + 0.35 - dist) / 0.7, 0.0, 1.0)
				var i := py * w + px
				if v > buf[i]:
					buf[i] = v

static func _stamp_disc(buf: PackedFloat32Array, w: int, h: int, c: Vector2, r: float, edge: FastNoiseLite) -> void:
	for py in range(maxi(int((c.y - r - 1.5) * RES), 0), mini(int((c.y + r + 1.5) * RES), h)):
		for px in range(maxi(int((c.x - r - 1.5) * RES), 0), mini(int((c.x + r + 1.5) * RES), w)):
			var p := Vector2(px + 0.5, py + 0.5) / RES
			var rr := r + edge.get_noise_2d(px, py) * 0.8
			var v := clampf((rr - p.distance_to(c)) / 0.8 + 0.5, 0.0, 1.0)
			var i := py * w + px
			if v > buf[i]:
				buf[i] = v

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := 0.0 if ab.length_squared() < 1e-6 else clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

static func _chaikin(pts: Array[Vector2]) -> Array[Vector2]:
	if pts.size() < 3:
		return pts
	var out: Array[Vector2] = [pts[0]]
	for k in pts.size() - 1:
		out.append(pts[k].lerp(pts[k + 1], 0.25))
		out.append(pts[k].lerp(pts[k + 1], 0.75))
	out.append(pts[pts.size() - 1])
	return out
