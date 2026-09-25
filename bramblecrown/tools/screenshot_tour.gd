extends Node
## Packaged-build QA: Bramblecrown.exe --screenshot-tour <dir> [--shot-size WxH] [--tour-only r2]
## Walks title -> map -> combat (idle, targeting, enemy turn) -> reward -> camp/shrine/market ->
## region 2 map, fight, elite, boss -> quits. `--tour-only r2` skips straight to the region 2 shots.

var out_dir := ""
var res := Vector2i(1920, 1080)
var _shots: Array = []
var only := ""


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
	_run.call_deferred()


func _run() -> void:
	var win := get_window()
	win.mode = Window.MODE_WINDOWED
	win.borderless = true
	win.position = Vector2i.ZERO
	win.size = res
	await _wait(2.5)
	if only == "r2":
		await _region2()
		get_tree().quit(0)
		return
	if only == "rooms":
		for reg in [0, 1]:
			await _rooms(reg)
		get_tree().quit(0)
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
	get_tree().quit(0)


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
