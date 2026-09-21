extends Node3D
class_name PlayerController

@export_category("References")
@export var ball: BallController
@export var movement_reference: Node3D

@export_category("Movement")
@export var rotation_speed: float = 10.0
@export var air_rotation_speed: float = 3.0

@export_category("Air Feel")
@export var air_lean_angle: float = 12.0
@export var air_lean_speed: float = 8.0
@export var air_lean_min_speed: float = 0.05
@export var landing_lean_recovery_speed: float = 12.0

var previous_air_offset: Vector3 = Vector3.ZERO
var air_offset_velocity: Vector3 = Vector3.ZERO

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

@export_category("Air Positioning")
@export var air_offset_speed: float = 2.5
@export var air_offset_return_speed: float = 1.5
@export var max_horizontal_air_offset: float = 1.0
@export var dive_separation: float = 0.9
@export var dive_separation_speed: float = 3.5

var air_offset: Vector3 = Vector3.ZERO

@onready var air_offset_root: Node3D = $AirOffsetRoot
@onready var trick_pivot: Node3D = $AirOffsetRoot/TrickPivot
@onready var tuck_aura: MeshInstance3D = $AirOffsetRoot/TrickPivot/TuckAura

@export_category("Debug Tracking")
@export var jump_height_threshold: float = 0.05

@export_category("Axies")
@export var axie_scenes: Array[PackedScene] = []

@onready var axie_slot: Node3D = (
	$AirOffsetRoot/TrickPivot/ContactRoot/VisualRoot/AxieSlot
)

var axie_visual: Node3D
var axie_animator: AxieAnimationController

@export_category("Visual Contact")
@export var grounded_contact_offset: float = 0.03
@export var contact_offset_speed: float = 6.0

@onready var contact_root: Node3D = (
	$AirOffsetRoot/TrickPivot/ContactRoot
)


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
	update_facing(delta)

	if ball.is_on_floor():
		realign_tricks(delta)
	else:
		handle_air_tricks(delta)
	
	update_air_motion_visuals(delta)
	update_tuck_visuals()
	update_jump_tracking()
	update_visual_contact(delta)


func _ready() -> void:
	setup_selected_axie()

	if tuck_aura.material_override is ShaderMaterial:
		tuck_aura_material = (
			tuck_aura.material_override.duplicate()
			as ShaderMaterial
		)

		tuck_aura.material_override = (
			tuck_aura_material
		)

	tuck_aura.visible = false

	if axie_animator != null:
		axie_animator.setup(
			self,
			ball
		)


func setup_selected_axie() -> void:
	if axie_scenes.is_empty():
		return

	var index: int = clampi(
		AxieSelection.selected_index,
		0,
		axie_scenes.size() - 1
	)

	axie_visual = (
		axie_scenes[index].instantiate()
		as Node3D
	)

	axie_slot.add_child(
		axie_visual
	)

	axie_animator = (
		axie_visual.find_child(
			"Animator",
			true,
			false
		)
		as AxieAnimationController
	)


func follow_ball() -> void:
	global_position = ball.rider_anchor.global_position


func update_facing(delta: float) -> void:
	var horizontal_velocity: Vector3 = Vector3(
		ball.velocity.x, 0.0, ball.velocity.z
	)

	if horizontal_velocity.length_squared() < 0.01:
		return

	var direction: Vector3 = horizontal_velocity.normalized()
	var target_yaw: float = atan2(
		-direction.x,
		-direction.z
	)

	var current_rotation_speed: float = rotation_speed

	if not ball.is_on_floor():
		current_rotation_speed = air_rotation_speed

	rotation.y = lerp_angle(
		rotation.y,
		target_yaw,
		clampf(current_rotation_speed * delta, 0.0, 1.0)
	)


func handle_air_tricks(delta: float) -> void:
	update_tuck(delta)
	update_air_spin(delta)
	update_dive(delta)
	update_air_offset(delta)
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
		jump_peak_y = maxf(
			jump_peak_y,
			current_y
		)

		current_jump_height = maxf(
			jump_peak_y - jump_start_y,
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


func update_air_offset(delta: float) -> void:
	var input_direction: Vector3 = get_air_movement_direction()

	if input_direction.length_squared() > 0.01:
		var local_direction: Vector3 = (
			global_transform.basis.inverse()
			* input_direction
		)

		local_direction.y = 0.0
		local_direction = local_direction.normalized()

		air_offset.x += local_direction.x * air_offset_speed * delta
		air_offset.z += local_direction.z * air_offset_speed * delta
	else:
		air_offset.x = move_toward(
			air_offset.x,
			0.0,
			air_offset_return_speed * delta
		)
		air_offset.z = move_toward(
			air_offset.z,
			0.0,
			air_offset_return_speed * delta
		)

	var horizontal_offset: Vector2 = Vector2(
		air_offset.x,
		air_offset.z
	)

	if horizontal_offset.length() > max_horizontal_air_offset:
		horizontal_offset = (
			horizontal_offset.normalized()
			* max_horizontal_air_offset
		)

		air_offset.x = horizontal_offset.x
		air_offset.z = horizontal_offset.y

	var target_vertical_offset: float = 0.0

	if Input.is_action_pressed("trick_dive"):
		target_vertical_offset = dive_separation

	air_offset.y = move_toward(
		air_offset.y,
		target_vertical_offset,
		dive_separation_speed * delta
	)

	air_offset_root.position = air_offset


func update_visual_contact(delta: float) -> void:
	var target_offset: float = 0.0

	if ball.is_on_floor():
		target_offset = grounded_contact_offset

	contact_root.position.y = move_toward(
		contact_root.position.y,
		target_offset,
		contact_offset_speed * delta
	)


func update_air_motion_visuals(delta: float) -> void:
	var current_offset: Vector3 = air_offset_root.position

	air_offset_velocity = (
		current_offset - previous_air_offset
	) / maxf(delta, 0.001)

	previous_air_offset = current_offset

	var target_pitch: float = 0.0
	var target_roll: float = 0.0

	if not ball.is_on_floor():
		var horizontal_velocity: Vector2 = Vector2(
			air_offset_velocity.x,
			air_offset_velocity.z
		)

		if horizontal_velocity.length() > air_lean_min_speed:
			var direction: Vector2 = horizontal_velocity.normalized()
			var intensity: float = clampf(
				horizontal_velocity.length()
				/ maxf(air_offset_speed, 0.001),
				0.0,
				1.0
			)

			var lean_angle: float = deg_to_rad(
				air_lean_angle
			)

			target_pitch = (
				direction.y
				* lean_angle
				* intensity
			)

			target_roll = (
				-direction.x
				* lean_angle
				* intensity
			)

	var current_lean_speed: float = air_lean_speed
	
	if ball.is_on_floor():
		current_lean_speed = landing_lean_recovery_speed

	var weight: float = clampf(
		current_lean_speed * delta,
		0.0,
		1.0
	)

	contact_root.rotation.x = lerp_angle(
		contact_root.rotation.x,
		target_pitch,
		weight
	)

	contact_root.rotation.z = lerp_angle(
		contact_root.rotation.z,
		target_roll,
		weight
	)


func apply_trick_rotation() -> void:
	trick_pivot.rotation = Vector3(
		air_pitch_angle,
		air_spin_angle,
		0.0
	)


func recover_air_offset(delta: float) -> void:
	air_offset = air_offset.move_toward(
		Vector3.ZERO,
		air_offset_return_speed * delta
	)

	air_offset_root.position = air_offset


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

	recover_air_offset(delta)

	air_spin_velocity = air_spin_momentum
	apply_trick_rotation()


func is_airborne() -> bool:
	return ball != null and not ball.is_on_floor()


func is_diving() -> bool:
	return absf(air_pitch_angle) > 0.05


func is_spin_aligned(window_degrees: float) -> bool:
	return get_spin_alignment_degrees() <= window_degrees


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


func get_rider_shadow_position() -> Vector3:
	return trick_pivot.global_position


func get_catch_distance() -> float:
	if ball == null:
		return 0.0

	return global_position.distance_to(
		ball.rider_anchor.global_position
	)
	

func get_air_movement_direction() -> Vector3:
	if movement_reference == null:
		return Vector3.ZERO

	var input: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	if input.length_squared() < 0.01:
		return Vector3.ZERO

	var camera_forward: Vector3 = (
		-movement_reference.global_transform.basis.z
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


func get_spin_alignment_degrees() -> float:
	var wrapped_angle: float = wrapf(
		air_spin_angle,
		-PI,
		PI
	)

	return absf(
		rad_to_deg(wrapped_angle)
	)


func get_spin_direction_label() -> String:
	if air_spin_velocity > 0.01:
		return "R"

	if air_spin_velocity < -0.01:
		return "L"

	return ""


func is_tucked() -> bool:
	return tuck_amount >= 0.5
