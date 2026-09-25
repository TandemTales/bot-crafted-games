extends Control
## Region map: pick the next node along the branching path.

const ICON_R := 34.0
const NAMES := {"fight": "Blighted Clearing", "elite": "Elite: a dangerous foe", "shrine": "Shrine: an unknown encounter",
	"camp": "Campfire: rest or tend a card", "market": "Pedlar: buy cards and charms", "boss": "Boss"}

var hud: RunHud
var _hover := -1
var _pos := {}
var _time := 0.0


func _ready() -> void:
	theme = UITheme.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Game.run == null:
		Game.new_run(1)
		return
	hud = RunHud.new()
	add_child(hud)
	var legend := Label.new()
	legend.text = "Choose your path upward.   X Fight   Horned skull: Elite   Arch: Shrine   Flame: Camp   Coin: Pedlar   Crown: The Mire Mother"
	legend.add_theme_color_override("font_color", UITheme.INK_DIM)
	legend.add_theme_font_size_override("font_size", 20)
	UITheme.anchor(legend, Control.PRESET_CENTER_BOTTOM, Vector2(-500, -50), Vector2(1000, 30))
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(legend)
	Sfx.play_music("map")
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	_pos.clear()
	var r := Game.run
	var top := 150.0
	var bottom := size.y - 110.0
	var rows := RunState.ROWS + 1
	var w := minf(size.x * 0.6, 1100.0)
	for n in r.map:
		var y: float = bottom - (bottom - top) * n["row"] / float(rows - 1)
		var x: float = size.x / 2 + (float(n["col"]) + 0.5 - n["width"] / 2.0) * (w / 4.0)
		# Deterministic jitter so the map feels hand-drawn.
		var j := float(hash(n["id"] * 7919 + r.seed_value) % 1000) / 1000.0
		x += (j - 0.5) * 50.0
		_pos[n["id"]] = Vector2(x, y)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var r := Game.run
	if r == null or _pos.is_empty():
		return
	# Backdrop: deep marsh gradient, fog bands, parchment scroll.
	for i in 24:
		var t := i / 23.0
		draw_rect(Rect2(0, size.y * t, size.x, size.y / 23.0 + 1), Color(0.05, 0.07, 0.06).lerp(Color(0.1, 0.09, 0.07), t))
	var scroll_w := minf(size.x * 0.7, 1240.0)
	var sr := Rect2(size.x / 2 - scroll_w / 2, 110, scroll_w, size.y - 170)
	draw_style_box(UITheme.box(Color(0.72, 0.64, 0.49), Color(0.35, 0.25, 0.14), 4, 18, 0), sr)
	var rng := RandomNumberGenerator.new()
	rng.seed = r.seed_value
	# Paper fibres and a darkened vignette edge.
	for i in 140:
		var p := sr.position + Vector2(rng.randf() * sr.size.x, rng.randf() * sr.size.y)
		var d := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(8, 30)
		draw_line(p, p + d, Color(0.45, 0.36, 0.22, 0.12), 1.0, true)
	for k in 10:
		draw_style_box(UITheme.box(Color(0, 0, 0, 0), Color(0.35, 0.25, 0.14, 0.05), 4 + k * 3, 18, 0), sr.grow(-k * 3))
	# Marsh water blotches and reeds as decoration.
	for i in 18:
		var p := sr.position + Vector2(rng.randf() * sr.size.x, rng.randf() * sr.size.y)
		for k in 5:
			draw_line(p + Vector2(k * 4, 0), p + Vector2(k * 4 + rng.randf_range(-3, 3), -rng.randf_range(12, 26)), Color(0.35, 0.3, 0.18, 0.5), 2)
	var avail := r.available_nodes()
	# Links.
	for n in r.map:
		for l in n["links"]:
			var a: Vector2 = _pos[n["id"]]
			var b: Vector2 = _pos[l]
			var on_path: bool = n["id"] == r.node_id and avail.has(l)
			var col := Color(0.25, 0.17, 0.09, 0.9) if not on_path else Color(0.2, 0.45, 0.12)
			var steps := int(a.distance_to(b) / 14.0)
			for s in steps:
				if s % 2 == 0:
					draw_line(a.lerp(b, s / float(steps)), a.lerp(b, (s + 1) / float(steps)), col, 4 if on_path else 3, true)
	# Nodes.
	for n in r.map:
		var p: Vector2 = _pos[n["id"]]
		var is_avail := avail.has(n["id"])
		var visited: bool = n["row"] < _current_row() or n["id"] == r.node_id
		var rad := ICON_R * (1.25 if n["type"] == "boss" else 1.0)
		if is_avail:
			var pulse := 0.5 + 0.5 * sin(_time * 4.0)
			draw_circle(p, rad + 10 + pulse * 5, Color(0.55, 0.95, 0.35, 0.35))
		if n["id"] == _hover and is_avail:
			draw_circle(p, rad + 8, Color(1, 0.9, 0.5, 0.8))
		draw_circle(p, rad, Color(0.18, 0.13, 0.08) if not visited else Color(0.35, 0.3, 0.22))
		draw_arc(p, rad, 0, TAU, 40, UITheme.GOLD if is_avail else Color(0.3, 0.22, 0.12), 3, true)
		_icon(n["type"], p, rad, 0.45 if (visited and n["id"] != r.node_id) else 1.0)
		if n["id"] == r.node_id:
			draw_circle(p + Vector2(rad * 0.8, -rad * 0.8), 10, UITheme.LEAF)
	if _hover >= 0:
		var n := r.node(_hover)
		var txt: String = NAMES.get(n["type"], n["type"])
		if n["type"] == "boss":
			txt = "Boss: The Mire Mother"
		var f := UITheme.font("heading")
		var p: Vector2 = _pos[_hover] + Vector2(ICON_R + 16, -10)
		var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		draw_style_box(UITheme.box(Color(0.06, 0.07, 0.06, 0.95), UITheme.GOLD, 1, 6, 0), Rect2(p - Vector2(8, 24), sz + Vector2(16, 14)))
		draw_string(f, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UITheme.INK)


func _current_row() -> int:
	var r := Game.run
	return -1 if r.node_id < 0 else int(r.node(r.node_id)["row"])


func _icon(t: String, p: Vector2, rad: float, alpha: float) -> void:
	var ink := Color(0.93, 0.86, 0.66, alpha)
	match t:
		"fight":
			draw_line(p + Vector2(-14, 14), p + Vector2(14, -14), ink, 5, true)
			draw_line(p + Vector2(-14, -14), p + Vector2(14, 14), ink, 5, true)
		"elite":
			var red := Color(0.9, 0.32, 0.25, alpha)
			draw_circle(p + Vector2(0, 2), 13, red)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-11, -6), p + Vector2(-22, -20), p + Vector2(-6, -12)]), red)
			draw_colored_polygon(PackedVector2Array([p + Vector2(11, -6), p + Vector2(22, -20), p + Vector2(6, -12)]), red)
			draw_circle(p + Vector2(-5, 0), 3.5, Color(0.1, 0.05, 0.04, alpha))
			draw_circle(p + Vector2(5, 0), 3.5, Color(0.1, 0.05, 0.04, alpha))
			draw_rect(Rect2(p + Vector2(-6, 9), Vector2(12, 5)), Color(0.1, 0.05, 0.04, alpha))
		"shrine":
			draw_arc(p + Vector2(0, 4), 14, PI, TAU, 16, ink, 4, true)
			draw_line(p + Vector2(-14, 4), p + Vector2(-14, 16), ink, 4)
			draw_line(p + Vector2(14, 4), p + Vector2(14, 16), ink, 4)
			draw_circle(p + Vector2(0, 2), 4, Color(1, 0.85, 0.4, alpha))
		"camp":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -18), p + Vector2(11, 4), p + Vector2(0, 14), p + Vector2(-11, 4)]), Color(1, 0.55, 0.15, alpha))
			draw_line(p + Vector2(-14, 16), p + Vector2(14, 10), Color(0.5, 0.33, 0.18, alpha), 4)
			draw_line(p + Vector2(-14, 10), p + Vector2(14, 16), Color(0.5, 0.33, 0.18, alpha), 4)
		"market":
			draw_circle(p + Vector2(0, 4), 13, Color(0.85, 0.65, 0.25, alpha))
			draw_line(p + Vector2(-6, -12), p + Vector2(6, -12), ink, 4)
			draw_string(UITheme.font("title"), p + Vector2(-6, 12), "g", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.3, 0.2, 0.1, alpha))
		"boss":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-24, 14), p + Vector2(-24, -10), p + Vector2(-12, 2), p + Vector2(0, -22), p + Vector2(12, 2), p + Vector2(24, -10), p + Vector2(24, 14)]), Color(0.7, 0.35, 0.95, alpha))
			draw_circle(p + Vector2(0, 4), 5, Color(1, 0.8, 0.3, alpha))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover = _node_at(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id := _node_at(event.position)
		if id >= 0 and Game.run.available_nodes().has(id):
			_enter(id)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		var avail := Game.run.available_nodes()
		if avail.is_empty():
			return
		var i := avail.find(_hover)
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				_hover = avail[wrapi(i - 1, 0, avail.size())]
			JOY_BUTTON_DPAD_RIGHT:
				_hover = avail[wrapi(i + 1, 0, avail.size())]
			JOY_BUTTON_A:
				if avail.has(_hover):
					_enter(_hover)
	elif event.is_action_pressed("cancel"):
		Game.save_run()
		Game.goto_title()


func _node_at(p: Vector2) -> int:
	for id in _pos:
		if p.distance_to(_pos[id]) < ICON_R + 6:
			return id
	return -1


func _enter(id: int) -> void:
	Sfx.play("click")
	var t := Game.run.enter_node(id)
	Game.save_run()
	if t in ["fight", "elite", "boss"]:
		Game.goto_combat()
	else:
		Game.route_to_status()
