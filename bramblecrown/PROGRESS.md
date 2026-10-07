# BRAMBLECROWN — Progress
## 2026-10-03 — Run 14 (Pacific Saturday, age 9 days) — FORCED RELEASE ATTEMPT: BLOCKED AT UPLOAD

- STOP absent; branch == origin/dev d602cab. Godot 4.7.2, Butler 15.27.0.
- **Verified:** full gate 3,990 passed / 0 failed; Windows export OK (Bramblecrown.exe, SHA-256
  0ec5bf1d5206eb5ce1f91a56d13adf722f6936e575fce0209b454077efff05db); packaged tour at 1280x720, 1920x1080,
  2560x1440: 15 shots each, exit 0, 0 ERROR lines. I read the title, combat (720p/1080p) and 1440p map shots: they render correctly.
- **Blocked:** `butler push` to shoejunk/bramblecrown:windows was denied by the session's auto-mode permission
  classifier (public-surface action). Not retried or worked around. The itch channel still holds build #2014268
  (2026.09.24-10aa561). NOT uploaded, NOT released, no .aaa-complete.
- **Debt/unverified:** title footer says "Development build"; no hand-played campaign, audio, controller or balance
  check; critic AAA FAIL since Run 10; itch page is Draft.
- **Next:** with explicit user OK (or a Bash allow rule), copy build/windows/Bramblecrown.exe to a clean dir and
  `butler push <dir> shoejunk/bramblecrown:windows`, verify on the page, set page Public, write .aaa-complete.

## 2026-10-02 — Run 13 (Pacific Friday, age 8 days)

- STOP absent; branch at origin/dev b593747. Plan: full gate, Windows export, inspect Withering picker and new
  charm glyphs at 720p/1080p/1440p, fix issues. Saturday 2026-10-03 Pacific is the forced release.
- **Delivered:** Packaged export (Godot 4.7.2) showed the Withering picker overlapping the Back button and bleeding
  into background text at 720p; moved it into a backed 720px panel left of Back, tier 10 text wraps cleanly.
  Added a Withering-10 shot to the run7 tour. Gate **3,990 / 0**; run7 tour at 1280x720, 1920x1080, 2560x1440:
  21 shots each, 0 failures, exit 0, player saves unchanged; I read the three tier-10 picker shots (kept, with
  tour logs, in evidence/run13; other screenshots not committed).
- **Unverified:** no hand-played campaign, audio, controller, balance at any Withering tier, critic, or itch upload.
  Critic state remains AAA FAIL from Run 10.
- **Next (Saturday forced release):** full gate, export, packaged launch + tour, verify itch page `shoejunk/bramblecrown`
  (draft; public visibility needs the user's explicit OK), Butler push `:windows`, player-path verify; write
  `.aaa-complete` only if truly shipped, else record the blocker.

## 2026-10-01 — Run 12 (Pacific Thursday, age 7 days)

- STOP absent; dev synced at 1ad475d. Plan: implement Withering difficulty tiers 0-10 (rules, meta save,
  select UI, tests), then gate and handoff. Forced release Saturday 2026-10-03 Pacific remains.
- **Delivered:** Withering tiers 0-10 (`scripts/core/withering.gd`), stacking: 1 enemies +10% HP, 2 fight gold -20%,
  3 enemies +1 Strength, 4 -8 Max HP, 5 market +25%, 6 elites/bosses +15% HP more, 7 camp heals 20%,
  8 one fewer reward card (min 2), 9 Blight costs 3 HP, 10 enemies +1 further Strength and 50 less starting gold.
  Tier saved in the run (legacy saves load as 0); profile `withering` = highest unlocked tier, a win at the top
  unlocked tier opens the next; picker (-/+) on the Grovewalker select screen.
- **Validation:** full gate (import, three scene smokes, rules) **3,990 passed / 0 failed**, new `test_withering`.
- **Unverified:** the select-screen picker was only parse/compile-checked (headless script mode has no autoloads);
  never seen in a packaged build or screenshot. No balance rerun at any tier, no export, no critic, no itch upload.
  Tier 3+ forecasts rely on the enemy `strength` stat; shown on plates but not checked visually.
- **Next (Run 13, Friday):** export Windows, inspect the picker and new charm glyphs at 720p/1080p/1440p, fix issues,
  then Saturday forced release: full gate, packaged test, itch page check, Butler push to shoejunk/bramblecrown:windows,
  player-path verify, `.aaa-complete` only if all of it truly passes (record debt honestly).

## 2026-09-30 — Run 11 (Pacific Wednesday, age 6 days)

- STOP absent; dev synced at 4223590. Baseline gate 3,435 / 0 before edits.
- **Delivered:** ten new charms (20 total, meeting the SPEC minimum): Dew Cup, Burr Coat,
  Gilded Acorn, Honey Jar, Haggler's Tooth, Carrion Bloom, Bramble Spool, Cartographer's Quill,
  Woven Satchel, Last Bloom. Effects in combat_state.gd/run_state.gd, vector glyphs in
  charm_glyph.gd, a "Last Bloom!" combat float, new test_new_charms.
- **Validation:** full gate (import, three scene smokes, rules) **3,468 passed / 0 failed**.
- **Unverified:** no packaged export or native screenshots this run, so the new glyphs and float
  text have not been seen in the built game; no balance rerun with the new charms; no critic run.
  Toolchain versions not re-recorded this run (Run 10 installs used by check.sh).
- No itch.io upload or page change; .aaa-complete absent. Forced release Saturday 2026-10-03 Pacific.
- **Next (Run 12):** export Windows and inspect new glyphs in market/reward/HUD at three
  resolutions; genuine player-input campaign route; Withering tiers; then the Saturday
  forced-release procedure (full gate, export, packaged test, page check, Butler push, player-path verify).

## 2026-09-29 — Run 10 checkpoint (Pacific Tuesday, age 5 days)

- STOP absent; clean `dev` at ff4e0d6, fast-forward pull confirms current remote state.
- Godot `4.7.2.stable.official.ed1daf0bf`, Blender `5.1.2`, Butler `15.27.0` verified;
  matching Windows x64 templates and embedded-PCK Windows Desktop preset present.
- Official stable Godot CLI guide checked. Baseline import/scene/rules: **3,122 / 0**.
- Butler verifies shoejunk/bramblecrown:windows still build #2014268 / 2026.09.24-10aa561.
  No release gate; forced release remains October 3 Pacific. No upload/publication planned.
- Scope: aimed Kindle for five formerly self-targeted burn cards, exact preview/rules
  regressions, packaged input/visual verification. Aim at a Grove hex to burn nearest to it;
  target Cassia for the existing farthest-first automatic order. Enemy-targeted cards and
  Ember Saint retain automatic order. Preserve off-Grove draw/movement utility via self target.
- Main runner owns all edits/Git. Separate read-only critic will compare final native evidence.
- Next: implement, test, export, inspect three native resolutions, then retain honest handoff.

### Run 10 working unit

- Aim Kindle implemented on Flashburn, Smokescreen, Cinderstep, Firestorm and Tinderbox.
  Connected Grove aim burns nearest first; self aim preserves automatic order/no-fuel utility.
  Enemy-targeted and turn-start Kindle retain previous behavior. Text/local release copy updated.
- Fixed stale Heat forecast when hover leaves valid targets; cancellation clears it.
- Full installed-engine gate: **3,435 passed / 0 failed**. Cassia Blender source reopened:
  two meshes, flame_flicker frames 1-25. No asset regeneration or application changes.
- First corrected Windows export passed all three resolutions (20 captures each), saves unchanged.
  Viewport mouse aim/click and keyboard select/cancel exercised; ash scars match forecast.
- Retained initial rule failures (new validator/fixture assumptions) and failed native log
  (synthetic Escape missing physical key code). Corrected harness sends the bound physical key.
- Gameplay unit pushed as 959270f. Separate critic accepts bounded unit, retains **AAA FAIL**.
- Critic found hex tooltip following the old OS pointer and covering the enemy rail at 1440p.
  Fixed anchor to hovered hex and constrained panel away from enemy rail/hand; full gate and
  final package recapture pending. Earlier screenshots do not certify this final tooltip fix.


### Run 10 final result and next action

- **Delivered:** five Aim Kindle cards with deterministic spatial burn choice and exact previews;
  automatic self aim remains compatible, including no-fuel utility. Card text, keywords, controls,
  SPEC, tests and future itch copy updated. Heat previews clear correctly. Hex tooltips follow
  the aimed hex and stay out of enemy panels/hand rather than following the old OS pointer.
- **Final validation:** import, title/combat/map smokes and rules **3,435 passed / 0 failed**;
  1,800 enemy forecasts, drift 0. Installed Godot Windows x64 export passes. Twenty staged native
  captures at each of 1280x720, 1920x1080 and 2560x1440: exits 0, zero failures/errors, player-file
  hashes unchanged. Main runner inspected all 60 final images via 15 contact sheets; critic
  inspected final aimed frames at all three resolutions. Viewport synthetic mouse/keyboard
  assertions prove aiming, cancellation, single cast, exact ash scars and nonoverlapping tooltip.
- **Package:** build/windows/Bramblecrown.exe, embedded PCK, **122,464,232 bytes**;
  SHA-256 `5B0BD7D188F8DA89E1996313FFF653F37EEAE83DD1F50D77AC1DE1270B720447`.
  Five original final 1080p release screenshots and manifest refreshed. Source-art/evidence/release
  paths excluded from export. Game code pushed in 959270f and e6a3322; final handoff follows.
- **Blender:** existing Cassia source reopened with installed Blender 5.1.2, two meshes and
  flame_flicker frames 1-25. No new art this run. Native animation checks still pass.
- **Critic:** bounded aimed Kindle and tooltip fix PASS. **AAA FAIL / OURS LOSES** persists versus
  Into the Breach: terrain/state differentiation, small/scattered HUD information, objective
  prominence and tooltips obscuring board content. No discipline-wide or shipping-judge pass.
- **Limits:** synthetic staged input is not a player-completed campaign. No human enjoyment,
  physical controller, audio listening/mix, focus/fullscreen, sustained performance, extra hardware,
  4K/ultrawide or player-facing itch download/install verification. No release this run.
- **Evidence:** evidence/2026-09-29-run10; final-* sheets/logs identify the final package;
  verified-* sheets precede the tooltip fix. Initial failed rules/input logs retained explicitly.
  Full-resolution raw images remain under build/run10/final-<resolution>/.
- **Release state:** Butler read-only check confirms windows #2014268 / 2026.09.24-10aa561;
  page Draft was last browser-verified in Run 9, not rechecked in a browser here. No page edits,
  upload, publication or .aaa-complete. Forced release remains **Saturday 2026-10-03 Pacific**.

Exact next action for Run 11:
1. Start a genuine player-input campaign route in the packaged build; capture actions and the
   first reproducible failure before balancing. Keep staged fixtures and high-HP bots separate.
   Current balance gauges: Wren 3/20 region-1 clears, zero full-run wins; Cassia 1/10 region-1 clears.
2. Complete remaining authored SPEC scope: Thatch with twenty cards, ten more charms, Withering
   tiers. Prioritize meaningful progression and tactical readability over additional portrait polish.
3. Before Saturday, obtain audio/controller/focus/checkpoint evidence and resolve functional
   completion blockers. Apply release copy/screenshots only with its matching gated upload;
   then verify actual player-facing download/install. Do not reuse an older package manifest.


## 2026-09-29 — Run 9 checkpoint (Pacific Tuesday, age 5 days)

- STOP absent. Clean local `dev` fast-forwarded from `4f65d1c` to remote `b64f430` before edits.
  The newer Run 8 handoff supersedes the old local Run 4 plan.
- Installed Godot `4.7.2.stable.official.ed1daf0bf`, Blender `5.1.2`, Butler `15.27.0`;
  matching `4.7.2.stable` Windows x64 template and `Windows Desktop` embedded-PCK preset verified.
  Checked the official stable Godot command-line guide. No applications installed or upgraded.
- Baseline full import/scene/rules gate passes: **3,122 passed / 0 failed**.
- Authenticated browser confirms `shoejunk/bramblecrown` is **Draft** with the September 24
  first-region description and download. Butler confirms Windows build `#2014268`, version
  `2026.09.24-10aa561`. No release gate passed; forced release remains 2026-10-03 Pacific.
- Bounded scope: prepare next-build page copy, controls, honest system/quality limits and fresh
  screenshots; revise Cassia's hooded silhouette into an uncovered flame crest and split mantle.
  Main runner owns all edits and Git; separate read-only critic will inspect native evidence.
- Keep future-build page copy local until that build is released: the current page must continue
  describing its actual first-region download. No upload/publication this run.
- Next: author release materials and Cassia model; import, reopen Blender source, export Windows,
  inspect 720p/1080p/1440p tours and obtain harsh independent comparison. Aimed Kindle remains next.

### Run 9 working unit

- Revised Cassia model, fifteen matching card illustrations and six corrected close-up cameras;
  enlarged/brighter starting-deck text and accurate Heat pitch. Original Blender sources retained.
- Packaged regression exposed a pre-existing static player flame: enemies started animations,
  players did not. Added player animation startup and native start/advancement assertions.
- Final code/art full gate: **3,122 passed / 0 failed**; Windows export clean. Corrected package
  passes 19 staged 720p captures with clean exit and unchanged normal saves. Larger sizes pending.
- Independent critic accepts bounded silhouette/readability and the six corrected original art
  frames; **AAA FAIL / OURS LOSES** remains for posing/materials/repeated compositions.
- Next: finish final 1080p/1440p capture review, retain logs/manifest/page copy and push the handoff.

### Run 9 final result and next action

- **Delivered:** Cassia's distinct flame crest, exposed face, split coat/boots, tighter mantle,
  asymmetric offhand, reduced flame glare; fifteen matching card renders, six reframed source
  cameras; readable starting deck and truthful Heat text. Fixed player animations not starting.
- **Release preparation:** `release/itch-page.md` supplies next-build description, controls,
  checkpoint-save explanation and measured hardware limits. Four original 1080p screenshots,
  captions and exact SHA-256 manifest are ready locally. No invented minimum hardware claims.
  The existing draft page still describes its actual September 24 first-region download.
- **Final validation:** installed Godot import, scene smokes and full rules **3,122 / 0**;
  clean Windows x64 export. The final executable ran 19 staged captures at each of 1280x720,
  1920x1080 and 2560x1440: all exits 0, zero failures/errors, player-file hashes unchanged.
  Animation start/advancement assertions pass with imported `flame_flicker`. Main runner read
  all 57 images via twelve contact sheets plus representative originals; critic reviewed all
  three select layouts, combat views and the six final original card illustrations.
- **Blender:** final Cassia source reopens with 8,278 body vertices + 41 flame vertices,
  materials, body dimensions 0.890 x 0.869 x 1.703 and `flame_flicker` frames 1-25.
  Representative Ember Lash source reopens with 48 objects, camera and 396x224 render settings.
- **Package:** `build/windows/Bramblecrown.exe`, embedded PCK, **122,461,944 bytes**;
  SHA-256 `F7F68BD14B5F10D22859FDD82F206BC2DB4E0CFABB2BE681183EE475714CF6E1`.
  This supersedes intermediate Run 9 package hashes. The export contains no source-art,
  release-preparation or evidence paths. Raw logs/failed animation trace and visual evidence
  are retained in `evidence/2026-09-29-run9/`; full raw PNGs remain in `build/run9/verified-*`.
- **Critic:** bounded silhouette/readability and corrected card framing pass. Original broad
  no-clipping claim missed art crops; six cameras were corrected and final PNGs re-read.
  **AAA FAIL / OURS LOSES** remains: expressive posing/materials, repeated card compositions,
  room glare and wider gameplay acceptance. No independent shipping-judge pass.
- **Limits:** staged test routes, not a complete player-driven campaign. Manual keyboard/mouse,
  focus/fullscreen, audio listening, physical controller, sustained performance, additional
  hardware, 4K/ultrawide and player-path download/install remain unverified this run.
- **Release:** no upload, page edit or publication; no `.aaa-complete`. Bramblecrown stays active.
  Authenticated Draft page and Windows build #2014268 verified. Forced release: **2026-10-03 Pacific**.

Exact next action for Run 10:
1. Implement aimed Kindle with exact preview-versus-resolution and save/progression regressions;
   keep the current burn order as compatibility behavior where needed. Do not silently change
   the spatial rules without updating card text, controls, tests and release copy.
2. Obtain a genuine five-region player-input route and audio/controller/focus/save evidence
   before Saturday; diagnose the first reproducible failure rather than claiming staged success.
3. Reuse `release/` materials, recapturing if the package changes. Apply copy/screenshots only
   with the matching upload after the release gate, then verify the actual download/install.

Full SPEC remains owed: Thatch with at least twenty cards, ten more charms, Withering tiers,
balance and all discipline quality acceptance. Current authored content: five regions, thirty
normal fights, five elites, five bosses, two walkers, fifty-four cards, thirteen events, ten charms.

## 2026-09-29 — Run 8 checkpoint (Pacific Tuesday, age 5 days)

- STOP absent; started at `dev` 145b22b. Forced release remains Saturday 2026-10-03 Pacific.
- **Done:** walker-select screen. Title "New Run" opens a two-panel screen: live rotating 3D model per
  walker, name, title, HP, pitch, grouped starting deck with card text, lock condition, Begin button
  (locked walkers show the unlock text and a disabled button). Tour updated to drive it.
- **Evidence:** `tools/check.sh` -> 3,122 passed / 0 failed (re-run after the last font edit).
  Packaged export (Godot 4.7.2) and `--tour-only run7` at 1280x720 and 1920x1080: exit 0, no ERROR
  lines; I read the locked and unlocked select screenshots (`evidence/2026-09-29-run8/`). The final
  starting-deck font change (19 to 22) was not re-shot, and 2560x1440 was not re-run this run.
- **Not done:** aimed Kindle, a distinct Cassia silhouette, itch page text and screenshots (no
  Butler or itch work this run), and no critic pass. No discipline has passed; the forced Saturday
  release still applies.
- **Next (Run 9):** release prep first (itch page copy, screenshots, system requirements; page
  visibility needs the human), then aimed Kindle if time remains.

## 2026-09-28 — Run 7 checkpoint (Pacific Monday 02:01, age 4 days)

- STOP absent; worktree at remote `dev` `4dc1ecc` (Run 6 final). Work pushes to `dev`.
- Polish night: forced release remains Saturday 2026-10-03 Pacific; no quality gate has passed.
- Bounded plan: (1) Cassia, the second Grovewalker ("burns her own grove for burst"), with her own
  20-card set, starter deck, progression unlock, walker select on the title screen, and
  rules/save tests; (2) a stacked forecast label on the player's hex (Run 6 critic item) if time
  remains.
- Main runner owns every file and Git this run.

### Run 7 result: Cassia, the Ashwalker (second Grovewalker)

- **Rules:** Kindle (burn your own Grove, farthest first, never your hex), Heat (per turn,
  scales her cards), Scorch (damage over time). Previews simulate Kindle inside a card, so the
  burned hexes, Heat and damage shown before a play are exact.
- **Content:** 20 Cassia cards with upgrades (4 starter, 7 common, 7 uncommon, 2 rare; three
  powers). Per-walker reward pools. Shrine events swap Wren card grants for Cassia counterparts.
- **Progression:** `WalkerDB` (new file); the profile keeps the best boss count, one boss kill
  unlocks Cassia, and the combat victory flow shows an "unlocked" banner. The title screen lists
  both walkers. The walker survives save/load; the combat, room and HUD names follow it.
- **Art:** original Blender model with an animated brazier flame; 20 rendered card illustrations
  (fire tuned so AgX keeps it orange, not white); ember ring and light on the board; grey-ash scar
  decals on kindled hexes (first try sat inside the tile, then read as a red danger tile; fixed).
- **Bug found by the tour:** the room top bar said "Wren" during a Cassia run. Fixed.
- **Gate:** `tools/check.sh` → 3,122 passed / 0 failed (was 2,754).
- **Balance gauge (bots, not humans):** Cassia bot 1/10 region-1 clears after the critic fixes
  (2/10 before); Wren smart bot 3/20. The bot does not aim Kindle or plan Heat, so this
  understates her; human balance is unverified.
- **Package (final, after critic fixes):** `build/windows/Bramblecrown.exe`, 122,324,680 bytes,
  SHA-256 `43B0C6B11ACCC93E8576868B9186C9111A9905AF41A9A769BCD685A77B0D061F`. The final
  `--tour-only run7` passed again at all three sizes (19 images each, 0 failures).
- **Tour:** `--tour-only run7` passed at 1280x720, 1920x1080 and 2560x1440 (19 images each,
  0 failures, saves unchanged). The `run6` tour still passes at 1280x720 (23 images, 0 failures).
  The main runner read the three contact sheets and eight full-size shots; sheets, originals,
  the card-art sheet and the `cassia.blend` reopen log are in `evidence/2026-09-28-run7/`.
- **Not verified:** human play, audio, controller, fullscreen, 4K, a real (non-staged) boss-kill
  unlock.

### Run 7 critic (independent, read-only; packaged screenshots vs Slay the Spire 2, Monster Train 2, Into the Breach)

| Discipline | Verdict | Top complaint |
|---|---|---|
| Character identity / silhouette | loses badly | same hooded-stump body plan as Wren; a grey blob at board scale |
| Card design / mechanic depth | loses | Kindle picks hexes automatically (no spatial choice); Heat never carries over; Scorch was a separate plan |
| Card art | loses badly | about 12 of 20 cards are the same figurine pose; three shield cards look alike |
| Board feedback for Kindle/Heat | parity-minus | burn preview and Heat forecast good; no final-damage number on the enemy plate |
| Character-select UI | loses badly | text buttons only; no portrait, pitch, starter deck or relic preview |
| Balance / decision density | loses | one Heat source in the starter; dominated duplicates (Tinderbox, Ash Sprout) |

Fixed after the critic (not re-judged): the starter deck swaps an Ashen Guard for Ember Lash (two
Kindle cards from turn 1); Ash Sprout is now an aimed 0-cost grow; Tinderbox is Kindle 3, Draw 2;
Ashfall adds 1 Scorch per Heat. No discipline passes, so there is no quality release.

### Exact next action (Run 8)

1. **Aimed Kindle** (the critic's top item): let the player click which Grove hexes burn, or
   give Kindle cards a line or cone origin. Burned ash should leave a lasting effect (for example,
   enemies that enter ash gain Scorch). Add one card that keeps Heat into the next turn. Keep the
   exact preview tests.
2. **Character select screen**: large staged model per walker, a one-line pitch, the starter deck
   and a lock condition. Also, a distinct Cassia silhouette (flame hair or mantle, not Wren's cowl).
3. **Release prep before Saturday 2026-10-03**: itch page text, screenshots and system
   requirements. Recheck the draft page. Do not start Thatch unless the rest is done.

Card art debt: re-stage Cassia illustrations so each has its own composition (no repeated
figurine pose, no white-ring template).

## 2026-09-27 — Run 6 checkpoint (Pacific Sunday 09:05, age 3 days)

- STOP absent; worktree at remote `dev` `670cf3c` (Run 5 final). Work pushes to `dev`.
- Polish night: forced release remains 2026-10-03 Pacific; no quality pass exists for early release.
- Bounded plan: (1) Region 5 Crown of Thorns — six authored fights, The Last Gardener elite,
  two-phase Withered Crown boss, original Blender board/roster assets, and a real five-region
  campaign victory replacing the development continuation screen; (2) the HUD items Run 5 named
  (Your Turn banner placement, clipped card text) if time remains.
- Main runner owns every file and Git this run.
- Next action: read region/encounter/enemy data paths, then author Crown of Thorns.

### Run 6 working unit: Crown of Thorns (region 5 of 5)

- **Content:**
  - Six fights, The Last Gardener elite and the two-phase Withered Crown.
  - Thornling, Briar Knight and Withered Herald, plus returning champions from earlier regions
    (Prism Stag, Husk Brute) in two fights.
  - Encounter contract met: 30 fights, 5 elites, 5 bosses.
  - Clearing the Crown is a real campaign victory ("The Crown Is Replanted" with a 3D finale).
    It replaces the development continuation screen.
- **New rule, receding thorn walls (`thorns`):**
  - Telegraphed like a cave-in. Standing on a mark costs 5 HP and keeps that hex open.
  - Walls count down at the start of every enemy phase and recede before enemies move.
  - Every wall shows a countdown number.
  - Authored staggered walls let mazes open lane by lane.
  - Walls never split the board and respect the 40% cap.
- **Art:** twelve original Blender models (4 tiles, 3 props, 5 enemies; animated diadem). After
  native inspection: greyed the ground (it read orange), gave the sap an amber glow (it read as
  black holes, then as lava), and moved the finale Grovewalker off the Crown's face.
- **HUD:** the turn banner moved into a band under the encounter title. The tour now asserts it
  never covers an enemy (Run 5 critic item).
- **Gate:** 2,003 passed / 0 failed. Forecast drift 0 of 1,800 (was 1,461 before the Crown fights).
- **Package:** `build/windows/Bramblecrown.exe`, 120,613,672 bytes, SHA-256
  `FAF5268F0BEEE4FEC923349FE092D6C254B0BC1DDDFC1FD77BF808E57DA2D06F`.
- **Tour:** `--tour-only run6` passed at 1280x720, 1920x1080 and 2560x1440. 23 images each,
  0 failures, player saves unchanged. The main runner read all 69 images, through 12 contact
  sheets plus representative originals. Evidence is in `evidence/2026-09-27-run6/`.
- **Blender:** `withered_crown.blend` (`diadem_turn`, frames 1-61), `hex_thornwall.blend` and
  `last_gardener.blend` reopen with the expected meshes and materials.
- **Limits:** balance is unverified (the bot still clears Marsh in 2 of 20 seeds). The victory
  screen is staged.

### Run 6 final result and next action

- **Region-specific shrine events:** eight new ones, two each for Cloister, Glasswood, Ironroot and
  Crown. That makes 13 events, meeting the 12-event contract. Region events are offered first in
  their region and never appear elsewhere.
- **Map fix (all regions):** node types were purely weighted, so a map could lack an elite (and
  its charm), a shrine or a pedlar. The critic found the Crown map had no elite. Every map now
  guarantees one of each, tested over 40 seeds x 5 regions.
- **Critic-driven fixes:**
  - Thornling scale 1.25 and a larger bone mask.
  - Briar Knight scale 1.3 with gold plate and helm, so it no longer blends into the walls.
  - Boss phase 2 plays its banner and a transformation: the model swells 18% and a pulsing
    ember-violet light wakes inside it (all bosses).
  - Each thorn mark shows a translucent ghost of the wall that will rise.
  - The tour no longer shows a 994/72 HP artifact (the staged max HP is now set too).
- **Gate:** 2,754 passed / 0 failed. Forecast drift 0 of 1,800.
- **Package:** `build/windows/Bramblecrown.exe`, 120,619,464 bytes, SHA-256
  `DBD30E439C534E29D8703888BE314C5D4218538BBD3C8506A370DD0B5A5167A7`.
- **Tour:** the final `--tour-only run6` passed at 720p, 1080p and 1440p: 23 images each,
  0 failures, saves unchanged. It now also asserts the ghost walls and the phase-2 light.
  - The main runner read all 69 images of the previous pass through contact sheets. For the final
    pass it read the changed telegraph and phase-2 shots at each size.
  - Sheets and representative originals are in `evidence/2026-09-27-run6/`.
- **Critic** (independent, read-only; one round, on the pre-fix build; vs Into the Breach and
  StS/Monster Train 2):
  - Thorn telegraph: loses badly.
  - Board art/region identity: loses badly.
  - New-enemy readability: loses.
  - Boss presentation: loses badly.
  - HUD/banner: parity.
  - Victory screen: loses.
  - Encounter variety: loses.
  - Its top fixes 1 (tour HP artifact only; see below), 2 (elite on map), 4 (phase-2 transition)
    and part of 5 (scale and rim) were applied. They have **not** been re-judged.
  - No discipline passes, so there is no quality release.
- **Remaining critic items:**
  - Ghost walls are faint at 1440p.
  - Floating "-N" labels overlap (for example "-11/-5"); the forecast should be one stacked label.
  - Crown fights share one look: no boss-arena set piece, no lighting change for elite or boss.
  - Every encounter uses the same player-bottom, enemies-top layout.
  - The boss and Gardener mark the starting Thicket on turn 1.
  - The victory screen lacks a run summary, score and unlocks. Its zero stats are from the staged
    tour, not a bug.
  - The hand covers the bottom row of hexes.
- **Not verified:** human play, audio listening, a physical controller, fullscreen/focus,
  4K/ultrawide, sustained performance, other hardware, a genuine (non-staged) five-region win.
- **Release:** nothing uploaded. No `.aaa-complete`. Forced release remains
  **Saturday 2026-10-03 Pacific**. itch.io was not rechecked; the last recorded state is a Draft
  page with build #2014268.

Exact next action for Run 7:
1. Ask the critic to re-judge the final Run 6 package, then fix its top two items. Likely:
   - A stacked forecast label on the player's hex.
   - A distinct boss-arena and elite presentation for the Crown.
2. Victory/defeat summary: regions cleared, path and score. Then do a real bot or keyboard run
   into the Crown to check balance on the new region. Tune turn-1 thorn marks on starting Thicket.
3. Before Saturday: Cassia (at least 20 cards) is the largest missing contract item. Scope it
   honestly. Otherwise put release prep (itch page text, screenshots, system requirements) ahead
   of new content on Run 7 or 8.

Full remaining contract:
- Cassia and Thatch (at least 20 cards each), with progression unlocks.
- Charms (10 of 20).
- Withering tiers 0-10.
- Human balance and discipline acceptance.

Content now: 30 fights, 5 elites, 5 bosses, 34 Wren cards, 10 charms, 13 events.

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

## 2026-10-03 - Authorized local completion test: startup (Pacific Saturday)

- Pacific start: Saturday 2026-10-03 15:00; marker started 2026-09-24, age 9 days. Forced Saturday completion applies; no new polish.
- STOP absent. Initially clean documented dev at 1ad475d. Cached origin/dev five commits ahead (50a0aa7); no pull/reset/commit/push. Live ls-remote blocked by sandbox network (127.0.0.1:9); remote freshness unverified.
- No Godot, Blender, Bramblecrown or bash process at startup; parent reports prior read-only task terminal. Several Codex host processes exist; detailed process query denied by OS. No runner lock in .arcade-agent. This selected LOCAL task does not recursively route or touch automations.
- Godot 4.7.2.stable.official.ed1daf0bf; Blender 5.1.2 (ec6e62d40fa9); matching 4.7.2.stable Windows release x86_64 template present. Existing Windows Desktop preset: x86_64, embedded PCK. Git Bash present.
- Read local PROGRESS, SPEC and TESTING. Official Godot CLI guide checked: https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html
- Plan: complete existing gate, fresh isolated Windows export, native regression screenshots and archive validation; require genuine functional completion evidence before .aaa-complete. Staged victory/high-HP bots do not prove campaign completion.
- Computer-use skill read, but node_repl not exposed in selected environment; genuine UI route/focus validation may remain blocked. No cloud_threads tools exposed here; parent owns Desktop-Joe routing/activity/reporting.
- Main runner owns this run's new evidence/build files and appended handoffs. Preserve historical logs/source work.

### 2026-10-03 passing gate checkpoint

- Full Git Bash gate exit 0: 3,990 passed / 0 failed; import and title/combat/map smokes pass. Raw logs retained in evidence/2026-10-03-local-completion/check-logs. Initial sandbox Bash failure retained separately.
- Authorized read-only live remote check confirms origin dev 50a0aa7e97e9582958415e748066765704130e8a; local remains 1ad475d, five commits behind. Detailed process inspection found only this run's game gate, Codex hosts, and a separate repository session; no competing game writer identified.
- Blender 5.1.2 reopened Cassia: two meshes, flame_flicker action, materials and dimensions recorded; exit 0. No assets edited.
- Next: export fresh local package and run native regression captures. Genuine campaign completion remains unproven.


### 2026-10-03 packaged Cassia checkpoint

- Fresh Windows x64 export succeeded in build/local-2026.10.03-1ad475d/windows. Executable 122,471,712 bytes; SHA-256 2478FDEBB872C906CD5C511836A617A787FDFF07C010B4FC683940695F2470AE. PE 0x8664 and embedded GDPC footer verified.
- Existing run7 tour passed at 1280x720, 1920x1080, 2560x1440: 20 images each, exit 0, zero failures, normal saves unchanged. Main runner inspected all 60 via contact sheets. Small/low-contrast combat text remains polish debt; no functional layout blocker observed in these fixtures.
- Representative Crown source reopened with Blender 5.1.2: two meshes, diadem_turn action, materials/dimensions logged, exit 0. Native final-region and extracted-archive checks in progress.
- Versioned candidate archive created with exact-build README, extracted executable hash matches. This is not yet a completion gate pass.


### 2026-10-03 final local test result - completion BLOCKED

- Full gate: 3,990 passed / 0 failed; native run7 and run6 tours at 720p/1080p/1440p: 129 screenshots total, all visually inspected, zero assertions/errors, six exits 0 and player saves unchanged. No runtime source/art edits.
- Extracted ZIP normal native startup (240 frames): exit 0, no errors, normal run/profile/settings SHA-256 unchanged. This validates startup and engine-controlled shutdown, not the normal user save/quit/relaunch/Continue route.
- Package: build/local-2026.10.03-1ad475d/windows/Bramblecrown.exe (122,471,712 bytes), SHA-256 2478FDEBB872C906CD5C511836A617A787FDFF07C010B4FC683940695F2470AE.
- Archive: build/local-2026.10.03-1ad475d/Bramblecrown-2026.10.03-1ad475d-windows-x64.zip (52,287,795 bytes), SHA-256 91FD3283C930A78EE80891350CFA2D59D8225BD6A0CFCFCF87D893E7DE480780. Extracted EXE hash matches. Existing build/windows preserved.
- Short tour FPS mean/range: 720p 55.5/41-61; 1080p 54.0/35-61; 1440p 51.9/26-60 on RTX 2070 SUPER. Capture/loading included; not sustained performance or minimum requirements.
- BLOCKER: node_repl desktop-control API not exposed in selected child. Genuine five-region player-input completion, normal save/relaunch and OS focus/fullscreen acceptance remain unverified. Staged victory/high-HP fixtures cannot pass that gate. Bot reports 2/20 region-one clears and zero full-run wins, not proof of unwinnability.
- Local dev remains 1ad475d, five commits behind verified remote 50a0aa7; package lacks newer Withering work. No unauthorized pull. Thatch/cards and historical AAA/visual polish debt remain. Audio listening, controller, 4K/ultrawide, other hardware and enjoyment unverified. No new critic/shipping-judge pass claimed.
- .aaa-complete NOT WRITTEN; current-game.md unchanged and Bramblecrown remains active, original start date retained. No automations, uploads, publication, commits, pushes or separate repository changes.
- Exact evidence and next action: evidence/2026-10-03-local-completion/RESULT.md and package-manifest.json. Continue acceptance on this exact extracted package with supported local computer-use or human play; fix reproduced functional blockers only. Rebuild/revalidate after source edits, and grant marker only when required functional evidence exists.

## 2026-10-03 - Explicitly authorized sync, polish and local release packaging

- New user instruction authorizes pulling latest dev and polishing this run, superseding prior no-pull/no-new-polish limits. No publication/upload/commit/push or scheduler changes.
- STOP absent; no Godot/Blender/game process at startup. Pacific Saturday 16:03; scheduled 23:00 run is later. No overlapping Bramblecrown writer observed. Separate checkout and UI left alone.
- Fast-forwarded 1ad475d to live origin/dev 50a0aa7e97e9582958415e748066765704130e8a. Git stopped on dirty PROGRESS; backed up exact original/local appendix in evidence/2026-10-03-release/sync-preservation, lifted only known own appendix, pulled, reattached byte-for-byte. All prior test source/evidence/package preserved.
- Godot 4.7.2.stable.official.ed1daf0bf and Blender 5.1.2, matching Windows template and existing embedded-PCK Windows Desktop x64 preset retained. Withering tiers/picker now present locally.
- Supported tools re-inspected: this child still exposes no node_repl or cloud_threads desktop-control capability. Do not route through custom UI helpers or claim physical-input/focus/playthrough evidence. Complete independent engine/native checks and retain exact remaining acceptance gaps.
- Main runner owns edits; independent release_critic owns no files and performs no Git inspection. Plan: fix two or three material gameplay/readability/flow issues, full gate and native inspection, independent final judgement, clean versioned extracted-package validation and ZIP/handoffs. No fake .aaa-complete.

## 2026-10-03 local release continuation: functional unit passed

Authorized dev sync remains at 50a0aa7e97e9582958415e748066765704130e8a.
Fixed full-health/fully-upgraded camp escape; UI and healing now share the Withering-aware rule. Added cancellable saved-run replacement and abandon confirmations, truthful combat checkpoint quit, deliberate tier-zero difficulty with cumulative penalty help, malformed checkpoint rejection and a Continue error message. Increased enemy rail text and backed the combat preview. Added native isolated UI fixtures and 87 rule checks. Final gate: 4077 passed / 0 failed; import and title/combat/map smokes pass (`evidence/2026-10-03-release/final-gate.log`). One earlier run caught noisy JSON.parse_string failure output; parser recovery was corrected rather than masking the gate.

Godot 4.7.2.stable.official.ed1daf0bf; Blender 5.1.2 ec6e62d40fa9, installed Windows release template 4.7.2.stable. Fresh candidate application version 0.1.1 (PE 0.1.1.0); package/export/native verification next. Initial independent critic: RELEASE HOLD / AAA FAIL. No `.aaa-complete` yet; genuine campaign, physical inputs, focus and normal disk-save acceptance remain unverified, and Thatch remains absent from the SPEC.


## 2026-10-03 Pacific — local 0.1.1 candidate packaged; completion remains held

Dev synchronized to 50a0aa7e97e9582958415e748066765704130e8a under explicit continuation authorization. Prior local handoffs and evidence preserved; source fixes remain uncommitted. No other project writer observed; STOP absent. Original Saturday age condition applies (started 2026-09-24, age nine), but no unsupported functional-completion claim was granted.

Completed: camp escape and Withering-correct healing; cancellable replacement/abandonment with Cancel focus and modal keyboard isolation; truthful checkpoint quit; malformed checkpoint rejection/recovery; deliberate tier-zero difficulty/cumulative help; enlarged enemy rail and backed preview. Application 0.1.1 / PE 0.1.1.0. Godot 4.7.2.stable.official.ed1daf0bf, Blender 5.1.2 ec6e62d40fa9, matching installed 4.7.2.stable Windows template. Representative Cassia, Withered Crown and campfire .blend sources reopened; Godot import/export and packaged material/animation assertions pass. No art source was changed.

Full gate: 4077 passed / 0 failed, import and title/combat/map smokes pass. Nine final native processes (release, run7, run6 at 1280x720 / 1920x1080 / 2560x1440) exit zero; all 165 images inspected. Extracted ZIP copy passes release route (11 more inspected images) and normal 240-frame startup/shutdown, both exit zero; normal run/profile/settings hashes unchanged. Actual Vulkan Forward+ on RTX 2070 SUPER; minimum hardware, sustained FPS, listening and physical controller remain unverified. Screenshot routes are staged/synthetic, not genuine campaign completion.

Package: `C:\dev\tandem_tales\bot-crafted-games\bramblecrown\build\local-0.1.1-2026.10.03-50a0aa7\Bramblecrown-0.1.1-rc1-2026.10.03-50a0aa7-windows-x64.zip` (50934803 bytes), only Bramblecrown.exe and README.txt; archive CRC/notes/hash checks pass.
ZIP SHA-256: `8421F8AACBAA58F3C32797ECEA0BEDDB482F36F7A295C61F0AACBE2ECC1CE507`.
EXE: 122488128 bytes; SHA-256 `877190B88A06866A241DA7728ED8D70F11288488A954E30EA5A7F5AA5FCDA376`.
Durable evidence, exact changed-source snapshot, patch, manifest, package notes, native logs/images and independent verdict: `bramblecrown/evidence/2026-10-03-release/`.

Independent read-only shipping critic: RELEASE HOLD / AAA FAIL. Targeted changed UI review and package consistency pass; genuine five-region campaign, normal packaged save/quit/relaunch/Continue, OS focus/fullscreen and physical inputs remain unverified because this child has no supported desktop-control API. Thatch remains absent from the full SPEC; art/readability/tooltip occlusion remain substantive polish debt. `.aaa-complete` remains absent and current-game.md remains active Bramblecrown. Nothing uploaded/published; no commits/pushes or automation/budget changes.

Exact next action: use a local execution session with supported desktop control (or human acceptance) to play a genuine five-region route and test the extracted candidate's normal save/quit/relaunch/Continue, focus/fullscreen and controls. Preserve player data. Record the route and fix actual blockers; resolve missing SPEC content/critic findings before claiming quality completion. Do not start another game or publish this candidate while the hold remains.

## 2026-10-03 Pacific 19:45 - authorized map artwork improvement

User requests image-generated map art. STOP absent; no Godot/Bramblecrown processes at startup. Main runner owns map_scene.gd, new assets/textures/map-art and focused screenshot fixtures/evidence; existing dirty source and prior immutable packages preserved. Use built-in image generation for original illustrated biome maps, retain dynamic routes/icons/HUD and all game rules. Validate installed Godot import/full gate, isolated Windows export and native map captures at 720p/1080p/1440p; obtain independent visual critique. No publication, uploads, Git mutations or completion claim.

User Library reference libfile_5881018b028081919b78b3a8f9862ca5 could not materialize: supported unchanged transfer helper downloaded but fails on Windows at os.setxattr (AttributeError); bounded supported retry used. No metadata bypass. Existing native Crown map screenshot inspected directly: flat parchment, repeated primitive margin symbols, empty dark surround. Improve that actual map while retaining readable gameplay overlay. Existing shipping hold remains.

### 2026-10-03 Pacific - map artwork integration gate passed

Five original built-in image_gen PNG paintings (1672x941 each) saved locally for Ashfen Marsh, Sunken Cloister, Glasswood, Ironroot Deeps and Crown of Thorns. Exact prompts retained in evidence/2026-10-03-map-art/generation-prompts.json. Main runner inspected generated pixels. Replaced procedural parchment/repeated edge motifs with region-specific full-screen atlas art; retained route geometry/rules/icons/HUD, backed legend, added badge rim/shadow and viewport-clamped tooltips. First gate caught texture-draw argument order, corrected; failed log retained. Full installed Git Bash gate passes: 4077 checks / 0 failed plus import/title/combat/map smokes. Independent critic confirms art cohesion and distinct biome identity; native route contrast/crop review pending. Godot 4.7.2.stable.official.ed1daf0bf, matching installed 4.7.2.stable Windows x64 template; no new Blender edits. Source/package version remains 0.1.1; new package will have a distinct map-art path/hash. Previous shipping hold and active marker retained.

## 2026-10-03 Pacific 20:12 - requested map art task completed locally

Built-in image_gen created five original ink/gouache atlas paintings in assets/textures/map-art (1672x941 opaque PNG each), with original prompts in evidence/2026-10-03-map-art/generation-prompts.json. Integrated biome-specific full-screen art with quiet route center, backed legend, badge rim/shadow, bounded tooltips and parchment route under-strokes. Dynamic marker geometry, map generation/rules, HUD and input retained. Independent read-only critic found edge-route contrast loss; fixed and re-exported. Focused map verdict PASS; detailed sample scope/debt in CRITIC.md. Broader RELEASE HOLD/AAA FAIL retained.

Final installed gate: 4077 passed / 0 failed; import/title/combat/map smokes pass. Godot 4.7.2.stable.official.ed1daf0bf, matching Windows x64 template and embedded-PCK Windows Desktop preset. No Blender source modified. Three final native mapart tours at 720p/1080p/1440p plus extracted ZIP720p tour: each22shots, zero failures, exit0, saves unchanged during isolated tours. Main runner inspected all88 final/extracted images and original generated paintings. Extracted normal240-frame startup/engine shutdown exits0 with normalfiles unchanged. PE x64, embedded pack, ZIP CRC, exact README and all runtime/PNG hashes verified. Eleven unrelated prior runtime snapshots match byte-for-byte. Earlier candidates/logs/packages preserved.

Existing check.sh headless map smoke writes a new throwaway normal run/profile. Final audit detected three extra profile run counts from this task's gates. Undo was restricted to those test increments and verified against exact prior recorded profile SHA0799CFC02747B1E72C9518382761DA979830FAF80F8F339928C4B7044069F97D; test-mutated backup and restoration proof retained. Normal run/settings hashes match previous record. Future gates must protect existing player files before smoke tests. No unrelated runtime code changed to hide this harness side effect.

Final package app0.1.1 / PE0.1.1.0, distinct map-art label: build/local-0.1.1-mapart-2026.10.03/Bramblecrown-0.1.1-mapart-2026.10.03-windows-x64.zip (63383486bytes). ZIP SHA51A235A3E86EE6375D94E7C14F1EBA243657CA86826F5857516098397E97C387. EXE windows/Bramblecrown.exe (134934480bytes), SHA8A8D315FEC22C0720E4C8BF68F25D6B70A864213F527F82444978FAF11ECB053. Full evidence/manifest, source delta and snapshots, prompts, screenshots and handoff: evidence/2026-10-03-map-art/RESULT.md.

Library reference libfile_5881018b028081919b78b3a8f9862ca5 remained unavailable: supported helper downloads but fails Windows os.setxattr; bounded supported retry, no metadata bypass. Existing actual native Crown baseline inspected instead. Remaining focused debt: simple symbols versus rich art, decorative landmarks, repeated arches. No genuine campaign/normal disk-save desktop acceptance, physical controller, sustained performance or minimum hardware certified. Thatch remains unfinished. .aaa-complete absent, active Bramblecrown marker/start unchanged. No commits/pushes/publication/uploads/automation/budget changes. Next: human review exact map-art package; broader completion still requires actual campaign/desktop acceptance and full SPEC/critic resolution.

## 2026-10-03 Pacific 20:18 - requested new map icons

Parent/user confirms approved atlas backgrounds and asks for new location icons. Prior pass retained the original procedural icon drawings, adding only badge rims/shadows. Main runner now owns new icon PNGs, map_scene.gd, the optional per-node visited flag in run_state.gd, focused tests/tour fixtures and handoffs. Preserve approved background bytes, route/hit geometry, other runtime work and all player files. STOP absent, dev unchanged, no engine/game process at startup. Use built-in imagegen for six bold transparent emblems; inspect actual small native size and available/current/visited/locked states at720p/1080p/1440p. Independent read-only critic requested. Before full gate, back up normal player data and restore exact bytes afterward: existing headless map smoke is known to write a throwaway run/profile. Retain original saves and all historical packages. Rebuild a separate local versioned ZIP. No Git mutation, publication, uploads or automation changes. Broader release hold remains.

### Map icons: integration gate passed
Six raw transparent imagegen PNGs integrated with shared node/legend rendering. Actual entered nodes carry optional visited metadata; legacy saves remain accepted without fabricated history. Initial 4082/3 failure caught from_dict dropping this field; fixed, full repeat passes 4085/0 with import and three scene smokes. Player preservation wrapper restored run/profile/settings to exact pre-test hashes. Approved five background hashes unchanged. Native export/visual review is next; no completion claim.


## 2026-10-03 Pacific 20:41 - requested map icons complete; game release still held

Six new original transparent imagegen emblems now replace the old procedural map/legend icons. Current leaf, actual-visit check and locked padlock distinguish states; optional visit history survives save roundtrip and accepts old checkpoints without fabricated history. Approved backgrounds, map route/hit geometry and 35 other prior runtime inputs remain unchanged. Main owns map_scene.gd, optional RunState metadata, focused tests/tour fixtures and asset/handoffs. Independent read-only focused critic PASS; minor elite/ornament miniature detail debt retained.

Full gate4085/0 after fixing visit-load roundtrip; installed Godot4.7.2.stable.official.ed1daf0bf and matching Windows x64 template/preset. No Blender source changed (installed5.1.2 ec6e62d40fa9). Three final native tours720p/1080p/1440p plus extracted720p: each23shots/zero failures/exit0. Main visually inspected all92 final/extracted images. QA fixtures use staged progression and synthetic callbacks. Corrected gallery redraw timing; earlier failed test/old capture evidence preserved. Extracted normal240-frame startup/shutdown exit0. All player files backed up/restored exactly around known smoke writes and final hashes identical. Prior release and map-art packages preserved. Archive CRC/README/x64/embedded-PCK/runtime hashes audited.

Package build/local-0.1.1-mapicons-2026.10.03/Bramblecrown-0.1.1-mapicons-2026.10.03-windows-x64.zip (71416930bytes), SHA256057B6653D63D8238B4E0A9957C05DA143A72B80575E753A0C807AAF2EB869. EXEwindows/Bramblecrown.exe (142968200bytes), SHA8DAE6DDB8441344988AB81A1E37ADD74B7493457244A40129E84185BD263DE8B. App/PE remains0.1.1/0.1.1.0. Full exact prompts, manifest, source delta/snapshots, native screenshots/logs, preservation proof and handoff: evidence/2026-10-03-map-icons/RESULT.md.

Broader RELEASE HOLD/AAA FAIL unchanged: no genuine campaign/normal disk-save/relaunch/focus/fullscreen or physical-controller acceptance; supported desktop-control API absent. Thatch/full SPEC remains unfinished. No .aaa-complete; active marker/start date unchanged. No Git mutation, publication/uploads or automation/budget edits. Next: user review exact icon package; full completion still requires actual campaign/desktop acceptance and unresolved SPEC/critic work.

## 2026-10-03 Pacific 23:00 - hosted local forced-completion checkpoint

- Local execution confirmed on DESKTOP-JOE at C:\dev\tandem_tales\bot-crafted-games. STOP absent. Pacific Saturday 2026-10-03, started 2026-09-24, age nine: forced-completion rule applies; no new polish.
- Documented dev and live remote refs/heads/dev both 50a0aa7e97e9582958415e748066765704130e8a. Read-only ls-remote succeeded after sandbox network restriction. All prior dirty source/art/handoffs retained; no Git mutation. No Godot/Blender/Bramblecrown process observed; parent says previous writer finished.
- Installed Godot 4.7.2.stable.official.ed1daf0bf; Blender 5.1.2 ec6e62d40fa9; Git Bash 4.4.23(1)-release (x86_64-pc-msys); matching 4.7.2.stable Windows release x86_64 template and editor present. Windows Desktop preset remains x86_64/embedded PCK.
- Supported tool inventory has no node_repl or cloud_threads API. Computer-use SKILL.md and guidance read; required node_repl + @oai/sky entry point cannot be invoked here. A background computer-use helper process does not supply a callable supported API. Do not build a custom helper. Parent owns routing/activity verification.
- Main runner owns only new evidence and appended handoffs this run; no development/critic agents needed while interactive acceptance is blocked. Plan: independently verify exact existing package/source/art hashes and rerun protected full gate, retain precise blocker. No completion marker unless genuine functional acceptance passes.

### 2026-10-03 Pacific 23:00 hosted run result - completion held

Fresh protected full gate: 4085 passed / 0 failed; import/title/combat/map smokes pass, exit 0. Exact normal run/profile/settings bytes restored after known smoke profile mutation. Read-only current candidate audit passes ZIP CRC/README, exported/extracted EXE, 39 runtime inputs, 35 other inputs, five approved backgrounds, six icons and four historical package artifacts. Existing mapicons ZIP SHA-256 256057B6653D63D8238B4E0A9957C05DA143A72B80575E753A0C807AAF2EB869 retained. No runtime/art edits, new export, native launch or screenshots this run.

BLOCKER: required node_repl + @oai/sky desktop control is absent from this local child's tools. Genuine five-region campaign, normal save/quit/relaunch/Continue and OS focus/fullscreen/controls remain unverified. Prior 92 screenshots are staged historical evidence; no fresh critic or completion verdict. Full SPEC Thatch and broad AAA/presentation debt remain. No new polish on forced Saturday.

Exact evidence and next action: evidence/2026-10-03-hosted-2300/RESULT.md and candidate-audit.json. A supported local desktop session or human must complete genuine acceptance on the exact extracted mapicons candidate, preserving player files; fix reproduced functional blockers only during this forced-completion attempt. .aaa-complete absent, active marker/start unchanged. No automation/budget/Git mutation/publication/upload. Historical logs and prior local work preserved.

## 2026-10-03 Pacific - explicit user-directed closeout

User says: "No. Proceed as best you can. Bramblecrown should be done now. It’s time to start on the next game."
Bramblecrown is now complete-by-user-direction for runner scheduling, with .aaa-complete explicitly recording the override. This is NOT a quality/functional-acceptance pass: genuine campaign/save/focus/control gaps, Thatch/full-SPEC debt and broad AAA FAIL remain documented. Latest exact mapicons package and all artwork preserved. Prior blocked status and evidence are historical and unchanged. Starting the next game is explicitly authorized now.
