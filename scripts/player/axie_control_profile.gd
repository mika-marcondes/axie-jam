extends Resource
class_name AxieControlProfile

@export_category("Identity")
@export var display_name: String = ""
@export var trait_summary: String = "BALANCED"

@export_category("Ball")
@export var acceleration_multiplier: float = 1.0
@export var max_speed_multiplier: float = 1.0
@export var steering_multiplier: float = 1.0
@export var jump_multiplier: float = 1.0
@export var air_control_multiplier: float = 1.0

@export_category("Tricks")
@export var spin_acceleration_multiplier: float = 1.0
@export var max_spin_speed_multiplier: float = 1.0
