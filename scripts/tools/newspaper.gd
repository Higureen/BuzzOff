extends HandTool

@export var hit_duration: float = 0.4
@export var attack_cooldown: float = 0.8
@export var min_kill_speed: float = 2.5   # m/s, tune this

@onready var hit_area: Area3D = $HitArea

var hit_time_left: float = 0.0
var cooldown_left: float = 0.0
var hit_targets: Dictionary = {}
var flinched_targets: Dictionary = {}

var _last_pos: Vector3
var _speed_history: Array[float] = []


func _ready() -> void:
	_last_pos = hit_area.global_position


func on_trigger_pressed() -> void:
	if cooldown_left > 0.0:
		return

	hit_time_left = hit_duration
	cooldown_left = attack_cooldown
	hit_targets.clear()
	flinched_targets.clear()


func _physics_process(delta: float) -> void:
	_track_speed(delta)
	cooldown_left = maxf(0.0, cooldown_left - delta)

	if hit_time_left <= 0.0:
		return

	var speed: float = _recent_speed()

	for area in hit_area.get_overlapping_areas():
		if not area.is_in_group("mosquito"):
			continue

		if not area.has_method("take_damage"):
			continue

		var target_id: int = area.get_instance_id()

		if hit_targets.has(target_id):
			continue

		if speed >= min_kill_speed:
			hit_targets[target_id] = true
			area.call("take_damage", "newspaper")
		elif not flinched_targets.has(target_id):
			# Too weak: scare it, but allow a harder hit later in this swing
			flinched_targets[target_id] = true
			if area.has_method("flinch"):
				area.call("flinch")
			print("too weak: ", snappedf(speed, 0.01))

	hit_time_left = maxf(0.0, hit_time_left - delta)


func _track_speed(delta: float) -> void:
	var pos: Vector3 = hit_area.global_position
	_speed_history.push_back(pos.distance_to(_last_pos) / maxf(delta, 0.0001))
	_last_pos = pos

	if _speed_history.size() > 6:   # ~0.1 s of history
		_speed_history.pop_front()


# Peak speed over the last few frames, because the tool often slows
# down at the moment of contact.
func _recent_speed() -> float:
	return _speed_history.max() if not _speed_history.is_empty() else 0.0


func on_unequipped() -> void:
	hit_time_left = 0.0
	hit_targets.clear()
	flinched_targets.clear()
