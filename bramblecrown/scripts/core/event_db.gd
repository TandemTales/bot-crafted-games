class_name EventDB
extends RefCounted
## Shrine events. Each option lists outcome ops that run_state.gd applies:
##   heal n | hurt n | max_hp n | gold n (negative = pay, option disabled if short) |
##   card id | upgrade_random | remove_random_starter | charm random
## `region` (optional) limits an event to one region; region events are offered first there.

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
	# ---------------- Region events: offered first while in their region ----------------
	"sunken_bell": {
		"title": "The Sunken Bell", "region": "cloister",
		"text": "A cracked bell lies half-drowned in the nave. Ring it and the faithful may answer. Its bronze would fetch a good price, if you can lift it.",
		"options": [
			{"label": "Ring it once. (Lose 6 HP, gain Bellbreaker.)", "ops": [["hurt", 6], ["card", "bellbreaker"]]},
			{"label": "Salvage the bronze. (Lose 9 HP, gain 60 gold.)", "ops": [["hurt", 9], ["gold", 60]]},
			{"label": "Let it lie.", "ops": []},
		],
	},
	"vigil_candles": {
		"title": "Vigil of Candles",
		"region": "cloister",
		"text": "Row on row of candles still burn for a service no one attends. The wax has run into a single pale lake across the floor.",
		"options": [
			{"label": "Light one for yourself. (Heal 15 HP.)", "ops": [["heal", 15]]},
			{"label": "Gather the warm wax. (Gain Last Lantern.)", "ops": [["card", "last_lantern"]]},
			{"label": "Snuff them all. (Lose 5 max HP, gain a random charm.)", "ops": [["max_hp", -5], ["charm", "random"]]},
		],
	},
	"mirror_pool": {
		"title": "The Mirror Pool", "region": "glasswood",
		"text": "The still water shows you as you might have been: taller, surer, with a full seed-pouch. The reflection holds out its hand.",
		"options": [
			{"label": "Take its hand. (Lose 8 HP, upgrade 2 random cards.)", "ops": [["hurt", 8], ["upgrade_random", 2]]},
			{"label": "Shatter it. (Gain Spinebreaker.)", "ops": [["card", "spinebreaker"]]},
			{"label": "Walk on without looking back.", "ops": []},
		],
	},
	"glass_fawn": {
		"title": "The Glass Fawn", "region": "glasswood",
		"text": "A fawn of living glass is caught in a snarl of splinters, chiming with every breath. Its shed antler lies nearby, bright as ice.",
		"options": [
			{"label": "Free it. (Lose 6 HP, gain a random charm.)", "ops": [["hurt", 6], ["charm", "random"]]},
			{"label": "Take the shed antler. (Gain 45 gold.)", "ops": [["gold", 45]]},
		],
	},
	"miners_cache": {
		"title": "The Miners' Cache", "region": "ironroot",
		"text": "A strongbox sits behind a snapped roof prop. The ceiling above it groans every time you breathe.",
		"options": [
			{"label": "Pry it open now. (Lose 12 HP, gain 90 gold.)", "ops": [["hurt", 12], ["gold", 90]]},
			{"label": "Shore up the roof first. (Pay 20 gold, gain 55 gold and Briar Wall.)", "ops": [["gold", -20], ["gold", 55], ["card", "briar_wall"]]},
			{"label": "Leave it to the Deeps.", "ops": []},
		],
	},
	"lamp_chapel": {
		"title": "The Lamp Chapel", "region": "ironroot",
		"text": "Miners hung their lamps here before every shift. One still burns, its oil topped up by no one you can see.",
		"options": [
			{"label": "Refill it. (Pay 30 gold, heal 22 HP.)", "ops": [["gold", -30], ["heal", 22]]},
			{"label": "Say the miners' prayer. (Upgrade 1 random card.)", "ops": [["upgrade_random", 1]]},
			{"label": "Take the oil. (Gain Wildfire.)", "ops": [["card", "wildfire"]]},
		],
	},
	"gardeners_shed": {
		"title": "The Gardener's Shed", "region": "crown",
		"text": "Tools hang in perfect order under a ledger of every plant the Crown ever grew. The last entry is only half written.",
		"options": [
			{"label": "Borrow the shears. (Remove a Thornstrike or Barkskin, upgrade 1 random card.)", "ops": [["remove_random_starter", 1], ["upgrade_random", 1]]},
			{"label": "Finish the ledger. (Gain Seed of Ages.)", "ops": [["card", "seed_of_ages"]]},
			{"label": "Rest among the pots. (Heal 20 HP.)", "ops": [["heal", 20]]},
		],
	},
	"first_seedling": {
		"title": "The First Seedling", "region": "crown",
		"text": "At the foot of a dead arch, one green shoot has pushed up through the ash. It is the first living thing you have seen in days.",
		"options": [
			{"label": "Shelter it with your own blood. (Lose 6 max HP, gain a random charm.)", "ops": [["max_hp", -6], ["charm", "random"]]},
			{"label": "Carry it with you. (Gain Verdant Surge, heal 10 HP.)", "ops": [["card", "verdant_surge"], ["heal", 10]]},
			{"label": "Leave it to grow. (Max HP +4.)", "ops": [["max_hp", 4]]},
		],
	},
}


static func get_def(id: String) -> Dictionary:
	var d: Dictionary = EVENTS[id].duplicate(true)
	d["id"] = id
	return d
