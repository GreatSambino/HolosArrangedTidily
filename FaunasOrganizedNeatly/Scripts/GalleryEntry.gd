class_name GalleryEntry
extends HBoxContainer


@export var piece_preview_panel: Panel
@export var piece_name_label: Label
@export var piece_artist_label: Label
@export var piece_description_label: Label


var piece: Piece


func initialize(piece_id: String):
	piece = PieceManager.loaded_pieces[piece_id].instantiate()
	piece.initialize(piece_id)
	piece_preview_panel.add_child(piece)
	piece.position = piece_preview_panel.custom_minimum_size * 0.5 - piece.pivot_offset
	piece_artist_label.text = "Artist: " + piece.artist_credit
	# Check if the piece has been discovered
	if ProgressManager.get_piece_discovered(piece_id):
		piece_name_label.text = piece.piece_name
		piece_description_label.text = piece.description
	else:
		piece_name_label.text = "???"
		piece_description_label.text = "You have not discovered this piece yet!"
		piece.self_modulate = Color.BLACK
