class_name LevelSelectMenu
extends Control


@onready var level_grid: GridContainer = $LevelGrid
@onready var label_select_label: Label = $LevelSelectLabel
var level_select_button_packed_scene: PackedScene = load("res://Assets/UI/LevelSelectButton.tscn")


func show_menu():
	visible = true
	label_select_label.text = "Level Select - " + LevelManager.get_current_level_type_string()
	_create_level_select_buttons(3) # Replace the hard-coded argument once there is a way to retrieve the count of levels

func _create_level_select_buttons(button_count: int):
	for existing_button in level_grid.get_children():
		existing_button.queue_free()
	for i in range(button_count):
		var new_button: LevelSelectButton = level_select_button_packed_scene.instantiate()
		level_grid.add_child(new_button)
		new_button.set_level_number(i + 1) # Level numbers are 1-based not 0-based
