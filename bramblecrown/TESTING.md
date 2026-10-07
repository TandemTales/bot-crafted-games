# BRAMBLECROWN — Testing

Tool paths (Windows workstation):

- `GODOT=C:\dev\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`
- `BLENDER=C:\Program Files\Blender Foundation\Blender 5.1\blender.exe`

## 1. Import / parse check

```
"$GODOT" --headless --editor --path bramblecrown --quit
```

Pass: the output contains no `SCRIPT ERROR`, `Parse Error`, or `ERROR:` lines. `tools/check.sh` greps for them.

## 2. Rule test suite

The complete gate is `bash tools/check.sh` from the game folder, using Git Bash on Windows.
It checks process exit codes as well as script/engine errors and retains raw logs in
`build/check-logs/`. Headless mode loads audio resources but skips inaudible playback
because the installed engine's Dummy driver retains an active looping WAV at shutdown.
Native packaged tests still use normal audio playback; headless checks do not validate audio output.

```
"$GODOT" --headless --path bramblecrown -s res://tests/test_runner.gd
```

Covers hex math, pathfinding, grove computation, card effects, the blight/thicket interaction,
intents and their resolution, win/loss, deterministic seeds, map generation, and save/load round
trips. Pass: the last line is `ALL TESTS PASSED` and the exit code is 0.

## 3. Blender asset regeneration

```
"$BLENDER" -b -P bramblecrown/source-art/build_assets.py
```

This regenerates `source-art/*.blend` and `assets/models/*.glb`. After regenerating, rerun step 1
and confirm that the GLBs import. Spot-check one `.blend` by reopening it:
`"$BLENDER" -b source-art/<file>.blend --python-expr "import bpy;print(len(bpy.data.objects))"`.

## 4. Release export

```
"$GODOT" --headless --path bramblecrown --export-release "Windows Desktop" <abs>/bramblecrown/build/windows/Bramblecrown.exe
```

The export must produce `Bramblecrown.exe` with the embedded PCK (preset `embed_pck=true`).

## 5. Packaged-build checks (run the exported exe, never the editor)

- Screenshot mode: `Bramblecrown.exe --screenshot-tour <abs-out-dir> --shot-size WxH` captures
  the title, map, and combat screens, then quits. Add `--tour-only r2` for just the Region 2 map/fight/elite/boss
  shots plus the draw-pile viewer, or `--tour-only rooms` for the reward/camp/shrine/market vignettes in both regions.
  (The tour forces regions without entering nodes, so its HUD shows "Floor 0"; that is expected.) Run it at 1280x720, 1920x1080, and 2560x1440, and read
  every PNG.
- Manual route: title → new run → map → fight (play cards, grow thicket, end turn, win) →
  reward → map → camp → quit → continue run restores the map position.
- Window resize while in combat: the UI anchors hold and the board stays framed.
- Clean shutdown: the process exits with code 0 and no errors in the log
  (`%APPDATA%\Godot\app_userdata\Bramblecrown\logs`).
- Controller: only verify if a pad is attached; otherwise record it as unverified.

## 6. Cloister and enemy-panel regression tour

Run the exported executable with `--screenshot-tour <abs-out-dir> --shot-size WxH --tour-only run3`
at 1280x720, 1920x1080, and 2560x1440. This produces 14 screenshots: six Cloister scenes,
four sheets covering all ten cards and upgrades, and four targeting/summon/resize images.
3840x2160 also passed on the local workstation. The tour checks description and card-header
clipping, inspector/hand bounds, keyboard selection, synthetic mouse hover/click through
the viewport input path, legal card resolution, six enemy panels for overlap, programmatic native
window resize, and player-file hashes.
It exits nonzero on failure. Inspect the actual PNGs in addition to checking the log.

The screenshot tour uses in-memory runs and suppresses run/profile/settings writes. It hashes
normal player files before/after to detect accidental mutation. It is a controlled UI regression,
not a human playthrough or evidence of campaign balance. Existing boss enemy-turn shots use a
fixed delay and can land after the animation; do not cite those images as animation coverage.

Focused rule tests cover all ten base/upgraded cards, prevention/expiry of Clarity, one-time
Daze refunds, spent and capped Ward reserves, Ward stealing/destruction, attack previews,
Grove reach, actual reward availability, and deck/progression/RNG save round trips.

## 7. Glasswood regression (Run 4)

Generate only Glasswood assets with the installed Blender:
`blender -b -P source-art/build_assets.py -- only=glasswood_tiles,glasswood_props,shardling,prism_stag,glass_mite,lantern_hart,splintered_queen`.
Reopen representative source files and check meshes, materials, dimensions, and animation actions.
Then run the full `tools/check.sh` gate with installed Godot and its normal editor-settings access.

Rules cover the Cloister-to-Glasswood transition, all eight checkpoint encounter restarts,
deterministic enemy/card setup, easy-pool selection, both Queen patterns and bounded summons.
Counterplay tests check charge interruption by Root, retreat from a stationary sweep, exposed
Mite support, and Ward-breaking previews versus actual card resolution. Existing data checks
cover reachability and imported models for every region. High-HP pattern execution is a rules
test, not campaign balance evidence. Saves restart a combat node; they do not restore mid-turn state.

Export and run `Bramblecrown.exe --screenshot-tour <abs-out-dir> --shot-size WxH --tour-only run4`.
It captures the region map, all eight encounters, Queen phase-two intent/resolution, development
clear screen, four room screens, and four existing input/resize regression views (20 images).
Run at 1280x720, 1920x1080, and 2560x1440 and inspect every image. Assertions cover actual region
models/theme, checkpoint restarts, turn animation completion, and prior input/save-preservation
checks. The end screen is staged; this does not certify defeating the Queen or a full playthrough.

Build outputs are ignored by Godot via `build/.gdignore` and excluded in the export preset,
alongside evidence and editable source art. Keep that guard when exporting into the project.

## 8. Ironroot and forecast regression (Run 5)

Generate only Ironroot assets:
`blender -b -P source-art/build_assets.py -- only=ironroot_tiles,ironroot_props,rustgrub,cart_golem,tunneler,foundry_heart,engine_of_rot`.
Reopen `engine_of_rot.blend` (two `piston_stroke` actions), `hex_rubble.blend` and `tunneler.blend`.

`test_enemy_forecast_matches_resolution` sweeps every authored encounter (3 seeds, 6 turns, a
seeded random walk) and compares each enemy's forecast end hex, hit/miss and damage with the actual
enemy phase. It must report drift 0. Before Run 5 it found 81 of 1,107 forecasts wrong.
`test_ironroot_collapse` covers targeting, forecast purity (terrain and RNG untouched), stepping
off, standing on a mark, enemy-occupied marks, connectivity and the rubble cap across 30 turns.
`test_ironroot_progression` and `test_ironroot_patterns` cover the region transition, checkpoint
restarts, easy pool, final-region victory, authored patterns in both boss phases and summon caps.

Run `Bramblecrown.exe --screenshot-tour <abs-out-dir> --shot-size WxH --tour-only run5`
(22 images): the map, all eight encounters, a staged cave-in telegraph and resolution (asserts the
glyph, highlighted hexes and rubble tile), Engine phase two, the clear screen, four Ironroot rooms
and the input/resize regression views. Run at 1280x720, 1920x1080 and 2560x1440 and read every image.

## 10. Cassia regression (Run 7)

- Rule suite: `test_cassia_data`, `test_cassia_unlock`, `test_kindle_rules`,
  `test_cassia_cards_resolve`, `test_cassia_powers`, `test_cassia_preview_matches_play` (every
  Cassia card, base and upgraded: burned hexes, Heat and damage match the preview exactly),
  `test_cassia_events`, `test_cassia_bot` (10 seeds; prints region-1 clears as a balance gauge).
- Packaged tour: `Bramblecrown.exe --screenshot-tour <dir> --shot-size WxH --tour-only run7` at
  1280x720, 1920x1080 and 2560x1440. It asserts the locked/unlocked title buttons, Cassia's model on
  the board, Flashburn giving 2 Heat and 2 ash scars, the "Heat 2 → 3" targeting forecast, Ember
  Lash landing exactly its preview, every Cassia card fitting its frame with Blender art, the
  shrine naming Smolder instead of Verdant Surge, and unchanged player saves. Exit code must be 0.
- Reopen `source-art/cassia.blend`: two meshes (`cassia`, `brazier_flame` with `flame_flicker`,
  frames 1-25).

Run 9 adds a packaged assertion that Cassia's imported AnimationPlayer is playing. Inspect the
revised model at both selection and board scale, including flame color, face, coat/leg separation
and whether the smaller mantle obscures the head. Inspect the enlarged starter-deck text in both
locked and unlocked selection screens at all three resolutions. Fifteen card illustrations that
contain Cassia were rerendered; inspect all base/upgraded card sheets for framing and consistency.
Reopen `source-art/card_ember_lash.blend` to check its editable camera and 396x224 render scene.
Future-build itch copy and the exact screenshot/package mapping are under `release/`, excluded
through both `.gdignore` and the export preset. No screenshot tour certifies a complete playthrough.

## 9. Crown of Thorns and thorn-wall regression (Run 6)

Generate only Crown assets:
`blender -b -P source-art/build_assets.py -- only=crown_tiles,crown_props,thornling,briar_knight,withered_herald,last_gardener,withered_crown`.
Reopen `withered_crown.blend` (one `diadem_turn` action, frames 1-61), `hex_thornwall.blend` and
`last_gardener.blend`, and check meshes, materials and dimensions.

`test_crown_thorns` covers authored walls, targeting, forecast purity (terrain, timers and RNG),
standing on a mark (5 damage, hex stays open), new walls lasting two enemy phases, receding at the
start of the enemy phase, countdowns, events and connectivity. `test_crown_patterns` runs every
authored move in both boss phases and checks summon caps, positive timers, the blocked cap and a
single walkable region. `test_crown_progression` covers Ironroot to Crown, map and checkpoint
restarts (including timers), the easy pool and the five-region victory.
`test_enemy_forecast_matches_resolution` now includes the eight Crown encounters (drift must be 0).
`test_encounters_valid` also rejects overlapping water, stone and thorn hexes.

Run `Bramblecrown.exe --screenshot-tour <abs-out-dir> --shot-size WxH --tour-only run6`
(23 images): the Crown map, all eight encounters, a staged Hedge Wall telegraph, the raised walls,
the same walls after they recede, Crown phase two intent and resolution, the campaign victory
screen, four Crown rooms and the input/resize regression views. Assertions cover the theme, a
thorn model on every authored wall, one countdown per wall, the thorn intent icon, highlighted
marks, ghost walls and tethers, raised and receded tiles, the phase-two boss light, the turn banner staying clear of every enemy, the
diadem animation, checkpoint resume and unchanged player saves. Run at 1280x720, 1920x1080 and
2560x1440 and read every image. The victory screen is staged, not a won campaign.

`test_events` requires at least 12 events with 2-3 choices, real cards, and region events offered
first and only in their region. `test_map_generation` requires an elite, shrine and pedlar on
every region map over 40 seeds. `tools/check.sh` does not parse `tools/screenshot_tour.gd`; the
tour itself reports parse errors, so read its log.

## 11. Aimed Kindle regression (Run 10)

`test_aimed_kindle` covers all five aimed cards and upgrades, four aim positions, exact
preview/resolution burn sets, Heat, damage, Phoenix Bark/Smokescreen Ward, preview purity
(including RNG), severed bridges, isolated Thicket, empty fuel, stale invalid targets and
Cassia deck/upgrade/RNG checkpoint round trips. Existing automatic Kindle tests remain.

The `--tour-only run7` packaged route additionally compares automatic and aimed Flashburn,
uses synthetic viewport mouse hover/click and keyboard selection/cancellation, checks the
Heat forecast clears on cancel, checks native ash scars match the previewed burn set, and
asserts the visible hex tooltip does not intersect any enemy intent panel. The tooltip tracks
the hovered hex instead of the OS pointer, including keyboard/controller cursor movement.
`73b_cassia_aimed_preview` is the added image (20 total). Run at 720p/1080p/1440p and inspect
all images, especially the longer Aim Kindle card rules and targeting instructions. This is
staged input regression evidence, not human play or a five-region completion route.

## 2026-10-03 local 0.1.1 release regression

Run the installed Git Bash `tools/check.sh` gate. The new rule cases reject malformed,
missing-key and invalid-reference checkpoints without script errors; round-trip all eleven
Withering tiers; and verify camp healing and full-health/fully-upgraded escape.

Launch the **exported executable**, including an extracted ZIP copy:

```powershell
./Bramblecrown.exe --screenshot-tour <absolute-evidence-dir> --shot-size 1280x720 --tour-only release --log-file <absolute-log>
```

Repeat at 1920x1080 and 2560x1440. `release` checks replacement/abandon cancellation,
Cancel focus, Escape and Space isolation, explicit checkpoint-quit semantics, tier-zero
default/cumulative difficulty help, Leave Camp, exact advertised healing, rail targeting,
six-enemy panels and resize. Run `run7` and `run6` at those resolutions for Cassia and
final-region coverage. Inspect every resulting image and require zero failures and unchanged
normal player files. Record the actual native process exit and executable SHA-256.

These fixtures suppress normal save/profile/settings writes and stage encounters. They do
not certify a genuine campaign, normal disk-save/relaunch/Continue, OS focus/fullscreen,
physical controller, audio listening, sustained performance or enjoyment. A release judge
must retain those acceptance gaps and the missing Thatch SPEC content in its verdict.

## 2026-10-03 illustrated map regression

Original AI-generated ink/gouache atlas textures are in assets/textures/map-art (five 1672x941 opaque PNGs). Routes, icons, hit target geometry and run rules remain drawn/handled at runtime. Full-screen art crops evenly to cover the window; the quiet center protects route contrast. A backed legend and viewport-clamped tooltip preserve readability.

Run tools/check.sh via installed Git Bash, then export Windows Desktop to a new isolated local folder. Launch the exported executable with --screenshot-tour <absolute-dir> --shot-size WxH --tour-only mapart --log-file <absolute-log>. Repeat 1280x720, 1920x1080 and 2560x1440. Each process produces 22 captures: initial, available hover, staged progress and boss hover for five regions, plus wide/tall resize. Assertions require the correct full-resolution texture, every retained marker hit target, a harmless margin click, available-node click creating a real combat state, synthetic D-pad selection, resized hit targets and unchanged normal player save/profile/settings. Inspect every image; require exit 0 and no script/import/runtime errors. These are staged callback/input regressions, not physical input or genuine campaign acceptance. Retain previous shipping hold.

Generation prompts/mode, exact PNG hashes, package identity, native logs and visual critique belong in evidence/2026-10-03-map-art. The supplied Library reference could not be inspected: its supported materializer fails on Windows os.setxattr after successful download. No metadata bypass or speculative download URL was used. Existing native Crown baseline was inspected.

Existing tools/check.sh map smoke invokes a normal Game.new_run and can write run/profile data. Before future gate runs, protect existing player files and verify exact restoration afterward. This map task restored three test-induced run-counter increments against the prior recorded profile SHA-256; normal run/settings hashes match that prior record. See evidence/2026-10-03-map-art/profile-restoration.json. Native mapart tours separately suppress all normal player writes and assert file hashes remain unchanged during each tour.


## 2026-10-03 - illustrated map icon regression checks

Latest candidate: build/local-0.1.1-mapicons-2026.10.03/; exact identity in evidence/2026-10-03-map-icons/package-manifest.json. Six generated PNGs are raw RGBA, alpha0..255. Approved map-art hashes must remain unchanged. Test optional node visited metadata roundtrip, missing legacy metadata and malformed flags in test_map_visit_history. Unchosen siblings cannot show completed checks; current/available/future/locked icons use distinct overlays/dimming.

Protect normal player data before check.sh: run evidence/2026-10-03-map-icons/run-gate.ps1 through installed PowerShell, with no other engine/game writer. It backs up run/profile/settings, runs installed Git Bash tools/check.sh and restores exact bytes after known profile smoke mutations. Full pass4085/0. Do not invoke unprotected headless map smoke on the user's profile.

Native exported/extracted EXE: `--screenshot-tour <absolute-dir> --shot-size 1280x720 --tour-only mapicons`. Repeat at 1920x1080 and 2560x1440. Each tour captures 23 images including five region start/hover/progress/boss maps, wide/tall resizes and an explicitly labelled 30-badge production-size state gallery. Tour suppresses normal writes; its footer must report zero failures and unchanged saves. Synthetic callbacks and staged history are not genuine campaign, disk save/relaunch or physical-controller proof. Main inspected 92 final/extracted images; independent scoped PASS samples in CRITIC.md. Final-audit.py verifies exact ZIP/EXE/runtime/background/player hashes, archive CRC and notes. Normal extracted startup is a 240-frame title load/shutdown, not a focus test. Prior broad release hold remains.
