extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(on_pressed)


func on_pressed():
	OS.shell_show_in_file_manager(LevelManager.custom_level_packs_directory_path)
