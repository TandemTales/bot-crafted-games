class_name RunConfirmation
extends CanvasLayer
## Explicit, cancellable choices for actions that discard a run or fight.

var previous_focus: Control


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_cancel()


func _cancel() -> void:
	if is_instance_valid(previous_focus):
		previous_focus.grab_focus()
	queue_free()

static func open(parent: Node, heading: String, message: String, action: String, confirmed: Callable) -> CanvasLayer:
	var layer := RunConfirmation.new()
	layer.previous_focus = parent.get_viewport().gui_get_focus_owner()
	layer.name = "RunConfirmation"
	layer.layer = 20
	parent.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.015, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.theme = UITheme.theme()
	layer.add_child(dim)
	var panel := PanelContainer.new()
	UITheme.anchor(panel, Control.PRESET_CENTER, Vector2(-420, -180), Vector2(840, 360))
	panel.add_theme_stylebox_override("panel", UITheme.box(Color(0.04, 0.065, 0.05), UITheme.GOLD, 2, 12, 24))
	dim.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	panel.add_child(box)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)
	var note := Label.new()
	note.text = message
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 28)
	note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(note)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	for text in ["Cancel", action]:
		var button := Button.new()
		button.name = "Cancel" if text == "Cancel" else "Confirm"
		button.text = text
		button.custom_minimum_size = Vector2(0, 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
		if text == "Cancel":
			button.pressed.connect(layer._cancel)
			button.grab_focus()
		else:
			button.pressed.connect(func(): layer.queue_free(); confirmed.call())
	return layer
