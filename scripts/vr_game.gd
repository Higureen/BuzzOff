extends Node3D

@export var main_menu_only: bool = false

const GAME_OVER_SCENE := preload("res://scenes/game_over.tscn")

var panel: VRMenuPanel
var pause_ui: Control
var end_panel: VRMenuPanel
var end_ui: Control
var vr_mode: bool = false
var _game_over: bool = false

var saved_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for child in get_children():
		child.process_mode = Node.PROCESS_MODE_PAUSABLE

	var origin: XROrigin3D = get_node_or_null("XROrigin3D")
	vr_mode = origin != null

	if vr_mode:
		var camera: XRCamera3D = origin.get_node("XRCamera3D")
		camera.process_mode = Node.PROCESS_MODE_ALWAYS

		for hand_name in ["LeftHand", "RightHand"]:
			var hand: XRController3D = origin.get_node(hand_name)
			hand.process_mode = Node.PROCESS_MODE_ALWAYS

			for child in hand.get_children():
				child.process_mode = Node.PROCESS_MODE_PAUSABLE

		var right_hand: XRController3D = origin.get_node("RightHand")
		right_hand.button_pressed.connect(_on_vr_button)

		panel = VRMenuPanel.new()
		panel.camera = camera
		panel.controller = right_hand
		panel.ui_scene = load(
			"res://scenes/main_menu.tscn"
			if main_menu_only
			else "res://scenes/pause_menu.tscn"
		)

		add_child(panel)
		pause_ui = panel.ui

		var old_menu: Control = get_node_or_null("PauseMenu")
		if old_menu:
			old_menu.hide()

		if main_menu_only:
			panel.open()
			return
	else:
		pause_ui = $PauseMenu
		pause_ui.process_mode = Node.PROCESS_MODE_ALWAYS
		pause_ui.hide()

	pause_ui.resume_requested.connect(_resume)
	GameManager.run_ended.connect(_show_game_over, CONNECT_DEFERRED)


func _unhandled_key_input(event: InputEvent) -> void:
	if main_menu_only or _game_over:
		return

	if event.is_action_pressed("escape") and not event.is_echo():
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _on_vr_button(button: String) -> void:
	if main_menu_only or _game_over:
		return

	if button == "by_button" and XRToolsStartXR.is_xr_active():
		_toggle_pause()


func _toggle_pause() -> void:
	if GameManager.shop_open:
		return

	var settings := pause_ui.get_node_or_null("AudioSettingsPopup")

	if settings != null and settings.visible:
		settings.close()
		return

	if get_tree().paused:
		_resume()
		return

	var equipment: Node = get_node_or_null("EquipmentManager")

	if equipment:
		equipment.close_menu()

		for slot in [equipment.left_slot, equipment.right_slot]:
			slot.trigger_down = true

			if slot.current_tool:
				slot.current_tool.trigger_released()

	saved_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if vr_mode:
		panel.open()
	else:
		pause_ui.show()
		pause_ui.get_node("VBoxContainer/Button").grab_focus()

	get_tree().paused = true


func _resume() -> void:
	if GameManager.shop_open or _game_over:
		return

	if vr_mode:
		panel.hide()
	else:
		pause_ui.hide()
		Input.mouse_mode = saved_mouse_mode

	get_tree().paused = false


func _show_game_over() -> void:
	if _game_over:
		return

	_game_over = true

	if vr_mode:
		var equipment: Node = get_node_or_null("EquipmentManager")
		if equipment:
			equipment.close_menu()

		end_panel = VRMenuPanel.new()
		end_panel.camera = panel.camera
		end_panel.controller = panel.controller
		end_panel.ui_scene = GAME_OVER_SCENE
		add_child(end_panel)

		end_ui = end_panel.ui
		end_panel.open()
	else:
		var overlay := CanvasLayer.new()
		overlay.layer = 10
		add_child(overlay)

		end_ui = GAME_OVER_SCENE.instantiate()
		overlay.add_child(end_ui)
		end_ui.get_node("VBoxContainer/Retry").grab_focus()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
