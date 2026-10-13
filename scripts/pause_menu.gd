extends Control

signal resume_requested


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_exit_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var target: String = (
		"res://scenes/vr_main_menu.tscn"
		if get_tree().root.use_xr
		else "res://scenes/main_menu.tscn"
	)

	get_tree().change_scene_to_file.call_deferred(target)
