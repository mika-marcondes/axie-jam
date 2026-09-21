extends Node
class_name ContestController

enum RunMode {
	STANDARD,
	SANDBOX
}

static var requested_mode: RunMode = RunMode.STANDARD

signal progress_changed(
	current_appeal: int,
	target_appeal: int
)

signal time_changed(
	time_remaining: float,
	is_overtime: bool
)

signal spotlight_changed(
	spotlight: int,
	target_appeal: int
)

signal spotlight_cleared(
	spotlight: int
)

signal run_failed(
	final_appeal: int,
	spotlights_cleared: int
)


@export_category("References")
@export var performance: PerformanceController
@export var dev_ui: CanvasLayer

@export_category("Timing")
@export var spotlight_duration: float = 60.0

@export_category("Appeal Progression")
@export var initial_target: int = 500
@export var target_increment: int = 1000
@export var increment_growth: int = 500


var current_target: int = 0
var current_increment: int = 0

var current_spotlight: int = 1
var spotlights_cleared: int = 0

var time_remaining: float = 0.0

var is_running: bool = false
var is_overtime: bool = false

var run_mode: RunMode = RunMode.STANDARD

#region Lifecycle

func _ready() -> void:
	if performance == null:
		push_error(
			"ContestController requires a PerformanceController."
		)
		return

	performance.appeal_changed.connect(
		_on_appeal_changed
	)

	run_mode = requested_mode

	if run_mode == RunMode.SANDBOX:
		start_sandbox()
	else:
		start_run()


func _process(delta: float) -> void:
	if not is_running:
		return

	if is_overtime:
		return

	time_remaining = maxf(
		time_remaining - delta,
		0.0
	)

	time_changed.emit(
		time_remaining,
		false
	)

	if time_remaining <= 0.0:
		handle_time_expired()

#endregion


#region Run

func start_run() -> void:
	current_target = initial_target
	current_increment = target_increment

	current_spotlight = 1
	spotlights_cleared = 0

	is_running = true
	is_overtime = false

	if dev_ui != null:
		dev_ui.visible = false

	reset_timer()
	emit_contest_state()


func start_sandbox() -> void:
	is_running = false
	is_overtime = false
	time_remaining = 0.0

	if dev_ui != null:
		dev_ui.visible = true


func reset_timer() -> void:
	time_remaining = spotlight_duration

	time_changed.emit(
		time_remaining,
		false
	)


func handle_time_expired() -> void:
	if performance.total_appeal >= current_target:
		clear_spotlight()
		return

	if performance.combo_points > 0:
		start_overtime()
		return

	fail_run()


func start_overtime() -> void:
	is_overtime = true
	time_remaining = 0.0

	time_changed.emit(
		0.0,
		true
	)


func clear_spotlight() -> void:
	if not is_running:
		return

	spotlights_cleared += 1

	spotlight_cleared.emit(
		current_spotlight
	)

	current_target += current_increment
	current_increment += increment_growth

	current_spotlight += 1
	is_overtime = false

	reset_timer()

	spotlight_changed.emit(
		current_spotlight,
		current_target
	)

	progress_changed.emit(
		performance.total_appeal,
		current_target
	)


func fail_run() -> void:
	if not is_running:
		return

	is_running = false
	is_overtime = false

	run_failed.emit(
		performance.total_appeal,
		spotlights_cleared
	)


func is_sandbox() -> bool:
	return run_mode == RunMode.SANDBOX

#endregion


#region Performance Events

func _on_appeal_changed(
	value: int
) -> void:
	progress_changed.emit(
		value,
		current_target
	)

	if not is_running:
		return

	if value >= current_target:
		clear_spotlight()
		return

	if is_overtime:
		fail_run()

#endregion


#region State

func emit_contest_state() -> void:
	progress_changed.emit(
		performance.total_appeal,
		current_target
	)

	spotlight_changed.emit(
		current_spotlight,
		current_target
	)

	time_changed.emit(
		time_remaining,
		is_overtime
	)

#endregion
