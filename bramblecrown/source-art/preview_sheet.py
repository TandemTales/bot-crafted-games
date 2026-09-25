"""Render a contact sheet of every exported GLB for visual QA.

    blender -b -P source-art/preview_sheet.py -- out=<png path>
"""
import bpy
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MODELS = os.path.join(os.path.dirname(HERE), "assets", "models")
out = os.path.join(HERE, "preview.png")
if "--" in sys.argv:
    for a in sys.argv[sys.argv.index("--") + 1:]:
        if a.startswith("out="):
            out = a[4:]

bpy.ops.wm.read_factory_settings(use_empty=True)
files = sorted(f for f in os.listdir(MODELS) if f.endswith(".glb"))
for a in sys.argv:
    if a.startswith("only="):
        files = [f for f in files if f[:-4] in a[5:].split(",")]
cols = 5
for i, f in enumerate(files):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(MODELS, f))
    new = [o for o in bpy.data.objects if o not in before]
    x = (i % cols) * 3.2
    y = -(i // cols) * 3.2
    for o in new:
        if o.parent is None:
            o.location.x += x
            o.location.y += y
scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 1600
scene.render.resolution_y = 1000
world = bpy.data.worlds.new("w")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.25, 0.27, 0.3, 1)
scene.world = world
bpy.ops.object.light_add(type="SUN", rotation=(math.radians(50), 0, math.radians(30)))
bpy.context.active_object.data.energy = 4
rows = (len(files) + cols - 1) // cols
cx = (cols - 1) * 3.2 / 2
cy = -(rows - 1) * 3.2 / 2
bpy.ops.object.camera_add(location=(cx, cy - 13, 12), rotation=(math.radians(48), 0, 0))
cam = bpy.context.active_object
cam.data.type = "ORTHO"
cam.data.ortho_scale = 17
scene.camera = cam
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
print("[preview] wrote", out)
