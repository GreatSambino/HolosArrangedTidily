## This class is intended to be used as a persistent singleton (Autoload).
## When added to Project Settings -> Autoload with Global Variable enabled, can be accessed from anywhere as though it were a static member
## Should not be instantiated at runtime (other than by Godot as an autoload on game start).

extends Node


enum LevelType { Campaign, Sapling }
var level_file_extension: String = ".lvl"


## The current level type to load
var load_level_type: LevelType
## The level number within the current level type to load
var load_level_number: int

# Loaded level data
var grid_size: Vector2i
var unused_cells: Array[Vector2i]
var piece_count: int
var piece_id: Array[int]
var piece_start_position_offset: Array[Vector2]
var piece_start_rotation: Array[int]

## Loads the level file corresponding to the current load level type and number, and populates the level data variables
func load_level_data():
	var level_type_string = get_current_level_type_string()
	var level_number_string = str(load_level_number)
	var path = "res://Levels/" + level_type_string + "/" + level_number_string + level_file_extension
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Error loading level file")
		print(FileAccess.get_open_error())
		return
	print("Loading " + level_type_string + "#" + level_number_string + " level from " + path)
	grid_size = Vector2i(file.get_8(), file.get_8())
	print("Grid size: " + str(grid_size))
	var unused_cell_count = file.get_16()
	print("Unused cell count: " + str(unused_cell_count))
	unused_cells = []
	for i in range(unused_cell_count):
		var unused_cell = Vector2i(file.get_8(), file.get_8())
		unused_cells.append(unused_cell)
		print(unused_cell)
	piece_count = file.get_16()
	print("Piece count: " + str(piece_count))
	piece_id = []
	piece_start_position_offset = []
	piece_start_rotation = []
	for i in range(piece_count):
		piece_id.append(file.get_8())
		var _piece_grid_origin = Vector2i(file.get_8(), file.get_8())
		var _piece_rotation_state = file.get_8()
		piece_start_position_offset.append(Vector2(file.get_float(), file.get_float()))
		piece_start_rotation.append(file.get_8())

func get_current_level_type_string() -> String:
	return LevelType.keys()[load_level_type]
