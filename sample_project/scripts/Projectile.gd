class_name Projectile
extends Node2D

var start_pos: Vector2
var target_pos: Vector2
var target_node: Node2D
var speed: float = 380.0
var damage: float = 10.0
var shooter_team: int = 0
var is_bullet: bool = false # Gunpowder musket or arrow
var progress: float = 0.0
var total_dist: float = 1.0
var peak_height: float = 24.0

func setup(start: Vector2, target: Node2D, dmg: float, team: int, bullet: bool = false) -> void:
	start_pos = start
	target_node = target
	target_pos = target.global_position if is_instance_valid(target) else start + Vector2(0, -50)
	damage = dmg
	shooter_team = team
	is_bullet = bullet
	global_position = start
	total_dist = max(10.0, start_pos.distance_to(target_pos))
	if is_bullet:
		speed = 650.0
		peak_height = 4.0
	else:
		speed = 340.0
		peak_height = min(40.0, total_dist * 0.25)

func _process(delta: float) -> void:
	if is_instance_valid(target_node):
		target_pos = target_node.global_position
		
	var step = (speed * delta) / total_dist
	progress += step
	
	if progress >= 1.0:
		_impact()
		return
		
	var current_ground = start_pos.lerp(target_pos, progress)
	var arc_y = -sin(progress * PI) * peak_height
	global_position = current_ground + Vector2(0, arc_y)
	
	# Rotate towards direction
	var next_ground = start_pos.lerp(target_pos, progress + 0.05)
	var next_arc_y = -sin(clamp(progress + 0.05, 0.0, 1.0) * PI) * peak_height
	var next_pos = next_ground + Vector2(0, next_arc_y)
	rotation = (next_pos - global_position).angle()
	
	queue_redraw()

func _impact() -> void:
	if is_instance_valid(target_node):
		if target_node.has_method("take_damage"):
			target_node.take_damage(damage, shooter_team)
	SoundManager.play_sound("hit")
	queue_free()

func _draw() -> void:
	if is_bullet:
		# Glowing spark/musket ball
		draw_circle(Vector2.ZERO, 3.5, Color(1.0, 0.9, 0.4))
		draw_line(Vector2(-10, 0), Vector2.ZERO, Color(1.0, 0.5, 0.1, 0.6), 2.0)
	else:
		# Wooden arrow with metal tip & fletching
		draw_line(Vector2(-10, 0), Vector2(6, 0), Color(0.4, 0.25, 0.1), 2.0)
		# Metal arrowhead
		draw_polygon(PackedVector2Array([Vector2(6, -2), Vector2(10, 0), Vector2(6, 2)]), [Color(0.8, 0.8, 0.85)])
		# Feather fletching
		draw_line(Vector2(-8, -2), Vector2(-11, 0), Color(1, 1, 1, 0.8), 1.5)
		draw_line(Vector2(-8, 2), Vector2(-11, 0), Color(1, 1, 1, 0.8), 1.5)
