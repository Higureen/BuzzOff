extends Node3D

@onready var flashlight: HandTool = $Flashlight
@onready var newspaper: HandTool = $Newspaper
@onready var camera: Camera3D = get_parent() as Camera3D

var _swinging: bool = false
var _rest_position: Vector3
var _rest_rotation: Vector3


func _ready() -> void:
	print("DesktopTools veikia")
	_rest_position = newspaper.position
	_rest_rotation = newspaper.rotation


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.physical_keycode == KEY_F:
				print("F paspaustas")
				flashlight.trigger_pressed()
				flashlight.trigger_released()
				get_viewport().set_input_as_handled()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_swing()
			get_viewport().set_input_as_handled()


func _swing() -> void:
	if _swinging:
		return

	_swinging = true

	newspaper.trigger_pressed()
	newspaper.trigger_released()

	var tween: Tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel(true)

	tween.tween_property(
		newspaper,
		"position",
		Vector3(0.02, -0.05, -0.7),
		0.16
	)

	tween.tween_property(
		newspaper,
		"rotation",
		Vector3(0.15, -0.3, 0.5),
		0.16
	)

	tween.chain().tween_interval(0.08)

	tween.chain().tween_property(
		newspaper, "position", _rest_position, 0.2
	)

	tween.parallel().tween_property(
		newspaper, "rotation", _rest_rotation, 0.2
	)

	tween.chain().tween_callback(
		func(): _swinging = false
	)
func _process(_delta: float) -> void:
	var aim_point: Vector3 = (
		camera.global_position
		- camera.global_basis.z * 5.0
	)

	flashlight.look_at(aim_point, camera.global_basis.y)
