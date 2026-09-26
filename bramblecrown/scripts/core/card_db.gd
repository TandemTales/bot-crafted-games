class_name CardDB
extends RefCounted
## Card definitions. `up` holds overrides applied to upgraded copies.
## target: "self" (no target), "enemy" (enemy within range), "hex" (any board hex within range).
## Text placeholders {a}, {b}, ... are filled from `vals` (or `up.vals`).

const CARDS := {
	# Sunken Cloister: unlocked in reward and market pools from region 2 onward.
	"bellbreaker": {
		"name": "Bellbreaker", "cost": 1, "type": "attack", "target": "enemy", "range": 2,
		"rarity": "common", "owner": "wren", "art": "strike", "min_region": 1,
		"text": "Remove all enemy Ward. Deal {a} damage.", "vals": {"a":5},
		"effects": [{"op":"break_ward"},{"op":"damage","amount":"a"}],
		"up": {"vals":{"a":8}},
	},
	"vow_shield": {
		"name": "Vow Shield", "cost": 1, "type": "skill", "target": "self", "range": 0,
		"rarity": "common", "owner": "wren", "art": "ward", "min_region": 1,
		"text": "Gain {a} Ward and Clarity until your next turn.", "vals": {"a":6},
		"effects": [{"op":"ward","amount":"a"},{"op":"clarity"}],
		"up": {"vals":{"a":9}},
	},
	"dry_wick": {
		"name": "Dry Wick", "cost": 0, "type": "skill", "target": "self", "range": 0,
		"rarity": "uncommon", "owner": "wren", "art": "cleanse", "min_region": 1, "exhaust": true,
		"text": "Recover Energy lost to Daze this turn. Draw {a}. Exhaust.", "vals": {"a":1},
		"effects": [{"op":"recover_daze"},{"op":"draw","n":"a"}],
		"up": {"vals":{"a":2}},
	},
	"last_lantern": {
		"name": "Last Lantern", "cost": 1, "type": "skill", "target": "self", "range": 0,
		"rarity": "uncommon", "owner": "wren", "art": "ward", "min_region": 1,
		"text": "Gain {a} Ward. Carry up to {b} unused Ward into your next turn.", "vals": {"a":5,"b":4},
		"effects": [{"op":"ward","amount":"a"},{"op":"reserve_ward","n":"b"}],
		"up": {"vals":{"a":8,"b":6}},
	},
	"censer_cut": {
		"name": "Censer Cut", "cost": 1, "type": "attack", "target": "enemy", "range": 3,
		"rarity": "common", "owner": "wren", "art": "lash", "min_region": 1,
		"text": "Deal {a} damage. Apply {b} Weak.", "vals": {"a":4,"b":1},
		"effects": [{"op":"damage","amount":"a"},{"op":"apply","status":"weak","n":"b"}],
		"up": {"vals":{"a":6,"b":2}},
	},
	"stillwater_step": {
		"name": "Stillwater Step", "cost": 0, "type": "skill", "target": "self", "range": 0,
		"rarity": "common", "owner": "wren", "art": "move", "min_region": 1,
		"text": "Gain {a} Movement and {b} Ward.", "vals": {"a":2,"b":2},
		"effects": [{"op":"move","n":"a"},{"op":"ward","amount":"b"}],
		"up": {"vals":{"a":3,"b":4}},
	},
	"bellroot": {
		"name": "Bellroot", "cost": 1, "type": "skill", "target": "hex", "range": 3,
		"rarity": "common", "owner": "wren", "art": "root", "min_region": 1,
		"text": "Grow {a} Thicket near the target. Root any enemy on the target hex.", "vals": {"a":2},
		"effects": [{"op":"grow","count":"a"},{"op":"apply","status":"rooted","n":1}],
		"up": {"vals":{"a":4}},
	},
	"choir_thorns": {
		"name": "Choir of Thorns", "cost": 2, "type": "attack", "target": "self", "range": 0,
		"rarity": "uncommon", "owner": "wren", "art": "lash", "min_region": 1,
		"text": "Deal {a} damage to foes touching your Grove. Gain {b} Ward.", "vals": {"a":6,"b":4},
		"effects": [{"op":"damage_grove_area","amount":"a"},{"op":"ward","amount":"b"}],
		"up": {"vals":{"a":9,"b":6}},
	},
	"borrowed_vow": {
		"name": "Borrowed Vow", "cost": 1, "type": "skill", "target": "enemy", "range": 2,
		"rarity": "uncommon", "owner": "wren", "art": "ward", "min_region": 1,
		"text": "Steal up to {a} enemy Ward. Apply 1 Weak.", "vals": {"a":8},
		"effects": [{"op":"steal_ward","n":"a"},{"op":"apply","status":"weak","n":1}],
		"up": {"vals":{"a":12}},
	},
	"candle_lance": {
		"name": "Candle Lance", "cost": 1, "type": "attack", "target": "enemy", "range": 3,
		"rarity": "rare", "owner": "wren", "art": "fire", "min_region": 1,
		"text": "Spend all Ward. Deal {a} damage plus Ward spent (max {b}).", "vals": {"a":4,"b":12},
		"effects": [{"op":"ward_strike","amount":"a","cap":"b"}],
		"up": {"vals":{"a":6,"b":18}},
	},
	# ---------------- Wren starter ----------------
	"thornstrike": {
		"name": "Thornstrike", "cost": 1, "type": "attack", "target": "enemy", "range": 1,
		"rarity": "starter", "owner": "wren", "art": "strike",
		"text": "Deal {a} damage.", "vals": {"a": 6},
		"effects": [{"op": "damage", "amount": "a"}],
		"up": {"vals": {"a": 9}},
	},
	"barkskin": {
		"name": "Barkskin", "cost": 1, "type": "skill", "target": "self", "range": 0,
		"rarity": "starter", "owner": "wren", "art": "ward",
		"text": "Gain {a} Ward.", "vals": {"a": 5},
		"effects": [{"op": "ward", "amount": "a"}],
		"up": {"vals": {"a": 8}},
	},
	"sow": {
		"name": "Sow", "cost": 1, "type": "skill", "target": "hex", "range": 2,
		"rarity": "starter", "owner": "wren", "art": "grow",
		"text": "Grow Thicket on {a} hexes around the target.", "vals": {"a": 3},
		"effects": [{"op": "grow", "count": "a"}],
		"up": {"vals": {"a": 5}},
	},
	"taproot": {
		"name": "Taproot", "cost": 0, "type": "skill", "target": "self", "range": 0,
		"rarity": "starter", "owner": "wren", "art": "grow",
		"text": "Grow Thicket beneath you and {a} adjacent hex. Draw 1.", "vals": {"a": 1},
		"effects": [{"op": "grow_self", "count": "a"}, {"op": "draw", "n": 1}],
		"up": {"vals": {"a": 3}},
	},
	# ---------------- Wren rewards ----------------
	"bramble_lash": {
		"name": "Bramble Lash", "cost": 1, "type": "attack", "target": "enemy", "range": 2,
		"rarity": "common", "owner": "wren", "art": "lash",
		"text": "Deal {a} damage. If the target stands in Thicket, apply {b} Bleed.",
		"vals": {"a": 4, "b": 3},
		"effects": [{"op": "damage", "amount": "a"}, {"op": "apply", "status": "bleed", "n": "b", "if_on": "thicket"}],
		"up": {"vals": {"a": 6, "b": 4}},
	},
	"heartwood_maul": {
		"name": "Heartwood Maul", "cost": 2, "type": "attack", "target": "enemy", "range": 1,
		"rarity": "common", "owner": "wren", "art": "strike",
		"text": "Deal {a} damage, plus 1 per hex in your Grove.", "vals": {"a": 8},
		"effects": [{"op": "damage", "amount": "a", "grove_mult": 1}],
		"up": {"vals": {"a": 11}},
	},
	"briar_wall": {
		"name": "Briar Wall", "cost": 1, "type": "skill", "target": "hex", "range": 4,
		"rarity": "common", "owner": "wren", "art": "grow",
		"text": "Grow a line of {a} Thicket from you toward the target. Gain {b} Ward.",
		"vals": {"a": 4, "b": 2},
		"effects": [{"op": "grow_line", "length": "a"}, {"op": "ward", "amount": "b"}],
		"up": {"vals": {"a": 5, "b": 5}},
	},
	"wildfire": {
		"name": "Wildfire", "cost": 2, "type": "attack", "target": "self", "range": 0,
		"rarity": "uncommon", "owner": "wren", "art": "fire",
		"text": "Burn your Grove. Each enemy touching a burned hex takes {a} damage per hex burned (max 10).",
		"vals": {"a": 2},
		"effects": [{"op": "burn_grove", "per_hex": "a", "cap": 10}],
		"up": {"vals": {"a": 3}},
	},
	"cleanse": {
		"name": "Cleanse", "cost": 1, "type": "skill", "target": "self", "range": 0,
		"rarity": "common", "owner": "wren", "art": "cleanse",
		"text": "Clear all Blight within {a} of you. Draw 1.", "vals": {"a": 2},
		"effects": [{"op": "cleanse", "radius": "a"}, {"op": "draw", "n": 1}],
		"up": {"vals": {"a": 3}},
	},
	"rootsnare": {
		"name": "Rootsnare", "cost": 1, "type": "skill", "target": "enemy", "range": 3,
		"rarity": "common", "owner": "wren", "art": "root",
		"text": "Deal {a} damage. Root the target (it cannot move this enemy turn).",
		"vals": {"a": 3},
		"effects": [{"op": "damage", "amount": "a"}, {"op": "apply", "status": "rooted", "n": 1}],
		"up": {"vals": {"a": 7}},
	},
	"overgrowth": {
		"name": "Overgrowth", "cost": 2, "type": "power", "target": "self", "range": 0,
		"rarity": "uncommon", "owner": "wren", "art": "grow",
		"text": "At the start of each turn, grow {a} Thicket at the edge of your Grove.",
		"vals": {"a": 2},
		"effects": [{"op": "power", "id": "overgrowth", "n": "a"}],
		"up": {"cost": 1},
	},
	"sap_draught": {
		"name": "Sap Draught", "cost": 0, "type": "skill", "target": "self", "range": 0,
		"rarity": "uncommon", "owner": "wren", "art": "sap", "exhaust": true,
		"text": "Gain {a} Energy. Draw 1. Exhaust.", "vals": {"a": 1},
		"effects": [{"op": "energy", "n": "a"}, {"op": "draw", "n": 1}],
		"up": {"vals": {"a": 2}},
	},
	"stride": {
		"name": "Stride", "cost": 0, "type": "skill", "target": "self", "range": 0,
		"rarity": "common", "owner": "wren", "art": "move",
		"text": "Gain {a} Movement.", "vals": {"a": 3},
		"effects": [{"op": "move", "n": "a"}],
		"up": {"vals": {"a": 4}, "text": "Gain {a} Movement. Draw 1.",
			"effects": [{"op": "move", "n": "a"}, {"op": "draw", "n": 1}]},
	},
	"thorn_mantle": {
		"name": "Thorn Mantle", "cost": 1, "type": "power", "target": "self", "range": 0,
		"rarity": "uncommon", "owner": "wren", "art": "ward",
		"text": "Whenever an enemy attacks you, it takes {a} damage.", "vals": {"a": 3},
		"effects": [{"op": "power", "id": "thorns", "n": "a"}],
		"up": {"vals": {"a": 5}},
	},
	"pollen_cloud": {
		"name": "Pollen Cloud", "cost": 1, "type": "skill", "target": "hex", "range": 3,
		"rarity": "common", "owner": "wren", "art": "pollen",
		"text": "Enemies within {a} of the target become Weak for 2 turns (deal 25% less damage).",
		"vals": {"a": 1},
		"effects": [{"op": "weak_area", "radius": "a", "n": 2}],
		"up": {"vals": {"a": 2}},
	},
	"deep_roots": {
		"name": "Deep Roots", "cost": 1, "type": "skill", "target": "self", "range": 0,
		"rarity": "common", "owner": "wren", "art": "ward",
		"text": "Gain {a} Ward, plus 1 per hex in your Grove.", "vals": {"a": 3},
		"effects": [{"op": "ward", "amount": "a", "grove_mult": 1}],
		"up": {"vals": {"a": 6}},
	},
	"verdant_surge": {
		"name": "Verdant Surge", "cost": 1, "type": "skill", "target": "hex", "range": 3,
		"rarity": "uncommon", "owner": "wren", "art": "grow", "exhaust": true,
		"text": "Grow Thicket on {a} hexes around the target. Exhaust.", "vals": {"a": 7},
		"effects": [{"op": "grow", "count": "a"}],
		"up": {"vals": {"a": 10}},
	},
	"graft": {
		"name": "Graft", "cost": 1, "type": "skill", "target": "self", "range": 0,
		"rarity": "common", "owner": "wren", "art": "sap",
		"text": "Draw {a}. If your Grove has 5+ hexes, gain 1 Energy.", "vals": {"a": 2},
		"effects": [{"op": "draw", "n": "a"}, {"op": "energy_if_grove", "min": 5, "n": 1}],
		"up": {"vals": {"a": 3}},
	},
	"thornvolley": {
		"name": "Thornvolley", "cost": 1, "type": "attack", "target": "self", "range": 0,
		"rarity": "common", "owner": "wren", "art": "lash",
		"text": "Deal {a} damage to every enemy in or touching your Grove.", "vals": {"a": 4},
		"effects": [{"op": "damage_grove_area", "amount": "a"}],
		"up": {"vals": {"a": 6}},
	},
	"hollow_oak": {
		"name": "Hollow Oak", "cost": 2, "type": "skill", "target": "self", "range": 0,
		"rarity": "uncommon", "owner": "wren", "art": "ward",
		"text": "Gain {a} Ward. Grow Thicket on every hex around you.", "vals": {"a": 10},
		"effects": [{"op": "ward", "amount": "a"}, {"op": "grow_self", "count": 6}],
		"up": {"vals": {"a": 14}},
	},
	"reclaim": {
		"name": "Reclaim", "cost": 1, "type": "skill", "target": "hex", "range": 3,
		"rarity": "uncommon", "owner": "wren", "art": "cleanse",
		"text": "Turn up to {a} Blight hexes near the target into Thicket.", "vals": {"a": 3},
		"effects": [{"op": "reclaim", "count": "a"}],
		"up": {"vals": {"a": 5}},
	},
	"crowns_wrath": {
		"name": "Crown's Wrath", "cost": 2, "type": "attack", "target": "enemy", "range": 1,
		"rarity": "rare", "owner": "wren", "art": "fire", "exhaust": true,
		"text": "Deal {a} damage per hex in your Grove. Exhaust.", "vals": {"a": 2},
		"effects": [{"op": "damage", "amount": 0, "grove_mult": "a"}],
		"up": {"vals": {"a": 3}},
	},
	"seed_of_ages": {
		"name": "Seed of Ages", "cost": 3, "type": "power", "target": "self", "range": 0,
		"rarity": "rare", "owner": "wren", "art": "grow",
		"text": "At the start of each turn, gain Ward equal to your Grove size.",
		"vals": {},
		"effects": [{"op": "power", "id": "seed_of_ages", "n": 1}],
		"up": {"cost": 2},
	},
	"spinebreaker": {
		"name": "Spinebreaker", "cost": 1, "type": "attack", "target": "enemy", "range": 1,
		"rarity": "uncommon", "owner": "wren", "art": "strike",
		"text": "Deal {a} damage. Deals double damage to a Rooted enemy.", "vals": {"a": 7},
		"effects": [{"op": "damage", "amount": "a", "double_if": "rooted"}],
		"up": {"vals": {"a": 10}},
	},
}

const STARTER_DECK := {
	"wren": ["thornstrike", "thornstrike", "thornstrike", "thornstrike",
		"barkskin", "barkskin", "barkskin", "barkskin", "sow", "sow", "taproot"],
}


static func has(id: String) -> bool:
	return CARDS.has(id)


## Resolved definition for a card id, with upgrade overrides merged.
static func get_def(id: String, upgraded: bool = false) -> Dictionary:
	var base: Dictionary = CARDS[id].duplicate(true)
	base["id"] = id
	base["upgraded"] = upgraded
	if upgraded and base.has("up"):
		var up: Dictionary = base["up"]
		for k in up:
			if k == "vals":
				var v: Dictionary = base["vals"].duplicate()
				v.merge(up["vals"], true)
				base["vals"] = v
			else:
				base[k] = up[k]
		base["name"] = base["name"] + "+"
	base.erase("up")
	return base


static func val(def: Dictionary, v) -> int:
	if v is String:
		return int(def["vals"].get(v, 0))
	return int(v)


static func describe(def: Dictionary) -> String:
	var t: String = def["text"]
	for k in def["vals"]:
		t = t.replace("{%s}" % k, str(def["vals"][k]))
	return t


static func reward_pool(owner: String, region: int = 0) -> Array:
	var out := []
	for id in CARDS:
		var c: Dictionary = CARDS[id]
		if c["rarity"] != "starter" and int(c.get("min_region", 0)) <= region and (c["owner"] == owner or c["owner"] == "neutral"):
			out.append(id)
	return out
