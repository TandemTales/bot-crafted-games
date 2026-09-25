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

- Screenshot mode: `Bramblecrown.exe --screenshot-tour <abs-out-dir> --resolution WxH` captures
  the title, map, and combat screens, then quits. Run it at 1280x720, 1920x1080, and 2560x1440, and read
  every PNG.
- Manual route: title → new run → map → fight (play cards, grow thicket, end turn, win) →
  reward → map → camp → quit → continue run restores the map position.
- Window resize while in combat: the UI anchors hold and the board stays framed.
- Clean shutdown: the process exits with code 0 and no errors in the log
  (`%APPDATA%\Godot\app_userdata\Bramblecrown\logs`).
- Controller: only verify if a pad is attached; otherwise record it as unverified.
