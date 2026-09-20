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

@export_category("Spin Variety")
@export_range(0.0, 1.0, 0.05)
var tuck_threshold: float = 0.5
@export var spin_velocity_threshold: float = 5.0

@export_category("Dive")
@export var minimum_dive_hold_time: float = 0.35
@export var dive_points_per_second: float = 30.0

@export_category("Live Multiplier")
@export var starting_multiplier: float = 1.0
@export var late_bounce_multiplier_gain: float = 0.5
@export var good_bounce_multiplier_gain: float = 1.0
@export var perfect_bounce_multiplier_gain: float = 1.5
@export var multiplier_cap: float = 0.0

var total_appeal: int = 0

var combo_points: int = 0
var combo_chain: int = 0
var combo_event_count: int = 0
var combo_multiplier: float = 1.0

var was_on_floor: bool = true
var pending_bounce: bool = false
var pending_bounce_grade: BallController.BounceGrade = (
	BallController.BounceGrade.NONE
)

var takeoff_y: float = 0.0
var max_air_y: float = 0.0
var dive_hold_time: float = 0.0

var active_spin_family: StringName = &""
var active_spin_rotations: int = 0
var active_spin_modifier: float = 1.0
var spin_progress_degrees: float = 0.0

var last_trick_family: StringName = &""
var repetition_count: int = 0


#region Lifecycle

func _ready() -> void:
	if scoring == null:
		push_error(
			"PerformanceController requires a ScoringConfig."
		)
		return

	if ball == null:
		push_error(
			"PerformanceController requires a BallController."
		)
		return

	combo_multiplier = starting_multiplier
	was_on_floor = ball.is_on_floor()

	if not ball.bounced.is_connected(
		_on_ball_bounced
	):
		ball.bounced.connect(
			_on_ball_bounced
		)

	if not ball.bounce_feedback.is_connected(
		_on_bounce_feedback
	):
		ball.bounce_feedback.connect(
			_on_bounce_feedback
		)


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

#endregion


#region Air Tracking

func begin_air() -> void:
	takeoff_y = ball.global_position.y
	max_air_y = takeoff_y
	dive_hold_time = 0.0

	reset_active_spin()


func update_air(delta: float) -> void:
	max_air_y = maxf(
		max_air_y,
		ball.global_position.y
	)

	update_spin(delta)
	update_dive_hold(delta)


func end_air() -> void:
	finalize_spin_segment()
	score_dive_hold()

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
	pending_bounce_grade = (
		BallController.BounceGrade.NONE
	)

#endregion


#region Spin Tracking

func update_spin(delta: float) -> void:
	var spin_velocity: float = (
		player.get_spin_velocity()
	)

	if absf(spin_velocity) < spin_velocity_threshold:
		return

	var family: StringName = get_spin_family(
		spin_velocity,
		player.get_tuck_amount() >= tuck_threshold
	)

	if active_spin_family == &"":
		begin_spin_segment(family)
	elif family != active_spin_family:
		finalize_spin_segment()
		begin_spin_segment(family)

	spin_progress_degrees += (
		absf(spin_velocity)
		* delta
	)

	while spin_progress_degrees >= 360.0:
		score_spin_rotation()

		spin_progress_degrees -= 360.0


func begin_spin_segment(
	family: StringName
) -> void:
	active_spin_family = family
	active_spin_rotations = 0
	active_spin_modifier = 1.0
	spin_progress_degrees = 0.0


func score_spin_rotation() -> void:
	if active_spin_family == &"":
		return

	if active_spin_rotations == 0:
		active_spin_modifier = (
			get_repetition_modifier(
				active_spin_family
			)
		)

	active_spin_rotations += 1

	var points: int = roundi(
		scoring.spin_base_points
		* scoring.spin_rotation_multiplier
		* active_spin_modifier
	)

	score_event(
		get_spin_event_name(
			active_spin_family
		),
		points
	)


func finalize_spin_segment() -> void:
	if (
		active_spin_family != &""
		and active_spin_rotations > 0
	):
		commit_trick_family(
			active_spin_family
		)

	reset_active_spin()


func reset_active_spin() -> void:
	active_spin_family = &""
	active_spin_rotations = 0
	active_spin_modifier = 1.0
	spin_progress_degrees = 0.0


func get_spin_family(
	spin_velocity: float,
	tucked: bool
) -> StringName:
	var is_right: bool = spin_velocity > 0.0

	if tucked:
		return (
			&"tuck_spin_right"
			if is_right
			else &"tuck_spin_left"
		)

	return (
		&"spin_right"
		if is_right
		else &"spin_left"
	)


func get_spin_event_name(
	family: StringName
) -> String:
	match family:
		&"spin_left":
			return "L Spin"

		&"spin_right":
			return "R Spin"

		&"tuck_spin_left":
			return "L Tuck Spin"

		&"tuck_spin_right":
			return "R Tuck Spin"

	return "Spin"

#endregion


#region Dive Tracking

func update_dive_hold(delta: float) -> void:
	if (
		Input.is_action_pressed("trick_dive")
		and player.is_diving()
	):
		dive_hold_time += delta


func score_dive_hold() -> void:
	if dive_hold_time < minimum_dive_hold_time:
		return

	var base_points: int = roundi(
		dive_hold_time
		* dive_points_per_second
	)

	score_trick_event(
		"Dive %.1fs" % dive_hold_time,
		base_points,
		&"dive"
	)

#endregion


#region Repetition

func get_repetition_modifier(
	family: StringName
) -> float:
	if family != last_trick_family:
		return 1.0

	return pow(
		scoring.repetition_penalty,
		repetition_count + 1
	)


func commit_trick_family(
	family: StringName
) -> void:
	if family == last_trick_family:
		repetition_count += 1
		return

	last_trick_family = family
	repetition_count = 0


func reset_repetition() -> void:
	last_trick_family = &""
	repetition_count = 0

#endregion


#region Scoring

func score_trick_event(
	event_name: String,
	base_points: int,
	family: StringName
) -> void:
	var modifier: float = (
		get_repetition_modifier(family)
	)

	var points: int = roundi(
		base_points
		* modifier
	)

	score_event(
		event_name,
		points
	)

	commit_trick_family(family)


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

	emit_combo_changed()


func continue_combo() -> void:
	if combo_chain <= 0:
		combo_chain = 1
	else:
		combo_chain += 1

	apply_bounce_multiplier(
		pending_bounce_grade
	)

	combo_continued.emit(
		combo_chain
	)

	emit_combo_changed()


func apply_bounce_multiplier(
	grade: BallController.BounceGrade
) -> void:
	var gain: float = 0.0

	match grade:
		BallController.BounceGrade.LATE:
			gain = late_bounce_multiplier_gain

		BallController.BounceGrade.GOOD:
			gain = good_bounce_multiplier_gain

		BallController.BounceGrade.PERFECT:
			gain = perfect_bounce_multiplier_gain

		_:
			gain = late_bounce_multiplier_gain

	combo_multiplier += gain

	if multiplier_cap > 0.0:
		combo_multiplier = minf(
			combo_multiplier,
			multiplier_cap
		)


func bank_combo() -> void:
	if combo_points <= 0:
		reset_combo()
		return

	var multiplier: float = (
		get_combo_multiplier()
	)

	var banked_points: int = roundi(
		combo_points
		* multiplier
	)

	total_appeal += banked_points

	combo_banked.emit(
		banked_points,
		multiplier
	)

	appeal_changed.emit(
		total_appeal
	)

	reset_combo()


func reset_combo() -> void:
	combo_points = 0
	combo_chain = 0
	combo_event_count = 0
	combo_multiplier = starting_multiplier

	reset_repetition()
	reset_active_spin()

	combo_changed.emit(
		combo_points,
		combo_chain
	)


func emit_combo_changed() -> void:
	combo_changed.emit(
		combo_points,
		combo_chain
	)


func get_combo_multiplier() -> float:
	return maxf(
		combo_multiplier,
		starting_multiplier
	)

#endregion


#region Ball Events

func _on_bounce_feedback(
	grade: BallController.BounceGrade
) -> void:
	match grade:
		BallController.BounceGrade.LATE:
			pending_bounce_grade = grade

		BallController.BounceGrade.GOOD:
			pending_bounce_grade = grade

		BallController.BounceGrade.PERFECT:
			pending_bounce_grade = grade


func _on_ball_bounced(
	_impact_speed: float,
	_bounce_velocity: float
) -> void:
	pending_bounce = true

#endregion
