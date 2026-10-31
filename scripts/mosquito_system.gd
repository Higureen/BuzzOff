extends Node3D

const MOSQUITO_SCENE: PackedScene = preload(
	"res://scenes/mosquito.tscn"
)

@export_range(1, 20) var mosquito_count: int = 6

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

	# palaukiam fizikos pasaulio ir aktyvios kameros
	await get_tree().physics_frame
	await get_tree().process_frame

	_perch_owners.clear()

	for enemy in mosquitoes.get_children():
		mosquitoes.remove_child(enemy)
		enemy.queue_free()

	var points: Array[Node] = spawn_points.get_children()
	var spawned: int = 0

	if points.is_empty():
		push_warning("pridek Marker3D i SpawnPoints.")
	else:
		for index in range(mosquito_count):
			var marker: Node3D = (
				points[index % points.size()] as Node3D
			)

			if marker == null:
				continue

			var enemy: Area3D = MOSQUITO_SCENE.instantiate()

			enemy.habitat = self
			enemy.position = mosquitoes.to_local(
				marker.global_position
			)

			mosquitoes.add_child(enemy)
			spawned += 1

	GameManager.start_round(spawned)
	_restarting = false


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

	return get_world_3d().direct_space_state.intersect_ray(
		query
	).is_empty()


func reserve_perch(enemy: Area3D) -> Marker3D:
	var candidates: Array[Node] = perch_points.get_children()
	candidates.shuffle()

	for candidate in candidates:
		var marker: Marker3D = candidate as Marker3D

		if marker == null:
			continue

		var owner_id: int = _perch_owners.get(
			marker.get_instance_id(), 0
		)

		if owner_id != 0:
			if is_instance_valid(instance_from_id(owner_id)):
				continue

		var landing_position: Vector3 = (
			marker.global_position + Vector3.UP * 0.08
		)

		if not is_route_clear(
			enemy.global_position, landing_position
		):
			continue

		_perch_owners[marker.get_instance_id()] = (
			enemy.get_instance_id()
		)

		return marker

	return null


func release_perch(marker: Marker3D, enemy: Area3D) -> void:
	if not is_instance_valid(marker):
		return

	if _perch_owners.get(marker.get_instance_id(), 0) == (
		enemy.get_instance_id()
	):
		_perch_owners.erase(marker.get_instance_id())
