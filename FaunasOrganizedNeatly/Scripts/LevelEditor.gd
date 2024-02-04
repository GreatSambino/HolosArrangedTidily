class_name LevelEditor
extends Node


@export var game_manager: GameManager
@export var grid: Grid
@export var piece_selector_button_container: Container
@export var piece_starting_areas: Array[Panel]
@export var level_title_line_edit: LineEdit
@export var author_line_edit: LineEdit
@export var pack_name_line_edit: LineEdit
@export var level_number_spin_box: SpinBox
@export var error_label: Label

var grid_pieces: Dictionary


func _ready():
	game_manager.piece_picked_up.connect(on_piece_picked_up)
	game_manager.piece_placed_in_grid.connect(on_piece_placed_in_grid)
	game_manager.piece_dropped_without_grid.connect(on_piece_dropped_without_grid)
	grid_pieces = {}
	grid.set_grid_size(Vector2i(12, 12))
	create_piece_selector_buttons()


func create_piece_selector_buttons():
	var button_packed_scene = load("res://Scenes/UI/piece_selector_button.tscn")
	for piece_id in PieceManager.loaded_pieces:
		var new_button: PieceSelectorButton = button_packed_scene.instantiate()
		piece_selector_button_container.add_child(new_button)
		new_button.initialize(piece_id)
		new_button.piece_selected.connect(on_piece_selected)


func _process(delta):
	if Input.is_action_just_pressed("LevelEditorMoveUp"):
		move_all_pieces(Vector2i(0, -1))
	if Input.is_action_just_pressed("LevelEditorMoveLeft"):
		move_all_pieces(Vector2i(-1, 0))
	if Input.is_action_just_pressed("LevelEditorMoveDown"):
		move_all_pieces(Vector2i(0, 1))
	if Input.is_action_just_pressed("LevelEditorMoveRight"):
		move_all_pieces(Vector2i(1, 0))


func on_save_level_button():
	error_label.text = ""
	# Make sure the puzzle has at least One Piece (The One Piece is reeeeal)
	if grid_pieces.is_empty():
		error_label.text = "Cannot save level with no pieces"
		return
	# Remove unwanted characters from the pack name (which is used as the directory for saved levels)
	var sanitized_directory_name = sanitize_directory_name(pack_name_line_edit.text)
	if sanitized_directory_name == "":
		error_label.text = "Please enter a valid pack name"
		return
	
	# Find all cells that are occupied by pieces
	var level_used_cells: Dictionary = {}
	for grid_piece in grid_pieces.keys(): # Iterate through all pieces in the level solution
		for occupied_cell in grid_piece.get_occupied_cells(): # Iterate through all the occupied cells of each piece
			level_used_cells[occupied_cell] = true # Add the cell position to the dictionary of used cells
	# Find the dimensions of the level grid that are actually used by pieces
	var first_used_cell = level_used_cells.keys()[0]
	var min_x = first_used_cell.x
	var min_y = first_used_cell.y
	var max_x = first_used_cell.x
	var max_y = first_used_cell.y
	for used_cell in level_used_cells:
		if used_cell.x < min_x:
			min_x = used_cell.x
		elif used_cell.x > max_x:
			max_x = used_cell.x
		if used_cell.y < min_y:
			min_y = used_cell.y
		elif used_cell.y > max_y:
			max_y = used_cell.y
	# Calculate the origin and size of the smallest grid that can fit all the level pieces
	var grid_xy0 = Vector2i(min_x, min_y)
	var level_grid_size = Vector2i(1 + max_x - min_x, 1 + max_y - min_y)
	print(grid_xy0)
	print(level_grid_size)
	# Adjust the used cell positions to fit in the new reduced grid size
	var adjusted_used_cells: Dictionary = {}
	for used_cell in level_used_cells:
		var adjusted_used_cell = used_cell - grid_xy0
		adjusted_used_cells[adjusted_used_cell] = true
		print("Used cell: " + str(adjusted_used_cell))
	# Find the cells that are not occupied by a piece
	var unused_cells: Dictionary = {}
	for x in range(level_grid_size.x):
		for y in range(level_grid_size.y):
			var cell = Vector2i(x, y)
			if not adjusted_used_cells.has(cell):
				unused_cells[cell] = true
				print("Unused cell: " + str(cell))
	
	# Create the save directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(LevelManager.custom_level_packs_directory_path):
		DirAccess.make_dir_absolute(LevelManager.custom_level_packs_directory_path)
	if not DirAccess.dir_exists_absolute(LevelManager.custom_level_packs_directory_path + "/" + sanitized_directory_name):
		DirAccess.make_dir_absolute(LevelManager.custom_level_packs_directory_path + "/" + sanitized_directory_name)
	
	var path: String = LevelManager.custom_level_packs_directory_path + "/" + sanitized_directory_name + "/" + str(level_number_spin_box.value) + LevelManager.level_file_extension
	var file = FileAccess.open(path, FileAccess.WRITE)
	# Save the level file version
	file.store_16(LevelManager.application_level_file_version)
	# Save level title and author
	file.store_pascal_string(level_title_line_edit.text)
	file.store_pascal_string(author_line_edit.text)
	# Save grid size to file
	file.store_8(level_grid_size.x)
	file.store_8(level_grid_size.y)
	# Save unused cells to file
	file.store_16(unused_cells.size()) # Store the count of unused cells
	for unused_cell in unused_cells:
		file.store_8(unused_cell.x)
		file.store_8(unused_cell.y)
	# Save grid pieces (ID, grid position, and rotation) and their linked ghost piece (starting position, rotation)
	file.store_16(grid_pieces.size()) # Store the count of pieces in the level
	for grid_piece: Piece in grid_pieces:
		file.store_pascal_string(grid_piece.id)
		var adjusted_grid_position = grid_piece.placed_grid_position - grid_xy0 # Find the origin position of the piece in the min-size solution grid
		file.store_8(adjusted_grid_position.x)
		file.store_8(adjusted_grid_position.y)
		file.store_8(grid_piece._current_rotation_state)
		var linked_piece_relative_position = grid_piece.linked_piece.position - grid.get_grid_center() # Find the position of the piece starting position relative to the grid center
		file.store_float(linked_piece_relative_position.x)
		file.store_float(linked_piece_relative_position.y)
		file.store_8(grid_piece.linked_piece._current_rotation_state)
	file.close()
	
	print("Level saved to " + path)
	
	OS.shell_show_in_file_manager(path)


func on_open_level_button():
	error_label.text = ""
	# Remove unwanted characters from the pack name (which is used as the directory for saved levels)
	var sanitized_directory_name = sanitize_directory_name(pack_name_line_edit.text)
	if sanitized_directory_name == "":
		error_label.text = "Please enter a valid pack name"
		return
	var path: String = OS.get_user_data_dir() + "/CustomLevelPacks/" + sanitized_directory_name + "/" + str(level_number_spin_box.value) + LevelManager.level_file_extension
	if not FileAccess.file_exists(path):
		error_label.text = "File not found"
		return
	# Clear old level
	grid_pieces.clear()
	game_manager.reset_level_state()
	# Load new level
	LevelManager.load_level_data_from_file(path)
	level_title_line_edit.text = LevelManager.level_title
	author_line_edit.text = LevelManager.author_name
	for i in range(LevelManager.piece_count):
		var grid_piece = game_manager.instantiate_piece(LevelManager.piece_id[i])
		var ghost_piece = game_manager.instantiate_piece(LevelManager.piece_id[i])
		grid_piece.set_piece_rotation(LevelManager.piece_rotation_state[i])
		game_manager.occupy_cells(grid_piece, LevelManager.piece_grid_origin[i])
		grid_piece.place_piece(LevelManager.piece_grid_origin[i], game_manager.get_piece_placed_position(grid_piece, LevelManager.piece_grid_origin[i]), true)
		grid_piece.linked_piece = ghost_piece
		grid_pieces[grid_piece] = true
		ghost_piece.set_piece_rotation(LevelManager.piece_start_rotation[i])
		ghost_piece.position = grid.get_grid_center() + LevelManager.piece_start_position_offset[i]
		ghost_piece.return_position = ghost_piece.position
		ghost_piece.set_as_ghost(grid_piece)


func on_piece_selected(piece_id: String, piece_position: Vector2):
	var grid_piece: Piece = game_manager.instantiate_piece(piece_id)
	grid_piece.global_position = piece_position
	game_manager.hold_piece(grid_piece)


func on_piece_picked_up(piece: Piece):
	if piece.is_ghost:
		piece.linked_piece.set_link_highlight(true)
	author_line_edit.release_focus()
	pack_name_line_edit.release_focus()
	level_number_spin_box.release_focus()


func on_piece_placed_in_grid(piece: Piece):
	if piece.linked_piece == null:
		# Newly created piece has been placed into the grid
		grid_pieces[piece] = true # Add it to the dictionary of pieces in the level
		var ghost_piece = game_manager.instantiate_piece(piece.id)
		ghost_piece.set_as_ghost(piece)
		ghost_piece.global_position = piece_starting_areas[0].global_position
		ghost_piece.return_position = ghost_piece.global_position
		piece.linked_piece = ghost_piece


func on_piece_dropped_without_grid(piece: Piece):
	# If the piece is a ghost make sure it is placed within a starting area
	if piece.is_ghost:
		if !is_within_starting_area(piece):
			piece.set_shape_origin_position(piece_starting_areas[0].global_position)
		piece.linked_piece.set_link_highlight(false) # turn off the highlight on the linked piece
		return
	# If the piece is not a ghost delete it and it's linked ghost
	if piece.linked_piece != null:
		grid_pieces.erase(piece)
		piece.linked_piece.queue_free()
	piece.queue_free()


func is_within_starting_area(piece: Piece) -> bool:
	var piece_xy0 = piece.get_shape_origin()
	var piece_xy1 = piece_xy0 + piece.get_shape_dimensions()
	var in_area = false
	for area in piece_starting_areas:
		var area_xy0 = area.global_position
		var area_xy1 = area.global_position + area.size
		if piece_xy0.x >= area_xy0.x and piece_xy0.y >= area_xy0.y and piece_xy1.x <= area_xy1.x and piece_xy1.y <= area_xy1.y:
			in_area = true
			break
	return in_area


func sanitize_directory_name(filename: String) -> String:
	var sanitized_str = filename.replace("\n", "") # Remove linebreaks from input filename
	var unwanted_chars_pattern = "[^\\w\\.-_]+" # Only allow letters, numbers, periods, hyphens, and underscores in the filename
	sanitized_str = sanitized_str.replace(unwanted_chars_pattern, "")
	return sanitized_str


## Moves the position of all pieces on the grid in the given direction if there is space to do so.
func move_all_pieces(direction: Vector2i):
	var check_free_cells: Array[Vector2i]
	if direction.x < 0:
		direction.x = -1
		for i in range(grid.height):
			check_free_cells.append(Vector2i(0, i))
	elif direction.x > 0:
		direction.x = 1
		for i in range(grid.height):
			check_free_cells.append(Vector2i(grid.width - 1, i))
	if direction.y < 0:
		direction.y = -1
		for i in range(grid.width):
			check_free_cells.append(Vector2i(i, 0))
	elif direction.y > 0:
		direction.y = 1
		for i in range(grid.width):
			check_free_cells.append(Vector2i(i, grid.height - 1))
	
	for cell in check_free_cells:
		if game_manager.occupied_grid_cells.has(cell):
			return
	
	for piece: Piece in game_manager.get_children():
		if piece.is_ghost:
			continue
		piece.placed_grid_position += direction
		piece.position += direction * grid.texture_size
	
	var new_occupied_cells = {}
	for cell in game_manager.occupied_grid_cells:
		new_occupied_cells[cell + direction] = true
	
	game_manager.occupied_grid_cells = new_occupied_cells
