extends Node3D

@export_category("References")
@export var ball: BallController

@export_category("Movement")
@export var rotation_speed: float = 10.0

@export_category("Air Tricks")
@export var air_spin_speed: float = 360.0
@export var landing_realign_speed: float = 8.0

@onready var trick_pivot: Node3D = $TrickPivot

var air_spin_angle: float = 0.0


func _physics_process(delta: float) -> void:
	if ball == null:
		return

	follow_ball()

	if ball.is_on_floor():
		update_facing(delta)
		realign_trick(delta)
	else:
		handle_air_spin(delta)


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


func handle_air_spin(delta: float) -> void:
	var spin_input: float = Input.get_axis(
		"trick_spin_left", "trick_spin_right"
	)

	air_spin_angle += spin_input * deg_to_rad(air_spin_speed) * delta
	air_spin_angle = wrapf(air_spin_angle, -PI, PI)

	trick_pivot.rotation.y = air_spin_angle


func realign_trick(delta: float) -> void:
	air_spin_angle = lerp_angle(
		air_spin_angle,
		0.0,
		clampf(landing_realign_speed * delta, 0.0, 1.0)
	)

	trick_pivot.rotation.y = air_spin_angle
