extends Control
class_name TutorialOverlay

@onready var page_label: Label = %PageLabel
@onready var title_label: Label = %TitleLabel
@onready var body_text: RichTextLabel = %BodyLabel

@onready var back_button: Button = %BackButton
@onready var close_button: Button = %CloseButton
@onready var next_button: Button = %NextButton


var current_page: int = 0

var pages: Array[Dictionary] = [
	{
		"title": "PERFORM",
		"body": """[center][color=#6EC6FF]Core controls[/color][/center]

[table=2]
[cell][b]Move[/b][/cell][cell]W A S D[/cell]
[cell][b]Camera[/b][/cell][cell]Q / R[/cell]
[cell][b]Spin[/b][/cell][cell]Left / Right[/cell]
[cell][b]Dive[/b][/cell][cell]Up[/cell]
[cell][b]Tuck[/b][/cell][cell]Down[/cell]
[cell][b]Jump / Bounce[/b][/cell][cell]Space[/cell]
[cell][b]Boost[/b][/cell][cell]Left Shift[/cell]
[/table]

[center][color=#cccccc]Hold jump to charge.
Release to launch.[/color][/center]"""
	},
	{
		"title": "BUILD YOUR LINE",
		"body": """[center][color=#6EC6FF]Build score in the air[/color][/center]

Spins, Tuck, Dive and Air all add to your [b]score[/b].

Mix [b]direction[/b] and [b]style[/b] to create better lines.

Repeating the same trick family too much becomes less valuable.

[center][color=#cccccc]Variety = better combos.[/color][/center]"""
	},
	{
		"title": "BOUNCE & BANK",
		"body": """[center][color=#6EC6FF]Watch the landing cue[/color][/center]

[color=#FFD84D][b]Late[/b][/color]
[color=#59FF85][b]Good[/b][/color]
[color=#C77DFF][b]Perfect![/b][/color]
[color=#FF5A5A][b]Miss[/b][/color]

Better bounces increase your [b]multiplier[/b].

[center][b]Score × Multiplier = Appeal[/b][/center]

Reach the [color=#6EC6FF]Appeal target[/color]
before time runs out."""
	}
]


func _ready() -> void:
	visible = false

	body_text.bbcode_enabled = true
	body_text.fit_content = true
	body_text.scroll_active = false

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
	var page: Dictionary = pages[current_page]

	page_label.text = "%d / %d" % [
		current_page + 1,
		pages.size()
	]

	title_label.text = str(
		page["title"]
	)

	body_text.clear()
	body_text.append_text(
		str(page["body"])
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
