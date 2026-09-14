extends Node3D

@export var target: Node3D
@export var follow_speed: float = 8.0
@export var look_height: float = 1.0

@onready var camera: Camera3D = $Camera3D


func _physics_process(delta: float) -> void:
	if target == null:
		return

	# Move the rig toward the target without rotating the rig itself.
	global_position = global_position.lerp(
		target.global_position,
		clampf(follow_speed * delta, 0.0, 1.0)
	)

	# Rotate only the camera toward the target.
	var look_target: Vector3 = target.global_position + Vector3.UP * look_height
	camera.look_at(look_target, Vector3.UP)
