## The UI in the corner of the level editor
extends HBoxContainer


@export var tab_buttons: Array[Button]
@export var tab_container: TabContainer


func _ready():
	tab_button_pressed(0)

func tab_button_pressed(index: int):
	for i in range(tab_buttons.size()):
		if i == index:
			tab_buttons[i].set_pressed_no_signal(true)
		else:
			tab_buttons[i].set_pressed_no_signal(false)
	tab_container.current_tab = index
