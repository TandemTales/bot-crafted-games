class_name CardView
extends Control
## One card, drawn procedurally: bark frame, parchment body, cost seed, art window, rules text.

signal pressed(card_view: CardView)
signal hovered(card_view: CardView, on: bool)

const SIZE := Vector2(230, 320)

var def: Dictionary = {}
var inst: Dictionary = {}
var playable := true
var selected := false
var hot := false
var _desc: RichTextLabel
var _name: Label
var _type: Label
var _art_tex: Texture2D


func setup(card_def: Dictionary, card_inst: Dictionary = {}) -> CardView:
	def = card_def
	inst = card_inst
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = Vector2(SIZE.x / 2, SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var art_path := "res://assets/textures/cards/%s.png" % def.get("id", "")
	if ResourceLoader.exists(art_path):
		_art_tex = load(art_path)
	_build()
	return self


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_name = Label.new()
	_name.text = def["name"]
	_name.add_theme_font_override("font", UITheme.font("heading"))
	_name.add_theme_font_size_override("font_size", 22 if def["name"].length() < 14 else 19)
	_name.add_theme_color_override("font_color", Color(1, 0.96, 0.86))
	_name.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_name.add_theme_constant_override("shadow_offset_y", 2)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.position = Vector2(44, 14)
	_name.size = Vector2(SIZE.x - 58, 30)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	_type = Label.new()
	_type.text = def["type"].capitalize()
	_type.add_theme_font_size_override("font_size", 15)
	_type.add_theme_color_override("font_color", Color(0.25, 0.18, 0.1))
	_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type.position = Vector2(0, 172)
	_type.size = Vector2(SIZE.x, 20)
	_type.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_type)
	_desc = RichTextLabel.new()
	_desc.bbcode_enabled = true
	_desc.fit_content = false
	_desc.scroll_active = false
	_desc.add_theme_color_override("default_color", Color(0.17, 0.12, 0.07))
	_desc.add_theme_font_size_override("normal_font_size", 18)
	_desc.add_theme_font_override("normal_font", UITheme.font("body"))
	_desc.position = Vector2(20, 196)
	_desc.size = Vector2(SIZE.x - 40, 112)
	_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := CardDB.describe(def)
	_desc.text = "[center]%s[/center]" % _dark_keywords(t)
	add_child(_desc)
	tooltip_text = UITheme.keyword_tips(t)


func _dark_keywords(t: String) -> String:
	var out := t
	for k in ["Thicket", "Grove", "Blight", "Ward", "Bleed", "Rooted", "Weak", "Exhaust", "Energy", "Movement"]:
		out = out.replace(k, "[b]%s[/b]" % k)
	return out


func set_state(can_play: bool, is_selected: bool) -> void:
	playable = can_play
	selected = is_selected
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, SIZE)
	var tc: Color = UITheme.TYPE_COLORS.get(def.get("type", "skill"), Color.GRAY)
	# Glow when selected / hovered.
	if selected:
		draw_style_box(UITheme.box(Color(0, 0, 0, 0), Color(0.75, 1.0, 0.45, 0.95), 6, 18, 0), r.grow(6))
	elif hot and playable:
		draw_style_box(UITheme.box(Color(0, 0, 0, 0), Color(1.0, 0.85, 0.45, 0.8), 4, 16, 0), r.grow(4))
	# Shadow, bark frame, parchment.
	draw_style_box(UITheme.box(Color(0, 0, 0, 0.45), Color(0, 0, 0, 0), 0, 16, 0), Rect2(Vector2(4, 8), SIZE))
	draw_style_box(UITheme.box(UITheme.BARK, tc.darkened(0.2), 3, 14, 0), r)
	draw_style_box(UITheme.box(UITheme.PARCHMENT, Color(0.4, 0.3, 0.18), 2, 10, 0), Rect2(10, 166, SIZE.x - 20, SIZE.y - 176))
	# Name banner.
	draw_style_box(UITheme.box(tc, tc.lightened(0.25), 2, 8, 0), Rect2(8, 10, SIZE.x - 16, 38))
	# Art window.
	var art := Rect2(16, 54, SIZE.x - 32, 112)
	if _art_tex:
		draw_texture_rect(_art_tex, art, false)
	else:
		_draw_art(art, tc)
	draw_rect(art, Color(0.1, 0.07, 0.04), false, 3.0)
	# Type ribbon.
	draw_style_box(UITheme.box(UITheme.PARCHMENT_DARK, Color(0.35, 0.25, 0.14), 1, 6, 0), Rect2(SIZE.x / 2 - 44, 168, 88, 24))
	# Cost seed.
	var cc := Vector2(26, 26)
	draw_circle(cc + Vector2(0, 2), 22, Color(0, 0, 0, 0.5))
	draw_circle(cc, 22, Color(0.18, 0.32, 0.12) if playable else Color(0.35, 0.12, 0.1))
	draw_arc(cc, 22, 0, TAU, 32, UITheme.GOLD, 2.5, true)
	var f := UITheme.font("title")
	var cost := str(def.get("cost", 0))
	var sz := f.get_string_size(cost, HORIZONTAL_ALIGNMENT_CENTER, -1, 30)
	draw_string(f, cc - Vector2(sz.x / 2, -10), cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 0.97, 0.85))
	if def.get("upgraded", false):
		draw_circle(Vector2(SIZE.x - 20, 58), 7, UITheme.LEAF)
	if not playable:
		draw_rect(r, Color(0, 0, 0, 0.35))


func _draw_art(a: Rect2, tc: Color) -> void:
	# Painterly gradient backdrop.
	var top := tc.darkened(0.55)
	var bottom := Color(0.1, 0.12, 0.08)
	for i in 12:
		var y0 := a.position.y + a.size.y * i / 12.0
		draw_rect(Rect2(a.position.x, y0, a.size.x, a.size.y / 12.0 + 1), top.lerp(bottom, i / 11.0))
	var c := a.get_center()
	var ink := Color(0.93, 0.86, 0.62)
	var leaf := Color(0.55, 0.85, 0.32)
	match def.get("art", ""):
		"strike":
			draw_line(c + Vector2(-40, 36), c + Vector2(40, -36), ink, 7, true)
			draw_line(c + Vector2(-40, -36), c + Vector2(40, 36), ink.darkened(0.2), 7, true)
			for i in 5:
				var p := c + Vector2(-40, 36).lerp(Vector2(40, -36), i / 4.0)
				draw_line(p, p + Vector2(10, 8), ink, 3, true)
		"ward":
			var pts := PackedVector2Array([c + Vector2(0, -44), c + Vector2(38, -28), c + Vector2(30, 20), c + Vector2(0, 44), c + Vector2(-30, 20), c + Vector2(-38, -28)])
			draw_colored_polygon(pts, Color(0.35, 0.55, 0.75))
			draw_polyline(pts + PackedVector2Array([pts[0]]), ink, 4, true)
			draw_line(c + Vector2(0, -30), c + Vector2(0, 30), Color(0.25, 0.18, 0.1), 4, true)
		"grow":
			draw_line(c + Vector2(0, 44), c + Vector2(0, -10), Color(0.4, 0.3, 0.15), 6, true)
			_leaf(c + Vector2(0, -10), -0.6, 34, leaf)
			_leaf(c + Vector2(0, -2), 2.4, 30, leaf.darkened(0.15))
			_leaf(c + Vector2(0, 12), -2.6, 24, leaf.lightened(0.1))
		"lash":
			var prev := c + Vector2(-50, 30)
			for i in 20:
				var t := i / 19.0
				var p := c + Vector2(-50 + 100 * t, 30 - 60 * t + sin(t * 9.0) * 14)
				draw_line(prev, p, Color(0.5, 0.36, 0.18), 5, true)
				if i % 3 == 0:
					draw_line(p, p + Vector2(6, -9), ink, 2, true)
				prev = p
		"fire":
			for k in 3:
				var s := 1.0 - k * 0.28
				var col: Color = [Color(0.95, 0.35, 0.1), Color(1, 0.62, 0.15), Color(1, 0.9, 0.5)][k]
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -46) * s + Vector2(0, 10 * k), c + Vector2(26, 0) * s, c + Vector2(20, 30) * s, c + Vector2(0, 40) * s, c + Vector2(-20, 30) * s, c + Vector2(-26, 0) * s]), col)
		"cleanse":
			for i in 8:
				var ang := i * TAU / 8.0
				draw_line(c + Vector2.from_angle(ang) * 14, c + Vector2.from_angle(ang) * 44, ink, 4, true)
			draw_circle(c, 14, Color(0.85, 1.0, 0.7))
		"root":
			for i in 5:
				var x := -40 + i * 20
				var prev := c + Vector2(x, -40)
				for j in 8:
					var p := c + Vector2(x + sin(j + i) * 8, -40 + j * 12)
					draw_line(prev, p, Color(0.5, 0.36, 0.2), 6 - j * 0.6, true)
					prev = p
		"sap":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -44), c + Vector2(26, 8), c + Vector2(18, 32), c + Vector2(0, 40), c + Vector2(-18, 32), c + Vector2(-26, 8)]), Color(0.85, 0.6, 0.15))
			draw_circle(c + Vector2(-8, 10), 6, Color(1, 0.9, 0.6))
		"move":
			for i in 3:
				var p := c + Vector2(-44 + i * 38, 26 - i * 22)
				draw_circle(p, 10, ink)
				draw_circle(p + Vector2(-7, -14), 4, ink)
				draw_circle(p + Vector2(4, -16), 4, ink)
		"pollen":
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			for i in 40:
				draw_circle(c + Vector2(rng.randf_range(-60, 60), rng.randf_range(-44, 44)), rng.randf_range(2, 5), Color(1, 0.9, 0.4, 0.8))
		_:
			draw_circle(c, 30, ink)


func _leaf(base: Vector2, ang: float, length: float, col: Color) -> void:
	var dir := Vector2.from_angle(ang)
	var n := dir.orthogonal()
	var pts := PackedVector2Array([base, base + dir * length * 0.5 + n * length * 0.28, base + dir * length, base + dir * length * 0.5 - n * length * 0.28])
	draw_colored_polygon(pts, col)
	draw_line(base, base + dir * length, col.darkened(0.35), 2, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
		accept_event()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			hot = true
			hovered.emit(self, true)
			queue_redraw()
		NOTIFICATION_MOUSE_EXIT:
			hot = false
			hovered.emit(self, false)
			queue_redraw()
