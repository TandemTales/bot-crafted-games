extends Control
## Post-fight rewards: gold (already added), optional charm, choose one of three cards.

var hud: RunHud
var _cards_box: HBoxContainer
var _charm_btn: Button


func _ready() -> void:
	theme = UITheme.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var r := Game.run
	add_child(RoomStage.create("reward", r.region_def().get("theme", "marsh"), "top"))
	add_child(RoomStage.shade("bottom"))
	hud = RunHud.new()
	add_child(hud)
	var v := VBoxContainer.new()
	UITheme.anchor(v, Control.PRESET_CENTER_TOP, Vector2(-640, 120), Vector2(1280, 930))
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(v)
	var h := Label.new()
	h.text = "The bells fall silent" if r.region_def().get("theme", "") == "cloister" else "The clearing is quiet again"
	if r.region_def().get("theme", "") == "glasswood":
		h.text = "The fractured light grows still"
	h.add_theme_font_override("font", UITheme.font("title"))
	h.add_theme_font_size_override("font_size", 52)
	h.add_theme_color_override("font_color", UITheme.GOLD)
	h.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	h.add_theme_constant_override("outline_size", 10)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var g := Label.new()
	g.text = "+%d gold" % int(r.reward.get("gold", 0))
	g.add_theme_font_size_override("font_size", 28)
	g.add_theme_color_override("font_color", Color(0.93, 0.75, 0.38))
	g.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	g.add_theme_constant_override("outline_size", 6)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(g)
	# The Grovewalker stands in the clearing in this gap.
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 250 if r.reward.get("charm", "") == "" else 170)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap)
	if r.reward.get("charm", "") != "":
		var cd := CharmDB.get_def(r.reward["charm"])
		_charm_btn = Button.new()
		_charm_btn.text = "Take charm: %s (%s)" % [cd["name"], cd["text"]]
		_charm_btn.custom_minimum_size = Vector2(0, 60)
		_charm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_charm_btn.pressed.connect(func():
			r.take_reward_charm()
			_charm_btn.disabled = true
			_charm_btn.text = "Took %s" % cd["name"]
			Sfx.play("win")
			hud.refresh()
			Game.save_run())
		v.add_child(_charm_btn)
	var pick := Label.new()
	pick.text = "Choose a card to add to your deck"
	pick.add_theme_font_size_override("font_size", 26)
	pick.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	pick.add_theme_constant_override("outline_size", 6)
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pick)
	_cards_box = HBoxContainer.new()
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_box.add_theme_constant_override("separation", 40)
	v.add_child(_cards_box)
	for id in r.reward.get("cards", []):
		var cv := CardView.new().setup(CardDB.get_def(id, false), {"uid": 0, "id": id, "up": false})
		cv.pressed.connect(func(_cv):
			r.take_reward_card(id)
			Sfx.play("grow")
			_leave())
		_cards_box.add_child(cv)
	var skip := Button.new()
	skip.text = "Skip card"
	skip.custom_minimum_size = Vector2(260, 56)
	skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip.pressed.connect(_leave)
	v.add_child(skip)
	Sfx.play_music("map")


func _leave() -> void:
	Sfx.play("click")
	var r := Game.run
	if r.reward.get("charm", "") != "":
		r.take_reward_charm()
	r.leave_reward()
	Game.save_run()
	if r.status == "victory":
		Game.record_end(true)
		Game.goto_scene("res://scenes/run_end.tscn")
	else:
		Game.route_to_status()
