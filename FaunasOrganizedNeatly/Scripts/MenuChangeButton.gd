extends Button


@export var deactivate_menu: Control
@export var activate_menu: Control


func _ready():
	pressed.connect(change_menu)

func change_menu():
	deactivate_menu.visible = false
	activate_menu.visible = true
