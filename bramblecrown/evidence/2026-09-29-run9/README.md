# Run 9 evidence and independent critique

## Scope

Local native Windows development build: Cassia's model identity, matching card art, character
selection readability, player animation startup, and accurate future itch.io release materials.
Installed tools: Godot 4.7.2.stable.official.ed1daf0bf; Blender 5.1.2; Butler 15.27.0.
Godot CLI flags were checked against the [official command-line guide](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).

The exact final executable size and SHA-256 are in `../../release/manifest.json`.
The native tour is `--tour-only run7`; its historical name is retained for reproducibility.

## What the evidence can establish

- Import, scene smoke and complete rules gate: 3,122 passed, zero failed.
- Native package at 1280x720, 1920x1080 and 2560x1440: 19 staged captures each, clean process
  exit, no script/engine errors, normal player-file hashes unchanged.
- Checks include walker selection locked/unlocked state, Kindle and Heat preview/resolution,
  all twenty Cassia base/upgraded cards fitting their frames, shrine card substitution, and
  Cassia's model in first/fifth-region combat and room staging.
- New checks verify the imported `flame_flicker` AnimationPlayer starts and advances in combat.
  The initial check failed because `BoardView` started only enemy animations. The player now
  calls the same animation-start helper. `failed-player-animation.log` retains that failure.
- Blender source reopens verify mesh/material/scale data and `flame_flicker` frames 1–25.
  A representative card scene reopens with its camera and 396x224 render configuration.
- All 57 final screenshots read through twelve contact sheets plus representative original
  select/combat/gallery images. Selected unmodified 1080p PNGs are under `../../release/screenshots/`.

## Independent critic (edited no files, no Git operations)

Reference: inspected full-size official [Slay the Spire 2 Steam gallery](https://store.steampowered.com/app/2868840/Slay_the_Spire_2/),
including the Defect fighting a blue beast. Commercial images were research only and are not
included in the game or this repository.

The revised crest, split coat/legs and asymmetric offhand distinguish Cassia from Wren.
Reduced flame glare, simplified eyes and larger/brighter deck copy improve readability. The
corrected Heat pitch matches the rules. Select/combat layouts fit at 720p/1080p/1440p.

The first critic pass missed cropped card illustrations despite passing text/UI framing. The
main runner found it in the original gallery; critic follow-up confirmed severe crest/head
crops on Ashen Guard and Crownfire plus tight framing on other cards. Six source cameras
(Ashen Guard, Smokescreen, Ember Ward, Crownfire, Kindling, Tinderbox) were widened and aimed
higher. Revised original art was inspected before the final export.

**Bounded silhouette/readability review passes; overall AAA comparison FAIL / OURS LOSES.**
Remaining substantive gaps include expressive/anatomical posing, authored material detail,
repetitive card compositions, bright room lighting, and wider gameplay/content acceptance.
No shipping judge or whole-game discipline pass is claimed.

## Limits and release state

These are staged in-memory routes, not a genuine player-driven complete campaign. They do not
prove enjoyment, balance, human audio listening, physical controller usability, focus/fullscreen,
sustained frame times, other hardware, 4K/ultrawide or a player-facing download/install. The native
API in this session did not expose interactive desktop app control. Existing keyboard/mouse
bindings were not manually exercised this run. Combat resumes at the node checkpoint, not
the exact turn. Preserve these open release checks.

Authenticated browser and Butler verified `shoejunk/bramblecrown:windows`: Draft page, processed
build #2014268, version 2026.09.24-10aa561. No upload, page edit or publication occurred. Future-build
copy/screenshots remain local because applying them now would misdescribe the existing download.
Forced release remains October 3, 2026 Pacific; functional release blockers still apply then.
