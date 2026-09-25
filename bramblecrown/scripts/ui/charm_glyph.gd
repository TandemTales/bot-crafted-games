class_name CharmGlyph
extends RefCounted
## Small vector icon for each charm, drawn into any CanvasItem (combat badges, run HUD, rewards).


static func draw_glyph(ci: CanvasItem, id: String, c: Vector2, s: float) -> void:
	var gold := UITheme.GOLD
	var leaf := UITheme.LEAF
	match id:
		"acorn_locket":
			ci.draw_circle(c + Vector2(0, 3) * s, 8 * s, Color(0.72, 0.5, 0.25))
			ci.draw_rect(Rect2(c + Vector2(-9, -8) * s, Vector2(18, 7) * s), Color(0.42, 0.28, 0.14))
			ci.draw_line(c + Vector2(0, -8) * s, c + Vector2(2, -12) * s, Color(0.42, 0.28, 0.14), 2 * s)
		"mossy_flask":
			ci.draw_rect(Rect2(c + Vector2(-3, -12) * s, Vector2(6, 6) * s), Color(0.6, 0.5, 0.35))
			ci.draw_circle(c + Vector2(0, 3) * s, 9 * s, Color(0.3, 0.55, 0.3))
			ci.draw_circle(c + Vector2(-3, 1) * s, 3 * s, leaf.lightened(0.3))
		"ironbark_husk":
			_shield(ci, c, 11 * s, Color(0.55, 0.42, 0.28))
			ci.draw_line(c + Vector2(0, -9) * s, c + Vector2(0, 9) * s, Color(0.3, 0.2, 0.1), 2 * s)
		"heron_feather":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(6, -12) * s, c + Vector2(2, 2) * s, c + Vector2(-7, 11) * s, c + Vector2(-2, -2) * s]), Color(0.85, 0.88, 0.9))
			ci.draw_line(c + Vector2(6, -12) * s, c + Vector2(-8, 12) * s, Color(0.4, 0.45, 0.5), 1.5 * s)
		"seed_pouch":
			ci.draw_circle(c + Vector2(0, 3) * s, 9 * s, Color(0.55, 0.38, 0.2))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -6) * s, c + Vector2(5, -6) * s, c + Vector2(3, -11) * s, c + Vector2(-3, -11) * s]), Color(0.45, 0.3, 0.15))
			ci.draw_circle(c + Vector2(0, 3) * s, 3 * s, leaf)
		"amber_heart":
			ci.draw_circle(c + Vector2(-4, -3) * s, 5.5 * s, Color(0.95, 0.6, 0.15))
			ci.draw_circle(c + Vector2(4, -3) * s, 5.5 * s, Color(0.95, 0.6, 0.15))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-9.5, -1) * s, c + Vector2(9.5, -1) * s, c + Vector2(0, 11) * s]), Color(0.95, 0.6, 0.15))
		"grove_bell":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -10) * s, c + Vector2(4, -10) * s, c + Vector2(7, 4) * s, c + Vector2(10, 7) * s, c + Vector2(-10, 7) * s, c + Vector2(-7, 4) * s]), leaf)
			ci.draw_circle(c + Vector2(0, 10) * s, 2.5 * s, gold)
		"ember_fang":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -10) * s, c + Vector2(6, -10) * s, c + Vector2(0, 12) * s]), Color(0.95, 0.9, 0.8))
			ci.draw_circle(c + Vector2(0, 4) * s, 3 * s, Color(1, 0.4, 0.1))
		"rot_ward":
			_shield(ci, c, 11 * s, UITheme.BLIGHT.darkened(0.2))
			ci.draw_line(c + Vector2(-6, -6) * s, c + Vector2(6, 6) * s, gold, 2.5 * s)
			ci.draw_line(c + Vector2(6, -6) * s, c + Vector2(-6, 6) * s, gold, 2.5 * s)
		"thorn_crown_shard":
			for i in 3:
				var x := -7 + i * 7
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x - 3, 8) * s, c + Vector2(x + 3, 8) * s, c + Vector2(x, -10 + (4 if i != 1 else 0)) * s]), Color(0.75, 0.62, 0.36))
			ci.draw_line(c + Vector2(-11, 8) * s, c + Vector2(11, 8) * s, leaf, 3 * s)
		_:
			var col := Color.from_hsv(float(hash(id) % 360) / 360.0, 0.5, 0.85)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -12) * s, c + Vector2(10, 0) * s, c + Vector2(0, 12) * s, c + Vector2(-10, 0) * s]), col)


static func _shield(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.9, -r * 0.6), c + Vector2(r * 0.7, r * 0.4), c + Vector2(0, r), c + Vector2(-r * 0.7, r * 0.4), c + Vector2(-r * 0.9, -r * 0.6)]), col)
