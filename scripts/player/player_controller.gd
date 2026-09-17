extends Node3D
class_name PlayerController

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
@onready var tuck_aura: MeshInstance3D = $TrickPivot/TuckAura

@export_category("Debug Tracking")
@export var jump_height_threshold: float = 0.05

var current_jump_height: float = 0.0
var last_jump_height: float = 0.0
var best_jump_height: float = 0.0

var jump_start_y: float = 0.0
var jump_peak_y: float = 0.0
var was_airborne: bool = false

var tuck_aura_material: ShaderMaterial

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

	update_tuck_visuals()
	update_jump_tracking()


func _ready() -> void:
	if tuck_aura.material_override is ShaderMaterial:
		tuck_aura_material = tuck_aura.material_override.duplicate() as ShaderMaterial
		tuck_aura.material_override = tuck_aura_material

	tuck_aura.visible = false


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


func update_tuck_visuals() -> void:
	if tuck_aura_material == null:
		return

	tuck_aura.visible = tuck_amount > 0.01

	tuck_aura_material.set_shader_parameter(
		"tuck_amount",
		tuck_amount
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


func update_jump_tracking() -> void:
	var airborne: bool = not ball.is_on_floor()
	var current_y: float = trick_pivot.global_position.y

	if airborne and not was_airborne:
		jump_start_y = current_y
		jump_peak_y = current_y
		current_jump_height = 0.0

	if airborne:
		jump_peak_y = maxf(jump_peak_y, current_y)

		current_jump_height = maxf(
			current_y - jump_start_y,
			0.0
		)

	if not airborne and was_airborne:
		last_jump_height = maxf(
			jump_peak_y - jump_start_y,
			0.0
		)

		if last_jump_height >= jump_height_threshold:
			best_jump_height = maxf(
				best_jump_height,
				last_jump_height
			)

		current_jump_height = 0.0

	was_airborne = airborne


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


func get_tuck_amount() -> float:
	return tuck_amount


func get_spin_velocity() -> float:
	return air_spin_velocity


func get_current_jump_height() -> float:
	return current_jump_height


func get_last_jump_height() -> float:
	return last_jump_height


func get_best_jump_height() -> float:
	return best_jump_height


func is_airborne() -> bool:
	return ball != null and not ball.is_on_floor()


func is_diving() -> bool:
	return absf(air_pitch_angle) > 0.05


func get_catch_distance() -> float:
	if ball == null:
		return 0.0

	return global_position.distance_to(
		ball.rider_anchor.global_position
	)
