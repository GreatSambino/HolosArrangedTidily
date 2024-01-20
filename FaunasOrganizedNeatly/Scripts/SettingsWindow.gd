extends Control


@export var display_mode_option_button: OptionButton
@export var window_size_option_button: OptionButton
@export var master_volume_slider: Slider
@export var sound_effects_volume_slider: Slider
@export var music_volume_slider: Slider
@export var fauna_noises_volume_slider: Slider
@export var fauna_noise_reference_player: AudioStreamPlayer

var file_save_delay_timer: Node


func _ready():
	display_mode_option_button.item_selected.connect(change_display_mode)
	window_size_option_button.item_selected.connect(change_window_size)
	master_volume_slider.value_changed.connect(Callable(change_audio_volume).bind(0))
	sound_effects_volume_slider.value_changed.connect(Callable(change_audio_volume).bind(1))
	music_volume_slider.value_changed.connect(Callable(change_audio_volume).bind(2))
	fauna_noises_volume_slider.value_changed.connect(Callable(change_audio_volume).bind(3))
	fauna_noises_volume_slider.value_changed.connect(Callable(play_reference_fauna_noise).unbind(1))

func show_window():
	display_mode_option_button.select(SettingsManager.display_mode)
	window_size_option_button.select(SettingsManager.get_current_window_size_option_index())
	master_volume_slider.set_value_no_signal(SettingsManager.audio_volumes[0])
	sound_effects_volume_slider.set_value_no_signal(SettingsManager.audio_volumes[1])
	music_volume_slider.set_value_no_signal(SettingsManager.audio_volumes[2])
	fauna_noises_volume_slider.set_value_no_signal(SettingsManager.audio_volumes[3])
	visible = true

func change_display_mode(new_display_mode: int):
	SettingsManager.display_mode = new_display_mode
	SettingsManager.apply_display_mode()
	SettingsManager.save_settings()

func change_window_size(new_window_size_option: int):
	SettingsManager.window_size = SettingsManager.window_size_from_option(new_window_size_option)
	SettingsManager.apply_window_size()
	SettingsManager.save_settings()

func change_audio_volume(new_volume: float, audio_volume_index: int):
	print(SettingsManager.AudioBusName.keys()[audio_volume_index] + " volume set to " + str(new_volume))
	SettingsManager.audio_volumes[audio_volume_index] = new_volume
	SettingsManager.apply_audio_volume(audio_volume_index)
	SettingsManager.file_save_delay_timer.start()

func play_reference_fauna_noise():
	if fauna_noise_reference_player.playing == false:
		fauna_noise_reference_player.playing = true
