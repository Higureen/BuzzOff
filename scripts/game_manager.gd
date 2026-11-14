extends Node

signal game_data_changed
signal run_ended

const MAX_HEALTH: int = 5
const BITE_COOLDOWN: float = 2.0
const SCORE_PATH := "user://scores.cfg"
const HISTORY_LIMIT: int = 5

const KILL_SOUNDS := {
	"newspaper": {"path": "res://assets/audio/laikrascio.mp3", "volume": 0.0},
	"mustukas": {"path": "res://assets/audio/mustukas.wav", "volume": 2.0},
	"bat": {"path": "res://assets/audio/nutrenkia.mp3", "volume": -14.0}
}

const ITEMS := {
	"newspaper": {"name": "Laikraštis", "price": 0},
	"mustukas": {"name": "Muštukas", "price": 200},
	"bat": {"name": "Rakėtė", "price": 600},
	"lamp": {"name": "Lempa", "price": 1000},
}

const SHOP_ORDER := ["newspaper", "mustukas", "bat", "lamp"]

var health: int = MAX_HEALTH
var elapsed_time: float = 0.0
var wave_number: int = 0
var run_active: bool = false
var high_score: int = 0
var score_history: Array[Dictionary] = []

var killed_count: int = 0
var mosquitoes_left: int = 0
var money: int = 0
var current_weapon: String = ""
var shop_open: bool = false
var selected_item: String = "newspaper"
var unlocked_items: Array[String] = ["ball", "flashlight", "newspaper"]

var _bite_cooldown_left: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	var save := ConfigFile.new()
	if save.load(SCORE_PATH) != OK:
		return

	high_score = int(save.get_value("scores", "best", 0))
	var history: Variant = save.get_value("scores", "history", [])

	if history is Array:
		for row in history:
			if row is Dictionary and score_history.size() < HISTORY_LIMIT:
				score_history.append(row)


func _physics_process(delta: float) -> void:
	if not run_active:
		return

	var previous_second := int(elapsed_time)
	elapsed_time += delta
	_bite_cooldown_left = maxf(0.0, _bite_cooldown_left - delta)

	if int(elapsed_time) != previous_second:
		game_data_changed.emit()


func start_round(count: int) -> void:
	mosquitoes_left = maxi(count, 0)
	health = MAX_HEALTH
	elapsed_time = 0.0
	wave_number = 1
	_bite_cooldown_left = 0.0
	run_active = count > 0
	killed_count = 0
	money = 1000
	game_data_changed.emit()


func add_wave(count: int) -> void:
	if not run_active or count <= 0:
		return

	wave_number += 1
	mosquitoes_left += count
	game_data_changed.emit()


func mosquito_killed(reward: int = 10) -> void:
	if not run_active or mosquitoes_left <= 0:
		return

	mosquitoes_left -= 1
	money += reward
	killed_count += 1
	game_data_changed.emit()


func try_bite_player() -> bool:
	if not run_active or _bite_cooldown_left > 0.0:
		return false

	_bite_cooldown_left = BITE_COOLDOWN
	health -= 1

	if health == 0:
		run_active = false
		_save_result()

	game_data_changed.emit()

	if not run_active:
		run_ended.emit()

	return true


func _save_result() -> void:
	high_score = maxi(high_score, killed_count)

	score_history.push_front({
		"kills": killed_count,
		"seconds": int(elapsed_time),
		"wave": wave_number,
	})

	if score_history.size() > HISTORY_LIMIT:
		score_history.pop_back()

	var save := ConfigFile.new()
	save.set_value("scores", "best", high_score)
	save.set_value("scores", "history", score_history)

	if save.save(SCORE_PATH) != OK:
		push_warning("Nepavyko išsaugoti BuzzOff rezultatų.")


func format_time(seconds: int) -> String:
	@warning_ignore("integer_division")
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func score_summary() -> String:
	var lines := PackedStringArray(["Rekordas: %d uodai" % high_score])

	if score_history.is_empty():
		lines.append("Baigtų partijų dar nėra")
	else:
		lines.append("Paskutinės partijos: uodai / laikas / banga")
		for row in score_history:
			lines.append("%d   /   %s   /   %d" % [
				int(row.get("kills", 0)),
				format_time(int(row.get("seconds", 0))),
				int(row.get("wave", 0)),
			])

	return "\n".join(lines)


func play_kill_sound(weapon: String, pos: Vector3) -> void:
	var info: Dictionary = KILL_SOUNDS.get(weapon, {})
	var path: String = info.get("path", "")

	if path.is_empty() or not ResourceLoader.exists(path):
		return

	var player := AudioStreamPlayer3D.new()
	player.stream = load(path)
	player.volume_db = info.get("volume", 0.0)
	get_tree().current_scene.add_child(player)
	player.global_position = pos
	player.finished.connect(player.queue_free)
	player.play()


func change_weapon(new_weapon: String) -> void:
	current_weapon = new_weapon
	game_data_changed.emit()


func is_unlocked(id: String) -> bool:
	return id in unlocked_items


func buy_item(id: String) -> bool:
	if not ITEMS.has(id) or is_unlocked(id):
		return false

	if not ITEMS[id].get("available", true):
		return false

	var price: int = ITEMS[id]["price"]
	if money < price:
		return false

	money -= price
	unlocked_items.append(id)
	game_data_changed.emit()
	return true
