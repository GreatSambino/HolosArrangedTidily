class_name LevelSelectButton
extends Button


var level_number: int


func _ready():
	pressed.connect(on_pressed)

func set_level_number(new_number: int):
	level_number = new_number
	text = str(new_number)

func on_pressed():
	LevelManager.load_level_number = level_number
	LevelManager.load_level_data()
	var gameplay_scene = load("res://GameplayScene.tscn").instantiate()
	get_tree().root.add_child(gameplay_scene)
	get_node("/root/MainMenu").queue_free()
