extends Node3D

@export var target: Node3D
@export var follow_speed: float = 8.0
@export var look_height: float = 1.0
@export var orbit_speed: float = 2.5

@onready var yaw_pivot: Node3D = $YawPivot
@onready var camera: Camera3D = $YawPivot/Camera3D


func _physics_process(delta: float) -> void:
	if target == null:
		return

	follow_target(delta)
	handle_orbit(delta)
	look_at_target()


func follow_target(delta: float) -> void:
	global_position = global_position.lerp(
		target.global_position,
		clampf(follow_speed * delta, 0.0, 1.0)
	)


func handle_orbit(delta: float) -> void:
	var camera_input: float = Input.get_axis(
		"camera_left",
		"camera_right"
	)

	yaw_pivot.rotate_y(
		- camera_input * orbit_speed * delta
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
