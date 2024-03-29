## Represents a puzzle piece that can be manipulated by the player. Also used in the level editor and gallery.
## The unique ID for a piece is it's filename within the Pieces directory, without the file extension (e.g. res://Pieces/test_piece.tscn will have the ID "test_piece").

class_name Piece
extends TextureRect


const RETURN_ANIMATION_DURATION: float = 0.5 # Number of seconds a piece takes to return to it's return position when dropped
const ROTATION_ANIMATION_DURATION: float = 0.35 # Number of seconds a piece takes to rotate
const PLACED_ANIMATION_DURATION: float = 0.2 # Number of seconds a piece take to move into it's placed position

var ghost_color = Color(0.5, 1.0, 0.6, 0.75) # Color of "ghost pieces" used in the level editor to represent a piece's starting position in the level

enum RotationStates { DEG_0 = 0, DEG_90, DEG_180, DEG_270 }
enum PlacementStates { UNPLACED, HELD, PLACED }
enum SoundCategory { PickedUp, Placed, Dropped, Rotated }


signal piece_clicked(piece: Piece) # Emitted by a piece when it is clicked, argument is a reference to itself


## The name of the piece that appears in the gallery listing and when it is first discovered. Does not have to match the piece ID or filename.
@export var piece_name: String
## The name of the artist who drew the art for the piece
@export var artist_credit: String
## Flavour text that appears in the piece's gallery listing and when it is first discovered
@export_multiline var description: String
## Lower values appear first in the gallery. See Gallery.sort_entry()
@export var gallery_order: int
## Used to define the cells occupied by this piece. Cell (0, 0) is the origin cell at the top-left of the piece. Should match the texture of the piece in it's unrotated state.
## For example, to define an L-shaped use the cells (0, 0), (0, 1), (0, 2), (1, 2).
@export var cells: Array[Vector2i]


var id: String # Identifies the type of piece this is. This is determined by the file name of the piece.
var _current_rotation_state: RotationStates
var current_placement_state: PlacementStates
var _current_angle_target: float # The rotation angle target for animation
var _current_cells: Array[Vector2i] # The cell offsets occupied by this piece given it's current rotation
var current_offset: Vector2 # For pieces with equal dimensions this is always the pivot_offset, for pieces with unequal dimensions the x and y component are swapped for 90 and 270 degree rotations
var _cells_max_x: int # Used for calculating cell positions after rotation
var _cells_max_y: int # ^

# This is the top left grid space occupied by this piece when placed.
# All other occupied spaces can be found by adding _current_cells to this position
var placed_grid_position: Vector2i

var return_position: Vector2 # Position to return this piece to when it is dropped without being placed into the level grid

var _movement_tween: Tween # Active tween for when this piece is moving to a position (e.g. when placed or returned). Set this to null when the tween is finished
var _rotation_tween: Tween # Active tween for when this piece is rotating. Set this to null when the tween is finished

var is_ghost: bool # Indicates whether this is a "ghost piece" used in the level editor to represent a piece's starting position in the level
var linked_piece: Piece # Used by the level editor to link a piece on the level grid and it's start position "ghost piece"


## Initializes a newly created piece.
func initialize(piece_id: String):
	id = piece_id
	current_placement_state = PlacementStates.UNPLACED
	
	# Initialize current cells array to same size as cells array
	_current_cells = []
	for i in range(cells.size()):
		_current_cells.append(cells[i])
	
	# Find max cell positions (used when calculating rotations)
	_cells_max_x = 0
	_cells_max_y = 0
	for i in range(cells.size()):
		if cells[i].x > _cells_max_x:
			_cells_max_x = cells[i].x
		if cells[i].y > _cells_max_y:
			_cells_max_y = cells[i].y
	
	current_offset = pivot_offset # Get offset from pivot_offset


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _check_shape_clicked():
				print("Piece " + name + " shape clicked")
				play_random_sound(SoundCategory.PickedUp)
				piece_clicked.emit(self)


## Sets this piece as a ghost that indicates the start position of a level editor piece
func set_as_ghost(ghost_of: Piece):
	is_ghost = true
	linked_piece = ghost_of
	self_modulate = ghost_color


## Gets the origin (top-left) position of the piece in it's current rotation
func get_shape_origin() -> Vector2:
	var shape_origin = position
	shape_origin += pivot_offset
	shape_origin -= current_offset
	return shape_origin


func set_shape_origin_position(new_position: Vector2):
	global_position = new_position + (current_offset - pivot_offset)


## Gets the dimensions of the piece in it's current rotation
func get_shape_dimensions() -> Vector2:
	if _current_rotation_state == RotationStates.DEG_0 or _current_rotation_state == RotationStates.DEG_180:
		return Vector2(_cells_max_x + 1, _cells_max_y + 1) * Grid.texture_size
	else:
		return Vector2(_cells_max_y + 1, _cells_max_x + 1) * Grid.texture_size


## Returns an array of all cells currently occupied by this piece (assumes the piece has been placed in the grid)
func get_occupied_cells() -> Array[Vector2i]:
	var occupied_cells: Array[Vector2i] = []
	for current_cell in _current_cells:
		var final_cell = placed_grid_position + current_cell
		occupied_cells.append(final_cell)
	return occupied_cells


func _check_shape_clicked() -> bool:
	var shape_origin = get_shape_origin()
	var mouse_position = get_viewport().get_mouse_position()
	var relative_click_position = mouse_position - shape_origin
	for i in range(_current_cells.size()):
		var cell00 = _current_cells[i] * Grid.texture_size
		var cell11 = _current_cells[i] * Grid.texture_size + Vector2(Grid.texture_size, Grid.texture_size)
		if relative_click_position.x >= cell00.x and relative_click_position.x <= cell11.x and relative_click_position.y >= cell00.y and relative_click_position.y < cell11.y: # I really wish gdscript let you break statements across lines
			return true # Mouse is inside one of the piece's cells
	# Mouse is not within the shape of the piece
	return false


func on_piece_held():
	current_placement_state = PlacementStates.HELD
	cancel_movement_tween()


func update_current_cells():
	# Rotates the occupied cells of the piece such that each position remains above (0,0)
	# Refer to 'CursedRotationGuide.png' in project root folder to become slightly more/less confused
	match _current_rotation_state:
		RotationStates.DEG_0: # No change from base cells
			for i in range(cells.size()):
				_current_cells[i] = Vector2i(cells[i])
		RotationStates.DEG_90: # Ascending x -> Ascending y | Ascending y -> Descending x
			for i in range(cells.size()):
				_current_cells[i] = Vector2i(_cells_max_y - cells[i].y, cells[i].x)
		RotationStates.DEG_180: # Ascending x -> Descending x | Ascending y -> Descending y
			for i in range(cells.size()):
				_current_cells[i] = Vector2i(_cells_max_x - cells[i].x, _cells_max_y - cells[i].y)
		RotationStates.DEG_270: # Ascending x -> Descending y | Ascending y -> Ascending x
			for i in range(cells.size()):
				_current_cells[i] = Vector2i(cells[i].y, _cells_max_x - cells[i].x)


## Sets the piece rotation and updates it visually immediately.
func set_piece_rotation(new_rotation: RotationStates):
	var rotation_steps = absi(new_rotation - _current_rotation_state)
	_current_rotation_state = new_rotation
	update_current_cells()
	for i in range(rotation_steps):
		_rotate_offset()
	rotation = new_rotation * PI * 0.5
	_current_angle_target = new_rotation * PI * 0.5


func rotate_clockwise():
	# Update rotation variables
	if _current_rotation_state == RotationStates.DEG_270:
		_current_rotation_state = RotationStates.DEG_0
	else:
		_current_rotation_state = _current_rotation_state + 1 as RotationStates
	_current_angle_target += PI * 0.5
	
	update_current_cells()
	
	# Update the offset to keep the piece visually aligned with the grid
	_rotate_offset()
	
	_start_rotation_tween()
	
	play_random_sound(SoundCategory.Rotated)


func rotate_anticlockwise():
	# Update rotation variables
	if _current_rotation_state == RotationStates.DEG_0:
		_current_rotation_state = RotationStates.DEG_270
	else:
		_current_rotation_state = _current_rotation_state - 1 as RotationStates
	_current_angle_target -= PI * 0.5
	
	update_current_cells()
	
	# Update the offset to keep the piece visually aligned with the grid
	_rotate_offset()
	
	_start_rotation_tween()
	
	play_random_sound(SoundCategory.Rotated)


func _rotate_offset():
	var new_offset_x = current_offset.y
	var new_offset_y = current_offset.x
	current_offset = Vector2(new_offset_x, new_offset_y)


func _start_rotation_tween():
	# Create the tween to animate the rotation
	cancel_rotation_tween()
	_rotation_tween = get_tree().create_tween()
	_rotation_tween.set_ease(Tween.EASE_OUT)
	_rotation_tween.set_trans(Tween.TRANS_SPRING)
	_rotation_tween.tween_property(self, "rotation", _current_angle_target, ROTATION_ANIMATION_DURATION)
	_rotation_tween.tween_callback(func(): _rotation_tween = null)


func return_piece():
	current_placement_state = PlacementStates.UNPLACED
	movement_tween_to(return_position, RETURN_ANIMATION_DURATION)
	play_random_sound(SoundCategory.Dropped)


func movement_tween_to(move_to: Vector2, duration: float):
	cancel_movement_tween()
	_movement_tween = get_tree().create_tween()
	_movement_tween.set_ease(Tween.EASE_OUT)
	_movement_tween.set_trans(Tween.TRANS_SINE)
	_movement_tween.tween_property(self, "position", move_to, duration)
	_movement_tween.tween_callback(func(): _movement_tween = null)


func cancel_movement_tween():
	if _movement_tween != null:
		_movement_tween.stop()
	_movement_tween = null


func cancel_rotation_tween():
	if _rotation_tween != null:
		_rotation_tween.stop()
	_rotation_tween = null


## Highlight a piece to show it's link to a level editor ghost piece
func set_link_highlight(show_highlight: bool):
	if show_highlight:
		self_modulate = ghost_color
	else:
		self_modulate = Color.WHITE


func place_piece(grid_position: Vector2i, move_to: Vector2, instant: bool = false):
	placed_grid_position = grid_position
	current_placement_state = PlacementStates.PLACED
	if instant:
		position = move_to
	else:
		movement_tween_to(move_to, PLACED_ANIMATION_DURATION)
		play_random_sound(SoundCategory.Placed)


func play_random_sound(sound_category: SoundCategory):
	var sound_parent: Node = get_node("Sounds/" + SoundCategory.keys()[sound_category])
	var sound_count = sound_parent.get_child_count()
	if sound_count == 0:
		return
	var play_index = randi_range(0, sound_count - 1)
	var play_sound: AudioStreamPlayer = sound_parent.get_child(play_index)
	play_sound.pitch_scale = randf_range(0.95, 1.05)
	play_sound.playing = true
