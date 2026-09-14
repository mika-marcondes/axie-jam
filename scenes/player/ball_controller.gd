extends CharacterBody3D
class_name BallController

@export_category("Movement")
@export var acceleration: float = 14.0
@export var max_speed: float = 10.0
@export var steering: float = 1.0
@export var drag: float = 6.0

@export_category("Ball")
@export var radius: float = 0.5

@export_category("Jump")
@export var jump_velocity: float = 7.0
@export_range(0.0, 1.0, 0.05) var air_control: float = 0.35

@export_category("References")
@export var movement_reference: Node3D

@onready var visual: Node3D = $Visual

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	handle_jump()
	apply_gravity(delta)
	handle_movement(delta)

	move_and_slide()

	update_visual_rotation(delta)
	check_fall_reset()


func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity


func check_fall_reset() -> void:
	if global_position.y < -10.0:
		get_tree().reload_current_scene()


func handle_movement(delta: float) -> void:
	var input: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)

	var input_direction: Vector3 = Vector3.ZERO

	if movement_reference != null:
		var camera_forward: Vector3 = -movement_reference.global_transform.basis.z
		var camera_right: Vector3 = movement_reference.global_transform.basis.x

		camera_forward.y = 0.0
		camera_right.y = 0.0

		camera_forward = camera_forward.normalized()
		camera_right = camera_right.normalized()

		input_direction = camera_right * input.x + camera_forward * -input.y
	else:
		input_direction = Vector3(input.x, 0.0, input.y)

	var horizontal_velocity: Vector3 = Vector3(
		velocity.x, 0.0, velocity.z
	)

	var control_multiplier: float = 1.0

	if not is_on_floor():
		control_multiplier = air_control

	if input_direction.length_squared() > 0.0:
		input_direction = input_direction.normalized()

		if horizontal_velocity.length() < 0.1:
			horizontal_velocity += (
				input_direction * acceleration * control_multiplier * delta
			)
		else:
			var momentum_direction: Vector3 = horizontal_velocity.normalized()

			# Split input into acceleration along the current momentum
			# and steering perpendicular to it.
			var parallel_amount: float = input_direction.dot(momentum_direction)
			var parallel_input: Vector3 = momentum_direction * parallel_amount
			var lateral_input: Vector3 = input_direction - parallel_input

			horizontal_velocity += (
				parallel_input * acceleration * control_multiplier * delta
			)

			horizontal_velocity += (
				lateral_input
				* acceleration
				* steering
				* control_multiplier
				* delta
			)

		if horizontal_velocity.length() > max_speed:
			horizontal_velocity = horizontal_velocity.normalized() * max_speed

	elif is_on_floor():
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO, drag * delta
		)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


func update_visual_rotation(delta: float) -> void:
	var horizontal_velocity := Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	if horizontal_velocity.length() < 0.01:
		return

	var direction := horizontal_velocity.normalized()

	var rotation_axis := Vector3(
		direction.z,
		0.0,
		-direction.x
	).normalized()

	var angle := horizontal_velocity.length() * delta / radius

	visual.rotate(rotation_axis, angle)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_scene"):
		get_tree().reload_current_scene()
