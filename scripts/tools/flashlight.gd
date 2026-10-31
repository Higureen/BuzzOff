extends HandTool

@onready var light: SpotLight3D = $SpotLight3D

var switched_on: bool = false


func _ready() -> void:
	add_to_group("mosquito_lights")
	light.visible = switched_on


func on_trigger_pressed() -> void:
	switched_on = not switched_on
	light.visible = switched_on

	print(
		"Žibintuvėlis: ", switched_on,
		" | Matomas: ", light.is_visible_in_tree()
	)

func on_unequipped() -> void:
	switched_on = false
	light.visible = false


func illuminates(target: Vector3) -> bool:
	if not switched_on or not light.is_visible_in_tree():
		return false

	var offset: Vector3 = target - light.global_position
	var distance: float = offset.length()

	if distance > light.spot_range:
		return false

	if distance < 0.001:
		return true

	# ar taskas patenka i zibintuvelio spinduli?
	var forward: Vector3 = -light.global_basis.z.normalized()
	var angle_limit: float = cos(deg_to_rad(light.spot_angle))

	if forward.dot(offset / distance) < angle_limit:
		return false

	# ar tarp zibintuvelio ir uodo nera sienos/baldo?
	var query := PhysicsRayQueryParameters3D.create(
		light.global_position,
		target,
		1
	)

	query.collide_with_areas = false

	return get_world_3d().direct_space_state.intersect_ray(
		query
	).is_empty()
