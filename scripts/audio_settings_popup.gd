extends Control

var _hidden_controls: Array[Control] = []
var _previous_focus: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBoxContainer/Back.pressed.connect(close)
	hide()


func open() -> void:
	if visible:
		return

	_previous_focus = get_viewport().gui_get_focus_owner()
	_hidden_controls.clear()

	for node_name in ["VBoxContainer", "Label"]:
		var control := get_parent().get_node_or_null(node_name) as Control

		if control != null and control.visible:
			_hidden_controls.append(control)
			control.hide()

	get_parent().set_meta("active_menu", self)

	show()
	$VBoxContainer/MasterVolume.grab_focus()


func close() -> void:
	if not visible:
		return

	hide()

	if get_parent().get_meta("active_menu", null) == self:
		get_parent().remove_meta("active_menu")

	for control in _hidden_controls:
		if is_instance_valid(control):
			control.show()

	_hidden_controls.clear()

	if is_instance_valid(_previous_focus):
		_previous_focus.grab_focus()
