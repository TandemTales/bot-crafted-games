# Next-build itch.io page copy — prepared 2026-09-29

Destination: `shoejunk/bramblecrown:windows`, https://shoejunk.itch.io/bramblecrown

**Prepared locally, not applied.** The authenticated page is Draft and still offers build
`2026.09.24-10aa561` (first region only). Apply the copy and screenshots below only with the
corresponding tested five-region upload after the release gate. Do not describe these features
as present in the existing September 24 download.

## Short description

Grow your battlefield. Burn your advantage. A tactical deckbuilder across five blighted regions.

## Description

The hedge that held Wend together is dying. Carry its last living seed through a valley of
drowned bells, crystal woods and rusting engines — and replant the Bramblecrown.

Bramblecrown is a turn-based deckbuilding roguelike on a 3D hex board. Your cards grow a connected
Thicket: hold it to strengthen your attacks and defenses, or move before the enemy poisons it
with Blight. Enemy intentions and movement forecasts help you plan the next turn.

**Two ways to tend the valley**

- Wren grows a connected Grove to strengthen strikes and Ward.
- Defeat your first boss to unlock Cassia. Kindle burns parts of her Grove for Heat, trading
  territory for stronger cards. Scorch wears enemies down over time. Aim Kindle cards let
  you choose where the burn starts; select Cassia herself for automatic farthest-first burns.
  Enemy-targeted Kindle and turn-start Kindle remain automatic.

**A route to the Crown**

Choose your path through five regions: Ashfen Marsh, Sunken Cloister, Glasswood, Ironroot Deeps
and the Crown of Thorns. The encounter pool contains 30 authored regular fights, five elites
and five bosses. Camps, markets, 13 shrine events, 54 cards with upgrades and 10 charms let you
reshape a run. Cave-ins change the mine routes; thorn walls rise and recede near the Crown.

This is an in-development build. Thatch, additional charms and Withering difficulty tiers are
not implemented. Balance, audio mix and controller usability still need hands-on validation.
There is no multiplayer. Made with Godot and Blender, using AI-assisted development and original
procedural art and audio.

## Controls

Mouse and keyboard are the primary controls. Click a card or press 1–9, then click its target.
Right-click or Esc cancels selection. Space or End Turn ends the turn. Q/E or right-drag rotates
the camera; the mouse wheel zooms. A/S/X opens draw/discard/exhausted piles. Esc with no card
selected opens the pause menu. For Aim Kindle, select a connected Grove hex to burn nearest
that hex first, or your own hex for automatic burns. Choose New Run on the title screen to select a Grovewalker.

Controller bindings exist but have not been validated with a physical controller; do not tag
this build as having verified controller support.

## Install instructions

Download the Windows x64 build. If itch.io packages the download as a ZIP, extract it first.
Run Bramblecrown.exe from the extracted folder. Godot and Blender do not need to be installed.
This is a desktop game, not a browser game.

Runs save at node checkpoints. Continue resumes the checkpoint; leaving during combat restarts
that encounter rather than restoring the exact turn. Saves, profile and settings are local
under `%APPDATA%\Godot\app_userdata\Bramblecrown`. Back up that folder before replacing a
development build. Cross-version save compatibility has not been broadly validated.

## Platform and hardware disclosure

Windows x64 only for this package. Keyboard and mouse. The build uses Godot's Forward+ renderer
and requires compatible graphics hardware/drivers. Native checks have used an NVIDIA RTX 2070
SUPER workstation at 1280×720, 1920×1080 and 2560×1440. These are tested configurations, not
minimum hardware requirements or performance guarantees. Minimum CPU/RAM/GPU and integrated
graphics support remain unmeasured. Do not invent minimum specifications for the store page.

## Release operator handoff

1. Recheck STOP, Pacific date, branch, release gate and current build. This file is not approval
   of game quality. October 3 is the forced-release date; glaring functional failures still block.
2. Run the complete rules/import gate and export the configured Windows x64 release preset.
3. Run the required native routes, including a real completion route, controls, save/load,
   focus, resizing and shutdown. Retain unresolved failures. Staged tours are not campaign proof.
4. Select fresh original PNGs from the final tested executable, not old or enlarged captures.
   Record their exact package hash in `screenshots.md`.
5. Verify this same account/page/channel, downloadable Windows flag and intended visibility.
   Upload the tested export directory, then apply copy/screenshots consistent with that build.
6. Verify the actual player-facing download/install and launch before claiming release or writing
   `.aaa-complete`. No such verification has been performed in this preparation run.
