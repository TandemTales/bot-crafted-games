class_name UnitPlate
extends Control
## Floating HP / ward / status / intent plate that follows a unit on screen.

const W := 176.0

var title := ""
var hp := 0
var max_hp := 1
var ward := 0
var statuses := {}
var intent := {}  # {name, icons:[{kind, n, hot}]}
var is_player := false
var pending_damage := 0
var highlight := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(W, 104)


func update_from(data: Dictionary) -> void:
	title = data.get("title", title)
	hp = int(data.get("hp", hp))
	max_hp = maxi(1, int(data.get("max_hp", max_hp)))
	ward = int(data.get("ward", 0))
	statuses = data.get("statuses", {})
	intent = data.get("intent", {})
	queue_redraw()


func _draw() -> void:
	var f := UITheme.font("heading")
	var fb := UITheme.font("body")
	var y := 0.0
	# Intent row above the bar.
	if not intent.is_empty():
		var icons: Array = intent.get("icons", [])
		var total_w := icons.size() * 66.0
		var x := (W - total_w) / 2.0
		if not icons.is_empty():
			draw_style_box(UITheme.box(Color(0.03, 0.03, 0.03, 0.78), Color(0.4, 0.3, 0.2, 0.8), 1, 12, 0), Rect2(x - 4, 0, total_w + 8, 50))
		for ic in icons:
			_intent_icon(Vector2(x + 26, 25), ic)
			x += 66.0
		y = 54.0
	# Name.
	var name_size := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
	draw_string(f, Vector2((W - name_size.x) / 2 + 1, y + 16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0, 0, 0, 0.8))
	draw_string(f, Vector2((W - name_size.x) / 2, y + 15), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UITheme.GOLD if highlight else UITheme.INK)
	y += 20.0
	# HP bar.
	var bar := Rect2(8, y, W - 16, 14)
	draw_rect(bar.grow(2), Color(0, 0, 0, 0.75))
	var frac := clampf(float(hp) / max_hp, 0, 1)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color(0.7, 0.14, 0.12) if not is_player else Color(0.72, 0.2, 0.16))
	if pending_damage > 0:
		var after := clampf(float(maxi(0, hp - maxi(0, pending_damage - ward))) / max_hp, 0, 1)
		draw_rect(Rect2(bar.position + Vector2(bar.size.x * after, 0), Vector2(bar.size.x * (frac - after), bar.size.y)), Color(1, 0.85, 0.4, 0.85))
	var hp_text := "%d/%d" % [hp, max_hp]
	var ts := fb.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_string(fb, Vector2(W / 2 - ts.x / 2, y + 12), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	if ward > 0:
		var c := Vector2(6, y + 7)
		_shield(c, 13, UITheme.WARD)
		var wt := str(ward)
		var ws := f.get_string_size(wt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		draw_string(f, c + Vector2(-ws.x / 2, 6), wt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	y += 20.0
	# Statuses.
	var sx := 8.0
	for s in statuses:
		var n := int(statuses[s])
		if n <= 0:
			continue
		var col: Color = {"bleed": UITheme.BLOOD, "rooted": UITheme.LEAF, "weak": Color(0.9, 0.85, 0.4), "strength": Color(1, 0.55, 0.3), "dazed": UITheme.GOLD}.get(s, UITheme.INK)
		var label := "%s %d" % [s.capitalize(), n]
		var lw := fb.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 10
		draw_style_box(UITheme.box(Color(0, 0, 0, 0.7), col, 1, 5, 0), Rect2(sx, y, lw, 18))
		draw_string(fb, Vector2(sx + 5, y + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
		sx += lw + 4


func _intent_icon(c: Vector2, ic: Dictionary) -> void:
	var kind: String = ic.get("kind", "")
	var hot: bool = ic.get("hot", false)
	draw_circle(c, 21, Color(0, 0, 0, 0.7))
	var col := Color(0.95, 0.35, 0.28) if hot else Color(0.8, 0.72, 0.6)
	match kind:
		"attack":
			draw_line(c + Vector2(-9, 9), c + Vector2(9, -9), col, 4, true)
			draw_line(c + Vector2(-6, 2), c + Vector2(2, 10), col, 3, true)
		"spread":
			col = UITheme.BLIGHT
			for i in 5:
				draw_circle(c + Vector2.from_angle(i * TAU / 5) * 7, 4, col)
			draw_circle(c, 4, col)
		"summon":
			col = UITheme.BLIGHT.lightened(0.2)
			draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), col, 4)
			draw_line(c + Vector2(0, -8), c + Vector2(0, 8), col, 4)
		"ward":
			col = UITheme.WARD
			_shield(c, 11, col)
		"daze":
			col = UITheme.GOLD
			# A bell.
			draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -9), c + Vector2(4, -9), c + Vector2(7, 3), c + Vector2(10, 7), c + Vector2(-10, 7), c + Vector2(-7, 3)]), col)
			draw_circle(c + Vector2(0, 10), 3, col)
		"heal":
			col = UITheme.LEAF
			draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), col, 5)
			draw_line(c + Vector2(0, -8), c + Vector2(0, 8), col, 5)
		"strength":
			col = Color(1, 0.55, 0.3)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -10), c + Vector2(9, 2), c + Vector2(3, 2), c + Vector2(3, 10), c + Vector2(-3, 10), c + Vector2(-3, 2), c + Vector2(-9, 2)]), col)
	draw_arc(c, 21, 0, TAU, 24, col, 2.5, true)
	if ic.has("n"):
		var f := UITheme.font("title")
		var t := str(ic["n"])
		draw_string_outline(f, c + Vector2(13, 20), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 27, 6, Color(0, 0, 0, 0.95))
		draw_string(f, c + Vector2(13, 20), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color(1, 0.9, 0.8) if not hot else Color(1, 0.5, 0.4))


func _shield(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.9, -r * 0.6), c + Vector2(r * 0.7, r * 0.4), c + Vector2(0, r), c + Vector2(-r * 0.7, r * 0.4), c + Vector2(-r * 0.9, -r * 0.6)]), col.darkened(0.3))
	draw_polyline(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.9, -r * 0.6), c + Vector2(r * 0.7, r * 0.4), c + Vector2(0, r), c + Vector2(-r * 0.7, r * 0.4), c + Vector2(-r * 0.9, -r * 0.6), c + Vector2(0, -r)]), col, 2, true)
