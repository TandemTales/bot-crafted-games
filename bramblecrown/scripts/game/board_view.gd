class_name BoardView
extends Node3D
## 3D diorama for a CombatState: tiles, growth props, units, overlays, and intent paths.

const HEX_SIZE := 1.0
const UNIT_SCALE := 1.45
const OUTLINE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
uniform vec4 color : source_color = vec4(0.02, 0.02, 0.02, 1.0);
uniform float width = 0.022;
void vertex() {
	VERTEX += NORMAL * width;
}
void fragment() {
	ALBEDO = color.rgb;
}
"""
const MODELS := "res://assets/models/%s.glb"
## Per-region look: tile models, surrounding props, and lighting.
const THEMES := {
	"ironroot": {
		"plain": "hex_mine", "stone": "hex_rubble", "water": "hex_sump",
		"outer": [["hex_mine", 0.7], ["hex_rubble", 0.3]],
		"props": [["timber_frame", 0.10], ["ore_spoil", 0.26], ["ore_cart", 0.05], ["blight", 0.10]],
		"tall": ["timber_frame"], "filler": "ore_spoil", "tall_scale": {"timber_frame": 1.0},
		"bg": Color(0.05, 0.04, 0.035), "ambient": Color(0.5, 0.44, 0.4), "fog": Color(0.13, 0.09, 0.07),
		"key": Color(1.0, 0.9, 0.78), "key_energy": 1.6, "rim": Color(0.35, 0.62, 0.58),
		"pool": Color(0.04, 0.035, 0.03),
		"water_color": Color(0.1, 0.09, 0.08),
		"lamp_prop": "timber_frame",
	},
	"glasswood": {
		"plain": "hex_glass", "stone": "hex_crystal", "water": "hex_mirror",
		"outer": [["hex_glass", 0.85], ["hex_mirror", 0.15]],
		"props": [["crystal_tree", 0.09], ["glass_fern", 0.20], ["fallen_prism", 0.06]],
		"tall": ["crystal_tree"], "filler": "glass_fern", "tall_scale": {"crystal_tree": 1.0},
		"bg": Color(0.035, 0.055, 0.075), "ambient": Color(0.40, 0.52, 0.59), "fog": Color(0.08, 0.15, 0.19),
		"key": Color(1.0, 0.86, 0.69), "key_energy": 1.35, "rim": Color(0.28, 0.58, 0.72),
		"pool": Color(0.025, 0.06, 0.075),
		"water_color": Color(0.16, 0.32, 0.39),
	},
	"marsh": {
		"plain": "hex_peat", "stone": "hex_stone", "water": "hex_water",
		"outer": [["hex_peat", 0.8], ["hex_stone", 0.2]],
		"props": [["willow", 0.16], ["reeds", 0.34], ["menhir", 0.06], ["blight", 0.14]],
		"tall": ["willow", "menhir"], "filler": "reeds", "tall_scale": {"willow": 1.4},
		"bg": Color(0.045, 0.06, 0.065), "ambient": Color(0.42, 0.5, 0.52), "fog": Color(0.1, 0.14, 0.15),
		"key": Color(1.0, 0.86, 0.66), "key_energy": 1.7, "rim": Color(0.55, 0.45, 0.95),
		"pool": Color(0.03, 0.06, 0.06),
	},
	"cloister": {
		"plain": "hex_flag", "stone": "hex_pillar", "water": "hex_flood",
		"outer": [["hex_flag", 0.75], ["hex_flood", 0.25]],
		"props": [["arch", 0.12], ["candles", 0.22], ["bell_fallen", 0.05], ["blight", 0.12]],
		"tall": ["arch"], "filler": "candles", "tall_scale": {"arch": 1.1},
		"bg": Color(0.035, 0.045, 0.07), "ambient": Color(0.4, 0.46, 0.6), "fog": Color(0.08, 0.1, 0.16),
		"key": Color(0.82, 0.86, 1.0), "key_energy": 1.45, "rim": Color(0.35, 0.7, 0.9),
		"pool": Color(0.025, 0.045, 0.07),
		"candle_lights": true,
	},
}
const OVERLAY_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float pulse = 0.0;
void fragment() {
	float edge = smoothstep(0.55, 1.0, UV.x);
	float p = 1.0 - pulse * (0.5 + 0.5 * sin(TIME * 5.0));
	ALBEDO = tint.rgb;
	ALPHA = tint.a * (0.18 + 0.82 * edge) * p;
}
"""

var combat: CombatState
var tiles := {}  # Vector2i -> Node3D
var tile_height := {}  # Vector2i -> float
var growth_nodes := {}  # Vector2i -> Node3D
var overlays := {}  # Vector2i -> MeshInstance3D
var units := {}  # "player" | uid -> Node3D
var _scenes := {}
var _overlay_mesh: ArrayMesh
var _overlay_shader: Shader
var _path_root: Node3D
var _time := 0.0
var _unit_base := {}  # node -> base y
var player_light: OmniLight3D
var _outline_mat: ShaderMaterial
var _incoming: Label3D
var _candle_lights := 0
var theme: Dictionary = THEMES["marsh"]


func _ready() -> void:
	_overlay_shader = Shader.new()
	_overlay_shader.code = OVERLAY_SHADER
	_overlay_mesh = _make_hex_mesh(0.93)
	_path_root = Node3D.new()
	add_child(_path_root)
	var osh := Shader.new()
	osh.code = OUTLINE_SHADER
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = osh
	_incoming = Label3D.new()
	_incoming.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_incoming.font = UITheme.font("title")
	_incoming.font_size = 96
	_incoming.pixel_size = 0.006
	_incoming.outline_size = 24
	_incoming.modulate = Color(1, 0.35, 0.28)
	_incoming.outline_modulate = Color(0.05, 0, 0, 1)
	_incoming.no_depth_test = true
	_incoming.visible = false
	add_child(_incoming)


## Moody marsh lighting shared by combat and title: warm key, cold violet rim, fog, glow.
static func make_environment(parent: Node, theme_id: String = "marsh") -> void:
	var th: Dictionary = THEMES.get(theme_id, THEMES["marsh"])
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = th["bg"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = th["ambient"]
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.1
	env.ssao_enabled = true
	env.ssao_radius = 0.8
	env.ssao_intensity = 1.6
	env.ssr_enabled = true
	env.fog_enabled = true
	env.fog_light_color = th["fog"]
	env.fog_density = 0.018
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.05
	we.environment = env
	parent.add_child(we)
	var key := DirectionalLight3D.new()
	key.light_color = th["key"]
	key.light_energy = th["key_energy"]
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 40.0
	key.rotation_degrees = Vector3(-52, -38, 0)
	parent.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_color = th["rim"]
	rim.light_energy = 0.55
	rim.rotation_degrees = Vector3(-25, 150, 0)
	parent.add_child(rim)


func scene(name_: String) -> PackedScene:
	if not _scenes.has(name_):
		_scenes[name_] = load(MODELS % name_)
	return _scenes[name_]


func world(h: Vector2i) -> Vector3:
	var p := Hex.to_world(h, HEX_SIZE)
	p.y = float(tile_height.get(h, 0.0))
	return p


# ------------------------------------------------------------------ build

func build(c: CombatState, region_seed: int = 1, theme_id: String = "marsh") -> void:
	combat = c
	theme = THEMES.get(theme_id, THEMES["marsh"])
	var rng := RandomNumberGenerator.new()
	rng.seed = region_seed
	for h in c.terrain:
		var t: String = c.terrain[h]
		var tile: Node3D = scene(theme["water"] if t == "water" else (theme["stone"] if t == "stone" else theme["plain"])).instantiate()
		var hgt := rng.randf_range(-0.03, 0.04) if t != "water" else -0.0
		tile_height[h] = hgt if t != "water" else -0.25
		tile.position = Hex.to_world(h, HEX_SIZE) + Vector3(0, hgt, 0)
		tile.rotation.y = deg_to_rad(60.0 * rng.randi_range(0, 5))
		add_child(tile)
		tiles[h] = tile
		if t == "water":
			tile.add_child(_water_disc())
		var ov := MeshInstance3D.new()
		ov.mesh = _overlay_mesh
		var m := ShaderMaterial.new()
		m.shader = _overlay_shader
		m.set_shader_parameter("tint", Color(0, 0, 0, 0))
		ov.material_override = m
		ov.position = world(h) + Vector3(0, 0.1, 0)
		ov.visible = false
		ov.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ov)
		overlays[h] = ov
	for h in c.growth:
		_set_growth_node(h, c.growth[h], false)
	# Units.
	var p: Node3D = scene("grovewalker").instantiate()
	add_child(p)
	units["player"] = p
	p.position = world(c.player["pos"])
	p.scale = Vector3.ONE * UNIT_SCALE
	_decorate_unit(p, Color(0.55, 1.0, 0.4))
	player_light = OmniLight3D.new()
	player_light.light_color = Color(0.7, 1.0, 0.45)
	player_light.light_energy = 1.4
	player_light.omni_range = 4.5
	player_light.position = Vector3(0.3, 1.6, 0.2)
	player_light.shadow_enabled = false
	p.add_child(player_light)
	for e in c.enemies:
		add_enemy(e, false)
	face_units()
	_build_surroundings(rng)


func add_enemy(e: Dictionary, animate: bool) -> Node3D:
	var n: Node3D = scene(e["def"]["model"]).instantiate()
	add_child(n)
	var s := float(e["def"].get("size", 1.0)) * UNIT_SCALE
	n.position = world(e["pos"])
	units[e["uid"]] = n
	_start_anims(n)
	_decorate_unit(n, Color(1.0, 0.3, 0.22) if not e["def"].get("boss", false) else Color(1.0, 0.55, 0.15))
	if animate:
		n.scale = Vector3.ONE * 0.01
		var tw := create_tween()
		tw.tween_property(n, "scale", Vector3.ONE * s, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		n.scale = Vector3.ONE * s
	return n


## Dark silhouette outline plus a glowing team ring under the unit.
func _decorate_unit(n: Node3D, ring_col: Color) -> void:
	for node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var m: Mesh = mi.mesh
		if m == null:
			continue
		for si in m.get_surface_count():
			var base := mi.get_active_material(si)
			if base and base.next_pass == null:
				var dup: Material = base.duplicate()
				dup.next_pass = _outline_mat
				mi.set_surface_override_material(si, dup)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.5
	tm.outer_radius = 0.58
	tm.rings = 32
	tm.ring_segments = 6
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = ring_col
	ring.material_override = rm
	# Rings are children of the scaled unit; undo the unit scale so every ring matches the hex.
	var us := maxf(0.05, n.scale.x)
	ring.scale = Vector3(1.0 / us, 0.12 / us, 1.0 / us)
	ring.position.y = 0.06 / us
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.name = "TeamRing"
	n.add_child(ring)


func _start_anims(n: Node) -> void:
	var ap := n.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.get_animation_list().size() > 0:
		var anim_name: StringName = ap.get_animation_list()[0]
		ap.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
		ap.play(anim_name)


func _water_disc() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _make_hex_mesh(0.97)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.04, 0.09, 0.09, 0.88)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.04
	m.metallic_specular = 0.9
	if theme.has("water_color"):
		m.albedo_color = theme["water_color"]
		m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		m.roughness = 0.28
		m.metallic_specular = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.position.y = -0.1
	return mi


func _build_surroundings(rng: RandomNumberGenerator) -> void:
	# Dark marsh water plane under everything.
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(140, 140)
	water.mesh = pm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = theme["pool"]
	wm.roughness = 0.06
	wm.metallic_specular = 0.8
	water.material_override = wm
	water.position.y = -0.55
	add_child(water)
	# Drowned outer tiles and props ringing the arena.
	var r := combat.radius
	for ring_r in range(r + 1, r + 5):
		for h in Hex.ring(Vector2i.ZERO, ring_r):
			var roll := rng.randf()
			if roll < 0.35 + 0.1 * (ring_r - r):
				continue
			var tr := rng.randf()
			var tname: String = theme["outer"][0][0]
			for o in theme["outer"]:
				if tr < o[1]:
					tname = o[0]
					break
				tr -= o[1]
			var t: Node3D = scene(tname).instantiate()
			t.position = Hex.to_world(h, HEX_SIZE) + Vector3(0, -0.35 - 0.12 * (ring_r - r) + rng.randf_range(-0.1, 0.1), 0)
			t.rotation.y = deg_to_rad(60.0 * rng.randi_range(0, 5))
			add_child(t)
			var prop_roll := rng.randf()
			var prop := ""
			for pr in theme["props"]:
				if prop_roll < pr[1]:
					prop = pr[0]
					break
				prop_roll -= pr[1]
			# Tall props in front of the board would cover the hand and End Turn button.
			if prop in theme["tall"] and (t.position.z > -1.0 or ring_r < r + 2):
				prop = theme["filler"] if t.position.z < combat.radius * 1.5 else ""
			if prop != "":
				var pn: Node3D = scene(prop).instantiate()
				pn.position = t.position + Vector3(rng.randf_range(-0.3, 0.3), 0.05, rng.randf_range(-0.3, 0.3))
				pn.rotation.y = rng.randf_range(0, TAU)
				if prop == "arch":
					# Arches face the board so they frame it rather than cut across it.
					pn.rotation.y = atan2(t.position.x, t.position.z) + PI * 0.5
				var sc := rng.randf_range(0.8, 1.3) * float(theme["tall_scale"].get(prop, 1.0))
				pn.scale = Vector3.ONE * sc
				add_child(pn)
				var lamp: bool = prop == theme.get("lamp_prop", "")
				if ((prop == "candles" and theme.get("candle_lights", false)) or lamp) and _candle_lights < 6:
					_candle_lights += 1
					var cl := OmniLight3D.new()
					cl.light_color = Color(1.0, 0.68, 0.32)
					cl.light_energy = 1.6
					cl.omni_range = 3.2
					cl.position = pn.position + Vector3(0, 1.4 * sc if lamp else 0.6, 0)
					add_child(cl)


func _make_hex_mesh(radius: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 6:
		var a0 := deg_to_rad(60.0 * i + 30.0)
		var a1 := deg_to_rad(60.0 * (i + 1) + 30.0)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(Vector3.ZERO)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(Vector3(cos(a1), 0, sin(a1)) * radius)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(Vector3(cos(a0), 0, sin(a0)) * radius)
	return st.commit()


# ------------------------------------------------------------------ growth

func _set_growth_node(h: Vector2i, g: String, animate: bool) -> void:
	if growth_nodes.has(h):
		var old: Node3D = growth_nodes[h]
		growth_nodes.erase(h)
		if animate:
			var tw := create_tween()
			tw.tween_property(old, "scale", Vector3.ONE * 0.01, 0.25).set_trans(Tween.TRANS_QUAD)
			tw.tween_callback(old.queue_free)
		else:
			old.queue_free()
	if g == "none":
		return
	var n: Node3D = scene(g).instantiate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(h) + (7 if g == "blight" else 3)
	n.position = world(h) + Vector3(0, 0.04, 0)
	n.rotation.y = deg_to_rad(60.0 * rng.randi_range(0, 5)) + rng.randf_range(-0.2, 0.2)
	var s := rng.randf_range(0.9, 1.08)
	add_child(n)
	growth_nodes[h] = n
	if animate:
		n.scale = Vector3(0.01, 0.01, 0.01)
		var tw := create_tween()
		tw.tween_interval(rng.randf_range(0.0, 0.12))
		tw.tween_property(n, "scale", Vector3.ONE * s, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		n.scale = Vector3.ONE * s


func apply_growth(changes: Dictionary) -> void:
	for h in changes:
		_set_growth_node(h, changes[h], true)


# ------------------------------------------------------------------ units

func face_units() -> void:
	if not units.has("player"):
		return
	var pp: Vector3 = units["player"].position
	var nearest := Vector3.ZERO
	var best := INF
	for e in combat.enemies:
		if units.has(e["uid"]):
			var ep: Vector3 = units[e["uid"]].position
			var d := ep.distance_to(pp)
			if d < best:
				best = d
				nearest = ep
			_face(units[e["uid"]], pp)
	if best < INF:
		_face(units["player"], nearest)


func _face(n: Node3D, target: Vector3) -> void:
	var d := target - n.position
	if Vector2(d.x, d.z).length() < 0.01:
		return
	var goal := atan2(d.x, d.z)
	var tw := create_tween()
	tw.tween_property(n, "rotation:y", lerp_angle(n.rotation.y, goal, 1.0), 0.2)


func move_unit(key, path: Array) -> void:
	if not units.has(key):
		return
	var n: Node3D = units[key]
	var tw := create_tween()
	for h in path:
		var target := world(h)
		var d := target - n.position
		if Vector2(d.x, d.z).length() > 0.01:
			tw.tween_property(n, "rotation:y", lerp_angle(n.rotation.y, atan2(d.x, d.z), 1.0), 0.06)
		tw.tween_property(n, "position", target + Vector3(0, 0.25, 0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(n, "position", target, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


func lunge(key, toward: Vector3) -> void:
	if not units.has(key):
		return
	var n: Node3D = units[key]
	var start := n.position
	var d := (toward - start)
	d.y = 0
	var hit := start + d.normalized() * minf(0.55, d.length() * 0.4)
	var tw := create_tween()
	tw.tween_property(n, "position", hit + Vector3(0, 0.12, 0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(n, "position", start, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished


func flash_hit(key) -> void:
	if not units.has(key):
		return
	var n: Node3D = units[key]
	var base_scale := n.scale
	var tw := create_tween()
	tw.tween_property(n, "scale", base_scale * Vector3(1.18, 0.8, 1.18), 0.06)
	tw.tween_property(n, "scale", base_scale, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_burst(n.position + Vector3(0, 0.7, 0), Color(1, 0.45, 0.3), 14)


func kill_unit(key) -> void:
	if not units.has(key):
		return
	var n: Node3D = units[key]
	units.erase(key)
	_burst(n.position + Vector3(0, 0.5, 0), Color(0.7, 0.35, 0.95), 30)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector3(n.scale.x * 1.3, 0.05, n.scale.z * 1.3), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(n, "position:y", n.position.y - 0.2, 0.4)
	tw.chain().tween_callback(n.queue_free)


## Cave-in: the open tile is replaced by the theme's blocking tile, which drops from above.
func collapse_hexes(hexes: Array) -> void:
	for h in hexes:
		_set_growth_node(h, "none", true)
		if tiles.has(h):
			tiles[h].queue_free()
		var tile: Node3D = scene(theme["stone"]).instantiate()
		tile.rotation.y = deg_to_rad(60.0 * (absi(hash(h)) % 6))
		var rest := Hex.to_world(h, HEX_SIZE) + Vector3(0, float(tile_height.get(h, 0.0)), 0)
		tile.position = rest + Vector3(0, 3.0, 0)
		add_child(tile)
		tiles[h] = tile
		var tw := create_tween()
		tw.tween_property(tile, "position", rest, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): _burst(rest + Vector3(0, 0.2, 0), Color(0.62, 0.52, 0.42), 16))


func growth_burst(h: Vector2i, g: String) -> void:
	var col := Color(0.6, 1.0, 0.4) if g == "thicket" else (Color(0.75, 0.35, 1.0) if g == "blight" else Color(0.9, 0.85, 0.7))
	_burst(world(h) + Vector3(0, 0.25, 0), col, 8)


func _burst(at: Vector3, col: Color, amount: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.8
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 3.0
	p.gravity = Vector3(0, -5, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var mesh := SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	mesh.radial_segments = 6
	mesh.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 2.5
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = m
	p.mesh = mesh
	p.position = at
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


# ------------------------------------------------------------------ overlays

## overlay: Vector2i -> [Color, pulse(bool)]
func set_overlays(data: Dictionary) -> void:
	for h in overlays:
		var ov: MeshInstance3D = overlays[h]
		if data.has(h):
			var d: Array = data[h]
			ov.visible = true
			ov.position = world(h) + Vector3(0, 0.09, 0)
			var m: ShaderMaterial = ov.material_override
			m.set_shader_parameter("tint", d[0])
			m.set_shader_parameter("pulse", 1.0 if d[1] else 0.0)
		else:
			ov.visible = false


## previews: [{path:[Vector2i], color:Color, from:Vector2i}]
func set_paths(previews: Array) -> void:
	for c in _path_root.get_children():
		c.queue_free()
	for pv in previews:
		var pts: Array = [pv["from"]] + pv["path"]
		if pts.size() < 2:
			continue
		var col: Color = pv["color"]
		for i in range(pts.size() - 1):
			var a := world(pts[i]) + Vector3(0, 0.2, 0)
			var b := world(pts[i + 1]) + Vector3(0, 0.2, 0)
			if i == 0:
				a = a.lerp(b, 0.3)
			if i == pts.size() - 2:
				b = a.lerp(b, 0.72)
			_path_segment(a, b, col)
		var end := world(pts.back()) + Vector3(0, 0.2, 0)
		var prev := world(pts[pts.size() - 2]) + Vector3(0, 0.2, 0)
		_path_arrow(end, (end - prev).normalized(), col)


func _path_segment(a: Vector3, b: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.11, 0.03, a.distance_to(b))
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_path_root.add_child(mi)
	mi.look_at_from_position((a + b) / 2.0, b, Vector3.UP)


## Floating red number over the hex that will be hit this enemy turn.
func set_incoming(dmg: int, h: Variant) -> void:
	if dmg <= 0 or h == null:
		_incoming.visible = false
		return
	_incoming.visible = true
	_incoming.text = "-%d" % dmg
	_incoming.position = world(h) + Vector3(0, 3.0, 0)


func _path_dot(at: Vector3, col: Color, r: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	mi.material_override = m
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_path_root.add_child(mi)


func _path_arrow(at: Vector3, dir: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.24
	cm.height = 0.42
	cm.radial_segments = 3
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	mi.material_override = m
	_path_root.add_child(mi)
	mi.position = at - dir * 0.25
	# Point the cone's +Y along the travel direction.
	var up := Vector3.UP
	var axis := up.cross(dir)
	if axis.length() > 0.001:
		mi.basis = Basis(axis.normalized(), up.angle_to(dir))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ------------------------------------------------------------------ picking / idle

func pick(camera: Camera3D, screen: Vector2) -> Variant:
	var from := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if absf(dir.y) < 0.0001:
		return null
	var t := -from.y / dir.y
	if t < 0:
		return null
	var hit := from + dir * t
	var h := Hex.from_world(hit, HEX_SIZE)
	if combat and combat.terrain.has(h):
		return h
	return null


func _process(delta: float) -> void:
	_time += delta
	for key in units:
		var n: Node3D = units[key]
		# Gentle breathing so the diorama never looks frozen.
		var ph := float(hash(key) % 100) / 16.0
		var s: Vector3 = n.scale
		var base := s.x
		n.scale.y = base * (1.0 + 0.025 * sin(_time * 2.2 + ph))
	if player_light:
		player_light.light_energy = 1.3 + 0.2 * sin(_time * 3.1)
