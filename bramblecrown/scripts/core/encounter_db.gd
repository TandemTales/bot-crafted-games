class_name EncounterDB
extends RefCounted
## Authored encounter layouts. Coordinates are axial (q, r) on a disc of `radius`.
## player: start hex; enemies: [[id, q, r]]; water/stone: impassable terrain;
## blight/thicket: starting growth.

const REGIONS := [
	{
		"id": "ashfen", "name": "Ashfen Marsh",
		"blurb": "Peat and black water, where the Blight first rose.",
		"fights": ["ash_scouts", "ash_moths", "ash_brute", "ash_caller", "ash_pair", "ash_nest"],
		"elites": ["ash_warden"],
		"boss": "ash_mother",
	},
]

const ENCOUNTERS := {
	"ash_scouts": {
		"name": "Scouts in the Reeds", "radius": 3, "player": [0, 2],
		"enemies": [["blightling", -1, -2], ["blightling", 2, -2]],
		"water": [[-3, 1], [-3, 2], [3, -1]], "stone": [[1, 1]],
		"blight": [[-1, -2], [0, -2], [2, -2], [2, -3]], "thicket": [[0, 2]],
	},
	"ash_moths": {
		"name": "Moth-Light", "radius": 3, "player": [-1, 2],
		"enemies": [["rotmoth", 1, -3], ["rotmoth", 3, -2], ["blightling", 0, -1]],
		"water": [[-3, 0], [-2, 0], [2, 1]], "stone": [],
		"blight": [[1, -3], [2, -3], [3, -2], [0, -1], [1, -1]], "thicket": [[-1, 2], [-2, 3]],
	},
	"ash_brute": {
		"name": "The Husk in the Peat", "radius": 3, "player": [0, 3],
		"enemies": [["husk_brute", 0, -2]],
		"water": [[-3, 3], [3, 0], [3, -1]], "stone": [[-2, 0], [2, -1]],
		"blight": [[0, -2], [-1, -2], [1, -3], [0, -3], [1, -2]], "thicket": [],
	},
	"ash_caller": {
		"name": "The Sporecaller's Ring", "radius": 3, "player": [0, 2],
		"enemies": [["sporecaller", 0, -3], ["blightling", -2, -1], ["blightling", 2, -2]],
		"water": [[-3, 2], [3, -3]], "stone": [[-1, 0], [1, -1]],
		"blight": [[0, -3], [-1, -2], [1, -3], [-2, -1], [2, -2]], "thicket": [[0, 2], [1, 1]],
	},
	"ash_pair": {
		"name": "Brute and Moth", "radius": 3, "player": [-2, 3],
		"enemies": [["husk_brute", 1, -2], ["rotmoth", 3, -3]],
		"water": [[0, 0], [1, 0], [-3, 1]], "stone": [[2, 1]],
		"blight": [[1, -2], [2, -3], [3, -3], [2, -2]], "thicket": [[-2, 3]],
	},
	"ash_nest": {
		"name": "The Nest", "radius": 3, "player": [0, 3],
		"enemies": [["blightling", -1, -1], ["blightling", 1, -2], ["blightling", 2, -1], ["rotmoth", -2, -1]],
		"water": [[3, 0], [-3, 3]], "stone": [],
		"blight": [[-1, -1], [1, -2], [2, -1], [0, -1], [0, -2], [-2, -1], [1, -1]], "thicket": [],
	},
	"ash_warden": {
		"name": "The Bog Warden", "radius": 3, "player": [0, 3], "elite": true,
		"enemies": [["bog_warden", 0, -2]],
		"water": [[-3, 0], [3, -3], [3, 0]], "stone": [[-1, 1], [1, 0]],
		"blight": [[0, -2], [-1, -2], [1, -3], [0, -3], [-1, -1], [1, -2]], "thicket": [[0, 3]],
	},
	"ash_mother": {
		"name": "The Mire Mother", "radius": 4, "player": [0, 4], "boss": true,
		"enemies": [["mire_mother", 0, -3]],
		"water": [[-4, 0], [-4, 1], [4, -4], [4, -3], [-2, 4], [3, 1]], "stone": [[-2, 1], [2, -1]],
		"blight": [[0, -3], [-1, -3], [1, -4], [0, -4], [-1, -2], [1, -3], [2, -4], [-2, -2]],
		"thicket": [[0, 4], [1, 3]],
	},
}


static func get_def(id: String) -> Dictionary:
	var d: Dictionary = ENCOUNTERS[id].duplicate(true)
	d["id"] = id
	return d
