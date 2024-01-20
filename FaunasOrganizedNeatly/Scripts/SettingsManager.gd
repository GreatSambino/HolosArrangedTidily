## This class is intended to be used as a persistent singleton (Autoload).
## When added to Project Settings -> Autoload with Global Variable enabled, can be accessed from anywhere as though it were a static member e.g. SettingsManager.master_volume = 1.0.
## Should not be instantiated at runtime (other than by Godot as an autoload on game start).

extends Node


## The display mode (window mode) options used by the game. This should match the option button list.
enum DisplayModeOption { Fullscreen, FullscreenExclusive, Windowed }
## The window size options used by the game. This should match the option button list.
enum WindowSizeOption { _1920x1080, _1600x900, _1366x768, _1280x720 }
## Links the index and bus name of each volume category
enum AudioBusName { Master, SoundEffects, Music, FaunaNoises }

@onready var DEFAULT_DISPLAY_MODE = DisplayModeOption.FullscreenExclusive
@onready var DEFAULT_WINDOW_SIZE = Vector2i(1280, 720)
@onready var DEFAULT_VOLUMES: Array[float] = [ 0.75, 0.5, 0.5, 1.0 ]

# Intialized in the ready function
## The path and filename where the settings are saved
var SETTINGS_FILE_PATH: String
## Maps SettingsManager.DisplayModeOption to the corresponding DisplayServer.WindowMode.
var DISPLAY_MODE_MAP: Dictionary
## Maps a window size to the corresponding option button index.
var WINDOW_SIZE_TO_INDEX_MAP: Dictionary
## Maps an option button index to the corresponding window size.
var WINDOW_INDEX_TO_SIZE_MAP: Dictionary

# Current setting values, must be applied with the appropriate function after being changed
var display_mode: DisplayModeOption
var window_size: Vector2i
var audio_volumes: Array[float] # Sound category volumes, values range 0-1

var file_save_delay_timer: Timer


func _ready():
	SETTINGS_FILE_PATH = OS.get_user_data_dir() + "/settings.json"
	
	DISPLAY_MODE_MAP = {
		DisplayModeOption.Fullscreen: DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayModeOption.FullscreenExclusive: DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
		DisplayModeOption.Windowed: DisplayServer.WINDOW_MODE_WINDOWED
	}
	
	WINDOW_SIZE_TO_INDEX_MAP = {
		Vector2i(1920, 1080): WindowSizeOption._1920x1080,
		Vector2i(1600, 900): WindowSizeOption._1600x900,
		Vector2i(1366, 768): WindowSizeOption._1366x768,
		Vector2i(1280, 720): WindowSizeOption._1280x720
	}
	
	WINDOW_INDEX_TO_SIZE_MAP = {} # This dictionary maps the opposite direction to WINDOW_SIZE_TO_INDEX_MAP
	for size in WINDOW_SIZE_TO_INDEX_MAP:
		var index = WINDOW_SIZE_TO_INDEX_MAP[size]
		WINDOW_INDEX_TO_SIZE_MAP[index] = size
	
	# Creates a short delay before saving the settings file when continuously adjustable settings like audio volume are changed
	file_save_delay_timer = Timer.new()
	add_child(file_save_delay_timer)
	file_save_delay_timer.wait_time = 0.1
	file_save_delay_timer.one_shot = true
	file_save_delay_timer.timeout.connect(save_settings)
	
	load_settings()
	save_settings()

func load_all_default_settings():
	display_mode = DEFAULT_DISPLAY_MODE
	window_size = DEFAULT_WINDOW_SIZE
	audio_volumes = DEFAULT_VOLUMES.duplicate()
	apply_all_settings()
	print("Loaded all default settings")

func save_settings():
	var settings = {
		"DisplayMode": display_mode,
		"WindowWidth": window_size.x,
		"WindowHeight": window_size.y
	}
	for i in range(audio_volumes.size()):
		var key_string = volume_setting_key_string(i)
		settings[key_string] = audio_volumes[i]
	
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	var json_string = JSON.stringify(settings, "\t", false)
	file.store_string(json_string)
	file.close()
	print("Saved settings at " + SETTINGS_FILE_PATH)

## Attempts to load settings from file, uses default settings where saved settings cannot be found
func load_settings():
	# Attempt to open settings file
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if file == null:
		print("Could not find settings file at " + SETTINGS_FILE_PATH)
		load_all_default_settings()
		return # Settings file does not exist or cannot be opened
	# Read json string from file
	var json_string = file.get_as_text()
	file.close()
	# Attempt to parse json string
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Failed to parse settings file at " + SETTINGS_FILE_PATH)
		load_all_default_settings()
		return # Settings file does not contain json data or is otherwise improperly formatted
	var settings: Dictionary = json.data
	if typeof(settings) != TYPE_DICTIONARY:
		print("Invalid settings file at " + SETTINGS_FILE_PATH)
		load_all_default_settings() # Settings file json data is not of correct object type
		return
		
	# Load settings where keys exist, otherwise use default value.
	# Display mode
	display_mode = settings.get("DisplayMode", DEFAULT_DISPLAY_MODE)
	if typeof(display_mode) != TYPE_INT:
		print("Invalid display mode value, loading default display mode")
		display_mode = DEFAULT_DISPLAY_MODE
	# Window size
	var window_width: int = settings.get("WindowWidth")
	var window_height: int = settings.get("WindowHeight")
	
	if typeof(window_width) != TYPE_INT or typeof(window_height) != TYPE_INT:
		print("Invalid window width or height value, loading default window size")
		window_size = DEFAULT_WINDOW_SIZE
	else:
		window_size = Vector2i(window_width, window_height)
	# Audio volumes
	audio_volumes = []
	for i in range(AudioBusName.size()):
		var key_string = volume_setting_key_string(i)
		var new_audio_volume = settings.get(key_string, DEFAULT_VOLUMES[i])
		if typeof(new_audio_volume) != TYPE_FLOAT:
			print("Invalid " + key_string + "value, loading default value")
			new_audio_volume = DEFAULT_VOLUMES[i]
		audio_volumes.append(new_audio_volume)
	
	print("Loaded settings at " + SETTINGS_FILE_PATH)
	
	apply_all_settings()

## Converts the index of the audio volume setting to the name used as the key in the settings json file
func volume_setting_key_string(index: int) -> String:
	return AudioBusName.keys()[index] + "Volume"

## Converts a window size dropdown option index to the actual window size Vector2i
func window_size_from_option(index: int) -> Vector2i:
	return WINDOW_INDEX_TO_SIZE_MAP.get(index)

func apply_all_settings():
	apply_display_mode() # This also applies the new window size
	for i in range(audio_volumes.size()):
		apply_audio_volume(i)

func apply_display_mode():
	var window_mode = DISPLAY_MODE_MAP.get(display_mode)
	if window_mode == null:
		display_mode = DEFAULT_DISPLAY_MODE
		window_mode = DISPLAY_MODE_MAP.get(display_mode)
	DisplayServer.window_set_mode(window_mode)
	apply_window_size()

func apply_window_size():
	DisplayServer.window_set_size(window_size)
	var window_size_with_decorations = DisplayServer.window_get_size_with_decorations()
	var screen_size = DisplayServer.screen_get_size()
	var window_position = (screen_size - window_size_with_decorations) * 0.5
	window_position.y += 24 # Make the window bar barely grabbable if the window is too large for the screen
	DisplayServer.window_set_position(window_position)
	DisplayServer.window_set_size(window_size)

func apply_audio_volume(audio_volume_index: int):
	var bus_index = audio_volume_index # AudioBusName enum and project audio bus settings are set up to have matching indices
	var db = linear_to_db(audio_volumes[audio_volume_index])
	AudioServer.set_bus_volume_db(bus_index, db)

## Gets the window size option button index to that matches the current window size setting.
## If this has been set to an arbitrary size by editing the settings.json file, return -1 which selects a blank option
func get_current_window_size_option_index() -> int:
	return WINDOW_SIZE_TO_INDEX_MAP.get(window_size, -1)
