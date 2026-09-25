extends Node3D
## Combat controller: wires CombatState to the BoardView, hand, HUD and input.

const COL_MOVE := Color(0.55, 0.95, 0.45, 0.42)
const COL_TARGET := Color(1.0, 0.82, 0.38, 0.5)
const COL_GROW := Color(0.5, 1.0, 0.35, 0.8)
const COL_CLEAR := Color(0.95, 0.95, 0.8, 0.7)
const COL_BURN := Color(1.0, 0.45, 0.15, 0.85)
const COL_SPREAD := Color(0.78, 0.32, 1.0, 0.6)
const COL_DANGER := Color(1.0, 0.25, 0.2, 0.75)
const COL_HOVER := Color(1, 1, 1, 0.35)

var c: CombatState
var board: BoardView
var rig: CameraRig
var ui: CanvasLayer
var hand_root: Control
var card_views: Array[CardView] = []
var plates := {}
var selected_uid := -1
var hover_hex: Variant = null
var hover_card: CardView = null
var busy := false
var ended := false
var _pad_cursor := Vector2i.ZERO
var _pad_cd := 0.0

# HUD widgets
var hud_hp: UnitPlate
var energy_label: Label
var move_label: Label
var grove_label: Label
var pile_label: Label
var hint_label: RichTextLabel
var end_btn: Button
var banner: Label
var info_panel: PanelContainer
var info_text: RichTextLabel
var title_label: Label
var pause_layer: Control
var float_root: Control


func _ready() -> void:
	if Game.combat == null:
		# Direct scene launch (debug): start a throwaway run.
		Game.run = RunState.new()
		Game.run.new_run(4242)
		Game.run.enter_node(Game.run.available_nodes()[0])
		Game.combat = Game.run.make_combat()
	c = Game.combat
	BoardView.make_environment(self)
	board = BoardView.new()
	add_child(board)
	board.build(c, Game.run.seed_value + Game.run.floor_num)
	rig = CameraRig.new()
	add_child(rig)
	rig.frame_radius(c.radius)
	_build_ui()
	_refresh_all()
	var boss: bool = c.encounter.get("boss", false)
	Sfx.play_music("battle_boss" if boss else "battle")
	_show_banner(c.encounter.get("name", "Ambush"), 1.6)


# ------------------------------------------------------------------ UI construction

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.theme()
	ui.add_child(root)
	float_root = Control.new()
	float_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	float_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(float_root)
	# Top-left: Grovewalker status.
	var tl := PanelContainer.new()
	tl.position = Vector2(24, 20)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tl)
	var tlv := VBoxContainer.new()
	tl.add_child(tlv)
	var who := Label.new()
	who.text = "Wren, Grovewalker"
	who.add_theme_font_override("font", UITheme.font("heading"))
	who.add_theme_font_size_override("font_size", 24)
	who.add_theme_color_override("font_color", UITheme.GOLD)
	tlv.add_child(who)
	hud_hp = UnitPlate.new()
	hud_hp.is_player = true
	hud_hp.custom_minimum_size = Vector2(UnitPlate.W, 60)
	hud_hp.scale = Vector2(1.6, 1.6)
	var hp_holder := Control.new()
	hp_holder.custom_minimum_size = Vector2(250, 70)
	hp_holder.add_child(hud_hp)
	tlv.add_child(hp_holder)
	grove_label = Label.new()
	grove_label.add_theme_font_size_override("font_size", 20)
	grove_label.add_theme_color_override("font_color", UITheme.LEAF)
	grove_label.mouse_filter = Control.MOUSE_FILTER_STOP
	grove_label.tooltip_text = UITheme.KEYWORDS["Grove"]
	tlv.add_child(grove_label)
	# Top-center: encounter title.
	title_label = Label.new()
	title_label.add_theme_font_override("font", UITheme.font("title"))
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", UITheme.INK)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("outline_size", 8)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.anchor(title_label, Control.PRESET_CENTER_TOP, Vector2(-400, 18), Vector2(800, 40))
	root.add_child(title_label)
	# Bottom-left: energy seed + movement.
	var bl := Control.new()
	UITheme.anchor(bl, Control.PRESET_BOTTOM_LEFT, Vector2(30, -250), Vector2(200, 200))
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bl)
	var orb := EnergyOrb.new()
	orb.scene = self
	orb.position = Vector2(20, 0)
	orb.size = Vector2(130, 130)
	orb.tooltip_text = UITheme.KEYWORDS["Energy"]
	orb.mouse_filter = Control.MOUSE_FILTER_STOP
	bl.add_child(orb)
	energy_label = Label.new()
	energy_label.add_theme_font_override("font", UITheme.font("title"))
	energy_label.add_theme_font_size_override("font_size", 44)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_label.size = Vector2(130, 130)
	energy_label.position = Vector2(20, 0)
	energy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bl.add_child(energy_label)
	move_label = Label.new()
	move_label.add_theme_font_size_override("font_size", 22)
	move_label.position = Vector2(0, 140)
	move_label.size = Vector2(190, 30)
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.tooltip_text = UITheme.KEYWORDS["Movement"]
	move_label.mouse_filter = Control.MOUSE_FILTER_STOP
	bl.add_child(move_label)
	pile_label = Label.new()
	pile_label.add_theme_font_size_override("font_size", 18)
	pile_label.add_theme_color_override("font_color", UITheme.INK_DIM)
	pile_label.position = Vector2(0, 172)
	pile_label.size = Vector2(190, 30)
	pile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.add_child(pile_label)
	# Bottom-right: end turn.
	end_btn = Button.new()
	end_btn.text = "End Turn"
	UITheme.anchor(end_btn, Control.PRESET_BOTTOM_RIGHT, Vector2(-250, -150), Vector2(210, 70))
	end_btn.add_theme_font_size_override("font_size", 30)
	end_btn.pressed.connect(_on_end_turn)
	end_btn.focus_mode = Control.FOCUS_NONE
	root.add_child(end_btn)
	var end_hint := Label.new()
	end_hint.text = "Space"
	end_hint.add_theme_font_size_override("font_size", 16)
	end_hint.add_theme_color_override("font_color", UITheme.INK_DIM)
	UITheme.anchor(end_hint, Control.PRESET_BOTTOM_RIGHT, Vector2(-250, -74), Vector2(210, 24))
	end_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(end_hint)
	# Top-right: charms and menu.
	var tr := HBoxContainer.new()
	UITheme.anchor(tr, Control.PRESET_TOP_RIGHT, Vector2(-420, 22), Vector2(396, 50))
	tr.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(tr)
	for ch in Game.run.charms:
		var cd := CharmDB.get_def(ch)
		var b := CharmBadge.new()
		b.charm_id = ch
		b.tooltip_text = "%s\n%s" % [cd["name"], cd["text"]]
		tr.add_child(b)
	var menu := Button.new()
	menu.text = "Menu"
	menu.focus_mode = Control.FOCUS_NONE
	menu.pressed.connect(_toggle_pause)
	tr.add_child(menu)
	# Hint line above the hand.
	hint_label = RichTextLabel.new()
	hint_label.bbcode_enabled = true
	hint_label.scroll_active = false
	hint_label.fit_content = true
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.anchor(hint_label, Control.PRESET_CENTER_BOTTOM, Vector2(-500, -300), Vector2(1000, 36))
	hint_label.add_theme_font_size_override("normal_font_size", 22)
	hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	hint_label.add_theme_constant_override("outline_size", 6)
	root.add_child(hint_label)
	# Hand.
	hand_root = Control.new()
	UITheme.anchor(hand_root, Control.PRESET_CENTER_BOTTOM, Vector2(0, 0))
	hand_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hand_root)
	# Info panel (hovered hex / enemy).
	info_panel = PanelContainer.new()
	info_panel.custom_minimum_size = Vector2(340, 0)
	info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.visible = false
	root.add_child(info_panel)
	info_text = RichTextLabel.new()
	info_text.bbcode_enabled = true
	info_text.fit_content = true
	info_text.scroll_active = false
	info_text.custom_minimum_size = Vector2(340, 0)
	info_text.add_theme_font_size_override("normal_font_size", 19)
	info_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(info_text)
	# Turn banner.
	banner = Label.new()
	banner.add_theme_font_override("font", UITheme.font("title"))
	banner.add_theme_font_size_override("font_size", 72)
	banner.add_theme_color_override("font_color", UITheme.GOLD)
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	banner.add_theme_constant_override("outline_size", 14)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.anchor(banner, Control.PRESET_CENTER, Vector2(-700, -200), Vector2(1400, 100))
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.modulate.a = 0
	root.add_child(banner)
	# Pause overlay.
	pause_layer = _build_pause()
	root.add_child(pause_layer)


func _build_pause() -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	var box := VBoxContainer.new()
	UITheme.anchor(box, Control.PRESET_CENTER, Vector2(-160, -170), Vector2(320, 340))
	box.add_theme_constant_override("separation", 14)
	dim.add_child(box)
	var t := Label.new()
	t.text = "Paused"
	t.add_theme_font_override("font", UITheme.font("title"))
	t.add_theme_font_size_override("font_size", 48)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	for pair in [["Resume", _toggle_pause], ["Toggle Fullscreen", Game.toggle_fullscreen],
			["Save & Quit to Title", func(): Game.save_run(); Game.goto_title()],
			["Abandon Run", _abandon]]:
		var b := Button.new()
		b.text = pair[0]
		b.custom_minimum_size = Vector2(320, 56)
		b.pressed.connect(pair[1])
		box.add_child(b)
	return dim


func _toggle_pause() -> void:
	pause_layer.visible = not pause_layer.visible
	Sfx.play("click")


func _abandon() -> void:
	Game.run.status = "defeat"
	Game.record_end(false)
	Game.goto_scene("res://scenes/run_end.tscn")


# ------------------------------------------------------------------ refresh

func _refresh_all() -> void:
	_sync_hand()
	_refresh_hud()
	_refresh_board_overlays()
	_sync_plates()


func _refresh_hud() -> void:
	var p := c.player
	hud_hp.update_from({"title": "", "hp": p["hp"], "max_hp": p["max_hp"], "ward": p["ward"], "statuses": {}})
	energy_label.text = "%d/%d" % [p["energy"], CombatState.BASE_ENERGY]
	move_label.text = "Movement %d" % p["move"]
	var g := c.grove().size()
	grove_label.text = "Grove %d  (+%d)" % [g, g / 3] if g > 0 else "No Grove: stand in Thicket"
	pile_label.text = "Draw %d · Discard %d" % [c.draw_pile.size(), c.discard.size()]
	title_label.text = "%s · Turn %d" % [c.encounter.get("name", ""), c.turn]
	end_btn.disabled = busy or c.phase != "player"
	var sel := _selected_inst()
	if busy:
		hint_label.text = ""
	elif not sel.is_empty():
		var d := c.card_def(sel)
		match d["target"]:
			"self":
				hint_label.text = "[center]Click [b]%s[/b] again, or click the board, to cast. Right-click cancels.[/center]" % d["name"]
			"enemy":
				hint_label.text = "[center]Choose an enemy within %d for [b]%s[/b].[/center]" % [d["range"], d["name"]]
			_:
				hint_label.text = "[center]Choose a hex within %d for [b]%s[/b].[/center]" % [d["range"], d["name"]]
	elif c.phase == "player":
		hint_label.text = "[center][color=#a6d86a]Green hexes[/color]: click to walk. Pick a card to play it.[/center]" if int(p["move"]) > 0 else "[center]Pick a card, or end your turn.[/center]"


func _sync_plates() -> void:
	var live := {}
	for e in c.enemies:
		live[e["uid"]] = true
		if not plates.has(e["uid"]):
			var pl := UnitPlate.new()
			float_root.add_child(pl)
			plates[e["uid"]] = pl
		var prev := c.enemy_preview(e)
		var icons: Array = []
		for a in e["intent"].get("actions", []):
			match a["t"]:
				"attack":
					icons.append({"kind": "attack", "n": c.attack_damage(e, int(a["dmg"]), prev["end"]), "hot": prev["hits"]})
				"spread", "blight_self":
					icons.append({"kind": "spread", "n": a.get("hexes", []).size()})
				"summon":
					icons.append({"kind": "summon"})
				"ward":
					icons.append({"kind": "ward", "n": a["n"]})
				"strength":
					icons.append({"kind": "strength", "n": a["n"]})
		plates[e["uid"]].update_from({"title": e["def"]["name"], "hp": e["hp"], "max_hp": e["max_hp"],
			"ward": e["ward"], "statuses": e["statuses"], "intent": {"name": e["intent"].get("name", ""), "icons": icons}})
	for uid in plates.keys():
		if not live.has(uid):
			plates[uid].queue_free()
			plates.erase(uid)


func _refresh_board_overlays() -> void:
	var ov := {}
	var paths: Array = []
	# Telegraphs.
	for e in c.enemies:
		for a in e["intent"].get("actions", []):
			if a["t"] in ["spread", "blight_self"]:
				for h in a.get("hexes", []):
					ov[h] = [COL_SPREAD, true]
		var pv := c.enemy_preview(e)
		var col := Color(1, 0.35, 0.3, 0.9) if pv["attack"] else Color(0.75, 0.4, 1.0, 0.9)
		if not pv["path"].is_empty():
			paths.append({"from": e["pos"], "path": pv["path"], "color": col})
		if pv["hits"]:
			ov[c.player["pos"]] = [COL_DANGER, true]
	var inst := _selected_inst()
	var pending := {}
	if not busy and c.phase == "player":
		if inst.is_empty():
			for h in c.reachable():
				if not ov.has(h):
					ov[h] = [COL_MOVE, false]
		else:
			var targets := c.valid_targets(inst)
			for h in targets:
				if not ov.has(h) or c.card_def(inst)["target"] == "enemy":
					ov[h] = [COL_TARGET, false]
			var tgt: Variant = null
			if c.card_def(inst)["target"] == "self":
				tgt = c.player["pos"]
			elif hover_hex != null and targets.has(hover_hex):
				tgt = hover_hex
			if tgt != null:
				var pr := c.preview_card(inst, tgt)
				for h in pr["grow"]:
					ov[h] = [COL_GROW, false]
				for h in pr["blight_clear"]:
					ov[h] = [COL_CLEAR, false]
				for h in pr["burn"]:
					ov[h] = [COL_BURN, false]
				pending = pr["damage"]
				if c.card_def(inst)["target"] != "self":
					ov[tgt] = [Color(1, 1, 0.8, 0.8), false]
	if hover_hex != null and not ov.has(hover_hex):
		ov[hover_hex] = [COL_HOVER, false]
	board.set_overlays(ov)
	board.set_paths(paths)
	for uid in plates:
		plates[uid].pending_damage = int(pending.get(uid, 0))
		plates[uid].highlight = pending.has(uid)
		plates[uid].queue_redraw()


func _selected_inst() -> Dictionary:
	if selected_uid < 0:
		return {}
	var i := c.hand_index(selected_uid)
	return {} if i < 0 else c.hand[i]


# ------------------------------------------------------------------ hand

func _sync_hand() -> void:
	var existing := {}
	for cv in card_views:
		existing[cv.inst["uid"]] = cv
	var next: Array[CardView] = []
	for inst in c.hand:
		var cv: CardView = existing.get(inst["uid"])
		if cv == null:
			cv = CardView.new().setup(c.card_def(inst), inst)
			cv.pressed.connect(_on_card_pressed)
			cv.hovered.connect(_on_card_hovered)
			hand_root.add_child(cv)
			# Deal in from the draw pile.
			cv.position = Vector2(-900, -120)
			cv.rotation = -0.4
		else:
			existing.erase(inst["uid"])
		next.append(cv)
	for uid in existing:
		var old: CardView = existing[uid]
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(old, "position", old.position + Vector2(0, -180), 0.25)
		tw.tween_property(old, "modulate:a", 0.0, 0.25)
		tw.chain().tween_callback(old.queue_free)
	card_views = next
	for cv in card_views:
		cv.set_state(c.can_afford(cv.inst) and c.phase == "player" and not busy, cv.inst["uid"] == selected_uid)


func _layout_hand(delta: float) -> void:
	var n := card_views.size()
	if n == 0:
		return
	var vp := get_viewport().get_visible_rect().size
	var ui_scale := vp.y / 1080.0
	hand_root.scale = Vector2.ONE * ui_scale * 0.9
	var spacing := minf(196.0, 1100.0 / maxf(1, n))
	var total := spacing * (n - 1)
	for i in n:
		var cv := card_views[i]
		var t := (i - (n - 1) / 2.0)
		var x := -total / 2.0 + i * spacing - CardView.SIZE.x / 2
		# Resting cards tuck partly below the screen edge; hovered cards rise fully into view.
		var y := -CardView.SIZE.y * 0.74 + absf(t) * absf(t) * 4.0
		var rot := t * 0.035
		var sc := 1.0
		if cv == hover_card or cv.inst["uid"] == selected_uid:
			y = -CardView.SIZE.y - 40
			rot = 0.0
			sc = 1.12
			cv.z_index = 10
		else:
			cv.z_index = i
		var k := clampf(delta * 14.0, 0, 1)
		cv.position = cv.position.lerp(Vector2(x, y), k)
		cv.rotation = lerpf(cv.rotation, rot, k)
		cv.scale = cv.scale.lerp(Vector2.ONE * sc, k)


func _on_card_hovered(cv: CardView, on: bool) -> void:
	if on:
		hover_card = cv
		Sfx.play("click", 0.1, -14)
	elif hover_card == cv:
		hover_card = null


func _on_card_pressed(cv: CardView) -> void:
	if busy or c.phase != "player" or pause_layer.visible:
		return
	var uid: int = cv.inst["uid"]
	if selected_uid == uid:
		if c.card_def(cv.inst)["target"] == "self":
			_play(uid, c.player["pos"])
		else:
			selected_uid = -1
	elif c.can_afford(cv.inst):
		selected_uid = uid
		Sfx.play("card", 0.05, -6)
	else:
		_float_text(get_viewport().get_mouse_position() + Vector2(0, -60), "Not enough Energy", UITheme.BLOOD)
	_refresh_all()


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if ended:
		return
	if event.is_action_pressed("cancel"):
		if selected_uid >= 0:
			selected_uid = -1
			_refresh_all()
		else:
			_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if pause_layer.visible or busy:
		return
	if event is InputEventMouseMotion:
		var h = board.pick(rig.camera, event.position)
		if h != hover_hex:
			hover_hex = h
			_refresh_board_overlays()
			_update_info()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var h = board.pick(rig.camera, event.position)
			_click_hex(h)
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_uid >= 0:
			selected_uid = -1
			_refresh_all()
	elif event.is_action_pressed("end_turn"):
		_on_end_turn()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_1 and k <= KEY_9:
			var i := k - KEY_1
			if i < card_views.size():
				_on_card_pressed(card_views[i])
		elif k == KEY_ENTER and selected_uid >= 0 and hover_hex != null:
			_click_hex(hover_hex)
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_A:
				if hover_hex == null:
					hover_hex = c.player["pos"]
				_click_hex(hover_hex)
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
				_cycle_card(-1 if event.button_index == JOY_BUTTON_DPAD_LEFT else 1)
			JOY_BUTTON_START:
				_toggle_pause()


func _cycle_card(dir: int) -> void:
	if card_views.is_empty():
		return
	var idx := -1
	for i in card_views.size():
		if card_views[i].inst["uid"] == selected_uid:
			idx = i
	idx = wrapi(idx + dir, 0, card_views.size())
	selected_uid = card_views[idx].inst["uid"]
	_refresh_all()


func _process(delta: float) -> void:
	_layout_hand(delta)
	_place_plates()
	# Controller hex cursor.
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	_pad_cd -= delta
	if stick.length() > 0.5 and _pad_cd <= 0.0 and not busy:
		_pad_cd = 0.18
		var base: Vector2i = hover_hex if hover_hex != null else c.player["pos"]
		var world_dir := Vector3(stick.x, 0, stick.y)
		var best := base
		var best_dot := -2.0
		for n in Hex.neighbors(base):
			if not c.terrain.has(n):
				continue
			var d := (Hex.to_world(n, 1.0) - Hex.to_world(base, 1.0)).normalized()
			var dot := d.dot(world_dir.normalized())
			if dot > best_dot:
				best_dot = dot
				best = n
		hover_hex = best
		_refresh_board_overlays()
		_update_info()


func _place_plates() -> void:
	var cam := rig.camera
	for uid in plates:
		if not board.units.has(uid):
			continue
		var n: Node3D = board.units[uid]
		var e = c.enemy_by_uid(uid)
		var hgt := 1.5 * float(e["def"].get("size", 1.0)) + 0.4 if e != null else 1.8
		var sp := cam.unproject_position(n.position + Vector3(0, hgt, 0))
		var pl: UnitPlate = plates[uid]
		pl.position = sp - Vector2(UnitPlate.W / 2, 60)
	if info_panel.visible:
		var mp := get_viewport().get_mouse_position()
		info_panel.position = mp + Vector2(24, 24)
		var vp := get_viewport().get_visible_rect().size
		if info_panel.position.x + info_panel.size.x > vp.x:
			info_panel.position.x = mp.x - info_panel.size.x - 24
		if info_panel.position.y + info_panel.size.y > vp.y - 340:
			info_panel.position.y = mp.y - info_panel.size.y - 24


func _update_info() -> void:
	if hover_hex == null or hover_card != null:
		info_panel.visible = false
		return
	var h: Vector2i = hover_hex
	var lines: Array = []
	var e = c.enemy_at(h)
	if e != null:
		lines.append("[b][color=#e8c070]%s[/color][/b]  %d/%d HP" % [e["def"]["name"], e["hp"], e["max_hp"]])
		var mv: Dictionary = e["intent"]
		lines.append("Intends: [b]%s[/b]" % mv.get("name", "?"))
		var pv := c.enemy_preview(e)
		for a in mv.get("actions", []):
			match a["t"]:
				"attack":
					lines.append("• Attack for [color=#ff7060]%d[/color] (range %d)%s" % [c.attack_damage(e, int(a["dmg"]), pv["end"]), a["range"],
						"  [color=#ff7060]will hit you[/color]" if pv["hits"] else "  [color=#a0a0a0]you're out of reach[/color]"])
				"spread":
					lines.append("• Spread [color=#c48be8]Blight[/color] on %d marked hexes near you" % a.get("hexes", []).size())
				"blight_self":
					lines.append("• Rot %d marked hexes around itself" % a.get("hexes", []).size())
				"summon":
					lines.append("• Summon %s" % EnemyDB.ENEMIES[a["enemy"]]["name"])
				"ward":
					lines.append("• Gain %d Ward" % a["n"])
				"strength":
					lines.append("• Gain %d strength" % a["n"])
		if e["def"].get("flying", false):
			lines.append("[i]Flies: ignores Thicket and water.[/i]")
		if e["def"].get("trample", false):
			lines.append("[i]Tramples: destroys Thicket it walks through.[/i]")
	elif h == c.player["pos"]:
		lines.append("[b][color=#e8c070]Wren[/color][/b]  %d/%d HP" % [c.player["hp"], c.player["max_hp"]])
	var g: String = c.growth[h]
	var t: String = c.terrain[h]
	match t:
		"water":
			lines.append("[color=#8fb8c0]Black water[/color]: impassable except to fliers.")
		"stone":
			lines.append("[color=#bbbbbb]Standing stone[/color]: blocks movement.")
	match g:
		"thicket":
			lines.append("[color=#a6d86a]Thicket[/color]: enemies pay 2 Movement to enter.")
		"blight":
			lines.append("[color=#c48be8]Blight[/color]: enemies here deal +2. Ending your turn here costs 2 HP.")
	info_text.text = UITheme.keywordize("\n".join(lines)) if not lines.is_empty() else ""
	info_panel.visible = not lines.is_empty()
	info_panel.reset_size()


func _click_hex(h: Variant) -> void:
	if busy or c.phase != "player":
		return
	var inst := _selected_inst()
	if not inst.is_empty():
		var def := c.card_def(inst)
		if def["target"] == "self":
			_play(selected_uid, c.player["pos"])
		elif h != null and c.can_play(inst, h):
			_play(selected_uid, h)
		else:
			Sfx.play("click", 0.0, -8)
		return
	if h == null:
		return
	if c.reachable().has(h):
		_run_events(c.move_player(h))


func _play(uid: int, target: Vector2i) -> void:
	selected_uid = -1
	Game.run.stats["cards_played"] = int(Game.run.stats["cards_played"]) + 1
	_run_events(c.play_card(uid, target))


func _on_end_turn() -> void:
	if busy or c.phase != "player" or pause_layer.visible:
		return
	selected_uid = -1
	Sfx.play("turn")
	_run_events(c.end_turn())


# ------------------------------------------------------------------ event playback

func _run_events(events: Array) -> void:
	busy = true
	_refresh_all()
	for ev in events:
		await _play_event(ev)
	busy = false
	board.face_units()
	_refresh_all()
	_update_info()
	if c.phase == "won":
		_on_won()
	elif c.phase == "lost":
		_on_lost()


func _play_event(ev: Dictionary) -> void:
	match ev["type"]:
		"card_played":
			Sfx.play("card")
			_sync_hand()
		"move":
			var key = "player" if ev["who"] is String else ev["who"]
			Sfx.play("step", 0.1, -4)
			await board.move_unit(key, ev["path"])
		"board":
			var cause: String = ev.get("cause", "")
			board.apply_growth(ev["changes"])
			for h in ev["changes"]:
				board.growth_burst(h, ev["changes"][h] if cause != "burn" else "burn")
			match cause:
				"grow":
					Sfx.play("grow")
				"blight", "trample":
					Sfx.play("blight")
				"burn":
					Sfx.play("burn")
					rig.shake(0.6)
				"cleanse":
					Sfx.play("ward")
			await _wait(0.28)
		"damage":
			var tgt = ev["target"]
			var key = "player" if tgt is String else tgt
			if board.units.has(key):
				board.flash_hit(key)
				var n: Node3D = board.units[key]
				var sp := rig.camera.unproject_position(n.position + Vector3(0, 1.3, 0))
				if int(ev["amount"]) > 0:
					_float_text(sp, "-%d" % ev["amount"], UITheme.BLOOD if key is String else Color(1, 0.85, 0.5), 44)
				if int(ev.get("blocked", 0)) > 0:
					_float_text(sp + Vector2(40, 30), "blocked %d" % ev["blocked"], UITheme.WARD, 24)
			if key is String:
				Sfx.play("hurt")
				rig.shake(0.5 if int(ev["amount"]) > 0 else 0.15)
			else:
				Sfx.play("hit")
			_refresh_hud()
			_sync_plates()
			await _wait(0.16)
		"hp_loss":
			var sp := rig.camera.unproject_position(board.units["player"].position + Vector3(0, 1.3, 0))
			_float_text(sp, "Rot -%d" % ev["amount"], UITheme.BLIGHT, 36)
			Sfx.play("blight")
			_refresh_hud()
			await _wait(0.3)
		"ward":
			var key = "player" if ev["target"] is String else ev["target"]
			if board.units.has(key):
				var sp := rig.camera.unproject_position(board.units[key].position + Vector3(0, 1.6, 0))
				_float_text(sp, "+%d Ward" % ev["gain"], UITheme.WARD, 30)
			Sfx.play("ward")
			_refresh_hud()
			_sync_plates()
		"status":
			if board.units.has(ev["target"]):
				var sp := rig.camera.unproject_position(board.units[ev["target"]].position + Vector3(0, 1.8, 0))
				_float_text(sp, "%s %d" % [String(ev["status"]).capitalize(), ev["n"]], UITheme.GOLD, 26)
			_sync_plates()
		"death":
			board.kill_unit(ev["target"])
			Sfx.play("death")
			_sync_plates()
			await _wait(0.35)
		"summon":
			var e = c.enemy_by_uid(ev["target"])
			if e != null:
				board.add_enemy(e, true)
				Sfx.play("summon")
				_sync_plates()
			await _wait(0.3)
		"enemy_act":
			if board.units.has(ev["target"]):
				var sp := rig.camera.unproject_position(board.units[ev["target"]].position + Vector3(0, 2.2, 0))
				_float_text(sp, ev["name"], UITheme.INK, 28, 1.2)
			await _wait(0.3)
		"attack":
			await board.lunge(ev["source"], board.units["player"].position if board.units.has("player") else Vector3.ZERO)
		"miss":
			if board.units.has(ev["source"]):
				var sp := rig.camera.unproject_position(board.units[ev["source"]].position + Vector3(0, 1.8, 0))
				_float_text(sp, "Out of reach", UITheme.INK_DIM, 24)
		"draw", "reshuffle":
			_sync_hand()
			_refresh_hud()
			await _wait(0.05)
		"turn_start":
			_show_banner("Your Turn", 0.9)
			_refresh_hud()
		"end_turn":
			_sync_hand()
			_show_banner("Enemy Turn", 0.7)
			await _wait(0.5)
		"phase2":
			_show_banner("The Mire Mother rises in fury!", 1.8)
			rig.shake(1.0)
			await _wait(0.8)
		"energy", "move_points", "power":
			_refresh_hud()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _show_banner(text: String, hold: float) -> void:
	banner.text = text
	var tw := create_tween()
	banner.modulate.a = 0
	banner.scale = Vector2(1, 1)
	tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(hold)
	tw.tween_property(banner, "modulate:a", 0.0, 0.4)


func _float_text(at: Vector2, text: String, col: Color, fsize: int = 32, life: float = 0.9) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UITheme.font("title"))
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	float_root.add_child(l)
	l.reset_size()
	l.position = at - l.size / 2
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 60, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, life * 0.5).set_delay(life * 0.5)
	tw.chain().tween_callback(l.queue_free)


func _on_won() -> void:
	if ended:
		return
	ended = true
	Sfx.play("win")
	_show_banner("Victory", 1.2)
	await _wait(1.6)
	Game.run.finish_combat(c)
	Game.combat = null
	Game.save_run()
	Game.route_to_status()


func _on_lost() -> void:
	if ended:
		return
	ended = true
	Sfx.play("lose")
	_show_banner("The Blight takes you", 2.0)
	await _wait(2.6)
	Game.run.finish_combat(c)
	Game.combat = null
	Game.record_end(false)
	Game.goto_scene("res://scenes/run_end.tscn")


# ------------------------------------------------------------------ small widgets

class EnergyOrb extends Control:
	var scene
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var ctr := size / 2
		var e: int = scene.c.player["energy"] if scene and scene.c else 0
		draw_circle(ctr + Vector2(0, 4), 58, Color(0, 0, 0, 0.5))
		draw_circle(ctr, 58, Color(0.12, 0.2, 0.08))
		var t := Time.get_ticks_msec() / 1000.0
		var glow := 0.75 + 0.15 * sin(t * 2.5)
		draw_circle(ctr, 50, Color(0.35, 0.6, 0.18).lerp(Color(0.2, 0.2, 0.18), 0.0 if e > 0 else 0.8) * glow)
		draw_arc(ctr, 58, 0, TAU, 48, UITheme.GOLD, 4, true)
		for i in 3:
			var a := -PI / 2 + (i - 1) * 0.5
			var p := ctr + Vector2.from_angle(a) * 66
			draw_circle(p, 7, UITheme.LEAF if i < e else Color(0.2, 0.2, 0.18))


class CharmBadge extends Control:
	var charm_id := ""
	func _init() -> void:
		custom_minimum_size = Vector2(46, 46)
		mouse_filter = Control.MOUSE_FILTER_STOP
	func _draw() -> void:
		var ctr := size / 2
		draw_circle(ctr, 21, Color(0.08, 0.07, 0.05))
		draw_arc(ctr, 21, 0, TAU, 32, UITheme.GOLD, 2, true)
		var col := Color.from_hsv(float(hash(charm_id) % 360) / 360.0, 0.5, 0.85)
		draw_colored_polygon(PackedVector2Array([ctr + Vector2(0, -12), ctr + Vector2(10, 0), ctr + Vector2(0, 12), ctr + Vector2(-10, 0)]), col)
