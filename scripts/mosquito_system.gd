extends Node3D

const MOSQUITO_SCENE: PackedScene = preload("res://scenes/mosquito.tscn")

@export_range(1, 20) var mosquito_count: int = 3
@export var wave_delay: float = 5.0
@export var min_per_wave: int = 3
@export var max_per_wave: int = 12

var _wave_wait: float = -1.0
var _restarting: bool = false
var _perch_owners: Dictionary = {}

@onready var spawn_points: Node3D = $SpawnPoints
@onready var perch_points: Node3D = $PerchPoints
@onready var mosquitoes: Node3D = $Mosquitoes


func _ready() -> void:
	restart_round()


func restart_round() -> void:
	if _restarting:
		return

	_restarting = true
	_wave_wait = -1.0

	await get_tree().physics_frame
	await get_tree().process_frame

	_perch_owners.clear()

	for enemy in mosquitoes.get_children():
		mosquitoes.remove_child(enemy)
		enemy.queue_free()

	GameManager.start_round(spawn_wave(mosquito_count, 1))
	_restarting = false


func spawn_wave(count: int, wave: int) -> int:
	var points: Array[Node] = spawn_points.get_children()

	if points.is_empty():
		push_warning("Pridėk Marker3D į SpawnPoints.")
		return 0

	var spawned: int = 0
	@warning_ignore("integer_division")
	var fast_count := mini(count / 2, wave - 1)
	var offset: int = randi() % points.size()

	for index in range(count):
		var marker := points[(index + offset) % points.size()] as Node3D
		if marker == null:
			continue

		var enemy: Area3D = MOSQUITO_SCENE.instantiate()
		enemy.habitat = self

		if index < fast_count:
			enemy.is_fast = true
			enemy.approach_speed *= 1.65
			enemy.flee_speed *= 1.25
			enemy.attack_interval *= 0.7

		enemy.position = mosquitoes.to_local(marker.global_position)
		mosquitoes.add_child(enemy)
		spawned += 1

	return spawned


func _process(delta: float) -> void:
	if _restarting or not GameManager.run_active or GameManager.mosquitoes_left > 0:
		return

	if _wave_wait < 0.0:
		_wave_wait = wave_delay

	_wave_wait -= delta

	if _wave_wait <= 0.0:
		_wave_wait = -1.0
		var next_wave: int = GameManager.wave_number + 1
		var count := mini(max_per_wave, min_per_wave + next_wave - 1)
		var spawned := spawn_wave(count, next_wave)

		if spawned > 0:
			GameManager.add_wave(spawned)
		else:
			GameManager.run_active = false


func _exit_tree() -> void:
	GameManager.run_active = false


func _unhandled_key_input(event: InputEvent) -> void:
	if get_tree().root.use_xr:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			restart_round()


func get_player_camera() -> Camera3D:
	return get_viewport().get_camera_3d()


func is_route_clear(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func reserve_perch(enemy: Area3D) -> Marker3D:
	var candidates: Array[Node] = perch_points.get_children()
	candidates.shuffle()

	for candidate in candidates:
		var marker := candidate as Marker3D
		if marker == null:
			continue

		var marker_id := marker.get_instance_id()
		var owner_id: int = _perch_owners.get(marker_id, 0)
		if owner_id != 0 and is_instance_valid(instance_from_id(owner_id)):
			continue

		var landing_position := marker.global_position + Vector3.UP * 0.08
		if not is_route_clear(enemy.global_position, landing_position):
			continue

		_perch_owners[marker_id] = enemy.get_instance_id()
		return marker

	return null


func release_perch(marker: Marker3D, enemy: Area3D) -> void:
	if not is_instance_valid(marker):
		return

	var marker_id := marker.get_instance_id()
	if _perch_owners.get(marker_id, 0) == enemy.get_instance_id():
		_perch_owners.erase(marker_id)
