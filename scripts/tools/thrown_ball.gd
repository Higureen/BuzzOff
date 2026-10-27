extends RigidBody3D

@export var disappear_on_hit: bool = true

@onready var hit_area: Area3D = $HitArea

var hit_targets: Dictionary = {}


func _ready() -> void:
	if hit_area == null:
		push_error("ThrownBall: child node 'HitArea' not found.")
		return
	hit_area.area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	print("ThrownBall touched: ", area.name)

	if not area.is_in_group("mosquito"):
		return

	if not area.has_method("take_damage"):
		return

	var target_id: int = area.get_instance_id()
	if hit_targets.has(target_id):
		return

	hit_targets[target_id] = true
	area.call("take_damage")

	if disappear_on_hit:
		queue_free()
