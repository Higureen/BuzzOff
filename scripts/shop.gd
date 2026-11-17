extends Control

signal closed

@onready var money_label: Label = $MoneyLabel
@onready var equipment_manager: Node = (
	get_tree().get_first_node_in_group("equipment_manager")
)

var item_ids: Array = GameManager.SHOP_ORDER
var buttons: Array[Button] = []

var nav_buttons: Array[Button] = []
var nav_index: int = 0
var stick_latched: bool = false
var trigger_down: bool = true
var hands: Array[XRController3D] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if has_node("BackButton"):
		$BackButton.pressed.connect(func(): closed.emit())
	else:
		push_warning("Shop: BackButton not found")

	if equipment_manager == null:
		push_warning("Shop: equipment_manager not found (check its group)")

	# Surenka visų ItemBox informaciją
	var boxes: Array = []
	for child in get_children():
		if child is HBoxContainer:
			boxes.append_array(child.get_children())

	for i in boxes.size():
		if i >= item_ids.size():
			boxes[i].visible = false
			continue

		var id: String = item_ids[i]
		var label: Label = boxes[i].find_child("Label", true, false)
		var button: Button = boxes[i].find_child("Button", true, false)

		if label == null or button == null:
			push_warning("Shop: box %d is missing Label or Button" % i)
			continue

		label.text = GameManager.ITEMS[id]["name"]
		buttons.append(button)
		button.pressed.connect(_on_button_pressed.bind(id))

	GameManager.game_data_changed.connect(refresh)
	if equipment_manager:
		equipment_manager.equipment_changed.connect(refresh)
	refresh()

	for hand_name in ["LeftHand", "RightHand"]:
		var node := get_tree().current_scene.find_child(hand_name, true, false)
		if node is XRController3D:
			hands.append(node)

	nav_buttons.append_array(buttons)
	if has_node("BackButton"):
		nav_buttons.append($BackButton)
	nav_index = 0
	_highlight()

	GameManager.shop_open = true


func _exit_tree() -> void:
	GameManager.shop_open = false


func refresh() -> void:
	money_label.text = "Money: %d$" % GameManager.money

	for i in buttons.size():
		var id: String = item_ids[i]
		var info: Dictionary = GameManager.ITEMS[id]
		var button := buttons[i]

		if not GameManager.is_unlocked(id) and not GameManager.requirement_met(id):
			button.text = "Locked"
			button.disabled = true
		elif not GameManager.is_unlocked(id):
			button.text = "Buy %d$" % info["price"]
			button.disabled = GameManager.money < info["price"]
		elif equipment_manager and id in equipment_manager.equipped_ids:
			button.text = "Equipped"
			button.disabled = false
		else:
			button.text = "Equip"
			button.disabled = false


func _on_button_pressed(id: String) -> void:
	if not GameManager.is_unlocked(id):
		GameManager.buy_item(id)
	elif equipment_manager and not id in equipment_manager.equipped_ids:
		GameManager.selected_item = id
		equipment_manager.equip_only(id)


func _highlight() -> void:
	if nav_buttons.is_empty():
		return
	nav_buttons[nav_index].grab_focus()


func _process(_delta: float) -> void:
	if nav_buttons.is_empty():
		return

	var stick := Vector2.ZERO
	var trigger := 0.0

	for c in hands:
		if c.get_is_active():
			var s := c.get_vector2("primary")
			if s.length() > stick.length():
				stick = s
			trigger = maxf(trigger, c.get_float("trigger"))

	if absf(stick.x) < 0.25:
		stick_latched = false
	elif absf(stick.x) > 0.65 and not stick_latched:
		stick_latched = true
		var dir := 1 if stick.x > 0.0 else -1
		nav_index = wrapi(nav_index + dir, 0, nav_buttons.size())
		_highlight()

	if trigger <= 0.25:
		trigger_down = false
	elif trigger >= 0.75 and not trigger_down:
		trigger_down = true
		var button := nav_buttons[nav_index]
		if not button.disabled:
			button.pressed.emit()
