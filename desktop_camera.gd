extends Camera3D

@export var speed: float = 3.0
@export var mouse_sensitivity: float = 0.002

func _ready() -> void:
	get_viewport().use_xr = false
	make_current()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotation.y -= event.relative.x * mouse_sensitivity
			rotation.x = clampf(
				rotation.x - event.relative.y * mouse_sensitivity,
				deg_to_rad(-85.0),
				deg_to_rad(85.0)
			)

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	var direction := Vector3.ZERO

	if Input.is_physical_key_pressed(KEY_W):
		direction.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		direction.z += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_Q):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_E):
		direction.y += 1.0

	var yaw_basis := Basis(Vector3.UP, rotation.y)
	position += yaw_basis * direction.normalized() * speed * delta
