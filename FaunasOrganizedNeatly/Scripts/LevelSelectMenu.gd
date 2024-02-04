class_name LevelSelectMenu
extends Control


const max_levels_per_pack = 50 # This should match the level editor level number spin box max value.

@onready var pack_selection: Control = $PackSelection
@onready var campaign_pack_button_container: HBoxContainer = $PackSelection/PanelContainer/MarginContainer/VBoxContainer/CampaignScrollContainer/HBoxContainer
@onready var custom_pack_button_container: HBoxContainer = $PackSelection/PanelContainer/MarginContainer/VBoxContainer/CustomScrollContainer/HBoxContainer
var level_pack_select_button: PackedScene = load("res://Scenes/UI/level_pack_select_button.tscn")
var no_custom_level_packs_message: PackedScene = load("res://Scenes/UI/no_custom_packs_found_message.tscn")

@onready var number_selection: Control = $NumberSelection
@onready var level_number_button_container: GridContainer = $NumberSelection/PanelContainer/MarginContainer/VBoxContainer/GridContainer
@onready var number_selection_pack_name_label: Label = $NumberSelection/PanelContainer/MarginContainer/VBoxContainer/PackNameLabel
var level_number_select_button: PackedScene = load("res://Scenes/UI/level_number_select_button.tscn")


func open_pack_select_menu():
	# Make the pack select menu the visible menu
	visible = true
	pack_selection.visible = true
	number_selection.visible = false
	
	create_pack_buttons(LevelManager.LevelPackType.CAMPAIGN)
	var custom_pack_button_count = create_pack_buttons(LevelManager.LevelPackType.CUSTOM)
	
	if custom_pack_button_count == 0:
		var new_node = no_custom_level_packs_message.instantiate()
		custom_pack_button_container.add_child(new_node)


func create_pack_buttons(pack_type: LevelManager.LevelPackType) -> int:
	var created_count: int = 0
	var button_parent: Control = campaign_pack_button_container if pack_type == LevelManager.LevelPackType.CAMPAIGN else custom_pack_button_container
	var directory_path: String = LevelManager.get_pack_type_path(pack_type)
	# Remove existing level pack buttons
	for pack_button in button_parent.get_children():
		pack_button.queue_free()
	# Create level pack selection buttons for each level pack included in the game's resources
	var directories = DirAccess.get_directories_at(directory_path) # Name of the level pack folder is the level pack name
	for pack_name in directories:
		# Find the number of level files within the pack
		var path_without_file = directory_path + "/" + pack_name + "/"
		var pack_level_count = 0
		for i in range(1, max_levels_per_pack + 1):
			var file_path = path_without_file + str(i) + LevelManager.level_file_extension
			if FileAccess.file_exists(file_path):
				pack_level_count += 1
		if pack_level_count == 0:
			print("Level pack " + pack_name + " contains no levels @" + path_without_file)
			continue
		# Get the count of levels in the pack that have already been completed
		var pack_completion_count = ProgressManager.get_pack_completion_count(pack_type, pack_name)
		# Create the button to represent the level pack and allow it's selection by the player
		var new_pack_select_button: LevelPackSelectButton = level_pack_select_button.instantiate()
		new_pack_select_button.initialize(pack_type, pack_name, pack_completion_count, pack_level_count)
		button_parent.add_child(new_pack_select_button)
		created_count += 1
		# When a level pack select button is pressed, open the level number select menu using the selected pack details
		new_pack_select_button.pressed.connect(Callable(on_pack_select_button).bind(new_pack_select_button))
	return created_count


func on_pack_select_button(level_pack_button: LevelPackSelectButton):
	# Set the selected level pack
	LevelManager.load_level_pack_type = level_pack_button.level_pack_type
	LevelManager.load_level_pack_name = level_pack_button.level_pack_name
	open_number_select_menu()


func open_number_select_menu():
	# Make the number select menu the visible menu
	visible = true
	pack_selection.visible = false
	number_selection.visible = true
	# Remove existing level pack buttons
	for number_button in level_number_button_container.get_children():
		number_button.queue_free()
	# Set the pack name label
	var pack_type_name = LevelManager.LevelPackType.keys()[LevelManager.load_level_pack_type]
	number_selection_pack_name_label.text = pack_type_name + " - " + LevelManager.load_level_pack_name
	# Create the buttons
	var pack_level_completion_dictionary: Dictionary = ProgressManager.get_pack_completion_dictionary(LevelManager.load_level_pack_type, LevelManager.load_level_pack_name)
	var directory_path: String = LevelManager.get_pack_type_path(LevelManager.load_level_pack_type)
	var path_without_file = directory_path + "/" + LevelManager.load_level_pack_name + "/"
	for level_number in range(1, max_levels_per_pack + 1):
		var file_path = path_without_file + str(level_number) + LevelManager.level_file_extension
		if FileAccess.file_exists(file_path):
			var level_complete: bool = pack_level_completion_dictionary.has(level_number)
			var new_level_number_button: LevelNumberSelectButton = level_number_select_button.instantiate()
			new_level_number_button.initialize(level_number, level_complete)
			level_number_button_container.add_child(new_level_number_button)
