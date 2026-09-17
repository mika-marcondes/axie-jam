extends Resource
class_name ScoringConfig

@export_category("Spin")
@export var spin_base_points: int = 50
@export var spin_rotation_multiplier: float = 1.0

@export_category("Air")
@export var minimum_air_height: float = 0.4

@export var small_air_height: float = 1.0
@export var small_air_points: int = 5

@export var medium_air_height: float = 2.0
@export var medium_air_points: int = 25

@export var big_air_height: float = 3.5
@export var big_air_points: int = 60

@export var huge_air_points: int = 100

@export_category("Posture")
@export var dive_points: int = 30

@export_category("Bounce")
@export var bounce_points: int = 20
@export var perfect_bounce_points: int = 75

@export_category("Combo")
@export var combo_multiplier_step: float = 0.25
@export var max_combo_multiplier: float = 5.0
@export_range(0.0, 1.0, 0.05) var repetition_penalty: float = 0.75

@export_category("Landing")
@export var clean_landing_multiplier: float = 1.0
@export var sketchy_landing_multiplier: float = 0.5
