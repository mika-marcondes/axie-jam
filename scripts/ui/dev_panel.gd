extends CanvasLayer

@export var ball_path: NodePath
@export var player: PlayerController

@onready var panel: Control = %PanelContainer

@onready var speed_label: Label = %SpeedLabel

@onready var acceleration_value: Label = %AccelerationValue
@onready var acceleration_slider: HSlider = %AccelerationSlider

@onready var max_speed_value: Label = %MaxSpeedValue
@onready var max_speed_slider: HSlider = %MaxSpeedSlider

@onready var steering_value: Label = %SteeringValue
@onready var steering_slider: HSlider = %SteeringSlider

@onready var drag_value: Label = %DragValue
@onready var drag_slider: HSlider = %DragSlider

@onready var jump_velocity_value: Label = %JumpVelocityValue
@onready var jump_velocity_slider: HSlider = %JumpVelocitySlider

@onready var air_control_value: Label = %AirControlValue
@onready var air_control_slider: HSlider = %AirControlSlider

@onready var charged_jump_velocity_value: Label = %ChargedJumpVelocityValue
@onready var charged_jump_velocity_slider: HSlider = %ChargedJumpVelocitySlider

@onready var max_charge_time_value: Label = %MaxChargeTimeValue
@onready var max_charge_time_slider: HSlider = %MaxChargeTimeSlider

@onready var jump_status_label: Label = %JumpStatusLabel
@onready var jump_charge_bar: ProgressBar = %JumpChargeBar

@onready var bounce_status_label: Label = %BounceStatusLabel
@onready var bounce_retention_value: Label = %BounceRetentionValue
@onready var bounce_retention_slider: HSlider = %BounceRetentionSlider

@onready var bounce_input_window_value: Label = %BounceInputWindowValue
@onready var bounce_input_window_slider: HSlider = %BounceInputWindowSlider

@onready var boost_status_label: Label = %BoostStatusLabel

@onready var boost_acceleration_multiplier_value: Label = %BoostAccelerationMultiplierValue
@onready var boost_acceleration_multiplier_slider: HSlider = %BoostAccelerationMultiplierSlider

@onready var boost_max_speed_multiplier_value: Label = %BoostMaxSpeedMultiplierValue
@onready var boost_max_speed_multiplier_slider: HSlider = %BoostMaxSpeedMultiplierSlider

@onready var boost_release_deceleration_value: Label = %BoostReleaseDecelerationValue
@onready var boost_release_deceleration_slider: HSlider = %BoostReleaseDecelerationSlider

@onready var spin_rpm_label: Label = %SpinRPMLabel
@onready var tuck_label: Label = %TuckLabel
@onready var airborne_label: Label = %AirborneLabel
@onready var dive_status_label: Label = %DiveStatusLabel

@onready var spin_acceleration_value: Label = %SpinAccelerationValue
@onready var spin_acceleration_slider: HSlider = %SpinAccelerationSlider

@onready var max_spin_speed_value: Label = %MaxSpinSpeedValue
@onready var max_spin_speed_slider: HSlider = %MaxSpinSpeedSlider

@onready var spin_drag_value: Label = %SpinDragValue
@onready var spin_drag_slider: HSlider = %SpinDragSlider

@onready var tuck_spin_multiplier_value: Label = %TuckSpinMultiplierValue
@onready var tuck_spin_multiplier_slider: HSlider = %TuckSpinMultiplierSlider

@onready var tuck_transition_speed_value: Label = %TuckTransitionSpeedValue
@onready var tuck_transition_speed_slider: HSlider = %TuckTransitionSpeedSlider

@onready var dive_angle_value: Label = %DiveAngleValue
@onready var dive_angle_slider: HSlider = %DiveAngleSlider

@onready var dive_speed_value: Label = %DiveSpeedValue
@onready var dive_speed_slider: HSlider = %DiveSpeedSlider

@onready var landing_realign_speed_value: Label = %LandingRealignSpeedValue
@onready var landing_realign_speed_slider: HSlider = %LandingRealignSpeedSlider

@onready var landing_spin_deceleration_value: Label = %LandingSpinDecelerationValue
@onready var landing_spin_deceleration_slider: HSlider = %LandingSpinDecelerationSlider

@onready var current_jump_height_label: Label = %CurrentJumpHeightLabel
@onready var last_jump_height_label: Label = %LastJumpHeightLabel
@onready var best_jump_height_label: Label = %BestJumpHeightLabel

@onready var catch_distance_label: Label = %CatchDistanceLabel

const MODIFIED_COLOR: Color = Color("#F6C85F")

const STATUS_READY_COLOR: Color = Color("#72E06A")
const STATUS_ACTIVE_COLOR: Color = Color("#66C7FF")
const STATUS_WARNING_COLOR: Color = Color("#FFD166")
const STATUS_FULL_COLOR: Color = Color("#D996FF")
const STATUS_INACTIVE_COLOR: Color = Color("#A0A0A0")

var original_slider_values: Dictionary = {}
var slider_labels: Dictionary = {}

var ball: BallController


func _ready() -> void:
	ball = get_node(ball_path) as BallController

	setup_sliders()
	setup_trick_sliders()

	sync_sliders_from_ball()
	sync_sliders_from_player()

	update_parameter_labels()
	update_player_parameter_labels()

	setup_parameter_cues()


func _process(_delta: float) -> void:
	if ball == null:
		return

	var horizontal_speed: float = Vector2(
		ball.velocity.x, ball.velocity.z
	).length()

	speed_label.text = "Speed: %.2f m/s" % horizontal_speed

	update_jump_debug()
	update_bounce_debug()
	update_boost_debug()
	update_player_debug()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_mode"):
		panel.visible = not panel.visible


func setup_sliders() -> void:
	acceleration_slider.min_value = 1.0
	acceleration_slider.max_value = 40.0
	acceleration_slider.step = 0.5

	max_speed_slider.min_value = 1.0
	max_speed_slider.max_value = 30.0
	max_speed_slider.step = 0.5

	steering_slider.min_value = 0.1
	steering_slider.max_value = 3.0
	steering_slider.step = 0.05

	drag_slider.min_value = 0.0
	drag_slider.max_value = 20.0
	drag_slider.step = 0.5

	jump_velocity_slider.min_value = 2.0
	jump_velocity_slider.max_value = 15.0
	jump_velocity_slider.step = 0.25

	air_control_slider.min_value = 0.0
	air_control_slider.max_value = 1.0
	air_control_slider.step = 0.05
	
	charged_jump_velocity_slider.min_value = 4.0
	charged_jump_velocity_slider.max_value = 20.0
	charged_jump_velocity_slider.step = 0.25

	max_charge_time_slider.min_value = 0.1
	max_charge_time_slider.max_value = 2.0
	max_charge_time_slider.step = 0.05
	
	bounce_retention_slider.min_value = 0.0
	bounce_retention_slider.max_value = 1.0
	bounce_retention_slider.step = 0.05

	bounce_input_window_slider.min_value = 0.05
	bounce_input_window_slider.max_value = 0.5
	bounce_input_window_slider.step = 0.01
	
	boost_acceleration_multiplier_slider.min_value = 1.0
	boost_acceleration_multiplier_slider.max_value = 3.0
	boost_acceleration_multiplier_slider.step = 0.05

	boost_max_speed_multiplier_slider.min_value = 1.0
	boost_max_speed_multiplier_slider.max_value = 2.5
	boost_max_speed_multiplier_slider.step = 0.05

	boost_release_deceleration_slider.min_value = 0.0
	boost_release_deceleration_slider.max_value = 15.0
	boost_release_deceleration_slider.step = 0.25


	acceleration_slider.value_changed.connect(_on_acceleration_changed)
	max_speed_slider.value_changed.connect(_on_max_speed_changed)
	steering_slider.value_changed.connect(_on_steering_changed)
	drag_slider.value_changed.connect(_on_drag_changed)
	jump_velocity_slider.value_changed.connect(_on_jump_velocity_changed)
	air_control_slider.value_changed.connect(_on_air_control_changed)
	charged_jump_velocity_slider.value_changed.connect(_on_charged_jump_velocity_changed)
	max_charge_time_slider.value_changed.connect(_on_max_charge_time_changed)
	bounce_retention_slider.value_changed.connect(_on_bounce_retention_changed)
	bounce_input_window_slider.value_changed.connect(_on_bounce_input_window_changed)
	boost_acceleration_multiplier_slider.value_changed.connect(
		_on_boost_acceleration_multiplier_changed
	)
	boost_max_speed_multiplier_slider.value_changed.connect(
		_on_boost_max_speed_multiplier_changed
	)
	boost_release_deceleration_slider.value_changed.connect(
		_on_boost_release_deceleration_changed
	)


func setup_trick_sliders() -> void:
	spin_acceleration_slider.min_value = 0.0
	spin_acceleration_slider.max_value = 2000.0
	spin_acceleration_slider.step = 10.0

	max_spin_speed_slider.min_value = 90.0
	max_spin_speed_slider.max_value = 1440.0
	max_spin_speed_slider.step = 10.0

	spin_drag_slider.min_value = 0.0
	spin_drag_slider.max_value = 720.0
	spin_drag_slider.step = 10.0

	tuck_spin_multiplier_slider.min_value = 1.0
	tuck_spin_multiplier_slider.max_value = 3.0
	tuck_spin_multiplier_slider.step = 0.05

	tuck_transition_speed_slider.min_value = 0.5
	tuck_transition_speed_slider.max_value = 20.0
	tuck_transition_speed_slider.step = 0.25

	dive_angle_slider.min_value = 0.0
	dive_angle_slider.max_value = 180.0
	dive_angle_slider.step = 5.0

	dive_speed_slider.min_value = 0.5
	dive_speed_slider.max_value = 20.0
	dive_speed_slider.step = 0.25

	landing_realign_speed_slider.min_value = 0.5
	landing_realign_speed_slider.max_value = 20.0
	landing_realign_speed_slider.step = 0.25

	landing_spin_deceleration_slider.min_value = 0.0
	landing_spin_deceleration_slider.max_value = 3000.0
	landing_spin_deceleration_slider.step = 25.0

	spin_acceleration_slider.value_changed.connect(
		_on_spin_acceleration_changed
	)
	max_spin_speed_slider.value_changed.connect(
		_on_max_spin_speed_changed
	)
	spin_drag_slider.value_changed.connect(
		_on_spin_drag_changed
	)
	tuck_spin_multiplier_slider.value_changed.connect(
		_on_tuck_spin_multiplier_changed
	)
	tuck_transition_speed_slider.value_changed.connect(
		_on_tuck_transition_speed_changed
	)
	dive_angle_slider.value_changed.connect(
		_on_dive_angle_changed
	)
	dive_speed_slider.value_changed.connect(
		_on_dive_speed_changed
	)
	landing_realign_speed_slider.value_changed.connect(
		_on_landing_realign_speed_changed
	)
	landing_spin_deceleration_slider.value_changed.connect(
		_on_landing_spin_deceleration_changed
	)


func sync_sliders_from_player() -> void:
	if player == null:
		return

	spin_acceleration_slider.value = player.spin_acceleration
	max_spin_speed_slider.value = player.max_spin_speed
	spin_drag_slider.value = player.spin_drag
	tuck_spin_multiplier_slider.value = player.tuck_spin_multiplier
	tuck_transition_speed_slider.value = player.tuck_transition_speed
	dive_angle_slider.value = player.dive_angle
	dive_speed_slider.value = player.dive_speed
	landing_realign_speed_slider.value = player.landing_realign_speed
	landing_spin_deceleration_slider.value = player.landing_spin_deceleration


func update_player_parameter_labels() -> void:
	if player == null:
		return

	spin_acceleration_value.text = (
		"Spin Acceleration: %.0f°/s²" % player.spin_acceleration
	)
	max_spin_speed_value.text = (
		"Max Spin Speed: %.0f°/s" % player.max_spin_speed
	)
	spin_drag_value.text = (
		"Spin Drag: %.0f°/s²" % player.spin_drag
	)
	tuck_spin_multiplier_value.text = (
		"Tuck Spin Mult.: %.2fx" % player.tuck_spin_multiplier
	)
	tuck_transition_speed_value.text = (
		"Tuck Transition Speed: %.2f" % player.tuck_transition_speed
	)
	dive_angle_value.text = (
		"Dive Angle: %.0f°" % player.dive_angle
	)
	dive_speed_value.text = (
		"Dive Speed: %.2f" % player.dive_speed
	)
	landing_realign_speed_value.text = (
		"Landing Re-align Speed: %.2f" % player.landing_realign_speed
	)
	landing_spin_deceleration_value.text = (
		"Landing Spin Deceleration: %.0f°/s²"
		% player.landing_spin_deceleration
	)


func sync_sliders_from_ball() -> void:
	if ball == null:
		return

	acceleration_slider.value = ball.acceleration
	max_speed_slider.value = ball.max_speed
	steering_slider.value = ball.steering
	drag_slider.value = ball.drag
	jump_velocity_slider.value = ball.jump_velocity
	air_control_slider.value = ball.air_control
	charged_jump_velocity_slider.value = ball.charged_jump_velocity
	max_charge_time_slider.value = ball.max_charge_time
	bounce_retention_slider.value = ball.bounce_retention
	bounce_input_window_slider.value = ball.bounce_input_window
	boost_acceleration_multiplier_slider.value = ball.boost_acceleration_multiplier
	boost_max_speed_multiplier_slider.value = ball.boost_max_speed_multiplier
	boost_release_deceleration_slider.value = ball.boost_release_deceleration


func update_parameter_labels() -> void:
	if ball == null:
		return

	acceleration_value.text = "Acceleration: %.2f" % ball.acceleration
	max_speed_value.text = "Max Speed: %.2f" % ball.max_speed
	steering_value.text = "Steering: %.2f" % ball.steering
	drag_value.text = "Drag: %.2f" % ball.drag
	jump_velocity_value.text = "Jump Velocity: %.2f" % ball.jump_velocity
	air_control_value.text = "Air Control: %.2f" % ball.air_control
	charged_jump_velocity_value.text = "Charged Jump Velocity: %.2f" % ball.charged_jump_velocity
	max_charge_time_value.text = "Max Charge Time: %.2f s" % ball.max_charge_time
	bounce_retention_value.text = "Bounce Retention: %.2f" % ball.bounce_retention
	bounce_input_window_value.text = "Bounce Input Window: %.2f s" % ball.bounce_input_window
	boost_acceleration_multiplier_value.text = (
	"Boost Acceleration: %.2fx" % ball.boost_acceleration_multiplier
	)

	boost_max_speed_multiplier_value.text = (
		"Boost Max Speed: %.2fx" % ball.boost_max_speed_multiplier
	)

	boost_release_deceleration_value.text = (
		"Boost Release Deceleration: %.2f" % ball.boost_release_deceleration
	)


func update_jump_debug() -> void:
	if ball == null:
		return

	var charge_ratio: float = clampf(
		ball.jump_charge_time / maxf(ball.max_charge_time, 0.001),
		0.0,
		1.0
	)

	jump_charge_bar.value = charge_ratio * 100.0

	if ball.is_charging_jump:
		if charge_ratio >= 1.0:
			set_status(
				jump_status_label,
				"Jump: FULL",
				STATUS_FULL_COLOR
			)
		else:
			set_status(
				jump_status_label,
				"Jump: CHARGING",
				STATUS_WARNING_COLOR
			)
	elif ball.is_on_floor():
		set_status(
			jump_status_label,
			"Jump: READY",
			STATUS_READY_COLOR
		)
	else:
		set_status(
			jump_status_label,
			"Jump: AIRBORNE",
			STATUS_ACTIVE_COLOR
		)


func update_bounce_debug() -> void:
	if ball == null:
		return

	if ball.bounce_input_timer > 0.0:
		set_status(
			bounce_status_label,
			"Bounce: BUFFERED (%.2f s)" % ball.bounce_input_timer,
			STATUS_WARNING_COLOR
		)
	elif ball.is_on_floor():
		set_status(
			bounce_status_label,
			"Bounce: READY",
			STATUS_READY_COLOR
		)
	else:
		set_status(
			bounce_status_label,
			"Bounce: WAITING",
			STATUS_INACTIVE_COLOR
		)


func update_boost_debug() -> void:
	if ball == null:
		return

	if ball.is_boosting:
		set_status(
			boost_status_label,
			"Boost: ACTIVE",
			STATUS_ACTIVE_COLOR
		)
	elif ball.is_on_floor():
		set_status(
			boost_status_label,
			"Boost: READY",
			STATUS_READY_COLOR
		)
	else:
		set_status(
			boost_status_label,
			"Boost: AIRBORNE",
			STATUS_INACTIVE_COLOR
		)


func update_player_debug() -> void:
	if player == null:
		return

	var rpm: float = player.get_spin_rpm()
	var tuck_amount: float = player.get_tuck_amount()
	var tuck_percent: int = roundi(tuck_amount * 100.0)

	spin_rpm_label.text = "RPM: %.1f" % rpm
	tuck_label.text = "Tuck: %d%%" % tuck_percent
	
	current_jump_height_label.text = (
		"Current Height: %.2f m"
		% player.get_current_jump_height()
	)

	last_jump_height_label.text = (
		"Last Jump: %.2f m"
		% player.get_last_jump_height()
	)

	best_jump_height_label.text = (
		"Best Jump: %.2f m"
		% player.get_best_jump_height()
	)

	if absf(rpm) > 1.0:
		spin_rpm_label.add_theme_color_override(
			"font_color",
			STATUS_ACTIVE_COLOR
		)
	else:
		spin_rpm_label.remove_theme_color_override(
			"font_color"
		)

	if tuck_amount >= 0.99:
		tuck_label.add_theme_color_override(
			"font_color",
			STATUS_FULL_COLOR
		)
	elif tuck_amount > 0.01:
		tuck_label.add_theme_color_override(
			"font_color",
			STATUS_WARNING_COLOR
		)
	else:
		tuck_label.remove_theme_color_override(
			"font_color"
		)

	if player.is_airborne():
		set_status(
			airborne_label,
			"Airborne: YES",
			STATUS_ACTIVE_COLOR
		)
	else:
		set_status(
			airborne_label,
			"Airborne: NO",
			STATUS_INACTIVE_COLOR
		)

	if player.is_diving():
		set_status(
			dive_status_label,
			"Dive: ACTIVE",
			STATUS_ACTIVE_COLOR
		)
	else:
		set_status(
			dive_status_label,
			"Dive: OFF",
			STATUS_INACTIVE_COLOR
		)


func register_parameter_cue(
	slider: HSlider,
	label: Label
) -> void:
	original_slider_values[slider] = slider.value
	slider_labels[slider] = label

	slider.value_changed.connect(
		_on_parameter_cue_changed.bind(slider)
	)


func _on_parameter_cue_changed(
	_value: float,
	slider: HSlider
) -> void:
	update_parameter_cue(slider)


func update_parameter_cue(slider: HSlider) -> void:
	if not original_slider_values.has(slider):
		return

	var label: Label = slider_labels.get(slider) as Label
	var original_value: float = float(original_slider_values[slider])

	if label == null:
		return

	if is_equal_approx(slider.value, original_value):
		label.remove_theme_color_override("font_color")
	else:
		label.add_theme_color_override(
			"font_color",
			MODIFIED_COLOR
		)


func setup_parameter_cues() -> void:
	# Movement
	register_parameter_cue(acceleration_slider, acceleration_value)
	register_parameter_cue(max_speed_slider, max_speed_value)
	register_parameter_cue(steering_slider, steering_value)
	register_parameter_cue(drag_slider, drag_value)

	# Jump
	register_parameter_cue(jump_velocity_slider, jump_velocity_value)
	register_parameter_cue(air_control_slider, air_control_value)
	register_parameter_cue(
		charged_jump_velocity_slider,
		charged_jump_velocity_value
	)
	register_parameter_cue(
		max_charge_time_slider,
		max_charge_time_value
	)

	# Bounce
	register_parameter_cue(
		bounce_retention_slider,
		bounce_retention_value
	)
	register_parameter_cue(
		bounce_input_window_slider,
		bounce_input_window_value
	)

	# Boost
	register_parameter_cue(
		boost_acceleration_multiplier_slider,
		boost_acceleration_multiplier_value
	)
	register_parameter_cue(
		boost_max_speed_multiplier_slider,
		boost_max_speed_multiplier_value
	)
	register_parameter_cue(
		boost_release_deceleration_slider,
		boost_release_deceleration_value
	)

	# Tricks
	register_parameter_cue(
		spin_acceleration_slider,
		spin_acceleration_value
	)
	register_parameter_cue(
		max_spin_speed_slider,
		max_spin_speed_value
	)
	register_parameter_cue(
		spin_drag_slider,
		spin_drag_value
	)
	register_parameter_cue(
		tuck_spin_multiplier_slider,
		tuck_spin_multiplier_value
	)
	register_parameter_cue(
		tuck_transition_speed_slider,
		tuck_transition_speed_value
	)
	register_parameter_cue(
		dive_angle_slider,
		dive_angle_value
	)
	register_parameter_cue(
		dive_speed_slider,
		dive_speed_value
	)
	register_parameter_cue(
		landing_realign_speed_slider,
		landing_realign_speed_value
	)
	register_parameter_cue(
		landing_spin_deceleration_slider,
		landing_spin_deceleration_value
	)


func set_status(
	label: Label,
	text: String,
	color: Color
) -> void:
	label.text = text
	label.add_theme_color_override(
		"font_color",
		color
	)


func _on_acceleration_changed(value: float) -> void:
	ball.acceleration = value
	update_parameter_labels()


func _on_max_speed_changed(value: float) -> void:
	ball.max_speed = value
	update_parameter_labels()


func _on_steering_changed(value: float) -> void:
	ball.steering = value
	update_parameter_labels()


func _on_drag_changed(value: float) -> void:
	ball.drag = value
	update_parameter_labels()


func _on_jump_velocity_changed(value: float) -> void:
	ball.jump_velocity = value
	update_parameter_labels()


func _on_air_control_changed(value: float) -> void:
	ball.air_control = value
	update_parameter_labels()


func _on_charged_jump_velocity_changed(value: float) -> void:
	ball.charged_jump_velocity = value
	update_parameter_labels()


func _on_max_charge_time_changed(value: float) -> void:
	ball.max_charge_time = value
	update_parameter_labels()


func _on_bounce_retention_changed(value: float) -> void:
	ball.bounce_retention = value
	update_parameter_labels()


func _on_bounce_input_window_changed(value: float) -> void:
	ball.bounce_input_window = value
	update_parameter_labels()


func _on_boost_acceleration_multiplier_changed(value: float) -> void:
	ball.boost_acceleration_multiplier = value
	update_parameter_labels()


func _on_boost_max_speed_multiplier_changed(value: float) -> void:
	ball.boost_max_speed_multiplier = value
	update_parameter_labels()


func _on_boost_release_deceleration_changed(value: float) -> void:
	ball.boost_release_deceleration = value
	update_parameter_labels()


func _on_spin_acceleration_changed(value: float) -> void:
	player.spin_acceleration = value
	update_player_parameter_labels()


func _on_max_spin_speed_changed(value: float) -> void:
	player.max_spin_speed = value
	update_player_parameter_labels()


func _on_spin_drag_changed(value: float) -> void:
	player.spin_drag = value
	update_player_parameter_labels()


func _on_tuck_spin_multiplier_changed(value: float) -> void:
	player.tuck_spin_multiplier = value
	update_player_parameter_labels()


func _on_tuck_transition_speed_changed(value: float) -> void:
	player.tuck_transition_speed = value
	update_player_parameter_labels()


func _on_dive_angle_changed(value: float) -> void:
	player.dive_angle = value
	update_player_parameter_labels()


func _on_dive_speed_changed(value: float) -> void:
	player.dive_speed = value
	update_player_parameter_labels()


func _on_landing_realign_speed_changed(value: float) -> void:
	player.landing_realign_speed = value
	update_player_parameter_labels()


func _on_landing_spin_deceleration_changed(value: float) -> void:
	player.landing_spin_deceleration = value
	update_player_parameter_labels()
