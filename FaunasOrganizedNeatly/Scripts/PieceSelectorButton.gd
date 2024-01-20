extends Button


@export var piece_id: int


func _ready():
	button_down.connect(on_button_down)

func on_button_down():
	var level_editor: LevelEditor = get_node("/root/RootNode/LevelEditor")
	var centre_position: Vector2 = get_node("PieceTexture").global_position
	level_editor.on_piece_selector_button_pressed(piece_id, centre_position)
