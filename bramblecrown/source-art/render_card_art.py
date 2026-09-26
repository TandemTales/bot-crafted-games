"""Render one illustration per card from the game's own GLB models.

    blender -b -P source-art/render_card_art.py [-- only=id1,id2]

Writes assets/textures/cards/<card_id>.png (396x224, drawn into the card's 2:1-ish art window).
Each card is a small staged vignette: models, a key light colour, a camera angle.
"""
import bpy
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
MODELS = os.path.join(ROOT, "assets", "models")
OUT = os.path.join(ROOT, "assets", "textures", "cards")
os.makedirs(OUT, exist_ok=True)

WARM = (1.0, 0.8, 0.55)
GREEN = (0.6, 1.0, 0.45)
RED = (1.0, 0.45, 0.3)
BLUE = (0.5, 0.75, 1.0)
VIOLET = (0.75, 0.45, 1.0)
GOLD = (1.0, 0.8, 0.35)
FIRE = (1.0, 0.5, 0.15)

# card id: (placements [(model, x, y, rot_deg, scale)], key colour, background colour, camera (dist, height, yaw_deg), extras)
T = "hex_peat"
SCENES = {
    "thornstrike": ([(T, 0, 0, 0, 1), (T, 1.7, 0, 0, 1), ("grovewalker", 0, 0, -70, 1.3), ("blightling", 1.7, 0, 110, 1.3), ("thicket", 0.8, 0.9, 0, 0.8)], RED, (0.2, 0.05, 0.04), (5.2, 2.2, 0), []),
    "barkskin": ([(T, 0, 0, 0, 1), ("grovewalker", 0, 0, 20, 1.5), ("thicket", -0.7, 0.4, 0, 0.8), ("thicket", 0.7, 0.4, 60, 0.8)], BLUE, (0.04, 0.08, 0.16), (4.0, 1.6, 0), ["shield"]),
    "sow": ([(T, -1.75, 0, 0, 1), (T, 0, 0, 0, 1), (T, 1.75, 0, 0, 1), ("thicket", -1.75, 0, 0, 1), ("thicket", 0, 0, 60, 1.1), ("thicket", 1.75, 0, 120, 0.7)], GREEN, (0.05, 0.12, 0.05), (5.6, 3.0, 0), []),
    "taproot": ([(T, 0, 0, 0, 1.2), ("thicket", 0, 0, 0, 1.2), ("grovewalker", 0, 0, 10, 1.4)], GREEN, (0.04, 0.1, 0.05), (3.6, 0.9, 0), ["roots"]),
    "bramble_lash": ([(T, 0, 0, 0, 1), ("thicket", 0, 0, 0, 1.3), ("rotmoth", 0.9, -0.2, 200, 1.2)], RED, (0.14, 0.05, 0.03), (4.2, 1.8, 20), []),
    "heartwood_maul": ([(T, -0.9, 0, 0, 1), (T, 0.9, 0, 0, 1), ("grovewalker", -0.9, 0, -80, 1.3), ("husk_brute", 1.0, 0, 100, 1.1)], WARM, (0.16, 0.08, 0.03), (4.8, 1.8, 0), []),
    "briar_wall": ([(T, -2.6, 0, 0, 1), (T, -0.9, 0, 0, 1), (T, 0.9, 0, 0, 1), (T, 2.6, 0, 0, 1), ("thicket", -2.6, 0, 0, 1), ("thicket", -0.9, 0, 50, 1.1), ("thicket", 0.9, 0, 100, 1.1), ("thicket", 2.6, 0, 150, 1)], GREEN, (0.05, 0.1, 0.04), (6.4, 1.6, 0), []),
    "wildfire": ([(T, -1.0, 0, 0, 1), (T, 1.0, 0, 0, 1), ("thicket", -1.0, 0, 0, 1.1), ("thicket", 1.0, 0, 90, 1.1)], FIRE, (0.25, 0.07, 0.02), (4.6, 1.5, 0), ["flames"]),
    "cleanse": ([(T, 0, 0, 0, 1.2), ("blight", 0, 0, 0, 1.1), ("grovewalker", -0.6, 0.6, 20, 1.2)], (0.9, 1.0, 0.8), (0.1, 0.12, 0.1), (4.2, 1.8, 0), ["burst"]),
    "rootsnare": ([(T, 0, 0, 0, 1.2), ("husk_brute", 0, 0, 180, 1.1), ("thicket", -0.5, -0.4, 0, 0.9), ("thicket", 0.5, -0.3, 60, 0.9)], GREEN, (0.06, 0.08, 0.04), (4.2, 1.6, 0), ["roots"]),
    "overgrowth": ([(T, x * 1.75 + (0.87 if y % 2 else 0), y * 1.5 - 1.5, 0, 1) for x in (-1, 0, 1) for y in (0, 1, 2)] + [("thicket", x * 1.75 + (0.87 if y % 2 else 0), y * 1.5 - 1.5, x * 40 + y * 20, 1) for x in (-1, 0, 1) for y in (0, 1, 2)], GREEN, (0.04, 0.09, 0.04), (7.0, 5.5, 0), []),
    "sap_draught": ([(T, 0, 0, 0, 1.2), ("willow", 0, 0.2, 30, 0.9)], GOLD, (0.16, 0.11, 0.03), (4.6, 1.6, 0), ["sap"]),
    "stride": ([(T, -1.75, 0.5, 0, 1), (T, 0, 0, 0, 1), (T, 1.75, -0.5, 0, 1), ("grovewalker", 0, 0, -75, 1.3)], WARM, (0.1, 0.1, 0.06), (5.2, 2.4, 0), []),
    "thorn_mantle": ([(T, 0, 0, 0, 1.3), ("grovewalker", 0, 0.1, 0, 1.4), ("thicket", -0.55, -0.35, 0, 1.0), ("thicket", 0.55, -0.35, 70, 1.0)], RED, (0.14, 0.03, 0.03), (3.8, 1.3, 0), []),
    "pollen_cloud": ([(T, 0, 0, 0, 1.2), ("rotmoth", 0, 0, 160, 1.3)], GOLD, (0.14, 0.12, 0.04), (4.0, 1.6, 0), ["pollen"]),
    "deep_roots": ([(T, 0, 0, 0, 1.3), ("grovewalker", 0, 0, 15, 1.3)], BLUE, (0.05, 0.07, 0.1), (3.8, 1.0, 0), ["roots", "shield"]),
    "verdant_surge": ([(T, 0, 0, 0, 1)] + [(T, 1.75 * math.cos(a), 1.75 * math.sin(a), 0, 1) for a in [i * math.pi / 3 + math.pi / 6 for i in range(6)]] + [("thicket", 0, 0, 0, 1.2)] + [("thicket", 1.75 * math.cos(a), 1.75 * math.sin(a), i * 30, 1) for i, a in enumerate([i * math.pi / 3 + math.pi / 6 for i in range(6)])], GREEN, (0.05, 0.12, 0.05), (6.0, 5.0, 0), []),
    "graft": ([(T, 0, 0, 0, 1.2), ("willow", 0.4, 0.4, 0, 0.7), ("thicket", -0.4, -0.2, 0, 1)], GOLD, (0.1, 0.1, 0.03), (4.6, 1.8, 0), ["sap"]),
    "thornvolley": ([(T, 0, 0, 0, 1), ("thicket", 0, 0, 0, 1.2), (T, -1.75, 0, 0, 1), (T, 1.75, 0, 0, 1), ("blightling", -1.75, 0, 60, 1.2), ("blightling", 1.75, 0, -60, 1.2)], RED, (0.15, 0.05, 0.04), (5.6, 2.2, 0), []),
    "hollow_oak": ([(T, 0, 0, 0, 1.4), ("willow", 0, 0, 0, 1.0), ("grovewalker", 0.35, -0.6, 0, 1.0)], BLUE, (0.04, 0.07, 0.1), (5.2, 1.6, 0), []),
    "reclaim": ([(T, -0.9, 0, 0, 1), (T, 0.9, 0, 0, 1), ("blight", -0.9, 0, 0, 1), ("thicket", 0.9, 0, 0, 1.1)], GREEN, (0.08, 0.06, 0.1), (4.6, 1.8, 0), []),
    "crowns_wrath": ([(T, 0, 0, 0, 1.2), ("grovewalker", 0, 0, 0, 1.5), ("thicket", -0.7, 0.3, 0, 0.9), ("thicket", 0.7, 0.3, 90, 0.9)], FIRE, (0.2, 0.08, 0.02), (3.4, 0.8, 0), ["burst"]),
    "seed_of_ages": ([(T, 0, 0, 0, 1.3), ("menhir", 0, 0.2, 0, 1.2), ("thicket", -0.6, -0.3, 0, 0.8), ("thicket", 0.6, -0.3, 0, 0.8)], GOLD, (0.12, 0.1, 0.03), (4.6, 1.4, 0), ["burst"]),
    "spinebreaker": ([(T, -0.9, 0, 0, 1), (T, 0.9, 0, 0, 1), ("grovewalker", -0.9, 0, -80, 1.3), ("bog_warden", 1.0, 0, 100, 0.95), ("thicket", 1.0, -0.2, 0, 0.8)], RED, (0.15, 0.04, 0.03), (5.0, 1.8, 0), []),
}


SCENES.update({
    "bellbreaker": ([("hex_flag", 0, 0, 0, 1.2), ("bell_fallen", 0, -0.2, 25, 1.4), ("thicket", -0.8, 0.3, 20, 0.9)], GOLD, (0.1, 0.055, 0.025), (4.2, 1.7, 15), ["burst"]),
    "vow_shield": ([("hex_flag", 0, 0, 0, 1.3), ("altar", 0, 0, 0, 0.8), ("candles", -0.9, -0.2, 0, 1.3)], BLUE, (0.035, 0.07, 0.11), (4.8, 1.9, -15), ["shield"]),
    "dry_wick": ([("hex_flag", 0, 0, 0, 1.2), ("candles", 0, -0.1, 25, 2.5), ("bell_fallen", 1.0, 0.6, -30, 0.7)], GOLD, (0.09, 0.075, 0.045), (3.5, 1.1, 5), []),
    "last_lantern": ([("hex_flood", 0, 0, 0, 1.4), ("arch", 0, 0.4, 0, 0.8), ("candles", 0, -0.5, 0, 1.8)], BLUE, (0.025, 0.05, 0.08), (6.8, 2.2, 15), ["shield"]),
    "censer_cut": ([("hex_flag", 0, 0, 0, 1.2), ("censer_wraith", 0, 0, 170, 1.4), ("thicket", -0.8, -0.5, 20, 0.8)], RED, (0.08, 0.04, 0.07), (6.4, 2.4, -20), ["roots"]),
    "stillwater_step": ([("hex_flood", -1.7, 0, 0, 1), ("hex_flag", 0, 0, 0, 1), ("hex_flood", 1.7, 0, 0, 1), ("grovewalker", 0, 0, -60, 1.3), ("candles", -1.7, 0.3, 0, 0.8)], BLUE, (0.035, 0.08, 0.1), (5.6, 2.8, 15), []),
    "bellroot": ([("hex_flag", 0, 0, 0, 1.2), ("bell_ghoul", 0, 0, 165, 1.3), ("thicket", -0.65, -0.3, 20, 1.0), ("thicket", 0.65, 0.2, 110, 0.9)], GREEN, (0.055, 0.08, 0.04), (4.6, 2.1, -10), ["roots"]),
    "choir_thorns": ([("hex_flag", 0, 0, 0, 1.4), ("choir_of_ash", 0, 0.3, 175, 0.9), ("thicket", -0.9, -0.4, 20, 1.1), ("thicket", 0.9, -0.4, 150, 1.1)], GREEN, (0.04, 0.06, 0.06), (5.4, 2.2, 0), []),
    "borrowed_vow": ([("hex_flag", -0.8, 0, 0, 1), ("hex_flag", 0.8, 0, 0, 1), ("moss_knight", 0.9, 0, 110, 1.1), ("candles", -0.8, -0.2, 0, 1.8)], BLUE, (0.035, 0.06, 0.1), (5.1, 1.8, -10), ["shield"]),
    "candle_lance": ([("hex_flag", 0, 0, 0, 1.3), ("candles", -0.65, 0, 0, 1.8), ("candles", 0.65, 0, 20, 1.8), ("altar", 0, 0.6, 0, 0.6)], FIRE, (0.13, 0.06, 0.025), (4.5, 1.5, 0), ["lance"]),
})


def emissive(name, col, strength):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*col, 1)
    b.inputs["Emission Color"].default_value = (*col, 1)
    b.inputs["Emission Strength"].default_value = strength
    return m


def place(model, x, y, rot, s):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(MODELS, model + ".glb"))
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.parent is None:
            o.location = (x, y, 0)
            o.rotation_euler = (0, 0, math.radians(rot))
            o.scale = (s, s, s)
            if o.animation_data:
                o.animation_data_clear()


def extras(kinds, key):
    for k in kinds:
        if k == "lance":
            for i in range(3):
                bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.06, radius2=0, depth=2.5,
                    location=(-0.55 + i * 0.55, -0.5, 1.35), rotation=(0, 0.45, 0))
                bpy.context.active_object.data.materials.append(emissive("candle_lance", GOLD, 4))
        if k == "flames":
            for i, (x, y) in enumerate([(-1.0, 0), (1.0, 0), (0, 0.4), (-0.4, -0.3), (0.5, -0.3)]):
                bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.25, radius2=0.0, depth=0.9 + 0.2 * (i % 2), location=(x, y, 0.55))
                bpy.context.active_object.data.materials.append(emissive(f"fl{i}", (1.0, 0.45 + 0.1 * (i % 3), 0.1), 12))
        elif k == "burst":
            for i in range(10):
                a = i * math.tau / 10
                bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.02, depth=1.2, location=(0.6 * math.cos(a), 0.6 * math.sin(a), 1.4),
                                                    rotation=(math.pi / 2, 0, a + math.pi / 2))
                bpy.context.active_object.data.materials.append(emissive(f"b{i}", key, 10))
        elif k == "pollen":
            import random
            random.seed(3)
            for i in range(40):
                bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(0.02, 0.05),
                                                      location=(random.uniform(-1.6, 1.6), random.uniform(-1, 1), random.uniform(0.3, 2.0)))
                bpy.context.active_object.data.materials.append(emissive(f"p{i}", (1.0, 0.85, 0.3), 6))
        elif k == "sap":
            for i in range(4):
                bpy.ops.mesh.primitive_uv_sphere_add(radius=0.1, location=(-0.5 + i * 0.35, -0.6, 0.6 + 0.25 * (i % 2)))
                o = bpy.context.active_object
                o.scale = (0.8, 0.8, 1.25)
                o.data.materials.append(emissive(f"s{i}", (1.0, 0.7, 0.2), 5))
        elif k == "shield":
            bpy.ops.mesh.primitive_torus_add(major_radius=1.1, minor_radius=0.03, location=(0, 0, 0.9), rotation=(math.pi / 2, 0, 0))
            bpy.context.active_object.data.materials.append(emissive("ward", (0.5, 0.8, 1.0), 8))
        elif k == "roots":
            for i in range(6):
                a = i * math.tau / 6
                bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.07, radius2=0.0, depth=1.2,
                                                location=(0.7 * math.cos(a), 0.7 * math.sin(a), 0.25), rotation=(0.9 * math.sin(a), -0.9 * math.cos(a), 0))
                m = bpy.data.materials.new(f"root{i}")
                m.use_nodes = True
                m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.3, 0.2, 0.1, 1)
                bpy.context.active_object.data.materials.append(m)


def render(card_id):
    placements, key, bg, cam, ex = SCENES[card_id]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for p in placements:
        place(*p)
    extras(ex, key)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 396
    scene.render.resolution_y = 224
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (*bg, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    scene.world = world
    bpy.ops.object.light_add(type="SUN", rotation=(math.radians(55), math.radians(10), math.radians(-35)))
    bpy.context.active_object.data.energy = 3.5
    bpy.context.active_object.data.color = key
    bpy.ops.object.light_add(type="SUN", rotation=(math.radians(-60), math.radians(20), math.radians(160)))
    bpy.context.active_object.data.energy = 2.0
    bpy.context.active_object.data.color = (0.55, 0.45, 1.0)
    dist, height, yaw = cam
    yaw_r = math.radians(yaw)
    target = (0, 0, 0.8)
    loc = (target[0] + math.sin(yaw_r) * -dist * 0.0 + dist * math.sin(yaw_r), target[1] - dist * math.cos(yaw_r), target[2] + height)
    bpy.ops.object.camera_add(location=loc)
    camo = bpy.context.active_object
    direction = (target[0] - loc[0], target[1] - loc[1], target[2] - loc[2])
    from mathutils import Vector
    camo.rotation_euler = Vector(direction).to_track_quat("-Z", "Y").to_euler()
    camo.data.lens = 39
    scene.camera = camo
    scene.render.filepath = os.path.join(OUT, card_id + ".png")
    # Keep editable lighting, placement and camera sources with the game.
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "card_" + card_id + ".blend"), compress=True)
    bpy.ops.render.render(write_still=True)
    print("[card-art]", card_id)


only = None
if "--" in sys.argv:
    for a in sys.argv[sys.argv.index("--") + 1:]:
        if a.startswith("only="):
            only = a[5:].split(",")
for cid in SCENES:
    if only and cid not in only:
        continue
    render(cid)
