class_name RunState
extends RefCounted
## A single run: deck, HP, gold, charms, region map, and progression. Serializable to JSON.

const ROWS := 7
const START_HP := 72
## The plain strike and guard of every Grovewalker; events may strip one from the deck.
const STARTER_BASICS := ["thornstrike", "barkskin", "cinder_strike", "ashen_guard"]
const NODE_WEIGHTS := {"fight": 46, "shrine": 20, "elite": 12, "market": 12, "camp": 10}

var seed_value := 0
var rng: Rng
var walker := "wren"
var withering := 0  # difficulty tier 0-10, see Withering
var hp := START_HP
var max_hp := START_HP
var gold := 99
var deck: Array = []  # [{id, up}]
var charms: Array = []
var region := 0
var map: Array = []  # [{id, row, col, width, type, links:[ids]}]
var node_id := -1
var floor_num := 0
var used_encounters: Array = []
var used_events: Array = []
var reward := {}  # pending reward after a fight
var market := {}  # current market stock
var status := "map"  # map | combat | reward | camp | shrine | market | victory | defeat
var current_event := ""
var current_encounter := ""
var stats := {"fights": 0, "elites": 0, "bosses": 0, "cards_played": 0}


func new_run(seed_in: int, walker_in: String = "wren", withering_in: int = 0) -> void:
	seed_value = seed_in
	rng = Rng.new(seed_in)
	walker = walker_in
	withering = Withering.clamp_tier(withering_in)
	hp = int(WalkerDB.get_def(walker)["hp"])
	if withering >= 4:
		hp -= 8
	max_hp = hp
	gold = 49 if withering >= 10 else 99
	deck = []
	for id in CardDB.STARTER_DECK[walker]:
		deck.append({"id": id, "up": false})
	charms = ["acorn_locket"]
	region = 0
	node_id = -1
	floor_num = 0
	status = "map"
	generate_map()


func region_def() -> Dictionary:
	return EncounterDB.REGIONS[mini(region, EncounterDB.REGIONS.size() - 1)]


# ------------------------------------------------------------------ map

func generate_map() -> void:
	map = []
	var rows: Array = []
	var next_id := 0
	for row in ROWS:
		var width := 3 if row == 0 or row == ROWS - 1 else rng.randi_range(2, 4)
		var row_nodes: Array = []
		for col in width:
			var t := "fight"
			if row == ROWS - 1:
				t = "camp"
			elif row > 0:
				var w := NODE_WEIGHTS.duplicate()
				if row < 2:
					w.erase("elite")
				if row < 2 or row == ROWS - 2:
					w.erase("camp")
				t = rng.weighted(w)
			var n := {"id": next_id, "row": row, "col": col, "width": width, "type": t, "links": []}
			next_id += 1
			row_nodes.append(n)
			map.append(n)
		rows.append(row_nodes)
	# Every region offers at least one elite (its charm), one shrine and one pedlar.
	for need in ["elite", "shrine", "market"]:
		if map.any(func(n): return n["type"] == need):
			continue
		var lo := 2 if need == "elite" else 1
		var spots: Array = map.filter(func(n): return n["type"] == "fight" and n["row"] >= lo and n["row"] <= ROWS - 2)
		if not spots.is_empty():
			spots[rng.randi_range(0, spots.size() - 1)]["type"] = need
	var boss := {"id": next_id, "row": ROWS, "col": 0, "width": 1, "type": "boss", "links": []}
	map.append(boss)
	# Link rows: each node to its nearest node above, sometimes a neighbour too.
	for row in ROWS - 1:
		var a: Array = rows[row]
		var b: Array = rows[row + 1]
		for n in a:
			var x: float = (n["col"] + 0.5) / n["width"]
			var best := 0
			for j in b.size():
				if absf((j + 0.5) / b.size() - x) < absf((best + 0.5) / b.size() - x):
					best = j
			n["links"].append(b[best]["id"])
			if rng.randf() < 0.45:
				var alt := best + (1 if rng.randf() < 0.5 else -1)
				if alt >= 0 and alt < b.size() and not n["links"].has(b[alt]["id"]):
					n["links"].append(b[alt]["id"])
		for j in b.size():
			var has_in := false
			for n in a:
				if n["links"].has(b[j]["id"]):
					has_in = true
			if not has_in:
				var x: float = (j + 0.5) / b.size()
				var best_n = a[0]
				for n in a:
					if absf((n["col"] + 0.5) / n["width"] - x) < absf((best_n["col"] + 0.5) / best_n["width"] - x):
						best_n = n
				best_n["links"].append(b[j]["id"])
	for n in rows[ROWS - 1]:
		n["links"].append(boss["id"])
	# Avoid two elites in a row on any link.
	for n in map:
		if n["type"] == "elite":
			for l in n["links"]:
				var m = node(l)
				if m["type"] == "elite":
					m["type"] = "fight"


func node(id: int) -> Dictionary:
	for n in map:
		if n["id"] == id:
			return n
	return {}


func available_nodes() -> Array:
	if node_id < 0:
		var out := []
		for n in map:
			if n["row"] == 0:
				out.append(n["id"])
		return out
	return node(node_id).get("links", [])


func enter_node(id: int) -> String:
	if not available_nodes().has(id):
		return ""
	node_id = id
	# Optional node metadata: old checkpoints remain valid without invented history.
	node(id)["visited"] = true
	floor_num += 1
	var t: String = node(id)["type"]
	match t:
		"fight", "elite", "boss":
			status = "combat"
		"shrine":
			status = "shrine"
			current_event = _pick_event()
		"market":
			status = "market"
			_stock_market()
		"camp":
			status = "camp"
	return t


# ------------------------------------------------------------------ combat

func encounter_for_current() -> String:
	var n := node(node_id)
	var reg := region_def()
	match n.get("type", "fight"):
		"boss":
			return reg["boss"]
		"elite":
			return reg["elites"][0]
	var pool: Array = []
	for id in reg["fights"]:
		if not used_encounters.has(id):
			pool.append(id)
	if pool.is_empty():
		pool = reg["fights"].duplicate()
	if n.get("row", 0) <= 1:
		# Early floors use the gentlest layouts.
		var easy_ids: Array = reg.get("easy", [])
		var easy := pool.filter(func(e): return e in easy_ids)
		if not easy.is_empty():
			pool = easy
	var pick: String = pool[stable_index(n.get("id", 0), pool.size())]
	return pick


func stable_index(salt: int, size: int) -> int:
	return (seed_value * 31 + salt * 17 + floor_num * 7) % maxi(size, 1)


func make_combat() -> CombatState:
	if current_encounter == "":
		current_encounter = encounter_for_current()
	var enc_id := current_encounter
	if not used_encounters.has(enc_id):
		used_encounters.append(enc_id)
	var c := CombatState.new()
	c.walker = walker
	c.withering = withering
	var combat_rng := Rng.new(seed_value * 1000 + floor_num)
	c.setup(EncounterDB.get_def(enc_id), deck, hp, max_hp, charms, combat_rng)
	return c


func finish_combat(c: CombatState) -> void:
	hp = int(c.player["hp"])
	current_encounter = ""
	if c.phase == "lost":
		status = "defeat"
		return
	var t: String = node(node_id).get("type", "fight")
	stats["fights"] += 1
	if charms.has("mossy_flask"):
		hp = mini(max_hp, hp + 6)
	match t:
		"elite":
			stats["elites"] += 1
			reward = {"gold": rng.randi_range(28, 38), "cards": roll_cards(_reward_choices(), 1.6), "charm": roll_charm()}
		"boss":
			stats["bosses"] += 1
			reward = {"gold": rng.randi_range(80, 95), "cards": roll_cards(_reward_choices(), 3.0), "charm": roll_charm()}
		_:
			reward = {"gold": rng.randi_range(12, 20), "cards": roll_cards(_reward_choices(), 1.0), "charm": ""}
	if withering >= 2:
		reward["gold"] = int(round(int(reward["gold"]) * 0.8))
	gold += int(reward["gold"])
	status = "reward"


func _reward_choices() -> int:
	var n := 4 if charms.has("cartographers_quill") else 3
	return maxi(2, n - 1) if withering >= 8 else n


func roll_cards(n: int, luck: float) -> Array:
	var pool := CardDB.reward_pool(walker, region)
	var out := []
	var guard := 0
	while out.size() < n and guard < 100:
		guard += 1
		var rarity: String = rng.weighted({"common": 60.0, "uncommon": 32.0 * luck, "rare": 6.0 * luck})
		var cands := pool.filter(func(id): return CardDB.CARDS[id]["rarity"] == rarity and not out.has(id))
		if cands.is_empty():
			continue
		out.append(rng.pick(cands))
	return out


func roll_charm() -> String:
	var cands := CharmDB.CHARMS.keys().filter(func(id): return not charms.has(id))
	if cands.is_empty():
		return ""
	return rng.pick(cands)


func take_reward_card(id: String) -> void:
	if reward.get("cards", []).has(id):
		deck.append({"id": id, "up": false})
		reward["cards"] = []


func take_reward_charm() -> void:
	var c: String = reward.get("charm", "")
	if c != "":
		add_charm(c)
		reward["charm"] = ""


func add_charm(id: String) -> void:
	if charms.has(id):
		return
	charms.append(id)
	if id == "gilded_acorn":
		gold += 60
	if id == "amber_heart":
		max_hp += 10
		hp += 10


## Called after the reward screen. Boss clear ends the region (and, for now, the run).
func leave_reward() -> void:
	reward = {}
	if node(node_id).get("type", "") == "boss":
		if region + 1 >= EncounterDB.REGIONS.size():
			status = "victory"
		else:
			region += 1
			node_id = -1
			used_encounters.clear()
			generate_map()
			hp = mini(max_hp, hp + int(max_hp * 0.5))
			status = "map"
	else:
		status = "map"


# ------------------------------------------------------------------ camp / market / shrine

func camp_heal_amount() -> int:
	return mini(max_hp - hp, int(ceil(max_hp * (0.2 if withering >= 7 else 0.3))))


func camp_rest() -> int:
	var heal := camp_heal_amount()
	var before := hp
	hp = mini(max_hp, hp + heal)
	status = "map"
	return hp - before


func upgrade_card(index: int) -> bool:
	if index < 0 or index >= deck.size() or deck[index]["up"]:
		return false
	deck[index]["up"] = true
	if status == "camp":
		status = "map"
	return true


func _stock_market() -> void:
	var cards := roll_cards(5, 1.4)
	var items := []
	for id in cards:
		var r: String = CardDB.CARDS[id]["rarity"]
		var price: int = {"common": 50, "uncommon": 75, "rare": 140}[r] + rng.randi_range(-6, 6)
		items.append({"kind": "card", "id": id, "price": price, "sold": false})
	for _i in 2:
		var ch := roll_charm()
		if ch != "" and not items.any(func(it): return it["id"] == ch):
			items.append({"kind": "charm", "id": ch, "price": 150 + rng.randi_range(-10, 10), "sold": false})
	if charms.has("haggler_tooth"):
		for it in items:
			it["price"] = int(round(int(it["price"]) * 0.75))
	if withering >= 5:
		for it in items:
			it["price"] = int(round(int(it["price"]) * 1.25))
	market = {"items": items, "remove_price": 56 if charms.has("haggler_tooth") else 75, "removed": false}


func market_buy(index: int) -> bool:
	var items: Array = market.get("items", [])
	if index < 0 or index >= items.size():
		return false
	var it: Dictionary = items[index]
	if it["sold"] or gold < int(it["price"]):
		return false
	gold -= int(it["price"])
	it["sold"] = true
	if it["kind"] == "card":
		deck.append({"id": it["id"], "up": false})
	else:
		add_charm(it["id"])
	return true


func market_remove(deck_index: int) -> bool:
	if market.get("removed", true) or gold < int(market["remove_price"]):
		return false
	if deck_index < 0 or deck_index >= deck.size() or deck.size() <= 5:
		return false
	gold -= int(market["remove_price"])
	deck.remove_at(deck_index)
	market["removed"] = true
	return true


func leave_room() -> void:
	status = "map"


## Unused events for this region come first, then unused global events, then a fresh cycle.
func _pick_event() -> String:
	var here: String = region_def()["id"]
	var allowed := EventDB.EVENTS.keys().filter(func(id): return EventDB.EVENTS[id].get("region", here) == here)
	var cands := allowed.filter(func(id): return EventDB.EVENTS[id].has("region") and not used_events.has(id))
	if cands.is_empty():
		cands = allowed.filter(func(id): return not used_events.has(id))
	if cands.is_empty():
		used_events.clear()
		cands = allowed
	var id: String = rng.pick(cands)
	used_events.append(id)
	return id


func event_option_enabled(event_id: String, idx: int) -> bool:
	var opt: Dictionary = EventDB.EVENTS[event_id]["options"][idx]
	for op in opt["ops"]:
		if op[0] == "gold" and int(op[1]) < 0 and gold < -int(op[1]):
			return false
		if op[0] == "hurt" and hp <= int(op[1]):
			return false
	return true


## Applies an event choice; returns a short summary for the UI.
func choose_event_option(event_id: String, idx: int) -> String:
	if not event_option_enabled(event_id, idx):
		return ""
	var opt: Dictionary = EventDB.EVENTS[event_id]["options"][idx]
	var notes: Array = []
	for op in opt["ops"]:
		match op[0]:
			"heal":
				var before := hp
				hp = mini(max_hp, hp + int(op[1]))
				notes.append("Healed %d." % (hp - before))
			"hurt":
				hp = maxi(1, hp - int(op[1]))
				notes.append("Lost %d HP." % int(op[1]))
			"max_hp":
				max_hp = maxi(10, max_hp + int(op[1]))
				hp = mini(hp, max_hp)
				notes.append("Max HP %+d." % int(op[1]))
			"gold":
				gold += int(op[1])
				notes.append("Gold %+d." % int(op[1]))
			"card":
				var cid := CardDB.for_walker(op[1], walker)
				deck.append({"id": cid, "up": false})
				notes.append("Gained %s." % CardDB.CARDS[cid]["name"])
			"upgrade_random":
				var idxs := []
				for i in deck.size():
					if not deck[i]["up"]:
						idxs.append(i)
				rng.shuffle(idxs)
				for i in mini(int(op[1]), idxs.size()):
					deck[idxs[i]]["up"] = true
					notes.append("Upgraded %s." % CardDB.CARDS[deck[idxs[i]]["id"]]["name"])
			"remove_random_starter":
				for i in deck.size():
					if deck[i]["id"] in STARTER_BASICS:
						notes.append("Removed %s." % CardDB.CARDS[deck[i]["id"]]["name"])
						deck.remove_at(i)
						break
			"charm":
				var c := roll_charm()
				if c != "":
					add_charm(c)
					notes.append("Found %s." % CharmDB.CHARMS[c]["name"])
	status = "map"
	return " ".join(notes) if not notes.is_empty() else "You move on."


# ------------------------------------------------------------------ save / load

func to_dict() -> Dictionary:
	return {
		"version": 1, "seed": seed_value, "rng": rng.get_state(), "walker": walker, "hp": hp,
		"max_hp": max_hp, "gold": gold, "deck": deck, "charms": charms, "region": region, "map": map,
		"node_id": node_id, "floor": floor_num, "used_encounters": used_encounters,
		"used_events": used_events, "reward": reward, "market": market, "withering": withering, "status": status,
		"current_event": current_event, "current_encounter": current_encounter, "stats": stats,
	}


func from_dict(d: Dictionary) -> void:
	seed_value = int(d["seed"])
	rng = Rng.new(seed_value)
	rng.set_state(d["rng"])
	walker = d["walker"]
	withering = Withering.clamp_tier(int(d.get("withering", 0)))
	hp = int(d["hp"])
	max_hp = int(d["max_hp"])
	gold = int(d["gold"])
	deck = []
	for c in d["deck"]:
		deck.append({"id": c["id"], "up": bool(c["up"])})
	charms = d["charms"].duplicate()
	region = int(d["region"])
	map = []
	for n in d["map"]:
		var links := []
		for l in n["links"]:
			links.append(int(l))
		map.append({"id": int(n["id"]), "row": int(n["row"]), "col": int(n["col"]),
			"width": int(n["width"]), "type": n["type"], "links": links})
		if n.has("visited"):
			map[-1]["visited"] = n["visited"]
	node_id = int(d["node_id"])
	floor_num = int(d["floor"])
	used_encounters = d["used_encounters"].duplicate()
	used_events = d["used_events"].duplicate()
	reward = d.get("reward", {})
	market = d.get("market", {})
	status = d.get("status", "map")
	current_event = d.get("current_event", "")
	current_encounter = d.get("current_encounter", "")
	var st: Dictionary = d.get("stats", {})
	for k in stats:
		stats[k] = int(st.get(k, 0))
	# A combat in progress restarts from the node when resumed.
	if status == "combat":
		pass


func to_json() -> String:
	return JSON.stringify(to_dict())


static func from_json(text: String) -> RunState:
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY or not _valid_save(parsed):
		return null
	var r := RunState.new()
	r.from_dict(parsed)
	return r


static func _number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) == floor(float(value))


## Reject damaged schemas before any required-key indexing or scene routing.
static func _valid_save(d: Dictionary) -> bool:
	if d.get("version", 1) != 1:
		return false
	if not _number(d.get("withering", 0)) or d.get("withering", 0) < 0 or d.get("withering", 0) > Withering.MAX_TIER:
		return false
	for key in ["seed", "hp", "max_hp", "gold", "region", "node_id", "floor"]:
		if not _number(d.get(key)):
			return false
	if d["max_hp"] < 1 or d["hp"] < 0 or d["hp"] > d["max_hp"] or d["gold"] < 0 or d["region"] < 0 or d["region"] >= EncounterDB.REGIONS.size():
		return false
	if not WalkerDB.ORDER.has(d.get("walker")):
		return false
	if typeof(d.get("rng")) != TYPE_DICTIONARY:
		return false
	for key in ["seed", "state"]:
		if typeof(d["rng"].get(key)) != TYPE_STRING or not d["rng"][key].is_valid_int():
			return false
	for key in ["deck", "charms", "map", "used_encounters", "used_events"]:
		if typeof(d.get(key)) != TYPE_ARRAY:
			return false
	if d["deck"].is_empty() or d["map"].is_empty():
		return false
	for card in d["deck"]:
		if typeof(card) != TYPE_DICTIONARY or not CardDB.CARDS.has(card.get("id")) or typeof(card.get("up")) != TYPE_BOOL:
			return false
	for charm in d["charms"]:
		if not CharmDB.CHARMS.has(charm):
			return false
	var ids := []
	for n in d["map"]:
		if typeof(n) != TYPE_DICTIONARY or typeof(n.get("links")) != TYPE_ARRAY:
			return false
		if n.has("visited") and typeof(n["visited"]) != TYPE_BOOL:
			return false
		for key in ["id", "row", "col", "width"]:
			if not _number(n.get(key)):
				return false
		if ids.has(n["id"]) or not ["fight", "elite", "boss", "camp", "shrine", "market"].has(n.get("type")):
			return false
		ids.append(n["id"])
	for n in d["map"]:
		for link in n["links"]:
			if not _number(link) or not ids.has(link):
				return false
	if d["node_id"] != -1 and not ids.has(d["node_id"]):
		return false
	var status: Variant = d.get("status", "map")
	if not ["map", "combat", "reward", "camp", "shrine", "market", "victory", "defeat"].has(status):
		return false
	var encounter: Variant = d.get("current_encounter", "")
	if typeof(encounter) != TYPE_STRING or (encounter != "" and not EncounterDB.ENCOUNTERS.has(encounter)):
		return false
	if status == "combat" and encounter == "" and d["node_id"] == -1:
		return false
	var event: Variant = d.get("current_event", "")
	if typeof(event) != TYPE_STRING or (event != "" and not EventDB.EVENTS.has(event)) or (status == "shrine" and event == ""):
		return false
	for key in ["reward", "market", "stats"]:
		if typeof(d.get(key, {})) != TYPE_DICTIONARY:
			return false
	for value in d.get("stats", {}).values():
		if not _number(value):
			return false
	var reward_data: Dictionary = d.get("reward", {})
	if not _number(reward_data.get("gold", 0)) or typeof(reward_data.get("cards", [])) != TYPE_ARRAY:
		return false
	for card in reward_data.get("cards", []):
		if not CardDB.CARDS.has(card):
			return false
	var charm: Variant = reward_data.get("charm", "")
	if typeof(charm) != TYPE_STRING or (charm != "" and not CharmDB.CHARMS.has(charm)):
		return false
	var market_data: Dictionary = d.get("market", {})
	if typeof(market_data.get("items", [])) != TYPE_ARRAY or not _number(market_data.get("remove_price", 75)) or typeof(market_data.get("removed", false)) != TYPE_BOOL:
		return false
	for item in market_data.get("items", []):
		if typeof(item) != TYPE_DICTIONARY or not _number(item.get("price")) or typeof(item.get("sold")) != TYPE_BOOL:
			return false
		if item.get("kind") == "card":
			if not CardDB.CARDS.has(item.get("id")):
				return false
		elif item.get("kind") == "charm":
			if not CharmDB.CHARMS.has(item.get("id")):
				return false
		else:
			return false
	return true
