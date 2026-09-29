class_name WalkerDB
extends RefCounted
## Playable Grovewalkers: starting stats, board model, and how each one is unlocked.
## `unlock` names a profile counter that must reach 1 (empty = always available).

const WALKERS := {
	"wren": {
		"name": "Wren", "title": "Grovewalker", "hp": 72, "model": "grovewalker",
		"light": Color(0.7, 1.0, 0.45), "ring": Color(0.55, 1.0, 0.4), "unlock": "",
		"blurb": "Grows the forest and fights from inside it. Every 3 hexes of Grove sharpen her cards.",
	},
	"cassia": {
		"name": "Cassia", "title": "Ashwalker", "hp": 64, "model": "cassia",
		"light": Color(1.0, 0.62, 0.3), "ring": Color(1.0, 0.6, 0.25), "unlock": "bosses",
		"blurb": "Kindle your Grove into Heat to strengthen cards this turn. Heat resets next turn.",
		"locked_text": "Defeat any region boss to unlock Cassia.",
	},
}

const ORDER := ["wren", "cassia"]


static func get_def(id: String) -> Dictionary:
	return WALKERS.get(id, WALKERS["wren"])


static func is_unlocked(id: String, profile: Dictionary) -> bool:
	var key: String = get_def(id).get("unlock", "")
	return key == "" or int(profile.get(key, 0)) >= 1
