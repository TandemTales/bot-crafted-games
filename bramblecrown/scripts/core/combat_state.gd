class_name CombatState
extends RefCounted
## Pure combat rules. Scene code reads this state and calls play_card / move_player / end_turn.
## Every mutating call returns an Array of event dictionaries the view animates in order.

const HAND_SIZE := 5
const BASE_ENERGY := 3
const BASE_MOVE := 2
const ROT_LOSS := 2
const EMPOWER_BONUS := 2
const MAX_HAND := 10

var rng: Rng
var encounter: Dictionary
var radius := 3
var terrain := {}  # Vector2i -> "plain" | "water" | "stone"
var growth := {}  # Vector2i -> "none" | "thicket" | "blight"
var player := {}
var enemies: Array = []
var draw_pile: Array = []
var hand: Array = []
var discard: Array = []
var exhausted: Array = []
var charms: Array = []
var turn := 0
var phase := "player"  # player | won | lost
var attacks_this_turn := 0
var _next_uid := 1
var _events: Array = []
var _trace = null  # uid -> forecast, recorded only on the throwaway copy in enemy_forecasts()


# ------------------------------------------------------------------ setup

func setup(enc: Dictionary, deck: Array, hp: int, max_hp: int, charm_ids: Array, rng_in: Rng) -> Array:
	_events = []
	rng = rng_in
	encounter = enc
	radius = int(enc.get("radius", 3))
	charms = charm_ids.duplicate()
	for h in Hex.disc(Vector2i.ZERO, radius):
		terrain[h] = "plain"
		growth[h] = "none"
	for p in enc.get("water", []):
		terrain[Vector2i(p[0], p[1])] = "water"
	for p in enc.get("stone", []):
		terrain[Vector2i(p[0], p[1])] = "stone"
	for p in enc.get("blight", []):
		growth[Vector2i(p[0], p[1])] = "blight"
	for p in enc.get("thicket", []):
		growth[Vector2i(p[0], p[1])] = "thicket"
	player = {
		"pos": Vector2i(enc["player"][0], enc["player"][1]), "hp": hp, "max_hp": max_hp,
		"ward": 0, "energy": 0, "move": 0, "statuses": {}, "powers": {},
	}
	for e in enc["enemies"]:
		_spawn_enemy(e[0], Vector2i(e[1], e[2]), true)
	for c in deck:
		draw_pile.append({"uid": _uid(), "id": c["id"], "up": bool(c.get("up", false))})
	rng.shuffle(draw_pile)
	if charms.has("acorn_locket"):
		_grow_self(2)
	for e in enemies:
		_choose_intent(e)
	_start_player_turn(true)
	return _flush()


func _uid() -> int:
	_next_uid += 1
	return _next_uid


func _spawn_enemy(id: String, pos: Vector2i, initial: bool) -> Dictionary:
	var def := EnemyDB.get_def(id)
	var hp := rng.randi_range(def["hp"][0], def["hp"][1])
	var e := {
		"uid": _uid(), "id": id, "def": def, "pos": pos, "hp": hp, "max_hp": hp, "ward": 0,
		"strength": 0, "statuses": {}, "pattern_idx": 0, "phase2": false, "intent": {},
	}
	if initial and not def.get("boss", false) and not def.get("elite", false):
		e["pattern_idx"] = rng.randi_range(0, def["pattern"].size() - 1)
	enemies.append(e)
	return e


# ------------------------------------------------------------------ queries

func in_bounds(h: Vector2i) -> bool:
	return terrain.has(h)


func passable(h: Vector2i, flying: bool = false) -> bool:
	if not terrain.has(h):
		return false
	var t: String = terrain[h]
	if t == "stone":
		return false
	if t == "water":
		return flying
	return true


func enemy_at(h: Vector2i) -> Variant:
	for e in enemies:
		if e["pos"] == h:
			return e
	return null


func enemy_by_uid(uid: int) -> Variant:
	for e in enemies:
		if e["uid"] == uid:
			return e
	return null


func occupied(h: Vector2i) -> bool:
	return player["pos"] == h or enemy_at(h) != null


## Connected Thicket containing the Grovewalker's hex (empty if not standing on Thicket).
func grove() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var start: Vector2i = player["pos"]
	if growth.get(start, "none") != "thicket":
		return out
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var h: Vector2i = queue.pop_front()
		out.append(h)
		for n in Hex.neighbors(h):
			if not seen.has(n) and growth.get(n, "none") == "thicket":
				seen[n] = true
				queue.append(n)
	return out


func rooted_bonus() -> int:
	return grove().size() / 3


func card_def(inst: Dictionary) -> Dictionary:
	return CardDB.get_def(inst["id"], inst["up"])


func hand_index(uid: int) -> int:
	for i in hand.size():
		if hand[i]["uid"] == uid:
			return i
	return -1


func can_afford(inst: Dictionary) -> bool:
	return int(card_def(inst)["cost"]) <= int(player["energy"])


## Hexes a card may target. Self cards return [player pos].
func valid_targets(inst: Dictionary) -> Array[Vector2i]:
	var def := card_def(inst)
	var out: Array[Vector2i] = []
	match def["target"]:
		"self":
			out.append(player["pos"])
		"enemy":
			for e in enemies:
				if Hex.distance(player["pos"], e["pos"]) <= int(def["range"]):
					out.append(e["pos"])
		"hex":
			var is_line: bool = def["effects"][0]["op"] == "grow_line"
			for h in Hex.disc(player["pos"], int(def["range"])):
				if not in_bounds(h) or not passable(h):
					continue
				if is_line and h == player["pos"]:
					continue
				out.append(h)
	return out


func can_play(inst: Dictionary, target: Vector2i) -> bool:
	if phase != "player" or not can_afford(inst):
		return false
	return valid_targets(inst).has(target)


## Movement: hex -> cost, reachable with the current movement points.
func reachable() -> Dictionary:
	return _dijkstra(player["pos"], int(player["move"]), false, false, true)["cost"]


func path_to(dest: Vector2i) -> Array[Vector2i]:
	var res := _dijkstra(player["pos"], int(player["move"]), false, false, true)
	return _build_path(res["prev"], player["pos"], dest)


## What a card would do at `target`, without changing state: hexes that change and damage per enemy uid.
func preview_card(inst: Dictionary, target: Vector2i) -> Dictionary:
	var def := card_def(inst)
	var out := {"grow": [], "blight_clear": [], "burn": [], "damage": {}, "ward_break": {}}
	var g := grove()
	for fx in def["effects"]:
		match fx["op"]:
			"break_ward", "steal_ward":
				var e = enemy_at(target)
				if e != null:
					out["ward_break"][e["uid"]] = int(e["ward"]) if fx["op"] == "break_ward" else mini(int(e["ward"]), CardDB.val(def, fx["n"]))
			"ward_strike":
				var e = enemy_at(target)
				if e != null:
					out["damage"][e["uid"]] = CardDB.val(def, fx["amount"]) + g.size() / 3 + mini(int(player["ward"]), CardDB.val(def, fx["cap"]))
			"damage":
				var e = enemy_at(target)
				if e != null:
					var amt := CardDB.val(def, fx["amount"]) + g.size() / 3 + g.size() * CardDB.val(def, fx.get("grove_mult", 0))
					if fx.get("double_if", "") != "" and int(e["statuses"].get(fx["double_if"], 0)) > 0:
						amt *= 2
					out["damage"][e["uid"]] = int(out["damage"].get(e["uid"], 0)) + amt
			"damage_grove_area":
				var area := {}
				var src: Array = g if not g.is_empty() else [player["pos"]]
				for h in src:
					area[h] = true
					for n in Hex.neighbors(h):
						area[n] = true
				for e in enemies:
					if area.has(e["pos"]):
						out["damage"][e["uid"]] = int(out["damage"].get(e["uid"], 0)) + CardDB.val(def, fx["amount"]) + g.size() / 3
			"grow":
				out["grow"] += _cluster(target, CardDB.val(def, fx["count"]), func(h): return growth[h] != "thicket")
			"grow_self":
				var hexes: Array[Vector2i] = [player["pos"]]
				var n := 0
				for h in Hex.neighbors(player["pos"]):
					if n >= CardDB.val(def, fx["count"]):
						break
					if passable(h) and growth[h] != "thicket":
						hexes.append(h)
						n += 1
				out["grow"] += hexes
			"grow_line":
				var dir: Vector2i = Hex.DIRS[Hex.direction_toward(player["pos"], target)]
				for i in range(1, CardDB.val(def, fx["length"]) + 1):
					var h: Vector2i = player["pos"] + dir * i
					if not in_bounds(h):
						break
					if passable(h):
						out["grow"].append(h)
			"reclaim":
				out["grow"] += _cluster(target, CardDB.val(def, fx["count"]), func(h): return growth[h] == "blight", true)
			"cleanse":
				for h in Hex.disc(player["pos"], CardDB.val(def, fx["radius"])):
					if growth.get(h, "") == "blight":
						out["blight_clear"].append(h)
			"burn_grove":
				out["burn"] = g.duplicate()
				var touched := {}
				for h in g:
					touched[h] = true
					for n in Hex.neighbors(h):
						touched[n] = true
				var amt := mini(g.size(), int(fx.get("cap", 99))) * CardDB.val(def, fx["per_hex"])
				for e in enemies:
					if touched.has(e["pos"]) and amt > 0:
						out["damage"][e["uid"]] = int(out["damage"].get(e["uid"], 0)) + amt
			"weak_area":
				for h in Hex.disc(target, CardDB.val(def, fx["radius"])):
					if in_bounds(h):
						out["blight_clear"].append(h)
	return out


# ------------------------------------------------------------------ player actions

func move_player(dest: Vector2i) -> Array:
	_events = []
	if phase != "player":
		return _flush()
	var res := _dijkstra(player["pos"], int(player["move"]), false, false, true)
	if not res["cost"].has(dest) or dest == player["pos"]:
		return _flush()
	var path := _build_path(res["prev"], player["pos"], dest)
	player["move"] = int(player["move"]) - int(res["cost"][dest])
	player["pos"] = dest
	_emit({"type": "move", "who": "player", "path": path})
	return _flush()


func play_card(uid: int, target: Vector2i) -> Array:
	_events = []
	var idx := hand_index(uid)
	if idx < 0:
		return _flush()
	var inst: Dictionary = hand[idx]
	if not can_play(inst, target):
		return _flush()
	var def := card_def(inst)
	player["energy"] = int(player["energy"]) - int(def["cost"])
	hand.remove_at(idx)
	_emit({"type": "card_played", "uid": uid, "id": inst["id"], "target": target})
	var is_attack: bool = def["type"] == "attack"
	for fx in def["effects"]:
		_apply_effect(def, fx, target, is_attack)
		if phase != "player":
			break
	if is_attack:
		attacks_this_turn += 1
	if def["type"] == "power" or def.get("exhaust", false):
		exhausted.append(inst)
	else:
		discard.append(inst)
	_check_victory()
	return _flush()


func end_turn() -> Array:
	_events = []
	if phase != "player":
		return _flush()
	_emit({"type": "end_turn"})
	# Hand is discarded.
	for c in hand:
		discard.append(c)
	hand.clear()
	# Rot.
	if growth.get(player["pos"], "none") == "blight" and not charms.has("rot_ward"):
		_lose_hp(ROT_LOSS, "rot")
	_tick_player_statuses()
	if phase != "player":
		return _flush()
	if not _enemy_phase():
		return _flush()
	_check_victory()
	if phase != "player":
		return _flush()
	for e in enemies:
		_choose_intent(e)
	_start_player_turn(false)
	return _flush()


# ------------------------------------------------------------------ effects

func _apply_effect(def: Dictionary, fx: Dictionary, target: Vector2i, is_attack: bool) -> void:
	var g := grove()
	match fx["op"]:
		"break_ward", "steal_ward":
			var e = enemy_at(target)
			if e != null:
				var n := int(e["ward"]) if fx["op"] == "break_ward" else mini(int(e["ward"]), CardDB.val(def, fx["n"]))
				e["ward"] = int(e["ward"]) - n
				_emit({"type": "ward", "target": e["uid"], "n": e["ward"], "gain": -n})
				if fx["op"] == "steal_ward":
					_gain_ward(n)
		"ward_strike":
			var e = enemy_at(target)
			if e != null:
				var amt := CardDB.val(def, fx["amount"]) + g.size() / 3 + mini(int(player["ward"]), CardDB.val(def, fx["cap"]))
				player["ward"] = 0
				_emit({"type": "ward", "target": "player", "n": 0, "gain": 0})
				_damage_enemy(e, amt)
				if is_attack and attacks_this_turn == 0 and charms.has("ember_fang") and enemies.has(e):
					_add_status(e, "bleed", 2)
		"clarity":
			player["statuses"]["clarity"] = 1
			_emit({"type": "status", "target": "player", "status": "clarity", "n": 1})
		"reserve_ward":
			player["statuses"]["ward_keep"] = maxi(int(player["statuses"].get("ward_keep", 0)), CardDB.val(def, fx["n"]))
		"recover_daze":
			var refund := int(player.get("daze_lost", 0))
			player["energy"] = int(player["energy"]) + refund
			player["daze_lost"] = 0
			_emit({"type": "energy", "n": player["energy"]})
		"damage":
			var e = enemy_at(target)
			if e == null:
				return
			var amt := CardDB.val(def, fx["amount"]) + g.size() / 3 + g.size() * CardDB.val(def, fx.get("grove_mult", 0))
			if fx.get("double_if", "") != "" and int(e["statuses"].get(fx["double_if"], 0)) > 0:
				amt *= 2
			_damage_enemy(e, amt)
			if is_attack and attacks_this_turn == 0 and charms.has("ember_fang") and enemies.has(e):
				_add_status(e, "bleed", 2)
		"damage_grove_area":
			var area := {}
			var src: Array = g if not g.is_empty() else [player["pos"]]
			for h in src:
				area[h] = true
				for n in Hex.neighbors(h):
					area[n] = true
			var amt := CardDB.val(def, fx["amount"]) + g.size() / 3
			for e in enemies.duplicate():
				if area.has(e["pos"]):
					_damage_enemy(e, amt)
		"ward":
			var amt := CardDB.val(def, fx["amount"]) + g.size() / 3 + g.size() * CardDB.val(def, fx.get("grove_mult", 0))
			_gain_ward(amt)
		"grow":
			_grow_hexes(_cluster(target, CardDB.val(def, fx["count"]), func(h): return growth[h] != "thicket"))
		"grow_self":
			_grow_self(CardDB.val(def, fx["count"]))
		"grow_line":
			var dir: Vector2i = Hex.DIRS[Hex.direction_toward(player["pos"], target)]
			var hexes: Array[Vector2i] = []
			for i in range(1, CardDB.val(def, fx["length"]) + 1):
				var h: Vector2i = player["pos"] + dir * i
				if not in_bounds(h):
					break
				if passable(h):
					hexes.append(h)
			_grow_hexes(hexes)
		"reclaim":
			var hexes := _cluster(target, CardDB.val(def, fx["count"]), func(h): return growth[h] == "blight", true)
			var changes := {}
			for h in hexes:
				growth[h] = "thicket"
				changes[h] = "thicket"
			if not changes.is_empty():
				_emit({"type": "board", "changes": changes, "cause": "grow"})
		"cleanse":
			var changes := {}
			for h in Hex.disc(player["pos"], CardDB.val(def, fx["radius"])):
				if growth.get(h, "") == "blight":
					growth[h] = "none"
					changes[h] = "none"
			if not changes.is_empty():
				_emit({"type": "board", "changes": changes, "cause": "cleanse"})
		"burn_grove":
			if g.is_empty():
				return
			var changes := {}
			var touched := {}
			for h in g:
				growth[h] = "none"
				changes[h] = "none"
				touched[h] = true
				for n in Hex.neighbors(h):
					touched[n] = true
			_emit({"type": "board", "changes": changes, "cause": "burn"})
			var amt := mini(g.size(), int(fx.get("cap", 99))) * CardDB.val(def, fx["per_hex"])
			for e in enemies.duplicate():
				if touched.has(e["pos"]):
					_damage_enemy(e, amt)
		"apply":
			var e = enemy_at(target)
			if e == null:
				return
			if fx.has("if_on") and growth.get(e["pos"], "") != fx["if_on"]:
				return
			_add_status(e, fx["status"], CardDB.val(def, fx["n"]))
		"weak_area":
			for e in enemies:
				if Hex.distance(e["pos"], target) <= CardDB.val(def, fx["radius"]):
					_add_status(e, "weak", CardDB.val(def, fx["n"]))
		"power":
			var pid: String = fx["id"]
			player["powers"][pid] = int(player["powers"].get(pid, 0)) + CardDB.val(def, fx["n"])
			_emit({"type": "power", "id": pid, "n": player["powers"][pid]})
		"draw":
			_draw(CardDB.val(def, fx["n"]))
		"energy":
			player["energy"] = int(player["energy"]) + CardDB.val(def, fx["n"])
			_emit({"type": "energy", "n": player["energy"]})
		"energy_if_grove":
			if g.size() >= int(fx["min"]):
				player["energy"] = int(player["energy"]) + CardDB.val(def, fx["n"])
				_emit({"type": "energy", "n": player["energy"]})
		"move":
			player["move"] = int(player["move"]) + CardDB.val(def, fx["n"])
			_emit({"type": "move_points", "n": player["move"]})


## BFS outward from `center` over in-bounds passable hexes, collecting up to `count` hexes matching `pred`.
func _cluster(center: Vector2i, count: int, pred: Callable, allow_skip: bool = true) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not in_bounds(center):
		return out
	var seen := {center: true}
	var queue: Array[Vector2i] = [center]
	while not queue.is_empty() and out.size() < count:
		var h: Vector2i = queue.pop_front()
		if passable(h) and pred.call(h):
			out.append(h)
		elif not allow_skip:
			continue
		for n in Hex.neighbors(h):
			if not seen.has(n) and in_bounds(n) and passable(n):
				seen[n] = true
				queue.append(n)
	return out


## Growth on a hex: blight -> none, none -> thicket.
func _grow_hexes(hexes: Array) -> void:
	var changes := {}
	for h in hexes:
		if not passable(h):
			continue
		match growth[h]:
			"blight":
				growth[h] = "none"
				changes[h] = "none"
			"none":
				growth[h] = "thicket"
				changes[h] = "thicket"
	if not changes.is_empty():
		_emit({"type": "board", "changes": changes, "cause": "grow"})


func _grow_self(extra: int) -> void:
	var hexes: Array[Vector2i] = [player["pos"]]
	var n := 0
	for h in Hex.neighbors(player["pos"]):
		if n >= extra:
			break
		if passable(h) and growth[h] != "thicket":
			hexes.append(h)
			n += 1
	_grow_hexes(hexes)


## Blight on a hex: thicket -> none, none -> blight.
func _blight_hexes(hexes: Array) -> void:
	var changes := {}
	for h in hexes:
		if not passable(h):
			continue
		match growth[h]:
			"thicket":
				growth[h] = "none"
				changes[h] = "none"
			"none":
				growth[h] = "blight"
				changes[h] = "blight"
	if not changes.is_empty():
		_emit({"type": "board", "changes": changes, "cause": "blight"})


func _gain_ward(n: int) -> void:
	player["ward"] = int(player["ward"]) + n
	_emit({"type": "ward", "target": "player", "n": player["ward"], "gain": n})


func _draw(n: int) -> void:
	var drawn := 0
	for _i in n:
		if hand.size() >= MAX_HAND:
			break
		if draw_pile.is_empty():
			if discard.is_empty():
				break
			draw_pile = discard.duplicate()
			discard.clear()
			rng.shuffle(draw_pile)
			_emit({"type": "reshuffle"})
		hand.append(draw_pile.pop_back())
		drawn += 1
	if drawn > 0:
		_emit({"type": "draw", "n": drawn})


func _add_status(e: Dictionary, status: String, n: int) -> void:
	e["statuses"][status] = int(e["statuses"].get(status, 0)) + n
	_emit({"type": "status", "target": e["uid"], "status": status, "n": e["statuses"][status]})


# ------------------------------------------------------------------ damage

func _damage_enemy(e: Dictionary, amount: int) -> void:
	if amount <= 0 or not enemies.has(e):
		return
	var blocked := mini(int(e["ward"]), amount)
	e["ward"] = int(e["ward"]) - blocked
	var dealt := amount - blocked
	e["hp"] = int(e["hp"]) - dealt
	_emit({"type": "damage", "target": e["uid"], "amount": dealt, "blocked": blocked})
	if int(e["hp"]) <= 0:
		_kill_enemy(e)
	elif e["def"].has("phase2_at") and not e["phase2"] and int(e["hp"]) <= int(e["max_hp"] * float(e["def"]["phase2_at"])):
		e["phase2"] = true
		e["pattern_idx"] = 0
		_emit({"type": "phase2", "target": e["uid"]})


func _kill_enemy(e: Dictionary) -> void:
	enemies.erase(e)
	_emit({"type": "death", "target": e["uid"], "pos": e["pos"]})
	if e["def"].get("death_blight", false):
		_blight_hexes([e["pos"]])
	if e["def"].get("boss", false):
		# Brood dies with its mother.
		for other in enemies.duplicate():
			_kill_enemy(other)


func _damage_player(amount: int, attacker) -> void:
	var blocked := mini(int(player["ward"]), amount)
	player["ward"] = int(player["ward"]) - blocked
	var dealt := amount - blocked
	player["hp"] = int(player["hp"]) - dealt
	_emit({"type": "damage", "target": "player", "amount": dealt, "blocked": blocked})
	var thorns := int(player["powers"].get("thorns", 0))
	if thorns > 0 and attacker != null and enemies.has(attacker):
		_damage_enemy(attacker, thorns)
	if int(player["hp"]) <= 0:
		player["hp"] = 0
		phase = "lost"
		_emit({"type": "lost"})


func _lose_hp(amount: int, cause: String) -> void:
	player["hp"] = int(player["hp"]) - amount
	_emit({"type": "hp_loss", "target": "player", "amount": amount, "cause": cause})
	if int(player["hp"]) <= 0:
		player["hp"] = 0
		phase = "lost"
		_emit({"type": "lost"})


func _check_victory() -> void:
	if phase == "player" and enemies.is_empty():
		phase = "won"
		_emit({"type": "won"})


# ------------------------------------------------------------------ turns

func _start_player_turn(first: bool) -> void:
	turn += 1
	attacks_this_turn = 0
	player["ward"] = mini(int(player["ward"]), int(player["statuses"].get("ward_keep", 0)))
	player["statuses"].erase("ward_keep")
	player["statuses"].erase("clarity")
	player["energy"] = BASE_ENERGY
	player["daze_lost"] = 0
	var dazed := int(player["statuses"].get("dazed", 0))
	if dazed > 0:
		player["energy"] = maxi(1, BASE_ENERGY - dazed)
		player["daze_lost"] = BASE_ENERGY - int(player["energy"])
		player["statuses"].erase("dazed")
		_emit({"type": "dazed", "target": "player", "n": dazed})
	player["move"] = BASE_MOVE + (1 if charms.has("heron_feather") else 0)
	if first and charms.has("ironbark_husk"):
		player["ward"] = 8
	_emit({"type": "turn_start", "turn": turn})
	var og := int(player["powers"].get("overgrowth", 0))
	if og > 0:
		var g := grove()
		var edge: Array[Vector2i] = []
		var src: Array = g if not g.is_empty() else [player["pos"]]
		for h in src:
			for n in Hex.neighbors(h):
				if passable(n) and growth[n] != "thicket" and not edge.has(n):
					edge.append(n)
		edge.sort_custom(func(a, b): return Hex.distance(a, player["pos"]) < Hex.distance(b, player["pos"]))
		var pick: Array[Vector2i] = []
		if g.is_empty() and growth[player["pos"]] != "thicket":
			pick.append(player["pos"])
		for h in edge:
			if pick.size() >= og:
				break
			pick.append(h)
		_grow_hexes(pick)
	if int(player["powers"].get("seed_of_ages", 0)) > 0:
		var gs := grove().size()
		if gs > 0:
			_gain_ward(gs)
	if charms.has("grove_bell") and grove().size() >= 6:
		player["energy"] = int(player["energy"]) + 1
	_draw(HAND_SIZE + (2 if first and charms.has("seed_pouch") else 0))


func _tick_player_statuses() -> void:
	pass


func _choose_intent(e: Dictionary) -> void:
	var def: Dictionary = e["def"]
	var pattern: Array = def["pattern2"] if e["phase2"] else def["pattern"]
	for _try in pattern.size():
		var mi: int = pattern[e["pattern_idx"] % pattern.size()]
		e["pattern_idx"] = int(e["pattern_idx"]) + 1
		var mv: Dictionary = def["moves"][mi].duplicate(true)
		if _move_is_useful(e, mv):
			_lock_targets(e, mv)
			e["intent"] = mv
			return
	var fallback: Dictionary = def["moves"][pattern[0]].duplicate(true)
	_lock_targets(e, fallback)
	e["intent"] = fallback


func _move_is_useful(e: Dictionary, mv: Dictionary) -> bool:
	for a in mv["actions"]:
		if a["t"] == "summon":
			var alive := 0
			for o in enemies:
				if o["id"] == a["enemy"]:
					alive += 1
			if alive >= int(a["max"]):
				return false
	return true


func _lock_targets(e: Dictionary, mv: Dictionary) -> void:
	for a in mv["actions"]:
		match a["t"]:
			"spread":
				a["hexes"] = _pick_blight_targets(player["pos"], int(a["radius"]), int(a["count"]))
			"blight_self":
				a["hexes"] = _pick_blight_targets(e["pos"], int(a["radius"]), int(a["count"]))


func _pick_blight_targets(center: Vector2i, r: int, count: int) -> Array:
	var cands: Array = []
	for h in Hex.disc(center, r):
		if passable(h) and growth[h] != "blight":
			cands.append(h)
	# Deterministic but varied: shuffle, then stable-sort by distance (thicket first).
	rng.shuffle(cands)
	cands.sort_custom(func(a, b):
		var da := Hex.distance(a, center) * 2 - (1 if growth[a] == "thicket" else 0)
		var db := Hex.distance(b, center) * 2 - (1 if growth[b] == "thicket" else 0)
		return da < db)
	return cands.slice(0, count)


func intent_attack(e: Dictionary) -> Dictionary:
	for a in e["intent"].get("actions", []):
		if a["t"] == "attack":
			return a
	return {}


## Damage an enemy attack would deal right now (strength, blight empowerment, weak).
func attack_damage(e: Dictionary, base: int, at_pos = null) -> int:
	var pos: Vector2i = e["pos"] if at_pos == null else at_pos
	var dmg := base + int(e["strength"])
	if growth.get(pos, "none") == "blight":
		dmg += EMPOWER_BONUS
	if int(e["statuses"].get("weak", 0)) > 0:
		dmg = int(floor(dmg * 0.75))
	return maxi(dmg, 0)


## Live preview of an enemy's upcoming turn given the current board.
func enemy_preview(e: Dictionary) -> Dictionary:
	var fc := enemy_forecasts()
	if fc.has(e["uid"]):
		return fc[e["uid"]]
	# Dies before acting (bleed, or a boss falling takes its brood with it).
	return {"path": [] as Array[Vector2i], "end": e["pos"], "attack": false, "dmg": 0, "hits": false}


## Forecast for every enemy, keyed by uid. Enemies act in order, so the coming phase is run on
## a throwaway copy: each enemy sees the moves, trample, blight, summons and deaths of the allies
## that act before it. The real state and its RNG are untouched.
func enemy_forecasts() -> Dictionary:
	var sim := CombatState.new()
	sim.rng = Rng.new()
	sim.rng.set_state(rng.get_state())
	sim.encounter = encounter
	sim.radius = radius
	sim.terrain = terrain
	sim.growth = growth.duplicate()
	sim.player = player.duplicate(true)
	sim.player["hp"] = 1 << 30  # an earlier lethal hit must not hide later forecasts
	sim.enemies = enemies.duplicate(true)
	sim.charms = charms
	sim.turn = turn
	sim._next_uid = _next_uid
	sim._trace = {}
	sim._enemy_phase()
	return sim._trace


## Resolves every enemy in order. Returns false if the fight ended mid-phase.
func _enemy_phase() -> bool:
	# Enemy ward lasts through the player's turn and drops as the enemies act.
	for e in enemies:
		e["ward"] = 0
	for e in enemies.duplicate():
		if not enemies.has(e):
			continue
		_enemy_act(e)
		if phase != "player":
			return false
	return true


func _enemy_act(e: Dictionary) -> void:
	# Bleed ticks at the start of the enemy's action.
	var bleed := int(e["statuses"].get("bleed", 0))
	if bleed > 0:
		e["hp"] = int(e["hp"]) - bleed
		_emit({"type": "damage", "target": e["uid"], "amount": bleed, "blocked": 0, "cause": "bleed"})
		e["statuses"]["bleed"] = bleed - 1
		if int(e["hp"]) <= 0:
			_kill_enemy(e)
			return
	var mv: Dictionary = e["intent"]
	_emit({"type": "enemy_act", "target": e["uid"], "name": mv.get("name", "")})
	var path := _enemy_plan_path(e)
	if not path.is_empty():
		var trampled := {}
		for h in path:
			if e["def"].get("trample", false) and growth[h] == "thicket":
				growth[h] = "none"
				trampled[h] = "none"
		e["pos"] = path.back()
		_emit({"type": "move", "who": e["uid"], "path": path})
		if not trampled.is_empty():
			_emit({"type": "board", "changes": trampled, "cause": "trample"})
	if _trace != null:
		var atk := intent_attack(e)
		_trace[e["uid"]] = {"path": path, "end": e["pos"], "attack": not atk.is_empty(), "dmg": 0, "hits": false}
		if not atk.is_empty():
			_trace[e["uid"]]["dmg"] = attack_damage(e, int(atk["dmg"]))
			_trace[e["uid"]]["hits"] = Hex.distance(e["pos"], player["pos"]) <= int(atk["range"])
	for a in mv.get("actions", []):
		if not enemies.has(e) or phase != "player":
			return
		match a["t"]:
			"attack":
				if _trace != null and a == intent_attack(e):
					_trace[e["uid"]]["dmg"] = attack_damage(e, int(a["dmg"]))  # after earlier buffs
				if Hex.distance(e["pos"], player["pos"]) <= int(a["range"]):
					_emit({"type": "attack", "source": e["uid"], "range": a["range"]})
					_damage_player(attack_damage(e, int(a["dmg"])), e)
				else:
					_emit({"type": "miss", "source": e["uid"]})
			"spread", "blight_self":
				_blight_hexes(a.get("hexes", []))
			"summon":
				var alive := 0
				for o in enemies:
					if o["id"] == a["enemy"]:
						alive += 1
				var n := mini(int(a["count"]), int(a["max"]) - alive)
				var spots: Array = []
				for r in range(1, radius * 2 + 1):
					for h in Hex.ring(e["pos"], r):
						if passable(h) and not occupied(h) and in_bounds(h):
							spots.append(h)
					if spots.size() >= n:
						break
				for i in mini(n, spots.size()):
					var ne := _spawn_enemy(a["enemy"], spots[i], false)
					_choose_intent(ne)
					_emit({"type": "summon", "target": ne["uid"], "pos": ne["pos"], "source": e["uid"]})
			"ward":
				e["ward"] = int(e["ward"]) + int(a["n"])
				_emit({"type": "ward", "target": e["uid"], "n": e["ward"], "gain": a["n"]})
			"strength":
				e["strength"] = int(e["strength"]) + int(a["n"])
				_emit({"type": "status", "target": e["uid"], "status": "strength", "n": e["strength"]})
			"daze":
				var st: Dictionary = player["statuses"]
				if int(st.get("clarity", 0)) > 0:
					_emit({"type": "status", "target": "player", "status": "clarity", "n": 1, "source": e["uid"]})
					continue
				st["dazed"] = mini(2, int(st.get("dazed", 0)) + int(a["n"]))
				_emit({"type": "status", "target": "player", "status": "dazed", "n": st["dazed"], "source": e["uid"]})
			"shield_allies":
				for o in enemies:
					if o != e:
						o["ward"] = int(o["ward"]) + int(a["n"])
						_emit({"type": "ward", "target": o["uid"], "n": o["ward"], "gain": a["n"]})
			"heal_allies":
				for o in enemies:
					var before := int(o["hp"])
					o["hp"] = mini(int(o["max_hp"]), before + int(a["n"]))
					if int(o["hp"]) > before:
						_emit({"type": "heal", "target": o["uid"], "n": int(o["hp"]) - before})
	for s in ["rooted", "weak"]:
		if int(e["statuses"].get(s, 0)) > 0:
			e["statuses"][s] = int(e["statuses"][s]) - 1


## Where the enemy will walk this turn (excluding its start hex).
func _enemy_plan_path(e: Dictionary) -> Array[Vector2i]:
	var none: Array[Vector2i] = []
	var mv: Dictionary = e["intent"]
	if mv.get("stay", false) or int(e["statuses"].get("rooted", 0)) > 0:
		return none
	var def: Dictionary = e["def"]
	var budget := int(def["move"]) + int(mv.get("move_bonus", 0))
	var atk := intent_attack(e)
	var pref := int(def.get("keep_range", 1))
	if not atk.is_empty():
		pref = mini(pref, int(atk["range"]))
	var res := _dijkstra(e["pos"], budget, def.get("flying", false), true, false, e)
	var best: Vector2i = e["pos"]
	var best_score := 1 << 30
	var keys: Array = res["cost"].keys()
	keys.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
	for h in keys:
		var d := Hex.distance(h, player["pos"])
		var score := absi(d - pref) * 100 + int(res["cost"][h])
		if score < best_score:
			best_score = score
			best = h
	if best == e["pos"]:
		return none
	return _build_path(res["prev"], e["pos"], best)


## Dijkstra over the board. Enemies pay extra to enter Thicket; units block.
func _dijkstra(start: Vector2i, budget: int, flying: bool, is_enemy: bool, is_player: bool, self_enemy = null) -> Dictionary:
	var cost := {start: 0}
	var prev := {}
	var frontier: Array = [[0, start]]
	var thicket_cost := 3 if charms.has("thorn_crown_shard") else 2
	while not frontier.is_empty():
		frontier.sort_custom(func(a, b): return a[0] < b[0])
		var cur = frontier.pop_front()
		var c: int = cur[0]
		var h: Vector2i = cur[1]
		if c > int(cost.get(h, 1 << 30)):
			continue
		for n in Hex.neighbors(h):
			if not passable(n, flying):
				continue
			if n == player["pos"]:
				continue
			var blocker = enemy_at(n)
			if blocker != null and blocker != self_enemy:
				continue
			var step := 1
			if is_enemy and not flying and growth[n] == "thicket":
				step = thicket_cost
			var nc := c + step
			if nc > budget:
				continue
			if nc < int(cost.get(n, 1 << 30)):
				cost[n] = nc
				prev[n] = h
				frontier.append([nc, n])
	# A flying unit cannot end its move on water.
	if flying:
		for h in cost.keys():
			if terrain[h] == "water":
				cost.erase(h)
	if is_player:
		cost.erase(start)
	return {"cost": cost, "prev": prev}


func _build_path(prev: Dictionary, start: Vector2i, dest: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var h := dest
	var guard := 0
	while h != start and guard < 200:
		path.push_front(h)
		if not prev.has(h):
			return []
		h = prev[h]
		guard += 1
	return path


# ------------------------------------------------------------------ events

func _emit(ev: Dictionary) -> void:
	_events.append(ev)


func _flush() -> Array:
	var out := _events
	_events = []
	return out
