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
