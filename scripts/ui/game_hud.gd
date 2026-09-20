extends CanvasLayer

@export_category("References")
@export var ball: BallController
@export var player: PlayerController
@export var performance: PerformanceController

@export_category("Display")
@export var bank_display_time: float = 1.5

@export_category("Colors")
@export var active_combo_color: Color = Color("#F6C85F")
@export var banked_score_color: Color = Color("#4AB7FF")
@export var appeal_color: Color = Color("#4AB7FF")
@export var trick_line_color: Color = Color("#FFFFFF")

@onready var appeal_label: Label = %AppealLabel
@onready var combo_score_label: Label = %ComboLabel
@onready var trick_line_label: Label = %TrickLineLabel
@onready var speed_label: Label = %SpeedLabel
@onready var rpm_label: Label = %RPMLabel

var trick_segments: Array[String] = []
var current_spin_rotations: int = 0

var showing_bank_result: bool = false
var display_revision: int = 0


#region Lifecycle

func _ready() -> void:
	if performance == null:
		return

	performance.appeal_changed.connect(_on_appeal_changed)
	performance.combo_changed.connect(_on_combo_changed)
	performance.event_scored.connect(_on_event_scored)
	performance.combo_banked.connect(_on_combo_banked)

	combo_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trick_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trick_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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
			ball.velocity.x, ball.velocity.z
		).length()

		speed_label.text = "SPEED  %.1f" % speed

	if player != null:
		rpm_label.text = "RPM  %.0f" % absf(
			player.get_spin_rpm()
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

	if showing_bank_result:
		return

	if performance.combo_points > 0:
		show_active_combo(
			performance.combo_points,
			performance.combo_chain
		)
	else:
		combo_score_label.text = ""


func show_active_combo(
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


func show_banked_score(points: int) -> void:
	combo_score_label.text = "+%d APPEAL" % points

	combo_score_label.add_theme_color_override(
		"font_color",
		banked_score_color
	)


func prepare_for_new_combo() -> void:
	if not showing_bank_result:
		return

	showing_bank_result = false
	display_revision += 1
	clear_trick_line()

#endregion


#region Trick Line

func add_spin_rotation() -> void:
	current_spin_rotations += 1
	update_trick_line()


func finish_spin_segment() -> void:
	if current_spin_rotations <= 0:
		return

	trick_segments.append(
		"%d Spin" % (current_spin_rotations * 360)
	)

	current_spin_rotations = 0


func update_trick_line() -> void:
	var display_segments: Array[String] = trick_segments.duplicate()

	if current_spin_rotations > 0:
		display_segments.append(
			"%d Spin" % (current_spin_rotations * 360)
		)

	trick_line_label.text = " + ".join(display_segments)


func clear_trick_line() -> void:
	trick_segments.clear()
	current_spin_rotations = 0
	trick_line_label.text = ""


func clear_combo_display() -> void:
	clear_trick_line()
	combo_score_label.text = ""

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

	prepare_for_new_combo()
	show_active_combo(points, chain)


func _on_event_scored(
	event_name: String,
	_points: int
) -> void:
	if event_name == "Bounce":
		return

	prepare_for_new_combo()

	if event_name == "360 Spin":
		add_spin_rotation()
	else:
		finish_spin_segment()
		trick_segments.append(event_name)

	update_trick_line()


func _on_combo_banked(
	points: int,
	_multiplier: float
) -> void:
	finish_spin_segment()
	update_trick_line()

	showing_bank_result = true
	display_revision += 1

	var bank_revision: int = display_revision

	show_banked_score(points)

	await get_tree().create_timer(bank_display_time).timeout

	if bank_revision != display_revision:
		return

	showing_bank_result = false
	clear_combo_display()

#endregion
