extends Node

const application_progress_file_version: int = 0
@onready var progress_file_path = OS.get_user_data_dir() + "/progress.dat"

## Keys are the level pack name with a prefix to distinguish Campaign and Custom level packs.
## Values are Dictionaries whos keys are the level numbers of completed levels.
var level_completed: Dictionary
## Keys are the piece ID of discovered pieces. Value is unused.
var discovered_pieces: Dictionary


func _ready():
	level_completed = {}
	discovered_pieces = {}
	load_progress_file()


func save_progress_file():
	var file = FileAccess.open(progress_file_path, FileAccess.WRITE)
	file.store_16(application_progress_file_version)
	# Store completed levels
	file.store_16(level_completed.size())
	for pack_name in level_completed:
		var level_number_dictionary: Dictionary = level_completed[pack_name]
		file.store_pascal_string(pack_name)
		file.store_8(level_number_dictionary.size())
		for level_number in level_number_dictionary:
			file.store_8(level_number)
	# Store discovered pieces
	file.store_16(discovered_pieces.size())
	for piece_id in discovered_pieces:
		file.store_pascal_string(piece_id)
	
	file.close()
	print("Progress saved to " + progress_file_path)


func load_progress_file():
	level_completed = {}
	if not FileAccess.file_exists(progress_file_path):
		print("No progress file exists")
		return
	var file = FileAccess.open(progress_file_path, FileAccess.READ)
	if file == null:
		print("Error loading progress file")
		print(FileAccess.get_open_error())
		return
	var file_version = file.get_16()
	# Load completed levels
	var level_pack_count = file.get_16()
	for pack_index in level_pack_count:
		var pack_name = file.get_pascal_string()
		var pack_completed_levels_count = file.get_8()
		var pack_dictionary = {}
		for level_number_index in pack_completed_levels_count:
			var level_number = file.get_8()
			pack_dictionary[level_number] = true
		level_completed[pack_name] = pack_dictionary
	# Load discovered pieces
	var discovered_piece_count = file.get_16()
	for discovered_piece_index in discovered_piece_count:
		var discovered_piece_id = file.get_pascal_string()
		discovered_pieces[discovered_piece_id] = true
	
	file.close()
	print("Loaded progress from " + progress_file_path)


func set_current_level_complete():
	set_level_complete(LevelManager.load_level_pack_type, LevelManager.load_level_pack_name, LevelManager.load_level_number)


func set_level_complete(pack_type: LevelManager.LevelPackType, pack_name: String, level_number: int):
	var pack_string = _get_pack_string(pack_type, pack_name)
	if not level_completed.has(pack_string):
		level_completed[pack_string] = {}
		print("Created progress for pack " + pack_string)
	level_completed[pack_string][level_number] = true
	print("Set " + pack_string + " level number " + str(level_number) + " as complete")
	save_progress_file()


## Gets the number of levels within a pack that have been completed
func get_pack_completion_count(pack_type: LevelManager.LevelPackType, pack_name: String) -> int:
	var pack_string = _get_pack_string(pack_type, pack_name)
	if not level_completed.has(pack_string):
		return 0
	var pack_dictionary: Dictionary = level_completed[pack_string]
	return pack_dictionary.size()


## Get the dictionary who's keys are the level numbers of levels within the pack that the player has already completed.
## Do not alter the returned Dictionary, use ProgressManager.set_... functions instead. Returns an empty dictionary if no progress exists.
func get_pack_completion_dictionary(pack_type: LevelManager.LevelPackType, pack_name: String) -> Dictionary:
	var pack_string = _get_pack_string(pack_type, pack_name)
	return level_completed.get(pack_string, {})


func set_piece_discovered(piece_id: String):
	discovered_pieces[piece_id] = true
	save_progress_file()


func get_piece_discovered(piece_id: String):
	return discovered_pieces.has(piece_id)


func _get_pack_string(pack_type: LevelManager.LevelPackType, pack_name: String) -> String:
	return str(pack_type) + pack_name
