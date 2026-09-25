# BRAMBLECROWN — Progress

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
