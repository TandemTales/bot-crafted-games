# Run 3 evidence

Windows executable: `build/windows/Bramblecrown.exe` (embedded PCK, not tracked).
SHA-256: `27FEE5A52334ED1ACEA86B12DCFE2A04827A6269986537646966F8452B9773E6`.

Installed Godot: 4.7.2.stable.official.ed1daf0bf. Blender: 5.1.2.
Native renderer reported Vulkan 1.4.341 / NVIDIA GeForce RTX 2070 SUPER.

The rule/import/scene check logs and native regression logs are retained here.
Representative unmodified screenshots are copied from the packaged executable.
The full local image sets are under `build/run3/checked-<resolution>/`.
All four final tours (1280x720, 1920x1080, 2560x1440, 3840x2160) exited 0 with
14 images each, zero assertion/engine errors, and unchanged normal save/profile/settings hashes.
The full rule gate passed 1,055 checks. The main runner inspected all 56 final images in contact
sheets and representative originals; the independent critic's final review covered 720p.
This directory is excluded from Godot imports and player downloads by `../.gdignore`.

The automated tour uses controlled scenarios and synthetic input. It proves the checked
rules/UI paths, rendering and programmatic resize; it does not prove manual play, focus
handling, controller hardware, sustained performance, listening quality, campaign completion,
or AAA quality. The five-region SPEC remains incomplete and no new itch upload occurred.

## Independent visual review

A read-only critic compared packaged images with actual official
[Into the Breach](https://store.steampowered.com/app/590380/Into_the_Breach/) and
[Slay the Spire 2](https://store.steampowered.com/app/2868840/Slay_the_Spire_2/) screenshots.
After revisions, its final 720p verdict passed the photographed gallery headers/descriptions,
unobstructed player and targeting hints, left-margin inspection, and six-entry enemy rail.
An alleged missing-cost issue was withdrawn after re-opening the exact original screenshots.
Battlefield visual noise, the small map legend, and card-art presentation still trail the
references. No whole-game or AAA approval was given.

CLI flags were checked against the current
[official Godot command-line guide](https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html)
and exercised with the installed editor and its matching export template.
