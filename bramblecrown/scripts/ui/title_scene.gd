extends Node3D
## Title screen: a live diorama of the Mire Mother's lair behind the menu.

var rig: CameraRig
var _t := 0.0
var _continue_btn: Button


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
	var nb := _btn(v, "New Run", func():
		Sfx.play("click")
		Game.clear_run()
		Game.new_run())
	_btn(v, "Toggle Fullscreen (F11)", func(): Sfx.play("click"); Game.toggle_fullscreen())
	_btn(v, "Quit", func(): get_tree().quit())
	(_continue_btn if _continue_btn.visible else nb).grab_focus()
	var foot := Label.new()
	foot.text = "v%s · Runs %d · Wins %d" % [ProjectSettings.get_setting("application/config/version"), Game.profile["runs"], Game.profile["wins"]]
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
