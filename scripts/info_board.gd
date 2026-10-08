extends Node3D

@onready var weapon_label: Label3D = $WeaponLabel
@onready var mosquito_label: Label3D = $MosquitoLabel
@onready var money_label: Label3D = $MoneyLabel


func _ready() -> void:
	GameManager.game_data_changed.connect(update_board)
	update_board()


func update_board() -> void:
	weapon_label.text = "Ginklas: " + GameManager.current_weapon
	mosquito_label.text = "Uodai liko: " + str(GameManager.mosquitoes_left)
	money_label.text = "Pinigai: " + str(GameManager.money)
