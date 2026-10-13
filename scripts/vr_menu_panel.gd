class_name VRMenuPanel
extends Node3D

var ui_scene: PackedScene
var camera: Camera3D
var controller: XRController3D

var screen: XRToolsViewport2DIn3D
var ui: Control

var buttons: Array[Button] = []
var index: int = 0

var stick_locked: bool = true
var trigger_locked: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	screen = preload(
		"res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn"
	).instantiate()

	screen.screen_size = Vector2(1.8, 1.2)
	screen.viewport_size = Vector2(1200, 800)
	screen.scene = ui_scene

	screen.enabled = false
	screen.input_keyboard = false
	screen.unshaded = true

	add_child(screen)

	ui = screen.get_scene_instance() as Control

	for child in ui.get_node("VBoxContainer").get_children():
		if child is Button and child.visible:
			buttons.append(child)

	hide()


func open() -> void:
	# meniu atsiranda pries zaideja
	global_position = camera.global_position
	global_rotation = Vector3(0, camera.global_rotation.y, 0)
	global_position -= global_basis.z * 1.5

	index = 0
	stick_locked = true
	trigger_locked = true

	show()
	buttons[index].grab_focus()


func _process(_delta: float) -> void:
	if not visible or buttons.is_empty():
		return

	if not controller.get_is_active() or not XRToolsStartXR.is_xr_active():
		stick_locked = true
		trigger_locked = true
		return

	var y: float = controller.get_vector2("primary").y

	if absf(y) < 0.25:
		stick_locked = false

	elif absf(y) > 0.65 and not stick_locked:
		stick_locked = true

		var direction: int = -1 if y > 0 else 1
		index = wrapi(index + direction, 0, buttons.size())

		buttons[index].grab_focus()

	var trigger: float = controller.get_float("trigger")

	if trigger < 0.25:
		trigger_locked = false

	elif trigger > 0.75 and not trigger_locked:
		trigger_locked = true
		buttons[index].pressed.emit()
