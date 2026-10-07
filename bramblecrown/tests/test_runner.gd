extends SceneTree
## Headless rule tests: godot --headless --path . -s res://tests/test_runner.gd

var _fails := 0
var _passes := 0
var _current := ""


func _init() -> void:
	var tests := [
		"test_feedback_previews", "test_hex_math", "test_hex_world_roundtrip", "test_encounters_valid", "test_cards_valid",
		"test_setup_and_draw", "test_grove_and_bonus", "test_growth_rules", "test_play_damage",
		"test_player_move", "test_enemy_thicket_cost", "test_enemy_attack_and_ward",
		"test_blight_empower_and_rot", "test_spread_locked", "test_burn_grove", "test_victory",
		"test_defeat", "test_deterministic_combat", "test_summon_max", "test_boss_phase2",
		"test_map_generation", "test_map_visit_history", "test_run_save_load", "test_release_save_recovery", "test_release_camp", "test_rewards_and_market", "test_events",
		"test_autoplay_region", "test_preview_matches_play", "test_smart_bot_balance",
		"test_region_data", "test_daze", "test_shield_and_heal_allies", "test_region2_boss_phase2",
		"test_region_transition",
		"test_cloister_card_progression", "test_cloister_ward_cards", "test_cloister_daze_cards",
		"test_cloister_growth_and_reach",
		"test_glasswood_progression", "test_glasswood_patterns", "test_glasswood_counterplay",
		"test_enemy_forecast_matches_resolution",
		"test_ironroot_progression", "test_ironroot_patterns", "test_ironroot_collapse",
		"test_crown_progression", "test_crown_patterns", "test_crown_thorns",
		"test_cassia_data", "test_cassia_unlock", "test_kindle_rules", "test_cassia_cards_resolve",
		"test_cassia_powers", "test_cassia_preview_matches_play", "test_aimed_kindle", "test_cassia_bot", "test_cassia_events", "test_new_charms",
	]
	for t in tests:
		_current = t
		var finished = call(t)
		if finished != true:
			check(false, "test aborted by a script error")
	print("---- %d passed, %d failed ----" % [_passes, _fails])
	if _fails == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		quit(1)


func check(cond: bool, msg: String) -> void:
	if cond:
		_passes += 1
	else:
		_fails += 1
		printerr("FAIL [%s] %s" % [_current, msg])


func test_release_save_recovery() -> bool:
	var r := RunState.new()
	r.new_run(1919)
	var valid := r.to_dict()
	check(RunState.from_json(JSON.stringify(valid)) != null, "valid legacy-compatible checkpoint accepted")
	for text in ["{", "[]", "{}", "null", "{\"version\":999}"]:
		check(RunState.from_json(text) == null, "invalid top-level save safely rejected: " + text)
	for key in ["seed", "hp", "max_hp", "gold", "region", "node_id", "floor", "rng", "walker", "deck", "charms", "map", "used_encounters", "used_events"]:
		var damaged := valid.duplicate(true)
		damaged.erase(key)
		check(RunState.from_json(JSON.stringify(damaged)) == null, "missing field safely rejected: " + key)
	for pair in [["hp", "broken"], ["hp", -1], ["region", 99], ["walker", "missing"], ["withering", {}], ["stats", []], ["market", {"items": [null]}], ["reward", {"cards": ["missing"]}], ["status", "missing"], ["deck", [{"id": "missing", "up": false}]], ["rng", {"state": "broken"}]]:
		var damaged := valid.duplicate(true)
		damaged[pair[0]] = pair[1]
		check(RunState.from_json(JSON.stringify(damaged)) == null, "malformed field safely rejected: " + str(pair[0]))
	var damaged := valid.duplicate(true)
	damaged["map"][0]["links"] = [99999]
	check(RunState.from_json(JSON.stringify(damaged)) == null, "dangling map links rejected")
	for tier in range(11):
		r.new_run(1919, "wren", tier)
		var restored := RunState.from_json(r.to_json())
		check(restored != null and restored.to_json() == r.to_json(), "Withering %d checkpoint roundtrip" % tier)
	return true


func test_map_visit_history() -> bool:
	var r := RunState.new()
	r.new_run(8804)
	check(r.map.all(func(n): return not n.has("visited")), "fresh map invents no visited path")
	var first: int = r.available_nodes()[0]
	var alternatives := r.available_nodes().slice(1)
	r.enter_node(first)
	check(r.node(first).get("visited", false), "chosen encounter records actual visit")
	check(alternatives.all(func(id): return not r.node(id).get("visited", false)), "unchosen siblings are not completed")
	var second: int = r.available_nodes()[0]
	r.enter_node(second)
	var restored := RunState.from_json(r.to_json())
	check(restored != null and restored.node(first).get("visited", false) and restored.node(second).get("visited", false), "actual visits survive checkpoint roundtrip")
	check(restored.map.filter(func(n): return n.get("visited", false)).size() == 2, "roundtrip invents no completed branches")
	var legacy := r.to_dict().duplicate(true)
	for node in legacy["map"]:
		node.erase("visited")
	var old := RunState.from_json(JSON.stringify(legacy))
	check(old != null and old.map.all(func(n): return not n.has("visited")), "legacy checkpoint loads without fabricated visit marks")
	legacy["map"][0]["visited"] = "broken"
	check(RunState.from_json(JSON.stringify(legacy)) == null, "malformed optional visit flag safely rejected")
	r.generate_map()
	check(r.map.all(func(n): return not n.has("visited")), "new region resets its map visit marks")
	return true


func test_release_camp() -> bool:
	for tier in range(11):
		var r := RunState.new()
		r.new_run(2026, "wren", tier)
		r.status = "camp"
		r.hp = 1
		var expected := int(ceil(r.max_hp * (0.2 if tier >= 7 else 0.3)))
		check(r.camp_heal_amount() == expected, "Withering %d advertised heal matches rule" % tier)
		check(r.camp_rest() == expected and r.hp == 1 + expected and r.status == "map", "camp heals and advances at tier %d" % tier)
		r.hp = r.max_hp
		r.status = "camp"
		for card in r.deck:
			card["up"] = true
		check(r.camp_heal_amount() == 0, "full health offers no heal")
		r.leave_room()
		check(r.status == "map" and r.hp == r.max_hp, "fully upgraded full-health camp has safe escape")
	return true


func test_ironroot_progression() -> bool:
	var r := RunState.new()
	r.new_run(1003)
	r.region = 2
	r.generate_map()
	for n in r.map:
		if n["type"] == "boss":
			r.node_id = n["id"]
	r.status = "reward"
	r.used_encounters = ["gls_queen"]
	r.leave_reward()
	check(r.region == 3 and r.status == "map", "Glasswood boss unlocks Ironroot rather than ending the run")
	check(r.region_def()["id"] == "ironroot", "fourth region is Ironroot Deeps")
	var restored := RunState.from_json(r.to_json())
	check(restored.to_json() == r.to_json(), "Ironroot map save roundtrip")
	var reg := r.region_def()
	for enc in reg["fights"] + reg["elites"] + [reg["boss"]]:
		r.current_encounter = enc
		r.status = "combat"
		var c := r.make_combat()
		var again := RunState.from_json(r.to_json()).make_combat()
		check(again.encounter["id"] == enc and again.enemies == c.enemies and again.terrain == c.terrain,
			"saved Ironroot node restarts the same deterministic encounter: " + enc)
	for seed_value in range(10):
		var rr := RunState.new()
		rr.new_run(seed_value)
		rr.region = 3
		rr.generate_map()
		rr.enter_node(rr.available_nodes()[0])
		rr.make_combat()
		check(reg["easy"].has(rr.current_encounter), "Ironroot starts from its easy pool")
	for n in r.map:
		if n["type"] == "boss":
			r.node_id = n["id"]
	r.status = "reward"
	r.leave_reward()
	check(r.region == 4 and r.status == "map", "clearing Ironroot unlocks the Crown of Thorns")
	return true


func test_crown_progression() -> bool:
	var r := RunState.new()
	r.new_run(1005)
	r.region = 4
	r.generate_map()
	check(r.region_def()["id"] == "crown", "fifth region is the Crown of Thorns")
	check(EncounterDB.REGIONS.size() == 5, "the campaign has exactly five regions")
	var restored := RunState.from_json(r.to_json())
	check(restored.to_json() == r.to_json(), "Crown map save roundtrip")
	var reg := r.region_def()
	for enc in reg["fights"] + reg["elites"] + [reg["boss"]]:
		r.current_encounter = enc
		r.status = "combat"
		var c := r.make_combat()
		var again := RunState.from_json(r.to_json()).make_combat()
		check(again.encounter["id"] == enc and again.enemies == c.enemies and again.terrain == c.terrain
			and again.thorn_timers == c.thorn_timers,
			"saved Crown node restarts the same deterministic encounter: " + enc)
		check(not c.thorn_timers.is_empty(), "%s opens with thorn walls on a schedule" % enc)
	for seed_value in range(10):
		var rr := RunState.new()
		rr.new_run(seed_value)
		rr.region = 4
		rr.generate_map()
		rr.enter_node(rr.available_nodes()[0])
		rr.make_combat()
		check(reg["easy"].has(rr.current_encounter), "Crown starts from its easy pool")
	# The Withered Crown is the final boss: clearing it wins the run.
	for n in r.map:
		if n["type"] == "boss":
			r.node_id = n["id"]
	r.status = "reward"
	r.leave_reward()
	check(r.status == "victory", "clearing the Crown of Thorns wins the five-region campaign")
	return true


func test_crown_patterns() -> bool:
	# Every authored move under real rules, both boss phases. Rules-bound, not a balance claim.
	for id in ["thornling", "briar_knight", "withered_herald", "last_gardener", "withered_crown"]:
		var c := _blank_combat({"radius": 4, "player": [0, 3], "enemies": [[id, 0, -2]]})
		c.player["hp"] = 9999
		c.player["max_hp"] = 9999
		var e: Dictionary = c.enemies[0]
		for phase in [false, true] if e["def"].has("pattern2") else [false]:
			if phase:
				var old_intent: Dictionary = e["intent"].duplicate(true)
				e["ward"] = 0
				c._damage_enemy(e, int(e["hp"]) - int(e["max_hp"] * e["def"]["phase2_at"]))
				check(e["phase2"], "Crown enters its second phase at the threshold")
				check(e["intent"] == old_intent, "phase change preserves this turn's promised intent")
			e["pattern_idx"] = 0
			var pattern: Array = e["def"]["pattern2"] if phase else e["def"]["pattern"]
			for mi in pattern:
				c._choose_intent(e)
				check(e["intent"]["name"] == e["def"]["moves"][mi]["name"], "%s authored pattern order" % id)
				c._enemy_act(e)
				check(c.player["hp"] > 0 and c.enemies.has(e), "%s move resolves without corrupting units" % id)
			for turn in 12:
				c.end_turn()
			for move in e["def"]["moves"]:
				for action in move["actions"]:
					if action["t"] == "summon":
						var count := c.enemies.filter(func(en): return en["id"] == action["enemy"]).size()
						check(count <= int(action["max"]), "%s summons remain capped" % id)
		var stone := 0
		for h in c.terrain:
			if c.terrain[h] == "stone":
				stone += 1
				check(c.thorn_timers.has(h) == (int(c.thorn_timers.get(h, 0)) > 0), "%s thorn timers stay positive" % id)
		check(stone <= int(c.terrain.size() * CombatState.COLLAPSE_CAP), "%s thorn walls respect the board cap" % id)
		check(c._walkable_regions([]) == 1, "%s thorn walls never split the board" % id)
	return true


func test_crown_thorns() -> bool:
	var c := _blank_combat({"player": [0, 1], "enemies": [["briar_knight", 0, -3]], "thicket": [[1, 0]],
		"thorns": [[-2, 0, 1], [2, -1, 2]]})
	check(c.terrain[Vector2i(-2, 0)] == "stone" and c.thorn_timers[Vector2i(-2, 0)] == 1, "authored thorn walls start raised")
	check(not c.passable(Vector2i(-2, 0)), "a thorn wall blocks movement")
	var k: Dictionary = c.enemies[0]
	k["pattern_idx"] = 0
	c._choose_intent(k)
	var marked: Array = k["intent"]["actions"][0]["hexes"]
	check(k["intent"]["name"] == "Hedge Wall" and marked.size() == 3, "Hedge Wall marks three hexes")
	for h in marked:
		check(Hex.distance(h, c.player["pos"]) <= 2 and c.terrain[h] == "plain", "thorns target open ground near the Grovewalker")
	# Forecasting must not touch the real board, timers or RNG, but must know walls will recede.
	var terrain0 := c.terrain.duplicate()
	var timers0 := c.thorn_timers.duplicate()
	var rng0 := c.rng.get_state()
	c.enemy_forecasts()
	check(c.terrain == terrain0 and c.thorn_timers == timers0 and c.rng.get_state() == rng0, "thorn forecast is pure")
	# Stand on one mark: take thorn damage, that hex stays open; the others rise for 2 enemy turns.
	var stand: Vector2i = marked[0]
	c.player["pos"] = stand
	c.player["ward"] = 0
	var hp0 := int(c.player["hp"])
	var events := c.end_turn()
	check(int(c.player["hp"]) <= hp0 - CombatState.THORN_DMG, "standing on a thorn mark costs %d HP" % CombatState.THORN_DMG)
	check(c.terrain[stand] == "plain", "an occupied thorn mark stays open")
	var raised := 0
	for h in marked:
		if h != stand and c.terrain[h] == "stone":
			raised += 1
			check(c.thorn_timers.get(h, 0) == 2, "a new thorn wall lasts two enemy turns")
	check(raised > 0, "unoccupied marks became thorn walls")
	check(c.terrain[Vector2i(-2, 0)] == "plain" and not c.thorn_timers.has(Vector2i(-2, 0)), "a wall at 1 recedes at the start of the enemy turn")
	check(c.thorn_timers.get(Vector2i(2, -1), 0) == 1, "longer walls count down")
	check(events.any(func(ev): return ev["type"] == "recede"), "receding emits an event for the board")
	check(events.any(func(ev): return ev["type"] == "collapse" and ev.get("thorns", false)), "raising emits a thorn event")
	# Two more enemy phases: every wall has receded.
	c.player["hp"] = 999
	c.player["max_hp"] = 999
	for i in 2:
		c.end_turn()
	for h in marked:
		if h != stand:
			check(c.terrain[h] == "plain" or c.thorn_timers.has(h), "no wall outlives its timer")
	check(not c.thorn_timers.has(Vector2i(2, -1)), "authored walls recede too")
	# A Grovewalker never gets sealed in: every raised wall keeps one walkable region.
	check(c._walkable_regions([]) == 1, "thorn walls keep the board connected")
	return true


func test_ironroot_patterns() -> bool:
	# Every authored move under real rules, both boss phases. Rules-bound, not a balance claim.
	for id in ["rustgrub", "cart_golem", "tunneler", "foundry_heart", "engine_of_rot"]:
		var c := _blank_combat({"radius": 4, "player": [0, 3], "enemies": [[id, 0, -2]]})
		c.player["hp"] = 9999
		c.player["max_hp"] = 9999
		var e: Dictionary = c.enemies[0]
		for phase in [false, true] if e["def"].has("pattern2") else [false]:
			if phase:
				var old_intent: Dictionary = e["intent"].duplicate(true)
				e["ward"] = 0
				c._damage_enemy(e, int(e["hp"]) - int(e["max_hp"] * e["def"]["phase2_at"]))
				check(e["phase2"], "Engine enters its second phase at the threshold")
				check(e["intent"] == old_intent, "phase change preserves this turn's promised intent")
			e["pattern_idx"] = 0
			var pattern: Array = e["def"]["pattern2"] if phase else e["def"]["pattern"]
			for mi in pattern:
				c._choose_intent(e)
				check(e["intent"]["name"] == e["def"]["moves"][mi]["name"], "%s authored pattern order" % id)
				c._enemy_act(e)
				check(c.player["hp"] > 0 and c.enemies.has(e), "%s move resolves without corrupting units" % id)
			for turn in 12:
				c.end_turn()
			for move in e["def"]["moves"]:
				for action in move["actions"]:
					if action["t"] == "summon":
						var count := c.enemies.filter(func(en): return en["id"] == action["enemy"]).size()
						check(count <= int(action["max"]), "%s summons remain capped" % id)
	return true


func test_ironroot_collapse() -> bool:
	var c := _blank_combat({"player": [0, 1], "enemies": [["tunneler", 0, -3]], "thicket": [[1, 0]], "blight": [[-1, 1]]})
	var t: Dictionary = c.enemies[0]
	t["pattern_idx"] = 0
	c._choose_intent(t)
	var marked: Array = t["intent"]["actions"][0]["hexes"]
	check(marked.size() == 2, "Undermine marks two hexes")
	for h in marked:
		check(Hex.distance(h, c.player["pos"]) <= 1 and c.terrain[h] == "plain", "cave-in targets open ground beside the Grovewalker")
	# Forecasting the enemy phase must not touch the real board or RNG.
	var terrain0 := c.terrain.duplicate()
	var rng0 := c.rng.get_state()
	c.enemy_preview(t)
	check(c.terrain == terrain0 and c.rng.get_state() == rng0, "forecast leaves terrain and RNG untouched")
	# Step off the marked hexes: they fall and clear any growth; the Grovewalker is unharmed.
	var safe := Vector2i(-3, 3)
	check(not marked.has(safe), "safe hex is not marked")
	c.player["pos"] = safe
	var hp: int = c.player["hp"]
	c._enemy_act(t)
	for h in marked:
		check(c.terrain[h] == "stone" and c.growth[h] == "none", "marked hex becomes rubble with no growth")
	check(c.player["hp"] == hp, "no damage when the Grovewalker stepped away")
	# Standing on a marked hex: it stays open and the Grovewalker takes the cave-in damage.
	var c2 := _blank_combat({"player": [0, 1], "enemies": [["tunneler", 0, -3]]})
	var t2: Dictionary = c2.enemies[0]
	t2["pattern_idx"] = 0
	c2._choose_intent(t2)
	var hexes: Array = t2["intent"]["actions"][0]["hexes"]
	c2.player["pos"] = hexes[0]
	var hp2: int = c2.player["hp"]
	c2._enemy_act(t2)
	check(c2.player["hp"] == hp2 - CombatState.COLLAPSE_DMG, "cave-in costs a Grovewalker who stays on the mark")
	check(c2.terrain[hexes[0]] == "plain", "an occupied hex does not become rubble")
	# An enemy standing on a marked hex also keeps it open.
	var c3 := _blank_combat({"player": [0, 2], "enemies": [["tunneler", 0, -3], ["rustgrub", 3, -3]]})
	var t3: Dictionary = c3.enemies[0]
	t3["pattern_idx"] = 0
	c3._choose_intent(t3)
	var h3: Vector2i = t3["intent"]["actions"][0]["hexes"][0]
	c3.enemies[1]["pos"] = h3
	c3._collapse_hexes([h3], t3)
	check(c3.terrain[h3] == "plain", "a cave-in never buries an enemy")
	# Repeated cave-ins never split the walkable board and stop at the cap.
	for enc in ["iro_undermine", "iro_foundry", "iro_engine", "iro_sump"]:
		var cc := CombatState.new()
		cc.setup(EncounterDB.get_def(enc), [{"id": "thornstrike", "up": false}], 9999, 9999, [], Rng.new(enc.length()))
		var regions0 := cc._walkable_regions([])
		for _t in 30:
			if cc.phase != "player":
				break
			for e in cc.enemies:
				e["statuses"]["rooted"] = 0
			cc.end_turn()
		var stone := 0
		for h in cc.terrain:
			if cc.terrain[h] == "stone":
				stone += 1
		check(cc._walkable_regions([]) <= regions0, "%s: cave-ins never split the walkable board" % enc)
		check(stone <= int(cc.terrain.size() * CombatState.COLLAPSE_CAP), "%s: rubble stays under the cap" % enc)
	return true


func test_glasswood_progression() -> bool:
	var r := RunState.new()
	r.new_run(926)
	r.region = 1
	r.generate_map()
	for n in r.map:
		if n["type"] == "boss":
			r.node_id = n["id"]
	r.status = "reward"
	r.used_encounters = ["clo_abbess"]
	r.hp = 10
	r.leave_reward()
	check(r.region == 2 and r.status == "map", "Cloister boss unlocks Glasswood rather than ending the run")
	check(r.region_def()["id"] == "glasswood", "third region is Glasswood")
	check(r.used_encounters.is_empty() and r.node_id == -1, "new region resets encounter pool and path")
	check(r.hp == 10 + int(r.max_hp * 0.5), "region transition keeps the intended partial heal")
	var restored := RunState.from_json(r.to_json())
	check(restored.to_json() == r.to_json(), "Glasswood map save roundtrip")
	var reg := r.region_def()
	for enc in reg["fights"] + reg["elites"] + [reg["boss"]]:
		r.current_encounter = enc
		r.status = "combat"
		var c := r.make_combat()
		var loaded := RunState.from_json(r.to_json())
		var again := loaded.make_combat()
		check(again.encounter["id"] == enc, "saved Glasswood node restarts same encounter: " + enc)
		check(again.player == c.player and again.enemies == c.enemies, "saved encounter restarts deterministic units/intents: " + enc)
		check(again.hand == c.hand and again.growth == c.growth, "saved encounter restarts deterministic cards/growth: " + enc)
	for seed_value in range(10):
		var rr := RunState.new()
		rr.new_run(seed_value)
		rr.region = 2
		rr.generate_map()
		rr.enter_node(rr.available_nodes()[0])
		rr.make_combat()
		check(reg["easy"].has(rr.current_encounter), "Glasswood starts from its easy pool")
	return true


func test_glasswood_patterns() -> bool:
	# Execute every authored move under real rules, including both boss phases.
	# Extra HP makes this a rules/summon-bound test, never a balance or playthrough claim.
	for id in ["shardling", "prism_stag", "glass_mite", "lantern_hart", "splintered_queen"]:
		var c := _blank_combat({"radius": 4, "player": [0, 3], "enemies": [[id, 0, -2]]})
		c.player["hp"] = 9999
		c.player["max_hp"] = 9999
		var e: Dictionary = c.enemies[0]
		for phase in [false, true] if e["def"].has("pattern2") else [false]:
			if phase:
				var old_intent: Dictionary = e["intent"].duplicate(true)
				e["ward"] = 0
				c._damage_enemy(e, int(e["hp"]) - int(e["max_hp"] * e["def"]["phase2_at"]))
				check(e["phase2"], "Queen enters her second phase at the threshold")
				check(e["intent"] == old_intent, "phase change preserves this turn's promised intent")
			e["pattern_idx"] = 0
			var pattern: Array = e["def"]["pattern2"] if phase else e["def"]["pattern"]
			for mi in pattern:
				c._choose_intent(e)
				check(e["intent"]["name"] == e["def"]["moves"][mi]["name"], "%s authored pattern order" % id)
				c._enemy_act(e)
				check(c.player["hp"] > 0 and c.enemies.has(e), "%s move resolves without corrupting units" % id)
			# Repeated turns must respect per-species summon limits.
			for turn in 12:
				c.end_turn()
			for move in e["def"]["moves"]:
				for action in move["actions"]:
					if action["t"] == "summon":
						var count := c.enemies.filter(func(en): return en["id"] == action["enemy"]).size()
						check(count <= int(action["max"]), "%s summons remain capped" % id)
	return true


func test_glasswood_counterplay() -> bool:
	var c := _blank_combat({"radius": 4, "player": [0, 2], "enemies": [["prism_stag", 0, -1]]})
	var stag: Dictionary = c.enemies[0]
	stag["pattern_idx"] = 0
	c._choose_intent(stag)
	check(c.enemy_preview(stag)["hits"], "Stag charge threatens a distant player")
	stag["statuses"]["rooted"] = 1
	check(not c.enemy_preview(stag)["hits"], "Root cancels the Stag's closing charge")
	var hp: int = c.player["hp"]
	c._enemy_act(stag)
	check(c.player["hp"] == hp, "rooted charge cannot reach the player in actual resolution")
	stag["pattern_idx"] = 2
	c._choose_intent(stag)
	c.player["pos"] = Vector2i(0, 0)
	check(c.enemy_preview(stag)["hits"], "stationary sweep threatens adjacent hex")
	c.player["pos"] = Vector2i(0, 1)
	check(not c.enemy_preview(stag)["hits"], "one hex retreat escapes stationary sweep")
	c._enemy_act(stag)
	check(c.player["hp"] == hp, "sweep respects the retreat preview")
	c = _blank_combat({"player": [0, 2], "enemies": [["glass_mite", -1, -1], ["shardling", 1, -1]]})
	var mite: Dictionary = c.enemies[0]
	var shard: Dictionary = c.enemies[1]
	mite["pattern_idx"] = 0
	c._choose_intent(mite)
	c._enemy_act(mite)
	check(shard["ward"] == 4 and mite["ward"] == 0, "Mite shields its ally while leaving itself exposed")
	c.player["pos"] = Vector2i(1, 0)
	var uid := _give(c, "bellbreaker")
	var pv := c.preview_card(c.hand[c.hand_index(uid)], shard["pos"])
	var before: int = shard["hp"]
	c.play_card(uid, shard["pos"])
	check(shard["ward"] == 0 and int(shard["hp"]) < before, "Cloister Ward-break card counters Glasswood support")
	check(before - int(shard["hp"]) == pv["damage"][shard["uid"]], "Ward-break damage matches the preview")
	return true


func test_cloister_card_progression() -> bool:
	var pool := CardDB.reward_pool("wren", 1)
	var old_pool := CardDB.reward_pool("wren", 0)
	var new_ids := pool.filter(func(id): return not old_pool.has(id))
	check(new_ids.size() == 10, "ten additional region-2 reward cards")
	check(not CardDB.reward_pool("cassia", 1).any(func(id): return CardDB.CARDS[id]["owner"] == "wren"), "Wren cards do not leak to another walker")
	var r := RunState.new()
	r.new_run(326)
	r.region = 1
	for id in new_ids:
		check(ResourceLoader.exists("res://assets/textures/cards/%s.png" % id), "%s original illustration imported" % id)
		r.deck.append({"id": id, "up": true})
	var restored := RunState.from_json(r.to_json())
	check(restored.deck == r.deck and restored.region == 1, "new upgraded cards survive save/load")
	check(restored.roll_cards(3, 1.6) == r.roll_cards(3, 1.6), "region-2 reward RNG survives save/load")
	var seen := {}
	for _i in 100:
		for id in r.roll_cards(3, 1.0):
			seen[id] = true
	for id in new_ids:
		check(seen.has(id), "%s obtainable from real rewards" % id)
	return true


func test_cloister_ward_cards() -> bool:
	for up in [false, true]:
		var c := _blank_combat({"enemies": [["moss_knight", 1, 0]], "thicket": [[0, 0], [0, 1], [-1, 1]]})
		var e: Dictionary = c.enemies[0]
		e["ward"] = 30
		var before := int(e["hp"])
		var uid := _give(c, "bellbreaker", up)
		var pv := c.preview_card(c.hand[c.hand_index(uid)], e["pos"])
		check(e["ward"] == 30 and e["hp"] == before, "ward-break preview is read-only")
		check(pv["ward_break"][e["uid"]] == 30, "preview includes all removed Ward")
		c.play_card(uid, e["pos"])
		check(e["ward"] == 0 and before - int(e["hp"]) == (9 if up else 6), "Bellbreaker strips before rooted-bonus damage")
		check(before - int(e["hp"]) == pv["damage"][e["uid"]], "Bellbreaker damage preview exact")
		c.player["energy"] = 10
		e["ward"] = 20
		c.play_card(_give(c, "borrowed_vow", up), e["pos"])
		var stolen := 12 if up else 8
		check(e["ward"] == 20 - stolen and c.player["ward"] == stolen, "Borrowed Vow transfers exact capped Ward, without Grove bonus")
		check(e["statuses"]["weak"] == 1, "Borrowed Vow weakens")
		e["ward"] = 2
		c.play_card(_give(c, "borrowed_vow", up), e["pos"])
		check(e["ward"] == 0 and c.player["ward"] == stolen + 2, "cannot steal more Ward than exists")
		c.play_card(_give(c, "borrowed_vow", up), e["pos"])
		check(c.player["ward"] == stolen + 2, "unwarded target creates no Ward")
		c.player["ward"] = 40
		e["hp"] = 100
		e["max_hp"] = 100
		e["ward"] = 5
		uid = _give(c, "candle_lance", up)
		pv = c.preview_card(c.hand[c.hand_index(uid)], e["pos"])
		check(c.player["ward"] == 40, "lance preview does not spend Ward")
		c.play_card(uid, e["pos"])
		check(c.player["ward"] == 0, "lance spends ALL Ward even over cap")
		check(100 - int(e["hp"]) == (20 if up else 12), "lance cap, Grove bonus and enemy Ward resolve correctly")
		check(pv["damage"][e["uid"]] - 5 == 100 - int(e["hp"]), "lance preview matches damage through Ward")
		var reserve := _blank_combat({"enemies": [["moss_knight", 3, 0]]})
		reserve.play_card(_give(reserve, "last_lantern", up), Vector2i.ZERO)
		reserve._start_player_turn(false)
		check(reserve.player["ward"] == (6 if up else 4), "reserve carries only capped unused Ward")
		reserve._start_player_turn(false)
		check(reserve.player["ward"] == 0, "reserve expires after one turn")
		reserve.play_card(_give(reserve, "last_lantern", up), Vector2i.ZERO)
		reserve._damage_player(50, null)
		reserve._start_player_turn(false)
		check(reserve.player["ward"] == 0, "spent reserve creates no Ward")
	return true


func test_cloister_daze_cards() -> bool:
	for up in [false, true]:
		var c := _blank_combat({"enemies": [["bell_ghoul", 0, -2]]})
		var e: Dictionary = c.enemies[0]
		e["intent"] = {"name": "Toll", "actions": [{"t": "daze", "n": 2}, {"t": "daze", "n": 2}]}
		c.play_card(_give(c, "vow_shield", up), Vector2i.ZERO)
		check(c.player["ward"] == (9 if up else 6), "Vow Shield grants stated Ward")
		c.end_turn()
		check(c.player["energy"] == 3 and c.player["daze_lost"] == 0, "Clarity blocks repeated Daze applications")
		check(not c.player["statuses"].has("clarity"), "Clarity expires on next player turn")
		e["intent"] = {"name": "Toll", "actions": [{"t": "daze", "n": 5}]}
		c.end_turn()
		check(c.player["energy"] == 1 and c.player["daze_lost"] == 2, "Daze after Clarity expiration records actual lost Energy")
		var before := c.hand.size()
		var uid := _give(c, "dry_wick", up)
		c.play_card(uid, Vector2i.ZERO)
		check(c.player["energy"] == 3 and c.player["daze_lost"] == 0, "Dry Wick restores only this turn's Daze loss")
		check(c.hand.size() == before + (2 if up else 1), "Dry Wick draw and upgrade")
		check(c.exhausted.any(func(inst): return inst["uid"] == uid), "Dry Wick exhausts")
		c.play_card(_give(c, "dry_wick", up), Vector2i.ZERO)
		check(c.player["energy"] == 3, "cannot double-refund Daze")
		c._start_player_turn(false)
		c.play_card(_give(c, "dry_wick", up), Vector2i.ZERO)
		check(c.player["energy"] == 3, "cannot refund an earlier turn's Daze")
	return true


func test_cloister_growth_and_reach() -> bool:
	for up in [false, true]:
		var c := _blank_combat({"enemies": [["moss_knight", 2, 0]]})
		var e: Dictionary = c.enemies[0]
		var uid := _give(c, "bellroot", up)
		var pv := c.preview_card(c.hand[c.hand_index(uid)], e["pos"])
		c.play_card(uid, e["pos"])
		check(e["statuses"]["rooted"] == 1, "Bellroot roots target")
		check(pv["grow"].size() == (4 if up else 2), "Bellroot upgraded growth count")
		for h in pv["grow"]:
			check(c.growth[h] == "thicket", "Bellroot grows each previewed hex")
		c.player["energy"] = 10
		var before := int(e["hp"])
		c.play_card(_give(c, "censer_cut", up), e["pos"])
		check(before - int(e["hp"]) == (6 if up else 4), "Censer Cut ranged damage")
		check(e["statuses"]["weak"] == (2 if up else 1), "Censer Cut Weak upgrade")
		var movement := int(c.player["move"])
		c.play_card(_give(c, "stillwater_step", up), Vector2i.ZERO)
		check(c.player["move"] == movement + (3 if up else 2), "Stillwater Step movement")
		check(c.player["ward"] == (4 if up else 2), "Stillwater Step Ward")
		var choir := _blank_combat({"enemies": [["moss_knight", 1, 0], ["moss_knight", 3, 0]], "thicket": [[0, 0]]})
		var near_hp := int(choir.enemies[0]["hp"])
		var far_hp := int(choir.enemies[1]["hp"])
		choir.play_card(_give(choir, "choir_thorns", up), Vector2i.ZERO)
		check(near_hp - int(choir.enemies[0]["hp"]) == (9 if up else 6), "Choir of Thorns reaches Grove neighbor")
		check(choir.enemies[1]["hp"] == far_hp, "Choir of Thorns cannot reach distant enemy")
		check(choir.player["ward"] == (6 if up else 4), "Choir of Thorns defense")
	return true


func _blank_combat(enc_over: Dictionary = {}, deck: Array = [], charms: Array = []) -> CombatState:
	var enc := {"radius": 3, "player": [0, 0], "enemies": [], "water": [], "stone": [], "blight": [], "thicket": []}
	enc.merge(enc_over, true)
	if deck.is_empty():
		for i in 10:
			deck.append({"id": "thornstrike", "up": false})
	var c := CombatState.new()
	c.setup(enc, deck, 50, 50, charms, Rng.new(7))
	return c


func _give(c: CombatState, id: String, up: bool = false) -> int:
	var inst := {"uid": 9000 + c.hand.size() + c.turn * 20, "id": id, "up": up}
	c.hand.append(inst)
	return inst["uid"]


# ---------------------------------------------------------------- hex

func test_hex_math() -> bool:
	check(Hex.distance(Vector2i(0, 0), Vector2i(3, -3)) == 3, "distance diagonal")
	check(Hex.distance(Vector2i(1, 2), Vector2i(-1, 3)) == 2, "distance mixed")
	check(Hex.disc(Vector2i.ZERO, 3).size() == 37, "disc radius 3 has 37")
	check(Hex.disc(Vector2i.ZERO, 4).size() == 61, "disc radius 4 has 61")
	check(Hex.ring(Vector2i.ZERO, 2).size() == 12, "ring 2 has 12")
	for h in Hex.ring(Vector2i(1, 1), 2):
		check(Hex.distance(h, Vector2i(1, 1)) == 2, "ring member distance")
	var l := Hex.line(Vector2i(0, 0), Vector2i(3, -1))
	check(l.size() == 4 and l[0] == Vector2i(0, 0) and l[3] == Vector2i(3, -1), "line endpoints")
	for i in l.size() - 1:
		check(Hex.distance(l[i], l[i + 1]) == 1, "line contiguous")
	return true


func test_hex_world_roundtrip() -> bool:
	for h in Hex.disc(Vector2i.ZERO, 4):
		check(Hex.from_world(Hex.to_world(h, 1.1), 1.1) == h, "world roundtrip %s" % h)


# ---------------------------------------------------------------- data
	return true


func test_encounters_valid() -> bool:
	for id in EncounterDB.ENCOUNTERS:
		var e: Dictionary = EncounterDB.ENCOUNTERS[id]
		var r := int(e["radius"])
		var seen := {}
		var p := Vector2i(e["player"][0], e["player"][1])
		check(Hex.distance(p, Vector2i.ZERO) <= r, "%s player in bounds" % id)
		seen[p] = true
		for en in e["enemies"]:
			check(EnemyDB.ENEMIES.has(en[0]), "%s enemy id %s" % [id, en[0]])
			var h := Vector2i(en[1], en[2])
			check(Hex.distance(h, Vector2i.ZERO) <= r, "%s enemy in bounds" % id)
			check(not seen.has(h), "%s units do not overlap" % id)
			seen[h] = true
		for key in ["water", "stone", "thorns"]:
			for w in e.get(key, []):
				var h := Vector2i(w[0], w[1])
				check(Hex.distance(h, Vector2i.ZERO) <= r, "%s %s in bounds" % [id, key])
				check(not seen.has(h), "%s %s not under a unit %s" % [id, key, h])
				seen[h] = true
	for reg in EncounterDB.REGIONS:
		for id in reg["fights"] + reg["elites"] + [reg["boss"]]:
			check(EncounterDB.ENCOUNTERS.has(id), "region references %s" % id)
	return true


func test_cards_valid() -> bool:
	for id in CardDB.CARDS:
		var d := CardDB.get_def(id, false)
		var u := CardDB.get_def(id, true)
		check(not CardDB.describe(d).contains("{"), "%s text filled" % id)
		check(not CardDB.describe(u).contains("{"), "%s upgraded text filled" % id)
		check(u["name"].ends_with("+"), "%s upgraded name" % id)
		check(d["target"] in ["self", "enemy", "hex", "kindle"], "%s target kind" % id)
		if d["target"] == "kindle":
			check(d["effects"][0]["op"] == "kindle", "%s aimed card starts with Kindle" % id)
	check(CardDB.reward_pool("wren").size() >= 15, "reward pool size")
	for id in CardDB.STARTER_DECK["wren"]:
		check(CardDB.has(id), "starter card %s exists" % id)


# ---------------------------------------------------------------- combat
	return true


func test_setup_and_draw() -> bool:
	var c := _blank_combat({"enemies": [["blightling", 0, -3]]})
	check(c.hand.size() == 5, "draws 5")
	check(c.player["energy"] == 3, "3 energy")
	check(c.player["move"] == 2, "2 move")
	check(c.enemies.size() == 1 and not c.enemies[0]["intent"].is_empty(), "enemy has intent")
	check(c.terrain.size() == 37, "radius 3 board")
	return true


func test_grove_and_bonus() -> bool:
	var c := _blank_combat({"enemies": [["blightling", 3, -3]], "thicket": [[0, 0], [1, 0], [2, 0], [0, 1], [-3, 3]]})
	check(c.grove().size() == 4, "grove connected size 4 (excludes island)")
	check(c.rooted_bonus() == 1, "rooted bonus 1")
	c.player["pos"] = Vector2i(0, -1)
	check(c.grove().is_empty(), "no grove off thicket")
	return true


func test_growth_rules() -> bool:
	var c := _blank_combat({"enemies": [["blightling", 3, -3]], "blight": [[1, 0]], "water": [[-1, 0]]})
	var uid := _give(c, "sow")
	c.play_card(uid, Vector2i(0, 0))
	check(c.growth[Vector2i(1, 0)] == "none", "grow on blight clears it")
	check(c.growth[Vector2i(0, 0)] == "thicket", "grow on target")
	check(c.terrain[Vector2i(-1, 0)] == "water" and c.growth[Vector2i(-1, 0)] == "none", "no growth on water")
	c._blight_hexes([Vector2i(0, 0)])
	check(c.growth[Vector2i(0, 0)] == "none", "blight on thicket clears it")
	c._blight_hexes([Vector2i(0, 0)])
	check(c.growth[Vector2i(0, 0)] == "blight", "blight on none")
	return true


func test_play_damage() -> bool:
	var c := _blank_combat({"enemies": [["husk_brute", 1, 0]], "thicket": [[0, 0], [0, 1], [-1, 1]]})
	var e: Dictionary = c.enemies[0]
	var hp0: int = e["hp"]
	var uid := _give(c, "thornstrike")
	var ev := c.play_card(uid, Vector2i(1, 0))
	check(hp0 - int(e["hp"]) == 7, "thornstrike 6 + rooted 1 (grove 3)")
	check(c.player["energy"] == 2, "energy spent")
	check(ev.any(func(x): return x["type"] == "damage"), "damage event")
	var far := _give(c, "thornstrike")
	check(not c.can_play(c.hand[c.hand_index(far)], Vector2i(3, -3)), "cannot target out of range")
	return true


func test_player_move() -> bool:
	var c := _blank_combat({"enemies": [["blightling", 3, -3]], "stone": [[1, 0]]})
	var r := c.reachable()
	check(r.has(Vector2i(2, 0)) == false, "stone blocks direct path within 2")
	check(r.has(Vector2i(0, 2)), "can reach 2 away")
	check(not r.has(Vector2i(0, 3)), "cannot reach 3 away")
	c.move_player(Vector2i(0, 2))
	check(c.player["pos"] == Vector2i(0, 2) and c.player["move"] == 0, "moved and spent")
	return true


func test_enemy_thicket_cost() -> bool:
	var c := _blank_combat({"player": [0, 3], "enemies": [["blightling", 0, -1]], "thicket": [[0, 0], [0, 1], [1, 0], [-1, 1], [1, -1], [-1, 0]]})
	var e: Dictionary = c.enemies[0]
	var prev := c.enemy_preview(e)
	check(prev["path"].size() <= 1, "thicket slows blightling (<=1 hex)")
	var c2 := _blank_combat({"player": [0, 3], "enemies": [["blightling", 0, -1]]})
	check(c2.enemy_preview(c2.enemies[0])["path"].size() == 2, "open ground moves 2")
	return true


func test_enemy_attack_and_ward() -> bool:
	var c := _blank_combat({"enemies": [["husk_brute", 1, 0]]})
	var e: Dictionary = c.enemies[0]
	e["intent"] = e["def"]["moves"][0].duplicate(true)  # Slam 11
	c.player["ward"] = 5
	c.hand.clear()
	c.end_turn()
	check(c.player["hp"] == 50 - 6, "ward absorbed 5 of 11 (hp %d)" % c.player["hp"])
	check(c.player["ward"] == 0, "ward reset at turn start")
	return true


func test_blight_empower_and_rot() -> bool:
	var c := _blank_combat({"enemies": [["husk_brute", 1, 0]], "blight": [[1, 0], [0, 0]]})
	var e: Dictionary = c.enemies[0]
	e["intent"] = e["def"]["moves"][0].duplicate(true)
	check(c.attack_damage(e, 11) == 13, "empowered on blight")
	c.end_turn()
	check(c.player["hp"] == 50 - 2 - 13, "rot 2 + empowered slam 13 (hp %d)" % c.player["hp"])
	var c2 := _blank_combat({"enemies": [["husk_brute", 3, -3]], "blight": [[0, 0]]}, [], ["rot_ward"])
	c2.end_turn()
	check(c2.player["hp"] == 50, "rot ward prevents rot")
	return true


func test_spread_locked() -> bool:
	var c := _blank_combat({"player": [0, 2], "enemies": [["rotmoth", 0, -3]]})
	var e: Dictionary = c.enemies[0]
	e["intent"] = e["def"]["moves"][1].duplicate(true)
	c._lock_targets(e, e["intent"])
	var targets: Array = e["intent"]["actions"][0]["hexes"].duplicate()
	check(targets.size() == 3, "3 spread targets")
	c.move_player(Vector2i(-1, 3))
	c.end_turn()
	for h in targets:
		check(c.growth[h] == "blight", "locked hex %s blighted" % h)
	return true


func test_burn_grove() -> bool:
	var c := _blank_combat({"enemies": [["husk_brute", 2, 0]], "thicket": [[0, 0], [1, 0], [0, 1], [-1, 1]]})
	var e: Dictionary = c.enemies[0]
	var hp0: int = e["hp"]
	var uid := _give(c, "wildfire")
	c.play_card(uid, c.player["pos"])
	check(hp0 - int(e["hp"]) == 8, "4 hexes x 2 = 8 (got %d)" % (hp0 - int(e["hp"])))
	check(c.grove().is_empty(), "grove consumed")
	return true


func test_victory() -> bool:
	var c := _blank_combat({"enemies": [["blightling", 1, 0]]})
	c.enemies[0]["hp"] = 3
	var uid := _give(c, "thornstrike")
	var ev := c.play_card(uid, Vector2i(1, 0))
	check(c.phase == "won", "won after last kill")
	check(ev.any(func(x): return x["type"] == "won"), "won event")
	check(c.growth[Vector2i(1, 0)] == "blight", "blightling leaves blight")
	return true


func test_defeat() -> bool:
	var c := _blank_combat({"enemies": [["husk_brute", 1, 0]]})
	c.player["hp"] = 5
	c.enemies[0]["intent"] = c.enemies[0]["def"]["moves"][0].duplicate(true)
	c.end_turn()
	check(c.phase == "lost", "lost at 0 hp")
	return true


func test_deterministic_combat() -> bool:
	var a := _sim(12345)
	var b := _sim(12345)
	check(a == b, "same seed same result")
	return true


func _sim(seed_v: int) -> String:
	var r := RunState.new()
	r.new_run(seed_v)
	r.enter_node(r.available_nodes()[0])
	var c := r.make_combat()
	var trace := ""
	for _t in 6:
		_autoplay_turn(c)
		trace += "%d/%d;" % [c.player["hp"], c.enemies.size()]
		if c.phase != "player":
			break
	return trace


func test_summon_max() -> bool:
	var c := _blank_combat({"player": [0, 3], "enemies": [["sporecaller", 0, -3], ["blightling", -3, 0], ["blightling", 3, -3], ["blightling", -2, -1], ["blightling", 2, 1]]})
	var e: Dictionary = c.enemies[0]
	e["pattern_idx"] = 1  # next = Call the Brood
	c._choose_intent(e)
	check(e["intent"]["name"] != "Call the Brood", "summon skipped when at max")
	return true


func test_boss_phase2() -> bool:
	var c := _blank_combat({"radius": 4, "player": [0, 4], "enemies": [["mire_mother", 0, -3]]})
	var e: Dictionary = c.enemies[0]
	c._damage_enemy(e, 71)
	check(e["phase2"], "phase 2 at half hp")
	c._choose_intent(e)
	check(e["intent"]["name"] == "Wake of Moths", "phase 2 pattern")


# ---------------------------------------------------------------- run
	return true


func test_map_generation() -> bool:
	for s in [1, 2, 3, 99, 4242]:
		var r := RunState.new()
		r.new_run(s)
		var boss_count := 0
		for n in r.map:
			if n["type"] == "boss":
				boss_count += 1
			if n["row"] < RunState.ROWS:
				check(not n["links"].is_empty(), "seed %d node %d has exits" % [s, n["id"]])
			if n["row"] > 0:
				var incoming := r.map.any(func(m): return m["links"].has(n["id"]))
				check(incoming, "seed %d node %d reachable" % [s, n["id"]])
		check(boss_count == 1, "one boss")
		check(r.available_nodes().size() == 3, "3 starting nodes")
	# Every region map, across many seeds, offers an elite, a shrine and a pedlar.
	for s in range(40):
		for reg in EncounterDB.REGIONS.size():
			var r := RunState.new()
			r.new_run(900 + s)
			r.region = reg
			r.generate_map()
			for need in ["elite", "shrine", "market"]:
				check(r.map.any(func(n): return n["type"] == need), "seed %d region %d map has a %s" % [s, reg, need])
	return true


func test_run_save_load() -> bool:
	var r := RunState.new()
	r.new_run(777)
	r.enter_node(r.available_nodes()[1])
	r.gold = 123
	r.deck[0]["up"] = true
	var text := r.to_json()
	var r2 := RunState.from_json(text)
	check(r2 != null, "parses")
	check(r2.to_json() == text, "roundtrip identical")
	check(r2.rng.randi_range(0, 1000000) == r.rng.randi_range(0, 1000000), "rng state restored")
	check(r2.encounter_for_current() == r.encounter_for_current(), "same encounter after load")
	# A fight in progress resumes as the same encounter even though it is marked used.
	var c1 := r.make_combat()
	var r3 := RunState.from_json(r.to_json())
	var c2 := r3.make_combat()
	check(c1.encounter["id"] == c2.encounter["id"], "resumed fight uses same encounter")
	check(c1.enemies.size() == c2.enemies.size() and c1.enemies[0]["hp"] == c2.enemies[0]["hp"], "resumed fight identical setup")
	return true


func test_rewards_and_market() -> bool:
	var r := RunState.new()
	r.new_run(55)
	var cards := r.roll_cards(3, 1.0)
	check(cards.size() == 3, "3 reward cards")
	check(cards[0] != cards[1] and cards[1] != cards[2] and cards[0] != cards[2], "reward cards unique")
	r._stock_market()
	check(r.market["items"].size() >= 5, "market stocked")
	r.gold = 1000
	var n := r.deck.size()
	check(r.market_buy(0), "buy works")
	check(not r.market_buy(0), "cannot buy twice")
	check(r.deck.size() == n + 1 or r.charms.size() == 2, "item delivered")
	check(r.market_remove(0), "remove works")
	check(not r.market_remove(0), "only one removal")
	return true


func test_events() -> bool:
	check(EventDB.EVENTS.size() >= 12, "at least 12 authored shrine events")
	var region_ids := EncounterDB.REGIONS.map(func(reg): return reg["id"])
	for id in EventDB.EVENTS:
		var ev: Dictionary = EventDB.EVENTS[id]
		check(ev["options"].size() >= 2 and ev["options"].size() <= 3, "%s has 2-3 choices" % id)
		if ev.has("region"):
			check(region_ids.has(ev["region"]), "%s names a real region" % id)
		for opt in ev["options"]:
			for op in opt["ops"]:
				if op[0] == "card":
					check(CardDB.CARDS.has(op[1]), "%s grants a real card %s" % [id, op[1]])
	# Region events come first in their own region and never leak into another.
	for ri in EncounterDB.REGIONS.size():
		var r := RunState.new()
		r.new_run(40 + ri)
		r.region = ri
		var here: String = EncounterDB.REGIONS[ri]["id"]
		var own := EventDB.EVENTS.keys().filter(func(id): return EventDB.EVENTS[id].get("region", "") == here)
		for k in 12:
			var got := r._pick_event()
			var owner: String = EventDB.EVENTS[got].get("region", here)
			check(owner == here, "%s never offers another region's event" % here)
			if k < own.size():
				check(own.has(got), "%s offers its own events first" % here)
		var saved := RunState.from_json(r.to_json())
		check(saved.used_events == r.used_events, "used events survive save/load in %s" % here)
	for id in EventDB.EVENTS:
		for i in EventDB.EVENTS[id]["options"].size():
			var r := RunState.new()
			r.new_run(3)
			r.gold = 200
			var note := r.choose_event_option(id, i)
			check(note != "", "%s option %d applies" % [id, i])
			check(r.hp >= 1 and r.hp <= r.max_hp, "%s option %d hp sane" % [id, i])
	return true


## Greedy bot: plays through the whole region by always taking the first node.
func test_autoplay_region() -> bool:
	var wins := 0
	for s in [11, 12, 13]:
		var r := RunState.new()
		r.new_run(s)
		var guard := 0
		while r.status != "victory" and r.status != "defeat" and guard < 80:
			guard += 1
			var opts := r.available_nodes()
			var t := r.enter_node(opts[0])
			match r.status:
				"combat":
					var c := r.make_combat()
					var turns := 0
					while c.phase == "player" and turns < 60:
						_autoplay_turn(c)
						turns += 1
					check(c.phase != "player", "seed %d fight %s finished in 60 turns" % [s, t])
					r.finish_combat(c)
					if r.status == "reward":
						if not r.reward["cards"].is_empty():
							r.take_reward_card(r.reward["cards"][0])
						r.take_reward_charm()
						r.leave_reward()
				"shrine":
					r.choose_event_option(r.current_event, EventDB.EVENTS[r.current_event]["options"].size() - 1)
				"market":
					r.leave_room()
				"camp":
					r.camp_rest()
		check(r.status in ["victory", "defeat"], "seed %d run reached an end (%s)" % [s, r.status])
		print("  seed %d: %s on floor %d, hp %d, deck %d" % [s, r.status, r.floor_num, r.hp, r.deck.size()])
		if r.status == "victory":
			wins += 1
	print("  autoplay bot region wins: %d/3" % wins)
	return true


func _autoplay_turn(c: CombatState) -> void:
	# Move toward nearest enemy, then play every affordable card on the best target.
	if not c.enemies.is_empty():
		var tgt: Vector2i = c.enemies[0]["pos"]
		var best: Vector2i = c.player["pos"]
		for h in c.reachable():
			if Hex.distance(h, tgt) < Hex.distance(best, tgt):
				best = h
		if best != c.player["pos"]:
			c.move_player(best)
	var guard := 0
	var progressed := true
	while progressed and c.phase == "player" and guard < 20:
		guard += 1
		progressed = false
		for inst in c.hand.duplicate():
			if not c.can_afford(inst):
				continue
			var targets := c.valid_targets(inst)
			if targets.is_empty():
				continue
			c.play_card(inst["uid"], targets[0])
			progressed = true
			break
	if c.phase == "player":
		c.end_turn()


## The on-board preview must agree with what actually happens.
func test_preview_matches_play() -> bool:
	for id in ["sow", "briar_wall", "reclaim", "taproot", "hollow_oak"]:
		var c := _blank_combat({"enemies": [["husk_brute", 3, -3]], "blight": [[1, -1], [2, -2], [0, -2]], "thicket": [[0, 0]]})
		var uid := _give(c, id)
		var inst: Dictionary = c.hand[c.hand_index(uid)]
		var targets := c.valid_targets(inst)
		var tgt: Vector2i = targets[targets.size() / 2]
		var pv := c.preview_card(inst, tgt)
		var before := c.growth.duplicate()
		c.play_card(uid, tgt)
		var changed := []
		for h in c.growth:
			if c.growth[h] != before[h]:
				changed.append(h)
		for h in changed:
			check(pv["grow" if c.growth[h] == "thicket" else "blight_clear"].has(h), "%s: changed hex %s was previewed" % [id, h])
	var c := _blank_combat({"enemies": [["husk_brute", 1, 0]], "thicket": [[0, 0], [0, 1]]})
	var e: Dictionary = c.enemies[0]
	var uid := _give(c, "heartwood_maul")
	var pv := c.preview_card(c.hand[c.hand_index(uid)], e["pos"])
	var hp0: int = e["hp"]
	c.play_card(uid, e["pos"])
	check(pv["damage"][e["uid"]] == hp0 - int(e["hp"]), "maul damage preview exact")
	return true


## Enemies act one after another, so each forecast must account for allies that move first.
## Sweeps every authored encounter and compares the forecast path end and hit/miss with the
## actual enemy phase.
func test_enemy_forecast_matches_resolution() -> bool:
	var compared := 0
	var mismatches := 0
	for enc_id in EncounterDB.ENCOUNTERS.keys():
		for s in [3, 11, 29]:
			var c := CombatState.new()
			var deck: Array = []
			for i in 10:
				deck.append({"id": "thornstrike", "up": false})
			c.setup(EncounterDB.get_def(enc_id), deck, 999, 999, [], Rng.new(s * 97 + enc_id.length()))
			var walk := Rng.new(s)
			for _t in 6:
				if c.phase != "player":
					break
				var moves: Array = c.reachable().keys()
				moves.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
				if not moves.is_empty() and walk.randf() < 0.6:
					c.move_player(moves[walk.randi_range(0, moves.size() - 1)])
				var fc := {}
				for e in c.enemies:
					var pv := c.enemy_preview(e)
					fc[e["uid"]] = {"start": e["pos"], "end": pv["end"], "attack": pv["attack"], "hits": pv["hits"], "dmg": pv["dmg"]}
				var actual := {}
				var striker := -1
				for ev in c.end_turn():
					match ev["type"]:
						"enemy_act":
							actual[ev["target"]] = {"end": fc.get(ev["target"], {}).get("start"), "hit": null}
						"move":
							if actual.has(ev["who"]):
								actual[ev["who"]]["end"] = ev["path"].back()
						"attack":
							striker = ev["source"]
							if actual.has(ev["source"]):
								actual[ev["source"]]["hit"] = true
						"damage":
							if ev["target"] is String and ev["target"] == "player" and actual.has(striker):
								actual[striker]["dmg"] = int(ev["amount"]) + int(ev["blocked"])
								striker = -1
						"miss":
							if actual.has(ev["source"]):
								actual[ev["source"]]["hit"] = false
				for uid in actual:
					if not fc.has(uid):
						continue
					compared += 1
					var f: Dictionary = fc[uid]
					var a: Dictionary = actual[uid]
					var ok: bool = a["end"] == f["end"]
					if f["attack"] and a["hit"] != null:
						ok = ok and bool(a["hit"]) == bool(f["hits"])
					if a.has("dmg"):
						ok = ok and int(a["dmg"]) == int(f["dmg"])
					if not ok:
						mismatches += 1
						if mismatches <= 5:
							printerr("  forecast drift %s seed %d turn %d uid %d: forecast %s/%s actual %s/%s" % [
								enc_id, s, c.turn, uid, f["end"], f["hits"], a["end"], a["hit"]])
	print("  enemy forecasts compared: %d, drift: %d" % [compared, mismatches])
	check(compared > 500, "forecast sweep exercised many enemy actions")
	check(mismatches == 0, "every enemy forecast matches its sequential resolution")
	return true


## Heuristic bot used as a balance gauge (a competent human should beat it comfortably).
func test_smart_bot_balance() -> bool:
	var wins := 0
	var region1 := 0
	var floors := []
	var seeds := range(100, 120)
	for s in seeds:
		var r := RunState.new()
		r.new_run(s)
		var guard := 0
		while r.status != "victory" and r.status != "defeat" and guard < 80:
			guard += 1
			var opts: Array = r.available_nodes()
			var pick: int = opts[0]
			var best_score := -999.0
			for id in opts:
				var t: String = r.node(id)["type"]
				var hp_frac := float(r.hp) / r.max_hp
				var sc: float = {"fight": 2.0, "elite": 3.0 if hp_frac > 0.7 else -3.0, "camp": 4.0 if hp_frac < 0.6 else 0.5,
					"shrine": 1.5, "market": 1.0 if r.gold > 120 else 0.0, "boss": 0.0}[t]
				if sc > best_score:
					best_score = sc
					pick = id
			r.enter_node(pick)
			match r.status:
				"combat":
					var c := r.make_combat()
					var turns := 0
					while c.phase == "player" and turns < 60:
						_smart_turn(c)
						turns += 1
					if r.node(r.node_id)["type"] == "boss":
						var boss_hp := 0
						for e in c.enemies:
							if e["def"].get("boss", false):
								boss_hp = e["hp"]
						print("    boss fight seed %d: entered hp ?, ended phase %s after %d turns, player hp %d, boss hp %d, deck %d" % [s, c.phase, turns, c.player["hp"], boss_hp, r.deck.size()])
					r.finish_combat(c)
					if r.status == "reward":
						var cards: Array = r.reward["cards"]
						if not cards.is_empty() and r.deck.size() < 22:
							var pref := ["heartwood_maul", "bramble_lash", "overgrowth", "deep_roots", "thornvolley", "hollow_oak", "spinebreaker", "rootsnare", "crowns_wrath", "wildfire"]
							var chosen := ""
							for id in pref:
								if cards.has(id):
									chosen = id
									break
							if chosen != "":
								r.take_reward_card(chosen)
						r.take_reward_charm()
						r.leave_reward()
				"shrine":
					var opts2: Array = EventDB.EVENTS[r.current_event]["options"]
					var chosen_i := opts2.size() - 1
					for i in opts2.size():
						if r.event_option_enabled(r.current_event, i):
							chosen_i = i
							break
					r.choose_event_option(r.current_event, chosen_i)
				"market":
					r.leave_room()
				"camp":
					if r.hp < r.max_hp * 0.75:
						r.camp_rest()
					else:
						for i in r.deck.size():
							if not r.deck[i]["up"] and r.deck[i]["id"] != "barkskin":
								r.upgrade_card(i)
								break
						r.status = "map"
		if r.status == "victory":
			wins += 1
		if r.region >= 1 or r.status == "victory":
			region1 += 1
		floors.append(r.floor_num)
	print("  smart bot: %d/%d region-1 clears, %d full-run wins, floors reached %s" % [region1, seeds.size(), wins, floors])
	check(region1 >= 1, "smart bot clears region 1 at least once in 20 seeds")
	return true


func _smart_turn(c: CombatState) -> void:
	var guard := 0
	while c.phase == "player" and guard < 30:
		guard += 1
		if not _smart_step(c):
			break
	if c.phase == "player":
		# Step off blight if possible.
		if c.growth[c.player["pos"]] == "blight":
			for h in c.reachable():
				if c.growth[h] != "blight":
					c.move_player(h)
					break
		c.end_turn()


func _incoming(c: CombatState) -> int:
	var total := 0
	for e in c.enemies:
		var pv := c.enemy_preview(e)
		if pv["hits"]:
			total += int(pv["dmg"])
	return total


## One decision; returns false when nothing useful remains.
func _smart_step(c: CombatState) -> bool:
	var best_uid := -1
	var best_tgt := Vector2i.ZERO
	var best_val := 0.0
	for inst in c.hand:
		if not c.can_afford(inst):
			continue
		var d := c.card_def(inst)
		for tgt in c.valid_targets(inst):
			var pv := c.preview_card(inst, tgt)
			var v := 0.0
			for uid in pv["damage"]:
				var e = c.enemy_by_uid(uid)
				var dmg: int = pv["damage"][uid]
				var focus := 1.4 if e["def"].get("boss", false) or e["def"].get("elite", false) else 1.0
				v += minf(dmg, e["hp"] + e["ward"]) * focus + (6.0 if dmg >= e["hp"] + e["ward"] else 0.0)
			v += pv["grow"].size() * 0.9
			for h in pv["grow"]:
				if Hex.distance(h, c.player["pos"]) <= 1:
					v += 0.6
			v += pv["blight_clear"].size() * 0.5
			for fx in d["effects"]:
				match fx["op"]:
					"ward":
						var w := CardDB.val(d, fx["amount"]) + c.grove().size() / 3 + c.grove().size() * CardDB.val(d, fx.get("grove_mult", 0))
						v += minf(w, maxi(0, _incoming(c) - int(c.player["ward"]))) * 1.1
					"power":
						v += 9.0 if c.turn <= 3 else 3.0
					"draw":
						v += 1.5
					"energy":
						v += 2.0
					"apply":
						v += 2.0
					"weak_area":
						v += 1.5 if _incoming(c) > 0 else 0.0
			v -= float(d["cost"]) * 0.8
			if v > best_val:
				best_val = v
				best_uid = inst["uid"]
				best_tgt = tgt
	# Consider moving next to an enemy if an attack could then land.
	if best_uid < 0 or best_val < 3.0:
		if int(c.player["move"]) > 0 and not c.enemies.is_empty():
			var weakest = c.enemies[0]
			for e in c.enemies:
				if e["def"].get("boss", false):
					weakest = e
					break
				if e["hp"] < weakest["hp"]:
					weakest = e
			var cur := Hex.distance(c.player["pos"], weakest["pos"])
			var dest: Vector2i = c.player["pos"]
			var dest_score := cur * 10.0 + (3.0 if c.growth[c.player["pos"]] == "blight" else 0.0)
			for h in c.reachable():
				var sc := Hex.distance(h, weakest["pos"]) * 10.0 + (3.0 if c.growth[h] == "blight" else 0.0) - (2.0 if c.growth[h] == "thicket" else 0.0)
				if sc < dest_score:
					dest_score = sc
					dest = h
			if dest != c.player["pos"]:
				c.move_player(dest)
				return true
	if best_uid >= 0 and best_val > 0.0:
		c.play_card(best_uid, best_tgt)
		return true
	return false


# ---------------------------------------------------------------- region 2

func test_region_data() -> bool:
	check(EncounterDB.REGIONS.size() >= 2, "at least two regions")
	for reg in EncounterDB.REGIONS:
		check(reg["fights"].size() >= 6, "%s has at least 6 fights" % reg["id"])
		for id in reg.get("easy", []):
			check(reg["fights"].has(id), "%s easy fight %s is a region fight" % [reg["id"], id])
		check(BoardView.THEMES.has(reg.get("theme", "marsh")), "%s theme exists" % reg["id"])
		for id in reg["fights"] + reg["elites"] + [reg["boss"]]:
			var e: Dictionary = EncounterDB.ENCOUNTERS[id]
			# Every enemy must be reachable on foot from the player (through passable hexes).
			var c := CombatState.new()
			c.setup(EncounterDB.get_def(id), [{"id": "thornstrike", "up": false}], 50, 50, [], Rng.new(1))
			var seen := {c.player["pos"]: true}
			var frontier: Array = [c.player["pos"]]
			while not frontier.is_empty():
				var h: Vector2i = frontier.pop_back()
				for n in Hex.neighbors(h):
					if c.in_bounds(n) and not seen.has(n) and c.terrain[n] == "plain":
						seen[n] = true
						frontier.append(n)
			for en in c.enemies:
				var adj := false
				for n in Hex.neighbors(en["pos"]):
					if seen.has(n):
						adj = true
				check(adj or seen.has(en["pos"]), "%s: %s reachable" % [id, en["id"]])
	for id in EnemyDB.ENEMIES:
		var m: String = EnemyDB.ENEMIES[id]["model"]
		check(ResourceLoader.exists("res://assets/models/%s.glb" % m), "model for %s exists" % id)
	for th in BoardView.THEMES.values():
		for key in ["plain", "stone", "water", "rail"]:
			if th.has(key):
				check(ResourceLoader.exists("res://assets/models/%s.glb" % th[key]), "theme tile %s exists" % th[key])
		for pr in th["props"]:
			check(ResourceLoader.exists("res://assets/models/%s.glb" % pr[0]), "theme prop %s exists" % pr[0])
	return true


func test_daze() -> bool:
	var c := _blank_combat({"player": [0, 0], "enemies": [["bell_ghoul", 0, -1]]})
	var e: Dictionary = c.enemies[0]
	e["pattern_idx"] = 1  # next = Toll
	c._choose_intent(e)
	check(e["intent"]["name"] == "Toll", "ghoul tolls")
	c.end_turn()
	check(c.player["energy"] == CombatState.BASE_ENERGY - 1, "dazed costs one energy next turn")
	check(not c.player["statuses"].has("dazed"), "daze is consumed")
	c.player["statuses"]["dazed"] = 1
	var e2: Dictionary = c.enemies[0]
	e2["intent"] = {"name": "Toll", "actions": [{"t": "daze", "n": 5}]}
	c.end_turn()
	check(c.player["energy"] >= 1, "daze never drops energy below 1")
	return true


func test_shield_and_heal_allies() -> bool:
	var c := _blank_combat({"player": [0, 3], "enemies": [["moss_knight", 0, -2], ["drowned_novice", -2, -1], ["choir_of_ash", 2, -3]]})
	var knight: Dictionary = c.enemies[0]
	var novice: Dictionary = c.enemies[1]
	var choir: Dictionary = c.enemies[2]
	knight["intent"] = {"name": "Bulwark", "stay": true, "actions": [{"t": "ward", "n": 8}, {"t": "shield_allies", "n": 6}]}
	novice["intent"] = {"name": "Wait", "stay": true, "actions": []}
	choir["hp"] = 40
	knight["hp"] = 20
	choir["intent"] = {"name": "Hymn", "stay": true, "actions": [{"t": "heal_allies", "n": 8}]}
	c.end_turn()
	check(int(novice["ward"]) == 6, "ally shielded after the knight acts (%d)" % novice["ward"])
	check(int(knight["ward"]) == 8, "knight keeps its own ward")
	check(int(choir["hp"]) == 48, "choir heals itself")
	check(int(knight["hp"]) == 28, "choir heals allies")
	return true


func test_region2_boss_phase2() -> bool:
	var c := _blank_combat({"radius": 4, "player": [0, 4], "enemies": [["drowned_abbess", 0, -3]]})
	var e: Dictionary = c.enemies[0]
	c._damage_enemy(e, 76)
	check(e["phase2"], "abbess enters phase 2 at half HP")
	for i in 3:
		c._choose_intent(e)
	c.end_turn()
	check(c.enemies.has(e) or c.phase != "player", "abbess survives its own turn")
	return true


func test_region_transition() -> bool:
	var r := RunState.new()
	r.new_run(77)
	var boss_id := -1
	for n in r.map:
		if n["type"] == "boss":
			boss_id = n["id"]
	r.node_id = boss_id
	r.status = "reward"
	r.reward = {"gold": 0, "cards": [], "charm": ""}
	r.hp = 10
	r.leave_reward()
	check(r.region == 1 and r.status == "map", "boss clear moves to region 2")
	check(r.region_def()["id"] == "cloister", "region 2 is the Sunken Cloister")
	check(r.hp > 10, "partial heal between regions")
	var first: int = r.available_nodes()[0]
	r.enter_node(first)
	if r.status == "combat":
		var enc := r.encounter_for_current()
		check(r.region_def()["fights"].has(enc), "region 2 fights come from the region 2 pool (%s)" % enc)
	var r2 := RunState.from_json(r.to_json())
	check(r2.region == 1, "region survives save/load")
	return true


# ---------------------------------------------------------------- Cassia, the Ashwalker

func test_cassia_data() -> bool:
	var own := CardDB.CARDS.keys().filter(func(id): return CardDB.CARDS[id]["owner"] == "cassia")
	check(own.size() >= 20, "Cassia has at least 20 cards (%d)" % own.size())
	for id in CardDB.STARTER_DECK["cassia"]:
		check(CardDB.has(id) and CardDB.CARDS[id]["owner"] == "cassia", "Cassia starter %s is hers" % id)
	var pool := CardDB.reward_pool("cassia", 4)
	check(pool.size() >= 15, "Cassia reward pool size")
	check(not pool.any(func(id): return CardDB.CARDS[id]["owner"] == "wren"), "no Wren cards in Cassia rewards")
	check(not CardDB.reward_pool("wren", 4).any(func(id): return CardDB.CARDS[id]["owner"] == "cassia"), "no Cassia cards in Wren rewards")
	for id in own:
		check(ResourceLoader.exists("res://assets/textures/cards/%s.png" % id), "%s has Blender card art" % id)
	check(ResourceLoader.exists("res://assets/models/cassia.glb"), "Cassia model exported")
	for w in WalkerDB.ORDER:
		check(CardDB.STARTER_DECK.has(w), "%s has a starter deck" % w)
	return true


func test_cassia_unlock() -> bool:
	check(WalkerDB.is_unlocked("wren", {}), "Wren always open")
	check(not WalkerDB.is_unlocked("cassia", {"runs": 3, "wins": 0}), "Cassia locked on a fresh profile")
	check(WalkerDB.is_unlocked("cassia", {"bosses": 1}), "one boss kill unlocks Cassia")
	var r := RunState.new()
	r.new_run(5, "cassia")
	check(r.walker == "cassia" and r.hp == 64 and r.max_hp == 64, "Cassia starts at 64 HP")
	check(r.deck.size() == 11 and r.deck.all(func(c): return CardDB.CARDS[c["id"]]["owner"] == "cassia"), "Cassia starter deck")
	check(r.deck.filter(func(c): return CardDB.CARDS[c["id"]]["effects"].any(func(fx): return fx["op"] == "kindle")).size() >= 2, "starter deck can Kindle from turn 1")
	var r2 := RunState.from_json(r.to_json())
	check(r2.walker == "cassia", "walker survives save/load")
	r2.enter_node(r2.available_nodes()[0])
	var c := r2.make_combat()
	check(c.walker == "cassia", "combat knows the walker")
	# Events that strip a starter basic must find Cassia's basics too.
	var found := false
	for id in EventDB.EVENTS:
		for i in EventDB.EVENTS[id]["options"].size():
			if found:
				break
			for op in EventDB.EVENTS[id]["options"][i]["ops"]:
				if op[0] == "remove_random_starter" and not found:
					var rr := RunState.new()
					rr.new_run(6, "cassia")
					rr.gold = 999
					var before := rr.deck.size()
					rr.choose_event_option(id, i)
					var carded: int = EventDB.EVENTS[id]["options"][i]["ops"].filter(func(o): return o[0] == "card").size()
					check(rr.deck.size() == before - 1 + carded, "starter removal works for Cassia's deck (%s)" % id)
					found = true
	return true


func test_kindle_rules() -> bool:
	# Grove: (0,0) under her, a line east (1,0),(2,0),(3,0) and one west (-1,0).
	var c := _blank_combat({"enemies": [["husk_brute", 0, -3]], "thicket": [[0, 0], [1, 0], [2, 0], [3, 0], [-1, 0]]})
	var first := c.kindle_targets(2)
	check(first.size() == 2 and first[0] == Vector2i(3, 0) and first[1] == Vector2i(2, 0), "kindle burns farthest first (%s)" % [first])
	check(not c.kindle_targets(99).has(Vector2i(0, 0)), "never burns her own hex")
	var uid := _give(c, "flashburn")
	var hand0 := c.hand.size()
	c.play_card(uid, c.player["pos"])
	check(int(c.player["heat"]) == 2, "Flashburn: 2 Heat")
	check(c.growth[Vector2i(3, 0)] == "none" and c.growth[Vector2i(2, 0)] == "none", "burned hexes are bare")
	check(c.growth[Vector2i(0, 0)] == "thicket", "still standing in Thicket")
	check(c.hand.size() == hand0, "Flashburn draws 1")
	# Ember Lash: Kindle 1 (Heat 3), 4 + 2 x 3; the Grove is then 2 hexes, so no Grove bonus.
	var e: Dictionary = c.enemies[0]
	e["pos"] = Vector2i(0, -2)
	var hp0 := int(e["hp"])
	uid = _give(c, "ember_lash")
	var pv := c.preview_card(c.hand[c.hand_index(uid)], e["pos"])
	c.play_card(uid, e["pos"])
	check(int(c.player["heat"]) == 3, "Ember Lash adds 1 Heat")
	check(hp0 - int(e["hp"]) == 10, "Ember Lash 4 + 2 x 3 Heat = 10 (got %d)" % (hp0 - int(e["hp"])))
	check(int(pv["damage"].get(e["uid"], -1)) == hp0 - int(e["hp"]), "Ember Lash preview exact")
	check(pv["burn"].size() == 1, "Ember Lash previews its burned hex")
	c.player["ward"] = 99
	c.end_turn()
	if c.phase == "player":
		check(int(c.player["heat"]) == 0, "Heat resets each turn")
	# Nothing to burn: no Heat, no crash.
	var c2 := _blank_combat({"enemies": [["husk_brute", 0, -3]]})
	uid = _give(c2, "flashburn")
	c2.play_card(uid, c2.player["pos"])
	check(int(c2.player["heat"]) == 0, "Kindle off-Grove does nothing")
	return true


func test_aimed_kindle() -> bool:
	var layout := {"enemies": [["husk_brute", 0, -2]],
		"thicket": [[0, 0], [1, 0], [2, 0], [3, 0], [-1, 0], [-2, 0], [0, 3]]}
	var c := _blank_combat(layout)
	check(c.kindle_targets(2, c.growth, Vector2i(-1, 0)) == [Vector2i(-1, 0), Vector2i(-2, 0)], "aim west preserves the eastern lane")
	check(c.kindle_targets(2, c.growth, Vector2i(1, 0)) == [Vector2i(1, 0), Vector2i(2, 0)], "aim selects fuel before severing a bridge")
	check(c.kindle_targets(2, c.growth, Vector2i.ZERO) == c.kindle_targets(2), "self aim retains old farthest-first order")
	check(c.kindle_targets(99, c.growth, Vector2i(-1, 0)).size() == 5, "oversized burn excludes self and disconnected thicket")
	for id in ["flashburn", "smokescreen", "cinderstep", "firestorm", "tinderbox"]:
		for up in [false, true]:
			for aim in [Vector2i.ZERO, Vector2i(-1, 0), Vector2i(1, 0), Vector2i(3, 0)]:
				c = _blank_combat(layout)
				c.player["energy"] = 9
				c.player["heat"] = 1
				c.player["powers"]["phoenix_bark"] = 2
				var uid := _give(c, id, up)
				var inst: Dictionary = c.hand[c.hand_index(uid)]
				var before := c.growth.duplicate()
				var player0 := c.player.duplicate(true)
				var rng0 := c.rng.get_state()
				var hand0 := c.hand.duplicate(true)
				var pv := c.preview_card(inst, aim)
				check(c.growth == before and c.player == player0 and c.rng.get_state() == rng0 and c.hand == hand0, "aim preview is pure: %s" % id)
				check(c.can_play(inst, aim), "aim is legal: %s" % id)
				check(not c.can_play(inst, Vector2i(0, 3)) and not c.can_play(inst, Vector2i(0, 1)), "reject isolated Thicket and bare ground: %s" % id)
				var e: Dictionary = c.enemies[0]
				var hp0 := int(e["hp"])
				c.play_card(uid, aim)
				var burned: Array[Vector2i] = []
				for h in before:
					if before[h] == "thicket" and c.growth[h] == "none":
						burned.append(h)
				check(burned.size() == pv["burn"].size() and burned.all(func(h): return pv["burn"].has(h)), "exact aimed burn set: %s" % id)
				check(int(c.player["heat"]) == int(pv["heat"]), "aimed Heat exact: %s" % id)
				check(hp0 - int(e["hp"]) == int(pv["damage"].get(e["uid"], 0)), "aimed damage exact: %s" % id)
				var expected_ward: int = burned.size() * 2
				if id == "smokescreen":
					expected_ward += int(c.player["heat"]) * 3 + c.grove().size() / 3
				check(c.player["ward"] == expected_ward, "aimed Phoenix Bark and Smokescreen Ward: %s" % id)
			# A card remains useful with no fuel (draw/movement/previous Heat).
			c = _blank_combat()
			var uid := _give(c, id, up)
			var inst: Dictionary = c.hand[c.hand_index(uid)]
			check(c.valid_targets(inst) == [c.player["pos"]], "no fuel offers self only: %s" % id)
			check(not c.play_card(uid, c.player["pos"]).is_empty() and c.player["heat"] == 0, "no fuel still resolves: %s" % id)
	# Invalid aim spends no resources or RNG, even after the originally hovered Grove changed.
	c = _blank_combat(layout)
	var uid := _give(c, "tinderbox")
	var rng0 := c.rng.get_state()
	var energy0: int = c.player["energy"]
	c.growth[Vector2i(1, 0)] = "none"
	check(c.play_card(uid, Vector2i(2, 0)).is_empty(), "stale disconnected aim rejected")
	check(c.hand_index(uid) >= 0 and c.player["energy"] == energy0 and c.rng.get_state() == rng0, "rejected aim preserves card energy RNG")
	# Checkpoint saves contain card identity, not target types: old IDs/upgrades retain new aiming.
	var r := RunState.new()
	r.new_run(103, "cassia")
	r.deck.append({"id": "tinderbox", "up": true})
	var restored := RunState.from_json(r.to_json())
	check(restored.walker == r.walker and restored.deck == r.deck and restored.rng.get_state() == r.rng.get_state(), "aimed deck checkpoint preserves walker upgrades RNG")
	check(CardDB.get_def("tinderbox", true)["target"] == "kindle", "restored upgraded card uses aimed rules")
	return true


func test_cassia_cards_resolve() -> bool:
	# Blaze burns the whole Grove except her hex and hits for 3 per Heat.
	var c := _blank_combat({"enemies": [["husk_brute", 1, -1]], "thicket": [[0, 0], [1, 0], [0, 1], [-1, 1], [-1, 0]]})
	var e: Dictionary = c.enemies[0]
	var hp0 := int(e["hp"])
	c.player["energy"] = 5
	var uid := _give(c, "blaze")
	c.play_card(uid, e["pos"])
	check(int(c.player["heat"]) == 4, "Blaze kindles all 4 other Grove hexes")
	check(hp0 - int(e["hp"]) == 12, "Blaze 3 x 4 = 12 (got %d)" % (hp0 - int(e["hp"])))
	check(c.grove().size() == 1, "only her hex remains")
	# Smokescreen: 3 Ward per Heat.
	c = _blank_combat({"enemies": [["husk_brute", 0, -3]], "thicket": [[0, 0], [1, 0], [2, 0]]})
	uid = _give(c, "smokescreen")
	c.play_card(uid, c.player["pos"])
	check(int(c.player["ward"]) == 6, "Smokescreen 2 Heat x 3 = 6 Ward (got %d)" % c.player["ward"])
	# Flare needs 2 Heat.
	uid = _give(c, "flare")
	var en := int(c.player["energy"])
	c.play_card(uid, c.player["pos"])
	check(int(c.player["energy"]) == en + 1, "Flare grants Energy at 2 Heat")
	# Firestorm hits everything within 2.
	c = _blank_combat({"enemies": [["husk_brute", 2, 0], ["husk_brute", -1, 0], ["husk_brute", 0, -3]], "thicket": [[0, 0], [0, 1], [1, 1], [-1, 2]]})
	c.player["energy"] = 5
	var hps := c.enemies.map(func(x): return int(x["hp"]))
	uid = _give(c, "firestorm")
	var pv := c.preview_card(c.hand[c.hand_index(uid)], c.player["pos"])
	c.play_card(uid, c.player["pos"])
	check(int(c.player["heat"]) == 3, "Firestorm kindles 3")
	check(hps[0] - int(c.enemies[0]["hp"]) == 6 and hps[1] - int(c.enemies[1]["hp"]) == 6, "Firestorm 2 x 3 Heat to enemies within 2")
	check(hps[2] == int(c.enemies[2]["hp"]), "Firestorm spares enemies 3 away")
	for i in 3:
		check(int(pv["damage"].get(c.enemies[i]["uid"], 0)) == hps[i] - int(c.enemies[i]["hp"]), "Firestorm preview exact for enemy %d" % i)
	# Scorch ticks at the start of the enemy's action and decays.
	c = _blank_combat({"enemies": [["husk_brute", 0, -3]]})
	e = c.enemies[0]
	uid = _give(c, "ashfall")
	c.play_card(uid, e["pos"])
	check(int(e["statuses"].get("scorch", 0)) == 3, "Ashfall applies 3 Scorch")
	c.player["heat"] = 2
	uid = _give(c, "ashfall")
	c.play_card(uid, e["pos"])
	check(int(e["statuses"].get("scorch", 0)) == 8, "Ashfall adds 3 + 1 per Heat (2) = 5 more Scorch")
	e["statuses"]["scorch"] = 3
	hp0 = int(e["hp"])
	c.player["ward"] = 99
	c.end_turn()
	check(hp0 - int(e["hp"]) == 3 and int(e["statuses"]["scorch"]) == 2, "Scorch ticks 3 then drops to 2")
	return true


func test_cassia_powers() -> bool:
	var c := _blank_combat({"enemies": [["husk_brute", 0, -3]], "thicket": [[0, 0], [1, 0], [2, 0], [0, 1]]})
	c.player["energy"] = 9
	var uid := _give(c, "phoenix_bark")
	c.play_card(uid, c.player["pos"])
	uid = _give(c, "flashburn")
	c.play_card(uid, c.player["pos"])
	check(int(c.player["ward"]) == 4, "Phoenix Bark: 2 Ward per hex kindled (got %d)" % c.player["ward"])
	uid = _give(c, "smolder")
	c.play_card(uid, c.player["pos"])
	uid = _give(c, "ember_saint")
	c.play_card(uid, c.player["pos"])
	c.player["ward"] = 99
	c.end_turn()
	if c.phase == "player":
		# Smolder regrows around her, then Ember Saint burns one hex for Heat and Energy.
		check(int(c.player["heat"]) == 1, "Ember Saint kindles 1 at turn start")
		check(int(c.player["energy"]) == CombatState.BASE_ENERGY + 1, "Ember Saint grants 1 Energy when a hex burns")
		check(c.grove().size() >= 3, "Smolder regrows fuel each turn")
	return true


func test_cassia_preview_matches_play() -> bool:
	for id in CardDB.CARDS:
		if CardDB.CARDS[id]["owner"] != "cassia":
			continue
		for up in [false, true]:
			var c := _blank_combat({"enemies": [["husk_brute", 1, -1], ["blightling", -2, 1], ["husk_brute", 0, -3]],
				"thicket": [[0, 0], [1, 0], [2, 0], [0, 1], [-1, 1], [-1, 0], [2, -1]]})
			c.player["energy"] = 9
			c.player["heat"] = 1
			var uid := _give(c, id, up)
			var inst: Dictionary = c.hand[c.hand_index(uid)]
			var targets := c.valid_targets(inst)
			if targets.is_empty():
				continue
			var tgt: Vector2i = targets[0]
			var pv := c.preview_card(inst, tgt)
			var before := c.growth.duplicate()
			var hps := {}
			for e in c.enemies:
				hps[e["uid"]] = int(e["hp"])
			c.play_card(uid, tgt)
			for h in c.growth:
				if before[h] == "thicket" and c.growth[h] == "none":
					check(pv["burn"].has(h), "%s: burned hex %s was previewed" % [id, h])
			check(int(c.player["heat"]) == int(pv["heat"]), "%s: Heat preview %d == %d" % [id, pv["heat"], c.player["heat"]])
			for e in c.enemies:
				var lost: int = hps[e["uid"]] - int(e["hp"])
				if pv["damage"].has(e["uid"]):
					check(lost == int(pv["damage"][e["uid"]]), "%s%s: damage preview %d == %d" % [id, "+" if up else "", pv["damage"][e["uid"]], lost])
	return true


## Cassia's deck clears fights end to end with the smart bot (balance gauge, not a win-rate bar).
func test_cassia_bot() -> bool:
	var region1 := 0
	var floors := []
	for s in range(200, 210):
		var r := RunState.new()
		r.new_run(s, "cassia")
		var guard := 0
		while r.status != "victory" and r.status != "defeat" and guard < 80:
			guard += 1
			var opts: Array = r.available_nodes()
			var pick: int = opts[0]
			for id in opts:
				if r.node(id)["type"] == ("camp" if r.hp < r.max_hp * 0.6 else "fight"):
					pick = id
			r.enter_node(pick)
			match r.status:
				"combat":
					var c := r.make_combat()
					var turns := 0
					while c.phase == "player" and turns < 60:
						_smart_turn(c)
						turns += 1
					check(c.phase != "player", "Cassia seed %d fight finished" % s)
					r.finish_combat(c)
					if r.status == "reward":
						var cards: Array = r.reward["cards"]
						for id in ["blaze", "firestorm", "smolder", "ember_lash", "backdraft", "kindling", "ash_sprout", "crownfire", "scorch_mark"]:
							if cards.has(id) and r.deck.size() < 20:
								r.take_reward_card(id)
								break
						r.take_reward_charm()
						r.leave_reward()
				"shrine":
					r.choose_event_option(r.current_event, EventDB.EVENTS[r.current_event]["options"].size() - 1)
				"market":
					r.leave_room()
				"camp":
					r.camp_rest()
		check(r.status in ["victory", "defeat"], "Cassia seed %d reached an end" % s)
		if r.region >= 1 or r.status == "victory":
			region1 += 1
		floors.append(r.floor_num)
	print("  cassia bot: %d/10 region-1 clears, floors %s" % [region1, floors])
	return true


## Shrine events that grant a named Wren card give Cassia her own counterpart, and say so.
func test_cassia_events() -> bool:
	for id in EventDB.EVENTS:
		var opts: Array = EventDB.EVENTS[id]["options"]
		for i in opts.size():
			for op in opts[i]["ops"]:
				if op[0] != "card":
					continue
				var swapped := CardDB.for_walker(op[1], "cassia")
				check(CardDB.CARDS[swapped]["owner"] == "cassia", "%s gives Cassia her own card (%s)" % [id, swapped])
				var label := CardDB.event_label(opts[i]["label"], opts[i]["ops"], "cassia")
				check(label.contains(CardDB.CARDS[swapped]["name"]), "%s label names %s" % [id, swapped])
				check(CardDB.event_label(opts[i]["label"], opts[i]["ops"], "wren") == opts[i]["label"], "%s label unchanged for Wren" % id)
				var r := RunState.new()
				r.new_run(9, "cassia")
				r.gold = 999
				r.hp = r.max_hp
				r.choose_event_option(id, i)
				check(r.deck.any(func(c): return c["id"] == swapped), "%s adds %s to Cassia's deck" % [id, swapped])
				check(not r.deck.any(func(c): return CardDB.CARDS[c["id"]]["owner"] == "wren"), "%s adds no Wren card for Cassia" % id)
	return true


func test_new_charms() -> bool:
	check(CharmDB.CHARMS.size() >= 20, "at least 20 charms")
	for id in CharmDB.CHARMS:
		var d := CharmDB.get_def(id)
		check(d["name"] != "" and d["text"] != "", "charm text " + id)
	# Dew Cup / Bramble Spool / Woven Satchel on the first turn.
	var base := _blank_combat()
	var c := _blank_combat({}, [], ["dew_cup", "bramble_spool", "woven_satchel"])
	check(c.player["ward"] == 3, "dew cup ward")
	check(int(c.player["energy"]) == int(base.player["energy"]) + 1, "bramble spool energy")
	check(c.hand.size() == base.hand.size() + 1, "woven satchel draw")
	# Carrion Bloom grows thicket where an enemy dies.
	var cb := _blank_combat({"enemies": [["rotmoth", 2, 0]]}, [], ["carrion_bloom"])
	if cb.enemies.size() > 0:
		var pos: Vector2i = cb.enemies[0]["pos"]
		cb._damage_enemy(cb.enemies[0], 9999)
		check(cb.growth[pos] == "thicket", "carrion bloom grows on death")
	# Last Bloom saves once per fight.
	var lb := _blank_combat({}, [], ["last_bloom"])
	lb._lose_hp(500, "test")
	check(lb.phase == "player" and lb.player["hp"] == 1, "last bloom survives")
	lb._lose_hp(500, "test")
	check(lb.phase == "lost", "last bloom only once")
	# Honey Jar heals at end of turn in Thicket.
	var hj := _blank_combat({"thicket": [[0, 0]]}, [], ["honey_jar"])
	hj.player["hp"] = 30
	hj.end_turn()
	check(hj.player["hp"] == 33, "honey jar heals 3")
	# Run-level charms.
	var r := RunState.new()
	r.new_run(5)
	var g0 := r.gold
	r.add_charm("gilded_acorn")
	check(r.gold == g0 + 60, "gilded acorn gold")
	r.add_charm("cartographers_quill")
	check(r._reward_choices() == 4, "quill offers four")
	var plain := RunState.new()
	plain.new_run(5)
	plain._stock_market()
	r.charms.append("haggler_tooth")
	r._stock_market()
	check(int(r.market["remove_price"]) < int(plain.market["remove_price"]), "haggler cheaper removal")
	# Save/load keeps the charms.
	var r2 := RunState.new()
	r2.from_dict(r.to_dict())
	check(r2.charms.has("last_bloom") == r.charms.has("last_bloom") and r2.charms.size() == r.charms.size(), "charms roundtrip")
	return true


func test_feedback_previews() -> bool:
	for id in ["sow", "taproot", "briar_wall", "reclaim", "bellroot"]:
		for up in [false, true]:
			var c := _blank_combat({"enemies": [["moss_knight", 3, 0]], "blight": [[1, 0]], "stone": [[0, 1]], "thicket": [[-1, 0]]})
			c.player["energy"] = 10
			var uid := _give(c, id, up)
			var inst: Dictionary = c.hand[c.hand_index(uid)]
			for target in c.valid_targets(inst):
				var before := c.growth.duplicate()
				var hand := c.hand.duplicate(true)
				var rng_state := c.rng.get_state()
				var pv := c.preview_card(inst, target)
				check(c.growth == before and c.hand == hand and c.rng.get_state() == rng_state, id + " retarget/cancel has no mutations")
				var events: Array = []
				for fx in c.card_def(inst)["effects"]:
					c._apply_effect(c.card_def(inst), fx, target, false)
				events = c._flush()
				var actual := {"grow": [], "blight_clear": []}
				for ev in events:
					if ev["type"] == "board":
						for h in ev["changes"]:
							actual["grow" if ev["changes"][h] == "thicket" else "blight_clear"].append(h)
				check(pv["grow"] == actual["grow"] and pv["blight_clear"] == actual["blight_clear"], id + " entire footprint matches committed growth")
				c.growth = before
	var c := _blank_combat({"enemies": [["moss_knight", 1, 0], ["moss_knight", 3, 0]], "thicket": [[0, 0], [1, 0]]})
	var near_uid: int = c.enemies[0]["uid"]
	var far_uid: int = c.enemies[1]["uid"]
	for id in ["choir_thorns", "wildfire", "bramble_lash", "bellroot", "pollen_cloud"]:
		c.player["energy"] = 10
		var uid := _give(c, id)
		var inst: Dictionary = c.hand[c.hand_index(uid)]
		var target: Vector2i = c.player["pos"] if c.card_def(inst)["target"] == "self" else Vector2i(1, 0)
		var enemies_before := c.enemies.duplicate(true)
		var pv := c.preview_card(inst, target)
		check(pv["enemy_effects"].has(near_uid) and not pv["enemy_effects"].has(far_uid), id + " identifies affected and unaffected enemies")
		check(c.enemies == enemies_before, id + " preview preserves enemy HP/status")
		check(c.preview_card(inst, Vector2i(99, 99))["enemy_effects"].is_empty(), id + " invalid retarget clears effects")
		c.hand.remove_at(c.hand_index(uid))
	var uid := _give(c, "bramble_lash")
	var inst: Dictionary = c.hand[c.hand_index(uid)]
	var pv := c.preview_card(inst, Vector2i(1, 0))
	check("Bleed 3" in pv["enemy_effects"][near_uid], "conditional Thicket Bleed preview")
	c.growth[Vector2i(1, 0)] = "none"
	pv = c.preview_card(inst, Vector2i(1, 0))
	check(not "Bleed 3" in pv["enemy_effects"][near_uid], "conditional status removed when enemy is off Thicket")
	return true


func test_withering() -> bool:
	check(Withering.TIERS.size() == Withering.MAX_TIER, "ten tier modifiers")
	check(Withering.unlocked({}) == 0, "tier 0 by default")
	check(Withering.after_win({}, 0) == 1, "win at 0 unlocks 1")
	check(Withering.after_win({"withering": 3}, 1) == 3, "win below top keeps unlock")
	check(Withering.after_win({"withering": 3}, 3) == 4, "win at top unlocks next")
	check(Withering.after_win({"withering": 10}, 10) == 10, "tier capped at ten")
	var base := RunState.new()
	base.new_run(7, "wren", 0)
	var w4 := RunState.new()
	w4.new_run(7, "wren", 4)
	check(w4.max_hp == base.max_hp - 8 and w4.hp == w4.max_hp, "tier 4 frail start")
	var w10 := RunState.new()
	w10.new_run(7, "wren", 10)
	check(w10.gold == 49 and base.gold == 99, "tier 10 starts with 50 less gold")
	# Enemy HP / strength.
	var enc := {"enemies": [["rotmoth", 2, 0]]}
	var c1 := CombatState.new()
	c1.withering = 1
	c1.setup({"radius": 3, "player": [-2, 0], "enemies": enc["enemies"]}, [], 30, 30, [], Rng.new(1))
	var c0b := CombatState.new()
	c0b.setup({"radius": 3, "player": [-2, 0], "enemies": enc["enemies"]}, [], 30, 30, [], Rng.new(1))
	check(int(c1.enemies[0]["max_hp"]) == int(round(int(c0b.enemies[0]["max_hp"]) * 1.1)), "tier 1 enemies +10% HP")
	var c3 := CombatState.new()
	c3.withering = 3
	c3.setup({"radius": 3, "player": [-2, 0], "enemies": enc["enemies"]}, [], 30, 30, [], Rng.new(1))
	check(int(c3.enemies[0]["strength"]) == 1, "tier 3 +1 strength")
	var c10 := CombatState.new()
	c10.withering = 10
	c10.setup({"radius": 3, "player": [-2, 0], "enemies": enc["enemies"]}, [], 30, 30, [], Rng.new(1))
	check(int(c10.enemies[0]["strength"]) == 2, "tier 10 +2 strength")
	# Economy modifiers.
	var r7 := RunState.new()
	r7.new_run(9, "wren", 7)
	r7.hp = 1
	check(r7.camp_rest() == int(ceil(r7.max_hp * 0.2)), "tier 7 camp heals 20%")
	var r8 := RunState.new()
	r8.new_run(9, "wren", 8)
	check(r8._reward_choices() == 2, "tier 8 offers two cards")
	var r0 := RunState.new()
	r0.new_run(9, "wren", 0)
	r0._stock_market()
	var r5 := RunState.new()
	r5.new_run(9, "wren", 5)
	r5._stock_market()
	check(r5.market["items"].size() > 0 and r0.market["items"].size() > 0, "markets stocked")
	# Save/load round trip keeps the tier.
	var back := RunState.from_json(r8.to_json())
	check(back != null and back.withering == 8, "withering survives save/load")
	# Old saves without the field load as tier 0.
	var d := r0.to_dict()
	d.erase("withering")
	var old := RunState.new()
	old.from_dict(d)
	check(old.withering == 0, "legacy save is tier 0")
	return true
