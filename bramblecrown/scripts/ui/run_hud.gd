class_name RunHud
extends PanelContainer
## Top bar shown outside combat: HP, gold, floor, charms, deck viewer.

var _label: RichTextLabel
var _charms: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	offset_left = 20
	offset_right = -20
	offset_top = 16
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	add_child(h)
	var name_l := Label.new()
	name_l.text = "Wren"
	name_l.add_theme_font_override("font", UITheme.font("title"))
	name_l.add_theme_font_size_override("font_size", 28)
	name_l.add_theme_color_override("font_color", UITheme.GOLD)
	h.add_child(name_l)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.custom_minimum_size = Vector2(620, 0)
	_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_label.add_theme_font_size_override("normal_font_size", 24)
	h.add_child(_label)
	_charms = HBoxContainer.new()
	_charms.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_charms)
	var deck := Button.new()
	deck.text = "Deck"
	deck.focus_mode = Control.FOCUS_NONE
	deck.pressed.connect(func(): DeckViewer.open(get_tree().current_scene, "view"))
	h.add_child(deck)
	refresh()


func refresh() -> void:
	var r := Game.run
	if r == null:
		return
	_label.text = "[color=#e06a5a]HP %d/%d[/color]    [color=#eec060]Gold %d[/color]    Floor %d    %s" % [
		r.hp, r.max_hp, r.gold, r.floor_num, r.region_def()["name"]]
	for ch in _charms.get_children():
		ch.queue_free()
	for id in r.charms:
		var d := CharmDB.get_def(id)
		var b := Label.new()
		b.text = d["name"]
		b.tooltip_text = d["text"]
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", UITheme.LEAF)
		b.add_theme_stylebox_override("normal", UITheme.box(Color(0.1, 0.12, 0.08), UITheme.LEAF.darkened(0.4), 1, 6, 6))
		_charms.add_child(b)
