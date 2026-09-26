# Asset provenance

All game models and card illustrations are original Bramblecrown assets authored by the
runner's Blender scripts in `source-art/`. Editable `.blend` files are retained beside
those scripts. Runtime GLBs live in `assets/models/`; rendered cards in `assets/textures/`.
No commercial reference images, extracted models, or third-party game assets are shipped.

The Glasswood set was generated with installed Blender 5.1.2 by `build_assets.py`:
`hex_glass`, `hex_crystal`, `hex_mirror`, `crystal_tree`, `glass_fern`, `fallen_prism`,
`shardling`, `prism_stag`, `glass_mite`, `lantern_hart`, and `splintered_queen`.
Godot imports GLB material, mesh and animation data; players do not need Blender.

Audio is original oscillator/noise synthesis from `tools/make_audio.py`. Fonts are selected
from Windows system fonts at runtime; font files are not redistributed. The icon is local
original SVG. Source art, tools, evidence and this document are excluded from the player export.

Commercial games referenced in pitches or critique are design research only.
