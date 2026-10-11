extends Node

signal game_data_changed

var killed_count: int = 0
var mosquitoes_left: int = 6
var money: int = 0
var current_weapon: String = ""


func mosquito_killed(reward: int = 10) -> void:
	if mosquitoes_left > 0:
		mosquitoes_left -= 1
		money += reward
		killed_count += 1
		game_data_changed.emit()


func change_weapon(new_weapon: String) -> void:
	current_weapon = new_weapon
	game_data_changed.emit()
