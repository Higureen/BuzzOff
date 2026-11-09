extends Control

signal resume_requested

const SHOP_SCENE := preload("res://scenes/shop.tscn")
var shop: Control
var _saved_mode: ProcessMode


func _on_resume_pressed() -> void:
	if GameManager.shop_open:
		return
	resume_requested.emit()


func _on_shop_pressed() -> void:
	if is_instance_valid(shop):
		return

	# the shop goes next to the pause menu, not inside it,
	# so switching the pause menu off doesn't switch the shop off
	shop = SHOP_SCENE.instantiate()
	get_parent().add_child(shop)
	shop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop.closed.connect(_on_shop_closed)

	_saved_mode = process_mode
	process_mode = Node.PROCESS_MODE_DISABLED  # stops its stick/trigger code
	visible = false  # hides Resume / Shop / Exit


func _on_shop_closed() -> void:
	if is_instance_valid(shop):
		shop.queue_free()
	shop = null

	process_mode = _saved_mode
	visible = true


func _exit_tree() -> void:
	if is_instance_valid(shop):
		shop.queue_free()


func _on_exit_pressed() -> void:
	if GameManager.shop_open:
		return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var target: String = (
		"res://scenes/vr_main_menu.tscn"
		if get_tree().root.use_xr
		else "res://scenes/main_menu.tscn"
	)

	get_tree().change_scene_to_file.call_deferred(target)
