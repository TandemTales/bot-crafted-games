extends Control
## Non-combat rooms: campfire, shrine event, and pedlar market.

var hud: RunHud
var body: VBoxContainer


func _ready() -> void:
	theme = UITheme.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := RoomBackdrop.new()
	bg.kind = Game.run.status
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	hud = RunHud.new()
	add_child(hud)
	body = VBoxContainer.new()
	UITheme.anchor(body, Control.PRESET_CENTER, Vector2(-700, -360), Vector2(1400, 780))
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 20)
	add_child(body)
	match Game.run.status:
		"camp":
			_camp()
		"shrine":
			_shrine()
		"market":
			_market()
		_:
			Game.route_to_status()
	Sfx.play_music("map")


func _heading(text: String, sub: String = "") -> void:
	var h := Label.new()
	h.text = text
	h.add_theme_font_override("font", UITheme.font("title"))
	h.add_theme_font_size_override("font_size", 56)
	h.add_theme_color_override("font_color", UITheme.GOLD)
	h.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	h.add_theme_constant_override("outline_size", 10)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(h)
	if sub != "":
		var s := RichTextLabel.new()
		s.bbcode_enabled = true
		s.fit_content = true
		s.scroll_active = false
		s.custom_minimum_size = Vector2(900, 0)
		s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		s.add_theme_font_size_override("normal_font_size", 26)
		s.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		s.add_theme_constant_override("outline_size", 6)
		s.text = "[center]%s[/center]" % sub
		body.add_child(s)


func _button(text: String, cb: Callable, enabled: bool = true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(620, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.disabled = not enabled
	b.pressed.connect(cb)
	body.add_child(b)
	return b


func _clear() -> void:
	for c in body.get_children():
		c.queue_free()


func _done(msg: String) -> void:
	_clear()
	_heading("", msg)
	hud.refresh()
	Game.save_run()
	_button("Continue", func(): Sfx.play("click"); Game.goto_map())


# ------------------------------------------------------------------ camp

func _camp() -> void:
	var r := Game.run
	_heading("Campfire", "The peat smoke keeps the Blight at bay for a night.")
	var heal := mini(r.max_hp - r.hp, int(ceil(r.max_hp * 0.3)))
	_button("Rest: heal %d HP" % heal, func():
		var got := r.camp_rest()
		Sfx.play("ward")
		_done("You sleep beside the embers. [color=#e06a5a]+%d HP[/color]." % got))
	_button("Tend: upgrade a card", func():
		var dv := DeckViewer.open(self, "upgrade")
		dv.chosen.connect(func(i):
			r.upgrade_card(i)
			r.status = "map"
			Sfx.play("grow")
			_done("Your %s grows stronger." % CardDB.get_def(r.deck[i]["id"], true)["name"])))


# ------------------------------------------------------------------ shrine

func _shrine() -> void:
	var r := Game.run
	var ev := EventDB.get_def(r.current_event)
	_heading(ev["title"], ev["text"])
	for i in ev["options"].size():
		var idx: int = i
		_button(ev["options"][i]["label"], func():
			var note := r.choose_event_option(r.current_event, idx)
			Sfx.play("card")
			_done(note), r.event_option_enabled(r.current_event, i))


# ------------------------------------------------------------------ market

func _market() -> void:
	var r := Game.run
	_clear()
	_heading("The Pedlar", "A hunched pedlar in a coat of moss-stitched sacks. \"Seeds, charms, cures. Gold only.\"")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	body.add_child(row)
	var items: Array = r.market.get("items", [])
	var charm_row := HBoxContainer.new()
	charm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	charm_row.add_theme_constant_override("separation", 20)
	for i in items.size():
		var it: Dictionary = items[i]
		var idx := i
		if it["kind"] == "card":
			var col := VBoxContainer.new()
			col.add_theme_constant_override("separation", 6)
			var cv := CardView.new().setup(CardDB.get_def(it["id"], false), {"uid": i, "id": it["id"], "up": false})
			cv.set_state(not it["sold"] and r.gold >= int(it["price"]), false)
			cv.pressed.connect(func(_cv):
				if r.market_buy(idx):
					Sfx.play("grow")
					hud.refresh()
					Game.save_run()
					_market())
			col.add_child(cv)
			var price := Label.new()
			price.text = "SOLD" if it["sold"] else "%d gold" % it["price"]
			price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			price.add_theme_color_override("font_color", UITheme.GOLD if r.gold >= int(it["price"]) else UITheme.BLOOD)
			col.add_child(price)
			row.add_child(col)
		else:
			var cd := CharmDB.get_def(it["id"])
			var b := Button.new()
			b.text = "SOLD" if it["sold"] else "%s: %d gold" % [cd["name"], it["price"]]
			b.tooltip_text = cd["text"]
			b.disabled = it["sold"] or r.gold < int(it["price"])
			b.custom_minimum_size = Vector2(420, 60)
			b.pressed.connect(func():
				if r.market_buy(idx):
					Sfx.play("win")
					hud.refresh()
					Game.save_run()
					_market())
			charm_row.add_child(b)
	body.add_child(charm_row)
	var can_remove: bool = not r.market.get("removed", true) and r.gold >= int(r.market.get("remove_price", 75))
	_button("Uproot a card from your deck (%d gold)" % int(r.market.get("remove_price", 75)), func():
		var dv := DeckViewer.open(self, "remove")
		dv.chosen.connect(func(i):
			r.market_remove(i)
			Sfx.play("burn")
			hud.refresh()
			Game.save_run()
			_market()), can_remove)
	_button("Leave", func():
		r.leave_room()
		Game.save_run()
		Sfx.play("click")
		Game.goto_map())


class RoomBackdrop extends Control:
	var kind := ""
	var _t := 0.0
	func _process(d: float) -> void:
		_t += d
		queue_redraw()
	func _draw() -> void:
		for i in 24:
			var t := i / 23.0
			draw_rect(Rect2(0, size.y * t, size.x, size.y / 23.0 + 1), Color(0.03, 0.04, 0.04).lerp(Color(0.09, 0.07, 0.05), t))
		var c := Vector2(size.x / 2, size.y * 0.86)
		match kind:
			"camp":
				for k in 4:
					var r := 380.0 - k * 80.0 + sin(_t * 3.0 + k) * 8.0
					draw_circle(c, r, Color(1.0, 0.5, 0.15, 0.05 + k * 0.03))
				for k in 3:
					var h := 90.0 + 20.0 * sin(_t * 7.0 + k * 2.0)
					draw_colored_polygon(PackedVector2Array([c + Vector2(-40 + k * 40, 0), c + Vector2(-10 + k * 40 - 30, -h), c + Vector2(20 + k * 40 - 40, 0)]), Color(1, 0.55 + k * 0.1, 0.2, 0.85))
			"shrine":
				for k in 5:
					draw_circle(Vector2(size.x / 2, size.y * 0.45), 460.0 - k * 70, Color(0.6, 0.8, 0.5, 0.03))
			"market":
				for k in 6:
					var p := Vector2(size.x * (0.15 + k * 0.14), size.y * 0.92)
					draw_circle(p, 30 + 6 * sin(_t * 2.0 + k), Color(1, 0.8, 0.35, 0.08))
