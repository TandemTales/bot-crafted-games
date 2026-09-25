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
