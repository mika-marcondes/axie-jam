extends Control
class_name TutorialOverlay

@onready var page_label: Label = %PageLabel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel

@onready var back_button: Button = %BackButton
@onready var close_button: Button = %CloseButton
@onready var next_button: Button = %NextButton


var current_page: int = 0

var pages: Array[Dictionary] = [
	{
		"title": "PERFORM",
		"body": """MOVE
WASD / Left Stick

CAMERA
Q / E / Right Stick

JUMP / BOUNCE
Hold Space / Cross to charge

SPIN
Arrow Keys

TUCK
C

DIVE
X

BOOST
Shift / R2"""
	},
	{
		"title": "BUILD YOUR LINE",
		"body": """Spins, Tuck, Dive and Air
build your combo score.

Mix directions and styles.

Repeating the same trick family
is worth less.

Tricks build SCORE."""
	},
	{
		"title": "BOUNCE & BANK",
		"body": """Watch for the blue glow as you land.

LATE       Yellow
GOOD       Green
PERFECT!   Purple
MISS       Red

Better bounces build your MULTIPLIER.

Land normally to bank:

SCORE × MULT → APPEAL

Reach the Appeal target
before time runs out."""
	}
]


func _ready() -> void:
	visible = false

	back_button.pressed.connect(
		_on_back_pressed
	)

	close_button.pressed.connect(
		close
	)

	next_button.pressed.connect(
		_on_next_pressed
	)

	update_page()


func open() -> void:
	current_page = 0
	visible = true

	update_page()

	next_button.grab_focus()


func close() -> void:
	visible = false


func update_page() -> void:
	var page: Dictionary = pages[
		current_page
	]

	page_label.text = "%d / %d" % [
		current_page + 1,
		pages.size()
	]

	title_label.text = str(
		page["title"]
	)

	body_label.text = str(
		page["body"]
	)

	back_button.disabled = (
		current_page <= 0
	)

	if current_page >= pages.size() - 1:
		next_button.text = "DONE"
	else:
		next_button.text = "NEXT"


func _on_back_pressed() -> void:
	current_page = maxi(
		current_page - 1,
		0
	)

	update_page()


func _on_next_pressed() -> void:
	if current_page >= pages.size() - 1:
		close()
		return

	current_page += 1
	update_page()
