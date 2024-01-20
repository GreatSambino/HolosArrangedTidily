class_name PieceManager
extends Control


const max_piece_id: int = 8

var loaded_pieces: Array[PackedScene] = []


func _enter_tree():
	# Populate the array of piece PackedScenes that can be instantiated from
	for i in range(max_piece_id + 1):
		var loaded_piece : PackedScene = load("res://Assets/Pieces/" + str(i) + ".tscn")
		loaded_pieces.append(loaded_piece)

func instantiate_piece(piece_id: int) -> Piece:
	var new_piece = loaded_pieces[piece_id].instantiate()
	add_child(new_piece)
	return new_piece

func free_all_pieces():
	for existing_piece in get_children():
		existing_piece.queue_free()
