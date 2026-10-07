# Wren rebuild and Back checkpoint — 2026-10-07

Wren's rebuilt appearance was accepted by the user as a big improvement. The
source is `source-art/grovewalker.blend`; runtime is `assets/models/grovewalker.glb`.
Construction source, 21 packed PBR maps, regeneration scripts, and a separate
construction checkpoint are retained. Runtime: 49,838 vertices / 98,345 triangles,
15 material surfaces, one four-second `Wren_Breathe` morph animation. Counts are
technical evidence, not a claim of AAA art quality.

The supplied original reference was materialized locally and visually inspected.
SHA-256: A83F574C9098EF8AA9BF621AC8FC85A8761E04A8C3CF74510FC5DBF13AF76C8B.
Library ID and version were verified in NTFS metadata; the current Library helper
was kept unchanged, with a Windows metadata adapter for its xattr calls.

Three render iterations corrected protruding eyes, fragmented fringe, open sleeve
tops, shoulder overlap, overly strong grain, and floating feet. Final full-body,
face and high-angle renders are included. Native selection, title, map, and combat
pixels were inspected. Existing card illustrations still depict the earlier model.

## Back regression

`back-before-fix.log` records native Back mouse down/up, pressed, hide and focus
restoration, then no frame advancement after `overlay_tree_exited`. The handler
received input; destruction of live preview viewports was the failure boundary.
`title_scene.gd` now hides/pauses one cached selection layer and reuses it on reopen.
It does not accumulate new layers. Focus and tier reset are restored on reopening.

`native-back-fixed-stdout.log`: three Back/reopen cycles, Begin as Wren -> map,
material/morph checks and production combat animation pass, zero failures.
Exported Windows process exit: 0. Vulkan Forward+ on RTX 2070 SUPER. Capture uses
the real production scenes and explicitly draws an occluded viewport. Input is
synthetic mouse events through the native GUI dispatch path; physical input and
full campaign acceptance are not claimed. No user save/profile/settings changes.

The initial `--script` test launches did not run the test: the installed release
template disables script/path overrides. The final harness uses the established
`--screenshot-tour ... --tour-only wren` entry point. Those initial launches are not
counted as visual validation. Sandbox-only temp/export/settings failures were
resolved using approved normal local Blender/Godot execution; final import/export
logs are clean. The unrelated reported crash remains deferred.

HP alignment and accepted Wren hashes are preserved. Earlier packages and source
snapshots remain available. No commits, pushes, publishing, installs or purchases.

## Local delivery

Validated archive: `build/local-0.1.1-wren-back-2026.10.07`.
Stable launch path after promotion: `build/latest/windows/Bramblecrown.exe`.
The package manifest holds exact hashes. Promotion stages and verifies all files,
refuses an active latest executable, and retains the previous latest directory.

Next authorized unit: rebuild Cassia separately, preserving this Wren checkpoint.
