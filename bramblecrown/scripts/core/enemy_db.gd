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
##   daze {n}                      the Grovewalker starts its next turn with n less energy (min 1)
##   shield_allies {n}             every other enemy gains n ward
##   heal_allies {n}               every enemy (itself included) heals n
##   collapse {count, radius}      cave-in: marked open hexes near the Grovewalker become stone
##                                 (locked at intent time; a Grovewalker still standing there takes
##                                 damage instead, and a cave-in never splits the walkable board)
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
		"name": "The Mire Mother", "hp": [124, 124], "move": 1, "keep_range": 1, "trample": true, "model": "mire_mother",
		"size": 2.0, "boss": true,
		"moves": [
			{"name": "Brood Tide", "actions": [{"t": "summon", "enemy": "blightling", "count": 1, "max": 3}, {"t": "spread", "count": 3, "radius": 2}]},
			{"name": "Drowning Grasp", "actions": [{"t": "attack", "dmg": 10, "range": 2}]},
			{"name": "Rot Swell", "stay": true, "actions": [{"t": "blight_self", "radius": 2, "count": 8}, {"t": "ward", "n": 14}]},
			{"name": "Mire Crush", "actions": [{"t": "attack", "dmg": 18, "range": 2}]},
			{"name": "Wake of Moths", "actions": [{"t": "summon", "enemy": "rotmoth", "count": 1, "max": 2}, {"t": "strength", "n": 2}]},
		],
		"pattern": [0, 1, 2],
		"phase2_at": 0.5,
		"pattern2": [4, 3, 0, 1],
	},
	# ---------------- Region 2: Sunken Cloister ----------------
	"drowned_novice": {
		"name": "Drowned Novice", "hp": [9, 12], "move": 2, "model": "drowned_novice", "size": 0.85,
		"death_blight": true,
		"moves": [
			{"name": "Clutch", "actions": [{"t": "attack", "dmg": 5, "range": 1}]},
			{"name": "Weep", "actions": [{"t": "attack", "dmg": 3, "range": 1}, {"t": "blight_self", "radius": 1, "count": 2}]},
		],
		"pattern": [0, 1],
	},
	"censer_wraith": {
		"name": "Censer Wraith", "hp": [15, 18], "move": 3, "keep_range": 2, "flying": true, "model": "censer_wraith",
		"size": 1.0,
		"moves": [
			{"name": "Incense", "actions": [{"t": "spread", "count": 3, "radius": 2}]},
			{"name": "Swing Censer", "actions": [{"t": "attack", "dmg": 6, "range": 2}]},
		],
		"pattern": [0, 1],
	},
	"bell_ghoul": {
		"name": "Bell Ghoul", "hp": [24, 28], "move": 2, "model": "bell_ghoul", "size": 1.05,
		"moves": [
			{"name": "Toll", "actions": [{"t": "daze", "n": 1}, {"t": "attack", "dmg": 4, "range": 1}]},
			{"name": "Maul", "actions": [{"t": "attack", "dmg": 10, "range": 1}]},
		],
		"pattern": [1, 0],
	},
	"moss_knight": {
		"name": "Moss Knight", "hp": [36, 40], "move": 1, "trample": true, "model": "moss_knight", "size": 1.2,
		"moves": [
			{"name": "Advance", "move_bonus": 1, "actions": [{"t": "attack", "dmg": 8, "range": 1}, {"t": "blight_self", "radius": 1, "count": 2}]},
			{"name": "Greatsword", "actions": [{"t": "attack", "dmg": 13, "range": 1}]},
			{"name": "Bulwark", "stay": true, "actions": [{"t": "ward", "n": 8}, {"t": "shield_allies", "n": 6}]},
		],
		"pattern": [0, 1, 2],
	},
	"choir_of_ash": {
		"name": "Choir of Ash", "hp": [72, 76], "move": 1, "keep_range": 3, "model": "choir_of_ash", "size": 1.3,
		"elite": true,
		"moves": [
			{"name": "Dirge", "actions": [{"t": "spread", "count": 5, "radius": 2}, {"t": "daze", "n": 1}]},
			{"name": "Crescendo", "actions": [{"t": "attack", "dmg": 13, "range": 3}]},
			{"name": "Hymn of Ash", "stay": true, "actions": [{"t": "heal_allies", "n": 8}, {"t": "ward", "n": 10}, {"t": "summon", "enemy": "drowned_novice", "count": 1, "max": 2}]},
		],
		"pattern": [0, 1, 2],
	},
	"drowned_abbess": {
		"name": "The Drowned Abbess", "hp": [150, 150], "move": 1, "keep_range": 2, "trample": true,
		"model": "drowned_abbess", "size": 1.15, "boss": true,
		"moves": [
			{"name": "Call the Faithful", "actions": [{"t": "summon", "enemy": "drowned_novice", "count": 2, "max": 3}, {"t": "ward", "n": 10}]},
			{"name": "Litany of Salt", "actions": [{"t": "attack", "dmg": 11, "range": 3}, {"t": "daze", "n": 1}]},
			{"name": "Flood the Nave", "actions": [{"t": "spread", "count": 6, "radius": 2}]},
			{"name": "Great Bell", "actions": [{"t": "attack", "dmg": 20, "range": 2}]},
			{"name": "Last Rites", "actions": [{"t": "summon", "enemy": "censer_wraith", "count": 1, "max": 1}, {"t": "heal_allies", "n": 12}]},
			{"name": "Undertow", "actions": [{"t": "spread", "count": 5, "radius": 2}, {"t": "strength", "n": 2}]},
		],
		"pattern": [2, 1, 0],
		"phase2_at": 0.5,
		"pattern2": [4, 3, 5, 1],
	},
	# ---------------- Region 3: Glasswood ----------------
	# Faceted bodies trade attacking turns for ward. Crack the ward or spend those
	# turns building a grove; none of these creatures suppresses player energy.
	"shardling": {
		"name": "Shardling", "hp": [16, 19], "move": 2, "model": "shardling", "size": 0.85,
		"moves": [
			{"name": "Close the Facets", "stay": true, "actions": [{"t": "ward", "n": 6}]},
			{"name": "Shard Bite", "actions": [{"t": "attack", "dmg": 7, "range": 1}]},
		],
		"pattern": [0, 1],
	},
	"prism_stag": {
		"name": "Prism Stag", "hp": [36, 40], "move": 1, "model": "prism_stag", "size": 1.1,
		# The charge closes distance, then two stationary turns reward repositioning.
		# It does not trample: a planted thicket still slows its approach.
		"moves": [
			{"name": "Prism Charge", "move_bonus": 2, "actions": [{"t": "attack", "dmg": 10, "range": 1}]},
			{"name": "Brace the Antlers", "stay": true, "actions": [{"t": "ward", "n": 8}]},
			{"name": "Antler Sweep", "stay": true, "actions": [{"t": "attack", "dmg": 14, "range": 1}]},
		],
		"pattern": [0, 1, 2],
	},
	"glass_mite": {
		"name": "Glass Mite", "hp": [13, 16], "move": 2, "keep_range": 2, "flying": true,
		"model": "glass_mite", "size": 0.75,
		"moves": [
			{"name": "Borrowed Facets", "stay": true, "actions": [{"t": "shield_allies", "n": 4}]},
			{"name": "Glass Needle", "actions": [{"t": "attack", "dmg": 5, "range": 2}]},
			{"name": "Scatter Splinters", "actions": [{"t": "spread", "count": 2, "radius": 1}]},
		],
		"pattern": [0, 1, 2],
	},
	"lantern_hart": {
		"name": "Lantern Hart", "hp": [78, 82], "move": 2, "keep_range": 2,
		"model": "lantern_hart", "size": 1.2, "elite": true,
		"moves": [
			{"name": "Light the Herd", "stay": true, "actions": [{"t": "ward", "n": 6}, {"t": "shield_allies", "n": 6}]},
			{"name": "Lantern Lance", "actions": [{"t": "attack", "dmg": 14, "range": 2}]},
			{"name": "Dimming Paths", "stay": true, "actions": [{"t": "spread", "count": 4, "radius": 2}]},
		],
		"pattern": [0, 1, 2],
	},
	"splintered_queen": {
		"name": "The Splintered Queen", "hp": [174, 174], "move": 1, "keep_range": 2,
		"model": "splintered_queen", "size": 1.15, "boss": true,
		# Keep defensive turns separate from summons: capped summons skip the entire
		# move, so combining them would erase the player's reliable recovery window.
		"moves": [
			{"name": "Court of Mirrors", "stay": true, "actions": [{"t": "ward", "n": 8}, {"t": "shield_allies", "n": 5}]},
			{"name": "Royal Refraction", "actions": [{"t": "attack", "dmg": 12, "range": 3}]},
			{"name": "Gather the Shards", "stay": true, "actions": [{"t": "summon", "enemy": "shardling", "count": 1, "max": 2}]},
			{"name": "Fracture the Grove", "stay": true, "actions": [{"t": "spread", "count": 4, "radius": 2}]},
			{"name": "Reforge the Crown", "stay": true, "actions": [{"t": "ward", "n": 6}, {"t": "strength", "n": 1}]},
			{"name": "Crownfall", "stay": true, "actions": [{"t": "attack", "dmg": 20, "range": 2}]},
			{"name": "Splinterstorm", "actions": [{"t": "attack", "dmg": 9, "range": 3}, {"t": "spread", "count": 3, "radius": 2}]},
			{"name": "Wake the Mirrorwing", "stay": true, "actions": [{"t": "summon", "enemy": "glass_mite", "count": 1, "max": 1}]},
		],
		"pattern": [0, 1, 2, 3],
		"phase2_at": 0.5,
		"pattern2": [4, 5, 7, 6],
	},
	# Ironroot Deeps: cave-ins reshape the board every few turns. Each creature asks a
	# different spatial question: stand off the marked hexes, keep thicket between you and
	# the carts, and reach the Tunnelers before the room closes in.
	"rustgrub": {
		"name": "Rustgrub", "hp": [15, 18], "move": 2, "model": "rustgrub", "size": 0.8,
		"death_blight": true,
		"moves": [
			{"name": "Gnaw", "actions": [{"t": "attack", "dmg": 7, "range": 1}]},
			{"name": "Rust Trail", "actions": [{"t": "blight_self", "count": 2, "radius": 1}]},
		],
		"pattern": [0, 0, 1],
	},
	"cart_golem": {
		"name": "Cart Golem", "hp": [42, 46], "move": 1, "model": "cart_golem", "size": 1.1,
		"trample": true,
		# A runaway charge crushes thicket; a stoke turn afterwards is the window to punish it.
		"moves": [
			{"name": "Runaway Cart", "move_bonus": 2, "actions": [{"t": "attack", "dmg": 11, "range": 1}]},
			{"name": "Stoke the Firebox", "stay": true, "actions": [{"t": "ward", "n": 7}, {"t": "strength", "n": 1}]},
			{"name": "Iron Ram", "actions": [{"t": "attack", "dmg": 8, "range": 1}]},
		],
		"pattern": [0, 1, 2],
	},
	"tunneler": {
		"name": "Tunneler", "hp": [20, 23], "move": 2, "keep_range": 2, "model": "tunneler", "size": 0.9,
		"moves": [
			{"name": "Undermine", "stay": true, "actions": [{"t": "collapse", "count": 2, "radius": 1}]},
			{"name": "Pick Throw", "actions": [{"t": "attack", "dmg": 6, "range": 2}]},
			{"name": "Shore Up", "actions": [{"t": "ward", "n": 5}]},
		],
		"pattern": [0, 1, 2],
	},
	"foundry_heart": {
		"name": "Foundry Heart", "hp": [86, 90], "move": 0, "keep_range": 3,
		"model": "foundry_heart", "size": 1.2, "elite": true,
		# Rooted in place: the fight is about crossing its cave-ins while the carts escort it.
		"moves": [
			{"name": "Bellows", "stay": true, "actions": [{"t": "ward", "n": 8}, {"t": "shield_allies", "n": 5}]},
			{"name": "Molten Arc", "stay": true, "actions": [{"t": "attack", "dmg": 13, "range": 3}]},
			{"name": "Ceiling Drop", "stay": true, "actions": [{"t": "collapse", "count": 3, "radius": 2}]},
			{"name": "Slag Pour", "stay": true, "actions": [{"t": "spread", "count": 3, "radius": 2}]},
		],
		"pattern": [0, 1, 2, 3],
	},
	"engine_of_rot": {
		"name": "The Engine of Rot", "hp": [196, 196], "move": 1, "keep_range": 2,
		"model": "engine_of_rot", "size": 1.15, "boss": true, "trample": true,
		# Phase 1 builds the mine around you; phase 2 drives straight through it.
		"moves": [
			{"name": "Piston Slam", "actions": [{"t": "attack", "dmg": 13, "range": 2}]},
			{"name": "Shaft Collapse", "stay": true, "actions": [{"t": "collapse", "count": 3, "radius": 2}]},
			{"name": "Feed the Furnace", "stay": true, "actions": [{"t": "summon", "enemy": "rustgrub", "count": 2, "max": 2}]},
			{"name": "Boiler Plating", "stay": true, "actions": [{"t": "ward", "n": 12}]},
			{"name": "Full Steam", "move_bonus": 2, "actions": [{"t": "attack", "dmg": 16, "range": 1}]},
			{"name": "Rot Exhaust", "stay": true, "actions": [{"t": "spread", "count": 4, "radius": 2}, {"t": "strength", "n": 1}]},
			{"name": "Deep Collapse", "stay": true, "actions": [{"t": "collapse", "count": 4, "radius": 2}]},
			{"name": "Couple the Cart", "stay": true, "actions": [{"t": "summon", "enemy": "cart_golem", "count": 1, "max": 1}]},
		],
		"pattern": [0, 1, 3, 2],
		"phase2_at": 0.5,
		"pattern2": [4, 6, 5, 7],
	},
}


static func get_def(id: String) -> Dictionary:
	var d: Dictionary = ENEMIES[id].duplicate(true)
	d["id"] = id
	return d
