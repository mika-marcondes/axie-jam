extends CharacterBody3D

@export_category("Movement")
@export var acceleration: float = 14.0
@export var max_speed: float = 10.0
@export var steering: float = 5.0
@export var drag: float = 6.0

@export_category("Ball")
@export var radius: float = 0.5

@onready var visual: Node3D = $Visual

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_movement(delta)

	move_and_slide()

	update_visual_rotation(delta)


func handle_movement(delta: float) -> void:
	var input: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	var input_direction := Vector3(input.x, 0.0, input.y)

	var horizontal_velocity := Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	if input_direction.length_squared() > 0.0:
		input_direction = input_direction.normalized()

		# Apply acceleration to the existing momentum instead of
		# directly replacing or rotating the velocity.
		horizontal_velocity += input_direction * acceleration * delta

		# Keep the horizontal speed within the configured limit.
		if horizontal_velocity.length() > max_speed:
			horizontal_velocity = horizontal_velocity.normalized() * max_speed

	else:
		# Preserve momentum while gradually slowing the ball down.
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			drag * delta
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
