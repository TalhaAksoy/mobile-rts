class_name Projectile3D
extends Node3D

var start_pos: Vector3
var target_pos: Vector3
var target_node: Node3D
var speed: float = 24.0
var damage: float = 10.0
var shooter_team: int = 0
var is_bullet: bool = false
var progress: float = 0.0
var total_dist: float = 1.0
var peak_height: float = 3.5

func setup(start: Vector3, target: Node3D, dmg: float, team: int, bullet: bool = false) -> void:
	start_pos = start
	target_node = target
	target_pos = target.global_position if is_instance_valid(target) else start + Vector3(0, 0, -5)
	damage = dmg
	shooter_team = team
	is_bullet = bullet
	global_position = start
	total_dist = max(1.0, start_pos.distance_to(target_pos))

	if is_bullet:
		speed = 48.0
		peak_height = 0.5
	else:
		speed = 22.0
		peak_height = clamp(total_dist * 0.22, 1.5, 4.5)

	_create_3d_visuals()

func _create_3d_visuals() -> void:
	if is_bullet:
		var spark = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radius = 0.12
		s_mesh.height = 0.24
		spark.mesh = s_mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.9, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.1)
		spark.material_override = mat
		add_child(spark)
	else:
		var arrow = MeshInstance3D.new()
		var a_mesh = CylinderMesh.new()
		a_mesh.top_radius = 0.04
		a_mesh.bottom_radius = 0.04
		a_mesh.height = 0.7
		arrow.mesh = a_mesh
		arrow.rotation_degrees = Vector3(90, 0, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.28, 0.15)
		arrow.material_override = mat
		add_child(arrow)

		# Metal Arrowhead
		var tip = MeshInstance3D.new()
		var t_mesh = PrismMesh.new()
		t_mesh.size = Vector3(0.12, 0.2, 0.12)
		tip.mesh = t_mesh
		tip.position = Vector3(0, 0, -0.4)
		tip.rotation_degrees = Vector3(-90, 0, 0)
		var tip_mat = StandardMaterial3D.new()
		tip_mat.albedo_color = Color(0.85, 0.85, 0.9)
		tip_mat.metallic = 0.8
		tip.material_override = tip_mat
		add_child(tip)

func _process(delta: float) -> void:
	if is_instance_valid(target_node):
		target_pos = target_node.global_position + Vector3(0, 0.8, 0)

	var step = (speed * delta) / total_dist
	progress += step

	if progress >= 1.0:
		_impact()
		return

	var current_ground = start_pos.lerp(target_pos, progress)
	var arc_y = sin(progress * PI) * peak_height
	var next_ground = start_pos.lerp(target_pos, min(1.0, progress + 0.05))
	var next_arc_y = sin(min(1.0, progress + 0.05) * PI) * peak_height

	global_position = current_ground + Vector3(0, arc_y, 0)
	var next_pos = next_ground + Vector3(0, next_arc_y, 0)

	if (next_pos - global_position).length_squared() > 0.001:
		look_at(next_pos, Vector3.UP)

func _impact() -> void:
	if is_instance_valid(target_node) and target_node.has_method("take_damage"):
		target_node.take_damage(damage, shooter_team)
	SoundManager.play_sound("hit")
	queue_free()
