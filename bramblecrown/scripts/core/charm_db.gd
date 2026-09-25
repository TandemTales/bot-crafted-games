class_name CharmDB
extends RefCounted
## Charms (relics). Their effects are implemented by id in combat_state.gd / run_state.gd.

const CHARMS := {
	"acorn_locket": {"name": "Acorn Locket", "text": "Start each fight standing in 3 Thicket.", "rarity": "common"},
	"mossy_flask": {"name": "Mossy Flask", "text": "Heal 6 HP after each fight.", "rarity": "common"},
	"ironbark_husk": {"name": "Ironbark Husk", "text": "Start each fight with 8 Ward.", "rarity": "common"},
	"heron_feather": {"name": "Heron Feather", "text": "+1 Movement each turn.", "rarity": "common"},
	"seed_pouch": {"name": "Seed Pouch", "text": "Draw 2 extra cards on the first turn of each fight.", "rarity": "common"},
	"amber_heart": {"name": "Amber Heart", "text": "Gain 10 max HP when picked up.", "rarity": "common"},
	"grove_bell": {"name": "Grove Bell", "text": "If your Grove has 6+ hexes at the start of your turn, gain 1 Energy.", "rarity": "uncommon"},
	"ember_fang": {"name": "Ember Fang", "text": "Your first attack each turn applies 2 Bleed.", "rarity": "uncommon"},
	"rot_ward": {"name": "Rot Ward", "text": "You no longer take Rot damage from standing on Blight.", "rarity": "uncommon"},
	"thorn_crown_shard": {"name": "Thorn-Crown Shard", "text": "Thicket costs enemies 3 Movement instead of 2.", "rarity": "rare"},
}


static func get_def(id: String) -> Dictionary:
	var d: Dictionary = CHARMS[id].duplicate()
	d["id"] = id
	return d
