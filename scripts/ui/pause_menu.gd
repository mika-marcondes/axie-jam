extends CanvasLayer
class_name PauseMenu

@export_file("*.tscn")
var main_menu_scene_path: String = (
	"res://scenes/menu/main_menu.tscn"
)

@onready var pause_root: Control = %PauseRoot

@onready var continue_button: Button = (
	%ContinueButton
)

@onready var restart_button: Button = (
	%RestartButton
)

@onready var main_menu_button: Button = (
	%MainMenuButton
)

@onready var controls_text: RichTextLabel = (
	%ControlsText
)

@onready var pause_hint: Label = %PauseHint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	pause_root.visible = false

	continue_button.pressed.connect(
		resume_game
	)

	restart_button.pressed.connect(
		restart_game
	)

	main_menu_button.pressed.connect(
		return_to_menu
	)

	setup_controls()
	update_pause_hint()


func _unhandled_input(
	event: InputEvent
) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if get_tree().paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	get_tree().paused = true
	pause_root.visible = true

	continue_button.grab_focus()


func resume_game() -> void:
	get_tree().paused = false
	pause_root.visible = false

	get_viewport().gui_release_focus()


func restart_game() -> void:
	get_tree().paused = false

	get_tree().reload_current_scene()


func return_to_menu() -> void:
	get_tree().paused = false

	get_tree().change_scene_to_file(
		main_menu_scene_path
	)


func setup_controls() -> void:
	controls_text.bbcode_enabled = true
	controls_text.scroll_active = false

	controls_text.text = """[table=2]
[cell][b]Move[/b][/cell][cell]W A S D[/cell]
[cell][b]Camera[/b][/cell][cell]Q / R[/cell]
[cell][b]Spin[/b][/cell][cell]← / →[/cell]
[cell][b]Dive[/b][/cell][cell]↑[/cell]
[cell][b]Tuck[/b][/cell][cell]↓[/cell]
[cell][b]Jump / Bounce[/b][/cell][cell]Space[/cell]
[cell][b]Boost[/b][/cell][cell]Left Shift[/cell]
[/table]"""


func update_pause_hint() -> void:
	var key_name: String = get_action_key_name(
		&"pause",
		"Esc"
	)

	if key_name == "Escape":
		key_name = "Esc"

	pause_hint.text = (
		"Press [%s] to continue"
		% key_name
	)


func get_action_key_name(
	action: StringName,
	fallback: String
) -> String:
	var events: Array[InputEvent] = (
		InputMap.action_get_events(action)
	)

	for event: InputEvent in events:
		if event is not InputEventKey:
			continue

		var key_event: InputEventKey = (
			event as InputEventKey
		)

		if key_event.keycode != 0:
			return OS.get_keycode_string(
				key_event.keycode
			)

		if key_event.physical_keycode != 0:
			return OS.get_keycode_string(
				key_event.physical_keycode
			)

	return fallback
