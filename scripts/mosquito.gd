extends Area3D

enum State { APPROACH, FLEE, LANDING, RESTING }

@export var approach_speed: float = 0.45
@export var flee_speed: float = 1.8
@export var reward: int = 10

var habitat: Node
var is_dead: bool = false
var state: State = State.APPROACH

var _time: float = 0.0
var _phase: float = 0.0
var _timer: float = 4.0
var _light_timer: float = 0.0

var _threat: Node3D
var _perch: Marker3D
var _landing_target: Vector3

var _avoid_target: Vector3
var _avoid_timer: float = 0.0

var _flight_shape: SphereShape3D = SphereShape3D.new()

@onready var buzz: AudioStreamPlayer3D = $Buzz
@onready var wings: Node3D = $Wings


func _ready() -> void:
	add_to_group("mosquito")

	# Uodas nebemirsta vien paspaudus ant jo.
	input_ray_pickable = false

	_flight_shape.radius = 0.05
	_phase = randf_range(0.0, TAU)
	_timer = randf_range(4.0, 8.0)

	buzz.pitch_scale = randf_range(0.94, 1.06)


func take_damage() -> void:
	if is_dead:
		return

	is_dead = true
	_release_perch()
	buzz.stop()

	GameManager.mosquito_killed(reward)
	queue_free()


func _physics_process(delta: float) -> void:
	if is_dead or habitat == null:
		return

	_time += delta
	_timer -= delta
	_avoid_timer -= delta
	_light_timer -= delta

	# sviesa tikriname kas 0,12 sekundes
	if _light_timer <= 0.0:
		_light_timer = 0.12
		_threat = null

		for source in get_tree().get_nodes_in_group(
			"mosquito_lights"
		):
			if source.illuminates(global_position):
				_threat = source as Node3D
				break

		if is_instance_valid(_threat):
			_release_perch()

			if state != State.FLEE:
				_avoid_timer = 0.0

			state = State.FLEE
			_timer = 1.5

	if state == State.RESTING:
		buzz.stop()
		wings.rotation.z = 0.0

		if _timer <= 0.0:
			_release_perch()
			_start_approach()

		return

	if not buzz.playing:
		buzz.play()

	wings.rotation.z = sin(
		_time * 95.0 + _phase
	) * 0.35

	var camera: Camera3D = habitat.get_player_camera()

	if camera == null:
		return

	var target: Vector3
	var speed: float = approach_speed

	match state:
		State.FLEE:
			if _timer <= 0.0:
				_start_approach()
				return

			var origin: Vector3 = camera.global_position

			if is_instance_valid(_threat):
				origin = _threat.global_position

			var away: Vector3 = global_position - origin
			away.y = 0.0
			if away.length_squared() < 0.001:
				away = Vector3(
					sin(_phase),
					0.0,
					cos(_phase)
				)

			away = away.normalized()

			# kiekvienas uodas renkasi kiek kitoki pabegimo sona
			var side: Vector3 = Vector3.UP.cross(away)
			var side_amount: float = sin(_phase) * 0.7

			var escape_direction: Vector3 = (
				away + side * side_amount
			).normalized()

			target = global_position + escape_direction * 2.0
			speed = flee_speed

		State.LANDING:
			target = _landing_target

			if global_position.distance_to(target) < 0.04:
				state = State.RESTING
				_timer = randf_range(2.0, 5.0)
				buzz.stop()
				return

			if _timer <= 0.0:
				_release_perch()
				_start_approach()
				return

		_:
			# arteja prie galvos, taciau neskrenda tiesiai i ja
			target = camera.global_position + Vector3(
				sin(_time * 0.8 + _phase) * 0.65,
				sin(_time * 1.3 + _phase) * 0.12,
				cos(_time * 0.8 + _phase) * 0.65
			)

			if _timer <= 0.0:
				_perch = habitat.reserve_perch(self)

				if is_instance_valid(_perch):
					state = State.LANDING

					_landing_target = (
						_perch.global_position
						+ Vector3.UP * 0.08
					)

					_timer = (
						global_position.distance_to(
							_landing_target
						) / maxf(approach_speed, 0.1)
						+ 3.0
					)
				else:
					_timer = randf_range(3.0, 6.0)

	if _avoid_timer > 0.0:
		target = _avoid_target

	_move_toward(target, speed, delta)


func _move_toward(
	target: Vector3,
	speed: float,
	delta: float
) -> void:
	var space: PhysicsDirectSpaceState3D = (
		get_world_3d().direct_space_state
	)

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _flight_shape
	query.transform = Transform3D(
		Basis.IDENTITY, global_position
	)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.margin = 0.005

	# jei jau istriges pavirsiuj, bandome is jo istrukt
	var contact: Dictionary = space.get_rest_info(query)

	if not contact.is_empty():
		var escape_direction: Vector3 = contact["normal"]

		if escape_direction.length_squared() < 0.001:
			escape_direction = (
				target - global_position
			).normalized()

		for step in range(1, 9):
			var candidate: Vector3 = (
				global_position
				+ escape_direction * float(step) * 0.04
			)

			query.transform = Transform3D(
				Basis.IDENTITY, candidate
			)

			if space.intersect_shape(query, 1).is_empty():
				global_position = candidate
				_avoid_target = (
					candidate + escape_direction * 0.4
				)
				_avoid_timer = 0.8
				return

		return

	var motion: Vector3 = (
		target - global_position
	).limit_length(speed * delta)

	if motion.length_squared() < 0.000001:
		return

	var start: Vector3 = global_position
	query.motion = motion

	var fractions: PackedFloat32Array = space.cast_motion(query)
	global_position += motion * fractions[0]

	if fractions[0] < 0.99:
		# randam pav krypti ir traukiames nuo jo
		query.motion = Vector3.ZERO
		query.transform = Transform3D(
			Basis.IDENTITY,
			start + motion * fractions[1]
		)

		contact = space.get_rest_info(query)

		var normal: Vector3 = -motion.normalized()

		if not contact.is_empty():
			var surface_normal: Vector3 = contact["normal"]

			if surface_normal.length_squared() > 0.001:
				normal = surface_normal.normalized()

		_avoid_target = global_position + normal * 0.5
		_avoid_timer = 0.8


func _start_approach() -> void:
	state = State.APPROACH
	_timer = randf_range(5.0, 9.0)
	_avoid_timer = 0.0


func _release_perch() -> void:
	if habitat != null and is_instance_valid(_perch):
		habitat.release_perch(_perch, self)

	_perch = null
