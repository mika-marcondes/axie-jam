extends CanvasLayer

@export_category("References")
@export var ball: BallController
@export var player: PlayerController
@export var performance: PerformanceController

@export_category("Display")
@export var bank_display_time: float = 1.5
@export_range(0.0, 1.0, 0.05) var tuck_display_threshold: float = 0.5

@export_category("Colors")
@export var active_combo_color: Color = Color("#F6C85F")
@export var banked_score_color: Color = Color("#4AB7FF")
@export var appeal_color: Color = Color("#4AB7FF")
@export var trick_line_color: Color = Color("#FFFFFF")

@export_category("Bounce Feedback")
@export var bounce_feedback_display_time: float = 0.65

@onready var appeal_label: Label = %AppealLabel
@onready var combo_score_label: Label = %ComboLabel
@onready var trick_line_label: Label = %TrickLineLabel
@onready var bounce_feedback_label: Label = %BounceFeedbackLabel
@onready var speed_label: Label = %SpeedLabel
@onready var rpm_label: Label = %RPMLabel

var trick_segments: Array[String] = []
var current_spin_rotations: int = 0
var current_spin_direction: String = ""
var current_spin_tucked: bool = false

var showing_bank_result: bool = false
var display_revision: int = 0
var bounce_feedback_revision: int = 0


#region Lifecycle

func _ready() -> void:
	if ball != null:
		ball.bounce_feedback.connect(
			_on_bounce_feedback
		)

	bounce_feedback_label.text = ""

	if performance == null:
		return

	performance.appeal_changed.connect(
		_on_appeal_changed
	)
	performance.combo_changed.connect(
		_on_combo_changed
	)
	performance.event_scored.connect(
		_on_event_scored
	)
	performance.combo_banked.connect(
		_on_combo_banked
	)

	combo_score_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	trick_line_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	trick_line_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	appeal_label.add_theme_color_override(
		"font_color",
		appeal_color
	)
	trick_line_label.add_theme_color_override(
		"font_color",
		trick_line_color
	)

	update_score_labels()


func _process(_delta: float) -> void:
	update_telemetry()

#endregion


#region Telemetry

func update_telemetry() -> void:
	if ball != null:
		var speed: float = Vector2(
			ball.velocity.x,
			ball.velocity.z
		).length()

		speed_label.text = "SPEED  %.1f" % speed

	if player != null:
		var rpm: float = absf(
			player.get_spin_rpm()
		)
		var air_height: float = (
			player.get_current_jump_height()
		)

		rpm_label.text = (
			"RPM  %.0f    AIR  %.1f m"
			% [rpm, air_height]
		)

#endregion


#region Score Display

func update_score_labels() -> void:
	if performance == null:
		return

	appeal_label.text = (
		"APPEAL  %d"
		% performance.total_appeal
	)
	appeal_label.add_theme_color_override(
		"font_color",
		appeal_color
	)

	if showing_bank_result:
		return

	if performance.combo_points > 0:
		update_combo_score(
			performance.combo_points,
			performance.combo_chain
		)
	else:
		combo_score_label.text = ""


func update_combo_score(
	points: int,
	chain: int
) -> void:
	combo_score_label.text = "%d × %d" % [
		points,
		maxi(chain, 1)
	]
	combo_score_label.add_theme_color_override(
		"font_color",
		active_combo_color
	)


func cancel_bank_display_for_new_combo() -> void:
	if not showing_bank_result:
		return

	showing_bank_result = false
	display_revision += 1
	clear_combo_display()

#endregion


#region Trick Line

func add_spin_rotation() -> void:
	if player == null:
		return

	var direction: String = get_spin_direction()
	var tucked: bool = (
		player.get_tuck_amount()
		>= tuck_display_threshold
	)

	if direction.is_empty():
		direction = current_spin_direction

	var same_spin: bool = (
		current_spin_rotations > 0
		and current_spin_direction == direction
		and current_spin_tucked == tucked
	)

	if current_spin_rotations > 0 and not same_spin:
		finish_spin_segment()

	if current_spin_rotations <= 0:
		current_spin_direction = direction
		current_spin_tucked = tucked

	current_spin_rotations += 1
	update_trick_line()


func get_spin_direction() -> String:
	if player == null:
		return ""

	var spin_velocity: float = (
		player.get_spin_velocity()
	)

	if spin_velocity > 0.01:
		return "R"

	if spin_velocity < -0.01:
		return "L"

	return ""


func finish_spin_segment() -> void:
	if current_spin_rotations <= 0:
		return

	var segment: String = build_spin_segment(
		current_spin_rotations,
		current_spin_direction,
		current_spin_tucked
	)

	if not segment.is_empty():
		trick_segments.append(segment)

	current_spin_rotations = 0
	current_spin_direction = ""
	current_spin_tucked = false


func build_current_spin_segment() -> String:
	return build_spin_segment(
		current_spin_rotations,
		current_spin_direction,
		current_spin_tucked
	)


func build_spin_segment(
	rotations: int,
	direction: String,
	tucked: bool
) -> String:
	if rotations <= 0:
		return ""

	var degrees: int = rotations * 360
	var direction_prefix: String = ""

	if not direction.is_empty():
		direction_prefix = "%s " % direction

	if tucked:
		return "%s%d Tuck Spin" % [
			direction_prefix,
			degrees
		]

	return "%s%d Spin" % [
		direction_prefix,
		degrees
	]


func add_trick_event(event_name: String) -> void:
	finish_spin_segment()
	trick_segments.append(event_name)
	update_trick_line()


func is_air_event(event_name: String) -> bool:
	return (
		event_name.begins_with("Small Air ")
		or event_name.begins_with("Air ")
		or event_name.begins_with("Medium Air ")
		or event_name.begins_with("Big Air ")
		or event_name.begins_with("Huge Air ")
	)


func update_trick_line() -> void:
	var display_segments: Array[String] = (
		trick_segments.duplicate()
	)
	var current_spin: String = (
		build_current_spin_segment()
	)

	if not current_spin.is_empty():
		display_segments.append(
			current_spin
		)

	trick_line_label.text = " + ".join(
		display_segments
	)


func clear_combo_display() -> void:
	trick_segments.clear()
	current_spin_rotations = 0
	current_spin_direction = ""
	current_spin_tucked = false

	combo_score_label.text = ""
	trick_line_label.text = ""

#endregion


#region Performance Signals

func _on_appeal_changed(value: int) -> void:
	appeal_label.text = "APPEAL  %d" % value
	appeal_label.add_theme_color_override(
		"font_color",
		appeal_color
	)


func _on_combo_changed(
	points: int,
	chain: int
) -> void:
	if points <= 0:
		return

	if showing_bank_result:
		cancel_bank_display_for_new_combo()

	update_combo_score(
		points,
		chain
	)


func _on_event_scored(
	event_name: String,
	_points: int
) -> void:
	if showing_bank_result:
		cancel_bank_display_for_new_combo()

	if event_name == "Bounce":
		return

	if event_name == "360 Spin":
		add_spin_rotation()
		return

	if is_air_event(event_name):
		finish_spin_segment()
		update_trick_line()
		return

	add_trick_event(event_name)


func _on_combo_banked(
	points: int,
	_multiplier: float
) -> void:
	finish_spin_segment()
	update_trick_line()

	showing_bank_result = true
	display_revision += 1

	var bank_revision: int = display_revision

	combo_score_label.text = "+%d APPEAL" % points
	combo_score_label.add_theme_color_override(
		"font_color",
		banked_score_color
	)

	await get_tree().create_timer(
		bank_display_time
	).timeout

	if bank_revision != display_revision:
		return

	showing_bank_result = false
	clear_combo_display()


func _on_bounce_feedback(
	grade: BallController.BounceGrade
) -> void:
	var feedback_text: String = ""

	match grade:
		BallController.BounceGrade.MISS:
			feedback_text = "MISS"

		BallController.BounceGrade.LATE:
			feedback_text = "LATE"

		BallController.BounceGrade.GOOD:
			feedback_text = "GOOD"

		BallController.BounceGrade.PERFECT:
			feedback_text = "PERFECT!"

		_:
			return

	bounce_feedback_label.text = feedback_text
	bounce_feedback_label.add_theme_color_override(
		"font_color",
		ball.get_bounce_grade_color(grade)
	)

	bounce_feedback_revision += 1
	var revision: int = bounce_feedback_revision

	await get_tree().create_timer(
		bounce_feedback_display_time
	).timeout

	if revision != bounce_feedback_revision:
		return

	bounce_feedback_label.text = ""

#endregion
