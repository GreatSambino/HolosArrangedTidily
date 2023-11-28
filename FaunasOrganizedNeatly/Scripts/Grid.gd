class_name Grid
extends TextureRect


const texture_size : float = 64;

var width: int
var height: int


func _ready():
	set_grid_size(8, 6)

# Called when the node enters the scene tree for the first time.
func set_grid_size(new_width: int, new_height: int):
	width = new_width
	height = new_height
	
	var viewport_size : Vector2 = get_viewport_rect().size
	size = Vector2(new_width * texture_size, new_height * texture_size)
	
	var x_pos = (viewport_size.x - size.x) * 0.5
	var y_pos = (viewport_size.y - size.y) * 0.5
	global_position = Vector2(x_pos, y_pos)

func grid_to_world_position(grid_position: Vector2i) -> Vector2:
	return grid_position * texture_size + position
