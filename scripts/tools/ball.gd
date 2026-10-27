extends HandTool

@export var thrown_ball_scene: PackedScene
@export var throw_multiplier: float = 1.0
@export var min_throw_speed: float = 1.0
@export var respawn_time: float = 1.0

const SAMPLE_COUNT: int = 6

@onready var held_mesh: Node3D = $BallMesh

var ball_ready: bool = true
var respawn_left: float = 0.0
var velocity_samples: Array[Vector3] = []
var last_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	last_position = global_position
	if held_mesh == null:
		push_error("Ball: child node 'BallMesh' not found. Rename the MeshInstance3D in ball.tscn to BallMesh.")


func _physics_process(delta: float) -> void:
	# track hand speed
	var current: Vector3 = global_position
	velocity_samples.append((current - last_position) / delta)
	if velocity_samples.size() > SAMPLE_COUNT:
		velocity_samples.pop_front()
	last_position = current

	# bring the ball back after a throw
	if not ball_ready:
		respawn_left -= delta
		if respawn_left <= 0.0:
			ball_ready = true
			if held_mesh:
				held_mesh.visible = true


func on_trigger_pressed() -> void:
	print("Ball: trigger pressed")


func on_trigger_released() -> void:
	print("Ball: trigger released, ball_ready = ", ball_ready)
	if not ball_ready:
		return
	_throw()


func _throw() -> void:
	if thrown_ball_scene == null:
		push_warning("Ball: thrown_ball_scene not assigned")
		return

	if velocity_samples.is_empty():
		return

	var sum: Vector3 = Vector3.ZERO
	for v in velocity_samples:
		sum += v
	var velocity: Vector3 = (sum / velocity_samples.size()) * throw_multiplier
	print("Ball: throw speed = ", velocity.length(), " (min ", min_throw_speed, ")")

	# too slow: keep the ball in hand
	if velocity.length() < min_throw_speed:
		return

	var ball: RigidBody3D = thrown_ball_scene.instantiate()
	get_tree().current_scene.add_child(ball)

	if held_mesh:
		ball.global_position = held_mesh.global_position
	else:
		ball.global_position = global_position

	ball.linear_velocity = velocity
	print("Ball spawned at ", ball.global_position, " velocity ", ball.linear_velocity)

	# delete the flying ball after 6 seconds
	get_tree().create_timer(6.0).timeout.connect(ball.queue_free)

	ball_ready = false
	respawn_left = respawn_time
	if held_mesh:
		held_mesh.visible = false


func on_unequipped() -> void:
	velocity_samples.clear()
