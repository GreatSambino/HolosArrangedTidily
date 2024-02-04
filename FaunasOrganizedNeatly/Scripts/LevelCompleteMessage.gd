class_name LevelCompleteMessage
extends Control


@onready var last_level_label: Label = $PanelContainer/MarginContainer/VBoxContainer/LastLevelLabel
@onready var next_level_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/NextLevelButton
@onready var exit_to_level_select_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ExitToLevelSelectButton


func show_level_complete():
	var next_level_exists = LevelManager.next_level_exists()
	visible = true
	last_level_label.visible = !next_level_exists
	next_level_button.visible = next_level_exists
	exit_to_level_select_button.visible = !next_level_exists
