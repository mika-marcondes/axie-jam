extends Node
class_name PerformanceController

signal appeal_changed(value: int)
signal combo_changed(points: int, chain: int)
signal event_scored(event_name: String, points: int)

signal combo_banked(points: int, multiplier: float)
signal combo_continued(chain: int)

@export_category("References")
@export var ball: BallController
@export var player: PlayerController
@export var scoring: ScoringConfig

var total_appeal: int = 0

var combo_points: int = 0
var combo_chain: int = 0
var combo_event_count: int = 0

var was_on_floor: bool = true
var pending_bounce: bool = false

var takeoff_y: float = 0.0
var max_air_y: float = 0.0
var spin_progress_degrees: float = 0.0


func _ready() -> void:
	if scoring == null:
		push_error("PerformanceController requires a ScoringConfig.")
		return

	if ball == null:
		push_error("PerformanceController requires a BallController.")
		return

	was_on_floor = ball.is_on_floor()

	if not ball.bounced.is_connected(_on_ball_bounced):
		ball.bounced.connect(_on_ball_bounced)


func _physics_process(delta: float) -> void:
	if ball == null or player == null or scoring == null:
		return

	var is_on_floor: bool = ball.is_on_floor()

	if was_on_floor and not is_on_floor:
		begin_air()

	if not is_on_floor:
		update_air(delta)

	if not was_on_floor and is_on_floor:
		end_air()

	was_on_floor = is_on_floor


#region Air Tracking

func begin_air() -> void:
	takeoff_y = ball.global_position.y
	max_air_y = takeoff_y
	spin_progress_degrees = 0.0


func update_air(delta: float) -> void:
	max_air_y = maxf(
		max_air_y,
		ball.global_position.y
	)

	spin_progress_degrees += (
		player.get_spin_velocity()
		* delta
	)

	while absf(spin_progress_degrees) >= 360.0:
		score_spin()

		var rotation_sign: float = (
			1.0
			if spin_progress_degrees >= 0.0
			else -1.0
		)

		spin_progress_degrees -= (
			360.0
			* rotation_sign
		)


func end_air() -> void:
	var jump_height: float = maxf(
		max_air_y - takeoff_y,
		0.0
	)

	score_air_height(jump_height)

	if pending_bounce:
		continue_combo()
	else:
		bank_combo()

	pending_bounce = false

#endregion


#region Scoring

func score_spin() -> void:
	var points: int = roundi(
		scoring.spin_base_points
		* scoring.spin_rotation_multiplier
	)

	score_event(
		"360 Spin",
		points
	)


func score_air_height(height: float) -> void:
	if height < scoring.minimum_air_height:
		return

	if height < scoring.small_air_height:
		score_event(
			"Small Air %.1fm" % height,
			scoring.small_air_points
		)
	elif height < scoring.medium_air_height:
		score_event(
			"Air %.1fm" % height,
			scoring.medium_air_points
		)
	elif height < scoring.big_air_height:
		score_event(
			"Big Air %.1fm" % height,
			scoring.big_air_points
		)
	else:
		score_event(
			"Huge Air %.1fm" % height,
			scoring.huge_air_points
		)


func score_event(
	event_name: String,
	points: int
) -> void:
	if combo_chain <= 0:
		combo_chain = 1

	combo_points += points
	combo_event_count += 1

	event_scored.emit(
		event_name,
		points
	)

	combo_changed.emit(
		combo_points,
		combo_chain
	)


func continue_combo() -> void:
	if combo_chain <= 0:
		combo_chain = 1
	else:
		combo_chain += 1

	score_event(
		"Bounce",
		scoring.bounce_points
	)

	combo_continued.emit(combo_chain)


func bank_combo() -> void:
	if combo_points <= 0:
		reset_combo()
		return

	var multiplier: float = get_combo_multiplier()
	var banked_points: int = roundi(
		combo_points
		* multiplier
	)

	total_appeal += banked_points

	combo_banked.emit(
		banked_points,
		multiplier
	)

	appeal_changed.emit(total_appeal)

	reset_combo()


func reset_combo() -> void:
	combo_points = 0
	combo_chain = 0
	combo_event_count = 0

	combo_changed.emit(
		combo_points,
		combo_chain
	)


func get_combo_multiplier() -> float:
	return float(
		maxi(combo_chain, 1)
	)

#endregion


#region Ball Events

func _on_ball_bounced(
	_impact_speed: float,
	_bounce_velocity: float
) -> void:
	pending_bounce = true

#endregion
