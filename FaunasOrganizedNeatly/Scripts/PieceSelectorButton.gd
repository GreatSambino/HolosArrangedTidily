class_name PieceSelectorButton
extends Button


signal piece_selected(piece_id: String, create_position: Vector2)


var _piece: Piece


func initialize(piece_id: String):
	button_down.connect(_on_button_down)
	_piece = PieceManager.loaded_pieces[piece_id].instantiate()
	_piece.id = piece_id
	add_child(_piece)
	_piece.position = size * 0.5 - _piece.pivot_offset
	_piece.process_mode = Node.PROCESS_MODE_DISABLED
	_piece.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_button_down():
	piece_selected.emit(_piece.id, _piece.global_position)
