extends SceneTree

const FactionArtManager = preload("res://scripts/FactionArtManager.gd")
const CivData = preload("res://scripts/CivData.gd")
const Building3D = preload("res://scripts/Building3D.gd")

func _init() -> void:
	call_deferred("_capture_screenshots")

func _capture_screenshots() -> void:
	print("Starting building screenshot capture across factions...")

	var dir = DirAccess.open("res://")
	if dir != null:
		dir.make_dir_recursive("../docs/audits/evidence/buildings")

	var vp = SubViewport.new()
	vp.size = Vector2i(720, 1280)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var world = World3D.new()
	vp.world_3d = world

	# Directional sun light
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_color = Color(1.0, 0.98, 0.92)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	vp.add_child(sun)

	# Ambient environment
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.18, 0.22, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.60, 0.55)
	env.ambient_light_energy = 0.8
	env_node.environment = env
	vp.add_child(env_node)

	# Camera at standard 45-degree RTS perspective
	var cam = Camera3D.new()
	cam.position = Vector3(0, 14, 14)
	cam.rotation_degrees = Vector3(-45, 0, 0)
	cam.current = true
	cam.fov = 42.0
	vp.add_child(cam)

	# Ground floor plane
	var ground = MeshInstance3D.new()
	var g_mesh = PlaneMesh.new()
	g_mesh.size = Vector2(40, 40)
	ground.mesh = g_mesh
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.32, 0.58, 0.28)
	ground.material_override = g_mat
	vp.add_child(ground)

	var civ_list = [
		{"civ": CivData.CivType.OTTOMANS, "name": "ottomans"},
		{"civ": CivData.CivType.BYZANTINES, "name": "byzantines"},
		{"civ": CivData.CivType.BRITONS, "name": "britons"},
		{"civ": CivData.CivType.FRANKS, "name": "franks"},
		{"civ": CivData.CivType.MONGOLS, "name": "mongols"},
		{"civ": CivData.CivType.TEUTONS, "name": "teutons"},
		{"civ": CivData.CivType.JAPANESE, "name": "japanese"},
		{"civ": CivData.CivType.SARACENS, "name": "saracens"},
		{"civ": CivData.CivType.VIKINGS, "name": "vikings"},
		{"civ": CivData.CivType.CHINESE, "name": "chinese"}
	]

	for item in civ_list:
		var c_type = item["civ"]
		var c_name = item["name"]

		var b_holder = Node3D.new()
		vp.add_child(b_holder)

		# Place Town Center, Castle, Barracks, Archery, Stable, House, Tower, Mill
		var placements = [
			{"type": Building3D.BuildingType.TOWN_CENTER, "pos": Vector3(-4.0, 0, -2.0)},
			{"type": Building3D.BuildingType.CASTLE, "pos": Vector3(4.5, 0, -3.0)},
			{"type": Building3D.BuildingType.BARRACKS, "pos": Vector3(-5.0, 0, 4.0)},
			{"type": Building3D.BuildingType.ARCHERY_RANGE, "pos": Vector3(0.0, 0, 4.5)},
			{"type": Building3D.BuildingType.STABLE, "pos": Vector3(5.5, 0, 4.0)},
			{"type": Building3D.BuildingType.TOWER, "pos": Vector3(0.0, 0, -1.0)},
			{"type": Building3D.BuildingType.HOUSE, "pos": Vector3(-4.0, 0, 9.0)},
			{"type": Building3D.BuildingType.MILL, "pos": Vector3(4.0, 0, 9.0)}
		]

		for p in placements:
			var b = Building3D.new()
			b_holder.add_child(b)
			b.setup_building(p["type"], 0, c_type, Vector2i(0, 0), null, null, false)
			b.position = p["pos"]

		# Render two frames to update transforms and shaders
		await process_frame
		await process_frame

		var img = vp.get_texture().get_image()
		if img != null:
			var save_path = "../docs/audits/evidence/buildings/%s_settlement.png" % c_name
			img.save_png(save_path)
			print("Saved screenshot: %s" % save_path)

		b_holder.queue_free()
		await process_frame

	print("ALL SCREENSHOTS CAPTURED SUCCESSFULLY!")
	quit(0)
