extends CharacterBody3D
class_name BallController

signal landed(impact_speed: float)
signal bounced(impact_speed: float, bounce_velocity: float)

@export_category("Movement")
@export var acceleration: float = 14.0
@export var max_speed: float = 10.0
@export var steering: float = 1.0
@export var drag: float = 6.0

@export_category("Ball")
@export var radius: float = 0.5

@export_category("Jump")
@export var jump_velocity: float = 6.0
@export var charged_jump_velocity: float = 11.0
@export var max_charge_time: float = 0.75
@export_range(0.0, 1.0, 0.05) var air_control: float = 0.35

@export_category("Bounce")
@export_range(0.0, 1.0, 0.05) var bounce_retention: float = 0.75
@export var bounce_input_window: float = 0.15

@export_category("Boost")
@export var boost_acceleration_multiplier: float = 1.6
@export var boost_max_speed_multiplier: float = 1.4
@export var boost_release_deceleration: float = 4.0

@export_category("Ground Shadow")
@export var shadow_max_height: float = 10.0
@export var shadow_min_scale: float = 0.45
@export var shadow_max_scale: float = 1.0
@export var shadow_min_opacity: float = 0.12
@export var shadow_max_opacity: float = 0.45
@export var shadow_ground_offset: float = 0.02

@export_category("Rider Shadow")
@export var rider_shadow_target: Node3D
@export var rider_shadow_surface_offset: float = 0.015
@export var rider_shadow_follow_speed: float = 14.0
@export var rider_shadow_max_separation: float = 1.5
@export var rider_shadow_min_scale: float = 0.45
@export var rider_shadow_max_scale: float = 0.85
@export var rider_shadow_min_opacity: float = 0.10
@export var rider_shadow_max_opacity: float = 0.38

@export_category("References")
@export var movement_reference: Node3D

@onready var visual: Node3D = $Visual
@onready var rider_anchor: Marker3D = $RiderAnchor
@onready var ground_probe: RayCast3D = $GroundProbe
@onready var ground_shadow: MeshInstance3D = $GroundShadow
@onready var rider_shadow_root: Node3D = $RiderShadow
@onready var rider_shadow_mesh: MeshInstance3D = $RiderShadow/MeshInstance3D

var jump_charge_time: float = 0.0
var is_charging_jump: bool = false
var bounce_input_timer: float = 0.0
var is_boosting: bool = false

var ground_shadow_material: ShaderMaterial
var rider_shadow_material: ShaderMaterial

var gravity: float = float(
	ProjectSettings.get_setting("physics/3d/default_gravity")
)


#region Lifecycle

func _ready() -> void:
	setup_shadow_materials()


func _physics_process(delta: float) -> void:
	update_bounce_input(delta)
	handle_jump(delta)
	apply_gravity(delta)
	handle_movement(delta)

	var was_on_floor: bool = is_on_floor()
	var impact_velocity: float = velocity.y

	move_and_slide()

	handle_landing(was_on_floor, impact_velocity)
	update_visual_rotation(delta)
	update_ground_shadow()
	update_rider_shadow(delta)
	check_fall_reset()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_scene"):
		get_tree().reload_current_scene()

#endregion


#region Movement

func handle_movement(delta: float) -> void:
	var input_direction: Vector3 = get_movement_direction()
	var horizontal_velocity: Vector3 = get_horizontal_velocity()
	var has_movement_input: bool = input_direction.length_squared() > 0.0

	is_boosting = (
		Input.is_action_pressed("boost")
		and is_on_floor()
		and has_movement_input
	)

	var current_acceleration: float = acceleration
	var current_max_speed: float = max_speed
	var control_multiplier: float = 1.0

	if is_boosting:
		current_acceleration *= boost_acceleration_multiplier
		current_max_speed *= boost_max_speed_multiplier

	if not is_on_floor():
		control_multiplier = air_control

	if is_on_floor() and not is_boosting and horizontal_velocity.length() > max_speed:
		var current_speed: float = horizontal_velocity.length()
		var reduced_speed: float = move_toward(
			current_speed,
			max_speed,
			boost_release_deceleration * delta
		)

		horizontal_velocity = horizontal_velocity.normalized() * reduced_speed

	if has_movement_input:
		input_direction = input_direction.normalized()

		var speed_before_input: float = horizontal_velocity.length()
		var allowed_speed: float = maxf(current_max_speed, speed_before_input)

		if horizontal_velocity.length() < 0.1:
			horizontal_velocity += (
				input_direction
				* current_acceleration
				* control_multiplier
				* delta
			)
		else:
			var momentum_direction: Vector3 = horizontal_velocity.normalized()
			var parallel_amount: float = input_direction.dot(momentum_direction)
			var parallel_input: Vector3 = momentum_direction * parallel_amount
			var lateral_input: Vector3 = input_direction - parallel_input

			horizontal_velocity += (
				parallel_input
				* current_acceleration
				* control_multiplier
				* delta
			)

			horizontal_velocity += (
				lateral_input
				* current_acceleration
				* steering
				* control_multiplier
				* delta
			)

		if horizontal_velocity.length() > allowed_speed:
			horizontal_velocity = (
				horizontal_velocity.normalized()
				* allowed_speed
			)
	elif is_on_floor():
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector3.ZERO,
			drag * delta
		)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z


func get_movement_direction() -> Vector3:
	var input: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	if input.length_squared() <= 0.0:
		return Vector3.ZERO

	if movement_reference == null:
		return Vector3(input.x, 0.0, input.y).normalized()

	var camera_forward: Vector3 = (
		- movement_reference.global_transform.basis.z
	)
	var camera_right: Vector3 = (
		movement_reference.global_transform.basis.x
	)

	camera_forward.y = 0.0
	camera_right.y = 0.0

	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()

	return (
		camera_right * input.x
		+ camera_forward * -input.y
	).normalized()


func get_horizontal_velocity() -> Vector3:
	return Vector3(
		velocity.x,
		0.0,
		velocity.z
	)


func get_horizontal_speed() -> float:
	return get_horizontal_velocity().length()

#endregion


#region Jump and Bounce

func handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		is_charging_jump = true
		jump_charge_time = 0.0

	if not is_charging_jump:
		return

	if not is_on_floor():
		reset_jump_charge()
		return

	if Input.is_action_pressed("jump"):
		jump_charge_time = minf(
			jump_charge_time + delta,
			max_charge_time
		)

	if Input.is_action_just_released("jump"):
		var charge_ratio: float = clampf(
			jump_charge_time / maxf(max_charge_time, 0.001),
			0.0,
			1.0
		)

		velocity.y = lerpf(
			jump_velocity,
			charged_jump_velocity,
			charge_ratio
		)

		reset_jump_charge()


func reset_jump_charge() -> void:
	is_charging_jump = false
	jump_charge_time = 0.0


func update_bounce_input(delta: float) -> void:
	bounce_input_timer = maxf(
		bounce_input_timer - delta,
		0.0
	)

	if Input.is_action_just_pressed("jump") and not is_on_floor():
		bounce_input_timer = bounce_input_window


func handle_landing(
	was_on_floor: bool,
	impact_velocity: float
) -> void:
	if was_on_floor or not is_on_floor():
		return

	var impact_speed: float = maxf(-impact_velocity, 0.0)
	landed.emit(impact_speed)

	if bounce_input_timer <= 0.0:
		return

	var bounce_velocity: float = impact_speed * bounce_retention
	var min_bounce_velocity: float = jump_velocity * 0.75
	var max_bounce_velocity: float = charged_jump_velocity

	bounce_velocity = clampf(
		bounce_velocity,
		min_bounce_velocity,
		max_bounce_velocity
	)

	velocity.y = bounce_velocity
	bounce_input_timer = 0.0

	bounced.emit(
		impact_speed,
		bounce_velocity
	)

#endregion


#region Physics

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


func check_fall_reset() -> void:
	if global_position.y < -10.0:
		get_tree().reload_current_scene()

#endregion


#region Visuals

func update_visual_rotation(delta: float) -> void:
	var horizontal_velocity: Vector3 = get_horizontal_velocity()

	if horizontal_velocity.length() < 0.01:
		return

	var direction: Vector3 = horizontal_velocity.normalized()
	var rotation_axis: Vector3 = Vector3(
		direction.z,
		0.0,
		- direction.x
	).normalized()
	var angle: float = horizontal_velocity.length() * delta / radius

	visual.rotate(
		rotation_axis,
		angle
	)

#endregion


#region Shadows

func setup_shadow_materials() -> void:
	ground_shadow.top_level = true

	ground_shadow_material = duplicate_shadow_material(
		ground_shadow
	)
	rider_shadow_material = duplicate_shadow_material(
		rider_shadow_mesh
	)

	if rider_shadow_target == null:
		rider_shadow_mesh.visible = false


func duplicate_shadow_material(
	mesh: MeshInstance3D
) -> ShaderMaterial:
	if not mesh.material_override is ShaderMaterial:
		return null

	var material: ShaderMaterial = (
		mesh.material_override.duplicate()
		as ShaderMaterial
	)

	mesh.material_override = material
	return material


func update_ground_shadow() -> void:
	ground_probe.force_raycast_update()

	if not ground_probe.is_colliding():
		ground_shadow.visible = false
		return

	ground_shadow.visible = true

	var ground_position: Vector3 = ground_probe.get_collision_point()
	var height: float = global_position.distance_to(ground_position)
	var height_ratio: float = clampf(
		height / maxf(shadow_max_height, 0.001),
		0.0,
		1.0
	)
	var shadow_scale: float = lerpf(
		shadow_max_scale,
		shadow_min_scale,
		height_ratio
	)
	var shadow_opacity: float = lerpf(
		shadow_max_opacity,
		shadow_min_opacity,
		height_ratio
	)

	ground_shadow.global_position = (
		ground_position
		+ Vector3.UP * shadow_ground_offset
	)
	ground_shadow.scale = Vector3(
		shadow_scale,
		1.0,
		shadow_scale
	)

	set_shadow_opacity(
		ground_shadow_material,
		shadow_opacity
	)


func update_rider_shadow(delta: float) -> void:
	if rider_shadow_target == null:
		rider_shadow_mesh.visible = false
		return

	var local_target: Vector3 = to_local(
		rider_shadow_target.global_position
	)

	if local_target.length_squared() < 0.0001:
		rider_shadow_mesh.visible = false
		return

	rider_shadow_mesh.visible = true

	var surface_normal: Vector3 = local_target.normalized()
	var target_position: Vector3 = (
		surface_normal
		* (radius + rider_shadow_surface_offset)
	)
	var follow_weight: float = clampf(
		rider_shadow_follow_speed * delta,
		0.0,
		1.0
	)
	var shadow_position: Vector3 = rider_shadow_root.position.lerp(
		target_position,
		follow_weight
	)

	rider_shadow_root.transform = Transform3D(
		make_surface_basis(surface_normal),
		shadow_position
	)

	var separation: float = rider_shadow_target.global_position.distance_to(
		rider_anchor.global_position
	)
	var separation_ratio: float = clampf(
		separation / maxf(rider_shadow_max_separation, 0.001),
		0.0,
		1.0
	)
	var shadow_scale: float = lerpf(
		rider_shadow_max_scale,
		rider_shadow_min_scale,
		separation_ratio
	)
	var shadow_opacity: float = lerpf(
		rider_shadow_max_opacity,
		rider_shadow_min_opacity,
		separation_ratio
	)

	rider_shadow_mesh.scale = Vector3(
		shadow_scale,
		1.0,
		shadow_scale
	)

	set_shadow_opacity(
		rider_shadow_material,
		shadow_opacity
	)


func make_surface_basis(surface_normal: Vector3) -> Basis:
	var reference_axis: Vector3 = Vector3.FORWARD

	if absf(surface_normal.dot(reference_axis)) > 0.98:
		reference_axis = Vector3.RIGHT

	var x_axis: Vector3 = surface_normal.cross(
		reference_axis
	).normalized()
	var z_axis: Vector3 = x_axis.cross(
		surface_normal
	).normalized()

	return Basis(
		x_axis,
		surface_normal,
		z_axis
	)


func set_shadow_opacity(
	material: ShaderMaterial,
	opacity: float
) -> void:
	if material == null:
		return

	material.set_shader_parameter(
		"opacity",
		opacity
	)

#endregion
