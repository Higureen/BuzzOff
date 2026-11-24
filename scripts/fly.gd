extends Area3D

@export var wander_speed: float = 1.4
@export var light_speed: float = 1.9
@export var health_reward: int = 1
@export var coin_reward: int = 5
@export var lifetime: float = 30.0

var habitat: Node
var is_dead: bool = false

var _time: float = 0.0
var _phase: float = 0.0
var _wander_timer: float = 0.0
var _light_timer: float = 0.0
var _life_left: float = 0.0
var _target: Vector3
var _light: Node3D

var _flight_shape: SphereShape3D = SphereShape3D.new()

@onready var buzz: AudioStreamPlayer3D = $Buzz


func _ready() -> void:
	buzz.bus = &"Buzz"
	add_to_group("mosquito")
	add_to_group("fly")
	input_ray_pickable = false

	_flight_shape.radius = 0.05
	_phase = randf_range(0.0, TAU)
	_life_left = lifetime
	_target = global_position
	buzz.pitch_scale = randf_range(0.7, 0.8) # deeper buzz than mosquitoes
	buzz.play()


func take_damage(weapon: String = "") -> void:
	if is_dead or not GameManager.run_active:
		return

	is_dead = true
	buzz.stop()
	GameManager.play_kill_sound(weapon, global_position)
	GameManager.fly_killed(health_reward, coin_reward)
	queue_free()


func _physics_process(delta: float) -> void:
	if is_dead or habitat == null or not GameManager.run_active:
		return

	_time += delta
	_wander_timer -= delta
	_light_timer -= delta
	_life_left -= delta

	# Flies away after a while so it doesn't pile up across waves
	if _life_left <= 0.0:
		queue_free()
		return
	
	if buzz != null and not buzz.playing:
		buzz.play()

	var camera: Camera3D = habitat.get_player_camera()
	if camera == null:
		return

	# Check lights every 0.12s, same as the mosquito
	if _light_timer <= 0.0:
		_light_timer = 0.12
		_light = null
		for source in get_tree().get_nodes_in_group("mosquito_lights"):
			if source.illuminates(global_position):
				_light = source as Node3D
				break

	var speed: float = wander_speed

	if is_instance_valid(_light):
		# Circle around the light source
		speed = light_speed
		_target = _light.global_position + Vector3(
			sin(_time * 3.0 + _phase) * 0.15,
			cos(_time * 2.3 + _phase) * 0.1,
			cos(_time * 3.0 + _phase) * 0.15
		)
	elif _wander_timer <= 0.0 or global_position.distance_to(_target) < 0.1:
		_pick_wander_target(camera.global_position)

	_move_toward(_target, speed, delta, camera.global_position)


func _pick_wander_target(center: Vector3) -> void:
	_wander_timer = randf_range(1.0, 2.5)
	var angle := randf_range(0.0, TAU)
	var radius := randf_range(0.8, 2.5)
	_target = center + Vector3(
		cos(angle) * radius,
		randf_range(-0.5, 0.6),
		sin(angle) * radius
	)


func _move_toward(target: Vector3, speed: float, delta: float, center: Vector3) -> void:
	var motion: Vector3 = (target - global_position).limit_length(speed * delta)
	if motion.length_squared() < 0.000001:
		return

	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _flight_shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.margin = 0.005
	query.motion = motion

	var fractions: PackedFloat32Array = space.cast_motion(query)
	global_position += motion * fractions[0]

	# Hit a wall: pick a new direction right away
	if fractions[0] < 0.99:
		_pick_wander_target(center)
