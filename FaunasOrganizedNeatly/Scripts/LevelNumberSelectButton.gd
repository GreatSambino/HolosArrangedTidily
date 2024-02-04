class_name LevelNumberSelectButton
extends Button


var _level_number: int


func initialize(level_number: int, complete: bool):
	_level_number = level_number
	# Set visual appearance of button
	var level_number_label: Label = $VBoxContainer/LevelNumberLabel
	var completion_label: Label = $VBoxContainer/CompletionLabel
	var separator: HSeparator = $VBoxContainer/HSeparator
	level_number_label.text = str(level_number)
	completion_label.visible = complete
	separator.visible = complete
	pressed.connect(on_pressed)


func on_pressed():
	MenuManager.return_to_menu = MenuManager.ReturnMenu.LEVEL_SELECT
	LevelManager.load_level_number = _level_number
	LevelManager.load_level_data()
	var gameplay_scene = load("res://Scenes/gameplay_scene.tscn").instantiate()
	get_tree().root.add_child(gameplay_scene)
	get_node("/root/MainMenu").queue_free()
