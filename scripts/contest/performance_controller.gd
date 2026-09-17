extends Node
class_name PerformanceController

signal appeal_changed(value: int)
signal combo_changed(points: int, chain: int)
signal event_scored(event_name: String, points: int)

@export_category("References")
@export var ball: BallController
@export var player: PlayerController

var total_appeal: int = 0
var combo_points: int = 0
var combo_chain: int = 0

var was_on_floor: bool = true

var takeoff_y: float = 0.0
var max_air_y: float = 0.0
var spin_progress_degrees: float = 0.0


func _ready() -> void:
	if ball != null:
		was_on_floor = ball.is_on_floor()


func _physics_process(delta: float) -> void:
	if ball == null or player == null:
		return

	var is_on_floor: bool = ball.is_on_floor()

	if was_on_floor and not is_on_floor:
		begin_air()

	if not is_on_floor:
		update_air(delta)

	if not was_on_floor and is_on_floor:
		end_air()

	was_on_floor = is_on_floor


func begin_air() -> void:
	takeoff_y = ball.global_position.y
	max_air_y = takeoff_y
	spin_progress_degrees = 0.0


func update_air(delta: float) -> void:
	max_air_y = maxf(
		max_air_y,
		ball.global_position.y
	)

	spin_progress_degrees += player.get_spin_velocity() * delta

	while absf(spin_progress_degrees) >= 360.0:
		score_event("360 Spin", 50)

		var rotation_sign: float = (
			1.0
			if spin_progress_degrees >= 0.0
			else -1.0
		)

		spin_progress_degrees -= 360.0 * rotation_sign


func end_air() -> void:
	var jump_height: float = maxf(
		max_air_y - takeoff_y,
		0.0
	)

	score_air_height(jump_height)


func score_air_height(height: float) -> void:
	if height < 0.4:
		return

	if height < 1.0:
		score_event("Small Air %.1fm" % height, 5)
	elif height < 2.0:
		score_event("Air %.1fm" % height, 25)
	elif height < 3.5:
		score_event("Big Air %.1fm" % height, 60)
	else:
		score_event("Huge Air %.1fm" % height, 100)


func score_event(event_name: String, points: int) -> void:
	total_appeal += points
	combo_points += points
	combo_chain += 1

	event_scored.emit(event_name, points)
	appeal_changed.emit(total_appeal)
	combo_changed.emit(combo_points, combo_chain)


func reset_combo() -> void:
	combo_points = 0
	combo_chain = 0

	combo_changed.emit(combo_points, combo_chain)
