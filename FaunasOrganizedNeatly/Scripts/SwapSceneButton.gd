class_name SwapSceneButton
extends Button


@export_file("*.tscn") var new_scene_path
@export var old_scene: Node


func _ready():
	pressed.connect(on_pressed)


func on_pressed():
	var new_scene = load(new_scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	old_scene.queue_free()


func set_return_menu(new_return_menu: MenuManager.ReturnMenu):
	MenuManager.return_to_menu = new_return_menu
