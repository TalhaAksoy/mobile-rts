class_name HD2DScatter
extends RefCounted
## Ground scatter for the HD-2D environment: grass tufts, flowers, ferns, pebbles, twigs, mushrooms.
## One MultiMeshInstance3D per CHUNK_ROWS map rows -> ~6 draw calls for the whole map, still
## frustum-culled per chunk. Placement follows the HD2DGround control map (no tufts on roads,
## pebbles on bare dirt, ferns/mushrooms next to trees). Purely visual: no collision, no shadows.

const CHUNK_ROWS: int = 10
const QUAD: float = 0.8    # sprite size in metres (16 px sprite -> 20 px/m: chunky, reads at default zoom)

# atlas cells (col, row) in SC_ScatterAtlas.png
const TUFTS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const FLOWERS := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
const DRY := [Vector2i(0, 2), Vector2i(1, 2)]
const FERNS := [Vector2i(2, 2), Vector2i(3, 2)]
const PEBBLES := [Vector2i(0, 3), Vector2i(1, 3)]
const TWIG := Vector2i(2, 3)
const MUSHROOM := Vector2i(3, 3)
# biome rows (atlas is 4 x 8 cells; see pe_kit.bake_scatter_atlas)
const LEAVES := [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4)]
const RUSSET_TUFT := Vector2i(3, 4)
const CACTUS := Vector2i(0, 5)
const DUNE_GRASS := [Vector2i(1, 5), Vector2i(2, 5)]
const BLEACHED_STONES := Vector2i(3, 5)
const FEATHER_GRASS := [Vector2i(0, 6), Vector2i(1, 6)]
const THISTLE := Vector2i(2, 6)
const LICHEN_STONE := Vector2i(3, 6)
const ATLAS_CELL := Vector2(0.25, 0.125)

static func _crossed_quad_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := QUAD
	var w := QUAD * 0.5
	for axis in [Vector3(1, 0, 0), Vector3(0, 0, 1)]:
		var a: Vector3 = -axis * w
		var b: Vector3 = axis * w
		var verts := [a, b, b + Vector3(0, h, 0), a + Vector3(0, h, 0)]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(uvs[idx])
			st.add_vertex(verts[idx])
	return st.commit()

## Returns { "nodes": Array[MultiMeshInstance3D], "cell_index": { Vector2i: [[mm, idx], ...] } }
static func build(mg, control: Image) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = mg.seed_val + 2024
	var biome: String = CivData.get_biome(mg.map_type)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/hd2d_scatter.gdshader")
	mat.set_shader_parameter("atlas", load("res://assets/3d/materials/textures/SC_ScatterAtlas.png"))
	var mesh := _crossed_quad_mesh()
	var res: int = control.get_width() / mg.MAP_WIDTH

	var per_chunk: Array = []   # Array of Array of [Transform3D, Vector2i atlas, Vector2i cell]
	for c in int(ceil(float(mg.MAP_HEIGHT) / CHUNK_ROWS)):
		per_chunk.append([])

	for y in mg.MAP_HEIGHT:
		for x in mg.MAP_WIDTH:
			var cell := Vector2i(x, y)
			if not mg.is_cell_passable_terrain(x, y):
				continue
			if cell in mg.trees or cell in mg.gold_mines or cell in mg.stone_mines or cell in mg.berry_bushes:
				continue
			var ctl := control.get_pixel(x * res + res / 2, y * res + res / 2)
			var near_tree := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if (cell + d) in mg.trees:
					near_tree = true
			var items: Array = []
			if ctl.r > 0.45:
				if rng.randf() < 0.25: items.append(PEBBLES[rng.randi() % 2])
			elif ctl.g > 0.5:
				if rng.randf() < 0.5: items.append(PEBBLES[rng.randi() % 2])
				if rng.randf() < 0.25: items.append(DRY[rng.randi() % 2])
			elif biome == "desert":
				if rng.randf() < 0.3: items.append(DUNE_GRASS[rng.randi() % 2])
				if rng.randf() < 0.15: items.append(DRY[rng.randi() % 2])
				if rng.randf() < 0.15: items.append(BLEACHED_STONES if rng.randf() < 0.5 else PEBBLES[rng.randi() % 2])
				if rng.randf() < 0.05: items.append(CACTUS)
			elif biome == "steppe":
				var n := rng.randi_range(2, 4)
				for k in n:
					items.append(FEATHER_GRASS[rng.randi() % 2] if rng.randf() < 0.6 else DRY[rng.randi() % 2])
				if rng.randf() < 0.14: items.append(THISTLE)
				if rng.randf() < 0.06: items.append(FLOWERS[1])
				if rng.randf() < 0.12: items.append(LICHEN_STONE)
			elif biome == "autumn":
				var n := rng.randi_range(2, 5)
				for k in n:
					items.append(RUSSET_TUFT if rng.randf() < 0.45 else TUFTS[rng.randi() % 4])
				if rng.randf() < (0.7 if near_tree else 0.3): items.append(LEAVES[rng.randi() % 3])
				if near_tree and rng.randf() < 0.15: items.append(MUSHROOM)
				if rng.randf() < 0.06: items.append(FLOWERS[rng.randi() % 4])
				if rng.randf() < 0.06: items.append(TWIG)
			for a in items:
				var px: float = (x + rng.randf_range(0.1, 0.9)) * mg.TILE_SIZE
				var pz: float = (y + rng.randf_range(0.1, 0.9)) * mg.TILE_SIZE
				var s := rng.randf_range(0.8, 1.25)
				var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
				var t := Transform3D(basis, Vector3(px, mg.get_height_at(Vector3(px, 0, pz)), pz))
				per_chunk[y / CHUNK_ROWS].append([t, a, cell])

	var nodes: Array = []
	var cell_index := {}
	for ci in per_chunk.size():
		var list: Array = per_chunk[ci]
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i][0])
			var a: Vector2i = list[i][1]
			mm.set_instance_custom_data(i, Color(a.x * ATLAS_CELL.x, a.y * ATLAS_CELL.y, 0, 0))
			var cell: Vector2i = list[i][2]
			if not cell_index.has(cell):
				cell_index[cell] = []
			cell_index[cell].append([mm, i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Scatter_%d" % ci
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nodes.append(mmi)
	return {"nodes": nodes, "cell_index": cell_index}

## Hide every scatter instance on the given cells (a building was placed there).
static func hide_cells(cell_index: Dictionary, origin: Vector2i, size: Vector2i) -> void:
	for dx in size.x:
		for dy in size.y:
			var c := origin + Vector2i(dx, dy)
			if cell_index.has(c):
				for entry in cell_index[c]:
					var mm: MultiMesh = entry[0]
					var t := mm.get_instance_transform(entry[1])
					mm.set_instance_transform(entry[1], Transform3D(Basis().scaled(Vector3.ZERO), t.origin))
				cell_index.erase(c)
