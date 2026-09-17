extends Node3D

@export_category("References")
@export var target: BallController

@export_category("Follow")
@export var follow_speed: float = 8.0
@export var look_height: float = 1.0

@export_category("Manual Orbit")
@export var manual_orbit_speed: float = 2.5
@export var manual_override_delay: float = 1.0

@export_category("Auto Follow")
@export var auto_follow_enabled: bool = true
@export var auto_follow_speed: float = 2.5
@export var min_auto_follow_speed: float = 1.5

@onready var yaw_pivot: Node3D = $YawPivot
@onready var camera: Camera3D = $YawPivot/Camera3D

var manual_override_timer: float = 0.0


func _process(delta: float) -> void:
	if target == null:
		return

	follow_target(delta)
	update_camera_yaw(delta)
	look_at_target()


func follow_target(delta: float) -> void:
	global_position = global_position.lerp(
		target.global_position,
		clampf(follow_speed * delta, 0.0, 1.0)
	)


func update_camera_yaw(delta: float) -> void:
	var camera_input: float = Input.get_axis(
		"camera_left", "camera_right"
	)

	if absf(camera_input) > 0.01:
		handle_manual_orbit(camera_input, delta)
		return

	manual_override_timer = maxf(
		manual_override_timer - delta,
		0.0
	)

	if auto_follow_enabled and manual_override_timer <= 0.0:
		handle_auto_follow(delta)


func handle_manual_orbit(
	camera_input: float,
	delta: float
) -> void:
	yaw_pivot.rotate_y(
		-camera_input * manual_orbit_speed * delta
	)

	manual_override_timer = manual_override_delay


func handle_auto_follow(delta: float) -> void:
	var horizontal_velocity: Vector3 = Vector3(
		target.velocity.x, 0.0, target.velocity.z
	)

	if horizontal_velocity.length() < min_auto_follow_speed:
		return

	var movement_direction: Vector3 = horizontal_velocity.normalized()

	# Align the camera behind the actual movement direction.
	var target_yaw: float = atan2(
		-movement_direction.x,
		-movement_direction.z
	)

	yaw_pivot.rotation.y = lerp_angle(
		yaw_pivot.rotation.y,
		target_yaw,
		clampf(auto_follow_speed * delta, 0.0, 1.0)
	)


func look_at_target() -> void:
	var look_target: Vector3 = (
		target.global_position
		+ Vector3.UP * look_height
	)

	camera.look_at(
		look_target,
		Vector3.UP
	)
