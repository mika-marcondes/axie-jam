extends CanvasLayer

@export var ball_path: NodePath

@onready var panel: Control = $PanelContainer
@onready var speed_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SpeedLabel

@onready var acceleration_value: Label = $PanelContainer/MarginContainer/VBoxContainer/AccelerationValue
@onready var acceleration_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/AccelerationSlider

@onready var max_speed_value: Label = $PanelContainer/MarginContainer/VBoxContainer/MaxSpeedValue
@onready var max_speed_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/MaxSpeedSlider

@onready var steering_value: Label = $PanelContainer/MarginContainer/VBoxContainer/SteeringValue
@onready var steering_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/SteeringSlider

@onready var drag_value: Label = $PanelContainer/MarginContainer/VBoxContainer/DragValue
@onready var drag_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/DragSlider

@onready var jump_velocity_value: Label = $PanelContainer/MarginContainer/VBoxContainer/JumpVelocityValue
@onready var jump_velocity_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/JumpVelocitySlider

@onready var air_control_value: Label = $PanelContainer/MarginContainer/VBoxContainer/AirControlValue
@onready var air_control_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/AirControlSlider

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
		ball.velocity.x,
		ball.velocity.z
	).length()

	speed_label.text = "Speed: %.2f m/s" % horizontal_speed


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


	acceleration_slider.value_changed.connect(_on_acceleration_changed)
	max_speed_slider.value_changed.connect(_on_max_speed_changed)
	steering_slider.value_changed.connect(_on_steering_changed)
	drag_slider.value_changed.connect(_on_drag_changed)
	jump_velocity_slider.value_changed.connect(_on_jump_velocity_changed)
	air_control_slider.value_changed.connect(_on_air_control_changed)


func sync_sliders_from_ball() -> void:
	if ball == null:
		return

	acceleration_slider.value = ball.acceleration
	max_speed_slider.value = ball.max_speed
	steering_slider.value = ball.steering
	drag_slider.value = ball.drag
	jump_velocity_slider.value = ball.jump_velocity
	air_control_slider.value = ball.air_control


func update_parameter_labels() -> void:
	if ball == null:
		return

	acceleration_value.text = "Acceleration: %.2f" % ball.acceleration
	max_speed_value.text = "Max Speed: %.2f" % ball.max_speed
	steering_value.text = "Steering: %.2f" % ball.steering
	drag_value.text = "Drag: %.2f" % ball.drag
	jump_velocity_value.text = "Jump Velocity: %.2f" % ball.jump_velocity
	air_control_value.text = "Air Control: %.2f" % ball.air_control


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
