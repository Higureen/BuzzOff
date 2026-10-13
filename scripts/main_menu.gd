extends Control


func _ready() -> void:
	#tiesiogiai paleistas 2d pagr menu yra dekstop menu
	if get_parent() == get_tree().root:
		get_tree().root.use_xr = false

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var in_vr: bool = get_tree().root.use_xr

	$VBoxContainer/StartVR.visible = not in_vr
	$VBoxContainer/Button.text = (
		"Play" if in_vr else "Play desktop"
	)


func _on_start_pressed() -> void:
	var target: String = (
		"res://scenes/main.tscn"
		if get_tree().root.use_xr
		else "res://scenes/desktop_test.tscn"
	)

	get_tree().change_scene_to_file.call_deferred(target)


func _on_start_vr_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(
		"res://scenes/vr_main_menu.tscn"
	)


func _on_exit_pressed() -> void:
	get_tree().quit()
