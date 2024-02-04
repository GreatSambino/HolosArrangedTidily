## This class is intended to be used as a persistent singleton (Autoload).
## When added to Project Settings -> Autoload with Global Variable enabled, can be accessed from anywhere as though it were a static member
## Should not be instantiated at runtime (other than by Godot as an autoload on game start).

extends Node


enum LevelPackType {CAMPAIGN, CUSTOM}
const application_level_file_version: int = 0
var level_file_extension: String = ".lvl"
var included_level_packs_directory_path = "res://Levels"
@onready var custom_level_packs_directory_path = OS.get_user_data_dir() + "/CustomLevelPacks"


## Whether to load an included level pack in resources, or from a custom level pack in app data
var load_level_pack_type: LevelPackType
## The name of the level pack to load from
var load_level_pack_name: String
## The level number within the current level pack to load
var load_level_number: int

# Loaded level data
var grid_size: Vector2i
var unused_cells: Array[Vector2i]
var piece_count: int
var piece_id: Array[String]
var piece_grid_origin: Array[Vector2i]
var piece_rotation_state: Array[Piece.RotationStates]
var piece_start_position_offset: Array[Vector2]
var piece_start_rotation: Array[int]
var level_title: String
var author_name: String

# Player progress (consider moving this to it's own Autoload script)
var level_completed: Dictionary


func _ready():
	# Create the Custom Level Pack directory
	if not DirAccess.dir_exists_absolute(custom_level_packs_directory_path):
		DirAccess.make_dir_absolute(custom_level_packs_directory_path)
	# Write the custom level pack readme file
	var read_me_file_path: String = LevelManager.custom_level_packs_directory_path + "/readme.txt"
	var read_me_file = FileAccess.open(read_me_file_path, FileAccess.WRITE)
	read_me_file.store_string("Level Pack folders placed here will appear as playable Custom Level Packs in-game.\n\nLevel Packs created in the level editor are also stored here.")


func load_level_data():
	var path: String = get_level_file_path(load_level_pack_type, load_level_pack_name, load_level_number)
	load_level_data_from_file(path)


## Loads the level file corresponding to the current load level type and number, and populates the level data variables
func load_level_data_from_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Error loading level file")
		print(FileAccess.get_open_error())
		return
	print("Loading level from " + path)
	var level_file_version = file.get_16()
	print("Level file version: " + str(level_file_version))
	level_title = file.get_pascal_string()
	print("Level title: " + level_title)
	author_name = file.get_pascal_string()
	print("Level author: " + author_name)
	grid_size = Vector2i(file.get_8(), file.get_8())
	print("Grid size: " + str(grid_size))
	var unused_cell_count = file.get_16()
	print("Unused cell count: " + str(unused_cell_count))
	unused_cells = []
	for i in range(unused_cell_count):
		var unused_cell = Vector2i(file.get_8(), file.get_8())
		unused_cells.append(unused_cell)
	piece_count = file.get_16()
	print("Piece count: " + str(piece_count))
	piece_id = []
	piece_grid_origin = []
	piece_rotation_state = []
	piece_start_position_offset = []
	piece_start_rotation = []
	for i in range(piece_count):
		piece_id.append(file.get_pascal_string())
		piece_grid_origin.append(Vector2i(file.get_8(), file.get_8()))
		piece_rotation_state.append(file.get_8())
		piece_start_position_offset.append(Vector2(file.get_float(), file.get_float()))
		piece_start_rotation.append(file.get_8())
	file.close()


func get_pack_type_path(pack_type: LevelPackType):
	if pack_type == LevelPackType.CAMPAIGN:
		return included_level_packs_directory_path
	else:
		return custom_level_packs_directory_path


func get_level_file_path(pack_type: LevelPackType, pack_name: String, level_number: int) -> String:
	var path: String = get_pack_type_path(pack_type)
	path = path + "/" + pack_name + "/" + str(level_number) + LevelManager.level_file_extension
	return path


## Returns whether the level following the currently loaded level exists
func next_level_exists() -> bool:
	var next_level_path: String = get_level_file_path(load_level_pack_type, load_level_pack_name, load_level_number + 1)
	return FileAccess.file_exists(next_level_path)
