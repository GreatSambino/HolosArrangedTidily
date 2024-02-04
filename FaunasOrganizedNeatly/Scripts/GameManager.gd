## Manages the manipulation of pieces and the game state flow.
## Used while playing levels and also the level editor.
## Pieces created for use in the level are children of this node.


class_name GameManager
extends Control


enum Mode { Normal, LevelEditor }

@export var current_mode: Mode
@export var grid: Grid
@export var level_complete_message: LevelCompleteMessage

@export var held_piece_pickup_duration: float # The amount of time taken for a held piece to move from it's placed/snapped position to the cursor
@export var held_piece_snap_animation_duration: float # The amount of time the held piece takes to move to it's snapped position

signal piece_picked_up(piece: Piece)
signal piece_placed_in_grid(piece: Piece)
signal piece_dropped_without_grid(piece: Piece)

var held_piece: Piece

## Cells of the grid that are currently occupied by a piece. Only key is used
var occupied_grid_cells: Dictionary

## Cells of the grid that are blocked as part of the level layout. Only key is used
var blocked_grid_cells: Dictionary

## The number of cells that need to be filled in the current level
var level_cell_count: int

var held_piece_snapped: bool
var held_piece_grid_origin: Vector2i
var held_piece_pickup_timer: float
var held_piece_pickup_position: Vector2


func _ready():
	occupied_grid_cells = {}
	blocked_grid_cells = {}
	if current_mode == Mode.Normal:
		create_level()

func _process(delta):
	if held_piece == null:
		return
	
	_do_held_piece_movement(delta)
	_do_held_piece_rotation()
	_do_held_piece_placement()

## Sets up the level scene based on the data in LevelManager.
func create_level():
	# Clear old level
	reset_level_state()
	# Get blocked cells
	for blocked_cell in LevelManager.unused_cells:
		blocked_grid_cells[blocked_cell] = true
	level_cell_count = LevelManager.grid_size.x * LevelManager.grid_size.y - LevelManager.unused_cells.size()
	# Set grid size
	grid.set_grid_size(LevelManager.grid_size, blocked_grid_cells)
	# Create pieces
	for i in range(LevelManager.piece_count):
		var new_piece = instantiate_piece(LevelManager.piece_id[i])
		new_piece.set_piece_rotation(LevelManager.piece_start_rotation[i])
		new_piece.position = grid.get_grid_center() + LevelManager.piece_start_position_offset[i]
		new_piece.return_position = new_piece.position
		ProgressManager.set_piece_discovered(LevelManager.piece_id[i])


func instantiate_piece(piece_id: String) -> Piece:
	var new_piece: Piece = PieceManager.loaded_pieces[piece_id].instantiate()
	add_child(new_piece)
	new_piece.piece_clicked.connect(hold_piece)
	new_piece.initialize(piece_id)
	return new_piece


## Resets the level, clearing all existing pieces and grid occupation state
func reset_level_state():
	for piece in get_children():
		piece.queue_free()
	occupied_grid_cells.clear()
	blocked_grid_cells.clear()


func go_to_next_level():
	LevelManager.load_level_number += 1
	LevelManager.load_level_data()
	create_level()
	level_complete_message.visible = false


func hold_piece(piece: Piece):
	if held_piece != null:
		print("Cannot pickup piece as there is already a held piece")
		return
	
	# Pick up the new held piece, and remove any grid positions it occupies
	held_piece = piece
	_remove_occupied_cells(held_piece)
	move_child(held_piece, -1) # Move the held piece to the bottom of it's siblings list so that it appears in front
	
	# Reset movement animations
	held_piece.cancel_movement_tween()
	held_piece_snapped = false
	held_piece_pickup_timer = 0
	held_piece_pickup_position = piece.position
	
	_update_held_piece_grid_origin()
	_update_held_piece_snapping()
	
	piece_picked_up.emit(held_piece)

func _do_held_piece_movement(delta):
	# Update the grid origin of the held piece, and if it has changed check if the piece can snap into the new position
	if _update_held_piece_grid_origin():
		_update_held_piece_snapping()
	
	# Do movement towards cursor
	if held_piece_snapped:
		return # If the held piece is snapped/snapping into place, do not move it to the cursor
	held_piece_pickup_timer += delta
	var t = clampf(held_piece_pickup_timer / held_piece_pickup_duration, 0, 1)
	var target_position: Vector2 = get_viewport().get_mouse_position()
	target_position -= held_piece.pivot_offset
	var held_piece_new_position = held_piece_pickup_position.lerp(target_position, t)
	held_piece.position = held_piece_new_position

# Updates the grid origin of the held piece and returns whether it has changed
func _update_held_piece_grid_origin() -> bool:
	var new_held_piece_grid_origin = _get_held_piece_grid_origin()
	if new_held_piece_grid_origin != held_piece_grid_origin:
		held_piece_grid_origin = new_held_piece_grid_origin
		return true
	else:
		return false

func _update_held_piece_snapping():
	if held_piece.is_ghost:
		return
	
	if _held_piece_fits_grid():
		# If the held piece fits the new position, begin snapping into place
		var snap_position = get_piece_placed_position(held_piece, held_piece_grid_origin)
		held_piece.movement_tween_to(snap_position, held_piece_snap_animation_duration)
		held_piece_snapped = true
	else:
		# If the held piece does not fit and was snapped, return to moving to the cursor
		if held_piece_snapped:
			held_piece_snapped = false
			held_piece_pickup_timer = 0
			held_piece_pickup_position = held_piece.position
			held_piece.cancel_movement_tween()

func _do_held_piece_rotation():
	if Input.is_action_just_pressed("RotateClockwise"):
		held_piece.rotate_clockwise()
		_update_held_piece_grid_origin()
		_update_held_piece_snapping()
	elif Input.is_action_just_pressed("RotateAnticlockwise"):
		held_piece.rotate_anticlockwise()
		_update_held_piece_grid_origin()
		_update_held_piece_snapping()

func _get_held_piece_grid_origin() -> Vector2i:
	var mouse_position = get_viewport().get_mouse_position()
	var piece_origin_cell_center: Vector2 = mouse_position - held_piece.current_offset
	piece_origin_cell_center -= grid.global_position
	piece_origin_cell_center += Vector2(grid.texture_size * 0.5, grid.texture_size * 0.5)
	var x = floor(piece_origin_cell_center.x / grid.texture_size)
	var y = floor(piece_origin_cell_center.y / grid.texture_size)
	return Vector2i(x, y)

func get_piece_placed_position(piece: Piece, piece_grid_origin: Vector2i) -> Vector2:
	var placed_position = grid.grid_to_world_position(piece_grid_origin)
	placed_position += (piece.current_offset - piece.pivot_offset)
	return placed_position

func _held_piece_fits_grid() -> bool:
	if held_piece_grid_origin.x < 0 or held_piece_grid_origin.y < 0:
		return false # One of the held piece's cells is outside the grid
	
	for i in range(held_piece._current_cells.size()):
		var cell = held_piece_grid_origin + held_piece._current_cells[i]
		if cell.x >= grid.width or cell.y >= grid.height:
			return false # One of the held piece's cells is outside the grid
		if occupied_grid_cells.has(cell) or blocked_grid_cells.has(cell):
			return false # One of the held piece's cells overlaps an occupied grid cell
	
	return true

func _remove_occupied_cells(piece: Piece):
	if piece.current_placement_state != Piece.PlacementStates.PLACED:
		return
	
	for i in range(piece._current_cells.size()):
		var cell_grid_position = piece.placed_grid_position + piece._current_cells[i]
		occupied_grid_cells.erase(cell_grid_position)
		print("Removed cell " + str(cell_grid_position))

func _do_held_piece_placement():
	# Try to place the held piece
	if !Input.is_action_just_released("PlacePiece"):
		return # Place piece input was not given
	if held_piece == null:
		return # There is no held piece to place
	
	# Level editor ghost pieces do not go in the grid and only represent a starting position
	if held_piece.is_ghost:
		piece_dropped_without_grid.emit(held_piece)
		held_piece = null
		return # Piece does not fit
	
	# Check if the held piece would fit in it's current grid position
	if !_held_piece_fits_grid():
		held_piece.return_piece()
		piece_dropped_without_grid.emit(held_piece)
		held_piece = null
		return # Piece does not fit
	
	# Place the piece
	# Add the newly occupied cells to the dictionary
	occupy_cells(held_piece, held_piece_grid_origin)
	
	# Find the grid aligned position on screen to move the placed piece to
	var placed_position = get_piece_placed_position(held_piece, held_piece_grid_origin)
	
	held_piece.place_piece(held_piece_grid_origin, placed_position)
	piece_placed_in_grid.emit(held_piece)
	
	held_piece = null # Piece is no longer being held
	
	if current_mode == Mode.Normal and check_win_condition():
		ProgressManager.set_current_level_complete()
		level_complete_message.show_level_complete()

func occupy_cells(placed_piece: Piece, piece_grid_origin: Vector2i):
	for current_cell in placed_piece._current_cells:
		var cell_grid_position = piece_grid_origin + current_cell
		occupied_grid_cells[cell_grid_position] = true
		print("Placed cell " + str(cell_grid_position))

func check_win_condition() -> bool:
	return occupied_grid_cells.size() == level_cell_count
