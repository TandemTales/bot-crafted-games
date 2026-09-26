# Bot Crafted Games — Runner Status

This file is the standing status log for the automated Godot + Blender game
design/build/release runner. Every scheduled run should read this file first
(per STEP 0/1 of the runner instructions) before doing anything else.

## 2026-09-25 — First run: blocked before any game work (environment missing required tools)

**Repository state at run start:** `TandemTales/bot-crafted-games` had zero
commits and zero branches on any remote. This was the very first run of the
runner against this repository.

**Blocker:** The runner's instructions require using a *locally installed*
Godot Engine and Blender, and explicitly forbid downloading or installing
either application. This environment has neither:

- `godot` / `godot4` — not found on `PATH`, not found anywhere on disk.
- `blender` — not found on `PATH`, not found anywhere on disk.
- `butler` (itch.io CLI) — not found on `PATH`, not found anywhere on disk.
- No `snap`/`flatpak` package managers that might have provided them.
- No environment variables, setup scripts, or `CLAUDE.md` pointing at
  alternate install locations.

The container only has generic scripting/dev toolchains (Node, Python, Ruby,
PHP, Java/Gradle, Rust, Bun) — no game-engine or 3D-content tooling, and no
itch.io credentials/Butler login configured.

**Why no game work was started:** Every later step in the runbook depends on
these tools:
- STEP 2.5 (scaffold) requires creating a *working* Godot project and
  validating it with the Godot editor (`godot --headless --editor --path
  <project> --quit`).
- Asset creation requires the installed Blender GUI/CLI.
- STEP 3/4 verification requires headless test runs, a real
  `--export-release` build, launching the packaged build, and screenshots.
- STEP 4 release requires an authenticated Butler CLI.

Writing Godot/Blender project files without being able to open, import, run,
or export them with the real applications would violate the runbook's "never
commit failing checks" / verification requirements, and I would not be able
to distinguish a working scaffold from a broken one. So instead of guessing,
I stopped here and recorded the blocker rather than fabricating unverified
game files or claiming any progress.

**Not attempted (out of scope while blocked):** Steam research/pitch writing
was deferred too — even though it doesn't need Godot/Blender, starting a
pitch cycle before confirming the project can actually be built and tested
risks locking in a concept the runner can never verify. Better to unblock
tooling first.

**What would unblock this:**
1. Install Godot Engine (stable, with the export templates for the intended
   platforms, at minimum Windows x64) into this environment/container image,
   available on `PATH` as `godot` (or update this file with the actual
   binary name/path).
2. Install Blender, available on `PATH` as `blender`.
3. Install the itch.io Butler CLI and complete its local login
   (`butler login`), or otherwise make an authenticated itch.io publishing
   path available. Do not store the credential in this repository.
4. Confirm exact installed versions so they can be recorded per-game in each
   game's `PROGRESS.md` as the runbook requires.

**Next run should:** Re-check for `godot`, `blender`, and `butler` on `PATH`
first. If still missing, re-confirm via a fresh search and stop again without
duplicating this investigation — just add a dated one-line confirmation
below. If present, proceed from STEP 1 of the runbook (no active game is
recorded, so STEP 2: research, choose, and scaffold a game).

## 2026-09-24 (Pacific) — Tooling unblocked on the local Windows runner

The earlier blocker came from a cloud container. The scheduled task also runs on the
owner's Windows workstation (`C:\dev\tandem_tales\bot-crafted-games`), where the tools
exist. They are not on `PATH`, so use these absolute paths:

| Tool | Version | Path |
|---|---|---|
| Godot (console) | 4.7.2.stable.official.ed1daf0bf | `C:\dev\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe` |
| Godot export templates | 4.7.2.stable (windows_release_x86_64 present) | `%APPDATA%\Godot\export_templates\4.7.2.stable` |
| Blender | 5.1.2 | `C:\Program Files\Blender Foundation\Blender 5.1\blender.exe` |
| Butler | v15.27.0 (a local login exists) | `C:\dev\bayou\dist\tools\butler\butler.exe` |

Git: `dev` is the development branch (created 2026-09-24 from `claude/nifty-hawking-ge8te7`,
which is still the GitHub default branch). Future runs work on `dev`.

The itch.io account is `shoejunk`, verified through the signed-in dashboard on 2026-09-24.
`bramblecrown` has a draft page and processed Windows build #2014268; see
`.arcade-agent/itch-projects.md`. Public publication is pending.

Proceeding to STEP 2 (new game).

## 2026-09-24 (Pacific) — Run 1 result

New game started: **bramblecrown** (see `bramblecrown/PROGRESS.md`). There is a playable region-1 build with an exported
Windows exe, verified at 3 resolutions through the packaged screenshot tour. A draft itch.io page
and Windows upload now exist; public publication and a player-facing download check remain pending.

## 2026-09-26 (Pacific) — Run 3 result

Active game remains Bramblecrown; work is on documented `dev`. First Saturday (age 2 days),
so forced release is still 2026-10-03. No upload/publication occurred this run.

Added ten Cloister cards (34 Wren cards total), Blender source illustrations, enemy targeting
rail, readable boss framing, rarity presentation, and unobstructed card inspection. Full
rule/import/scene gate: 1,055 passed, 0 failed. Final native Windows package passed automated
input, resize, save-preservation and screenshot checks at 720p/1080p/1440p/4K. Retained raw
evidence and the exact package hash in `bramblecrown/evidence/2026-09-26/`.

Independent static readability review passes the revised interfaces; art/map/overall AAA
gates remain unmet. Campaign content and human play/audio/controller validation remain
incomplete. Next action: Glasswood content, then region-specific events and further art work.
Read the latest Run 3 section at the top of `bramblecrown/PROGRESS.md` for exact scope and limits.
