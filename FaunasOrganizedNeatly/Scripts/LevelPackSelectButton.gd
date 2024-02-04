class_name LevelPackSelectButton
extends Button


# Information about the level pack this selection button represents
var level_pack_type: LevelManager.LevelPackType
var level_pack_name: String
var level_pack_level_count: int


func initialize(pack_type: LevelManager.LevelPackType, pack_name: String, completion_count: int, level_count: int):
	# Set pack details to select when this button is pressed
	level_pack_type = pack_type
	level_pack_name = pack_name
	level_pack_level_count = level_count
	# Set button visual information
	var pack_name_label = $PackNameLabel
	var completion_number_label = $CompletionNumberLabel
	pack_name_label.text = level_pack_name
	completion_number_label.text = str(completion_count) + " / " + str(level_count)
