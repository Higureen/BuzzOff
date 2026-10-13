extends Node3D

@onready var weapon_label: Label3D = $WeaponLabel
@onready var mosquito_label: Label3D = $MosquitoLabel
@onready var money_label: Label3D = $MoneyLabel
@onready var killed_label: Label3D = $KilledLabel

@onready var equipment_manager: Node = (
	get_tree().get_first_node_in_group("equipment_manager")
)


func _ready() -> void:
	GameManager.game_data_changed.connect(update_board)

	if is_instance_valid(equipment_manager):
		equipment_manager.equipment_changed.connect(update_board)

	update_board()


func update_board() -> void:
	var hands: Array[String] = ["", ""]

	if is_instance_valid(equipment_manager):
		hands = equipment_manager.equipped_ids

	weapon_label.text = "Kairė: " + tool_display_name(hands[0])
	weapon_label.text += "\nDešinė: " + tool_display_name(hands[1])

	mosquito_label.text = (
		"Uodai liko: " + str(GameManager.mosquitoes_left)
	)
	money_label.text = "Pinigai: " + str(GameManager.money)
	killed_label.text = (
		"Nukauti uodai: " + str(GameManager.killed_count)
	)


func tool_display_name(tool_id: String) -> String:
	match tool_id:
		"flashlight":
			return "Žibintuvėlis"
		"newspaper":
			return "Laikraštis"
		"":
			return "Tuščia"
		_:
			return tool_id
