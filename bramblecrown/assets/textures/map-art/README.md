# Bramblecrown illustrated region maps

Five original opaque PNG backgrounds generated with the built-in image_gen tool on
2026-10-03 Pacific for the user's requested map-screen art improvement. Each is
1672x941, retained at its returned resolution without bitmap editing. No commercial
game art, screenshot, map, logo or extracted asset was used as a generation input.

Ink contours and gouache on antique parchment carry the established world:
dead-willow Ashfen Marsh, flooded Sunken Cloister, crystalline Glasswood,
root-bound Ironroot mines and the dying royal Crown of Thorns gardens.
Detailed art stays near the sides; the center is quiet for dynamic routes.

`scripts/ui/map_scene.gd` chooses the region texture and crops it evenly to cover
the window. Routes, encounter badges, hover labels, progression and all input
remain real runtime elements. A pale under-stroke preserves route contrast.

Exact prompts, generation mode, PNG identities, native screenshots and the
independent review: `evidence/2026-10-03-map-art/`. Editable text prompts are kept;
these generated bitmap assets do not have Blender source scenes.

The supplied Library screenshot could not be inspected because the supported
Library metadata helper fails on Windows at `os.setxattr`. Development used the
actual prior native map capture as its visual baseline. No metadata bypass.
