extends Node
class_name AxieAnimationController

@export_category("Locomotion")
@export var run_speed_reference: float = 8.0
@export var blend_response: float = 6.0

@onready var animation_tree: AnimationTree = $"../AnimationTree"

var player: PlayerController
var ball: BallController

var playback: AnimationNodeStateMachinePlayback
var locomotion_blend: float = 0.0


func _ready() -> void:
	animation_tree.active = true

	playback = animation_tree.get(
		"parameters/playback"
	) as AnimationNodeStateMachinePlayback


func setup(
	player_controller: PlayerController,
	ball_controller: BallController
) -> void:
	player = player_controller
	ball = ball_controller

	if playback != null:
		playback.start("Grounded")


func _process(delta: float) -> void:
	if player == null or ball == null or playback == null:
		return

	if ball.is_on_floor():
		update_grounded_animation(delta)
	else:
		update_airborne_animation()


func update_grounded_animation(delta: float) -> void:
	if playback.get_current_node() != "Grounded":
		playback.travel("Grounded")

	var horizontal_speed: float = Vector2(
		ball.velocity.x,
		ball.velocity.z
	).length()

	var target_blend: float = clampf(
		horizontal_speed / maxf(run_speed_reference, 0.001),
		0.0,
		1.0
	)

	locomotion_blend = move_toward(
		locomotion_blend,
		target_blend,
		blend_response * delta
	)

	animation_tree.set(
		"parameters/Grounded/blend_position",
		locomotion_blend
	)


func update_airborne_animation() -> void:
	if playback.get_current_node() != "Airborne":
		playback.travel("Airborne")
