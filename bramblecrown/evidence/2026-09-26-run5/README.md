# Run 5 evidence (2026-09-26 Pacific)

Tools: Godot `4.7.2.stable.official.ed1daf0bf` (console binary), Blender `5.1.2`.

## Package

`build/windows/Bramblecrown.exe` (gitignored), "Windows Desktop" preset, embedded PCK.
Size and SHA-256 are in `package-sha256.txt`. All three native tours below used this exact file.

## Rules / import / export

- `rules.log`: final `tools/check.sh` gate, **1,658 passed / 0 failed** (import, three scene smokes, rules).
- The forecast sweep reports `enemy forecasts compared: 1461, drift: 0`. Before the fix, the same
  sweep (then 1,107 comparisons, pre-Ironroot) found 81 forecasts with the wrong end hex or hit/miss.
- `import.log`, `export.log`: installed-Godot import and release export, exit 0.
- `blender-build.log`: eleven Ironroot models written by `source-art/build_assets.py`.
- `blender-reopen.log`: `engine_of_rot.blend` (body 1,421 verts plus two piston meshes, two 1–25
  `piston_stroke` actions), `hex_rubble.blend` and `tunneler.blend` reopened with materials and dimensions.

## Native packaged tours (`--tour-only run5`)

`native-1280x720.log`, `native-1920x1080.log`, `native-2560x1440.log`: each run exited 0 with
22 screenshots, 0 assertion failures, and normal save/profile/settings files unchanged.
Assertions include: Ironroot theme and a model for every unit in all eight encounters; the
cave-in glyph and highlighted hexes; at least one marked hex turned into a rubble tile after the
native enemy turn; the Engine animation playing; Engine phase-two turn completing; checkpoint
resume of every encounter.

The main runner read all 66 images through the six `sheet5-*.jpg` contact sheets, plus the
full-size 1280x720 originals retained here. The first 720p pass showed rust-coloured enemies and
the amber cave-in overlay blending into an orange floor. The floor and key light were cooled and
the Rustgrub and Tunneler scaled up, then everything was re-exported and all three tours were rerun.
Each later fix unit repeated the same export and three-resolution tour.

## Critic round 1 and fixes

An independent read-only critic compared the first packaged Ironroot build with Into the Breach
and Slay the Spire 2 / Monster Train 2 presentation. It rated room/reward screens at parity and
everything else as losing or losing badly. Its key finding was that the phase-two "Deep Collapse"
showed no marks on the board. Investigation found a pre-existing shader bug: pulsing telegraph
overlays (cave-in, blight spread, danger) faded to alpha 0 at every pulse trough in all regions.
Fixed (minimum 60% opacity), along with these:

- a single continuous rail line along the central row;
- per-encounter prop layouts;
- a larger, brighter Rustgrub;
- a squat brick-crucible Foundry Heart distinct from the Engine;
- a pit-headframe map motif.

The rules gate was rerun (**1,658 passed / 0 failed**). The build was re-exported and all three
native tours were rerun: 22 images each, 0 failures, saves unchanged. The final package hash is in
`package-sha256.txt`, and the contact sheets, logs and originals here come from that final package.

"Floor 0" and the zeroed clear-screen stats in the tour images come from staging each encounter
directly. They are not play results.

## Critic round 2 and final fix unit

The critic re-inspected the regenerated images:

- Resolved: the overlay fade, the per-encounter layouts, the Foundry silhouette and the map motif.
- Partly resolved: the rail (same row in every fight, crossed by rock piles, and a new plank decal
  adds floor noise) and the Rustgrub (still too close to Blight in hue).
- Verdicts: board art, enemy readability, map and Region 4 identity improved from "loses badly" to
  "loses". The cave-in telegraph still "loses badly": no per-hex damage and no link to its source.

Final unit, verified natively:

- Each cave-in hex carries a "-6" label, with a dashed amber tether to the enemy that marked it.
  The tour now asserts the marks exist.
- The Rustgrub has a pale bone-green body and verdigris shell plates, so it separates from Blight.
- The clear screen pluralises "charm" correctly.

The gate passed again (1,658 / 0). The build was re-exported, and the tours passed at all three
sizes (22 images each, 0 failures). The files here come from this final package. The critic has
not re-judged this last unit.

## Limits

Tours stage encounters, one cave-in, the boss phase change and the clear screen with synthetic
input. They are not a playthrough. No human full-region play, audio listening, physical controller,
fullscreen/focus, 4K/ultrawide, sustained performance or other hardware checks were done this run.
Campaign balance is unverified. The heuristic bot still clears Marsh in only 2 of 20 seeds.
