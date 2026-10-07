extends Control
## Region map: pick the next node along the branching path.

const ICON_R := 34.0
const MAP_ART := {
	"marsh": preload("res://assets/textures/map-art/ashfen-marsh.png"),
	"cloister": preload("res://assets/textures/map-art/sunken-cloister.png"),
	"glasswood": preload("res://assets/textures/map-art/glasswood.png"),
	"ironroot": preload("res://assets/textures/map-art/ironroot-deeps.png"),
	"crown": preload("res://assets/textures/map-art/crown-of-thorns.png"),
}
const MAP_ICONS := {
	"fight": preload("res://assets/textures/map-icons/fight.png"),
	"elite": preload("res://assets/textures/map-icons/elite.png"),
	"shrine": preload("res://assets/textures/map-icons/shrine.png"),
	"camp": preload("res://assets/textures/map-icons/camp.png"),
	"market": preload("res://assets/textures/map-icons/market.png"),
	"boss": preload("res://assets/textures/map-icons/boss.png"),
}
const NAMES := {"fight": "Blighted Clearing", "elite": "Elite: a dangerous foe", "shrine": "Shrine: an unknown encounter",
	"camp": "Campfire: rest or tend a card", "market": "Pedlar: buy cards and charms", "boss": "Boss"}

var hud: RunHud
var _hover := -1
var _pos := {}
var _time := 0.0
var _art: Texture2D
# QA-only fixture uses the exact runtime badge renderer at the same dimensions.
var _qa_icon_gallery := false


func _ready() -> void:
	theme = UITheme.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Game.run == null:
		Game.new_run(1)
		return
	_art = MAP_ART.get(Game.run.region_def().get("theme", "marsh"), MAP_ART["marsh"])
	hud = RunHud.new()
	add_child(hud)
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
	# Full-bleed illustrated atlas. Crop only the edges on non-16:9 windows;
	# the quiet parchment center remains behind every interactive route.
	var texture_size := _art.get_size()
	var scale_factor := maxf(size.x / texture_size.x, size.y / texture_size.y)
	var visible_size := size / scale_factor
	draw_texture_rect_region(_art, Rect2(Vector2.ZERO, size),
		Rect2((texture_size - visible_size) * 0.5, visible_size))
	# Dark gutters keep the HUD and legend legible over the edge illustration.
	for i in 12:
		var opacity := 0.44 * pow(1.0 - i / 12.0, 2.0)
		draw_rect(Rect2(0, i * 9, size.x, 10), Color(0.06, 0.07, 0.055, opacity))
	var legend_rect := Rect2(size.x / 2 - 566, size.y - 68, 1132, 60)
	draw_style_box(UITheme.box(Color(0.055, 0.065, 0.05, 0.95),
		Color(0.62, 0.48, 0.26, 0.8), 1, 10, 0), legend_rect)
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
					var dash_a := a.lerp(b, s / float(steps))
					var dash_b := a.lerp(b, (s + 1) / float(steps))
					# A parchment under-stroke separates routes from detailed edge landmarks.
					draw_line(dash_a, dash_b, Color(0.96, 0.88, 0.71, 0.82), 7 if on_path else 6, true)
					draw_line(dash_a, dash_b, col, 4 if on_path else 3, true)
	var reachable := _reachable_nodes(avail)
	# Nodes.
	for n in r.map:
		var p: Vector2 = _pos[n["id"]]
		_draw_badge(n["type"], p, _node_state(n, avail, reachable), n["id"] == _hover)
	# Use the very same drawn symbols as the nodes, with short readable labels.
	var legend_types := ["fight", "elite", "shrine", "camp", "market", "boss"]
	var legend_labels := ["Fight", "Elite", "Shrine", "Camp", "Pedlar", "Boss"]
	for i in legend_types.size():
		var p := Vector2(size.x / 2 - 510 + i * 185, size.y - 32)
		_icon(legend_types[i], p, ICON_R, 1.0)
		draw_string(UITheme.font("heading"), p + Vector2(32, 8), legend_labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UITheme.INK)
	if _qa_icon_gallery:
		_draw_icon_gallery()
	if _hover >= 0 and not _qa_icon_gallery:
		var n := r.node(_hover)
		var txt: String = NAMES.get(n["type"], n["type"])
		if n["type"] == "boss":
			txt = "Boss: %s" % _boss_name()
		var state := _node_state(n, avail, reachable)
		var prefix := {"current": "Current", "completed": "Visited", "locked": "Locked", "future": "Later", "available": "Choose"}
		txt = "%s: %s" % [prefix[state], txt]
		var f := UITheme.font("heading")
		var p: Vector2 = _pos[_hover] + Vector2(ICON_R + 16, -10)
		var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		p.x = clampf(p.x, 16, size.x - sz.x - 24)
		p.y = clampf(p.y, 122, size.y - 86)
		draw_style_box(UITheme.box(Color(0.06, 0.07, 0.06, 0.95), UITheme.GOLD, 1, 6, 0), Rect2(p - Vector2(8, 24), sz + Vector2(16, 14)))
		draw_string(f, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UITheme.INK)


func _current_row() -> int:
	var r := Game.run
	return -1 if r.node_id < 0 else int(r.node(r.node_id)["row"])


func _reachable_nodes(avail: Array) -> Array:
	var found: Array = []
	var pending := avail.duplicate()
	while not pending.is_empty():
		var id: int = pending.pop_back()
		if found.has(id):
			continue
		found.append(id)
		pending.append_array(Game.run.node(id)["links"])
	return found


func _node_state(n: Dictionary, avail: Array, reachable: Array) -> String:
	if n["id"] == Game.run.node_id:
		return "current"
	if n["row"] < _current_row():
		return "completed" if n.get("visited", false) else "locked"
	if avail.has(n["id"]):
		return "available"
	return "future" if reachable.has(n["id"]) else "locked"


func _draw_badge(t: String, p: Vector2, state: String, hovered := false) -> void:
	var rad := ICON_R * (1.25 if t == "boss" else 1.0)
	var active := state in ["available", "current"]
	if state == "available":
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		draw_circle(p, rad + 10 + pulse * 5, Color(0.55, 0.95, 0.35, 0.35))
	if hovered and state == "available":
		draw_circle(p, rad + 8, Color(1, 0.9, 0.5, 0.8))
	draw_circle(p + Vector2(0, 3), rad + 4, Color(0.12, 0.09, 0.055, 0.24))
	draw_circle(p, rad + 2, Color(0.8, 0.68, 0.45))
	draw_circle(p, rad, Color(0.18, 0.13, 0.08))
	draw_arc(p, rad, 0, TAU, 40, UITheme.GOLD if active else Color(0.4, 0.31, 0.2), 3, true)
	_icon(t, p, rad, {"available": 1.0, "current": 1.0, "future": 0.78, "completed": 0.65, "locked": 0.30}[state])
	if state in ["current", "completed", "locked"]:
		var mark := p + Vector2(rad * 0.78, -rad * 0.78)
		draw_circle(mark, 13, Color(0.08, 0.10, 0.065))
		draw_arc(mark, 13, 0, TAU, 24, UITheme.GOLD if state == "current" else Color(0.68, 0.62, 0.46), 2, true)
		if state == "completed":
			draw_polyline(PackedVector2Array([mark + Vector2(-7, 0), mark + Vector2(-2, 5), mark + Vector2(7, -6)]), UITheme.LEAF, 4, true)
		elif state == "current":
			# Leaf pointer: shape as well as color distinguishes the current location.
			draw_colored_polygon(PackedVector2Array([mark + Vector2(0, -8), mark + Vector2(7, -1), mark + Vector2(0, 9), mark + Vector2(-7, -1)]), UITheme.LEAF)
		else:
			draw_arc(mark + Vector2(0, -2), 5, PI, TAU, 12, Color(0.88, 0.83, 0.70), 2, true)
			draw_style_box(UITheme.box(Color(0.88, 0.83, 0.70), Color.TRANSPARENT, 0, 2, 0), Rect2(mark + Vector2(-6, -2), Vector2(12, 9)))


func _icon(t: String, p: Vector2, rad: float, alpha: float) -> void:
	var tex: Texture2D = MAP_ICONS[t]
	var extent := Vector2.ONE * rad * 1.74
	var scale_factor := minf(extent.x / tex.get_width(), extent.y / tex.get_height())
	var dimensions := tex.get_size() * scale_factor
	draw_texture_rect(tex, Rect2(p - dimensions * 0.5, dimensions), false, Color(1, 1, 1, alpha))


func _draw_icon_gallery() -> void:
	# Production-size badges; fixture is explicitly labelled, never player progression.
	var panel := Rect2(size.x / 2 - 790, 170, 1580, 700)
	draw_style_box(UITheme.box(Color(0.11, 0.12, 0.09, 0.98), UITheme.GOLD, 2, 12, 0), panel)
	var font := UITheme.font("heading")
	draw_string(font, Vector2(panel.position.x + 28, 212), "QA fixture: original icons at runtime size", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UITheme.INK)
	var types := ["fight", "elite", "shrine", "camp", "market", "boss"]
	var labels := ["Fight", "Elite", "Shrine", "Camp", "Pedlar", "Boss"]
	var states := ["available", "current", "completed", "locked", "future"]
	for col in 6:
		var x := panel.position.x + 340 + col * 208
		draw_string(font, Vector2(x - 36, 260), labels[col], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UITheme.INK)
		for row in states.size():
			var y := 330.0 + row * 110
			if col == 0:
				draw_string(font, Vector2(panel.position.x + 30, y + 8), states[row].capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UITheme.INK)
			_draw_badge(types[col], Vector2(x, y), states[row])


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


func _boss_name() -> String:
	var enc: Dictionary = EncounterDB.ENCOUNTERS[Game.run.region_def()["boss"]]
	return EnemyDB.ENEMIES[enc["enemies"][0][0]]["name"]
