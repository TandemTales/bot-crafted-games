# Pitches — 2026-09-24 (Pacific)

## Research snapshot

Research date: Thursday 2026-09-24, Pacific time.

**Steam Most Played** (daily rollup dated 2026-09-23, from `api.steampowered.com/ISteamChartsService/GetMostPlayedGames`,
which feeds https://store.steampowered.com/charts/mostplayed). Peak concurrent players shown:

| Rank | Game | Genre | Peak |
|---|---|---|---|
| 1 | Counter-Strike 2 | competitive FPS | 1,452,036 |
| 2 | Dota 2 | MOBA | 805,725 |
| 3 | PUBG | battle royale | 731,479 |
| 5 | WARDOGS (EA, released 2026-09-10) | 100-player 3-team zone-control FPS with destruction and fortifying | 284,112 |
| 6 | Apex Legends | hero battle royale | 254,139 |
| 7 | Valheim | survival crafting | 199,097 |
| 9 | Aniimo (released 2026-09-15) | creature-collection MMO RPG | 145,080 |
| 11 | HELLDIVERS 2 | co-op squad shooter | 70,123 |
| 12 | Slay the Spire 2 (EA) | roguelike deckbuilder | 89,279 |
| 13 | Marvel Rivals | hero shooter | 91,844 |
| 26 | Stardew Valley | farming life sim | 68,614 |
| 27 | Rust | survival crafting | 98,597 |
| 30 | Palworld | creature survival crafting | 69,035 |
| 32 | Project Zomboid | survival sim | 53,015 |
| 34 | Baldur's Gate 3 | party RPG | 53,638 |

**Steam Weekly Top Sellers (US, 2026-09-15 to 2026-09-22)**: https://store.steampowered.com/charts/topsellers/US.
The top of the chart: WARDOGS, Counter-Strike 2, Marvel Rivals, RuneScape: Dragonwilds, Aniimo, EA SPORTS FC 27,
Steam Deck, Apex Legends, Borderlands 4, Baldur's Gate 3, Halloween: The Game, Dimraeth, CONTROL Resonant,
Diablo IV, Overwatch, Trails in the Sky 2nd Chapter, Limbus Company, HELLDIVERS 2, Warframe, The Blood of Dawnwalker.

Store pages read: https://store.steampowered.com/app/1867240/ (WARDOGS, Very Positive, 83% of 50,614 reviews)
and https://store.steampowered.com/app/2868840/ (Slay the Spire 2, 91% of 69,814 reviews, five characters, co-op).

Limits: this is one day's snapshot of two chart types, plus prior knowledge of long-running
genre popularity. Monthly Top Releases were not captured this run.

## Catalog check

This repository has no games yet, so no pitch can repeat a catalog game. The owner's separate
browser arcade (`ai-game-of-the-day`) has a light/beacon adventure (Prism Warden), a neon pinball
table (Lumen Pinnacle), a coastal demolition campaign (Ironwake), and a time-loop heist
(Paradox Vault). The pitches below avoid those themes and verbs too.

---

## Pitch 1 — BRAMBLECROWN (tactical territory deckbuilder roguelike)

- **References:** Slay the Spire 2 (#12 most played, 89k peak; https://store.steampowered.com/app/2868840/).
  Additional genre reference (outside the chart): the telegraphed-intent hex/grid tactics of Into the Breach.
- **Mechanic reinterpreted:** the Slay the Spire loop of drawing a hand, spending energy, reading enemy intents,
  and building a deck and relics along a branching map.
- **Original twist:** the fight takes place on a 3D hex diorama, and **the board is the second deck**. Many cards
  *grow* Thicket onto hexes. Enemies spread *Blight*, which converts hexes each turn. Your attacks scale with the
  size of the connected grove you stand in, blight hexes empower enemies, and some cards consume your own grove
  for burst damage. Each fight is a tug-of-war over territory as well as HP, so card choice is also spatial
  planning. Enemy intents are drawn as arrows and marked hexes on the board.
- **Player experience:** the "one more run" deckbuilding hook plus the satisfaction of reshaping a living board;
  every turn asks both "what do I play?" and "where does the forest go?".
- **Scope:** 5 authored regions (Ashfen Marsh, Sunken Cloister, Glasswood, Ironroot Deeps, the Crown of Thorns),
  each with its own board art, hazards, and enemy roster. About 30 fight/elite encounters, 5 bosses, 12+ shrine
  events, camps, and a market. 3 Grovewalkers with distinct card pools, 60+ cards with upgrades, 20+ charms
  (relics), and 10 "Withering" difficulty tiers.
- **Why it's distinct:** no catalog game is a deckbuilder or turn-based. The territory layer is a core rule,
  not a theme.

## Pitch 2 — SALTMARROW (tide-clock survival crafting)

- **References:** Valheim (#7, 199k peak), Rust (#27), Palworld (#30), Project Zomboid (#32).
- **Mechanic reinterpreted:** the gather → craft → build → venture-further loop of survival crafting.
- **Original twist:** a drowned archipelago on a 20-minute tide clock. Low tide exposes causeways, wrecks, and
  resources; high tide floods them. Bases must be built on stilts or as floating rafts, and every expedition is a
  race against the returning water.
- **Player experience:** tense timed expeditions and a base that grows in the vertical and floating dimensions.
- **Scope:** 5 islands, 25+ crafting tiers/objectives, 4 bosses.
- **Risk:** open-world survival needs large amounts of animation, AI, and terrain-streaming polish to meet the
  quality bar on a single-agent budget. A weak version would read as a hollow sandbox.

## Pitch 3 — CROSSFIRE KENNEL (three-faction zone control vs. bots)

- **References:** WARDOGS (#5, 284k peak, #1 top seller; https://store.steampowered.com/app/1867240/),
  HELLDIVERS 2 (#11), Battlefield 6.
- **Mechanic reinterpreted:** three teams contesting shifting control zones, with destruction and fortification.
- **Original twist:** single-player third-person squad command. You lead a pack of 4 bot hounds with
  whistle-orders, and three factions fight over a moving zone across 5 district maps in a campaign.
- **Player experience:** chaotic three-way battles where positioning and orders beat aim.
- **Risk:** convincing real-time bot AI, gunfeel, and character animation for 30+ agents is the costliest possible
  choice for AAA-level feel with our toolchain. Without multiplayer, it loses the social loop that drives WARDOGS.

---

## Selection

No `.arcade-agent/pitch-selection.md` existed and there were no human messages, so no human choice is pending.
**Selected: Pitch 1 — BRAMBLECROWN.** Reasons:

1. It is built on a top-charting, long-lived design (Slay the Spire 2 is top-15 by concurrent players) but has a
   strong, original board-territory rule that changes every decision.
2. A turn-based game can meet a very high quality bar on this toolchain: the rules are fully deterministic
   and testable, and Blender-authored diorama boards, figures, and props can be iterated to a high finish without
   dozens of skeletal animation sets.
3. The authored content bar (5 regions, 30+ encounters, 5 bosses, 60+ cards, events) is concrete and measurable.

Pitches 2 and 3 remain on file as future candidates.
