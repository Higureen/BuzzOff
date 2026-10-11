class_name HandToolSlot
extends Node3D

var current_tool: HandTool
var controller: XRController3D
var trigger_down: bool = true
var input_blocked: bool = false

func _ready() -> void:
	controller = get_parent() as XRController3D


func _process(_delta: float) -> void:
	if input_blocked:
		if current_tool:
			current_tool.trigger_released()

		trigger_down = true
		return
	if controller == null:
		return

	if not controller.get_is_active() or not XRToolsStartXR.is_xr_active():
		if current_tool:
			current_tool.trigger_released()

		trigger_down = true
		return

	var trigger_value: float = controller.get_float("trigger")

	if trigger_value >= 0.75 and not trigger_down:
		trigger_down = true

		if current_tool:
			current_tool.trigger_pressed()

	elif trigger_value <= 0.25 and trigger_down:
		trigger_down = false

		if current_tool:
			current_tool.trigger_released()


func equip_tool(tool_scene: PackedScene) -> void:
	if tool_scene == null:
		clear_tool()
		return

	var instance: Node = tool_scene.instantiate()

	if not instance is HandTool:
		push_error("Įrankio scena turi paveldėti HandTool.")
		instance.free()
		return

	clear_tool()

	current_tool = instance as HandTool
	add_child(current_tool)
	current_tool.transform = Transform3D.IDENTITY

	trigger_down = true


func clear_tool() -> void:
	if current_tool:
		current_tool.unequip()
		remove_child(current_tool)
		current_tool.queue_free()
		current_tool = null

	trigger_down = true
