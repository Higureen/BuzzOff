extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	$VBoxContainer/Result.text = (
		"Mosquitoes swatted: %d\nTime survived: %s\nWave reached: %d\nBest score: %d"
		% [
			GameManager.killed_count,
			GameManager.format_time(int(GameManager.elapsed_time)),
			GameManager.wave_number,
			GameManager.high_score,
		]
	)

	$VBoxContainer/Retry.pressed.connect(_on_retry_pressed)
	$VBoxContainer/Menu.pressed.connect(_on_menu_pressed)


func _on_retry_pressed() -> void:
	var tree := get_tree()
	tree.paused = false
	tree.reload_current_scene.call_deferred()


func _on_menu_pressed() -> void:
	var tree := get_tree()
	tree.paused = false

	var path := (
		"res://scenes/vr_main_menu.tscn"
		if tree.root.use_xr
		else "res://scenes/main_menu.tscn"
	)

	tree.change_scene_to_file.call_deferred(path)
