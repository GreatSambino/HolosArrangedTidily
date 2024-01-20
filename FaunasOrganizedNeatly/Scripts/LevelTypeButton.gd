extends Button


@export var level_type: LevelManager.LevelType
@export var level_type_menu: Control
@export var level_select_menu: LevelSelectMenu


func _ready():
	pressed.connect(on_pressed)

func on_pressed():
	LevelManager.load_level_type = level_type
	level_type_menu.visible = false
	level_select_menu.show_menu()
