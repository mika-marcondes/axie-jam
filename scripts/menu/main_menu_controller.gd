extends Node3D
class_name MainMenuController

@export_file("*.tscn")
var contest_scene_path: String = (
	"res://scenes/contest/contest_greybox.tscn"
)

@onready var axie_name_label: Label = %AxieNameLabel
@onready var next_axie_button: Button = %NextAxieButton
@onready var play_button: Button = %PlayButton

@export_category("References")
@export var camera: Camera3D
@export var name_tag_anchor: Marker3D
@onready var tutorial_overlay: TutorialOverlay = (
	%TutorialOverlay
)

@export_category("Axies")
@export var axie_scenes: Array[PackedScene] = []
@export var axie_names: Array[String] = []

@onready var axie_slot: Node3D = (
	$Stage/CharacterAnchor/AxieSlot
)

var current_axie: Node3D

@onready var how_to_play_button: Button = (
	%HowToPlayButton
)

@onready var character_tag: Control = %CharacterTag

@onready var sandbox_button: Button = %SandboxButton

func _ready() -> void:
	show_selected_axie()
	axie_name_label.text = "PUFFY"

	play_button.pressed.connect(
		_on_play_pressed
	)
	
	sandbox_button.pressed.connect(
		_on_sandbox_pressed
	)

	how_to_play_button.pressed.connect(
		tutorial_overlay.open
	)

	next_axie_button.pressed.connect(
		_on_next_axie_pressed
	)

	play_button.grab_focus()


func _process(_delta: float) -> void:
	update_character_tag_position()


func show_selected_axie() -> void:
	if axie_scenes.is_empty():
		return

	if current_axie != null:
		current_axie.queue_free()

	var index: int = clampi(
		AxieSelection.selected_index,
		0,
		axie_scenes.size() - 1
	)

	current_axie = (
		axie_scenes[index].instantiate()
		as Node3D
	)

	axie_slot.add_child(
		current_axie
	)

	if index < axie_names.size():
		axie_name_label.text = (
			axie_names[index].to_upper()
		)


func _on_next_axie_pressed() -> void:
	if axie_scenes.is_empty():
		return

	AxieSelection.selected_index = (
		AxieSelection.selected_index + 1
	) % axie_scenes.size()

	show_selected_axie()


func update_character_tag_position() -> void:
	if camera == null or name_tag_anchor == null:
		return

	if camera.is_position_behind(
		name_tag_anchor.global_position
	):
		character_tag.visible = false
		return

	character_tag.visible = true

	var screen_position: Vector2 = (
		camera.unproject_position(
			name_tag_anchor.global_position
		)
	)

	character_tag.position = (
		screen_position
		- character_tag.size * 0.5
	)


func _on_play_pressed() -> void:
	ContestController.requested_mode = (
		ContestController.RunMode.STANDARD
	)

	get_tree().change_scene_to_file(
		contest_scene_path
	)


func _on_sandbox_pressed() -> void:
	ContestController.requested_mode = (
		ContestController.RunMode.SANDBOX
	)

	get_tree().change_scene_to_file(
		contest_scene_path
	)
