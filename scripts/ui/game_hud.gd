extends CanvasLayer

@export_category("References")
@export var ball: BallController
@export var player: PlayerController
@export var performance: PerformanceController

@onready var appeal_label: Label = %AppealLabel
@onready var combo_label: Label = %ComboLabel
@onready var event_feed: VBoxContainer = %EventFeed
@onready var speed_label: Label = %SpeedLabel
@onready var rpm_label: Label = %RPMLabel


func _ready() -> void:
	if performance == null:
		return

	performance.appeal_changed.connect(_on_appeal_changed)
	performance.combo_changed.connect(_on_combo_changed)
	performance.event_scored.connect(_on_event_scored)

	update_score_labels()


func _process(_delta: float) -> void:
	update_telemetry()


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


func update_score_labels() -> void:
	if performance == null:
		return

	appeal_label.text = "APPEAL  %d" % performance.total_appeal

	combo_label.text = "COMBO  %d  x%d" % [
		performance.combo_points,
		performance.combo_chain
	]


func show_event(event_name: String, points: int) -> void:
	var label: Label = Label.new()

	label.text = "%s  +%d" % [
		event_name,
		points
	]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)

	event_feed.add_child(label)

	var tween: Tween = create_tween()

	tween.tween_interval(0.8)
	tween.tween_property(
		label,
		"modulate:a",
		0.0,
		0.5
	)

	tween.tween_callback(label.queue_free)


func _on_appeal_changed(_value: int) -> void:
	update_score_labels()


func _on_combo_changed(
	_points: int,
	_chain: int
) -> void:
	update_score_labels()


func _on_event_scored(
	event_name: String,
	points: int
) -> void:
	show_event(event_name, points)
