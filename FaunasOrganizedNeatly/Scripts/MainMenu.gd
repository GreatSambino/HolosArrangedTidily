extends Control


@export var main_menu_buttons: Control
@export var level_select_menu: LevelSelectMenu


# Called when the node enters the scene tree for the first time.
func _ready():
	if MenuManager.first_start or MenuManager.return_to_menu == MenuManager.ReturnMenu.MAIN:
		main_menu_buttons.visible = true
		level_select_menu.visible = false
	elif MenuManager.return_to_menu == MenuManager.ReturnMenu.LEVEL_SELECT:
		main_menu_buttons.visible = false
		level_select_menu.open_number_select_menu()
