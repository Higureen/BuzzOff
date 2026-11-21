extends Node

signal volume_changed

const SAVE_PATH := "user://audio_settings.cfg"

var master_volume: float = 1.0
var buzz_volume: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# sukuriamas atskiras kanalas uodu zvimb
	if AudioServer.get_bus_index("Buzz") == -1:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, "Buzz")
		AudioServer.set_bus_send(index, "Master")

	var config := ConfigFile.new()

	if config.load(SAVE_PATH) == OK:
		master_volume = clampf(
			float(config.get_value("audio", "master", 1.0)),
			0.0,
			1.0
		)
		buzz_volume = clampf(
			float(config.get_value("audio", "buzz", 1.0)),
			0.0,
			1.0
		)

	_apply_volumes()


func cycle_volume(channel: String) -> void:
	if channel == "Master":
		master_volume = _next_volume(master_volume)
	elif channel == "Buzz":
		buzz_volume = _next_volume(buzz_volume)
	else:
		return

	_apply_volumes()
	_save()
	volume_changed.emit()


func get_volume(channel: String) -> float:
	return buzz_volume if channel == "Buzz" else master_volume


func _next_volume(current: float) -> float:
	if current <= 0.0:
		return 1.0

	return maxf(0.0, current - 0.25)


func _apply_volumes() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Buzz", buzz_volume)


func _set_bus_volume(bus_name: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)

	if index == -1:
		return

	AudioServer.set_bus_mute(index, volume <= 0.0)

	# tyla valdo mute, todel vengiam logaritmo is nulio
	AudioServer.set_bus_volume_db(
		index,
		linear_to_db(maxf(volume, 0.0001))
	)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "buzz", buzz_volume)

	if config.save(SAVE_PATH) != OK:
		push_warning("Nepavyko išsaugoti garso nustatymų.")
