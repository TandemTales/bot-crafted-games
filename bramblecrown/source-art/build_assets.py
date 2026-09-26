"""Bramblecrown asset builder.

Run with the installed Blender:
    blender -b -P source-art/build_assets.py [-- only=name1,name2]

Authors every model procedurally, saves an editable source-art/<name>.blend and exports
assets/models/<name>.glb for Godot. Blender Z-up / -Y forward becomes Godot Y-up / +Z forward.
Units: 1 Blender unit = 1 Godot unit. Hex tiles have circumradius 1.0 (pointy-top).
"""
import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "assets", "models")
os.makedirs(OUT, exist_ok=True)


# ------------------------------------------------------------------ helpers

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color, rough=0.8, metal=0.0, emit=None, emit_strength=0.0, alpha=1.0):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit is not None:
        b.inputs["Emission Color"].default_value = (*emit, 1.0)
        b.inputs["Emission Strength"].default_value = emit_strength
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha
    return m


def assign(obj, material):
    obj.data.materials.clear()
    obj.data.materials.append(material)
    return obj


def smooth(obj, on=True):
    for p in obj.data.polygons:
        p.use_smooth = on
    return obj


def active(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def apply_all(obj):
    active(obj)
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def subsurf(obj, levels=1):
    m = obj.modifiers.new("sub", "SUBSURF")
    m.levels = levels
    m.render_levels = levels
    return obj


def noise_displace(obj, strength=0.05, size=0.4, seed=0):
    tex = bpy.data.textures.new(f"noise_{obj.name}_{seed}", "CLOUDS")
    tex.noise_scale = size
    tex.noise_depth = 2
    m = obj.modifiers.new("disp", "DISPLACE")
    m.texture = tex
    m.strength = strength
    m.mid_level = 0.5
    m.texture_coords = "GLOBAL"
    # Offset the noise field per seed.
    return obj


def cyl(name, r, depth, loc=(0, 0, 0), verts=16, rot=(0, 0, 0), r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=depth, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    return o


def sphere(name, r, loc=(0, 0, 0), scale=(1, 1, 1), seg=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=r, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    return o


def ico(name, r, loc=(0, 0, 0), scale=(1, 1, 1), sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    return o


def cube(name, size, loc=(0, 0, 0), scale=(1, 1, 1), rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=size, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    return o


def tube(name, points, radius, material, taper=True, bevel_res=4):
    """A tapered tube following `points` (list of xyz)."""
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = radius
    cu.bevel_resolution = bevel_res
    cu.use_fill_caps = True
    sp = cu.splines.new("NURBS")
    sp.points.add(len(points) - 1)
    for i, p in enumerate(points):
        sp.points[i].co = (*p, 1.0)
        if taper:
            sp.points[i].radius = max(0.08, 1.0 - i / max(1, len(points) - 1) * 0.92)
    sp.use_endpoint_u = True
    sp.order_u = min(4, len(points))
    o = bpy.data.objects.new(name, cu)
    bpy.context.collection.objects.link(o)
    active(o)
    bpy.ops.object.convert(target="MESH")
    o = bpy.context.active_object
    assign(o, material)
    smooth(o)
    return o


def hex_prism(name, radius, height, z0=0.0, bevel=0.06):
    bm = bmesh.new()
    top = []
    bot = []
    for i in range(6):
        a = math.radians(60 * i + 30)  # pointy-top: vertex on +/-Y (Godot +/-Z)
        top.append(bm.verts.new((radius * math.cos(a), radius * math.sin(a), z0 + height)))
        bot.append(bm.verts.new((radius * math.cos(a), radius * math.sin(a), z0)))
    bm.faces.new(top)
    bm.faces.new(list(reversed(bot)))
    for i in range(6):
        j = (i + 1) % 6
        bm.faces.new((bot[i], bot[j], top[j], top[i]))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    if bevel > 0:
        m = o.modifiers.new("bevel", "BEVEL")
        m.width = bevel
        m.segments = 3
        m.limit_method = "ANGLE"
    return o


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
        if o.type == "MESH" and o.modifiers:
            bpy.context.view_layer.objects.active = o
            apply_all(o)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = name
    # Bake the transform so the origin is the modelling origin (feet at 0,0,0).
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return o


def finish(name):
    bpy.ops.object.select_all(action="SELECT")
    blend = os.path.join(HERE, f"{name}.blend")
    glb = os.path.join(OUT, f"{name}.glb")
    bpy.ops.wm.save_as_mainfile(filepath=blend, compress=True)
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", export_apply=True,
                              export_animations=True, export_yup=True)
    print(f"[assets] wrote {name}: {len(bpy.data.objects)} objects")


# ------------------------------------------------------------------ palette

def palette():
    return {
        "peat": mat("peat_top", (0.095, 0.115, 0.055), 0.95),
        "moss": mat("moss", (0.16, 0.25, 0.08), 0.9),
        "soil": mat("soil_side", (0.11, 0.065, 0.04), 1.0),
        "soil_dark": mat("soil_dark", (0.08, 0.05, 0.03), 1.0),
        "stone": mat("stone", (0.36, 0.35, 0.32), 0.85),
        "stone_dark": mat("stone_dark", (0.2, 0.2, 0.19), 0.9),
        "bark": mat("bark", (0.22, 0.14, 0.08), 0.9),
        "bark_light": mat("bark_light", (0.42, 0.30, 0.17), 0.85),
        "leaf": mat("leaf", (0.23, 0.48, 0.14), 0.7),
        "leaf_light": mat("leaf_light", (0.45, 0.66, 0.22), 0.65),
        "berry": mat("berry", (0.62, 0.06, 0.08), 0.35),
        "thorn": mat("thorn", (0.55, 0.47, 0.30), 0.6),
        "blight": mat("blight", (0.20, 0.14, 0.22), 0.45),
        "blight_goo": mat("blight_goo", (0.10, 0.06, 0.12), 0.15),
        "rotflesh": mat("rotflesh", (0.42, 0.12, 0.10), 0.55),
        "rotflesh_dark": mat("rotflesh_dark", (0.16, 0.05, 0.05), 0.5),
        "sporecap": mat("sporecap", (0.66, 0.32, 0.10), 0.6),
        "mire": mat("mire", (0.13, 0.17, 0.10), 0.35),
        "blight_glow": mat("blight_glow", (0.55, 0.2, 0.7), 0.4, emit=(0.62, 0.22, 0.9), emit_strength=3.0),
        "fungus": mat("fungus", (0.52, 0.47, 0.50), 0.7),
        "cloth": mat("cloth_green", (0.14, 0.27, 0.17), 0.95),
        "cloth_red": mat("cloth_red", (0.48, 0.14, 0.09), 0.9),
        "skin": mat("skin", (0.78, 0.60, 0.47), 0.7),
        "seed_glow": mat("seed_glow", (0.6, 0.9, 0.3), 0.4, emit=(0.65, 1.0, 0.35), emit_strength=6.0),
        "eye": mat("eye_glow", (1.0, 0.7, 0.2), 0.3, emit=(1.0, 0.62, 0.15), emit_strength=8.0),
        "husk": mat("husk", (0.45, 0.36, 0.28), 0.9),
        "husk_dark": mat("husk_dark", (0.17, 0.14, 0.13), 0.95),
        "iron": mat("iron", (0.3, 0.3, 0.32), 0.45, metal=0.8),
        "moth": mat("moth_wing", (0.78, 0.55, 0.16), 0.75),
        "moth_body": mat("moth_body", (0.2, 0.12, 0.08), 0.8),
        "water": mat("water", (0.05, 0.09, 0.08), 0.05),
        "reed": mat("reed", (0.46, 0.43, 0.24), 0.85),
        "gold": mat("gold", (0.8, 0.6, 0.25), 0.35, metal=1.0),
    }


# ------------------------------------------------------------------ assets

def build_hex_tiles():
    for variant in ("hex_peat", "hex_stone", "hex_water"):
        reset()
        P = palette()
        random.seed(hash(variant) & 0xFFFF)
        parts = []
        if variant == "hex_water":
            base = hex_prism("base", 0.98, 0.55, z0=-0.8, bevel=0.05)
            assign(base, P["soil_dark"])
            rim = hex_prism("rim", 0.98, 0.08, z0=-0.28, bevel=0.03)
            assign(rim, P["soil"])
            parts = [base, rim]
            # A few drowned stakes and lily pads.
            for i in range(3):
                a = random.uniform(0, 6.28)
                r = random.uniform(0.2, 0.6)
                pad = cyl("pad", 0.12, 0.01, (r * math.cos(a), r * math.sin(a), -0.2), verts=12)
                assign(pad, P["leaf"])
                parts.append(pad)
            stake = cyl("stake", 0.035, 0.6, (0.45, -0.3, -0.05), verts=6, rot=(0.25, 0.15, 0))
            assign(stake, P["bark"])
            parts.append(stake)
        else:
            body = hex_prism("body", 0.98, 1.0, z0=-1.0, bevel=0.0)
            assign(body, P["soil"])
            top = hex_prism("top", 0.98, 0.12, z0=-0.06, bevel=0.05)
            m = top.modifiers.new("sub", "SUBSURF")
            m.levels = 2
            m.subdivision_type = "SIMPLE"
            noise_displace(top, 0.035, 0.25)
            assign(top, P["peat"])
            parts = [body, top]
            # Moss tufts and pebbles for surface texture.
            for i in range(7):
                a = random.uniform(0, 6.28)
                r = random.uniform(0.15, 0.78)
                t = ico("tuft", random.uniform(0.05, 0.1), (r * math.cos(a), r * math.sin(a), 0.07),
                        scale=(1, 1, 0.45), sub=1)
                assign(t, P["moss"] if i % 3 else P["stone_dark"])
                parts.append(t)
            if variant == "hex_stone":
                for i, (x, y, s) in enumerate([(0, 0.05, 0.55), (0.32, -0.25, 0.3), (-0.3, -0.28, 0.26)]):
                    rock = ico("rock", s, (x, y, s * 0.55), scale=(1, 0.9, 0.85), sub=2)
                    noise_displace(rock, 0.18 * s / 0.55, 0.3)
                    assign(rock, P["stone"] if i == 0 else P["stone_dark"])
                    parts.append(rock)
                moss = ico("mosscap", 0.33, (0.02, 0.08, 0.78), scale=(1, 1, 0.3), sub=2)
                noise_displace(moss, 0.05, 0.2)
                assign(moss, P["moss"])
                parts.append(moss)
        join(parts, variant)
        finish(variant)


def build_thicket():
    reset()
    P = palette()
    random.seed(11)
    parts = []
    # Arching bramble canes.
    for i in range(9):
        a = i / 9 * 6.283 + random.uniform(-0.3, 0.3)
        r0 = random.uniform(0.05, 0.3)
        r1 = random.uniform(0.45, 0.8)
        h = random.uniform(0.35, 0.7)
        pts = [
            (r0 * math.cos(a), r0 * math.sin(a), 0.0),
            ((r0 + r1) * 0.35 * math.cos(a + 0.2), (r0 + r1) * 0.35 * math.sin(a + 0.2), h * 0.8),
            ((r0 + r1) * 0.6 * math.cos(a + 0.35), (r0 + r1) * 0.6 * math.sin(a + 0.35), h),
            (r1 * math.cos(a + 0.5), r1 * math.sin(a + 0.5), h * 0.35),
        ]
        cane = tube("cane", pts, 0.035, P["bark"] if i % 2 else P["bark_light"])
        parts.append(cane)
        # Thorns along the cane.
        for t in range(4):
            u = (t + 1) / 5
            p = Vector(pts[1]).lerp(Vector(pts[2]), u) if t < 2 else Vector(pts[2]).lerp(Vector(pts[3]), u)
            th = cyl("thorn", 0.018, 0.08, p, verts=5, r2=0.0,
                     rot=(random.uniform(0, 3.1), random.uniform(0, 3.1), 0))
            assign(th, P["thorn"])
            parts.append(th)
    # Leaves.
    for i in range(26):
        a = random.uniform(0, 6.283)
        r = random.uniform(0.1, 0.75)
        z = random.uniform(0.15, 0.6) * (1.0 - r * 0.6)
        leaf = ico("leaf", 0.09, (r * math.cos(a), r * math.sin(a), z), scale=(1.4, 0.7, 0.18), sub=1)
        leaf.rotation_euler = (random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6), a)
        assign(leaf, P["leaf"] if i % 3 else P["leaf_light"])
        parts.append(leaf)
    # Berries.
    for i in range(6):
        a = random.uniform(0, 6.283)
        r = random.uniform(0.2, 0.6)
        b = sphere("berry", 0.04, (r * math.cos(a), r * math.sin(a), random.uniform(0.25, 0.5)), seg=8, rings=6)
        assign(b, P["berry"])
        parts.append(b)
    # Root mat on the ground.
    mat_ = cyl("rootmat", 0.85, 0.03, (0, 0, 0.0), verts=6)
    mat_.rotation_euler = (0, 0, math.radians(30))
    assign(mat_, P["moss"])
    parts.append(mat_)
    join(parts, "thicket")
    finish("thicket")


def build_blight():
    reset()
    P = palette()
    random.seed(23)
    parts = []
    goo = cyl("goo", 0.82, 0.025, (0, 0, 0.01), verts=6)
    goo.rotation_euler = (0, 0, math.radians(30))
    m = goo.modifiers.new("sub", "SUBSURF")
    m.levels = 2
    noise_displace(goo, 0.04, 0.2)
    assign(goo, P["blight_goo"])
    parts.append(goo)
    # Fungal stalks with caps.
    for i in range(6):
        a = random.uniform(0, 6.283)
        r = random.uniform(0.1, 0.6)
        h = random.uniform(0.12, 0.38)
        x, y = r * math.cos(a), r * math.sin(a)
        stalk = cyl("stalk", 0.035, h, (x, y, h / 2), verts=8, r2=0.025)
        assign(stalk, P["fungus"])
        cap = sphere("cap", random.uniform(0.07, 0.13), (x, y, h), scale=(1, 1, 0.45), seg=12, rings=8)
        assign(cap, P["blight"])
        parts += [stalk, cap]
    # Crystal spikes glowing violet.
    for i in range(5):
        a = random.uniform(0, 6.283)
        r = random.uniform(0.2, 0.65)
        h = random.uniform(0.2, 0.5)
        spike = cyl("spike", 0.06, h, (r * math.cos(a), r * math.sin(a), h / 2 - 0.02), verts=5, r2=0.0,
                    rot=(random.uniform(-0.4, 0.4), random.uniform(-0.4, 0.4), 0))
        assign(spike, P["blight_glow"] if i % 2 == 0 else P["blight"])
        parts.append(spike)
    # Pustules.
    for i in range(8):
        a = random.uniform(0, 6.283)
        r = random.uniform(0.1, 0.75)
        p = sphere("pust", random.uniform(0.03, 0.06), (r * math.cos(a), r * math.sin(a), 0.03), seg=8, rings=6)
        assign(p, P["blight_glow"])
        parts.append(p)
    join(parts, "blight")
    finish("blight")


def build_grovewalker():
    reset()
    P = palette()
    parts = []
    # Cloak: flared cone with a subdivided hem.
    cloak = cyl("cloak", 0.36, 0.95, (0, 0, 0.5), verts=16, r2=0.14)
    subsurf(cloak, 1)
    noise_displace(cloak, 0.03, 0.15)
    assign(cloak, P["cloth"])
    smooth(cloak)
    # Hood.
    hood = sphere("hood", 0.2, (0, 0.02, 1.06), scale=(1, 1.05, 1.15))
    assign(hood, P["cloth"])
    smooth(hood)
    face = sphere("face", 0.12, (0, -0.15, 1.02), scale=(1, 0.8, 1.1))
    assign(face, P["skin"])
    smooth(face)
    shadow = sphere("hoodshadow", 0.13, (0, -0.05, 1.08), scale=(1.05, 0.7, 0.9))
    assign(shadow, P["soil_dark"])
    # Scarf / mantle in red.
    mantle = cyl("mantle", 0.25, 0.14, (0, 0, 0.9), verts=16, r2=0.18)
    assign(mantle, P["cloth_red"])
    smooth(mantle)
    # Arms.
    for s in (-1, 1):
        arm = cyl("arm", 0.07, 0.45, (s * 0.26, -0.05, 0.72), verts=8, r2=0.055, rot=(0.35, s * 0.35, 0))
        assign(arm, P["cloth"])
        hand = sphere("hand", 0.055, (s * 0.33, -0.14, 0.52))
        assign(hand, P["skin"])
        parts += [arm, hand]
    # Staff with a glowing seed.
    staff = tube("staff", [(0.36, -0.16, 0.0), (0.37, -0.15, 0.6), (0.35, -0.16, 1.2), (0.3, -0.2, 1.45)], 0.03,
                 P["bark_light"], taper=False)
    seed = sphere("seed", 0.075, (0.3, -0.2, 1.5), scale=(1, 1, 1.25))
    assign(seed, P["seed_glow"])
    for i in range(3):
        a = i * 2.09
        curl = tube("curl", [(0.3, -0.2, 1.4), (0.3 + 0.08 * math.cos(a), -0.2 + 0.08 * math.sin(a), 1.5),
                             (0.3 + 0.04 * math.cos(a), -0.2 + 0.04 * math.sin(a), 1.6)], 0.012, P["bark"])
        parts.append(curl)
    # Satchel and belt.
    belt = cyl("belt", 0.27, 0.05, (0, 0, 0.62), verts=16)
    assign(belt, P["bark"])
    satchel = cube("satchel", 0.18, (-0.27, 0.05, 0.5), scale=(0.6, 1, 0.9))
    assign(satchel, P["bark_light"])
    # Leaf-sprouts on the hood.
    for i, (x, z) in enumerate([(-0.08, 1.26), (0.06, 1.28), (0.0, 1.3)]):
        lf = ico("sprout", 0.05, (x, 0.05, z), scale=(0.6, 1.4, 0.2), sub=1)
        lf.rotation_euler = (0.9, 0.3 * (i - 1), 0)
        assign(lf, P["leaf_light"])
        parts.append(lf)
    parts += [cloak, hood, face, shadow, mantle, staff, seed, belt, satchel]
    join(parts, "grovewalker")
    finish("grovewalker")


def _eyes(parts, P, positions, r=0.035):
    for p in positions:
        e = sphere("eye", r, p, seg=8, rings=6)
        assign(e, P["eye"])
        parts.append(e)


def build_blightling():
    reset()
    P = palette()
    random.seed(5)
    parts = []
    body = ico("body", 0.32, (0, 0, 0.3), scale=(1, 1.15, 0.85), sub=3)
    noise_displace(body, 0.08, 0.25)
    assign(body, P["rotflesh"])
    smooth(body)
    head = ico("head", 0.2, (0, -0.28, 0.42), scale=(1.1, 1, 0.85), sub=3)
    noise_displace(head, 0.04, 0.2)
    assign(head, P["rotflesh"])
    smooth(head)
    jaw = ico("jaw", 0.14, (0, -0.4, 0.3), scale=(1.2, 0.9, 0.5), sub=2)
    assign(jaw, P["rotflesh_dark"])
    _eyes(parts, P, [(-0.08, -0.44, 0.47), (0.08, -0.44, 0.47), (0.0, -0.46, 0.53)], 0.035)
    for i in range(6):
        sp = cyl("spine", 0.05, 0.22, (random.uniform(-0.15, 0.15), 0.05 + i * 0.05, 0.55 - i * 0.02), verts=5,
                 r2=0.0, rot=(-0.5 - i * 0.1, random.uniform(-0.4, 0.4), 0))
        assign(sp, P["blight_glow"] if i % 2 else P["fungus"])
        parts.append(sp)
    for s in (-1, 1):
        for k in (-1, 1):
            leg = cyl("leg", 0.05, 0.3, (s * 0.22, k * 0.14, 0.12), verts=6, r2=0.02, rot=(k * 0.3, s * 0.5, 0))
            assign(leg, P["blight_goo"])
            parts.append(leg)
    parts += [body, head, jaw]
    join(parts, "blightling")
    finish("blightling")


def build_rotmoth():
    reset()
    P = palette()
    parts = []
    body = sphere("thorax", 0.12, (0, 0, 0.8), scale=(0.9, 1.6, 0.9))
    assign(body, P["moth_body"])
    abdomen = sphere("abdomen", 0.1, (0, 0.24, 0.76), scale=(0.9, 1.7, 0.9))
    assign(abdomen, P["moth_body"])
    head = sphere("head", 0.08, (0, -0.2, 0.84))
    assign(head, P["moth_body"])
    _eyes(parts, P, [(-0.05, -0.26, 0.87), (0.05, -0.26, 0.87)], 0.03)
    for s in (-1, 1):
        ant = tube("antenna", [(s * 0.03, -0.25, 0.9), (s * 0.1, -0.35, 1.0), (s * 0.16, -0.38, 1.08)], 0.008,
                   P["moth_body"], taper=False)
        parts.append(ant)
    body_parts = [body, abdomen, head] + parts
    parts = []
    body_obj = join(body_parts, "rotmoth_body")
    wings = []
    for s in (-1, 1):
        for front, (w, h, y) in enumerate([(0.55, 0.36, 0.05), (0.4, 0.28, 0.25)]):
            bpy.ops.mesh.primitive_circle_add(vertices=16, radius=1.0, fill_type="NGON", location=(0, 0, 0))
            wg = bpy.context.active_object
            wg.name = f"wing_{'L' if s < 0 else 'R'}{front}"
            wg.scale = (w / 2, h / 2, 1)
            bpy.ops.object.transform_apply(scale=True)
            for v in wg.data.vertices:
                v.co.x += s * w / 2
                v.co.y += y
            sol = wg.modifiers.new("solid", "SOLIDIFY")
            sol.thickness = 0.01
            apply_all(wg)
            assign(wg, P["moth"])
            wg.location = (s * 0.08, 0, 0.82)
            wg.parent = body_obj
            wg.location = (s * 0.08, 0, 0.82)
            wings.append((wg, s))
    body_obj.location = (0, 0, 0)
    # Flap animation: wings rotate about the body axis.
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 16
    for wg, s in wings:
        for f, ang in ((1, 0.55), (9, -0.35), (16, 0.55)):
            wg.rotation_euler = (0, s * -ang, 0)
            wg.keyframe_insert("rotation_euler", frame=f)
    # Body bobs.
    for f, z in ((1, 0.0), (9, 0.06), (16, 0.0)):
        body_obj.location = (0, 0, z)
        body_obj.keyframe_insert("location", frame=f)
    for wg, s in wings:
        wg.animation_data.action.name = "flap"
    finish("rotmoth")


def build_husk_brute():
    reset()
    P = palette()
    random.seed(9)
    parts = []
    torso = ico("torso", 0.45, (0, 0, 0.85), scale=(1.15, 0.9, 1.1), sub=3)
    noise_displace(torso, 0.1, 0.3)
    assign(torso, P["husk"])
    smooth(torso)
    belly = ico("belly", 0.33, (0, -0.15, 0.62), scale=(1, 0.9, 0.9), sub=2)
    assign(belly, P["husk_dark"])
    head = ico("head", 0.17, (0, -0.28, 1.3), scale=(1, 1, 0.9), sub=2)
    assign(head, P["husk_dark"])
    _eyes(parts, P, [(-0.06, -0.42, 1.32), (0.06, -0.42, 1.32)], 0.03)
    for s in (-1, 1):
        sh = ico("shoulder", 0.24, (s * 0.52, 0, 1.12), sub=2)
        noise_displace(sh, 0.06, 0.2)
        assign(sh, P["husk"])
        arm = cyl("arm", 0.14, 0.7, (s * 0.62, -0.1, 0.72), verts=10, r2=0.18, rot=(0.25, s * 0.15, 0))
        assign(arm, P["husk"])
        fist = ico("fist", 0.2, (s * 0.66, -0.2, 0.32), sub=2)
        noise_displace(fist, 0.05, 0.15)
        assign(fist, P["husk_dark"])
        leg = cyl("leg", 0.16, 0.45, (s * 0.24, 0.05, 0.22), verts=10, r2=0.13)
        assign(leg, P["husk_dark"])
        parts += [sh, arm, fist, leg]
    # Bark plates and blight fungus on the back.
    for i in range(7):
        pl = cube("plate", 0.2, (random.uniform(-0.35, 0.35), 0.3, random.uniform(0.7, 1.2)),
                  scale=(1, 0.25, 0.8), rot=(random.uniform(-0.4, 0.4), 0, random.uniform(-0.4, 0.4)))
        assign(pl, P["bark"])
        parts.append(pl)
    for i in range(4):
        cap = sphere("fcap", 0.09, (random.uniform(-0.3, 0.3), 0.36, random.uniform(0.9, 1.3)),
                     scale=(1, 1, 0.5))
        assign(cap, P["blight_glow"] if i % 2 else P["blight"])
        parts.append(cap)
    parts += [torso, belly, head]
    join(parts, "husk_brute")
    finish("husk_brute")


def build_sporecaller():
    reset()
    P = palette()
    parts = []
    robe = cyl("robe", 0.3, 1.1, (0, 0, 0.55), verts=14, r2=0.1)
    subsurf(robe, 1)
    noise_displace(robe, 0.04, 0.15)
    assign(robe, P["fungus"])
    smooth(robe)
    neck = cyl("neck", 0.06, 0.3, (0, 0, 1.2), verts=8)
    assign(neck, P["husk_dark"])
    cap = sphere("cap", 0.34, (0, 0, 1.42), scale=(1, 1, 0.5))
    assign(cap, P["sporecap"])
    smooth(cap)
    gills = cyl("gills", 0.3, 0.04, (0, 0, 1.36), verts=24)
    assign(gills, P["blight_glow"])
    for i in range(6):
        a = i * 1.047
        spot = sphere("spot", 0.05, (0.24 * math.cos(a), 0.24 * math.sin(a), 1.5), scale=(1, 1, 0.4))
        assign(spot, P["fungus"])
        parts.append(spot)
    _eyes(parts, P, [(-0.05, -0.1, 1.28), (0.05, -0.1, 1.28)], 0.025)
    staff = tube("staff", [(-0.3, -0.1, 0.0), (-0.32, -0.1, 0.8), (-0.3, -0.12, 1.5), (-0.22, -0.12, 1.7)], 0.025,
                 P["husk_dark"], taper=False)
    for i in range(3):
        sac = sphere("sac", 0.07, (-0.22 + 0.05 * i, -0.12, 1.72 - 0.06 * i))
        assign(sac, P["blight_glow"])
        parts.append(sac)
    parts += [robe, neck, cap, gills, staff]
    join(parts, "sporecaller")
    finish("sporecaller")


def build_bog_warden():
    reset()
    P = palette()
    random.seed(4)
    parts = []
    torso = cyl("torso", 0.42, 0.9, (0, 0, 1.0), verts=12, r2=0.5)
    subsurf(torso, 1)
    noise_displace(torso, 0.05, 0.2)
    assign(torso, P["iron"])
    skirt = cyl("skirt", 0.5, 0.5, (0, 0, 0.35), verts=12, r2=0.42)
    noise_displace(skirt, 0.05, 0.15)
    assign(skirt, P["husk_dark"])
    helm = cyl("helm", 0.24, 0.42, (0, 0, 1.66), verts=12, r2=0.2)
    assign(helm, P["iron"])
    visor = cube("visor", 0.3, (0, -0.2, 1.66), scale=(0.9, 0.2, 0.15))
    assign(visor, P["soil_dark"])
    _eyes(parts, P, [(-0.07, -0.25, 1.67), (0.07, -0.25, 1.67)], 0.03)
    for s in (-1, 1):
        pa = sphere("pauldron", 0.26, (s * 0.52, 0, 1.38), scale=(1.1, 1, 0.7))
        assign(pa, P["iron"])
        arm = cyl("arm", 0.12, 0.7, (s * 0.6, -0.05, 0.95), verts=8)
        assign(arm, P["husk"])
        parts += [pa, arm]
    # Great peat-cleaver.
    blade = cube("blade", 1.0, (0.72, -0.35, 0.95), scale=(0.07, 0.34, 0.75), rot=(0.2, 0, 0))
    assign(blade, P["iron"])
    haft = cyl("haft", 0.035, 1.3, (0.72, -0.1, 0.55), verts=8, rot=(0.2, 0, 0))
    assign(haft, P["bark"])
    # Reeds and moss hanging from the armor.
    for i in range(10):
        a = random.uniform(0, 6.28)
        reed = cyl("reed", 0.015, 0.5, (0.45 * math.cos(a), 0.45 * math.sin(a), 0.9), verts=4, r2=0.005,
                   rot=(random.uniform(-0.3, 0.3), random.uniform(-0.3, 0.3), 0))
        assign(reed, P["reed"])
        parts.append(reed)
    for i in range(5):
        cap = sphere("fcap", 0.08, (random.uniform(-0.3, 0.3), 0.35, random.uniform(0.9, 1.4)), scale=(1, 1, 0.5))
        assign(cap, P["blight_glow"])
        parts.append(cap)
    parts += [torso, skirt, helm, visor, blade, haft]
    join(parts, "bog_warden")
    finish("bog_warden")


def build_mire_mother():
    reset()
    P = palette()
    random.seed(8)
    parts = []
    mass = ico("mass", 0.9, (0, 0, 0.75), scale=(1.1, 1.0, 0.95), sub=4)
    noise_displace(mass, 0.25, 0.45)
    assign(mass, P["mire"])
    smooth(mass)
    under = ico("under", 1.0, (0, 0, 0.15), scale=(1.2, 1.2, 0.3), sub=3)
    noise_displace(under, 0.1, 0.3)
    assign(under, P["blight_goo"])
    smooth(under)
    # Crown of reeds and dead branches.
    for i in range(14):
        a = i / 14 * 6.283
        r = 0.45
        pts = [(r * math.cos(a), r * math.sin(a), 1.4),
               (r * 1.3 * math.cos(a), r * 1.3 * math.sin(a), 1.9 + random.uniform(-0.1, 0.2)),
               (r * 1.2 * math.cos(a + 0.2), r * 1.2 * math.sin(a + 0.2), 2.3 + random.uniform(-0.2, 0.3))]
        br = tube("crown", pts, 0.04, P["bark"] if i % 2 else P["reed"])
        parts.append(br)
    # Many eyes across the face.
    eyes = []
    for i in range(9):
        a = random.uniform(-1.2, 1.2) - math.pi / 2
        z = random.uniform(0.6, 1.3)
        eyes.append((0.95 * math.cos(a), 0.95 * math.sin(a), z))
    _eyes(parts, P, eyes, 0.07)
    # Tendrils.
    for i in range(8):
        a = i / 8 * 6.283
        pts = [(0.8 * math.cos(a), 0.8 * math.sin(a), 0.4),
               (1.3 * math.cos(a + 0.2), 1.3 * math.sin(a + 0.2), 0.3),
               (1.6 * math.cos(a + 0.4), 1.6 * math.sin(a + 0.4), 0.05)]
        t = tube("tendril", pts, 0.12, P["blight_goo"])
        parts.append(t)
    for i in range(10):
        a = random.uniform(0, 6.283)
        sp = cyl("spike", 0.1, 0.6, (0.7 * math.cos(a), 0.7 * math.sin(a), 1.2), verts=5, r2=0.0,
                 rot=(random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6), 0))
        assign(sp, P["blight_glow"])
        parts.append(sp)
    parts += [mass, under]
    join(parts, "mire_mother")
    finish("mire_mother")


def build_props():
    # Dead willow.
    reset()
    P = palette()
    random.seed(31)
    parts = []
    trunk = tube("trunk", [(0, 0, -0.2), (0.05, 0, 0.8), (-0.05, 0.05, 1.6), (0.1, 0, 2.2)], 0.22, P["bark"])
    parts.append(trunk)
    for i in range(6):
        a = i * 1.05 + random.uniform(-0.3, 0.3)
        z = random.uniform(1.4, 2.1)
        br = tube("branch", [(0, 0, z), (0.5 * math.cos(a), 0.5 * math.sin(a), z + 0.4),
                             (1.0 * math.cos(a), 1.0 * math.sin(a), z + 0.3),
                             (1.3 * math.cos(a), 1.3 * math.sin(a), z - 0.4)], 0.06, P["bark"])
        parts.append(br)
        for k in range(3):
            hang = cyl("moss", 0.02, 0.6, (1.1 * math.cos(a) + random.uniform(-0.1, 0.1),
                                           1.1 * math.sin(a) + random.uniform(-0.1, 0.1), z - 0.5), verts=4, r2=0.005)
            assign(hang, P["moss"])
            parts.append(hang)
    for i in range(5):
        a = i * 1.25
        root = tube("root", [(0, 0, 0.3), (0.4 * math.cos(a), 0.4 * math.sin(a), 0.05),
                             (0.7 * math.cos(a), 0.7 * math.sin(a), -0.1)], 0.08, P["bark"])
        parts.append(root)
    join(parts, "willow")
    finish("willow")

    # Reed clump.
    reset()
    P = palette()
    random.seed(32)
    parts = []
    for i in range(22):
        a = random.uniform(0, 6.283)
        r = random.uniform(0, 0.35)
        h = random.uniform(0.5, 1.1)
        reed = cyl("reed", 0.018, h, (r * math.cos(a), r * math.sin(a), h / 2), verts=4, r2=0.004,
                   rot=(random.uniform(-0.25, 0.25), random.uniform(-0.25, 0.25), 0))
        assign(reed, P["reed"])
        parts.append(reed)
        if i % 4 == 0:
            head = cyl("cattail", 0.03, 0.14, (r * math.cos(a), r * math.sin(a), h - 0.05), verts=6)
            assign(head, P["bark"])
            parts.append(head)
    join(parts, "reeds")
    finish("reeds")

    # Standing stone with carved spiral (region landmark).
    reset()
    P = palette()
    stone = cube("menhir", 1.0, (0, 0, 0.9), scale=(0.35, 0.25, 0.95))
    subsurf(stone, 2)
    noise_displace(stone, 0.12, 0.3)
    assign(stone, P["stone"])
    cap = ico("lichen", 0.3, (0, 0, 1.75), scale=(1.1, 0.8, 0.35), sub=2)
    noise_displace(cap, 0.05, 0.2)
    assign(cap, P["moss"])
    join([stone, cap], "menhir")
    finish("menhir")


# ------------------------------------------------------------------ region 2: Sunken Cloister

def cloister_palette():
    P = palette()
    P.update({
        "flag": mat("flagstone", (0.085, 0.088, 0.09), 0.75),
        "flag_light": mat("flagstone_light", (0.12, 0.118, 0.11), 0.7),
        "flag_dark": mat("flagstone_dark", (0.055, 0.058, 0.062), 0.85),
        "grout": mat("grout_moss", (0.05, 0.085, 0.035), 0.95),
        "marble": mat("marble", (0.26, 0.25, 0.22), 0.45),
        "marble_dark": mat("marble_dark", (0.14, 0.135, 0.125), 0.55),
        "bronze": mat("bronze", (0.45, 0.30, 0.13), 0.35, metal=1.0),
        "verdigris": mat("verdigris", (0.20, 0.42, 0.36), 0.6, metal=0.3),
        "wax": mat("wax", (0.86, 0.80, 0.64), 0.5),
        "flame": mat("flame", (1.0, 0.7, 0.3), 0.3, emit=(1.0, 0.62, 0.22), emit_strength=9.0),
        "ghost": mat("ghost_cloth", (0.30, 0.33, 0.36), 0.9),
        "ghost_dark": mat("ghost_cloth_dark", (0.12, 0.13, 0.15), 0.95),
        "mask": mat("pale_mask", (0.80, 0.77, 0.68), 0.45),
        "ash": mat("ash", (0.36, 0.34, 0.32), 0.95),
        "ash_dark": mat("ash_dark", (0.12, 0.11, 0.10), 1.0),
        "ember": mat("ember", (1.0, 0.4, 0.1), 0.4, emit=(1.0, 0.36, 0.08), emit_strength=6.0),
        "drowned": mat("drowned_cloth", (0.10, 0.20, 0.21), 0.6),
        "drowned_light": mat("drowned_light", (0.20, 0.34, 0.33), 0.55),
        "ghoul": mat("ghoul_skin", (0.46, 0.44, 0.38), 0.7),
        "ghoul_dark": mat("ghoul_dark", (0.20, 0.18, 0.16), 0.8),
        "steel": mat("steel_old", (0.34, 0.35, 0.36), 0.4, metal=0.85),
        "incense": mat("incense_glow", (0.9, 0.6, 0.3), 0.4, emit=(1.0, 0.55, 0.2), emit_strength=5.0),
        "pool": mat("pool", (0.04, 0.08, 0.09), 0.05),
    })
    return P


def _flag_top(P, parts, rng_seed, z=0.0, cracked=0.0):
    """A hex top tiled with irregular flagstones (Voronoi-ish slabs) over mossy grout."""
    random.seed(rng_seed)
    grout = hex_prism("grout", 0.98, 0.06, z0=z - 0.06, bevel=0.02)
    assign(grout, P["grout"])
    parts.append(grout)
    # Slabs: a centre stone and a ring of six wedges, each shrunk to leave grout lines.
    centre = hex_prism("slab_c", 0.34, 0.07, z0=z - 0.04, bevel=0.03)
    centre.rotation_euler = (0, 0, random.uniform(-0.2, 0.2))
    assign(centre, P["flag_light"])
    parts.append(centre)
    for i in range(6):
        a0 = math.radians(60 * i + 30 + 3)
        a1 = math.radians(60 * (i + 1) + 30 - 3)
        r_in, r_out = 0.40, 0.93
        bm = bmesh.new()
        h = 0.07 + random.uniform(-0.02, 0.015) - (0.03 if random.random() < cracked else 0)
        tilt = random.uniform(-0.02, 0.02)
        pts = [(r_in * math.cos(a0), r_in * math.sin(a0)), (r_out * math.cos(a0), r_out * math.sin(a0)),
               (r_out * math.cos(a1), r_out * math.sin(a1)), (r_in * math.cos(a1), r_in * math.sin(a1))]
        top = [bm.verts.new((x, y, z - 0.04 + h + tilt * k)) for k, (x, y) in enumerate(pts)]
        bot = [bm.verts.new((x, y, z - 0.05)) for (x, y) in pts]
        bm.faces.new(top)
        bm.faces.new(list(reversed(bot)))
        for k in range(4):
            j = (k + 1) % 4
            bm.faces.new((bot[k], bot[j], top[j], top[k]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new(f"slab{i}")
        bm.to_mesh(me)
        bm.free()
        o = bpy.data.objects.new(f"slab{i}", me)
        bpy.context.collection.objects.link(o)
        bev = o.modifiers.new("bevel", "BEVEL")
        bev.width = 0.02
        bev.segments = 2
        assign(o, random.choice([P["flag"], P["flag"], P["flag_light"], P["flag_dark"]]))
        parts.append(o)
    # Moss in the cracks and a few chips.
    for i in range(5):
        a = random.uniform(0, 6.28)
        r = random.uniform(0.35, 0.9)
        t = ico("tuft", random.uniform(0.04, 0.08), (r * math.cos(a), r * math.sin(a), z + 0.03),
                scale=(1.3, 1, 0.35), sub=1)
        assign(t, P["moss"])
        parts.append(t)


def build_cloister_tiles():
    # Plain: flagstone floor over a masonry plinth.
    reset()
    P = cloister_palette()
    parts = []
    body = hex_prism("body", 0.98, 1.0, z0=-1.06, bevel=0.0)
    assign(body, P["flag_dark"])
    band = hex_prism("band", 0.99, 0.08, z0=-0.3, bevel=0.02)
    assign(band, P["marble_dark"])
    parts += [body, band]
    _flag_top(P, parts, 101)
    join(parts, "hex_flag")
    finish("hex_flag")

    # Stone: a broken fluted pillar on flagstones.
    reset()
    P = cloister_palette()
    random.seed(102)
    parts = []
    body = hex_prism("body", 0.98, 1.0, z0=-1.06, bevel=0.0)
    assign(body, P["flag_dark"])
    parts.append(body)
    _flag_top(P, parts, 103, cracked=0.5)
    plinth = hex_prism("plinth", 0.5, 0.18, z0=0.0, bevel=0.03)
    assign(plinth, P["marble_dark"])
    parts.append(plinth)
    shaft = cyl("shaft", 0.33, 1.25, (0, 0, 0.8), verts=16)
    # Fluting: alternate vertex radii.
    for v in shaft.data.vertices:
        ang = math.atan2(v.co.y, v.co.x)
        k = 0.92 + 0.08 * (1 if int(round(ang / (math.pi / 8))) % 2 else 0)
        v.co.x *= k
        v.co.y *= k
    # Broken top: jitter the top ring heights.
    for v in shaft.data.vertices:
        if v.co.z > 0.5:
            v.co.z += random.uniform(-0.35, 0.05)
    assign(shaft, P["marble"])
    parts.append(shaft)
    drum = cyl("drum", 0.3, 0.42, (0.5, -0.45, 0.2), verts=16, rot=(math.radians(90), 0, math.radians(35)))
    assign(drum, P["marble_dark"])
    parts.append(drum)
    ivy = ico("ivy", 0.3, (0.05, 0.1, 1.1), scale=(1.2, 1.1, 0.5), sub=2)
    noise_displace(ivy, 0.08, 0.2)
    assign(ivy, P["moss"])
    parts.append(ivy)
    for i in range(6):
        z = random.uniform(0.3, 1.1)
        a = random.uniform(0, 6.28)
        lf = ico("vine", 0.06, (0.34 * math.cos(a), 0.34 * math.sin(a), z), scale=(1, 1, 1.6), sub=1)
        assign(lf, P["leaf"])
        parts.append(lf)
    join(parts, "hex_pillar")
    finish("hex_pillar")

    # Water: a flooded, sunken bay with a masonry lip.
    reset()
    P = cloister_palette()
    random.seed(104)
    base = hex_prism("base", 0.98, 0.55, z0=-0.8, bevel=0.05)
    assign(base, P["flag_dark"])
    lip = hex_prism("lip", 0.98, 0.08, z0=-0.28, bevel=0.03)
    assign(lip, P["marble_dark"])
    parts = [base, lip]
    for i in range(3):
        a = random.uniform(0, 6.28)
        r = random.uniform(0.25, 0.6)
        slab = cube("sunk", 0.3, (r * math.cos(a), r * math.sin(a), -0.24), scale=(1, 0.7, 0.2),
                    rot=(random.uniform(-0.3, 0.3), random.uniform(-0.3, 0.3), a))
        assign(slab, P["flag"])
        parts.append(slab)
    candle = cyl("candle", 0.04, 0.16, (-0.4, 0.35, -0.12), verts=8)
    assign(candle, P["wax"])
    flame = sphere("flame", 0.03, (-0.4, 0.35, -0.01), scale=(1, 1, 1.8), seg=8, rings=6)
    assign(flame, P["flame"])
    parts += [candle, flame]
    join(parts, "hex_flood")
    finish("hex_flood")


def build_cloister_props():
    # Ruined pointed arch.
    reset()
    P = cloister_palette()
    random.seed(111)
    parts = []
    for s in (-1, 1):
        base = cube("base", 0.5, (s * 0.9, 0, 0.1), scale=(1, 1, 0.5))
        assign(base, P["marble_dark"])
        col = cyl("col", 0.18, 2.0, (s * 0.9, 0, 1.2), verts=12)
        assign(col, P["marble"])
        cap = cube("cap", 0.46, (s * 0.9, 0, 2.25), scale=(1, 1, 0.3))
        assign(cap, P["marble_dark"])
        parts += [base, col, cap]
    # Pointed arch from voussoir blocks; the right half is broken off.
    n = 14
    for i in range(n):
        u = i / (n - 1)
        if u > 0.7:
            break
        ang = math.pi * u
        x = -0.9 * math.cos(ang)
        z = 2.4 + 1.0 * math.sin(ang)
        blk = cube("vous", 0.36, (x, 0, z), scale=(0.75, 1.2, 0.95), rot=(0, -ang + math.pi / 2, 0))
        assign(blk, P["marble"] if i % 2 else P["marble_dark"])
        parts.append(blk)
    for i in range(4):
        rub = ico("rubble", random.uniform(0.1, 0.2), (random.uniform(0.4, 1.3), random.uniform(-0.4, 0.4), 0.08), sub=1)
        assign(rub, P["marble_dark"])
        parts.append(rub)
    ivy = tube("ivy", [(-0.95, 0.15, 0.2), (-0.9, 0.2, 1.0), (-0.85, 0.2, 1.8), (-0.6, 0.18, 2.8), (-0.2, 0.2, 3.1)], 0.05, P["leaf"])
    parts.append(ivy)
    join(parts, "arch")
    finish("arch")

    # Candle cluster.
    reset()
    P = cloister_palette()
    random.seed(112)
    parts = []
    for i in range(7):
        a = random.uniform(0, 6.28)
        r = random.uniform(0, 0.28)
        h = random.uniform(0.12, 0.45)
        x, y = r * math.cos(a), r * math.sin(a)
        c = cyl("candle", random.uniform(0.035, 0.06), h, (x, y, h / 2), verts=10)
        assign(c, P["wax"])
        drip = sphere("drip", 0.05, (x, y, 0.02), scale=(1.4, 1.4, 0.4), seg=8, rings=5)
        assign(drip, P["wax"])
        f = sphere("flame", 0.025, (x, y, h + 0.04), scale=(1, 1, 1.9), seg=8, rings=6)
        assign(f, P["flame"])
        parts += [c, drip, f]
    join(parts, "candles")
    finish("candles")

    # Fallen bronze bell, half sunk.
    reset()
    P = cloister_palette()
    parts = []
    bell = cyl("bell", 0.5, 0.75, (0, 0, 0.3), verts=24, r2=0.26, rot=(math.radians(22), 0, 0))
    subsurf(bell, 1)
    smooth(bell)
    assign(bell, P["bronze"])
    lip = cyl("lip", 0.54, 0.09, (0, 0.14, -0.04), verts=24, rot=(math.radians(22), 0, 0))
    assign(lip, P["verdigris"])
    band = cyl("band", 0.4, 0.06, (0, -0.08, 0.5), verts=24, rot=(math.radians(22), 0, 0))
    assign(band, P["verdigris"])
    crown = cyl("crown", 0.1, 0.18, (0, -0.2, 0.72), verts=10, rot=(math.radians(22), 0, 0))
    assign(crown, P["bronze"])
    parts += [bell, lip, band, crown]
    random.seed(113)
    for i in range(6):
        a = random.uniform(0, 6.28)
        rub = ico("rubble", random.uniform(0.08, 0.16), (0.6 * math.cos(a), 0.6 * math.sin(a), 0.04), sub=1)
        assign(rub, P["marble_dark"])
        parts.append(rub)
    join(parts, "bell_fallen")
    finish("bell_fallen")


def build_censer_wraith():
    reset()
    P = cloister_palette()
    random.seed(121)
    parts = []
    robe = cyl("robe", 0.32, 1.0, (0, 0, 0.9), verts=16, r2=0.12)
    # Tattered hem: pull alternate bottom vertices down.
    for v in robe.data.vertices:
        if v.co.z < 0:
            ang = math.atan2(v.co.y, v.co.x)
            v.co.z -= 0.12 * (1 if int(round(ang / (math.pi / 8))) % 2 else 0) + random.uniform(0, 0.05)
    subsurf(robe, 1)
    noise_displace(robe, 0.03, 0.15)
    assign(robe, P["ghost"])
    smooth(robe)
    hood = sphere("hood", 0.2, (0, 0.03, 1.45), scale=(1, 1.1, 1.2))
    assign(hood, P["ghost_dark"])
    mask = sphere("mask", 0.12, (0, -0.12, 1.42), scale=(0.9, 0.5, 1.15))
    assign(mask, P["mask"])
    _eyes(parts, P, [(-0.045, -0.18, 1.45), (0.045, -0.18, 1.45)], 0.022)
    for s in (-1, 1):
        sl = cyl("sleeve", 0.08, 0.5, (s * 0.26, -0.1, 1.15), verts=10, r2=0.12, rot=(0.9, s * 0.4, 0))
        assign(sl, P["ghost"])
        parts.append(sl)
    parts += [robe, hood, mask]
    body = join(parts, "censer_wraith_body")
    # Censer on a chain, pivoting at the right hand.
    cparts = []
    chain = cyl("chain", 0.012, 0.5, (0, 0, -0.25), verts=6)
    assign(chain, P["bronze"])
    pot = sphere("pot", 0.1, (0, 0, -0.55), scale=(1, 1, 0.8), seg=12, rings=8)
    assign(pot, P["bronze"])
    lid = cyl("lid", 0.07, 0.08, (0, 0, -0.45), verts=10, r2=0.02)
    assign(lid, P["verdigris"])
    glow = sphere("glow", 0.06, (0, -0.02, -0.55), seg=8, rings=6)
    assign(glow, P["incense"])
    cparts += [chain, pot, lid, glow]
    for i in range(4):
        puff = ico("smoke", 0.05 + i * 0.02, (0.03 * i, 0, -0.4 + 0.15 * i), sub=1)
        assign(puff, P["ghost_dark"])
        cparts.append(puff)
    censer = join(cparts, "censer")
    censer.parent = body
    censer.location = (0.36, -0.35, 1.0)
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 40
    for f, ang in ((1, 0.45), (21, -0.45), (40, 0.45)):
        censer.rotation_euler = (ang, 0, 0)
        censer.keyframe_insert("rotation_euler", frame=f)
    for f, z in ((1, 0.0), (21, 0.08), (40, 0.0)):
        body.location = (0, 0, z)
        body.keyframe_insert("location", frame=f)
    finish("censer_wraith")


def build_bell_ghoul():
    reset()
    P = cloister_palette()
    random.seed(122)
    parts = []
    torso = ico("torso", 0.34, (0, 0.05, 0.7), scale=(1.0, 1.2, 0.9), sub=3)
    noise_displace(torso, 0.05, 0.25)
    assign(torso, P["ghoul"])
    smooth(torso)
    head = ico("head", 0.16, (0, -0.32, 0.78), scale=(0.9, 1.1, 0.85), sub=2)
    assign(head, P["ghoul"])
    smooth(head)
    jaw = ico("jaw", 0.1, (0, -0.42, 0.68), scale=(1, 1, 0.5), sub=2)
    assign(jaw, P["ghoul_dark"])
    _eyes(parts, P, [(-0.06, -0.45, 0.82), (0.06, -0.45, 0.82)], 0.028)
    for s in (-1, 1):
        arm = tube("arm", [(s * 0.28, -0.1, 0.85), (s * 0.45, -0.3, 0.55), (s * 0.4, -0.45, 0.15)], 0.06, P["ghoul"])
        hand = ico("hand", 0.08, (s * 0.4, -0.47, 0.08), scale=(1, 1.3, 0.5), sub=1)
        assign(hand, P["ghoul_dark"])
        leg = cyl("leg", 0.07, 0.4, (s * 0.18, 0.2, 0.2), verts=8, r2=0.05, rot=(-0.3, 0, 0))
        assign(leg, P["ghoul_dark"])
        parts += [arm, hand, leg]
    # Great bell strapped to the back.
    bell = cyl("bell", 0.32, 0.55, (0, 0.46, 0.88), verts=20, r2=0.16, rot=(-1.1, 0, 0))
    subsurf(bell, 1)
    smooth(bell)
    assign(bell, P["bronze"])
    rim = cyl("rim", 0.35, 0.06, (0, 0.68, 0.73), verts=20, rot=(-1.1, 0, 0))
    assign(rim, P["verdigris"])
    strap = cyl("strap", 0.36, 0.06, (0, 0.2, 0.9), verts=16, rot=(0.9, 0, 0))
    assign(strap, P["bark"])
    clapper = sphere("clapper", 0.07, (0, 0.72, 0.66), seg=8, rings=6)
    assign(clapper, P["iron"])
    rags = cyl("rags", 0.3, 0.35, (0, 0.05, 0.42), verts=12, r2=0.36)
    noise_displace(rags, 0.04, 0.12)
    assign(rags, P["drowned"])
    parts += [torso, head, jaw, bell, rim, strap, clapper, rags]
    join(parts, "bell_ghoul")
    finish("bell_ghoul")


def build_moss_knight():
    reset()
    P = cloister_palette()
    random.seed(123)
    parts = []
    torso = cyl("torso", 0.34, 0.75, (0, 0, 1.0), verts=12, r2=0.4)
    subsurf(torso, 1)
    assign(torso, P["steel"])
    tabard = cyl("tabard", 0.36, 0.7, (0, 0, 0.5), verts=12, r2=0.3)
    noise_displace(tabard, 0.03, 0.12)
    assign(tabard, P["drowned"])
    helm = cyl("helm", 0.2, 0.36, (0, 0, 1.55), verts=12, r2=0.17)
    assign(helm, P["steel"])
    crest = cube("crest", 0.3, (0, 0.02, 1.8), scale=(0.1, 0.9, 0.5))
    assign(crest, P["moss"])
    slit = cube("slit", 0.25, (0, -0.17, 1.58), scale=(0.9, 0.2, 0.12))
    assign(slit, P["ash_dark"])
    _eyes(parts, P, [(-0.05, -0.2, 1.58), (0.05, -0.2, 1.58)], 0.025)
    for s in (-1, 1):
        pa = sphere("pauldron", 0.2, (s * 0.42, 0, 1.28), scale=(1.1, 1, 0.7))
        assign(pa, P["steel"])
        leg = cyl("leg", 0.1, 0.5, (s * 0.15, 0, 0.25), verts=10)
        assign(leg, P["steel"])
        parts += [pa, leg]
    # Tower shield on the left arm, greatsword in the right.
    shield = cube("shield", 1.0, (-0.52, -0.2, 0.85), scale=(0.08, 0.5, 0.8), rot=(0, 0, 0.25))
    assign(shield, P["bronze"])
    boss_ = sphere("boss", 0.08, (-0.58, -0.35, 0.95), scale=(1, 0.6, 1))
    assign(boss_, P["verdigris"])
    blade = cube("blade", 1.0, (0.5, -0.3, 0.95), scale=(0.05, 0.12, 1.2), rot=(0.25, 0, 0))
    assign(blade, P["steel"])
    guard = cube("guard", 1.0, (0.5, -0.17, 0.4), scale=(0.3, 0.06, 0.05), rot=(0.25, 0, 0))
    assign(guard, P["bronze"])
    parts += [torso, tabard, helm, crest, slit, shield, boss_, blade, guard]
    # Moss overgrowth and small ferns all over the armour.
    for i in range(14):
        a = random.uniform(0, 6.28)
        z = random.uniform(0.6, 1.5)
        m = ico("moss", random.uniform(0.07, 0.13), (0.36 * math.cos(a), 0.36 * math.sin(a), z), scale=(1, 1, 0.55), sub=1)
        assign(m, P["moss"] if i % 3 else P["leaf"])
        parts.append(m)
    for i in range(3):
        cap = sphere("fcap", 0.06, (random.uniform(-0.2, 0.2), 0.3, random.uniform(0.9, 1.3)), scale=(1, 1, 0.5))
        assign(cap, P["blight_glow"])
        parts.append(cap)
    join(parts, "moss_knight")
    finish("moss_knight")


def build_drowned_novice():
    reset()
    P = cloister_palette()
    random.seed(124)
    parts = []
    robe = cyl("robe", 0.26, 0.7, (0, 0, 0.35), verts=14, r2=0.1)
    subsurf(robe, 1)
    noise_displace(robe, 0.03, 0.12)
    assign(robe, P["drowned"])
    smooth(robe)
    hood = sphere("hood", 0.15, (0, 0.0, 0.78), scale=(1, 1.1, 1.1))
    assign(hood, P["drowned_light"])
    face = sphere("face", 0.09, (0, -0.1, 0.76), scale=(0.9, 0.5, 1.0))
    assign(face, P["ghoul"])
    _eyes(parts, P, [(-0.035, -0.14, 0.78), (0.035, -0.14, 0.78)], 0.02)
    for s in (-1, 1):
        arm = cyl("arm", 0.05, 0.35, (s * 0.18, -0.12, 0.5), verts=8, r2=0.04, rot=(1.0, s * 0.3, 0))
        assign(arm, P["drowned"])
        parts.append(arm)
    for i in range(6):
        a = random.uniform(0, 6.28)
        weed = cyl("weed", 0.012, 0.3, (0.22 * math.cos(a), 0.22 * math.sin(a), 0.3), verts=4, r2=0.004,
                   rot=(random.uniform(-0.3, 0.3), random.uniform(-0.3, 0.3), 0))
        assign(weed, P["moss"])
        parts.append(weed)
    candle = cyl("candle", 0.03, 0.12, (0, -0.3, 0.5), verts=8)
    assign(candle, P["wax"])
    fl = sphere("flame", 0.022, (0, -0.3, 0.59), scale=(1, 1, 1.8), seg=8, rings=6)
    assign(fl, P["flame"])
    parts += [robe, hood, face, candle, fl]
    join(parts, "drowned_novice")
    finish("drowned_novice")


def build_choir_of_ash():
    reset()
    P = cloister_palette()
    random.seed(125)
    parts = []
    plinth = cyl("plinth", 0.75, 0.2, (0, 0, 0.1), verts=6)
    plinth.rotation_euler = (0, 0, math.radians(30))
    assign(plinth, P["marble_dark"])
    parts.append(plinth)
    for k, (x, y, h) in enumerate([(0, 0.2, 1.3), (-0.42, -0.2, 1.05), (0.42, -0.2, 1.1)]):
        robe = cyl("robe", 0.22, h, (x, y, 0.2 + h / 2), verts=12, r2=0.08)
        subsurf(robe, 1)
        noise_displace(robe, 0.04, 0.1)
        assign(robe, P["ash"])
        smooth(robe)
        head = sphere("head", 0.12, (x, y - 0.02, 0.2 + h + 0.08), scale=(0.9, 0.9, 1.15))
        assign(head, P["ash"])
        mouth = sphere("mouth", 0.04, (x, y - 0.12, 0.2 + h + 0.03), scale=(0.8, 0.4, 1.4), seg=8, rings=6)
        assign(mouth, P["ember"])
        _eyes(parts, P, [(x - 0.04, y - 0.11, 0.2 + h + 0.12), (x + 0.04, y - 0.11, 0.2 + h + 0.12)], 0.018)
        book = cube("hymnal", 0.16, (x, y - 0.2, 0.2 + h * 0.62), scale=(1, 0.2, 0.7), rot=(0.6, 0, 0))
        assign(book, P["ash_dark"])
        parts += [robe, head, mouth, book]
        # Cracks of ember light in the robes.
        for i in range(3):
            z = 0.25 + random.uniform(0.1, h * 0.8)
            a = random.uniform(-2.4, -0.7)
            crack = cube("crack", 0.05, (x + 0.2 * math.cos(a), y + 0.2 * math.sin(a), z), scale=(0.3, 0.3, 2.0),
                         rot=(0, random.uniform(-0.4, 0.4), a))
            assign(crack, P["ember"])
            parts.append(crack)
    for i in range(6):
        a = i * 1.047
        c = cyl("candle", 0.04, 0.2, (0.62 * math.cos(a), 0.62 * math.sin(a), 0.3), verts=8)
        assign(c, P["wax"])
        f = sphere("flame", 0.025, (0.62 * math.cos(a), 0.62 * math.sin(a), 0.44), scale=(1, 1, 1.8), seg=8, rings=6)
        assign(f, P["flame"])
        parts += [c, f]
    join(parts, "choir_of_ash")
    finish("choir_of_ash")


def build_drowned_abbess():
    reset()
    P = cloister_palette()
    random.seed(126)
    parts = []
    # Robes that spill out into a pool of black water.
    pool = cyl("pool", 1.0, 0.03, (0, 0, 0.015), verts=24)
    noise_displace(pool, 0.03, 0.3)
    assign(pool, P["pool"])
    skirt = cyl("skirt", 0.75, 0.9, (0, 0, 0.45), verts=20, r2=0.32)
    for v in skirt.data.vertices:
        if v.co.z < 0:
            v.co.x *= random.uniform(1.0, 1.25)
            v.co.y *= random.uniform(1.0, 1.25)
    subsurf(skirt, 1)
    noise_displace(skirt, 0.05, 0.2)
    assign(skirt, P["drowned"])
    smooth(skirt)
    body = cyl("body", 0.32, 0.8, (0, 0, 1.25), verts=16, r2=0.22)
    subsurf(body, 1)
    assign(body, P["drowned_light"])
    smooth(body)
    scap = cyl("scapular", 0.14, 1.2, (0, -0.26, 0.95), verts=8, r2=0.1)
    scap.scale = (1.0, 0.2, 1.0)
    assign(scap, P["mask"])
    head = sphere("wimple", 0.2, (0, 0, 1.8), scale=(1, 1, 1.2))
    assign(head, P["mask"])
    veil = cyl("veil", 0.26, 0.9, (0, 0.06, 1.55), verts=16, r2=0.18)
    noise_displace(veil, 0.03, 0.12)
    assign(veil, P["ghost_dark"])
    # Bring the ivory death-mask in front of the veil; the old face was buried inside it.
    face = sphere("face", 0.19, (0, -0.29, 1.82), scale=(0.95, 0.55, 1.2))
    assign(face, P["mask"])
    for x in (-0.073, 0.073):
        socket = sphere("eye_socket", 0.05, (x, -0.385, 1.86), scale=(1.1, 0.35, 0.7))
        assign(socket, P["ghost_dark"])
        parts.append(socket)
    _eyes(parts, P, [(-0.073, -0.407, 1.86), (0.073, -0.407, 1.86)], 0.022)
    mouth = sphere("silent_mouth", 0.043, (0, -0.393, 1.72), scale=(0.7, 0.25, 1.2))
    assign(mouth, P["ghost_dark"])
    parts.append(mouth)
    for s in (-1, 1):
        sl = cyl("sleeve", 0.1, 0.7, (s * 0.35, -0.1, 1.35), verts=10, r2=0.18, rot=(0.5, s * 0.6, 0))
        assign(sl, P["drowned"])
        parts.append(sl)
    # Bell staff.
    staff = tube("staff", [(0.6, -0.3, 0.0), (0.62, -0.3, 1.2), (0.6, -0.32, 2.2), (0.55, -0.32, 2.5)], 0.035, P["bronze"], taper=False)
    bell = cyl("bell", 0.16, 0.26, (0.55, -0.32, 2.35), verts=16, r2=0.08)
    assign(bell, P["verdigris"])
    # Halo of candles behind the head.
    halo = bpy.ops.mesh.primitive_torus_add(major_radius=0.45, minor_radius=0.03, location=(0, 0.2, 2.0),
                                            rotation=(math.radians(90), 0, 0))
    halo = bpy.context.active_object
    assign(halo, P["bronze"])
    parts += [pool, skirt, body, scap, head, veil, face, staff, bell, halo]
    for i in range(7):
        a = i / 6 * math.pi
        x, z = 0.46 * math.cos(a), 2.0 + 0.46 * math.sin(a)
        c = cyl("candle", 0.048, 0.22, (x, 0.2, z + 0.11), verts=8)
        assign(c, P["wax"])
        f = sphere("flame", 0.032, (x, 0.2, z + 0.27), scale=(1, 1, 1.8), seg=8, rings=6)
        assign(f, P["flame"])
        parts += [c, f]
    # Weeds and chains trailing in the water.
    for i in range(10):
        a = random.uniform(0, 6.28)
        weed = tube("weed", [(0.6 * math.cos(a), 0.6 * math.sin(a), 0.3), (0.85 * math.cos(a), 0.85 * math.sin(a), 0.12),
                             (1.0 * math.cos(a + 0.2), 1.0 * math.sin(a + 0.2), 0.02)], 0.025, P["moss"])
        parts.append(weed)
    for i in range(6):
        a = random.uniform(0, 6.283)
        sp = cyl("spike", 0.06, 0.4, (0.35 * math.cos(a), 0.35 * math.sin(a) + 0.1, 1.5), verts=5, r2=0.0,
                 rot=(random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6), 0))
        assign(sp, P["blight_glow"])
        parts.append(sp)
    join(parts, "drowned_abbess")
    finish("drowned_abbess")


# ------------------------------------------------------------------ room vignettes (camp, shrine, market)

def build_campfire():
    reset()
    P = cloister_palette()
    random.seed(201)
    parts = []
    for i in range(9):
        a = i / 9 * 6.283
        st = ico("stone", random.uniform(0.09, 0.13), (0.34 * math.cos(a), 0.34 * math.sin(a), 0.05),
                 scale=(1.2, 1.0, 0.7), sub=2)
        noise_displace(st, 0.03, 0.1)
        assign(st, P["stone"] if i % 2 else P["stone_dark"])
        parts.append(st)
    ash = cyl("ash", 0.3, 0.03, (0, 0, 0.015), verts=16)
    assign(ash, P["soil_dark"])
    parts.append(ash)
    for i in range(5):
        a = i / 5 * 6.283 + 0.3
        log = cyl("log", 0.045, 0.5, (0.08 * math.cos(a), 0.08 * math.sin(a), 0.14), verts=8,
                  rot=(math.cos(a + math.pi / 2) * 0.9, math.sin(a + math.pi / 2) * 0.9, 0))
        assign(log, P["bark"])
        parts.append(log)
    for i in range(6):
        a = random.uniform(0, 6.28)
        r = random.uniform(0.0, 0.1)
        h = random.uniform(0.18, 0.38)
        fl = cyl("flame", random.uniform(0.05, 0.08), h, (r * math.cos(a), r * math.sin(a), 0.12 + h / 2), verts=6, r2=0.0)
        assign(fl, P["flame"])
        parts.append(fl)
    for i in range(6):
        a = random.uniform(0, 6.28)
        em = sphere("ember", 0.025, (0.15 * math.cos(a), 0.15 * math.sin(a), 0.05), seg=6, rings=4)
        assign(em, P["ember"])
        parts.append(em)
    # Bedroll and a pot on a tripod.
    roll = cyl("bedroll", 0.1, 0.6, (-0.7, 0.25, 0.1), verts=12, rot=(0, math.radians(90), math.radians(20)))
    assign(roll, P["cloth_red"])
    parts.append(roll)
    for k in range(3):
        a = k / 3 * 6.283
        leg = cyl("tripod", 0.015, 0.8, (0.18 * math.cos(a), 0.18 * math.sin(a), 0.36), verts=5,
                  rot=(-math.sin(a) * 0.22, math.cos(a) * 0.22, 0))
        assign(leg, P["bark_light"])
        parts.append(leg)
    pot = sphere("pot", 0.1, (0, 0, 0.5), scale=(1, 1, 0.8), seg=12, rings=8)
    assign(pot, P["iron"])
    parts.append(pot)
    join(parts, "campfire")
    finish("campfire")


def build_pedlar():
    reset()
    P = cloister_palette()
    random.seed(202)
    parts = []
    # Cart bed, wheels, shafts.
    bed = cube("bed", 1.0, (0, 0.2, 0.55), scale=(1.1, 0.7, 0.12))
    assign(bed, P["bark_light"])
    parts.append(bed)
    for s in (-1, 1):
        side = cube("side", 1.0, (s * 0.55, 0.2, 0.72), scale=(0.04, 0.7, 0.25))
        assign(side, P["bark"])
        wheel = cyl("wheel", 0.36, 0.06, (s * 0.62, 0.2, 0.36), verts=16, rot=(0, math.radians(90), 0))
        assign(wheel, P["bark"])
        hub = cyl("hub", 0.07, 0.1, (s * 0.66, 0.2, 0.36), verts=8, rot=(0, math.radians(90), 0))
        assign(hub, P["iron"])
        shaft = cyl("shaft", 0.03, 1.2, (s * 0.35, -0.65, 0.45), verts=6, rot=(math.radians(80), 0, 0))
        assign(shaft, P["bark"])
        parts += [side, wheel, hub, shaft]
        for k in range(6):
            a = k / 6 * 6.283
            sp = cyl("spoke", 0.015, 0.62, (s * 0.62, 0.2, 0.36), verts=4, rot=(a, math.radians(90), 0))
            sp.rotation_euler = (a, 0, 0)
            sp.location = (s * 0.62, 0.2, 0.36)
            assign(sp, P["bark_light"])
            parts.append(sp)
    # Canopy on poles.
    for x in (-0.5, 0.5):
        for y in (-0.12, 0.55):
            pole = cyl("pole", 0.02, 0.9, (x, y, 1.05), verts=6)
            assign(pole, P["bark"])
            parts.append(pole)
    canopy = cube("canopy", 1.0, (0, 0.22, 1.52), scale=(1.2, 0.85, 0.05), rot=(0.12, 0, 0))
    assign(canopy, P["cloth_red"])
    parts.append(canopy)
    for k in range(7):
        fr = cube("fringe", 0.1, (-0.55 + k * 0.18, -0.22, 1.43), scale=(0.9, 0.2, 1.2))
        assign(fr, P["gold"] if k % 2 else P["cloth_red"])
        parts.append(fr)
    # Wares: sacks, jars, bundles.
    for i in range(6):
        x = random.uniform(-0.4, 0.4)
        y = random.uniform(0.0, 0.45)
        sack = ico("sack", random.uniform(0.12, 0.17), (x, y, 0.72), scale=(1, 1, 1.1), sub=2)
        noise_displace(sack, 0.03, 0.1)
        assign(sack, random.choice([P["husk"], P["cloth"], P["reed"]]))
        parts.append(sack)
    for i in range(4):
        jar = cyl("jar", 0.05, 0.14, (-0.35 + i * 0.22, -0.05, 0.68), verts=10)
        assign(jar, P["verdigris"] if i % 2 else P["seed_glow"])
        parts.append(jar)
    lantern = cube("lantern", 0.12, (0.5, -0.2, 1.3), scale=(1, 1, 1.3))
    assign(lantern, P["flame"])
    lcap = cyl("lcap", 0.09, 0.06, (0.5, -0.2, 1.4), verts=4, r2=0.02)
    assign(lcap, P["iron"])
    parts += [lantern, lcap]
    # The pedlar: hunched, hooded, moss-stitched coat, long nose.
    coat = cyl("coat", 0.26, 0.8, (-0.85, -0.3, 0.4), verts=12, r2=0.13)
    subsurf(coat, 1)
    noise_displace(coat, 0.03, 0.12)
    assign(coat, P["bark_light"])
    smooth(coat)
    # A towering pack of wares on the pedlar's back.
    pack = cube("pack", 1.0, (-0.85, -0.05, 0.95), scale=(0.34, 0.26, 0.5), rot=(-0.15, 0, 0))
    assign(pack, P["husk"])
    roll = cyl("packroll", 0.09, 0.42, (-0.85, -0.02, 1.28), verts=10, rot=(0, math.radians(90), 0))
    assign(roll, P["cloth_red"])
    pan = cyl("pan", 0.1, 0.02, (-0.66, 0.02, 0.9), verts=12, rot=(0, math.radians(90), 0))
    assign(pan, P["iron"])
    hump = ico("hump", 0.2, (-0.85, -0.22, 0.8), scale=(1, 1.1, 0.8), sub=2)
    assign(hump, P["bark"])
    hood = sphere("hood", 0.16, (-0.85, -0.3, 0.9), scale=(1, 1.0, 1.05))
    assign(hood, P["cloth"])
    face = sphere("face", 0.1, (-0.85, -0.42, 0.87), scale=(0.9, 0.7, 1.0))
    assign(face, P["skin"])
    nose = cyl("nose", 0.03, 0.16, (-0.85, -0.56, 0.85), verts=6, r2=0.01, rot=(math.radians(100), 0, 0))
    assign(nose, P["skin"])
    _eyes(parts, P, [(-0.89, -0.5, 0.9), (-0.81, -0.5, 0.9)], 0.02)
    parts += [pack, roll, pan, face]
    for i in range(5):
        a = random.uniform(0, 6.28)
        patch = ico("patch", 0.06, (-0.85 + 0.22 * math.cos(a), -0.3 + 0.22 * math.sin(a), random.uniform(0.2, 0.7)),
                    scale=(1, 1, 0.5), sub=1)
        assign(patch, P["moss"])
        parts.append(patch)
    stick = tube("stick", [(-1.1, -0.45, 0.0), (-1.1, -0.47, 0.6), (-1.08, -0.47, 1.05)], 0.02, P["bark_light"], taper=False)
    parts += [coat, hump, hood, nose, stick]
    join(parts, "pedlar")
    finish("pedlar")


def build_altar():
    reset()
    P = cloister_palette()
    random.seed(203)
    parts = []
    base = cyl("base", 0.55, 0.2, (0, 0, 0.1), verts=8)
    assign(base, P["stone_dark"])
    step = cyl("step", 0.42, 0.18, (0, 0, 0.29), verts=8)
    assign(step, P["stone"])
    slab = cube("slab", 1.0, (0, 0.1, 0.95), scale=(0.5, 0.18, 1.1))
    subsurf(slab, 1)
    noise_displace(slab, 0.05, 0.25)
    assign(slab, P["stone"])
    # Carved spiral disc with a glowing seed at its heart.
    disc = cyl("disc", 0.2, 0.04, (0, -0.01, 1.15), verts=24, rot=(math.radians(90), 0, 0))
    assign(disc, P["stone_dark"])
    seed = sphere("seed", 0.07, (0, -0.05, 1.15), scale=(1, 0.7, 1.25))
    assign(seed, P["seed_glow"])
    parts += [base, step, slab, disc, seed]
    for i in range(24):
        a = i / 24 * 6.283 * 2
        rr = 0.03 + i * 0.0065
        dot = sphere("groove", 0.012, (rr * math.cos(a), -0.04, 1.15 + rr * math.sin(a)), seg=6, rings=4)
        assign(dot, P["seed_glow"] if i % 3 == 0 else P["thorn"])
        parts.append(dot)
    # Thorn wreath and offerings.
    for i in range(10):
        a = i / 10 * 6.283
        pts = [(0.45 * math.cos(a), 0.45 * math.sin(a), 0.4), (0.5 * math.cos(a + 0.3), 0.5 * math.sin(a + 0.3), 0.5),
               (0.45 * math.cos(a + 0.6), 0.45 * math.sin(a + 0.6), 0.42)]
        vine = tube("vine", pts, 0.02, P["bark"])
        parts.append(vine)
        lf = ico("leaf", 0.05, pts[1], scale=(1.4, 0.7, 0.2), sub=1)
        assign(lf, P["leaf"])
        parts.append(lf)
    for i in range(3):
        bowl = sphere("bowl", 0.07, (-0.25 + i * 0.25, -0.38, 0.42), scale=(1, 1, 0.45), seg=10, rings=6)
        assign(bowl, P["bark_light"])
        parts.append(bowl)
    for i in range(4):
        c = cyl("candle", 0.03, 0.14, (-0.35 + i * 0.23, -0.5, 0.27), verts=8)
        assign(c, P["wax"])
        f = sphere("flame", 0.022, (-0.35 + i * 0.23, -0.5, 0.37), scale=(1, 1, 1.8), seg=8, rings=6)
        assign(f, P["flame"])
        parts += [c, f]
    join(parts, "altar")
    finish("altar")


# ------------------------------------------------------------------ Glasswood

def glasswood_palette():
    """Opaque cut glass reads at board distance without bloom or transparency noise."""
    return {
        "earth": mat("glasswood_earth", (0.075, 0.095, 0.10), 0.96),
        "floor": mat("glasswood_floor", (0.13, 0.20, 0.20), 0.32, metal=0.12),
        "moss": mat("glasswood_moss", (0.14, 0.23, 0.18), 0.92),
        "bark": mat("glasswood_bark", (0.085, 0.115, 0.12), 0.84),
        "glass": mat("smoked_teal_glass", (0.16, 0.32, 0.34), 0.23, metal=0.20),
        "edge": mat("glass_cut_edge", (0.32, 0.47, 0.47), 0.27, metal=0.12),
        "dark": mat("obsidian_joint", (0.045, 0.065, 0.08), 0.55),
        "stone": mat("glasswood_stone", (0.19, 0.24, 0.26), 0.86),
        "water": mat("mirror_pool", (0.065, 0.12, 0.15), 0.08, metal=0.28),
        "mask": mat("amber_porcelain", (0.68, 0.37, 0.15), 0.52),
        "crown": mat("tarnished_crown", (0.43, 0.29, 0.12), 0.4, metal=0.65),
        "eye": mat("glasswood_amber_eye", (0.95, 0.52, 0.16), 0.4,
                   emit=(1.0, 0.42, 0.09), emit_strength=0.55),
    }


def glass_shard(name, base, tip, radius, material, edge=None):
    """Six-sided crystal with a long cut shoulder and an asymmetric pointed crown."""
    direction = Vector(tip) - Vector(base)
    length = direction.length
    vertices = []
    for z, r in [(0, radius * 0.75), (length * 0.7, radius)]:
        for i in range(6):
            a = i * math.tau / 6
            vertices.append((r * math.cos(a), r * math.sin(a), z))
    vertices.append((radius * 0.14, -radius * 0.1, length))
    faces = [tuple(reversed(range(6)))]
    for i in range(6):
        j = (i + 1) % 6
        faces.extend([(i, j, j + 6, i + 6), (i + 6, j + 6, 12)])
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = base
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    assign(obj, material)
    if edge:
        obj.data.materials.append(edge)
        for polygon in obj.data.polygons:
            if polygon.index in (4, 8, 12):
                polygon.material_index = 1
    return obj


def glasswood_floor(P):
    parts = [assign(hex_prism("root_soil", 0.98, 0.94, -1.0, 0), P["earth"]),
             assign(hex_prism("polished_ground", 0.98, 0.09, -0.07, 0.025), P["floor"])]
    # Broad dark roots and low leaf litter retain a forest floor, not a gem field.
    for i in range(3):
        a = i * 2.1 + 0.3
        parts.append(tube("buried_root", [(0.78 * math.cos(a), 0.78 * math.sin(a), 0.023),
                                          (0.4 * math.cos(a + 0.3), 0.4 * math.sin(a + 0.3), 0.025),
                                          (0.1, 0.05, 0.027)], 0.018, P["bark"]))
        parts.append(assign(ico("moss_island", 0.14, (0.6 * math.cos(a), 0.6 * math.sin(a), 0.025),
                                scale=(1.2, 0.7, 0.15), sub=1), P["moss"]))
    return parts


def build_glasswood_tiles():
    for name in ("hex_glass", "hex_crystal", "hex_mirror"):
        reset()
        P = glasswood_palette()
        if name == "hex_mirror":
            parts = [assign(hex_prism("sunken_bed", 0.98, 0.58, -0.8, 0.025), P["earth"]),
                     assign(hex_prism("still_water", 0.96, 0.018, -0.215, 0.015), P["water"])]
            for x, y, r in [(-0.60, 0.22, 0.17), (0.58, 0.30, 0.13), (0.40, -0.57, 0.10)]:
                parts.append(assign(ico("drowned_stone", r, (x, y, -0.19), scale=(1, 1.2, 0.55), sub=1), P["stone"]))
        else:
            parts = glasswood_floor(P)
            if name == "hex_crystal":
                # Keep the rock below the long crystal shafts. The previous .76m
                # boulder swallowed them, leaving only tiny tips at board distance.
                parts.append(assign(ico("blocking_boulder", 0.44, (0, 0.08, 0.19),
                                        scale=(1.1, 0.9, 0.48), sub=2), P["stone"]))
                for x, y, h, r, lean in [(0.0, 0.12, 1.15, 0.19, -0.06),
                                         (-0.31, -0.13, 0.85, 0.17, -0.18),
                                         (0.28, -0.19, 0.72, 0.15, 0.17)]:
                    parts.append(glass_shard("rooted_crystal", (x, y, 0.06),
                                             (x + lean, y + 0.04, h), r, P["glass"], P["edge"]))
        join(parts, name)
        finish(name)


def build_glasswood_props():
    reset()
    P = glasswood_palette()
    parts = [tube("crooked_trunk", [(0, 0, 0), (-0.1, 0.03, 0.65), (0.05, 0.06, 1.3),
                                    (-0.03, 0.12, 1.9)], 0.15, P["bark"])]
    for side, y, h in [(-1, 0.08, 1.1), (1, 0.10, 1.38), (-1, 0.16, 1.68)]:
        end = (side * 0.52, y, h + 0.22)
        parts.append(tube("bare_bough", [(0, 0.06, h - 0.5), (side * 0.3, y, h - 0.05), end], 0.055, P["bark"]))
        for i in range(3):
            parts.append(glass_shard("crystalline_bud", (end[0] + (i - 1) * 0.09, y, h + 0.10),
                                     (end[0] + side * 0.09 + (i - 1) * 0.15, y + 0.025, h + 0.45 - abs(i - 1) * 0.13),
                                     0.065, P["glass"], P["edge"]))
    for i in range(4):
        a = i * math.pi / 2
        parts.append(tube("root", [(0, 0, 0.15), (0.23 * math.cos(a), 0.23 * math.sin(a), 0.035),
                                   (0.45 * math.cos(a + 0.2), 0.45 * math.sin(a + 0.2), 0.01)], 0.055, P["bark"]))
    join(parts, "crystal_tree")
    finish("crystal_tree")

    reset()
    P = glasswood_palette()
    parts = []
    for k in range(5):
        a = k * math.tau / 5
        direction = Vector((math.cos(a), math.sin(a), 0))
        cross = Vector((-math.sin(a), math.cos(a), 0))
        parts.append(tube("fern_stem", [(0, 0, 0), tuple(direction * 0.24 + Vector((0, 0, 0.32))),
                                       tuple(direction * 0.5 + Vector((0, 0, 0.26)))], 0.013, P["bark"]))
        for j in range(4):
            u = (j + 1) / 5
            base = direction * (0.44 * u) + Vector((0, 0, 0.26 * math.sin(u * 2)))
            for side in (-1, 1):
                tip = base + direction * 0.07 + cross * side * (0.15 - 0.08 * u) + Vector((0, 0, 0.035))
                parts.append(glass_shard("fern_pinna", base, tip, 0.018, P["glass"], P["edge"]))
    join(parts, "glass_fern")
    finish("glass_fern")

    reset()
    P = glasswood_palette()
    parts = [glass_shard("fallen_trunk", (-0.55, 0.0, 0.12), (0.52, 0.15, 0.22), 0.17, P["glass"], P["edge"]),
             assign(ico("moss", 0.20, (-0.25, 0.08, 0.11), scale=(1.6, 0.75, 0.3), sub=1), P["moss"])]
    for x, y in [(0.35, -0.22), (0.6, 0.02), (-0.38, -0.18)]:
        parts.append(glass_shard("fallen_chip", (x, y, 0.015), (x + 0.1, y + 0.02, 0.07), 0.04, P["edge"]))
    join(parts, "fallen_prism")
    finish("fallen_prism")


def glasswood_face(parts, P, center, radius):
    x, y, z = center
    parts.append(assign(ico("amber_mask", radius, center, scale=(0.9, 0.42, 1.05), sub=2), P["mask"]))
    for side in (-1, 1):
        parts.append(assign(ico("dark_socket", radius * 0.24, (x + side * radius * 0.36, y - radius * 0.35, z + radius * 0.1),
                                scale=(1.0, 0.45, 0.65), sub=1), P["dark"]))
    _eyes(parts, P, [(x - radius * 0.36, y - radius * 0.46, z + radius * 0.1),
                     (x + radius * 0.36, y - radius * 0.46, z + radius * 0.1)], radius * 0.09)


def build_shardling():
    reset()
    P = glasswood_palette()
    parts = [assign(ico("angular_body", 0.22, (0, 0.03, 0.32), scale=(0.8, 0.8, 1.15), sub=1), P["glass"])]
    for s in (-1, 1):
        parts.append(tube("bent_leg", [(s * 0.10, 0.02, 0.30), (s * 0.20, -0.02, 0.16),
                                      (s * 0.15, -0.12, 0.025)], 0.038, P["dark"], taper=False))
        parts.append(glass_shard("claw_arm", (s * 0.15, 0.01, 0.40), (s * 0.34, -0.21, 0.22), 0.05, P["edge"]))
        parts.append(glass_shard("ear", (s * 0.10, 0.015, 0.57), (s * 0.18, 0.04, 0.78), 0.055, P["glass"], P["edge"]))
    glasswood_face(parts, P, (0, -0.12, 0.54), 0.15)
    parts.append(glass_shard("back_spur", (0, 0.15, 0.27), (0.07, 0.32, 0.51), 0.075, P["glass"]))
    join(parts, "shardling")
    finish("shardling")


def glasswood_stag(P, lantern=False):
    parts = [assign(ico("ribcage", 0.25, (0, 0.03, 0.43), scale=(0.9 if lantern else 0.7, 1.5, 0.86), sub=2), P["glass"]),
             tube("arched_neck", [(0, -0.18, 0.45), (0, -0.30, 0.59), (0, -0.32, 0.77)], 0.10, P["glass"], taper=False)]
    for side in (-1, 1):
        for y in (-0.18, 0.25):
            parts.append(tube("articulated_leg", [(side * 0.13, y, 0.44), (side * 0.14, y + 0.06, 0.22),
                                                 (side * 0.15, y - 0.04, 0.045)], 0.03, P["dark"], taper=False))
            parts.append(assign(cube("hoof", 0.075, (side * 0.15, y - 0.06, 0.038), scale=(0.7, 1.25, 0.65)), P["crown"]))
        parts.append(glass_shard("ear", (side * 0.08, -0.31, 0.76), (side * 0.22, -0.26, 0.83), 0.044, P["edge"]))
        for k in range(3):
            x = side * (0.14 + k * 0.13) if lantern else side * (0.11 + k * 0.075)
            z = 0.85 + k * 0.045
            parts.append(tube("antler_tine", [(side * 0.07, -0.28, 0.79), (x, -0.21, z),
                                             (x + side * 0.035, -0.19, z + 0.12)], 0.016, P["crown"] if lantern else P["edge"]))
        if lantern:
            # Wide forked antlers and open hanging lanterns distinguish the elite.
            # A solid cylinder hid the old lens; caps and narrow posts leave it visible.
            x = side * 0.38
            parts.append(tube("lantern_hanger", [(x, -0.20, 0.98), (x, -0.21, 0.87)], 0.009, P["dark"], taper=False))
            for z in (0.70, 0.87):
                parts.append(assign(cyl("lantern_cap", 0.09, 0.025, (x, -0.21, z), verts=6), P["crown"]))
            for dx in (-0.07, 0.07):
                parts.append(tube("lantern_post", [(x + dx, -0.21, 0.71), (x + dx, -0.21, 0.86)],
                                  0.009, P["crown"], taper=False))
            parts.append(assign(ico("amber_lantern", 0.068, (x, -0.21, 0.785), scale=(0.8, 0.8, 1.0), sub=1), P["eye"]))
            parts.append(glass_shard("shoulder_ruff", (side * 0.12, -0.13, 0.56),
                                     (side * 0.28, -0.08, 0.70), 0.065, P["glass"], P["edge"]))
    parts.append(assign(ico("long_muzzle", 0.105, (0, -0.39, 0.72), scale=(0.8, 1.5, 0.8), sub=1), P["mask"]))
    _eyes(parts, P, [(-0.065, -0.39, 0.78), (0.065, -0.39, 0.78)], 0.013)
    parts.append(glass_shard("tail", (0, 0.35, 0.48), (0, 0.43, 0.60), 0.047, P["edge"]))
    if lantern:
        for k in range(4):
            parts.append(glass_shard("saddle_plate", (0, 0.30 - k * 0.12, 0.50), (0, 0.34 - k * 0.12, 0.72), 0.075, P["glass"], P["edge"]))
    return parts


def build_prism_stag():
    reset()
    join(glasswood_stag(glasswood_palette()), "prism_stag")
    finish("prism_stag")


def build_lantern_hart():
    reset()
    join(glasswood_stag(glasswood_palette(), lantern=True), "lantern_hart")
    finish("lantern_hart")


def build_glass_mite():
    reset()
    P = glasswood_palette()
    parts = [assign(ico("beetle_abdomen", 0.25, (0, 0.09, 0.27), scale=(1, 1.15, 0.66), sub=2), P["dark"])]
    for side in (-1, 1):
        parts.append(assign(ico("split_elytron", 0.24, (side * 0.105, 0.09, 0.30), scale=(0.53, 1.12, 0.68), sub=1), P["glass"]))
        for k in range(3):
            y = -0.15 + k * 0.16
            parts.append(tube("six_jointed_legs", [(side * 0.16, y, 0.26), (side * (0.33 + (k % 2) * 0.06), y + (k - 1) * 0.08, 0.20),
                                                (side * 0.4, y + (k - 1) * 0.13, 0.02)], 0.026, P["dark"], taper=False))
        parts.append(tube("antenna", [(side * 0.07, -0.25, 0.30), (side * 0.17, -0.38, 0.40),
                                     (side * 0.19, -0.43, 0.45)], 0.012, P["edge"]))
        parts.append(glass_shard("mandible", (side * 0.06, -0.27, 0.20), (side * 0.07, -0.40, 0.15), 0.035, P["crown"]))
    glasswood_face(parts, P, (0, -0.25, 0.27), 0.13)
    join(parts, "glass_mite")
    finish("glass_mite")


def build_splintered_queen():
    reset()
    P = glasswood_palette()
    # 1.30m authored height: ~2.07m at the game's 1.1 * 1.45 boss scale.
    parts = [assign(cyl("gown", 0.30, 0.65, (0, 0.055, 0.36), verts=10, r2=0.10), P["dark"]),
             assign(ico("bodice", 0.18, (0, 0, 0.79), scale=(0.8, 0.75, 1.25), sub=1), P["glass"])]
    for side in (-1, 1):
        parts.append(tube("queen_arm", [(side * 0.12, 0, 0.88), (side * 0.30, -0.07, 0.76),
                                       (side * 0.36, -0.21, 0.91)], 0.032, P["crown"], taper=False))
        parts.append(assign(ico("hand", 0.045, (side * 0.36, -0.21, 0.92), scale=(0.7, 0.8, 1.25), sub=1), P["mask"]))
    glasswood_face(parts, P, (0, -0.10, 1.06), 0.14)
    # Crown remains a readable warm silhouette, with no emissive crystal halo.
    parts.append(assign(cyl("crown_band", 0.12, 0.055, (0, -0.055, 1.18), verts=10), P["crown"]))
    for i in range(5):
        a = i * math.tau / 5
        base = (0.105 * math.cos(a), -0.055 + 0.105 * math.sin(a), 1.19)
        parts.append(glass_shard("crown_point", base, (base[0] * 1.12, base[1], 1.30 - (i % 2) * 0.035),
                                 0.025, P["mask"]))
    join(parts, "splintered_queen_body")
    # Each mantle panel has its own shoulder pivot. Animation is restrained and
    # preserves the large dark gaps between panels at a tactical camera distance.
    for side in (-1, 1):
        panels = []
        for k in range(3):
            panels.append(glass_shard("mantle_shingle", (side * (0.13 + k * 0.075), 0.12, 0.91 - k * 0.04),
                                      (side * (0.24 + k * 0.13), 0.16, 0.21 + k * 0.06),
                                      0.082 - k * 0.009, P["glass"], P["edge"]))
        mantle = join(panels, "mantle_left" if side < 0 else "mantle_right")
        pivot = Vector((side * 0.13, 0.12, 0.91))
        mantle.data.transform(Matrix.Translation(-pivot))
        mantle.location = pivot
        for frame, angle in [(1, -0.025), (25, 0.025), (49, -0.025)]:
            mantle.rotation_euler.y = side * angle
            mantle.keyframe_insert("rotation_euler", frame=frame)
        mantle.animation_data.action.name = "mantle_breath"
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 49
    bpy.context.scene.frame_set(1)
    finish("splintered_queen")


# ------------------------------------------------------------------ region 4: Ironroot Deeps

def ironroot_palette():
    """Soot, rust and old timber, lit by warm lamps. Copper ore gives the only cool accent."""
    return {
        "earth": mat("ironroot_earth", (0.07, 0.055, 0.045), 0.97),
        "floor": mat("packed_spoil", (0.115, 0.11, 0.105), 0.93),
        "gravel": mat("coal_gravel", (0.075, 0.07, 0.07), 0.9),
        "timber": mat("pit_timber", (0.28, 0.17, 0.09), 0.86),
        "timber_dark": mat("tarred_timber", (0.13, 0.08, 0.05), 0.8),
        "rail": mat("rail_iron", (0.30, 0.28, 0.27), 0.45, metal=0.8),
        "rust": mat("flaking_rust", (0.45, 0.19, 0.07), 0.78, metal=0.35),
        "iron": mat("black_iron", (0.10, 0.10, 0.11), 0.52, metal=0.75),
        "rock": mat("seam_rock", (0.24, 0.21, 0.19), 0.9),
        "rock_dark": mat("seam_rock_dark", (0.13, 0.115, 0.11), 0.92),
        "ore": mat("verdigris_ore", (0.16, 0.52, 0.44), 0.35, metal=0.4),
        "water": mat("rust_sump", (0.045, 0.05, 0.05), 0.06, metal=0.35),
        "scum": mat("rust_scum", (0.42, 0.18, 0.06), 0.7),
        "flesh": mat("grub_flesh", (0.78, 0.56, 0.42), 0.55),
        "flesh_dark": mat("grub_fold", (0.36, 0.22, 0.17), 0.7),
        "canvas": mat("miners_canvas", (0.55, 0.47, 0.3), 0.9),
        "brass": mat("tarnished_brass", (0.55, 0.40, 0.16), 0.38, metal=0.8),
        "blight": mat("iron_blight", (0.30, 0.10, 0.36), 0.7),
        "brick": mat("kiln_brick", (0.42, 0.17, 0.11), 0.88),
        "brick_dark": mat("kiln_brick_dark", (0.24, 0.1, 0.07), 0.9),
        "eye": mat("furnace_eye", (1.0, 0.55, 0.18), 0.4, emit=(1.0, 0.42, 0.08), emit_strength=0.8),
        "glow": mat("furnace_glow", (1.0, 0.36, 0.06), 0.5, emit=(1.0, 0.35, 0.05), emit_strength=1.2),
    }


def rock_chunk(name, r, loc, material, seed, squash=0.7):
    random.seed(seed)
    o = ico(name, r, loc, scale=(random.uniform(0.9, 1.3), random.uniform(0.8, 1.15), squash), sub=1)
    o.rotation_euler = (random.uniform(-0.3, 0.3), random.uniform(-0.3, 0.3), random.uniform(0, 6.28))
    return assign(o, material)


def ironroot_floor(P, seed, rails=False):
    random.seed(seed)
    parts = [assign(hex_prism("bedrock", 0.98, 0.94, -1.0, 0), P["earth"]),
             assign(hex_prism("packed_spoil", 0.98, 0.09, -0.07, 0.025), P["floor"])]
    if rails:
        # Rails run edge-to-edge along X (east-west in Godot) so neighbouring rail tiles join.
        for y in (-0.19, 0.19):
            parts.append(assign(cube("rail", 1.0, (0, y, 0.045), scale=(1.7, 0.035, 0.03)), P["rail"]))
        for x in (-0.64, -0.21, 0.21, 0.64):
            parts.append(assign(cube("sleeper", 1.0, (x, 0, 0.022), scale=(0.11, 0.62, 0.03),
                                     rot=(0, 0, random.uniform(-0.08, 0.08))), P["timber_dark"]))
    else:
        # Worn plank walkway fragments and spoil ridges keep open ground from reading as flat.
        for i in range(2):
            a = random.uniform(0, 6.28)
            parts.append(assign(cube("loose_plank", 1.0, (0.35 * math.cos(a), 0.35 * math.sin(a), 0.03),
                                     scale=(0.42, 0.1, 0.025), rot=(0, 0, a + 1.2)), P["timber_dark"]))
    for i in range(7):
        a = random.uniform(0, 6.28)
        d = random.uniform(0.42, 0.8)
        parts.append(rock_chunk("gravel", random.uniform(0.035, 0.06), (d * math.cos(a), d * math.sin(a), 0.02),
                                P["gravel"], seed * 31 + i, 0.5))
    a = random.uniform(0, 6.28)
    parts.append(assign(ico("ore_fleck", 0.05, (0.62 * math.cos(a), 0.62 * math.sin(a), 0.03),
                            scale=(1.3, 0.8, 0.5), sub=1), P["ore"]))
    return parts


def build_ironroot_tiles():
    for name in ("hex_mine", "hex_mine_rail", "hex_rubble", "hex_sump"):
        reset()
        P = ironroot_palette()
        if name == "hex_sump":
            parts = [assign(hex_prism("sump_bed", 0.98, 0.58, -0.8, 0.025), P["earth"]),
                     assign(hex_prism("rust_water", 0.96, 0.018, -0.215, 0.015), P["water"])]
            # A drowned rail end and a sunk cart wheel read as a flooded working, not a pond.
            parts.append(assign(cube("drowned_rail", 1.0, (-0.25, 0.1, -0.2), scale=(0.035, 1.1, 0.03),
                                     rot=(0.12, 0, 0.3)), P["rust"]))
            parts.append(assign(cyl("sunk_wheel", 0.2, 0.05, (0.45, -0.35, -0.16), verts=14,
                                    rot=(math.radians(70), 0, 0.4)), P["rust"]))
            # Rust scum rings the edge so the pool reads as mine water, not bare soil.
            for i in range(6):
                t = i / 6 * 6.283 + 0.3
                parts.append(assign(ico("scum", 0.12, (0.78 * math.cos(t), 0.78 * math.sin(t), -0.2),
                                        scale=(1.6, 0.7, 0.12), sub=1), P["scum"]))
        else:
            parts = ironroot_floor(P, {"hex_mine": 11, "hex_mine_rail": 17}.get(name, 23), rails=name == "hex_mine_rail")
            if name == "hex_rubble":
                # A cave-in: heaped rock under a snapped roof prop. Tall enough to read as a wall.
                for i, (x, y, r, z) in enumerate([(0, 0.05, 0.5, 0.22), (-0.4, -0.25, 0.32, 0.14),
                                                  (0.42, -0.2, 0.34, 0.15), (0.26, 0.4, 0.3, 0.14),
                                                  (-0.36, 0.34, 0.28, 0.12), (0.02, -0.05, 0.38, 0.58),
                                                  (-0.14, 0.14, 0.28, 0.86), (0.18, 0.1, 0.22, 1.0)]):
                    parts.append(rock_chunk("fallen_rock", r, (x, y, z), P["rock"] if i % 2 else P["rock_dark"],
                                            400 + i, 0.75))
                parts.append(assign(cube("snapped_prop", 1.0, (0.3, -0.25, 0.75), scale=(0.1, 0.1, 1.1),
                                         rot=(0.55, 0.35, 0)), P["timber"]))
                parts.append(assign(cube("split_cap", 1.0, (-0.25, 0.1, 0.42), scale=(0.7, 0.1, 0.1),
                                         rot=(0.2, 0.5, 0.7)), P["timber_dark"]))
                parts.append(assign(ico("exposed_ore", 0.09, (0.3, -0.3, 0.3), scale=(1.2, 0.8, 0.7), sub=1), P["ore"]))
        join(parts, name)
        finish(name)


def build_ironroot_props():
    # Timber roof set: two posts and a cap beam with a hanging lamp.
    reset()
    P = ironroot_palette()
    parts = []
    for s in (-1, 1):
        parts.append(assign(cube("post", 1.0, (s * 0.55, 0, 0.9), scale=(0.14, 0.14, 1.8), rot=(0, s * 0.06, 0)), P["timber"]))
        parts.append(assign(cube("foot_wedge", 1.0, (s * 0.55, 0, 0.06), scale=(0.24, 0.24, 0.12)), P["timber_dark"]))
        parts.append(assign(cube("brace", 1.0, (s * 0.4, 0, 1.62), scale=(0.08, 0.08, 0.42), rot=(0, -s * 0.8, 0)), P["timber_dark"]))
    parts.append(assign(cube("cap_beam", 1.0, (0, 0, 1.84), scale=(1.45, 0.18, 0.16)), P["timber"]))
    parts.append(tube("lamp_chain", [(0.2, 0, 1.76), (0.2, 0, 1.5)], 0.01, P["iron"], taper=False))
    parts.append(assign(cyl("lamp_cage", 0.07, 0.16, (0.2, 0, 1.42), verts=6), P["brass"]))
    parts.append(assign(sphere("lamp_flame", 0.045, (0.2, 0, 1.42), seg=8, rings=6), P["glow"]))
    join(parts, "timber_frame")
    finish("timber_frame")

    # Abandoned ore cart, tipped slightly, spilling ore.
    reset()
    P = ironroot_palette()
    parts = [assign(cube("tub", 1.0, (0, 0, 0.36), scale=(0.5, 0.72, 0.36), rot=(0.08, 0, 0)), P["rust"]),
             assign(cube("tub_rim", 1.0, (0, 0, 0.55), scale=(0.56, 0.78, 0.05), rot=(0.08, 0, 0)), P["iron"])]
    for x in (-0.27, 0.27):
        for y in (-0.24, 0.24):
            parts.append(assign(cyl("wheel", 0.12, 0.05, (x, y, 0.12), verts=14, rot=(0, math.radians(90), 0)), P["iron"]))
    for i in range(6):
        parts.append(rock_chunk("ore_load", 0.1, (random.uniform(-0.15, 0.15), random.uniform(-0.25, 0.25), 0.58),
                                P["ore"] if i % 3 == 0 else P["rock_dark"], 700 + i))
    join(parts, "ore_cart")
    finish("ore_cart")

    # Low filler: rock spoil and a copper seam.
    reset()
    P = ironroot_palette()
    parts = []
    for i in range(5):
        a = i * 1.3
        parts.append(rock_chunk("spoil", 0.1 + (i % 3) * 0.035, (0.18 * math.cos(a), 0.18 * math.sin(a), 0.05),
                                P["rock"] if i % 2 else P["rock_dark"], 800 + i))
    for i in range(3):
        parts.append(assign(ico("copper_seam", 0.055, (0.12 * i - 0.1, -0.05 * i, 0.16 + 0.03 * i),
                                scale=(1.3, 0.7, 0.8), sub=1), P["ore"]))
    join(parts, "ore_spoil")
    finish("ore_spoil")


def build_rustgrub():
    reset()
    P = ironroot_palette()
    parts = []
    # Segmented larva, head toward -Y, rust plates along the back.
    for i in range(5):
        y = -0.22 + i * 0.13
        r = 0.16 - abs(i - 1.5) * 0.02
        parts.append(assign(ico("segment", r, (0, y, r * 0.9), scale=(1.0, 0.85, 0.85), sub=2),
                            P["flesh"] if i % 2 == 0 else P["flesh_dark"]))
        parts.append(assign(cube("rust_plate", 1.0, (0, y, r * 1.7), scale=(r * 1.5, 0.09, 0.04),
                                 rot=(0.2, 0, 0)), P["rust"]))
        for s in (-1, 1):
            parts.append(tube("stub_leg", [(s * r * 0.8, y, r * 0.5), (s * r * 1.25, y - 0.02, 0.02)],
                              0.02, P["flesh_dark"], taper=False))
    head = (0, -0.34, 0.16)
    parts.append(assign(ico("head", 0.14, head, scale=(1.0, 0.9, 0.9), sub=2), P["flesh_dark"]))
    for s in (-1, 1):
        parts.append(tube("mandible", [(s * 0.07, -0.44, 0.12), (s * 0.1, -0.53, 0.1), (s * 0.03, -0.58, 0.09)],
                          0.022, P["iron"]))
    _eyes(parts, P, [(-0.06, -0.46, 0.21), (0.06, -0.46, 0.21)], 0.028)
    join(parts, "rustgrub")
    finish("rustgrub")


def build_cart_golem():
    reset()
    P = ironroot_palette()
    random.seed(77)
    parts = []
    # An ore cart that learned to stand: tub torso, rail-iron legs, firebox belly, wheel shoulders.
    parts.append(assign(cube("tub_torso", 1.0, (0, 0, 0.78), scale=(0.62, 0.5, 0.46), rot=(0.1, 0, 0)), P["rust"]))
    parts.append(assign(cube("tub_rim", 1.0, (0, 0.02, 1.02), scale=(0.68, 0.56, 0.06), rot=(0.1, 0, 0)), P["iron"]))
    parts.append(assign(cube("firebox", 1.0, (0, -0.26, 0.68), scale=(0.3, 0.06, 0.2)), P["iron"]))
    parts.append(assign(cube("fire_grate", 1.0, (0, -0.29, 0.68), scale=(0.22, 0.02, 0.12)), P["glow"]))
    for i in range(5):
        parts.append(rock_chunk("ore_heap", 0.12, (random.uniform(-0.2, 0.2), random.uniform(-0.1, 0.18), 1.08),
                                P["ore"] if i == 2 else P["rock_dark"], 900 + i))
    # Head: a miner's lamp in an iron hood.
    parts.append(assign(cube("hood", 1.0, (0, -0.12, 1.2), scale=(0.24, 0.2, 0.18)), P["iron"]))
    parts.append(assign(cyl("head_lamp", 0.06, 0.05, (0, -0.23, 1.22), verts=12, rot=(math.radians(90), 0, 0)), P["brass"]))
    _eyes(parts, P, [(-0.07, -0.23, 1.14), (0.07, -0.23, 1.14)], 0.03)
    for s in (-1, 1):
        parts.append(assign(cyl("wheel_shoulder", 0.17, 0.07, (s * 0.36, -0.02, 0.95), verts=16,
                                rot=(0, math.radians(90), 0)), P["iron"]))
        parts.append(tube("arm", [(s * 0.38, -0.02, 0.9), (s * 0.46, -0.12, 0.6), (s * 0.44, -0.24, 0.38)],
                          0.06, P["rail"], taper=False))
        parts.append(assign(cube("ram_fist", 1.0, (s * 0.44, -0.27, 0.32), scale=(0.16, 0.18, 0.16)), P["iron"]))
        parts.append(tube("leg", [(s * 0.2, 0.05, 0.56), (s * 0.24, 0.0, 0.3), (s * 0.22, 0.02, 0.04)],
                          0.07, P["rail"], taper=False))
        parts.append(assign(cube("foot", 1.0, (s * 0.22, -0.05, 0.04), scale=(0.18, 0.28, 0.08)), P["iron"]))
    join(parts, "cart_golem")
    finish("cart_golem")


def build_tunneler():
    reset()
    P = ironroot_palette()
    parts = []
    # Hunched mole-miner: canvas coat, a lamp helm, digging claws and a pick across the back.
    parts.append(assign(ico("coat", 0.24, (0, 0.04, 0.42), scale=(0.95, 0.85, 1.2), sub=2), P["canvas"]))
    parts.append(assign(ico("snout_head", 0.15, (0, -0.16, 0.7), scale=(0.9, 1.2, 0.85), sub=2), P["flesh_dark"]))
    parts.append(assign(ico("nose", 0.045, (0, -0.33, 0.68), sub=1), P["flesh"]))
    parts.append(assign(sphere("helm", 0.14, (0, -0.12, 0.8), scale=(1.05, 1.05, 0.6), seg=14, rings=8), P["brass"]))
    parts.append(assign(cyl("helm_lamp", 0.045, 0.05, (0, -0.26, 0.83), verts=10, rot=(math.radians(80), 0, 0)), P["glow"]))
    _eyes(parts, P, [(-0.06, -0.28, 0.72), (0.06, -0.28, 0.72)], 0.022)
    for s in (-1, 1):
        parts.append(tube("arm", [(s * 0.18, -0.02, 0.52), (s * 0.28, -0.14, 0.36), (s * 0.24, -0.26, 0.26)],
                          0.045, P["canvas"], taper=False))
        for k in range(3):
            parts.append(tube("claw", [(s * 0.24, -0.26, 0.26), (s * (0.22 + k * 0.03), -0.36, 0.2 - k * 0.02)],
                              0.014, P["iron"]))
        parts.append(tube("leg", [(s * 0.12, 0.05, 0.22), (s * 0.14, 0.0, 0.03)], 0.05, P["flesh_dark"], taper=False))
    parts.append(tube("pick_haft", [(-0.26, 0.24, 0.2), (0.24, 0.22, 0.78)], 0.02, P["timber"], taper=False))
    parts.append(tube("pick_head", [(0.1, 0.24, 0.86), (0.24, 0.22, 0.78), (0.4, 0.2, 0.66)], 0.025, P["iron"]))
    join(parts, "tunneler")
    finish("tunneler")


def build_foundry_heart():
    reset()
    P = ironroot_palette()
    parts = []
    # A wide, squat brick crucible fused into the rock: low and broad, with a molten bowl on top
    # and a huge glowing maw, so it never shares the Engine's tall boiler-and-stack silhouette.
    for i in range(8):
        a = i / 8 * 6.283
        parts.append(rock_chunk("root_rock", 0.2, (0.5 * math.cos(a), 0.5 * math.sin(a), 0.1),
                                P["rock"] if i % 2 else P["rock_dark"], 1000 + i))
    parts.append(assign(cyl("crucible_body", 0.5, 0.62, (0, 0, 0.42), verts=10, r2=0.58), P["brick"]))
    for z in (0.2, 0.62):
        parts.append(assign(cyl("brick_course", 0.53 + (z - 0.2) * 0.12, 0.06, (0, 0, z), verts=10), P["brick_dark"]))
    parts.append(assign(cyl("rim", 0.6, 0.08, (0, 0, 0.75), verts=12), P["iron"]))
    parts.append(assign(cyl("molten_bowl", 0.5, 0.03, (0, 0, 0.78), verts=16), P["glow"]))
    parts.append(assign(cube("maw", 1.0, (0, -0.46, 0.36), scale=(0.44, 0.12, 0.26)), P["glow"]))
    parts.append(assign(cube("maw_lip", 1.0, (0, -0.52, 0.22), scale=(0.5, 0.1, 0.06)), P["iron"]))
    _eyes(parts, P, [(-0.17, -0.5, 0.58), (0.17, -0.5, 0.58)], 0.06)
    # Pouring lip facing the player: a tongue of slag.
    parts.append(assign(cube("pour_spout", 1.0, (0.36, -0.36, 0.72), scale=(0.16, 0.26, 0.06), rot=(0.3, 0, 0.6)), P["iron"]))
    for s in (-1, 1):
        # Bellows arms with brass nozzles.
        parts.append(assign(cube("bellows", 1.0, (s * 0.66, 0.05, 0.42), scale=(0.14, 0.34, 0.24), rot=(0, s * 0.3, 0)), P["canvas"]))
        parts.append(assign(cyl("nozzle", 0.045, 0.22, (s * 0.56, -0.14, 0.4), verts=8, rot=(math.radians(80), 0, s * 0.4)), P["brass"]))
    join(parts, "foundry_heart")
    finish("foundry_heart")


def build_engine_of_rot():
    reset()
    P = ironroot_palette()
    parts = []
    # A mine winding-engine grown through with Blight. ~1.35m authored height.
    parts.append(assign(cube("chassis", 1.0, (0, 0.05, 0.3), scale=(0.7, 0.9, 0.26)), P["iron"]))
    for x in (-0.38, 0.38):
        for y in (-0.3, 0.38):
            parts.append(assign(cyl("drive_wheel", 0.2, 0.08, (x, y, 0.2), verts=18, rot=(0, math.radians(90), 0)), P["rust"]))
    parts.append(assign(cyl("boiler", 0.3, 0.8, (0, 0.12, 0.66), verts=16, rot=(math.radians(90), 0, 0)), P["rust"]))
    for y in (-0.15, 0.12, 0.4):
        parts.append(assign(cyl("boiler_band", 0.315, 0.04, (0, y, 0.66), verts=16, rot=(math.radians(90), 0, 0)), P["iron"]))
    parts.append(assign(cyl("smokestack", 0.1, 0.5, (0, 0.3, 1.08), verts=12, r2=0.14), P["iron"]))
    parts.append(assign(cyl("stack_glow", 0.12, 0.03, (0, 0.3, 1.34), verts=12), P["glow"]))
    # Face: a furnace door under a riveted brow, with a toothed cowcatcher jaw.
    parts.append(assign(cyl("furnace_face", 0.24, 0.06, (0, -0.3, 0.66), verts=16, rot=(math.radians(90), 0, 0)), P["iron"]))
    parts.append(assign(cube("mouth_grate", 1.0, (0, -0.34, 0.58), scale=(0.28, 0.03, 0.08)), P["glow"]))
    parts.append(assign(cube("brow", 1.0, (0, -0.33, 0.8), scale=(0.44, 0.08, 0.06), rot=(0.25, 0, 0)), P["rust"]))
    _eyes(parts, P, [(-0.1, -0.35, 0.72), (0.1, -0.35, 0.72)], 0.045)
    for k in range(5):
        x = -0.28 + k * 0.14
        parts.append(assign(cyl("cowcatcher_tooth", 0.045, 0.22, (x, -0.52, 0.14), verts=4, r2=0.0,
                                rot=(math.radians(-70), 0, 0)), P["rail"]))
    # Blight grows through the seams.
    random.seed(1200)
    for i in range(6):
        parts.append(assign(sphere("blight_bloom", 0.07, (random.uniform(-0.3, 0.3), random.uniform(0.0, 0.5), 0.92),
                                   scale=(1, 1, 0.55), seg=10, rings=6), P["blight"]))
    for s in (-1, 1):
        parts.append(tube("blight_vine", [(s * 0.3, 0.45, 0.4), (s * 0.36, 0.3, 0.8), (s * 0.2, 0.1, 0.98)], 0.03, P["blight"]))
    join(parts, "engine_of_rot_body")
    # Piston arms rise and fall on each side: pivot at the boiler shoulder.
    for side in (-1, 1):
        arm = join([tube("piston_rod", [(side * 0.36, 0.0, 0.0), (side * 0.52, -0.2, -0.28), (side * 0.5, -0.36, -0.45)],
                         0.05, P["rail"], taper=False),
                    assign(cube("piston_head", 1.0, (side * 0.5, -0.38, -0.5), scale=(0.18, 0.2, 0.14)), P["iron"])],
                   "piston_left" if side < 0 else "piston_right")
        arm.location = Vector((0, 0.05, 0.8))
        # The two pistons alternate strokes.
        for frame, up in [(1, side > 0), (13, side < 0), (25, side > 0)]:
            arm.rotation_euler.x = 0.18 if up else 0.0
            arm.keyframe_insert("rotation_euler", frame=frame)
        arm.animation_data.action.name = "piston_stroke"
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 25
    bpy.context.scene.frame_set(1)
    finish("engine_of_rot")


BUILDERS = {
    "hex": build_hex_tiles,
    "thicket": build_thicket,
    "blight": build_blight,
    "grovewalker": build_grovewalker,
    "blightling": build_blightling,
    "rotmoth": build_rotmoth,
    "husk_brute": build_husk_brute,
    "sporecaller": build_sporecaller,
    "bog_warden": build_bog_warden,
    "mire_mother": build_mire_mother,
    "props": build_props,
    "cloister_tiles": build_cloister_tiles,
    "cloister_props": build_cloister_props,
    "censer_wraith": build_censer_wraith,
    "bell_ghoul": build_bell_ghoul,
    "moss_knight": build_moss_knight,
    "drowned_novice": build_drowned_novice,
    "choir_of_ash": build_choir_of_ash,
    "drowned_abbess": build_drowned_abbess,
    "campfire": build_campfire,
    "pedlar": build_pedlar,
    "altar": build_altar,
    "glasswood_tiles": build_glasswood_tiles,
    "glasswood_props": build_glasswood_props,
    "shardling": build_shardling,
    "prism_stag": build_prism_stag,
    "glass_mite": build_glass_mite,
    "lantern_hart": build_lantern_hart,
    "splintered_queen": build_splintered_queen,
    "ironroot_tiles": build_ironroot_tiles,
    "ironroot_props": build_ironroot_props,
    "rustgrub": build_rustgrub,
    "cart_golem": build_cart_golem,
    "tunneler": build_tunneler,
    "foundry_heart": build_foundry_heart,
    "engine_of_rot": build_engine_of_rot,
}


def main():
    only = None
    if "--" in sys.argv:
        for a in sys.argv[sys.argv.index("--") + 1:]:
            if a.startswith("only="):
                only = a[5:].split(",")
    for name, fn in BUILDERS.items():
        if only and name not in only:
            continue
        fn()


main()
