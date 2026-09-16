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


var ball: BallController


func _ready() -> void:
	ball = get_node(ball_path) as BallController

	setup_sliders()
	sync_sliders_from_ball()
	update_parameter_labels()


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
			jump_status_label.text = "Jump: FULL"
		else:
			jump_status_label.text = "Jump: CHARGING"
	elif ball.is_on_floor():
		jump_status_label.text = "Jump: READY"
	else:
		jump_status_label.text = "Jump: AIRBORNE"


func update_bounce_debug() -> void:
	if ball == null:
		return

	if ball.bounce_input_timer > 0.0:
		bounce_status_label.text = "Bounce: BUFFERED (%.2f s)" % ball.bounce_input_timer
	elif ball.is_on_floor():
		bounce_status_label.text = "Bounce: READY"
	else:
		bounce_status_label.text = "Bounce: WAITING"


func update_boost_debug() -> void:
	if ball == null:
		return

	if ball.is_boosting:
		boost_status_label.text = "Boost: ACTIVE"
	elif ball.is_on_floor():
		boost_status_label.text = "Boost: READY"
	else:
		boost_status_label.text = "Boost: AIRBORNE"


func update_player_debug() -> void:
	if player == null:
		return

	spin_rpm_label.text = "RPM: %.1f" % player.get_spin_rpm()

	var tuck_percent: int = roundi(
		player.get_tuck_amount() * 100.0
	)
	tuck_label.text = "Tuck: %d%%" % tuck_percent

	airborne_label.text = (
		"Airborne: YES"
		if player.is_airborne()
		else "Airborne: NO"
	)

	dive_status_label.text = (
		"Dive: ACTIVE"
		if player.is_diving()
		else "Dive: OFF"
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
