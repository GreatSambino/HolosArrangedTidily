class_name LevelEditor
extends Node


@export var game_manager: GameManager
@export var piece_manager: PieceManager
@export var grid: Grid
@export var piece_starting_areas: Array[Panel]
@export var filename_text_edit: TextEdit
@export var save_level_output_label: Label

var grid_pieces: Dictionary

enum States { EDIT_PIECES, EDIT_BLOCKERS }

var current_state: States


func _ready():
	current_state = States.EDIT_PIECES
	game_manager.piece_picked_up.connect(on_piece_picked_up)
	game_manager.piece_placed_in_grid.connect(on_piece_placed_in_grid)
	game_manager.piece_dropped_without_grid.connect(on_piece_dropped_without_grid)
	grid_pieces = {}
	grid.set_grid_size(Vector2i(10, 10))

func on_save_level_button():
	# Make sure the puzzle has at least One Piece (The One Piece is reeeeal)
	if grid_pieces.is_empty():
		save_level_output_label.text = "Cannot save level with no pieces"
		return
	# Remove unwanted characters from the filename and make sure the resulting filename is more than zero length
	var sanitized_filename = sanitize_filename(filename_text_edit.text)
	if sanitized_filename == "":
		save_level_output_label.text = "Please enter a valid filename"
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
	
	var path: String = OS.get_user_data_dir() + "/" + sanitized_filename + LevelManager.level_file_extension
	var file = FileAccess.open(path, FileAccess.WRITE)
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
		file.store_8(grid_piece.id)
		var adjusted_grid_position = grid_piece.placed_grid_position - grid_xy0 # Find the origin position of the piece in the min-size solution grid
		file.store_8(adjusted_grid_position.x)
		file.store_8(adjusted_grid_position.y)
		file.store_8(grid_piece._current_rotation_state)
		var linked_piece_relative_position = grid_piece.linked_piece.position - grid.get_grid_center() # Find the position of the piece starting position relative to the grid center
		file.store_float(linked_piece_relative_position.x)
		file.store_float(linked_piece_relative_position.y)
		file.store_8(grid_piece.linked_piece._current_rotation_state)
		
	print("Saved to " + path)
	save_level_output_label.text = "Saved to " + path

func on_piece_selector_button_pressed(piece_id: int, piece_position: Vector2):
	var grid_piece: Piece = piece_manager.instantiate_piece(piece_id)
	grid_piece.initialize()
	grid_piece.global_position = piece_position
	game_manager.hold_piece(grid_piece)

func on_piece_picked_up(piece: Piece):
	if piece.is_ghost:
		piece.linked_piece.set_link_highlight(true)

func on_piece_placed_in_grid(piece: Piece):
	if piece.linked_piece == null:
		# Newly created piece has been placed into the grid
		grid_pieces[piece] = true # Add it to the dictionary of pieces in the level
		var ghost_piece = piece_manager.instantiate_piece(piece.id)
		ghost_piece.initialize()
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

func sanitize_filename(filename: String) -> String:
	var sanitized_str = filename.replace("\n", "") # Remove linebreaks from input filename
	var unwanted_chars_pattern = "[^\\w\\.-_]+" # Only allow letters, numbers, periods, hyphens, and underscores in the filename
	sanitized_str = sanitized_str.replace(unwanted_chars_pattern, "")
	return sanitized_str
