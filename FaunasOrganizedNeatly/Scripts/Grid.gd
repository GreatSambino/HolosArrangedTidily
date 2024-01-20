class_name Grid
extends Control


@export var bottom_margin : float

const texture_size : float = 64

var grid_cell_packed_scene: PackedScene

var width: int
var height: int


func _enter_tree():
	grid_cell_packed_scene = load("res://Assets/UI/GridCell.tscn")

# Called when the node enters the scene tree for the first time.
func set_grid_size(new_size: Vector2i, skip_cells: Dictionary = {}):
	width = new_size.x
	height = new_size.y
	
	var viewport_size : Vector2 = get_viewport_rect().size
	size = Vector2(width * texture_size, height * texture_size)
	
	var x_pos = (viewport_size.x - size.x) * 0.5
	var y_pos = (viewport_size.y - size.y - bottom_margin) * 0.5
	global_position = Vector2(x_pos, y_pos)
	
	# Create the visual representation of the grid
	for grid_cell in get_children(): # Remove old grid cells
		grid_cell.queue_free()
	for y in range(height):
		for x in range(width):
			if skip_cells.has(Vector2i(x, y)):
				continue
			var new_cell: TextureRect = grid_cell_packed_scene.instantiate()
			add_child(new_cell)
			new_cell.position = Vector2(x, y) * texture_size
			new_cell.name = "Cell(" + str(x) + "," + str(y) + ")"

func grid_to_world_position(grid_position: Vector2i) -> Vector2:
	return grid_position * texture_size + position

func get_grid_center() -> Vector2:
	return global_position + Vector2(width, height) * 0.5 * texture_size
