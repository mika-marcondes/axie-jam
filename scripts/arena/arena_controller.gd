@tool
extends Node3D
class_name ArenaController

@export_category("Arena Size")
@export var arena_width: float = 24.0:
	set(value):
		arena_width = maxf(value, 2.0)
		request_update()

@export var arena_length: float = 32.0:
	set(value):
		arena_length = maxf(value, 2.0)
		request_update()

@export var floor_thickness: float = 0.25:
	set(value):
		floor_thickness = maxf(value, 0.05)
		request_update()

@export_category("Barriers")
@export var barrier_height: float = 2.0:
	set(value):
		barrier_height = maxf(value, 0.1)
		request_update()

@export var barrier_collision_height: float = 12.0:
	set(value):
		barrier_collision_height = maxf(
			value,
			barrier_height
		)
		request_update()

@export var barrier_thickness: float = 0.4:
	set(value):
		barrier_thickness = maxf(value, 0.05)
		request_update()


func _ready() -> void:
	update_arena()


func request_update() -> void:
	if not is_inside_tree():
		return

	update_arena()


func update_arena() -> void:
	update_floor()
	update_barriers()


func update_floor() -> void:
	var floor_body: StaticBody3D = get_node_or_null(
		"Floor"
	)

	if floor_body == null:
		return

	var size: Vector3 = Vector3(
		arena_width,
		floor_thickness,
		arena_length
	)

	configure_floor(
		floor_body,
		size
	)

	floor_body.position = Vector3(
		0.0,
		-floor_thickness * 0.5,
		0.0
	)


func update_barriers() -> void:
	var north: StaticBody3D = get_node_or_null(
		"Barriers/North"
	)
	var south: StaticBody3D = get_node_or_null(
		"Barriers/South"
	)
	var east: StaticBody3D = get_node_or_null(
		"Barriers/East"
	)
	var west: StaticBody3D = get_node_or_null(
		"Barriers/West"
	)

	if (
		north == null
		or south == null
		or east == null
		or west == null
	):
		return

	var half_width: float = (
		arena_width * 0.5
	)
	var half_length: float = (
		arena_length * 0.5
	)
	var half_barrier: float = (
		barrier_thickness * 0.5
	)

	var horizontal_size: Vector2 = Vector2(
		arena_width
		+ barrier_thickness * 2.0,
		barrier_thickness
	)

	var vertical_size: Vector2 = Vector2(
		barrier_thickness,
		arena_length
		+ barrier_thickness * 2.0
	)

	configure_barrier(
		north,
		horizontal_size
	)
	configure_barrier(
		south,
		horizontal_size
	)
	configure_barrier(
		east,
		vertical_size
	)
	configure_barrier(
		west,
		vertical_size
	)

	north.position = Vector3(
		0.0,
		0.0,
		-half_length - half_barrier
	)

	south.position = Vector3(
		0.0,
		0.0,
		half_length + half_barrier
	)

	east.position = Vector3(
		half_width + half_barrier,
		0.0,
		0.0
	)

	west.position = Vector3(
		-half_width - half_barrier,
		0.0,
		0.0
	)


func configure_floor(
	body: StaticBody3D,
	size: Vector3
) -> void:
	var mesh_instance: MeshInstance3D = (
		body.get_node_or_null("MeshInstance3D")
	)

	var collision_shape: CollisionShape3D = (
		body.get_node_or_null("CollisionShape3D")
	)

	if (
		mesh_instance == null
		or collision_shape == null
	):
		return

	var box_mesh: BoxMesh = (
		mesh_instance.mesh as BoxMesh
	)

	var box_shape: BoxShape3D = (
		collision_shape.shape as BoxShape3D
	)

	if box_mesh == null or box_shape == null:
		return

	box_mesh.size = size
	box_shape.size = size


func configure_barrier(
	body: StaticBody3D,
	horizontal_size: Vector2
) -> void:
	var mesh_instance: MeshInstance3D = (
		body.get_node_or_null("MeshInstance3D")
	)

	var collision_shape: CollisionShape3D = (
		body.get_node_or_null("CollisionShape3D")
	)

	if (
		mesh_instance == null
		or collision_shape == null
	):
		return

	var box_mesh: BoxMesh = (
		mesh_instance.mesh as BoxMesh
	)

	var box_shape: BoxShape3D = (
		collision_shape.shape as BoxShape3D
	)

	if box_mesh == null or box_shape == null:
		return

	box_mesh.size = Vector3(
		horizontal_size.x,
		barrier_height,
		horizontal_size.y
	)

	box_shape.size = Vector3(
		horizontal_size.x,
		barrier_collision_height,
		horizontal_size.y
	)

	mesh_instance.position.y = (
		barrier_height * 0.5
	)

	collision_shape.position.y = (
		barrier_collision_height * 0.5
	)
