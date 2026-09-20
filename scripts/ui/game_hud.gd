extends CanvasLayer

@export_category("References")
@export var ball: BallController
@export var player: PlayerController
@export var performance: PerformanceController
@export var contest: ContestController

@onready var time_label: Label = %TimeLabel

@export_category("Spotlight Feedback")
@export var spotlight_feedback_time: float = 1.2
@export var spotlight_feedback_color: Color = Color("#5FD4F5")

@onready var spotlight_feedback_label: Label = (
	%SpotlightFeedbackLabel
)

@export_category("Display")
@export var bank_display_time: float = 1.5

@export_category("Colors")
@export var active_combo_color: Color = Color("#F6C85F")
@export var banked_score_color: Color = Color("#4AB7FF")
@export var appeal_color: Color = Color("#4AB7FF")
@export var trick_line_color: Color = Color("#FFFFFF")

@export_category("Bounce Feedback")
@export var bounce_feedback_display_time: float = 0.65

@onready var bounce_feedback_label: Label = (
	%BounceFeedbackLabel
)

@onready var appeal_label: Label = %AppealLabel
@onready var combo_score_label: Label = %ComboLabel
@onready var trick_line_label: Label = %TrickLineLabel
@onready var speed_label: Label = %SpeedLabel
@onready var rpm_label: Label = %RPMLabel

var trick_segments: Array[String] = []

var current_spin_family: String = ""
var current_spin_rotations: int = 0

var showing_bank_result: bool = false
var display_revision: int = 0
var bounce_feedback_revision: int = 0

var spotlight_feedback_revision: int = 0

#region Lifecycle

func _ready() -> void:
	if contest != null:
		contest.progress_changed.connect(
			_on_contest_progress_changed
		)

		contest.time_changed.connect(
			_on_contest_time_changed
		)

		contest.spotlight_cleared.connect(
			_on_spotlight_cleared
		)
	
	if performance == null:
		return

	if ball != null:
		if not ball.bounce_feedback.is_connected(
			_on_bounce_feedback
		):
			ball.bounce_feedback.connect(
				_on_bounce_feedback
			)

	bounce_feedback_label.text = ""

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

#endregion


#region Telemetry

func _process(_delta: float) -> void:
	update_telemetry()


func update_telemetry() -> void:
	if ball != null:
		var speed: float = Vector2(
			ball.velocity.x,
			ball.velocity.z
		).length()

		speed_label.text = (
			"SPEED  %.1f"
			% speed
		)

	if player != null:
		var rpm: float = absf(
			player.get_spin_rpm()
		)
		var air_height: float = (
			player.get_current_jump_height()
		)

		rpm_label.text = (
			"RPM  %.0f    AIR  %.1f m"
			% [
				rpm,
				air_height
			]
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
			performance.combo_points
		)
	else:
		combo_score_label.text = ""


func update_combo_score(
	points: int
) -> void:
	combo_score_label.text = (
		"%d × %.1f"
		% [
			points,
			performance.get_combo_multiplier()
		]
	)

	combo_score_label.add_theme_color_override(
		"font_color",
		active_combo_color
	)


func cancel_bank_display_for_new_combo() -> void:
	if not showing_bank_result:
		return

	showing_bank_result = false
	display_revision += 1

	clear_trick_line()

	combo_score_label.text = ""
	trick_line_label.text = ""

#endregion


#region Trick Line

func is_spin_event(
	event_name: String
) -> bool:
	return (
		event_name == "L Spin"
		or event_name == "R Spin"
		or event_name == "L Tuck Spin"
		or event_name == "R Tuck Spin"
	)


func add_spin_event(
	event_name: String
) -> void:
	if (
		current_spin_rotations > 0
		and current_spin_family != event_name
	):
		finish_spin_segment()

	if current_spin_rotations <= 0:
		current_spin_family = event_name

	current_spin_rotations += 1
	update_trick_line()


func finish_spin_segment() -> void:
	if current_spin_rotations <= 0:
		return

	trick_segments.append(
		build_current_spin_segment()
	)

	current_spin_family = ""
	current_spin_rotations = 0


func build_current_spin_segment() -> String:
	if current_spin_rotations <= 0:
		return ""

	var degrees: int = (
		current_spin_rotations
		* 360
	)

	if current_spin_family == "L Tuck Spin":
		return "L %d Tuck Spin" % degrees

	if current_spin_family == "R Tuck Spin":
		return "R %d Tuck Spin" % degrees

	if current_spin_family == "L Spin":
		return "L %d Spin" % degrees

	if current_spin_family == "R Spin":
		return "R %d Spin" % degrees

	return "%d Spin" % degrees


func add_trick_event(
	event_name: String
) -> void:
	finish_spin_segment()

	trick_segments.append(
		event_name
	)

	update_trick_line()


func is_air_event(
	event_name: String
) -> bool:
	return (
		event_name.begins_with("Small Air ")
		or event_name.begins_with("Air ")
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


func clear_trick_line() -> void:
	trick_segments.clear()
	current_spin_family = ""
	current_spin_rotations = 0


func clear_combo_display() -> void:
	clear_trick_line()

	combo_score_label.text = ""
	trick_line_label.text = ""

#endregion


#region Performance Signals

func _on_appeal_changed(
	value: int
) -> void:
	if contest != null:
		_on_contest_progress_changed(
			value,
			contest.current_target
		)
		return

	appeal_label.text = "APPEAL  %d" % value


func _on_combo_changed(
	points: int,
	_chain: int
) -> void:
	if points <= 0:
		return

	if showing_bank_result:
		cancel_bank_display_for_new_combo()

	update_combo_score(
		points
	)


func _on_event_scored(
	event_name: String,
	_points: int
) -> void:
	if showing_bank_result:
		cancel_bank_display_for_new_combo()

	if event_name == "Bounce":
		return

	if is_spin_event(event_name):
		add_spin_event(
			event_name
		)
		return

	if is_air_event(event_name):
		finish_spin_segment()
		update_trick_line()
		return

	add_trick_event(
		event_name
	)


func _on_combo_banked(
	points: int,
	_multiplier: float
) -> void:
	finish_spin_segment()
	update_trick_line()

	showing_bank_result = true
	display_revision += 1

	var bank_revision: int = (
		display_revision
	)

	combo_score_label.text = (
		"+%d APPEAL"
		% points
	)
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

	bounce_feedback_label.text = (
		feedback_text
	)

	bounce_feedback_label.add_theme_color_override(
		"font_color",
		ball.get_bounce_grade_color(
			grade
		)
	)

	bounce_feedback_revision += 1

	var revision: int = (
		bounce_feedback_revision
	)

	await get_tree().create_timer(
		bounce_feedback_display_time
	).timeout

	if revision != bounce_feedback_revision:
		return

	bounce_feedback_label.text = ""


func _on_contest_progress_changed(
	current_appeal: int,
	target_appeal: int
) -> void:
	appeal_label.text = "APPEAL  %d / %d" % [
		current_appeal,
		target_appeal
	]


func _on_contest_time_changed(
	remaining: float,
	overtime: bool
) -> void:
	var total_seconds: int = ceili(
		remaining
	)

	var minutes: int = (
		total_seconds / 60
	)

	var seconds: int = (
		total_seconds % 60
	)

	time_label.text = "TIME  %d:%02d" % [
		minutes,
		seconds
	]

	if overtime:
		time_label.text = "TIME  0:00  OVERTIME"


func _on_spotlight_cleared(
	spotlight: int
) -> void:
	spotlight_feedback_revision += 1

	var revision: int = (
		spotlight_feedback_revision
	)

	spotlight_feedback_label.text = (
		"SPOTLIGHT %d CLEARED!"
		% spotlight
	)

	spotlight_feedback_label.add_theme_color_override(
		"font_color",
		spotlight_feedback_color
	)

	spotlight_feedback_label.modulate.a = 1.0
	spotlight_feedback_label.visible = true

	await get_tree().create_timer(
		spotlight_feedback_time
	).timeout

	if revision != spotlight_feedback_revision:
		return

	var tween: Tween = create_tween()

	tween.tween_property(
		spotlight_feedback_label,
		"modulate:a",
		0.0,
		0.25
	)

	await tween.finished

	if revision != spotlight_feedback_revision:
		return

	spotlight_feedback_label.visible = false

#endregion
