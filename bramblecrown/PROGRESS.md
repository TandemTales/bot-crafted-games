# BRAMBLECROWN — Progress

## 2026-09-26 — Run 5 checkpoint (Pacific Saturday 09:35, age 2 days)

- STOP absent; worktree fast-forwarded to remote `dev` `4f65d1c` (Run 4 final). Work pushes to `dev`.
- Polish night: forced release remains 2026-10-03 Pacific; no quality pass exists for early release.
- Bounded plan from Run 4's next action: (1) sequential-enemy forecast vs resolution regression,
  (2) Region 4 Ironroot Deeps (board, roster, elite, boss, encounters, original Blender assets).
- Next action: write the forecast regression, then Ironroot content.

### Run 5 final result and next action

- **Forecast fix (all regions):** a new sweep of every authored encounter found 81 of 1,107
  enemy forecasts disagreeing with the actual enemy phase: wrong end hex, or a telegraphed hit that
  missed and vice versa. Forecasts now run the whole enemy phase on a throwaway copy (the real
  state and RNG are untouched). Drift is 0 of 1,461, including damage and Ironroot cave-ins.
- **Telegraph visibility (all regions):** pulsing overlays (blight spread, cave-in, danger) faded
  to alpha 0 at every pulse trough, so marks could vanish from the board. They now stay at 60% or more.
- **Ironroot Deeps (region 4 of 5):**
  - Six fights, the Foundry Heart elite and the two-phase Engine of Rot.
  - Rustgrub, Cart Golem and Tunneler.
  - New telegraphed **cave-in** rule: marked hexes become rubble, and standing on a mark costs
    6 HP. Cave-ins never split the walkable board and are capped at 40% rubble.
  - Twelve original Blender models, including a separate rail tile, and an animated Engine.
  - Each cave-in hex shows a "-6" label with a dashed tether to the enemy that marked it.
  - Lamp-lit board theme, one continuous rail line, per-encounter prop layouts.
  - Themed map motif, rooms, reward headline, camp text and four-region clear text.
- **Gate:** 1,658 passed / 0 failed (installed Godot import, scene smokes, rules).
- **Package:** `build/windows/Bramblecrown.exe`, SHA-256 `42B77CA94A8618256BEFF51740939C26578C542FAF70957A4170F72A1FE6E633`
  (118,581,368 bytes). The `--tour-only run5` tour passed at 1280x720, 1920x1080 and 2560x1440:
  22 images each, 0 failures, normal saves unchanged. The main runner read all 66 images.
  Evidence is in `evidence/2026-09-26-run5/`.
- **Critic** (independent, read-only; two rounds; vs Into the Breach and StS2/Monster Train 2):
  - Round 1: room/reward screens at parity; everything else "loses" or "loses badly".
  - Round 2, after fixes:
    - Board art: loses (was loses badly).
    - New-enemy readability: loses (was loses badly).
    - Cave-in telegraph: loses badly.
    - HUD/rail: loses.
    - Map: loses (was loses badly).
    - Rooms: parity.
    - Coherence: loses.
    - Region 4 identity: loses (was loses badly).
  - The final unit (per-hex labels, source tethers, Rustgrub recolour) answers the critic's top two
    items but has **not** been re-judged.
  - No discipline passes, so there is no quality release.
- **Limits:**
  - Tours stage fights and synthetic input; no genuine playthrough.
  - Not verified: human play, audio listening, a physical controller, fullscreen/focus,
    4K/ultrawide, sustained performance, or other hardware.
  - Balance is unverified (the bot still clears Marsh in 2 of 20 seeds).
  - Combat resume restarts the node.
- **Release:** nothing uploaded. No `.aaa-complete`. Forced release remains **2026-10-03 Pacific**.
  The only Butler binary found here (`C:\dev\bayou\...`) is not authenticated for this project,
  so itch.io status was not rechecked. The last recorded state is a Draft page with build #2014268.

Exact next action for Run 6:
1. Ask the critic to re-judge the cave-in telegraph and Rustgrub on the final package.
   Then fix the remaining HUD items it named:
   - Intent icons and target counts on the enemy rail.
   - A boss phase-2 notch and banner in real play.
   - Move the "Your Turn" banner off enemies.
   - Taproot's clipped card text.
2. Improve the cave-in aftermath:
   - A flatter, darker rubble model with a crash effect, so it is not read as decoration.
   - Vary the rail row per encounter (encounter key `rail_row`).
   - Show sump water in at least two Ironroot fights.
3. Start Region 5 (Crown of Thorns) or region-specific shrine events. Also do a real (non-staged)
   run to the clear screen and check the stats there.

Full remaining contract:
- Region 5 (Crown of Thorns: mixed elite pairs, The Last Gardener, The Withered Crown).
- Cassia and Thatch, with at least 20 cards each.
- Charms (10 of 20), and events (5 global of 12, none region-specific).
- Withering tiers, and human balance and discipline acceptance.

Content now: 24 fights, 4 elites, 4 bosses, 34 Wren cards, 10 charms, 5 events.

## 2026-09-26 — Run 4 checkpoint (Pacific Saturday, age 2 days)

- STOP absent; clean documented `dev` at `977a7d9`, equal to remote `dev`.
- Installed Godot `4.7.2.stable.official.ed1daf0bf`, Blender `5.1.2`; matching
  `4.7.2.stable/windows_release_x86_64.exe` and embedded-PCK `Windows Desktop` preset verified.
- Authenticated Butler confirms `shoejunk/bramblecrown:windows`, processed build `#2014268`,
  version `2026.09.24-10aa561`. Page visibility is not rechecked; last recorded state is Draft.
- Polish night: release is not due until 2026-10-03 Pacific. No early-release quality pass.
- Bounded scope: Glasswood roster and eight authored encounters; original Blender board/roster
  assets; progression, save/resume and packaged UI verification. Preserve the full SPEC contract.
- Main runner owns integration and Git. Separate content collaborators each own exactly one
  SPEC-listed file: `enemy_db.gd` and `encounter_db.gd`. Independent critic edits no files.
- Next action: implement Glasswood, run installed-engine import/rules, reopen representative
  Blender source, export Windows and inspect native captures at 720p/1080p/1440p.


### Run 4 working unit

- Integrated Glasswood: six authored fights, Lantern Hart elite, two-phase Splintered Queen,
  eleven original Blender model sources/exports, region-themed rooms and map, matching-icon
  map legend, and truthful three-region development completion text.
- Installed Godot full import/scene/rule gate: **1,373 passed / 0 failed**. New checks cover
  progression, all eight deterministic encounter restarts, boss phases/summon caps and tactical
  counters. Campaign balance is not established; existing bot still clears Marsh 2/20 times.
- Windows package ran a first 720p tour: 20 images, zero assertions/errors, normal player saves
  unchanged. Initial visual inspection found captures during banner fade; tour now waits for the
  banner to clear and asserts that state. Crystal blocker silhouettes need another art review.
- Blender Queen source reopened: three meshes (915/39/39 vertices), materials present, two
  1–49 frame mantle actions. Initial generation succeeded but sandbox denied thumbnail-cache
  writes; source and GLB outputs exist, import and export pass. Thumbnail warnings are not asset QA.
- Fixed export hygiene: `build/.gdignore` plus explicit build/evidence/source-art preset exclusions
  prevent local screenshots and editable assets being imported/shipped in later packages.
- Next: finish bounded visual corrections, re-export, inspect all three required resolutions,
  obtain independent critic follow-up, retain evidence and push final handoff. No itch upload.
### Run 4 final result and next action

- **Delivered:** Glasswood (six fights, elite, two-phase boss), eleven editable Blender models
  and runtime GLBs, animated Queen mantle, thematic room/map presentation and completion text.
  Corrected crystal visibility and Hart identity after native inspection. Critic-driven UI fixes
  distinguish self/ally Ward and back gold/prices with dark panels.
- **Final gate:** 1,373 passed / 0 failed; installed Godot import, scene smokes and export clean.
  Corrected package ran at **1280x720, 1920x1080, 2560x1440**, with 20 screenshots per size,
  zero assertions/errors, exit 0, and unchanged normal player files. Main runner read all 60
  images through contact sheets plus representative originals. Queen animation is imported/playing.
- **Package:** `build/windows/Bramblecrown.exe`, embedded PCK, 117,920,216 bytes.
  SHA-256 `244FDD2CAC12D5E15D5C74409C872E26DF512F4CD4FF80DB628CE3CD5838B275`.
  Raw logs, nine contact sheets, representative originals, source reopen evidence and independent
  critic scope are retained in `evidence/2026-09-26-run4/`.
- **Critic:** narrow readability corrections pass; no new blocking visual regression.
  Overall **ours loses / no AAA or shipping pass**: sparse void/flat terrain, dark small enemies,
  repeated map stamps, overbright room lights, rudimentary faces and missing regional event scenes.
  Three regions and one walker still do not satisfy the full SPEC.
- **Limits:** tours use staged encounters/endings and synthetic input. No genuine full-region
  keyboard/mouse playthrough, listening, physical controller, focus/fullscreen, 4K/ultrawide this
  run, sustained performance, other hardware or player-path download/install verification.
  Combat save/resume restarts the node; it does not retain mid-turn combat state.
- **Release:** nothing uploaded/published. No `.aaa-complete`; Bramblecrown remains active.
  Forced release remains **2026-10-03 Pacific**. Butler's old processed build is unchanged;
  Draft is the last recorded page visibility, not freshly browser-verified this run.

Exact next action for Run 5:
1. Add a focused sequential-enemy preview versus actual resolution regression. The critic flagged
   current-occupancy forecasts versus ordered enemy movement as an unverified pre-existing risk.
   Fix only if reproduced, preserving the authoritative combat rules.
2. Continue full content with Ironroot Deeps: six encounters, Rustgrub/Cart Golem/Tunneler,
   Foundry Heart elite, Engine of Rot boss, and original Blender environment/roster assets.
3. Author region-specific Cloister/Glasswood shrine choices and matching scenes; retain the
   current readability gains. Schedule genuine play/audio/controller evidence when available.

Full remaining contract: regions 4–5; Cassia and Thatch with at least 20 cards each; additional
charms/events; Withering tiers; human balance and all discipline quality acceptance. Existing
content is 18 normal fights + 3 elites + 3 bosses, 34 Wren cards, 10 charms and 5 global events.
## 2026-09-26 — Run 3 checkpoint (Pacific Saturday, age 2 days)

- STOP absent. Clean `dev` at `9a4220b`, confirmed equal to remote `dev` before changes.
- Installed tools rechecked: Godot `4.7.2.stable.official.ed1daf0bf`, Blender `5.1.2`; matching `4.7.2.stable` Windows x64 release template present. Existing preset: `Windows Desktop`, embedded PCK.
- Butler authenticated status still reports `shoejunk/bramblecrown:windows`, processed build `#2014268`, version `2026.09.24-10aa561`. Recorded page state is Draft; visibility has not been rechecked this run.
- First Saturday, below the nine-day threshold: polish night. Forced release remains 2026-10-03; outstanding critic failures also prevent an early release.
- Bounded plan: (1) a non-overlapping enemy plate rail with clear unit association and readable Abbess, (2) ten authored Cloister cards with ward/daze counterplay, original Blender illustrations, and rarity presentation. Preserve the full five-region SPEC contract.
- Verification planned: focused rules and save/preview regressions, installed-Godot import and complete suite, Blender reopen/import, Windows export and native screenshot checks at three resolutions, then independent harsh critique and a pushed handoff. Human play, audio listening, and physical controller coverage must remain explicitly unverified unless performed.
- Next action: implement and verify enemy readability first.

### Working unit checkpoint

- Implemented ten Cloister cards (34 total), region-gated rewards/markets, base/upgrades, Ward
  destruction/stealing/reserve/spend and Daze prevention/recovery. Every illustration was
  generated with installed Blender; ten editable card scenes and the remodeled Abbess are tracked.
- Enemy plates now form a numbered side rail; matching board badges and hover links associate
  each enemy. Rail clicks use normal targeting. Revised camera framing preserves boss headroom,
  rarity is labeled/framed, and deck-viewer backgrounds are opaque.
- Strict import/scene/rule checks: **1,055 passed, 0 failed**, all process exits checked and no
  engine errors. Tightening the harness exposed the old shutdown error: verbose output identifies
  active AudioStreamPlaybackWAV/music under Godot's Dummy audio driver. Headless mode now loads
  audio assets without starting playback; native builds retain normal playback.
- Blender reopen: Abbess is one joined mesh with 5,796 vertices; Borrowed Vow's editable scene
  opens with eight objects, a camera, and 396x224 output. Updated GLB and all card textures import.
- First new packaged regression at 1280x720: 13 images, zero assertion failures, keyboard card
  selection and mouse rail targeting resolve correctly, six panels do not overlap, all new
  base/upgraded descriptions fit, normal save/profile/settings hashes unchanged. Sandbox native
  log has a certificate-store environment error; repeat final native checks outside that boundary.
- Independent critic inspected six earlier packaged screenshots alongside official Into the Breach
  and Slay the Spire 2 screenshots. Verdict: **no quality pass**. It recognized improved enemy
  association but rejected camera/hand collision, small forecast text, noisy battlefield contrast,
  underused pile-viewer space, and unreadable text over terrain. Camera/font/hint revisions are
  implemented; final re-review is still pending.
- Next action: final art/framing touch-ups, re-export, three-resolution native checks, critic
  follow-up, and the final pushed handoff. No release or complete marker.

### Final Run 3 result and handoff

- **Delivered:** ten region-2 Wren cards and upgrades, original editable Blender illustrations,
  readable Abbess mask/candle crown, numbered enemy targeting rail, rarity frames/labels,
  enlarged pile cards, and a left-margin card inspector that leaves Wren and targeting hints clear.
  Initial pile enlargement clipped headers because of the hand card's bottom pivot; fixed the
  pivot and added whole-card bounds checks. The critic's later missing-cost report was withdrawn
  after it re-opened the exact original images and confirmed all costs.
- **Validation:** the strict full gate passed **1,055 / 0**. Subsequent presentation-only changes
  passed combat scene smoke and packaged checks. The same final Windows x64 executable ran at
  **1280x720, 1920x1080, 2560x1440, and 3840x2160**: 14 screenshots and zero assertions/errors
  at each size, clean process exits, normal player-file hashes unchanged. The main runner inspected
  every final image through contact sheets and opened representative card/targeting images at
  full size. The independent critic inspected the final 720p images.
- **Package:** `build/windows/Bramblecrown.exe`, embedded PCK.
  SHA-256 `27FEE5A52334ED1ACEA86B12DCFE2A04827A6269986537646966F8452B9773E6`.
  Renderer reported Vulkan 1.4.341 / NVIDIA GeForce RTX 2070 SUPER. This is one workstation,
  not hardware coverage or a frame-time/performance certification.
- **Evidence:** raw check logs, all four native tour logs, representative unmodified PNGs,
  exact package hash, and critic scope in `evidence/2026-09-26/`. All 56 final PNGs remain
  locally in `build/run3/checked-<resolution>/`. Evidence and Blender sources are excluded
  from player downloads through their `.gdignore` files.
- **Critic verdict:** static readability passes for gallery headers/descriptions, player/hint
  visibility, left-margin inspection, and six-entry enemy association. Still loses to the
  inspected official Into the Breach / Slay the Spire 2 references on battlefield visual noise,
  map legend/presentation, and card-art quality. No whole-game/AAA or shipping-judge pass.
- **Unverified:** human/full-region playthrough, audio listening, physical controller input,
  focus/fullscreen behavior, ultrawide, sustained frame times, and player-path download/install.
  Input and resize evidence here are automated native-window checks. The boss “enemy turn”
  capture can occur after the animation and is not animation-timing proof.
- **Release:** nothing uploaded or published this run. No `.aaa-complete`. Bramblecrown stays
  active, and the forced release remains **2026-10-03 Pacific**.

### Exact next action (Run 4)

1. Implement Glasswood as the next substantial content unit: authored board identity, Blender
   roster, at least six distinct encounters, Lantern Hart elite, and multi-phase Splintered Queen.
   Integrate progression/save tests and import/package evidence before pushing.
2. Add region-specific Cloister shrine choices and strengthen its visual hierarchy (calmer
   peripheral glow/tiles; region-specific map composition). Preserve today's readability gains.
3. Obtain a genuine keyboard/mouse full-region playthrough and listening/controller evidence
   when available; do not substitute screenshot tours for those checks.

Full contract still owed: regions 3–5, Cassia and Thatch with their own card sets, additional
charms/events, Withering tiers, and broad quality/interaction acceptance. There are 34 Wren cards;
each other walker still needs its planned 20-card minimum, irrespective of the overall 60-card floor.

Started: 2026-09-24 (Pacific). Forced release date: Saturday 2026-10-03.

## Toolchain (verified 2026-09-24)

- Godot 4.7.2.stable.official.ed1daf0bf (`C:\dev\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`). Export templates 4.7.2.stable are installed, including `windows_release_x86_64`.
- Blender 5.1.2 (`C:\Program Files\Blender Foundation\Blender 5.1\blender.exe`)
- Butler v15.27.0 (`C:\dev\bayou\dist\tools\butler\butler.exe`). A local login exists, but the **itch account name has not been verified** (see Open issues).
- Python 3.13 with numpy 2.2.5 and Pillow (audio synthesis and card-art contact sheets).

## 2026-09-24 — Run 1 (new game night)

### Done (all pushed on `claude/nifty-hawking-ge8te7`)

1. Steam research and three pitches (`.arcade-agent/pitches.md`). Bramblecrown was selected and recorded in `.arcade-agent/current-game.md`.
2. SPEC / TESTING / PROGRESS handoffs.
3. **Pure rules core** in `scripts/core/`:
   - Hex math, a seeded RNG, combat (grove, thicket/blight tug-of-war, telegraphed intents, locked blight targets, live movement preview, statuses, powers, and charms), and the run (branching map, rewards, market, camp, shrine events, JSON save/load, resume-in-combat).
   - Content: 24 cards (Wren), 6 region-1 enemies including an elite and a two-phase boss, 8 authored encounters, 10 charms, and 5 shrine events.
4. **Blender pipeline** `source-art/build_assets.py` writes 15 models (3 hex tiles, thicket, blight, Grovewalker, 5 enemies + boss, willow, reeds, menhir) as `.blend` and GLB. The rotmoth has a keyframed wing-flap animation.
   - `source-art/render_card_art.py` renders a unique illustration for every card from the game models.
   - `source-art/preview_sheet.py` renders a contact sheet for asset QA.
5. **Godot presentation**:
   - A 3D diorama board with a lighting/fog/glow/SSAO environment, animated growth props, outlined units with team rings, solid intent arrows, pulsing blight-target hexes, and an incoming-damage number.
   - Card hand with hover/select, keyword tooltips, and a hover preview of exactly which hexes change and how much damage lands.
   - Screens: map, reward, camp/shrine/market, deck viewer, run end, a title screen with a live boss diorama, and a pause menu.
   - Keyboard/mouse controls, plus controller bindings (untested).
6. **Audio**: `tools/make_audio.py` synthesizes 14 SFX and 4 looping music beds (original, oscillator/noise based).
7. **Tests**: `tools/check.sh` runs import, headless scene smoke, and `tests/test_runner.gd` (650 checks, including preview-vs-play agreement, save/load, resume, map validity, and full-region autoplay by two bots).
8. **Windows export**: preset "Windows Desktop", embedded PCK, `build/windows/Bramblecrown.exe` (~113 MB, gitignored).

### Evidence

- `bash tools/check.sh` → `ALL CHECKS PASSED` (650 passed, 0 failed) on the last commit of this run.
- The packaged exe ran `--screenshot-tour <dir> --shot-size WxH` at **1280x720, 1920x1080, and 2560x1440**. It exited with code 0 each time and wrote 9 screens per resolution (title, map, combat, targeting, enemy turn, reward, camp, shrine, market).
  - I read the combat, targeting, enemy-turn, map, and reward shots myself at multiple resolutions.
- Balance gauge: the heuristic bot clears region 1 in **2/20 seeds** and usually dies at the Mire Mother (boss HP was reduced 140→124 and brood summons cut this run). The greedy bot clears 0/3. A human should do better; this is **not verified with a human**.

### Critic verdicts (independent read-only critic, packaged screenshots, vs Slay the Spire 2 / Into the Breach)

| Discipline | Verdict at first review | Action this run | Status now |
|---|---|---|---|
| Board / 3D art | parity (ITB) / loses (StS2) | darker palette, foreground props filtered | still loses to StS2: tile material variety is flat |
| Unit readability | loses badly | 1.45x scale, outlines, team rings, warm enemy palette, flying moths | improved, not re-judged |
| Card design | loses | unique Blender-rendered art per card, full-height hand, keyword style fixed | improved, not re-judged |
| HUD / UI | loses | HP plate fixed | **still loses**: no clickable draw/discard piles, no combat relic tooltips beyond badges, unlabeled diamond badge |
| Map | loses | blotches removed, elite icon, legend | still loses: no illustrated map |
| Reward / room screens | loses badly | none | **still loses badly**: text on a dark void |
| Telegraphs | parity (StS2) / loses (ITB) | solid arrows, bigger intent icons on a backing plate, incoming damage number | improved, not re-judged |
| Art-direction coherence | loses | none | still loses: 2D screens vs 3D combat |

No discipline has passed a critic gate, so the game is **not** release-quality.

### Open issues / debt

- **itch.io**: `shoejunk/bramblecrown` was verified through the signed-in dashboard and created as a draft on 2026-09-24. Windows build #2014268 is processed. Public publication is pending explicit approval after automatic review rejected making the draft page public.
- Running the tour through the editor binary logs `ERROR: 1 resources still in use at exit` on quit. It has not been investigated yet (check the packaged log, probably a Label3D/SystemFont reference).
- Audio has not been listened to by a human. The waveforms were generated without errors, and loudness and mix are unverified.
- Controller support is coded (stick hex cursor, A/B/Y, d-pad card cycling) but not tested with a pad.
- Manual resize/fullscreen and a hand-played full run through the packaged build have not been done yet. Only the automated tour was run.
- Content still owed against SPEC: regions 2–5 (4 boards, rosters, bosses), Grovewalkers Cassia and Thatch, ~36 more cards, ~10 more charms, ~7 more events, and Withering difficulty tiers.

### Next action (Run 2)

1. Reward/room screens: render 3D vignette backdrops (campfire, pedlar, hermit/shrine) with the Blender pipeline, or stage them live in Godot with BoardView. Show the reward screen over the dimmed battle board.
2. Combat HUD: clickable draw/discard pile viewers, labeled charm bar with icons, and a Ward overlay on the HP bar. Then ask the critic to re-judge all disciplines with fresh packaged screenshots.
3. Content: Region 2 (Sunken Cloister) with a new board palette, 3–4 enemies, an elite, a boss, 6 encounters, and ~10 new cards.
4. Hand-play one full region in the packaged exe and record the outcome.

## 2026-09-24 — itch.io draft upload

- Re-exported the Windows x64 preset from clean commit `10aa561ee3c33c46927b8ee8c595611373183b72` with Godot 4.7.2. SHA-256 of `build/windows/Bramblecrown.exe`: `E8C2627837E2FEFF9DC1211EB51746214566A3F4F8C5B36BD0A2A8D40C501D89`.
- Rule suite: 650 passed, 0 failed. The exported executable wrote all nine 1280x720 screenshot-tour images; its log recorded tour completion.
- Created https://shoejunk.itch.io/bramblecrown with in-development status, first-region scope, controls, cover/gameplay screenshots, free download pricing, and AI-content disclosure. It remains a **draft**.
- Butler uploaded `build/windows` to `shoejunk/bramblecrown:windows` as version `2026.09.24-10aa561`. `butler status` confirmed processed build #2014268 (upload #19390429).
- Public visibility and a player-facing download/install check remain pending. Automatic approval review rejected saving Public visibility because the request to push a build did not explicitly authorize publishing the page to everyone.

## 2026-09-25 — Run 2 (polish night, Friday; day 2 of 10)

Plan for this run (from Run 1's next action):
1. Room/reward screens get staged 3D backdrops instead of text on a void; reward shown over the dimmed battle board.
2. Combat HUD: clickable draw/discard pile viewers, labeled charm bar with tooltips.
3. Content: Region 2 (Sunken Cloister) board, roster, elite, boss, encounters, new cards.

Housekeeping: stopped tracking Blender `.blend1` backup files (added to `.gitignore`).

### Done (pushed on `dev`)

1. **Region 2: Sunken Cloister** (commit bd0a82e)
   - Blender assets:
     - Tiles: flagstone, broken-pillar, and flooded-bay hex tiles.
     - Props: ruined arch, candle cluster, fallen bell.
     - Enemies: Drowned Novice, Censer Wraith (flying, animated censer swing), Bell Ghoul, and Moss Knight.
     - Elite: Choir of Ash. Boss: The Drowned Abbess (two phases).
   - Content: 6 fights, an elite, and a boss (`clo_*` in `encounter_db.gd`), with a per-region "easy" pool for early floors.
   - New intents:
     - `daze`: the Grovewalker has 1 less energy next turn. It stacks to at most 2, and energy never drops below 1. It shows a bell icon and appears on the HP plate.
     - `shield_allies` and `heal_allies`.
   - Rules change: enemy ward now clears at the start of the enemy phase, so shields given to allies last through the player's turn.
   - `BoardView.THEMES` sets tiles, surrounding props, lighting, and warm candle lights per region. The phase-2 banner uses the boss's name.
   - Enemy plates and floating text are clamped below the encounter title.
2. **Live 3D vignettes on non-combat screens** (commit d0e5167)
   - New `RoomStage` (a SubViewport) stages region-themed tiles, props, flickering lights, and Wren behind the camp, shrine, market, and reward screens. The UI moves to a shaded side panel.
   - New Blender models: campfire, pedlar cart with a beak-nosed merchant, and a wayside altar.
3. **Combat HUD** (commit 2c32b8e): clickable Draw, Discard, and Exhausted pile viewers (A / S / X). The draw pile is shown sorted so its order stays hidden. Each charm now has its own vector icon (`charm_glyph.gd`).
4. **Critic-driven fixes**:
   - The map legend and boss tooltip now name the region's boss.
   - Rest is disabled at full HP.
   - The cloister has its own reward headline and camp text.

### Evidence

- `bash tools/check.sh` → ALL CHECKS PASSED, **919 passed / 0 failed**. The count rose from 650 because of new tests:
  - Region data: fight counts, easy pools, themes, and a reachability flood-fill for every encounter.
  - Every enemy model and theme asset exists.
  - Daze, including its energy floor.
  - Shield and heal allies.
  - Abbess phase 2.
  - Region transition and save/load.
- Balance bot: the smart bot clears region 1 in 2/20 seeds and dies in region 2 (floors 13–14). No full-run wins. This has not been checked with a human.
- Packaged exe: exported with Godot 4.7.2; SHA-256 `25ea1ac53b6fdc9b3f9897a18f9a012153369e02f13c5009faee71fa3eed313c`, which is gitignored.
  - The full tour and the rooms tour both exited with code 0 at **1280x720, 1920x1080, and 2560x1440**, producing 23 screenshots per resolution. The latest log has no ERROR lines.
  - I read these screenshots myself: the region 2 combat, elite, and boss screens; the draw-pile viewer; every room screen in both regions; the 1280x720 market and shrine; the 2560x1440 boss turn; and the post-fix region 2 map and 1280x720 cloister camp.

### Critic verdicts (independent read-only critic; 17 packaged screenshots; vs StS2 / Into the Breach / Monster Train 2)

| Discipline | Verdict | Top complaint |
|---|---|---|
| Board / 3D art | loses | board floats in a black void; no ground plane or fog; too much bloom from candles and crystals |
| Unit readability | **loses badly** | enemy plates overlap models and each other (Abbess, 720p Moss Knight, Rotmoth/Blightling); the Abbess has no readable face |
| Card design | **loses badly** | most art is re-posed Wren; no rarity frames; body text about 9px at 720p |
| HUD / UI | loses | pile viewers added, but the combat title bleeds through the modal; empty portrait panel; text "Menu" button |
| Map | **loses badly** | icon discs on flat parchment, same template for every region (boss name bug fixed) |
| Reward / room screens | loses (was "loses badly") | the Grafter NPC is not staged; charms are text buttons without icons; the camp layout is the same in both regions |
| Telegraphs | loses | no per-hex damage tint; intent icons lack tooltips |
| Art-direction coherence | loses | mixed UI kit; uneven bloom; title boss cropped at 720p |
| Region 2 identity | loses | only combat is region-specific; the map, events, and camp composition are shared |

No discipline passes, so the game is **not** release-quality.

### Open issues / debt

- The plate-overlap system needs a screen-space rail or stacking. This is the top critic item.
- Card art: there are no illustrations yet for any new Region 2 cards; none were added this run. The card count is still 24 of the 60 planned.
- Content still owed: regions 3–5, Cassia and Thatch, about 36 cards, about 10 charms, about 7 events (plus Region 2 event text), and the Withering difficulty tiers.
- Carried over from Run 1: audio has not been heard by a human; controller support is untested; there has been no hand-played full run or manual resize test. The editor-run tour still logs "1 resources still in use at exit". The packaged log is clean.
- itch.io: the page is still a **draft** holding build #2014268 from Run 1. This run's build was not uploaded, because release happens on Saturday 2026-10-03.

### Next action (Run 3)

1. Unit readability: put enemy plates on a stacked screen-space rail with no overlaps. Give the Abbess a face and a candle crown.
2. Region 2 cards: about 10 new Wren cards that use daze and ward counterplay, with Blender art in `render_card_art.py` that uses the new cloister models. Add rarity frames to `card_view.gd`.
3. Illustrated map backdrop per region, with a boss portrait at the top. Stage the Grafter NPC in the shrine vignette. Add Region 2 shrine events.
4. Start Region 3 (Glasswood) if time remains. Rerun the critic on fresh packaged screenshots.
