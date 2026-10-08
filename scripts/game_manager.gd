extends Node

signal game_data_changed

var mosquitoes_left: int = 6
var money: int = 0
var current_weapon: String = "Musgaudis"


func mosquito_killed(reward: int = 10) -> void:
	if mosquitoes_left > 0:
		mosquitoes_left -= 1
		money += reward
		game_data_changed.emit()


func change_weapon(new_weapon: String) -> void:
	current_weapon = new_weapon
	game_data_changed.emit()
