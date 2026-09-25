class_name EventDB
extends RefCounted
## Shrine events. Each option lists outcome ops that run_state.gd applies:
##   heal n | hurt n | max_hp n | gold n (negative = pay, option disabled if short) |
##   card id | upgrade_random | remove_random_starter | charm random | curse id

const EVENTS := {
	"drowned_well": {
		"title": "The Drowned Well",
		"text": "A stone well brims with black water. Something glints at the bottom, and the water smells faintly of rain.",
		"options": [
			{"label": "Reach in. (Lose 7 HP, gain a random charm.)", "ops": [["hurt", 7], ["charm", "random"]]},
			{"label": "Drink. (Heal 12 HP.)", "ops": [["heal", 12]]},
			{"label": "Leave it be.", "ops": []},
		],
	},
	"hermit_grafter": {
		"title": "The Hermit Grafter",
		"text": "An old woman binds living twigs to a crooked staff. \"Everything can be improved,\" she says, \"for a price.\"",
		"options": [
			{"label": "Pay 40 gold. (Upgrade 2 random cards.)", "ops": [["gold", -40], ["upgrade_random", 2]]},
			{"label": "Offer blood. (Lose 5 max HP, upgrade 1 random card.)", "ops": [["max_hp", -5], ["upgrade_random", 1]]},
			{"label": "Decline politely.", "ops": []},
		],
	},
	"weeping_willow": {
		"title": "The Weeping Willow",
		"text": "A willow still lives here, its roots wrapped around a Grovewalker's cairn. Its branches lean toward you.",
		"options": [
			{"label": "Rest beneath it. (Heal to full, remove a Thornstrike or Barkskin.)", "ops": [["heal", 999], ["remove_random_starter", 1]]},
			{"label": "Take a cutting. (Gain Verdant Surge.)", "ops": [["card", "verdant_surge"]]},
		],
	},
	"peat_cutters": {
		"title": "Abandoned Peat Cut",
		"text": "Cutters fled in a hurry. Their pay chest is still half-buried where the Blight is thickest.",
		"options": [
			{"label": "Dig out the chest. (Lose 10 HP, gain 75 gold.)", "ops": [["hurt", 10], ["gold", 75]]},
			{"label": "Search their packs. (Gain 20 gold.)", "ops": [["gold", 20]]},
		],
	},
	"moth_choir": {
		"title": "The Moth Choir",
		"text": "Hundreds of pale moths hum one low note. They part, and a path opens through them, or you could burn the lot.",
		"options": [
			{"label": "Listen. (Gain Pollen Cloud.)", "ops": [["card", "pollen_cloud"]]},
			{"label": "Burn them. (Gain Wildfire, lose 4 HP.)", "ops": [["hurt", 4], ["card", "wildfire"]]},
		],
	},
}


static func get_def(id: String) -> Dictionary:
	var d: Dictionary = EVENTS[id].duplicate(true)
	d["id"] = id
	return d
