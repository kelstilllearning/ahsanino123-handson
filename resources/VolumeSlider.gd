extends HSlider

func _ready() -> void:
	min_value = 0
	max_value = 100

	# Load previously saved volume
	set_value_no_signal(global_music_player.saved_volume)

func _on_value_changed(value: float) -> void:

	# Update global volume
	global_music_player.apply_volume(value)

	print("Volume: ", value)
