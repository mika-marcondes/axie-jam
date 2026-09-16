extends Node3D

@export_category("References")
@export var ball: BallController

@export_category("Movement")
@export var rotation_speed: float = 10.0

@export_category("Air Tricks")
@export var spin_acceleration: float = 720.0
@export var max_spin_speed: float = 540.0
@export var spin_drag: float = 30.0
@export var landing_realign_speed: float = 8.0
@export var landing_spin_deceleration: float = 1080.0
@export var dive_angle: float = 90.0
@export var dive_speed: float = 6.0

@export_category("Tuck")
@export var tuck_spin_multiplier: float = 1.8
@export var tuck_transition_speed: float = 8.0

@onready var trick_pivot: Node3D = $TrickPivot

var air_spin_angle: float = 0.0
var air_spin_momentum: float = 0.0
var air_spin_velocity: float = 0.0
var air_pitch_angle: float = 0.0
var tuck_amount: float = 0.0


func _physics_process(delta: float) -> void:
	if ball == null:
		return

	follow_ball()

	if ball.is_on_floor():
		update_facing(delta)
		realign_tricks(delta)
	else:
		handle_air_tricks(delta)


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


func handle_air_tricks(delta: float) -> void:
	update_tuck(delta)
	update_air_spin(delta)
	update_dive(delta)
	apply_trick_rotation()


func update_tuck(delta: float) -> void:
	var target_tuck: float = 0.0

	if Input.is_action_pressed("trick_tuck"):
		target_tuck = 1.0

	tuck_amount = move_toward(
		tuck_amount,
		target_tuck,
		tuck_transition_speed * delta
	)


func update_air_spin(delta: float) -> void:
	var spin_input: float = Input.get_axis(
		"trick_spin_left", "trick_spin_right"
	)

	if absf(spin_input) > 0.01:
		air_spin_momentum += spin_input * spin_acceleration * delta
	else:
		air_spin_momentum = move_toward(
			air_spin_momentum,
			0.0,
			spin_drag * delta
		)

	air_spin_momentum = clampf(
		air_spin_momentum,
		- max_spin_speed,
		max_spin_speed
	)

	var spin_multiplier: float = lerpf(
		1.0,
		tuck_spin_multiplier,
		tuck_amount
	)

	air_spin_velocity = air_spin_momentum * spin_multiplier

	air_spin_angle += deg_to_rad(air_spin_velocity) * delta
	air_spin_angle = wrapf(air_spin_angle, -PI, PI)


func update_dive(delta: float) -> void:
	var target_pitch: float = 0.0

	if Input.is_action_pressed("trick_dive"):
		target_pitch = deg_to_rad(-dive_angle)

	air_pitch_angle = lerp_angle(
		air_pitch_angle,
		target_pitch,
		clampf(dive_speed * delta, 0.0, 1.0)
	)


func apply_trick_rotation() -> void:
	trick_pivot.rotation = Vector3(
		air_pitch_angle,
		air_spin_angle,
		0.0
	)


func realign_tricks(delta: float) -> void:
	var weight: float = clampf(
		landing_realign_speed * delta,
		0.0,
		1.0
	)

	air_spin_angle = lerp_angle(
		air_spin_angle,
		0.0,
		weight
	)

	air_pitch_angle = lerp_angle(
		air_pitch_angle,
		0.0,
		weight
	)

	air_spin_momentum = move_toward(
		air_spin_momentum,
		0.0,
		landing_spin_deceleration * delta
	)

	tuck_amount = move_toward(
		tuck_amount,
		0.0,
		tuck_transition_speed * delta
	)

	air_spin_velocity = air_spin_momentum
	apply_trick_rotation()


func get_spin_rpm() -> float:
	return air_spin_velocity / 6.0
