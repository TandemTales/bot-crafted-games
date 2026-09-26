# Run 5 evidence (2026-09-26 Pacific)

Tools: Godot `4.7.2.stable.official.ed1daf0bf` (console binary), Blender `5.1.2`.

## Package

`build/windows/Bramblecrown.exe` (gitignored), "Windows Desktop" preset, embedded PCK.
Size and SHA-256 are in `package-sha256.txt`. All three native tours below used this exact file.

## Rules / import / export

- `rules.log`: `tools/check.sh` gate, **1,657 passed / 0 failed** (import, three scene smokes, rules).
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

## Limits

Tours stage encounters, one cave-in, the boss phase change and the clear screen with synthetic
input. They are not a playthrough. No human full-region play, audio listening, physical controller,
fullscreen/focus, 4K/ultrawide, sustained performance or other hardware checks were done this run.
Campaign balance is unverified. The heuristic bot still clears Marsh in only 2 of 20 seeds.
