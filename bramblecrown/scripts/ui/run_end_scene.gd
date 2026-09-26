extends Control
## Victory or defeat summary.


func _ready() -> void:
	theme = UITheme.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.04)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var r := Game.run
	var won := r != null and r.status == "victory"
	var v := VBoxContainer.new()
	UITheme.anchor(v, Control.PRESET_CENTER, Vector2(-500, -260), Vector2(1000, 520))
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 24)
	add_child(v)
	var h := Label.new()
	h.text = "The Road Continues" if won else "The Blight Takes Root"
	h.add_theme_font_override("font", UITheme.font("title"))
	h.add_theme_font_size_override("font_size", 64)
	h.add_theme_color_override("font_color", UITheme.LEAF if won else UITheme.BLIGHT)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var s := Label.new()
	if r:
		s.text = "Floor %d reached · %d fights won · %d elites · %d cards played\nDeck of %d cards · %d charms" % [
			r.floor_num, r.stats["fights"], r.stats["elites"], r.stats["cards_played"], r.deck.size(), r.charms.size()]
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_font_size_override("font_size", 26)
	v.add_child(s)
	var note := Label.new()
	note.text = "The Splintered Queen falls, and the Glasswood holds its own light again. You have cleared the three regions in this development build. Ironroot Deeps and the Crown of Thorns are still to come." if won else "Another Grovewalker will take up the seed."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", UITheme.INK_DIM)
	v.add_child(note)
	var b := Button.new()
	b.text = "Return to Title"
	b.custom_minimum_size = Vector2(320, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): Game.run = null; Game.goto_title())
	v.add_child(b)
	Sfx.play_music("title")
