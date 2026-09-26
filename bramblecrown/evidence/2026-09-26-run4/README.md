# Run 4: Glasswood evidence

Installed Godot `4.7.2.stable.official.ed1daf0bf`, Blender `5.1.2`, and matching Godot
`4.7.2.stable` Windows x64 export template. Primary package is
`build/windows/Bramblecrown.exe`, 117,920,216 bytes, with embedded PCK.
SHA-256: `244FDD2CAC12D5E15D5C74409C872E26DF512F4CD4FF80DB628CE3CD5838B275`.

## Checks

- Full installed-engine import, three scene smokes, and rules: **1,373 passed, 0 failed**.
  Raw logs are retained here. No script/engine errors in the final gate or export.
- The same exported executable ran outside the editor at 1280x720, 1920x1080 and 2560x1440.
  Each process exited 0: 20 screenshots, zero assertions/errors, normal player files unchanged.
  Renderer: Vulkan 1.4.341 / NVIDIA GeForce RTX 2070 SUPER on this workstation.
- Native checks cover all eight Glasswood encounters, imported roster/theme, checkpoint
  restarts, Queen phase change/turn completion and playing mantle animation, ally Ward display,
  existing keyboard/synthetic mouse targeting, six-enemy panels and programmatic window resize.
- Main runner inspected all 60 final images via the nine contact sheets retained here, plus
  full-size 720p Crossing, 1080p Hart and 1440p market. Representative originals are retained;
  all originals remain locally in `build/run4/final-<resolution>/`.
- Queen and corrected crystal `.blend` files reopened in installed Blender; raw dimension,
  vertex/material and animation queries are retained. The first asset generation logged denied
  thumbnail-cache writes under the sandbox, while saving sources and GLBs successfully. The
  corrected generation with normal Blender access exited 0 without these errors.
- Export log contains no player files from `build/`, `evidence/`, or `source-art/`.
  These are explicitly excluded; source/evidence/build also have `.gdignore` guards.

The tour deliberately stages the phase boundary and development ending. It does not beat the
campaign. Resuming combat restarts the saved node, not the exact mid-turn state. Human play,
audio listening, physical controller, focus/fullscreen, 4K/ultrawide this run, sustained frame
times and other hardware remain unverified. No itch upload/publication or player-path test.

## Independent critic

The read-only critic inspected all 20 initial 720p images and 12 corrected samples (six at
720p, three at 1080p, three at 1440p, including original-resolution market/rail views).
It visually compared the build with the official
[released Slay the Spire 2 combat screenshot](https://www.megacrit.com/images/steam_screenshot2_new.png),
whose context is the [March 2026 launch](https://www.megacrit.com/news/2026-03-05-early-access-launch/).
It also inspected the official [map image](https://www.megacrit.com/images/map_qol.jpg) from a
[2024 prerelease design article](https://www.megacrit.com/news/2024-11-07-neowsletter-issue-4/);
that is not evidence of the current released map. References are research, not shipped assets.

Scoped corrections pass: ally Ward meaning, gold/price contrast, upright crystal silhouettes,
water distinction, matching map legend, clear fight captures and accurate development ending.
No new blocking visual regression was found. **Whole-game/AAA/shipping verdict remains FAIL.**

Still weaker: flat board/sparse surroundings; small dark enemy silhouettes against Blight;
repeated map stamps/generic boss icon; overbright shrine/staff lighting; rudimentary faces;
absent Grafter despite event text; missing regions, walkers, cards, events and progression.
Audio, sustained performance and human play have no quality pass.

Source review also flags a pre-existing risk: separate enemy previews use current occupancy
while resolution moves enemies sequentially. Add a focused multi-enemy preview-versus-resolution
test next run; no tested failure or fix is claimed here.

CLI usage was checked against the [official Godot guide](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
and exercised with the installed binary. Evidence is excluded from the download.
