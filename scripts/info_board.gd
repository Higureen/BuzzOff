extends Node3D
@onready var title_label: Label3D = $TitleLabel
#@onready var weapon_label: Label3D = $WeaponLabel
@onready var mosquito_label: Label3D = $MosquitoLabel
@onready var money_label: Label3D = $MoneyLabel
@onready var killed_label: Label3D = $KilledLabel
@onready var time_label: Label3D = $TimeLabel

#@onready var equipment_manager: Node = (
	#get_tree().get_first_node_in_group("equipment_manager")
#)


func _ready() -> void:
	GameManager.game_data_changed.connect(update_board)
#
	#if is_instance_valid(equipment_manager):
		#equipment_manager.equipment_changed.connect(update_board)

	update_board()


func update_board() -> void:
	title_label.text = "Gyvybės: %d/%d   Banga: %d" % [
		GameManager.health,
		GameManager.MAX_HEALTH,
		GameManager.wave_number,
	]

	#var hands: Array[String] = ["", ""]
#
	#if is_instance_valid(equipment_manager):
		#hands = equipment_manager.equipped_ids
		
	time_label.text = "Laikas: " + str(GameManager.format_time(int(GameManager.elapsed_time)))
	mosquito_label.text = "Uodai liko: " + str(GameManager.mosquitoes_left)
	money_label.text = "Pinigai: " + str(GameManager.money)
	killed_label.text = "Nukauti uodai: " + str(GameManager.killed_count)


#func tool_display_name(tool_id: String) -> String:
	#match tool_id:
		#"flashlight":
			#return "Žibintuvėlis"
		#"newspaper":
			#return "Laikraštis"
		#"":
			#return "Tuščia"
		#_:
			#return tool_id
