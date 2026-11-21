extends Button

@export_enum("Master", "Buzz") var audio_channel: String = "Master"


func _ready() -> void:
	pressed.connect(_on_pressed)
	AudioSettings.volume_changed.connect(_update_text)
	_update_text()


func _on_pressed() -> void:
	AudioSettings.cycle_volume(audio_channel)


func _update_text() -> void:
	var volume: float = AudioSettings.get_volume(audio_channel)

	var title: String = (
		"MOSQUITO BUZZ"
		if audio_channel == "Buzz"
		else "MASTER VOLUME"
	)

	var value: String = (
		"OFF"
		if volume <= 0.0
		else "%d%%" % roundi(volume * 100.0)
	)

	text = title + ": " + value
