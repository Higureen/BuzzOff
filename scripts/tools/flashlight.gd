extends HandTool

@onready var light: SpotLight3D = $SpotLight3D

var switched_on: bool = false


func on_trigger_pressed() -> void:
	switched_on = not switched_on
	light.visible = switched_on


func on_unequipped() -> void:
	switched_on = false
	light.visible = false
