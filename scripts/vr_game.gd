extends Node3D

@onready var pause_menu = $PauseMenu

func _ready() -> void:
	pause_menu.hide()
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("menu_button"):
		if pause_menu.visible:
			pause_menu.resume()
		else:
			pause_menu.pause()
