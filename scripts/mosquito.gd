extends Area3D

@export var movement_radius: float = 1.0
@export var movement_speed: float = 2.0
@export var reward: int = 10

var start_position: Vector3
var movement_time: float = 0.0
var is_dead: bool = false


func _ready() -> void:
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	start_position = global_position


func take_damage() -> void:
	if is_dead:
		return

	is_dead = true
	GameManager.mosquito_killed(reward)
	queue_free()


func _on_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			take_damage()


func _process(delta: float) -> void:
	movement_time += delta * movement_speed

	global_position = start_position + Vector3(
		sin(movement_time) * movement_radius,
		sin(movement_time * 1.7) * 0.3,
		cos(movement_time) * movement_radius
	)
