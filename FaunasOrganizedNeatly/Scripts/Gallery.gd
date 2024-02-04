extends Control


## The distance to scroll between each gallery entry. This should be the width of an entry + the spacing between entries.
@export var gallery_entry_width: int = 1024
## The scroll container for gallery entries.
@export var scroll_container: ScrollContainer
## The parent container for the gallery entries.
@export var entry_container: HBoxContainer
## Button to go to previous entry
@export var previous_button: Button
## Button to go to next entry
@export var next_button: Button
## Shows the position in entry navigation
@export var entry_number_label: Label
## The amount of time taken to switch between gallery entries
@export var scroll_time: float


var _current_entry_index: int
var _entry_count: int

var _scroll_tween: Tween # Null when inactive


func _ready():
	# Create gallery entries
	for existing_entry in entry_container.get_children(): # Remove existing placeholder entry
		existing_entry.queue_free()
	var entry_packed_scene = load("res://Scenes/UI/gallery_entry.tscn")
	var gallery_entries: Array[GalleryEntry] = []
	for piece_id in PieceManager.loaded_pieces:
		var new_entry: GalleryEntry = entry_packed_scene.instantiate()
		new_entry.initialize(piece_id)
		gallery_entries.append(new_entry)
	gallery_entries.sort_custom(sort_entry)
	for gallery_entry in gallery_entries:
		entry_container.add_child(gallery_entry)
	# Set initial state
	_current_entry_index = 0
	_entry_count = gallery_entries.size()
	scroll_container.scroll_horizontal = 0
	update_entry_number_label()
	# Subscribe button signals
	previous_button.pressed.connect(Callable(scroll).bind(-1))
	next_button.pressed.connect(Callable(scroll).bind(1))


func scroll(index_change: int):
	_current_entry_index += index_change
	if _current_entry_index <= 0:
		_current_entry_index = 0
		previous_button.disabled = true
	else:
		previous_button.disabled = false
	if _current_entry_index >= _entry_count - 1:
		_current_entry_index = _entry_count - 1
		next_button.disabled = true
	else:
		next_button.disabled = false
	update_entry_number_label()
	start_scroll_tween()


func update_entry_number_label():
	entry_number_label.text = str(_current_entry_index + 1) + " / " + str(_entry_count)


func start_scroll_tween():
	if _scroll_tween != null:
		_scroll_tween.stop()
	_scroll_tween = get_tree().create_tween()
	_scroll_tween.set_ease(Tween.EASE_OUT)
	_scroll_tween.set_trans(Tween.TRANS_SINE)
	var scroll_target = _current_entry_index * gallery_entry_width
	_scroll_tween.tween_property(scroll_container, "scroll_horizontal", scroll_target, scroll_time)
	_scroll_tween.tween_callback(func(): _scroll_tween = null)


## Used when sorting the array of gallery entries. Pieces with lower gallery order come first.
## When pieces have equal gallery order, sort alphabetically
func sort_entry(a: GalleryEntry, b: GalleryEntry):
	if a.piece.gallery_order != b.piece.gallery_order:
		return a.piece.gallery_order < b.piece.gallery_order
	else:
		return a.piece.piece_name < b.piece.piece_name
