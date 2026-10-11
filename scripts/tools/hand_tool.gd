class_name HandTool
extends Node3D

@export var tool_name: String = "Įrankis"

var trigger_held: bool = false


func trigger_pressed() -> void:
	if trigger_held:
		return

	trigger_held = true
	on_trigger_pressed()


func trigger_released() -> void:
	if not trigger_held:
		return

	trigger_held = false
	on_trigger_released()


func unequip() -> void:
	trigger_released()
	on_unequipped()


func _process(delta: float) -> void:
	if trigger_held:
		on_trigger_held(delta)


# konkretiem irankiam
func on_trigger_pressed() -> void:
	pass


func on_trigger_released() -> void:
	pass


func on_trigger_held(_delta: float) -> void:
	pass


func on_unequipped() -> void:
	pass
