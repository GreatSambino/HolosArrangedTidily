## Autoload used to load piece scenes and easily instantiate them by ID at runtime.
## Currently loads all pieces in the res://Pieces folder when the game first runs and keeps them all in memory for the duration of the game.
# NOTE: In a game with a large number of unique pieces or large artwork file sizes, this may be inefficient.
# For such a game this class might need to be redesigned to dynamically load/unload only Pieces that are currently needed.
# However this current implementation should be fine for most games, and there are situations such as the level editor where all pieces are loaded anyhow.

extends Node


var piece_directory_path = "res://Pieces"


## Key is piece ID string, value is PackedScene that can be instantiated from
var loaded_pieces: Dictionary


func _enter_tree():
	loaded_pieces = {}
	var piece_filenames = DirAccess.get_files_at(piece_directory_path)
	for piece_filename in piece_filenames:
		var id: String = piece_filename.get_slice(".", 0) # Get the part of the filename before the file extension
		var trimmed_filename = piece_filename.trim_suffix(".remap") # Godot adds a ".remap" suffix to the filename of resources in exported projects, but ResourceLoader.load() still takes the original filename.
		loaded_pieces[id] = load(piece_directory_path + "/" + trimmed_filename)
	print("Pieces loaded")
