class_name EnemyDB
extends RefCounted
## Enemy definitions. Each enemy cycles through `pattern` (indices into `moves`).
## A move approaches the player first (unless `stay`), then runs its actions in order.
## Action types:
##   attack  {dmg, range}          hits the Grovewalker if within range after moving
##   spread  {count, radius}       blights hexes near the Grovewalker (targets locked when the intent is chosen)
##   blight_self {radius}          blights hexes around itself (locked at intent time)
##   summon  {enemy, count, max}   adds enemies on free hexes near itself
##   ward    {n}                   gains ward
##   strength {n}                  permanently gains strength
## Flags: move (hexes per turn), keep_range (preferred distance), flying (ignores Thicket cost),
## trample (destroys Thicket it walks through), death_blight (blights its hex on death), size (visual scale).

const ENEMIES := {
	"blightling": {
		"name": "Blightling", "hp": [11, 14], "move": 2, "model": "blightling", "size": 0.8,
		"death_blight": true,
		"moves": [
			{"name": "Gnash", "actions": [{"t": "attack", "dmg": 5, "range": 1}]},
			{"name": "Seep", "actions": [{"t": "attack", "dmg": 3, "range": 1}, {"t": "blight_self", "radius": 1, "count": 2}]},
		],
		"pattern": [0, 1],
	},
	"rotmoth": {
		"name": "Rotmoth", "hp": [9, 11], "move": 3, "keep_range": 2, "flying": true, "model": "rotmoth", "size": 0.9,
		"moves": [
			{"name": "Spore Spit", "actions": [{"t": "attack", "dmg": 4, "range": 3}]},
			{"name": "Dust Wings", "actions": [{"t": "spread", "count": 3, "radius": 2}]},
		],
		"pattern": [1, 0],
	},
	"husk_brute": {
		"name": "Husk Brute", "hp": [30, 34], "move": 1, "trample": true, "model": "husk_brute", "size": 1.25,
		"moves": [
			{"name": "Slam", "actions": [{"t": "attack", "dmg": 11, "range": 1}]},
			{"name": "Hunker", "stay": true, "actions": [{"t": "ward", "n": 8}, {"t": "blight_self", "radius": 1, "count": 3}]},
			{"name": "Lumber", "move_bonus": 2, "actions": [{"t": "attack", "dmg": 7, "range": 1}]},
		],
		"pattern": [2, 0, 1],
	},
	"sporecaller": {
		"name": "Sporecaller", "hp": [20, 24], "move": 1, "keep_range": 3, "model": "sporecaller", "size": 1.0,
		"moves": [
			{"name": "Call the Brood", "actions": [{"t": "summon", "enemy": "blightling", "count": 1, "max": 4}]},
			{"name": "Rot Bloom", "actions": [{"t": "spread", "count": 4, "radius": 2}]},
			{"name": "Spore Lance", "actions": [{"t": "attack", "dmg": 6, "range": 3}]},
		],
		"pattern": [1, 0, 2],
	},
	"bog_warden": {
		"name": "Bog Warden", "hp": [58, 62], "move": 2, "trample": true, "model": "bog_warden", "size": 1.45,
		"elite": true,
		"moves": [
			{"name": "Peat Cleaver", "actions": [{"t": "attack", "dmg": 12, "range": 1}]},
			{"name": "Sink the Ground", "stay": true, "actions": [{"t": "ward", "n": 10}, {"t": "blight_self", "radius": 2, "count": 6}]},
			{"name": "Wade", "move_bonus": 2, "actions": [{"t": "attack", "dmg": 8, "range": 1}, {"t": "strength", "n": 2}]},
		],
		"pattern": [2, 0, 1],
	},
	"mire_mother": {
		"name": "The Mire Mother", "hp": [140, 140], "move": 1, "keep_range": 2, "trample": true, "model": "mire_mother",
		"size": 2.0, "boss": true,
		"moves": [
			{"name": "Brood Tide", "actions": [{"t": "summon", "enemy": "blightling", "count": 2, "max": 4}, {"t": "spread", "count": 3, "radius": 2}]},
			{"name": "Drowning Grasp", "actions": [{"t": "attack", "dmg": 10, "range": 2}]},
			{"name": "Rot Swell", "stay": true, "actions": [{"t": "blight_self", "radius": 2, "count": 8}, {"t": "ward", "n": 14}]},
			{"name": "Mire Crush", "actions": [{"t": "attack", "dmg": 18, "range": 2}]},
			{"name": "Wake of Moths", "actions": [{"t": "summon", "enemy": "rotmoth", "count": 2, "max": 5}, {"t": "strength", "n": 2}]},
		],
		"pattern": [0, 1, 2],
		"phase2_at": 0.5,
		"pattern2": [4, 3, 0, 1],
	},
}


static func get_def(id: String) -> Dictionary:
	var d: Dictionary = ENEMIES[id].duplicate(true)
	d["id"] = id
	return d
