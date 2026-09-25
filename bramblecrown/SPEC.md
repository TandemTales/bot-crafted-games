# BRAMBLECROWN — Game Specification

Native desktop game (Godot 4.7.2, Windows x64 primary). Original IP. Selected from
`.arcade-agent/pitches.md` (Pitch 1) on 2026-09-24.

## One-line pitch

A roguelike deckbuilder fought on a 3D hex diorama. Your cards grow a living **Thicket** across
the board while the enemy spreads **Blight**, so every turn is both a card decision and a
territory decision.

## Fiction

The Bramblecrown was the living hedge that kept the valley of Wend whole. It has withered, and
a grey rot called the Blight is eating its way up from the marsh. You are a **Grovewalker**, one
of the last people who can make things grow on command. You carry a seed of the Crown up through
five blighted regions to replant it at the Crown of Thorns. Names, characters, and places are
original to this project.

## Core rules (combat)

- **Board:** axial-coordinate hex grid. Normal fights use radius 3 (37 hexes) and bosses radius 4
  (61 hexes). Each hex has a **terrain** (`plain`, `stone` = blocks movement, `water` = impassable)
  and a **growth** (`none`, `thicket`, `blight`).
- **Grove:** the connected set of thicket hexes containing the Grovewalker's hex. It is empty if
  you are not standing on thicket. `G` = grove size.
- **Rooted bonus:** damage and ward from cards gain `+floor(G / 3)`. Some cards scale harder
  with `G`.
- **Thicket** costs enemies 2 movement to enter; it costs you 1. Some enemies trample it.
- **Blight:** an enemy standing on blight is **Empowered** (+2 attack damage). If you end your
  turn on blight you take 2 **Rot** damage. When blight is spread onto thicket, the thicket is
  destroyed (hex becomes `none`). When it is spread onto `none`, the hex becomes blight. Blight
  does not spread by itself; enemies spread it through telegraphed intents, so nothing is hidden.
- **Turn:** you start with 3 energy and draw 5 cards. You play cards, then end the turn. Your hand
  is discarded, then the enemies act in order, following the **intents** shown during your turn.
  Intents show the damage number, the predicted path, attack hexes, and the hexes to be blighted.
- **Ward** absorbs damage and is cleared at the start of your next turn.
- **Statuses:** `bleed N` (lose N HP at end of turn, then N-1), `rooted` (cannot move this enemy
  turn), `empowered` (derived from blight), `strength N`.
- **Win:** every enemy is defeated. **Loss:** your HP reaches 0 (ends the run).
- All randomness goes through a seeded RNG owned by the run, so fights and maps are
  reproducible from a seed.

## Run structure

- 5 regions, each on a branching node map (7 rows, 2–4 nodes per row, then a boss node).
  Node types: **Fight**, **Elite** (charm reward), **Shrine** (authored event with choices),
  **Camp** (rest +30% HP or upgrade a card), **Market** (buy cards/charms, remove a card), and
  **Boss**.
- Rewards: gold, choose 1 of 3 cards (or skip), and a charm from elites and bosses.
- A run is saved when entering each node and can be resumed from the title screen. Profile data
  (unlocks and highest Withering cleared) is saved separately.
- **Withering** difficulty tiers 0–10 unlock after each win and stack modifiers.

## Content plan (full game contract)

| Region | Board identity | Enemy roster (fights / elites) | Boss |
|---|---|---|---|
| 1. Ashfen Marsh | peat hexes, water pools, dead willows | Blightling, Rotmoth, Husk Brute, Sporecaller / Bog Warden | The Mire Mother |
| 2. Sunken Cloister | flooded flagstones, broken pillars (stone) | Censer Wraith, Bell Ghoul, Moss Knight / Choir of Ash | The Drowned Abbess |
| 3. Glasswood | crystal trees, reflective hexes | Shardling, Prism Stag, Glass Mite / Lantern Hart | The Splintered Queen |
| 4. Ironroot Deeps | mine rails, ore hexes, collapsing stone | Rustgrub, Cart Golem, Tunneler / Foundry Heart | The Engine of Rot |
| 5. Crown of Thorns | the dying hedge crown, shifting thorns | mixed elite pairs / The Last Gardener | The Withered Crown |

- **Encounters:** ≥ 6 authored fight setups per region (≥ 30 total) with fixed blight, terrain,
  and enemy placements, plus 5 elites and 5 bosses with multi-phase intents.
- **Grovewalkers:** Wren (balanced growth/strikes, starter), Cassia (burns her own grove for
  burst), Thatch (defensive walls, rooting, thorns). Cassia and Thatch unlock through progression.
- **Cards:** ≥ 60 cards total, each with an upgraded version (≥ 20 per Grovewalker plus neutral).
- **Charms:** ≥ 20.
- **Shrine events:** ≥ 12 authored events with 2–3 choices each.
- **Meaningful decisions:** every node choice, card reward, charm pick, market purchase, camp
  choice, and event choice, on top of spatial card play. That is well over 20 per run.

## Presentation

- **Camera:** 3D perspective looking down at about 55°, framing a hex diorama that floats over
  region-specific surroundings. It can orbit ±30° with Q/E or right-drag, and zoom with the mouse
  wheel.
- **Art direction:** a dark-fairytale "living diorama". Chunky beveled hex tiles with soil sides,
  warm key light versus a cold blight rim light, fog, and hand-built props. All 3D assets are
  authored in Blender (`source-art/*.blend`, generated by `source-art/*.py`) and exported as GLB
  into `assets/models/`.
- **UI:** parchment-and-bark card frames, a readable intent overlay on the board, hover tooltips
  for every keyword, and a clear turn banner.
- **Audio:** original synthesized SFX and ambient beds (`assets/audio/`), generated by
  `tools/make_audio.py`.

## Controls

| Action | Keyboard / mouse | Controller |
|---|---|---|
| Select card | Click card, or keys 1–9 | D-pad left/right + A |
| Target hex/enemy | Click hex | Left stick moves a hex cursor + A |
| Cancel | Right-click / Esc | B |
| End turn | Space / End Turn button | Y |
| Rotate camera | Q / E, right-drag | Shoulders |
| Zoom | Mouse wheel | Triggers |
| Pause menu | Esc (with no card selected) | Start |
| View draw / discard / exhausted pile | A / S / X, or click the pile buttons | — |

## Architecture and ownership

Rules are pure GDScript classes with no scene dependencies (`scripts/core/`) so they can be
tested headless. Scenes and views only read rule state and submit actions.

| File | Owner (single collaborator) | Responsibility |
|---|---|---|
| `scripts/core/hex.gd` | rules-engineer | axial hex math, neighbors, distance, rings, lines, pathfinding |
| `scripts/core/rng.gd` | rules-engineer | seeded deterministic RNG wrapper |
| `scripts/core/card_db.gd` | content-designer | card definitions and upgrades |
| `scripts/core/enemy_db.gd` | content-designer | enemy definitions and intent patterns |
| `scripts/core/encounter_db.gd` | content-designer | authored encounter layouts per region |
| `scripts/core/charm_db.gd` | content-designer | charm (relic) definitions |
| `scripts/core/event_db.gd` | content-designer | shrine event definitions |
| `scripts/core/combat_state.gd` | rules-engineer | combat rules, intents, resolution |
| `scripts/core/run_state.gd` | rules-engineer | run progression, map generation, rewards, save/load |
| `scripts/game/game.gd` (autoload `Game`) | integration (main runner) | scene flow, current run, profile |
| `scripts/game/board_view.gd` | render-engineer | 3D board, units, growth props, intent overlays |
| `scripts/game/camera_rig.gd` | render-engineer | orbit/zoom camera |
| `scripts/game/combat_scene.gd` | integration (main runner) | combat controller, input, hand/HUD wiring |
| `scripts/ui/card_view.gd` | ui-engineer | single card widget |
| `scripts/ui/hand_view.gd` | ui-engineer | hand layout and hover/select |
| `scripts/ui/map_scene.gd` | ui-engineer | region map screen |
| `scripts/ui/title_scene.gd` | ui-engineer | title/menu screen |
| `scripts/ui/reward_scene.gd` | ui-engineer | post-fight rewards |
| `scripts/ui/theme_builder.gd` | ui-engineer | shared UI theme, fonts, anchoring helper |
| `scripts/ui/unit_plate.gd` | ui-engineer | floating HP / ward / status / intent plates |
| `scripts/ui/run_hud.gd` | ui-engineer | out-of-combat top bar |
| `scripts/ui/deck_viewer.gd` | ui-engineer | deck grid (view / upgrade / remove) |
| `scripts/ui/room_scene.gd` | ui-engineer | camp, shrine, and market screens |
| `scripts/ui/room_stage.gd` | render-engineer | live 3D vignettes behind camp/shrine/market/reward screens |
| `scripts/ui/charm_glyph.gd` | ui-engineer | vector icon per charm |
| `scripts/ui/run_end_scene.gd` | ui-engineer | victory / defeat summary |
| `scripts/game/audio.gd` (autoload `Sfx`) | audio-designer | SFX/music playback |
| `source-art/*.py`, `source-art/*.blend` | 3d-artist | Blender asset generation |
| `tools/make_audio.py` | audio-designer | synthesized audio generation |
| `tests/test_runner.gd` | qa-engineer | headless rule tests |
| `tools/screenshot_tour.gd` | qa-engineer | packaged-build screenshot capture mode |
| `tools/check.sh` | qa-engineer | import + scene smoke + rule tests |
| `source-art/preview_sheet.py` | 3d-artist | Blender contact-sheet render for asset QA |
| `export_presets.cfg` | integration (main runner) | Windows x64 release preset |

## Why this differs from every existing project

The repository has no other games yet. Compared with the owner's separate browser arcade
(Prism Warden, Lumen Pinnacle, Ironwake, Paradox Vault, and others), Bramblecrown is the only
turn-based card game, the only roguelike deckbuilder, and the only game where territory control
on a hex board is the central resource. It is also a native desktop build rather than a browser
game.
