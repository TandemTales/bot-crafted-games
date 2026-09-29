extends Node3D
## Title screen: a live diorama of the Mire Mother's lair behind the menu.

var rig: CameraRig
var _t := 0.0
var _continue_btn: Button
var _new_btn: Button


func _ready() -> void:
	BoardView.make_environment(self)
	var c := CombatState.new()
	var enc := EncounterDB.get_def("ash_mother")
	enc["thicket"] = [[0, 4], [1, 3], [0, 3], [-1, 4], [1, 2], [-1, 3], [2, 2]]
	enc["enemies"] = [["mire_mother", 0, -3], ["blightling", -2, -1], ["rotmoth", 2, -2], ["blightling", 1, -1]]
	c.setup(enc, [{"id": "thornstrike", "up": false}], 72, 72, [], Rng.new(3))
	var board := BoardView.new()
	add_child(board)
	board.build(c, 77)
	rig = CameraRig.new()
	rig.pitch_deg = 30.0
	rig.distance = 13.0
	rig.yaw_limit_deg = 180
	add_child(rig)
	rig.set_process_unhandled_input(false)
	rig.camera.h_offset = -3.2
	_build_ui()
	Sfx.play_music("title")


func _process(delta: float) -> void:
	_t += delta
	rig._yaw_goal = 0.55 + sin(_t * 0.08) * 0.35


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var shade := TextureRect.new()
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.82))
	g.set_color(1, Color(0, 0, 0, 0.0))
	grad.gradient = g
	grad.fill_from = Vector2(0, 0.5)
	grad.fill_to = Vector2(0.62, 0.5)
	shade.texture = grad
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	v.offset_left = 110
	v.offset_top = 170
	v.offset_right = 900
	v.add_theme_constant_override("separation", 16)
	root.add_child(v)
	var t := Label.new()
	t.text = "BRAMBLECROWN"
	t.add_theme_font_override("font", UITheme.font("title"))
	t.add_theme_font_size_override("font_size", 104)
	t.add_theme_color_override("font_color", Color(0.9, 0.82, 0.58))
	t.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.04))
	t.add_theme_constant_override("outline_size", 16)
	t.add_theme_color_override("font_shadow_color", Color(0.3, 0.6, 0.15, 0.55))
	t.add_theme_constant_override("shadow_offset_y", 6)
	v.add_child(t)
	var sub := Label.new()
	sub.text = "Grow the forest. Hold the ground. Replant the Crown."
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_color", UITheme.INK)
	v.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	v.add_child(spacer)
	_continue_btn = _btn(v, "Continue Run", func(): Sfx.play("click"); Game.continue_run())
	_continue_btn.visible = Game.has_saved_run()
	_new_btn = _btn(v, "New Run", _open_select)
	_btn(v, "Toggle Fullscreen (F11)", func(): Sfx.play("click"); Game.toggle_fullscreen())
	_btn(v, "Quit", func(): get_tree().quit())
	(_continue_btn if _continue_btn.visible else _new_btn).grab_focus()
	var foot := Label.new()
	foot.text = "Development build · %d of 5 regions · Runs %d · Clears %d" % [EncounterDB.REGIONS.size(), Game.profile["runs"], Game.profile["wins"]]
	foot.add_theme_color_override("font_color", UITheme.INK_DIM)
	foot.add_theme_font_size_override("font_size", 18)
	UITheme.anchor(foot, Control.PRESET_BOTTOM_LEFT, Vector2(110, -60))
	root.add_child(foot)


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 66)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 30)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Walker select: a staged model, pitch, starter deck and lock condition for each Grovewalker.
func _open_select() -> void:
	Sfx.play("click")
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.theme()
	layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.015, 0.012, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var head := Label.new()
	head.text = "Choose your Grovewalker"
	head.add_theme_font_override("font", UITheme.font("title"))
	head.add_theme_font_size_override("font_size", 56)
	head.add_theme_color_override("font_color", Color(0.9, 0.82, 0.58))
	head.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	head.offset_top = 40
	head.offset_left = -400
	head.offset_right = 400
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(head)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_top = 130
	row.offset_bottom = -110
	row.offset_left = 80
	row.offset_right = -80
	row.add_theme_constant_override("separation", 40)
	root.add_child(row)
	var first: Button = null
	for w in WalkerDB.ORDER:
		var pick := _walker_panel(row, w)
		if first == null and pick != null:
			first = pick
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(240, 60)
	back.add_theme_font_size_override("font_size", 28)
	back.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	back.offset_left = -120
	back.offset_right = 120
	back.offset_top = -90
	back.offset_bottom = -30
	back.pressed.connect(func():
		Sfx.play("click")
		layer.queue_free()
		_new_btn.grab_focus())
	root.add_child(back)
	(first if first != null else back).grab_focus()


func _walker_panel(row: Control, w: String) -> Button:
	var wd := WalkerDB.get_def(w)
	var open := WalkerDB.is_unlocked(w, Game.profile)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 24)
	panel.add_child(hb)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(300, 0)
	hb.add_child(svc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	svc.add_child(vp)
	var pivot := Node3D.new()
	vp.add_child(pivot)
	var model := (load("res://assets/models/%s.glb" % wd["model"]) as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * 1.6
	pivot.add_child(model)
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.get_animation_list().size() > 0:
		var an: StringName = ap.get_animation_list()[0]
		ap.get_animation(an).loop_mode = Animation.LOOP_LINEAR
		ap.play(an)
	var cam := Camera3D.new()
	vp.add_child(cam)
	cam.position = Vector3(0, 1.3, 3.6)
	cam.look_at(Vector3(0, 0.8, 0))
	var lamp := OmniLight3D.new()
	lamp.light_color = wd["light"]
	lamp.light_energy = 3.0
	lamp.omni_range = 9.0
	vp.add_child(lamp)
	lamp.position = Vector3(1.5, 2.5, 2.5)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.8
	fill.rotation_degrees = Vector3(-40, 30, 0)
	vp.add_child(fill)
	var tw := create_tween().set_loops()
	tw.tween_property(pivot, "rotation_degrees:y", 25.0, 4.0).from(-25.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(pivot, "rotation_degrees:y", -25.0, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	hb.add_child(v)
	var n := Label.new()
	n.text = wd["name"]
	n.add_theme_font_override("font", UITheme.font("title"))
	n.add_theme_font_size_override("font_size", 52)
	n.add_theme_color_override("font_color", wd["light"])
	v.add_child(n)
	var t := Label.new()
	t.text = "%s  ·  %d HP" % [wd["title"], wd["hp"]]
	t.add_theme_font_size_override("font_size", 26)
	v.add_child(t)
	var bl := Label.new()
	bl.text = wd["blurb"]
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.add_theme_font_size_override("font_size", 24)
	bl.add_theme_color_override("font_color", UITheme.INK)
	v.add_child(bl)
	var counts := {}
	for id in CardDB.STARTER_DECK[w]:
		counts[id] = int(counts.get(id, 0)) + 1
	var lines := PackedStringArray()
	for id in counts:
		var cd: Dictionary = CardDB.CARDS[id]
		lines.append("%dx %s (%d): %s" % [counts[id], cd["name"], int(cd["cost"]), CardDB.describe(cd)])
	var dl := Label.new()
	dl.text = "Starting deck\n" + "\n".join(lines)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.add_theme_font_size_override("font_size", 24)
	dl.add_theme_constant_override("line_spacing", 5)
	dl.add_theme_color_override("font_color", UITheme.INK)
	v.add_child(dl)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	if not open:
		var why := Label.new()
		why.text = wd.get("locked_text", "Locked")
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.add_theme_font_size_override("font_size", 22)
		why.add_theme_color_override("font_color", Color(0.95, 0.6, 0.4))
		v.add_child(why)
	var b := Button.new()
	b.text = "Begin as %s" % wd["name"] if open else "Locked"
	b.disabled = not open
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_font_size_override("font_size", 30)
	b.pressed.connect(func():
		Sfx.play("click")
		Game.clear_run()
		Game.new_run(-1, w))
	v.add_child(b)
	return b if open else null
