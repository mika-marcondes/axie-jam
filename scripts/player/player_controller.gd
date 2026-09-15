extends Node3D

@export var ball: BallController
@export var rotation_speed: float = 10.0

@onready var visual_root: Node3D = $VisualRoot


func _physics_process(delta: float) -> void:
	if ball == null:
		return

	follow_ball()
	update_facing(delta)


func follow_ball() -> void:
	global_position = ball.rider_anchor.global_position


func update_facing(delta: float) -> void:
	var horizontal_velocity: Vector3 = Vector3(
		ball.velocity.x, 0.0, ball.velocity.z
	)

	if horizontal_velocity.length_squared() < 0.01:
		return

	var direction: Vector3 = horizontal_velocity.normalized()
	var target_yaw: float = atan2(-direction.x, -direction.z)

	rotation.y = lerp_angle(
		rotation.y,
		target_yaw,
		clampf(rotation_speed * delta, 0.0, 1.0)
	)
