extends Node

signal equipment_changed

const TOOL_SCENES: Dictionary = {
	"flashlight": preload("res://scenes/tools/flashlight.tscn"),
	"newspaper": preload("res://scenes/tools/newspaper.tscn")
}

var active_hand: int = -1
var selected_index: int = 0
var menu_options: Array[String] = []
var stick_latched: bool = false
var menu_trigger_down: bool = true
var previous_movement_enabled: bool = true

@onready var left_controller: XRController3D = (
	$"../XROrigin3D/LeftHand"
)

@onready var right_controller: XRController3D = (
	$"../XROrigin3D/RightHand"
)

@onready var menu_label: Label3D = (
	$"../XROrigin3D/XRCamera3D/EquipmentMenu"
)

@onready var movement: XRToolsMovementDirect = (
	$"../XROrigin3D/LeftHand/MovementDirect"
)
func _ready() -> void:
	left_controller.button_pressed.connect(
		_on_controller_button.bind(0)
	)

	right_controller.button_pressed.connect(
		_on_controller_button.bind(1)
	)

	menu_label.visible = false
# turimi daiktai, rankos pradzioje tuscios
var owned_tools: Array[String] = ["flashlight", "newspaper"]
var equipped_ids: Array[String] = ["", ""]

@onready var left_slot: HandToolSlot = (
	$"../XROrigin3D/LeftHand/ToolSlot"
)

@onready var right_slot: HandToolSlot = (
	$"../XROrigin3D/RightHand/ToolSlot"
)


# hand: 0 – kaire, 1 – desine
# tuscias tool_id nuima iranki
func equip(hand: int, tool_id: String) -> void:
	if hand < 0 or hand > 1:
		return

	if tool_id != "":
		if not owned_tools.has(tool_id):
			return

		if not TOOL_SCENES.has(tool_id):
			return

	if equipped_ids[hand] == tool_id:
		return

	var other_hand: int = 1 - hand

	# vienas daiktas negali buti abiiejose rankose
	if tool_id != "" and equipped_ids[other_hand] == tool_id:
		_get_slot(other_hand).clear_tool()
		equipped_ids[other_hand] = ""

	var slot: HandToolSlot = _get_slot(hand)

	if tool_id == "":
		slot.clear_tool()
	else:
		var scene: PackedScene = TOOL_SCENES[tool_id]
		slot.equip_tool(scene)

	equipped_ids[hand] = tool_id
	equipment_changed.emit()


func swap_hands() -> void:
	var left_id: String = equipped_ids[0]
	var right_id: String = equipped_ids[1]

	left_slot.clear_tool()
	right_slot.clear_tool()
	equipped_ids[0] = ""
	equipped_ids[1] = ""

	equip(0, right_id)
	equip(1, left_id)


func _get_slot(hand: int) -> HandToolSlot:
	return left_slot if hand == 0 else right_slot
	
func _on_controller_button(button: String, hand: int) -> void:
	if hand == 1 and button == "by_button":
		return
	if get_tree().paused:
		return
		
	if not XRToolsStartXR.is_xr_active():
		return

	if button == "ax_button":
		if active_hand == hand:
			_close_menu()
		else:
			_open_menu(hand)

	elif button == "by_button":
		_close_menu()
		swap_hands()


func _open_menu(hand: int) -> void:
	if active_hand == -1:
		previous_movement_enabled = movement.enabled

	active_hand = hand
	selected_index = 0
	stick_latched = false
	menu_trigger_down = true

	menu_options.clear()
	menu_options.append("")
	menu_options.append_array(owned_tools)
	menu_options.append("@swap")

	left_slot.input_blocked = true
	right_slot.input_blocked = true
	movement.enabled = false

	menu_label.visible = true
	_refresh_menu()


func _close_menu() -> void:
	if active_hand == -1:
		return

	active_hand = -1
	menu_label.visible = false

	left_slot.input_blocked = false
	right_slot.input_blocked = false
	movement.enabled = previous_movement_enabled


func _process(_delta: float) -> void:
	if active_hand == -1:
		return

	var controller: XRController3D = (
		left_controller if active_hand == 0 else right_controller
	)

	if not controller.get_is_active() or not XRToolsStartXR.is_xr_active():
		_close_menu()
		return

	var stick: Vector2 = controller.get_vector2("primary")

	if absf(stick.y) < 0.25:
		stick_latched = false

	elif absf(stick.y) > 0.65 and not stick_latched:
		stick_latched = true

		var direction: int = -1 if stick.y > 0.0 else 1
		selected_index = wrapi(
			selected_index + direction,
			0,
			menu_options.size()
		)

		_refresh_menu()

	var trigger: float = controller.get_float("trigger")

	if trigger <= 0.25:
		menu_trigger_down = false

	elif trigger >= 0.75 and not menu_trigger_down:
		menu_trigger_down = true

		var choice: String = menu_options[selected_index]

		if choice == "@swap":
			swap_hands()
		else:
			equip(active_hand, choice)

		_close_menu()


func _refresh_menu() -> void:
	var title: String = (
		"KAIRĖ RANKA" if active_hand == 0 else "DEŠINĖ RANKA"
	)

	menu_label.text = title + "\n\n"

	for index in range(menu_options.size()):
		var tool_id: String = menu_options[index]
		var display_name: String = tool_id

		match tool_id:
			"":
				display_name = "Tuščia"
			"flashlight":
				display_name = "Žibintuvėlis"
			"newspaper":
				display_name = "Laikraštis"
			"@swap":
				display_name = "Sukeisti rankas"

		var prefix: String = "> " if index == selected_index else "  "
		menu_label.text += prefix + display_name + "\n"

	menu_label.text += "\nSvirtelė ↑↓ – pasirinkti"
	menu_label.text += "\nTrigeris – patvirtinti"
	menu_label.text += "\nX / A – uždaryti"


func close_menu() -> void:
	_close_menu()
