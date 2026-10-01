class_name Withering
extends RefCounted
## Difficulty tiers 0-10. Each tier adds one modifier and keeps every lower tier's modifier.
## The profile stores the highest tier unlocked; winning a run at the top unlocked tier opens the next.

const MAX_TIER := 10
const TIERS := [
	{"name": "Thin Soil", "text": "Enemies have 10% more HP."},
	{"name": "Lean Purses", "text": "Fights pay 20% less gold."},
	{"name": "Sharp Thorns", "text": "Enemies begin each fight with +1 Strength."},
	{"name": "Frail Start", "text": "Start with 8 less Max HP."},
	{"name": "Dear Pedlar", "text": "Market prices are 25% higher."},
	{"name": "Bitter Elites", "text": "Elites and bosses have 15% more HP."},
	{"name": "Scant Rest", "text": "Camp restores 20% of Max HP instead of 30%."},
	{"name": "Stingy Boons", "text": "One fewer card is offered in rewards (minimum two)."},
	{"name": "Ravenous Ash", "text": "Standing in Blight at turn end costs 3 HP."},
	{"name": "The Long Withering", "text": "Enemies gain a further +1 Strength; start with 50 less gold."},
]


static func clamp_tier(t: int) -> int:
	return clampi(t, 0, MAX_TIER)


static func active(level: int, tier: int) -> bool:
	return level >= tier


## Highest tier a player may start at, given the profile.
static func unlocked(profile: Dictionary) -> int:
	return clamp_tier(int(profile.get("withering", 0)))


## Profile tier after winning a run played at `played`.
static func after_win(profile: Dictionary, played: int) -> int:
	var cur := unlocked(profile)
	return clamp_tier(maxi(cur, played + 1)) if played >= cur else cur


static func describe(level: int) -> String:
	var lines: Array = []
	for i in clamp_tier(level):
		lines.append("%d  %s: %s" % [i + 1, TIERS[i]["name"], TIERS[i]["text"]])
	return "\n".join(lines)
