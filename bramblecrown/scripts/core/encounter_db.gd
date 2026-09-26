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
		"easy": ["ash_scouts", "ash_moths", "ash_brute"],
		"theme": "marsh",
	},
	{
		"id": "cloister", "name": "Sunken Cloister",
		"blurb": "A drowned abbey whose bells still ring for the Blight.",
		"fights": ["clo_nave", "clo_bells", "clo_knight", "clo_vespers", "clo_aisle", "clo_procession"],
		"elites": ["clo_choir"],
		"boss": "clo_abbess",
		"easy": ["clo_nave", "clo_bells", "clo_aisle"],
		"theme": "cloister",
	},
	{
		"id": "glasswood", "name": "Glasswood",
		"blurb": "Crystal boughs and silver channels beneath a fractured crown.",
		"fights": ["gls_crossing", "gls_orchard", "gls_mirrors", "gls_splinters", "gls_runoff", "gls_court"],
		"elites": ["gls_hart"],
		"boss": "gls_queen",
		"easy": ["gls_crossing", "gls_orchard", "gls_mirrors"],
		"theme": "glasswood",
	},
	{
		"id": "ironroot", "name": "Ironroot Deeps",
		"blurb": "Abandoned mine galleries where rails rust and the ceilings give way.",
		"fights": ["iro_shaft", "iro_rails", "iro_undermine", "iro_gallery", "iro_sump", "iro_depot"],
		"elites": ["iro_foundry"],
		"boss": "iro_engine",
		"easy": ["iro_shaft", "iro_rails", "iro_sump"],
		"theme": "ironroot",
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
	# ---------------- Region 2: Sunken Cloister ----------------
	"clo_nave": {
		"name": "Incense in the Nave", "radius": 3, "player": [0, 3],
		"enemies": [["censer_wraith", -2, -1], ["censer_wraith", 2, -3]],
		"water": [[3, -1], [-3, 3]], "stone": [[-2, 1], [2, 0], [-1, -1], [1, -2]],
		"blight": [[-2, -1], [2, -3], [1, -3], [-1, -2]], "thicket": [[0, 3]],
	},
	"clo_bells": {
		"name": "The Bell-Ringer", "radius": 3, "player": [-1, 3],
		"enemies": [["bell_ghoul", 1, -2], ["drowned_novice", -2, -1], ["drowned_novice", 3, -3]],
		"water": [[-3, 0], [3, 0]], "stone": [[-1, 1], [1, 0], [0, -1]],
		"blight": [[1, -2], [0, -2], [-2, -1], [3, -3], [2, -3]], "thicket": [[-1, 3], [0, 2]],
	},
	"clo_knight": {
		"name": "Knight of the Moss", "radius": 3, "player": [0, 3],
		"enemies": [["moss_knight", 0, -2], ["drowned_novice", -2, -1], ["drowned_novice", 2, -3]],
		"water": [[-3, 1], [3, -2]], "stone": [[-1, 0], [1, 0]],
		"blight": [[0, -2], [-1, -2], [1, -3], [-2, -1], [2, -3], [0, -3]], "thicket": [],
	},
	"clo_vespers": {
		"name": "Vespers", "radius": 3, "player": [0, 2],
		"enemies": [["bell_ghoul", 0, -3], ["censer_wraith", -3, 0], ["drowned_novice", 2, -2]],
		"water": [[-2, 3], [3, -1]], "stone": [[-1, -1], [2, -1], [-2, 1]],
		"blight": [[0, -3], [1, -3], [-3, 0], [2, -2], [-1, -2]], "thicket": [[0, 2]],
	},
	"clo_aisle": {
		"name": "The Flooded Aisle", "radius": 3, "player": [-2, 3],
		"enemies": [["moss_knight", 1, -3], ["censer_wraith", 3, -2]],
		"water": [[0, 0], [1, -1], [-1, 1], [2, -2]], "stone": [[-3, 1], [3, 0]],
		"blight": [[1, -3], [2, -3], [3, -2], [0, -2]], "thicket": [[-2, 3], [-1, 3]],
	},
	"clo_procession": {
		"name": "Procession of the Drowned", "radius": 3, "player": [0, 3],
		"enemies": [["drowned_novice", -2, -1], ["drowned_novice", -1, -2], ["drowned_novice", 1, -3], ["drowned_novice", 2, -2], ["bell_ghoul", 0, -3]],
		"water": [[-3, 3], [3, 0]], "stone": [[-2, 2], [2, 1]],
		"blight": [[-2, -1], [-1, -2], [1, -3], [2, -2], [0, -3], [0, -2], [-1, -1]], "thicket": [],
	},
	"clo_choir": {
		"name": "The Choir of Ash", "radius": 3, "player": [0, 3], "elite": true,
		"enemies": [["choir_of_ash", 0, -3], ["drowned_novice", -2, -1], ["drowned_novice", 2, -2]],
		"water": [[-3, 0], [3, -3]], "stone": [[-1, 0], [1, -1], [-2, 2], [2, 1]],
		"blight": [[0, -3], [-1, -2], [1, -3], [-2, -1], [2, -2], [0, -2]], "thicket": [[0, 3]],
	},
	"clo_abbess": {
		"name": "The Drowned Abbess", "radius": 4, "player": [0, 4], "boss": true,
		"enemies": [["drowned_abbess", 0, -3]],
		"water": [[-4, 1], [-4, 2], [4, -4], [4, -3], [0, 0], [-1, 1]], "stone": [[-3, 0], [3, -1], [-2, 3], [2, 1], [-1, -2], [2, -3]],
		"blight": [[0, -3], [-1, -3], [1, -4], [0, -4], [1, -3], [-2, -2], [2, -4]],
		"thicket": [[0, 4], [1, 3]],
	},
	# ---------------- Region 3: Glasswood ----------------
	# One dry bridge: hold the approach while the two Shardlings alternate Ward and strikes.
	"gls_crossing": {
		"name": "The Silver Crossing", "radius": 3, "player": [0, 3],
		"enemies": [["shardling", -2, -1], ["shardling", 2, -3]],
		"water": [[-3, 0], [-2, 0], [-1, 0], [1, 0], [2, 0], [3, 0]], "stone": [[-1, 2], [1, 1]],
		"blight": [[-2, -1], [-1, -2], [2, -3], [1, -2]], "thicket": [[0, 3], [0, 2], [0, 1]],
	},
	# A crystal copse splits the Stag's approach; the western growth patch tempts a Mite-first flank.
	"gls_orchard": {
		"name": "The Prism Orchard", "radius": 3, "player": [0, 3],
		"enemies": [["prism_stag", 1, -3], ["glass_mite", -2, 0]],
		"water": [[3, -2], [3, -1], [-3, 3]], "stone": [[-1, 0], [0, 0], [0, -1]],
		"blight": [[1, -3], [0, -2], [2, -3], [-2, 0]], "thicket": [[0, 3], [-1, 3], [-2, 1]],
	},
	# Flying Mites cross the broken channels; the clear middle offers access to either bank.
	"gls_mirrors": {
		"name": "Mites on the Mirrors", "radius": 3, "player": [0, 2],
		"enemies": [["glass_mite", -3, 0], ["glass_mite", 3, -3], ["shardling", 0, -2]],
		"water": [[-2, 0], [-1, 0], [1, -1], [2, -1]], "stone": [[-1, -2], [1, 2]],
		"blight": [[-3, 0], [-2, -1], [3, -3], [2, -2], [0, -2]], "thicket": [[0, 2], [0, 1]],
	},
	# Start inside a Grove, surrounded on three sides: commit to one exit before Ward becomes attack.
	"gls_splinters": {
		"name": "A Thousand Splinters", "radius": 3, "player": [0, 0],
		"enemies": [["shardling", -3, 1], ["shardling", 3, -1], ["shardling", 0, -3]],
		"water": [[-2, 2], [-1, 2], [2, -3], [1, -3]], "stone": [[-2, 0], [2, 0], [-1, -1]],
		"blight": [[-3, 1], [-3, 2], [3, -1], [2, -1], [0, -3], [0, -2]],
		"thicket": [[0, 0], [-1, 1], [1, 0]],
	},
	# A diagonal channel has two distant ends: take the western Grove or pursue the exposed Mite east.
	"gls_runoff": {
		"name": "The Forked Runoff", "radius": 3, "player": [-3, 3],
		"enemies": [["prism_stag", 2, -2], ["glass_mite", 1, -3]],
		"water": [[-1, 1], [0, 0], [1, -1]], "stone": [[-2, 1], [2, 0]],
		"blight": [[2, -2], [3, -3], [1, -3], [0, -2], [-1, -1]],
		"thicket": [[-3, 3], [-2, 3], [-2, 0], [-3, 1]],
	},
	# The Mite shields across the western pool while Stag and Shardling divide the two dry lanes.
	"gls_court": {
		"name": "Court of Broken Boughs", "radius": 3, "player": [0, 3],
		"enemies": [["prism_stag", -1, -2], ["shardling", 2, -3], ["glass_mite", -3, 0]],
		"water": [[1, 1], [2, 0], [3, -1], [-3, 1], [-3, 2]], "stone": [[-1, 0], [-1, -1], [0, -1]],
		"blight": [[-1, -2], [0, -2], [2, -3], [1, -3], [-3, 0], [-2, 0]],
		"thicket": [[0, 3], [0, 2], [1, 0]],
	},
	# The crystal screen breaks the approach, not ranged attacks: flank toward a support or close on Hart.
	"gls_hart": {
		"name": "The Lantern Hart", "radius": 3, "player": [-1, 3], "elite": true,
		"enemies": [["lantern_hart", 0, -2], ["glass_mite", -2, -1], ["shardling", 2, -3]],
		"water": [[-3, 0], [3, -3], [-2, 3], [2, 1]], "stone": [[-1, 0], [0, 0], [1, -1]],
		"blight": [[0, -2], [-1, -2], [1, -2], [-2, -1], [2, -3], [0, -3]],
		"thicket": [[-1, 3], [0, 2], [1, 1]],
	},
	# Central causeway and two wide flanks leave space to reposition when the Queen calls her court.
	"gls_queen": {
		"name": "The Splintered Queen", "radius": 4, "player": [0, 4], "boss": true,
		"enemies": [["splintered_queen", 0, -3]],
		"water": [[-2, 0], [-1, 0], [1, -1], [2, -1], [-3, 2], [3, 0]],
		"stone": [[-2, -1], [-1, -2], [1, -3], [2, -3], [-1, 3], [2, 1]],
		"blight": [[0, -3], [0, -4], [-1, -3], [1, -4], [0, -2], [2, -4], [-2, -2]],
		"thicket": [[0, 4], [1, 3], [0, 3]],
	},
	# Two Rustgrubs rot the approach; kill them off open ground so their death-blight stays clear.
	"iro_shaft": {
		"name": "The Rusted Shaft", "radius": 3, "player": [0, 3],
		"enemies": [["rustgrub", -1, -2], ["rustgrub", 2, -3]],
		"water": [[3, -1], [-3, 3]], "stone": [[-2, 1], [2, 0]],
		"blight": [[-1, -2], [0, -2], [2, -3], [1, -3], [-2, -1]], "thicket": [[0, 3], [1, 2]],
	},
	# The Cart Golem tramples a straight line toward you: plant thicket across the rails first.
	"iro_rails": {
		"name": "Runaway Rails", "radius": 3, "player": [-2, 3],
		"enemies": [["cart_golem", 2, -3], ["rustgrub", 0, -2]],
		"water": [[3, 0], [2, 1]], "stone": [[-3, 1], [1, 0], [-1, -1]],
		"blight": [[2, -3], [1, -2], [0, -2], [3, -3]],
		"thicket": [[-2, 3], [-1, 2], [-1, 1], [0, 1]],
	},
	# Two Tunnelers keep their distance and bring the roof down around you; close on one flank.
	"iro_undermine": {
		"name": "Undermined", "radius": 3, "player": [0, 2],
		"enemies": [["tunneler", -2, -1], ["tunneler", 2, -2], ["rustgrub", 0, -3]],
		"water": [[-3, 2], [3, -3]], "stone": [[-1, 0], [1, -1]],
		"blight": [[-2, -1], [2, -2], [0, -3], [1, -3], [-1, -2]],
		"thicket": [[0, 2], [-1, 2], [1, 1]],
	},
	# Start in the middle of a broken gallery: a cart from the west, a Tunneler to the north.
	"iro_gallery": {
		"name": "Collapsed Gallery", "radius": 3, "player": [0, 0],
		"enemies": [["tunneler", 0, -3], ["cart_golem", -3, 2]],
		"water": [[3, 0], [-3, 0]], "stone": [[-1, -1], [1, -2], [2, 0], [-2, 2]],
		"blight": [[0, -3], [1, -3], [-3, 2], [-2, 1]],
		"thicket": [[0, 0], [1, 0], [0, 1]],
	},
	# A flooded seam divides the chamber; its single dry crossing is the obvious cave-in target.
	"iro_sump": {
		"name": "The Flooded Sump", "radius": 3, "player": [-3, 2],
		"enemies": [["rustgrub", 3, -1], ["rustgrub", 1, -3], ["tunneler", 2, -3]],
		"water": [[-2, 0], [-1, 0], [1, 0], [2, 0]], "stone": [[-3, 3], [0, 2], [3, -2]],
		"blight": [[3, -1], [1, -3], [2, -3], [2, -2], [3, -3]],
		"thicket": [[-3, 2], [-2, 2], [-3, 1]],
	},
	# Ore carts, a Tunneler and a grub hold the depot: three threats, three different answers.
	"iro_depot": {
		"name": "The Ore Depot", "radius": 3, "player": [0, 3],
		"enemies": [["cart_golem", -2, -1], ["tunneler", 2, -3], ["rustgrub", 1, -2]],
		"water": [[-3, 3], [3, -2]], "stone": [[-1, 1], [1, 0], [0, -1]],
		"blight": [[-2, -1], [-1, -2], [2, -3], [1, -2], [2, -2]],
		"thicket": [[0, 3], [-1, 3], [1, 2]],
	},
	# The Heart never moves: cross its cave-ins while grubs rot the lanes around it.
	"iro_foundry": {
		"name": "The Foundry Heart", "radius": 3, "player": [0, 3], "elite": true,
		"enemies": [["foundry_heart", 0, -2], ["rustgrub", -2, -1], ["rustgrub", 2, -2]],
		"water": [[-3, 1], [3, -3]], "stone": [[-1, 0], [1, -1]],
		"blight": [[0, -2], [-1, -2], [1, -3], [0, -3], [-2, -1], [2, -2]],
		"thicket": [[0, 3], [-1, 3], [1, 2]],
	},
	# A wide gallery: the Engine collapses it in phase 1, then drives through what is left.
	"iro_engine": {
		"name": "The Engine of Rot", "radius": 4, "player": [0, 4], "boss": true,
		"enemies": [["engine_of_rot", 0, -3]],
		"water": [[-4, 2], [4, -2], [2, -4]],
		"stone": [[-2, -1], [2, -2], [-3, 2], [3, 0]],
		"blight": [[0, -3], [-1, -3], [1, -3], [0, -4], [-1, -2], [1, -4]],
		"thicket": [[0, 4], [1, 3], [-1, 4]],
	},
}


static func get_def(id: String) -> Dictionary:
	var d: Dictionary = ENCOUNTERS[id].duplicate(true)
	d["id"] = id
	return d
