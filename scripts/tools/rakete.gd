extends HandTool

@export var hit_duration: float = 0.4
@export var attack_cooldown: float = 0.5

@onready var hit_area: Area3D = $Pivot/HitArea

var hit_time_left: float = 0.0
var cooldown_left: float = 0.0
var hit_targets: Dictionary = {}


func _ready() -> void:
	if hit_area == null:
		push_error("Bat: child node 'HitArea' not found.")


func on_trigger_pressed() -> void:
	if cooldown_left > 0.0:
		return

	hit_time_left = hit_duration
	cooldown_left = attack_cooldown
	hit_targets.clear()


func _physics_process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)

	if hit_area == null or hit_time_left <= 0.0:
		return

	for area in hit_area.get_overlapping_areas():
		if not area.is_in_group("mosquito"):
			continue

		if not area.has_method("take_damage"):
			continue

		var target_id: int = area.get_instance_id()

		if hit_targets.has(target_id):
			continue

		hit_targets[target_id] = true
		area.call("take_damage")

	hit_time_left = maxf(0.0, hit_time_left - delta)


func on_unequipped() -> void:
	hit_time_left = 0.0
	hit_targets.clear()
