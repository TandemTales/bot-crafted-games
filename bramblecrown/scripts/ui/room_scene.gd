extends Control
## Non-combat rooms: campfire, shrine event, and pedlar market.

var hud: RunHud
var body: VBoxContainer


func _ready() -> void:
	theme = UITheme.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var st: String = Game.run.status
	add_child(RoomStage.create(st, Game.run.region_def().get("theme", "marsh"), "left"))
	add_child(RoomStage.shade("right"))
	hud = RunHud.new()
	add_child(hud)
	body = VBoxContainer.new()
	if st == "market":
		# Five cards need most of the width; the pedlar keeps the left edge.
		UITheme.anchor(body, Control.PRESET_CENTER_RIGHT, Vector2(-1420, -380), Vector2(1380, 800))
	else:
		UITheme.anchor(body, Control.PRESET_CENTER_RIGHT, Vector2(-880, -360), Vector2(800, 760))
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
		s.custom_minimum_size = Vector2(760, 0)
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
	_heading("Campfire", "Candle-wax and wet stone. The Blight will not cross a lit hearth tonight." if r.region_def().get("theme", "") == "cloister" else "The peat smoke keeps the Blight at bay for a night.")
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

