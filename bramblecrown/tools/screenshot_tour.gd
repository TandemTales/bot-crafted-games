extends Node
## Packaged-build QA: Bramblecrown.exe --screenshot-tour <dir> [--shot-size WxH] [--tour-only r2]
## Walks title -> map -> combat (idle, targeting, enemy turn) -> reward -> camp/shrine/market ->
## region 2 map, fight, elite, boss -> quits. `--tour-only r2` skips straight to the region 2 shots.

var out_dir := ""
var res := Vector2i(1920, 1080)
var _shots: Array = []
var only := ""
var failures := 0
var save_hashes := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	for i in args.size():
		if args[i] == "--screenshot-tour" and i + 1 < args.size():
			out_dir = args[i + 1]
		if args[i] == "--shot-size" and i + 1 < args.size():
			var p := args[i + 1].split("x")
			res = Vector2i(int(p[0]), int(p[1]))
		if args[i] == "--tour-only" and i + 1 < args.size():
			only = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out_dir)
	for path in [Game.RUN_PATH, Game.PROFILE_PATH, Game.SETTINGS_PATH]:
		save_hashes[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	_run.call_deferred()


func _run() -> void:
	var win := get_window()
	win.mode = Window.MODE_WINDOWED
	win.borderless = true
	win.position = Vector2i.ZERO
	win.size = res
	await _wait(2.5)
	if only == "run5":
		await _ironroot()
		await _rooms(3)
		await _rail_input()
		_finish()
		return
	if only == "run4":
		await _glasswood()
		await _rooms(2)
		await _rail_input()
		_finish()
		return
	if only == "run3":
		await _region2()
		await _cloister_cards()
		await _rail_input()
		_finish()
		return
	if only == "r2":
		await _region2()
		_finish()
		return
	if only == "rooms":
		for reg in [0, 1]:
			await _rooms(reg)
		_finish()
		return
	await _shot("01_title")
	Game.clear_run()
	Game.new_run(4242)
	await _wait(1.5)
	await _shot("02_map")
	var r := Game.run
	r.enter_node(r.available_nodes()[0])
	Game.goto_combat()
	await _wait(3.5)
	await _shot("03_combat")
	var scene = get_tree().current_scene
	if scene and scene.has_method("_refresh_all"):
		# Select Sow (or the first card) and hover a target hex to show the preview.
		var pick := -1
		for inst in scene.c.hand:
			if inst["id"] == "sow":
				pick = inst["uid"]
		if pick < 0 and not scene.c.hand.is_empty():
			pick = scene.c.hand[0]["uid"]
		scene.selected_uid = pick
		var targets: Array = scene.c.valid_targets(scene.c.hand[scene.c.hand_index(pick)])
		if not targets.is_empty():
			scene.hover_hex = targets[targets.size() / 2]
		scene._refresh_all()
		await _wait(0.8)
		await _shot("04_combat_targeting")
		scene.selected_uid = -1
		scene.hover_hex = null
		scene._on_end_turn()
		await _wait(1.6)
		await _shot("05_enemy_turn")
		await _wait(4.0)
		# Fast-forward to victory for the reward screen.
		scene.c.phase = "won"
		scene.ended = true
		r.finish_combat(scene.c)
		Game.combat = null
		Game.route_to_status()
		await _wait(1.2)
		await _shot("06_reward")
	for st in ["camp", "shrine", "market"]:
		r.status = st
		if st == "shrine":
			r.current_event = "hermit_grafter"
		if st == "market":
			r.gold = 180
			r._stock_market()
		Game.route_to_status()
		await _wait(1.2)
		await _shot("07_%s" % st)
	await _region2()
	_finish()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("[tour] FAIL: ", message)


func _glasswood() -> void:
	Game.new_run(926)
	var r := Game.run
	r.region = 2
	r.generate_map()
	Game.goto_map()
	await _wait(1.2)
	await _shot("40_glasswood_map")
	var reg := r.region_def()
	for enc in reg["fights"] + reg["elites"] + [reg["boss"]]:
		r.current_encounter = enc
		r.status = "combat"
		Game.goto_combat()
		await _wait(3.2)
		var sc = get_tree().current_scene
		_check(sc.banner.modulate.a < 0.01, "encounter title has cleared before capture")
		_check(sc.board.theme == BoardView.THEMES["glasswood"], "Glasswood theme is active")
		_check(sc.board.units.size() == sc.c.enemies.size() + 1, "every Glasswood unit has a model")
		for enemy in sc.c.enemies:
			var panel: UnitPlate = sc.plates[enemy["uid"]]
			for action in enemy["intent"].get("actions", []):
				if action["t"] == "shield_allies":
					_check(panel.intent["icons"].any(func(ic): return ic["kind"] == "ally_ward"), "ally Ward is distinguished from self Ward")
		await _shot("41_" + enc)
		if enc == reg["boss"]:
			# Deliberately stage the phase boundary. This tests actual turn handling, not a boss win.
			var boss: Dictionary = sc.c.enemies[0]
			var animation: AnimationPlayer = sc.board.units[boss["uid"]].find_child("AnimationPlayer", true, false)
			_check(animation != null and animation.is_playing(), "Queen mantle animation imported and playing")
			sc.c._damage_enemy(boss, int(boss["hp"]) / 2 + 1)
			_check(boss["phase2"], "Queen switches phase")
			sc.c._choose_intent(boss)
			sc._refresh_all()
			await _shot("42_queen_phase2_intent")
			sc._on_end_turn()
			for frame in 100:
				await _wait(0.1)
				if not sc.busy:
					break
			_check(not sc.busy and sc.c.turn >= 2, "Queen phase-two enemy turn finishes")
			await _wait(1.4)
			await _shot("43_queen_phase2_resolved")
		# A checkpoint resume restarts the authored encounter, preserving normal files.
		var expected: String = enc
		Game.run = RunState.from_json(r.to_json())
		Game.goto_combat()
		await _wait(0.4)
		_check(Game.combat.encounter["id"] == expected, "native checkpoint resume: " + expected)
		r = Game.run
	r.status = "victory"
	Game.route_to_status()
	await _wait(0.7)
	await _shot("44_development_clear")
	Game.goto_title()
	await _wait(0.4)


func _ironroot() -> void:
	Game.new_run(1003)
	var r := Game.run
	r.region = 3
	r.generate_map()
	Game.goto_map()
	await _wait(1.2)
	await _shot("50_ironroot_map")
	var reg := r.region_def()
	for enc in reg["fights"] + reg["elites"] + [reg["boss"]]:
		r.current_encounter = enc
		r.status = "combat"
		Game.goto_combat()
		await _wait(3.2)
		var sc = get_tree().current_scene
		_check(sc.banner.modulate.a < 0.01, "encounter title has cleared before capture")
		_check(sc.board.theme == BoardView.THEMES["ironroot"], "Ironroot theme is active")
		_check(sc.board.units.size() == sc.c.enemies.size() + 1, "every Ironroot unit has a model")
		await _shot("51_" + enc)
		if enc == "iro_undermine":
			# Stage a telegraphed cave-in beside the Grovewalker, then resolve it natively.
			var tun: Dictionary = sc.c.enemies[0]
			tun["pattern_idx"] = 0
			sc.c._choose_intent(tun)
			var marked: Array = tun["intent"]["actions"][0]["hexes"]
			sc._refresh_all()
			var panel: UnitPlate = sc.plates[tun["uid"]]
			_check(panel.intent["icons"].any(func(ic): return ic["kind"] == "collapse"), "cave-in intent has its own icon")
			_check(marked.size() > 0 and sc.board.overlays[marked[0]].visible, "cave-in hexes are highlighted")
			await _shot("52_cave_in_telegraph")
			sc._on_end_turn()
			for frame in 100:
				await _wait(0.1)
				if not sc.busy:
					break
			_check(not sc.busy, "cave-in enemy turn finishes")
			var fell := 0
			for h in marked:
				if sc.c.terrain[h] == "stone":
					fell += 1
					_check(sc.board.tiles[h].scene_file_path.ends_with("hex_rubble.glb"), "fallen hex shows rubble")
			_check(fell > 0, "at least one marked hex collapsed")
			await _wait(1.0)
			await _shot("53_cave_in_resolved")
		if enc == reg["boss"]:
			var boss: Dictionary = sc.c.enemies[0]
			var animation: AnimationPlayer = sc.board.units[boss["uid"]].find_child("AnimationPlayer", true, false)
			_check(animation != null and animation.is_playing(), "Engine piston animation imported and playing")
			sc.c._damage_enemy(boss, int(boss["hp"]) / 2 + 1)
			_check(boss["phase2"], "Engine switches phase")
			sc.c._choose_intent(boss)
			sc._refresh_all()
			await _shot("54_engine_phase2_intent")
			sc._on_end_turn()
			for frame in 100:
				await _wait(0.1)
				if not sc.busy:
					break
			_check(not sc.busy and sc.c.turn >= 2, "Engine phase-two enemy turn finishes")
			await _wait(1.4)
			await _shot("55_engine_phase2_resolved")
		var expected: String = enc
		Game.run = RunState.from_json(r.to_json())
		Game.goto_combat()
		await _wait(0.4)
		_check(Game.combat.encounter["id"] == expected, "native checkpoint resume: " + expected)
		r = Game.run
	r.status = "victory"
	Game.route_to_status()
	await _wait(0.7)
	await _shot("56_development_clear")
	Game.goto_title()
	await _wait(0.4)


func _finish() -> void:
	var saves_unchanged := true
	for path in save_hashes:
		var now := FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
		saves_unchanged = saves_unchanged and now == save_hashes[path]
		_check(now == save_hashes[path], "normal player save/profile/settings unchanged: " + path)
	print("[tour] completed: %d screenshots, %d failures; normal saves unchanged=%s" % [_shots.size(), failures, saves_unchanged])
	get_tree().quit(0 if failures == 0 else 1)


func _cloister_cards() -> void:
	var ids := CardDB.reward_pool("wren", 1).filter(func(id): return CardDB.CARDS[id].get("min_region", 0) == 1)
	for up in [false, true]:
		for page in 2:
			var cards: Array = []
			for id in ids.slice(page * 5, page * 5 + 5):
				cards.append({"id": id, "up": up})
			var dv := DeckViewer.open_pile(get_tree().current_scene, "Cloister cards%s · %d / 2" % [" upgraded" if up else "", page + 1], cards, "Unlocked in Sunken Cloister rewards and markets")
			await _wait(0.7)
			for cv in dv.find_children("*", "Control", true, false):
				if cv is CardView:
					_check(cv._desc.get_content_height() <= cv._desc.size.y + 1, "card rules fit: " + cv.def["name"])
					_check(cv.get_global_transform().origin.y >= cv.get_parent().get_global_rect().position.y - 1, "card header stays within its allocated row: " + cv.def["name"])
			await _shot("30_cards_%s_%d" % ["up" if up else "base", page])
			dv.queue_free()
			await _wait(0.2)


func _rail_input() -> void:
	Game.new_run(326)
	Game.run.region = 1
	Game.run.current_encounter = "clo_abbess"
	Game.goto_combat()
	await _wait(2.0)
	var sc = get_tree().current_scene
	# A controlled encounter checks UI input without pretending to complete the campaign.
	var e: Dictionary = sc.c.enemies[0]
	sc.c.player["pos"] = e["pos"] + Vector2i(1, 0)
	sc.c.terrain[sc.c.player["pos"]] = "plain"
	sc.c.hand = [{"id": "bellbreaker", "up": false, "uid": 9001}]
	e["ward"] = 12
	sc.board.units["player"].position = sc.board.world(sc.c.player["pos"])
	sc._refresh_all()
	await _wait(0.8)
	var key := InputEventKey.new()
	key.keycode = KEY_1
	key.pressed = true
	get_viewport().push_input(key, true)
	await _wait(0.2)
	_check(sc.selected_uid == 9001, "keyboard selects card")
	key = InputEventKey.new()
	key.keycode = KEY_1
	key.pressed = false
	get_viewport().push_input(key, true)
	var pl: UnitPlate = sc.plates[e["uid"]]
	var pos := pl.position + Vector2(80, 30)
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	get_viewport().push_input(motion, true)
	await _wait(0.2)
	_check(sc.hover_hex == e["pos"], "enemy rail hover selects matching hex")
	_check(is_instance_valid(sc.card_inspector), "selected card has a separate inspector")
	if is_instance_valid(sc.card_inspector):
		_check(sc.card_inspector.get_global_rect().end.x < 350, "card inspector stays in left margin")
	for cv in sc.card_views:
		_check(cv.get_global_rect().position.y > sc.hint_label.get_global_rect().end.y, "hand card does not cover targeting instruction")
	await _shot("31_rail_target_preview")
	var hp := int(e["hp"])
	for down in [true, false]:
		var mouse := InputEventMouseButton.new()
		mouse.position = pos
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = down
		get_viewport().push_input(mouse, true)
		await _wait(0.1)
	await _wait(1.2)
	_check(e["ward"] == 0 and int(e["hp"]) < hp, "rail click plays selected card through normal input and rules")
	_check(sc.c.player["energy"] == 2, "rail click spends card energy once")
	await _shot("32_rail_after_play")
	# Stress the rail with a boss and five summons; no labels may overlap or reach End Turn.
	for hex in [Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]:
		if sc.c.occupied(hex):
			continue
		sc.c.terrain[hex] = "plain"
		var add: Dictionary = sc.c._spawn_enemy("drowned_novice", hex, false)
		sc.c._choose_intent(add)
		sc.board.add_enemy(add, false)
	sc._refresh_all()
	await _wait(0.5)
	_check(sc.plates.size() == 6, "stress scenario contains six live enemies")
	var rects: Array[Rect2] = []
	for plate in sc.plates.values():
		var rect := Rect2(plate.position, plate.size)
		_check(rect.end.y < sc.end_btn.position.y, "rail remains above End Turn")
		for other in rects:
			_check(not rect.intersects(other), "enemy rail plates do not overlap")
		rects.append(rect)
	await _shot("33_summoned_rail")
	get_window().size = Vector2i(1600, 900) if res != Vector2i(1600, 900) else Vector2i(1280, 720)
	await _wait(0.4)
	get_window().size = res
	await _wait(0.5)
	_check(get_window().size == res, "native window returns to requested size after resize")
	await _shot("34_after_resize")
	Game.clear_run()


## Reward (with a charm) and every room screen for one region's theme.
func _rooms(reg: int) -> void:
	Game.clear_run()
	Game.new_run(6060 + reg)
	var r := Game.run
	r.region = reg
	r.generate_map()
	var elite := -1
	for n in r.map:
		if n["type"] == "fight":
			elite = n["id"]
	r.node_id = elite
	r.reward = {"gold": 31, "cards": r.roll_cards(3, 1.6), "charm": r.roll_charm()}
	r.status = "reward"
	Game.route_to_status()
	await _wait(1.8)
	await _shot("20_r%d_reward" % (reg + 1))
	for st in ["camp", "shrine", "market"]:
		r.status = st
		if st == "shrine":
			r.current_event = "hermit_grafter"
		if st == "market":
			r.gold = 180
			r._stock_market()
		Game.route_to_status()
		await _wait(1.8)
		await _shot("21_r%d_%s" % [reg + 1, st])
	Game.clear_run()


func _region2() -> void:
	Game.clear_run()
	Game.new_run(5151)
	var r := Game.run
	r.region = 1
	r.node_id = -1
	r.generate_map()
	r.status = "map"
	Game.goto_map()
	await _wait(1.5)
	await _shot("08_map_r2")
	for enc in ["clo_knight", "clo_choir", "clo_abbess"]:
		r.enter_node(r.available_nodes()[0])
		r.current_encounter = enc
		Game.goto_combat()
		await _wait(3.5)
		await _shot("09_r2_%s" % enc)
		if enc == "clo_knight":
			var sc = get_tree().current_scene
			if sc and sc.has_method("_open_pile"):
				var dv = sc._open_pile("draw")
				await _wait(0.6)
				await _shot("09_r2_draw_pile")
				if dv:
					dv.queue_free()
				await _wait(0.3)
		if enc == "clo_abbess":
			var scene = get_tree().current_scene
			if scene and scene.has_method("_on_end_turn"):
				scene._on_end_turn()
				await _wait(1.6)
				await _shot("10_r2_boss_enemy_turn")
				await _wait(4.0)
		r.current_encounter = ""
		r.node_id = -1
		r.status = "map"
	Game.clear_run()
	print("[tour] wrote %d screenshots to %s" % [_shots.size(), out_dir])


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true).timeout


func _shot(name_: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := out_dir.path_join("%s_%dx%d.png" % [name_, img.get_width(), img.get_height()])
	img.save_png(path)
	_shots.append(path)
	print("[tour] ", path)
