extends AudioStreamPlayer

var saved_volume: float = 50.0

func _ready() -> void:
	apply_volume(saved_volume)
	play()

func apply_volume(volume: float) -> void:
	saved_volume = volume

	var bus_index = AudioServer.get_bus_index("Master")

	if volume <= 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(
			bus_index,
			linear_to_db(volume / 100.0)
		)
		
