class_name DeckViewer
extends ColorRect
## Full-screen deck grid. Modes: "view", "upgrade" (camp), "remove" (market).

signal chosen(index: int)

var mode := "view"


static func open(parent: Node, mode_: String) -> DeckViewer:
	var layer := CanvasLayer.new()
	layer.layer = 20
	parent.add_child(layer)
	var dv := DeckViewer.new()
	dv.mode = mode_
	layer.add_child(dv)
	dv.tree_exited.connect(layer.queue_free)
	return dv


func _ready() -> void:
	color = Color(0.02, 0.03, 0.03, 0.9)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.theme()
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 60
	v.offset_right = -60
	v.offset_top = 30
	v.offset_bottom = -30
	v.add_theme_constant_override("separation", 16)
	add_child(v)
	var head := Label.new()
	head.text = {"view": "Your Deck", "upgrade": "Tend a card (upgrade it)", "remove": "Uproot a card (remove it)"}[mode]
	head.add_theme_font_override("font", UITheme.font("title"))
	head.add_theme_font_size_override("font_size", 44)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var grid := HFlowContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	grid.alignment = FlowContainer.ALIGNMENT_CENTER
	scroll.add_child(grid)
	var deck: Array = Game.run.deck
	for i in deck.size():
		var c: Dictionary = deck[i]
		var show_up: bool = c["up"] or mode == "upgrade"
		var cv := CardView.new().setup(CardDB.get_def(c["id"], show_up), {"uid": i, "id": c["id"], "up": c["up"]})
		var ok := true
		if mode == "upgrade" and c["up"]:
			ok = false
		cv.set_state(ok, false)
		var idx := i
		cv.pressed.connect(func(_cv):
			if mode == "view" or not ok:
				return
			Sfx.play("card")
			chosen.emit(idx)
			queue_free())
		grid.add_child(cv)
	var close := Button.new()
	close.text = "Close" if mode == "view" else "Cancel"
	close.custom_minimum_size = Vector2(240, 56)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(queue_free)
	v.add_child(close)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
