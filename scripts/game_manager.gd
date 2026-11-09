extends Node

signal game_data_changed

var killed_count: int = 0
var mosquitoes_left: int = 0
var money: int = 0
var current_weapon: String = ""
var shop_open: bool = false
var selected_item: String = "newspaper"

# pradiniai itemai
var unlocked_items: Array[String] = ["ball", "flashlight", "newspaper"]

# priplojimo garsai
const KILL_SOUNDS := {
	"newspaper": {"path": "res://assets/audio/laikrascio.mp3",  "volume": 0.0},
	"mustukas": {"path": "res://assets/audio/mustukas.wav", "volume": 2.0},
	"bat": {"path": "res://assets/audio/nutrenkia.mp3", "volume": -14.0}
}

# parduotuves itemai
const ITEMS := {
	"newspaper": {"name": "Laikraštis", "price": 0},
	"mustukas": {"name": "Muštukas", "price": 200},
	"bat": {"name": "Rakėtė", "price": 600},
	"lamp": {"name": "Lempa", "price": 1000},
}

const SHOP_ORDER := ["newspaper", "mustukas", "bat", "lamp"]

func mosquito_killed(reward: int = 10) -> void:
	if mosquitoes_left > 0:
		mosquitoes_left -= 1
		money += reward
		killed_count += 1
		game_data_changed.emit()
		
func play_kill_sound(weapon: String, pos: Vector3) -> void:
	var info: Dictionary = KILL_SOUNDS.get(weapon, {})
	var path: String = info.get("path", "")
	if path == "" or not ResourceLoader.exists(path):
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
	
func start_round(count: int) -> void:
	mosquitoes_left = maxi(count, 0)
	killed_count = 0
	money = 1000
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

# wave spawninimas
func add_wave(count: int) -> void:
	mosquitoes_left += maxi(count, 0)
	game_data_changed.emit()
