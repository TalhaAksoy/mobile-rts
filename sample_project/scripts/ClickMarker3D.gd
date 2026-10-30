class_name ClickMarker3D
extends Node3D

var timer: float = 0.5
var max_time: float = 0.5
var ring_mesh: MeshInstance3D

func setup(pos: Vector3, type: String = "move") -> void:
	global_position = pos + Vector3(0, 0.08, 0)
	
	ring_mesh = MeshInstance3D.new()
	var t_mesh = TorusMesh.new()
	t_mesh.inner_radius = 0.5
	t_mesh.outer_radius = 0.65
	ring_mesh.mesh = t_mesh
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	
	match type:
		"attack":
			mat.albedo_color = Color(1.0, 0.2, 0.2, 0.9)
			mat.emission = Color(1.0, 0.2, 0.2)
		"gather":
			mat.albedo_color = Color(1.0, 0.85, 0.2, 0.9)
			mat.emission = Color(1.0, 0.85, 0.2)
		"build":
			mat.albedo_color = Color(0.3, 0.8, 1.0, 0.9)
			mat.emission = Color(0.3, 0.8, 1.0)
		_: # move
			mat.albedo_color = Color(0.2, 0.95, 0.35, 0.9)
			mat.emission = Color(0.2, 0.95, 0.35)
			
	ring_mesh.material_override = mat
	add_child(ring_mesh)

func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		queue_free()
		return
		
	var prog = 1.0 - (timer / max_time)
	var sc = 1.0 + prog * 0.4
	scale = Vector3(sc, sc, sc)
	if is_instance_valid(ring_mesh) and ring_mesh.material_override:
		(ring_mesh.material_override as StandardMaterial3D).albedo_color.a = (1.0 - prog) * 0.9
