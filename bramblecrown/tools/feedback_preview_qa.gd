extends SceneTree
var sc
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func verify(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func shot(name_: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/feedback/" + name_ + ".png")
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = root.get_node("Game")
	game.tour_dir = "feedback-qa"
	game.run = RunState.new()
	game.run.new_run(4242)
	game.run.enter_node(game.run.available_nodes()[0])
	var c := CombatState.new()
	c.setup({"radius": 3, "player": [0, 0], "enemies": [["moss_knight", 1, 0], ["moss_knight", 3, 0]], "blight": [[0, -1]], "stone": [[0, 1]], "thicket": [[0, 0], [1, 0]]}, [{"id": "sow", "up": false}], 50, 50, [], Rng.new(7))
	c.player["energy"] = 10
	c.hand = [{"id": "sow", "up": false, "uid": 9001}, {"id": "choir_thorns", "up": false, "uid": 9002}, {"id": "pollen_cloud", "up": false, "uid": 9003}]
	game.combat = c
	change_scene_to_file("res://scenes/combat.tscn")
	await create_timer(2).timeout
	sc = current_scene
	DirAccess.make_dir_recursive_absolute("res://build/feedback")
	sc.selected_uid = 9001
	sc.hover_hex = Vector2i(0, -1)
	sc._refresh_all()
	await shot("growth-720")
	verify(sc.preview_label.text.begins_with("2 grow / 1 clear"), "full Sow footprint separates clearing Blight")
	sc.hover_hex = Vector2i(99, 99)
	sc._refresh_all()
	verify(sc.preview_label.text == "Hover a valid target to preview.", "invalid retarget clears preview")
	sc.selected_uid = 9002
	sc._refresh_all()
	await shot("enemies-720")
	verify(not sc.plates[c.enemies[0]["uid"]].pending_effects.is_empty(), "Grove-adjacent enemy has exact effect")
	verify(sc.plates[c.enemies[1]["uid"]].pending_effects.is_empty(), "distant enemy has no effect")
	sc.selected_uid = 9003
	sc.hover_hex = Vector2i(-2, 0)
	sc._refresh_all()
	await shot("no-effects-720")
	verify(sc.preview_label.text.ends_with("No enemy effects"), "zero affected enemies explicit")
	sc.hover_hex = Vector2i(1, 0)
	sc._refresh_all()
	await shot("status-720")
	verify("Weak 2" in sc.plates[c.enemies[0]["uid"]].pending_effects, "status-only target is highlighted")
	var cancel := InputEventKey.new()
	cancel.physical_keycode = KEY_ESCAPE
	cancel.pressed = true
	root.push_input(cancel, true)
	await process_frame
	sc._refresh_all()
	verify(sc.preview_label.text.is_empty() and not sc.plates[c.enemies[0]["uid"]].preview_active, "cancel clears all pending effects")
	root.size = Vector2i(1920, 1080)
	sc.selected_uid = 9001
	sc.hover_hex = Vector2i(0, -1)
	sc._refresh_all()
	await create_timer(0.4).timeout
	await shot("growth-1080")
	var expected := c.preview_card(c.hand[c.hand_index(9001)], Vector2i(0, -1))
	var grow_before := c.growth.duplicate()
	sc._click_hex(Vector2i(0, -1))
	await create_timer(1.5).timeout
	verify(c.hand_index(9001) < 0, "confirm casts card once")
	for h in expected["grow"]:
		verify(c.growth[h] == "thicket", "committed growth matches preview")
	for h in expected["blight_clear"]:
		verify(c.growth[h] == "none", "committed clearing matches preview")
	verify(sc.preview_label.text.is_empty(), "commit clears pending preview")
	print("FEEDBACK UI QA: %d failures" % failures)
	quit(failures)
