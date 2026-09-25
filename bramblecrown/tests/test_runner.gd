extends SceneTree
## Headless rule tests: godot --headless --path . -s res://tests/test_runner.gd

var _fails := 0
var _passes := 0
var _current := ""


func _init() -> void:
	var tests := [
		"test_hex_math", "test_hex_world_roundtrip", "test_encounters_valid", "test_cards_valid",
		"test_setup_and_draw", "test_grove_and_bonus", "test_growth_rules", "test_play_damage",
		"test_player_move", "test_enemy_thicket_cost", "test_enemy_attack_and_ward",
		"test_blight_empower_and_rot", "test_spread_locked", "test_burn_grove", "test_victory",
		"test_defeat", "test_deterministic_combat", "test_summon_max", "test_boss_phase2",
		"test_map_generation", "test_run_save_load", "test_rewards_and_market", "test_events",
		"test_autoplay_region", "test_preview_matches_play", "test_smart_bot_balance",
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
		for key in ["water", "stone"]:
			for w in e[key]:
				var h := Vector2i(w[0], w[1])
				check(Hex.distance(h, Vector2i.ZERO) <= r, "%s %s in bounds" % [id, key])
				check(not seen.has(h), "%s %s not under a unit %s" % [id, key, h])
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
		check(d["target"] in ["self", "enemy", "hex"], "%s target kind" % id)
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
		while r.status != "victory" and r.status != "defeat" and guard < 40:
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
			check(pv["grow"].has(h), "%s: changed hex %s was previewed" % [id, h])
	var c := _blank_combat({"enemies": [["husk_brute", 1, 0]], "thicket": [[0, 0], [0, 1]]})
	var e: Dictionary = c.enemies[0]
	var uid := _give(c, "heartwood_maul")
	var pv := c.preview_card(c.hand[c.hand_index(uid)], e["pos"])
	var hp0: int = e["hp"]
	c.play_card(uid, e["pos"])
	check(pv["damage"][e["uid"]] == hp0 - int(e["hp"]), "maul damage preview exact")
	return true


## Heuristic bot used as a balance gauge (a competent human should beat it comfortably).
func test_smart_bot_balance() -> bool:
	var wins := 0
	var floors := []
	var seeds := range(100, 120)
	for s in seeds:
		var r := RunState.new()
		r.new_run(s)
		var guard := 0
		while r.status != "victory" and r.status != "defeat" and guard < 40:
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
		floors.append(r.floor_num)
	print("  smart bot: %d/%d region clears, floors reached %s" % [wins, seeds.size(), floors])
	check(wins >= 1, "smart bot clears the region at least once in 20 seeds")
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
