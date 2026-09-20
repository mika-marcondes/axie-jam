extends CharacterBody3D
class_name BallController

signal landed(impact_speed: float)
signal bounced(impact_speed: float, bounce_velocity: float)
signal bounce_feedback(
	grade: BounceGrade
)

enum BounceGrade {
	NONE,
	MISS,
	LATE,
	GOOD,
	PERFECT
}


#region Exports

@export_category("References")
@export var movement_reference: Node3D
@export var rider: PlayerController
@export var rider_shadow_target: Node3D

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
@export var bounce_input_window: float = 0.50
@export var bounce_attempt_window: float = 0.75

@export_category("Bounce Timing")
@export_range(10.0, 120.0, 1.0) var bounce_permission_angle: float = 70.0
@export_range(5.0, 90.0, 1.0) var bounce_good_angle: float = 35.0
@export_range(2.0, 45.0, 1.0) var bounce_perfect_angle: float = 15.0
@export var bounce_preview_time: float = 0.45
@export_range(5.0, 90.0, 1.0) var bounce_alignment_angle: float = 35.0
@export_range(45.0, 180.0, 1.0) var bounce_preview_angle: float = 110.0

@export_category("Bounce Feedback")
@export var bounce_feedback_time: float = 0.25
@export var bounce_shadow_normal_color: Color = Color("#181818")
@export var bounce_shadow_ready_color: Color = Color("#5FD4F5")
@export var bounce_glow_ready_color: Color = Color("#48DFFF")
@export var bounce_miss_color: Color = Color("#FF5C5C")
@export var bounce_late_color: Color = Color("#F6C85F")
@export var bounce_good_color: Color = Color("#72E06A")
@export var bounce_perfect_color: Color = Color("#B66CFF")
@export var ground_shadow_bounce_feedback_enabled: bool = true

@export_category("Boost")
@export var boost_acceleration_multiplier: float = 1.6
@export var boost_max_speed_multiplier: float = 1.4
@export var boost_release_deceleration: float = 4.0

@export_category("Gravity")
@export var rise_gravity_multiplier: float = 0.9
@export var fall_gravity_multiplier: float = 1.25
@export var max_fall_speed: float = 18.0

@export_category("Ground Shadow")
@export var shadow_max_height: float = 10.0
@export var shadow_min_scale: float = 0.45
@export var shadow_max_scale: float = 1.0
@export var shadow_min_opacity: float = 0.12
@export var shadow_max_opacity: float = 0.45
@export var shadow_ground_offset: float = 0.02

@export_category("Rider Shadow")
@export var rider_shadow_surface_offset: float = 0.015
@export var rider_shadow_follow_speed: float = 14.0
@export var rider_shadow_max_separation: float = 1.5
@export var rider_shadow_min_scale: float = 0.45
@export var rider_shadow_max_scale: float = 0.85
@export var rider_shadow_min_opacity: float = 0.10
@export var rider_shadow_max_opacity: float = 0.38

#endregion


#region Node References

@onready var visual: Node3D = $Visual
@onready var bounce_glow: MeshInstance3D = $BounceGlow
@onready var rider_anchor: Marker3D = $RiderAnchor
@onready var ground_probe: RayCast3D = $GroundProbe
@onready var ground_shadow: MeshInstance3D = $GroundShadow
@onready var rider_shadow_root: Node3D = $RiderShadow
@onready var rider_shadow_mesh: MeshInstance3D = $RiderShadow/MeshInstance3D

#endregion


#region State

var jump_charge_time: float = 0.0
var is_charging_jump: bool = false
var is_boosting: bool = false

var bounce_input_timer: float = 0.0
var is_bounce_armed: bool = false
var armed_bounce_grade: BounceGrade = BounceGrade.NONE
var bounce_feedback_timer: float = 0.0
var bounce_feedback_grade: BounceGrade = BounceGrade.NONE

var ground_shadow_material: ShaderMaterial
var rider_shadow_material: ShaderMaterial
var bounce_glow_material: ShaderMaterial

var gravity: float = float(
	ProjectSettings.get_setting("physics/3d/default_gravity")
)

#endregion


#region Lifecycle

func _ready() -> void:
	setup_visual_materials()


func _physics_process(delta: float) -> void:
	bounce_feedback_timer = maxf(
	bounce_feedback_timer - delta,
	0.0
)

	if bounce_feedback_timer <= 0.0:
		bounce_feedback_grade = BounceGrade.NONE
	
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
	update_bounce_glow()
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
		control_multiplier = get_air_control_multiplier()

	if (
		is_on_floor()
		and not is_boosting
		and horizontal_velocity.length() > max_speed
	):
		var current_speed: float = horizontal_velocity.length()
		var reduced_speed: float = move_toward(
			current_speed,
			max_speed,
			boost_release_deceleration * delta
		)

		horizontal_velocity = (
			horizontal_velocity.normalized()
			* reduced_speed
		)

	if has_movement_input:
		input_direction = input_direction.normalized()

		var speed_before_input: float = horizontal_velocity.length()
		var allowed_speed: float = maxf(
			current_max_speed,
			speed_before_input
		)

		if horizontal_velocity.length() < 0.1:
			horizontal_velocity += (
				input_direction
				* current_acceleration
				* control_multiplier
				* delta
			)
		else:
			var momentum_direction: Vector3 = horizontal_velocity.normalized()
			var parallel_amount: float = input_direction.dot(
				momentum_direction
			)
			var parallel_input: Vector3 = (
				momentum_direction
				* parallel_amount
			)
			var lateral_input: Vector3 = (
				input_direction
				- parallel_input
			)

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
		return Vector3(
			input.x,
			0.0,
			input.y
		).normalized()

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


func get_air_control_multiplier() -> float:
	if rider != null and rider.is_diving():
		return 0.0

	return air_control

#endregion


#region Jump

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

#endregion


#region Bounce

func update_bounce_input(delta: float) -> void:
	bounce_input_timer = maxf(
		bounce_input_timer - delta,
		0.0
	)

	if bounce_input_timer <= 0.0:
		is_bounce_armed = false

	if not Input.is_action_just_pressed("jump"):
		return

	if is_on_floor():
		return

	if velocity.y >= 0.0:
		return

	var time_to_ground: float = (
		get_estimated_time_to_ground()
	)

	if time_to_ground > bounce_attempt_window:
		return

	var grade: BounceGrade = get_bounce_grade()

	if (
		time_to_ground > bounce_input_window
		or grade == BounceGrade.NONE
	):
		show_bounce_miss()
		return

	armed_bounce_grade = grade
	is_bounce_armed = true
	bounce_input_timer = bounce_input_window
	
	start_bounce_feedback(
		armed_bounce_grade
	)

	bounce_feedback.emit(
		armed_bounce_grade
	)


func can_arm_bounce() -> bool:
	if rider == null:
		return false

	if velocity.y >= 0.0:
		return false

	if get_estimated_time_to_ground() > bounce_input_window:
		return false

	return get_bounce_grade() != BounceGrade.NONE


func handle_landing(
	was_on_floor: bool,
	impact_velocity: float
) -> void:
	if was_on_floor or not is_on_floor():
		return

	var impact_speed: float = maxf(
		- impact_velocity,
		0.0
	)

	landed.emit(impact_speed)

	if not is_bounce_armed or bounce_input_timer <= 0.0:
		clear_armed_bounce()
		return

	var bounce_velocity: float = (
		impact_speed
		* bounce_retention
	)
	var min_bounce_velocity: float = (
		jump_velocity * 0.75
	)
	var max_bounce_velocity: float = charged_jump_velocity

	bounce_velocity = clampf(
		bounce_velocity,
		min_bounce_velocity,
		max_bounce_velocity
	)

	velocity.y = bounce_velocity
	bounce_input_timer = 0.0
	is_bounce_armed = false

	bounced.emit(
		impact_speed,
		bounce_velocity
	)


func clear_armed_bounce() -> void:
	is_bounce_armed = false
	armed_bounce_grade = BounceGrade.NONE
	bounce_input_timer = 0.0


func get_bounce_grade() -> BounceGrade:
	if rider == null:
		return BounceGrade.NONE

	var alignment: float = rider.get_spin_alignment_degrees()

	if alignment <= bounce_perfect_angle:
		return BounceGrade.PERFECT

	if alignment <= bounce_good_angle:
		return BounceGrade.GOOD

	if alignment <= bounce_permission_angle:
		return BounceGrade.LATE

	return BounceGrade.NONE


func get_bounce_grade_color(
	grade: BounceGrade
) -> Color:
	match grade:
		BounceGrade.MISS:
			return bounce_miss_color
		
		BounceGrade.LATE:
			return bounce_late_color

		BounceGrade.GOOD:
			return bounce_good_color

		BounceGrade.PERFECT:
			return bounce_perfect_color

	return bounce_glow_ready_color

#endregion


#region Bounce Feedback

func is_bounce_preview_active() -> bool:
	if rider == null:
		return false

	if velocity.y >= 0.0:
		return false

	return (
		get_estimated_time_to_ground()
		<= bounce_preview_time
	)


func show_bounce_miss() -> void:
	start_bounce_feedback(
		BounceGrade.MISS
	)

	bounce_feedback.emit(
		BounceGrade.MISS
	)


func get_bounce_preview_strength() -> float:
	if not is_bounce_preview_active():
		return 0.0

	var alignment_error: float = rider.get_spin_alignment_degrees()

	if alignment_error >= bounce_preview_angle:
		return 0.0

	if alignment_error <= bounce_alignment_angle:
		return 1.0

	return 1.0 - clampf(
		(
			alignment_error
			- bounce_alignment_angle
		)
		/ maxf(
			bounce_preview_angle
			- bounce_alignment_angle,
			0.001
		),
		0.0,
		1.0
	)


func update_bounce_glow() -> void:
	if bounce_glow_material == null:
		return

	var strength: float = 0.0
	var glow_color: Color = bounce_glow_ready_color

	if bounce_feedback_timer > 0.0:
		strength = 1.0
		glow_color = get_bounce_grade_color(
			bounce_feedback_grade
		)
	elif is_bounce_armed:
		strength = 1.0
		glow_color = get_bounce_grade_color(
			armed_bounce_grade
		)
	elif (
		is_bounce_preview_active()
		and get_bounce_grade() != BounceGrade.NONE
	):
		strength = 0.85

	bounce_glow_material.set_shader_parameter(
		"glow_strength",
		strength
	)

	bounce_glow_material.set_shader_parameter(
		"glow_color",
		glow_color
	)


func update_ground_shadow_bounce_color() -> void:
	if ground_shadow_material == null:
		return

	var shadow_color: Color = bounce_shadow_normal_color

	if ground_shadow_bounce_feedback_enabled:
		if bounce_feedback_timer > 0.0:
			shadow_color = get_bounce_grade_color(
				bounce_feedback_grade
			)
		elif is_bounce_armed:
			shadow_color = get_bounce_grade_color(
				armed_bounce_grade
			)
		elif is_bounce_preview_active():
			var preview_strength: float = (
				get_bounce_preview_strength()
			)

			shadow_color = bounce_shadow_normal_color.lerp(
				bounce_shadow_ready_color,
				preview_strength
			)

	ground_shadow_material.set_shader_parameter(
		"shadow_color",
		shadow_color
	)


func set_ground_shadow_bounce_feedback_enabled(
	enabled: bool
) -> void:
	ground_shadow_bounce_feedback_enabled = enabled

	if not enabled and ground_shadow_material != null:
		ground_shadow_material.set_shader_parameter(
			"shadow_color",
			bounce_shadow_normal_color
		)


func start_bounce_feedback(
	grade: BounceGrade
) -> void:
	bounce_feedback_grade = grade
	bounce_feedback_timer = bounce_feedback_time


#endregion


#region Physics

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var gravity_multiplier: float = rise_gravity_multiplier

	if velocity.y < 0.0:
		gravity_multiplier = fall_gravity_multiplier

	velocity.y -= gravity * gravity_multiplier * delta
	velocity.y = maxf(
		velocity.y,
		- max_fall_speed
	)


func check_fall_reset() -> void:
	if global_position.y < -10.0:
		get_tree().reload_current_scene()

#endregion


#region Visuals

func setup_visual_materials() -> void:
	ground_shadow.top_level = true

	ground_shadow_material = duplicate_active_shader_material(
		ground_shadow
	)
	rider_shadow_material = duplicate_active_shader_material(
		rider_shadow_mesh
	)
	bounce_glow_material = duplicate_active_shader_material(
		bounce_glow
	)

	if bounce_glow_material != null:
		bounce_glow_material.set_shader_parameter(
			"glow_strength",
			0.0
		)

	if rider_shadow_target == null:
		rider_shadow_mesh.visible = false


func duplicate_active_shader_material(
	mesh: MeshInstance3D
) -> ShaderMaterial:
	var source_material: Material = mesh.material_override

	if not source_material is ShaderMaterial:
		source_material = mesh.get_active_material(0)

	if not source_material is ShaderMaterial:
		return null

	var material: ShaderMaterial = (
		source_material.duplicate()
		as ShaderMaterial
	)

	mesh.material_override = material
	return material


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
	var angle: float = (
		horizontal_velocity.length()
		* delta
		/ radius
	)

	visual.rotate(
		rotation_axis,
		angle
	)

#endregion


#region Shadows

func update_ground_shadow() -> void:
	ground_probe.force_raycast_update()

	if not ground_probe.is_colliding():
		ground_shadow.visible = false
		return

	ground_shadow.visible = true

	var ground_position: Vector3 = ground_probe.get_collision_point()
	var height: float = global_position.distance_to(
		ground_position
	)
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
	update_ground_shadow_bounce_color()


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

	var separation: float = (
		rider_shadow_target.global_position.distance_to(
			rider_anchor.global_position
		)
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


#region Ground Query

func get_ground_clearance() -> float:
	ground_probe.force_raycast_update()

	if not ground_probe.is_colliding():
		return INF

	var ground_position: Vector3 = (
		ground_probe.get_collision_point()
	)
	var center_distance: float = global_position.distance_to(
		ground_position
	)

	return maxf(
		center_distance - radius,
		0.0
	)


func get_estimated_time_to_ground() -> float:
	if velocity.y >= 0.0:
		return INF

	var clearance: float = get_ground_clearance()

	if is_inf(clearance):
		return INF

	var fall_acceleration: float = maxf(
		gravity * fall_gravity_multiplier,
		0.001
	)
	var discriminant: float = (
		velocity.y * velocity.y +2.0 * fall_acceleration * clearance
	)

	return (
		velocity.y
		+ sqrt(discriminant)
	) / fall_acceleration

#endregion
