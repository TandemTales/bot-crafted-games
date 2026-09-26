class_name RoomStage
extends SubViewportContainer
## Live 3D vignette staged behind the non-combat screens: campfire, shrine, pedlar, and the
## post-fight clearing. Built from the same region-themed models as the battle board.
## `focus` says where the subject should sit on screen so the UI can take the other side.

const MODELS := "res://assets/models/%s.glb"

var kind := "camp"  # camp | shrine | market | reward
var theme_id := "marsh"
var focus := "left"  # left | top
var _vp: SubViewport
var _root: Node3D
var _pivot: Node3D
var _cam: Camera3D
var _lights: Array = []  # [OmniLight3D, base energy, flicker speed]
var _t := 0.0
var _rng := RandomNumberGenerator.new()


static func create(kind_: String, theme_: String, focus_: String) -> RoomStage:
	var s := RoomStage.new()
	s.kind = kind_
	s.theme_id = theme_
	s.focus = focus_
	return s


## A gradient that darkens the side of the screen the UI sits on, so text stays legible.
static func shade(side: String) -> Control:
	var sh := Shade.new()
	sh.side = side
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return sh


class Shade extends Control:
	var side := "right"
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var clear := Color(0.01, 0.015, 0.012, 0.0)
		var dark := Color(0.01, 0.015, 0.012, 0.86)
		if side == "right":
			var x0 := w * 0.4
			var x1 := w * 0.66
			draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, h), Vector2(x0, h)]),
				PackedColorArray([clear, dark, dark, clear]))
			draw_rect(Rect2(x1, 0, w - x1, h), dark)
		else:
			var y0 := h * 0.42
			var y1 := h * 0.62
			draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(w, y0), Vector2(w, y1), Vector2(0, y1)]),
				PackedColorArray([clear, clear, dark, dark]))
			draw_rect(Rect2(0, y1, w, h - y1), dark)
		# Soft top band behind the run HUD.
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 160), Vector2(0, 160)]),
			PackedColorArray([dark, dark, clear, clear]))


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = hash(kind + theme_id)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	add_child(_vp)
	_root = Node3D.new()
	_vp.add_child(_root)
	BoardView.make_environment(_root, theme_id)
	_pivot = Node3D.new()
	_root.add_child(_pivot)
	_build_ground()
	match kind:
		"camp":
			_camp()
		"shrine":
			_shrine()
		"market":
			_market()
		_:
			_reward()
	_cam = Camera3D.new()
	_cam.fov = 38
	_root.add_child(_cam)
	_frame()


func _th() -> Dictionary:
	return BoardView.THEMES.get(theme_id, BoardView.THEMES["marsh"])


func _place(model: String, pos: Vector3, rot_deg: float = 0.0, sc: float = 1.0) -> Node3D:
	var n: Node3D = (load(MODELS % model) as PackedScene).instantiate()
	n.position = pos
	n.rotation.y = deg_to_rad(rot_deg)
	n.scale = Vector3.ONE * sc
	_pivot.add_child(n)
	var ap := n.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.get_animation_list().size() > 0:
		var an: StringName = ap.get_animation_list()[0]
		ap.get_animation(an).loop_mode = Animation.LOOP_LINEAR
		ap.play(an)
	return n


func _light(pos: Vector3, col: Color, energy: float, rng_: float, flicker: float = 0.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_
	l.position = pos
	l.shadow_enabled = flicker > 0.0
	_pivot.add_child(l)
	_lights.append([l, energy, flicker])
	return l


func _hex(h: Vector2i) -> Vector3:
	return Hex.to_world(h, 1.0)


## A small island of region tiles with props fading into the fog behind it.
func _build_ground() -> void:
	var th := _th()
	for h in Hex.disc(Vector2i.ZERO, 2):
		var t: String = th["plain"]
		if Hex.distance(h, Vector2i.ZERO) == 2 and _rng.randf() < 0.18 and h.y < 0:
			t = th["stone"]
		var tile := _place(t, _hex(h) + Vector3(0, _rng.randf_range(-0.03, 0.03), 0), 60.0 * _rng.randi_range(0, 5))
		tile.position.y -= 0.0
	for ring_r in range(3, 6):
		for h in Hex.ring(Vector2i.ZERO, ring_r):
			if _rng.randf() < 0.3 + 0.12 * (ring_r - 3):
				continue
			var tname: String = th["outer"][0][0] if _rng.randf() < 0.8 else th["stone"]
			_place(tname, _hex(h) + Vector3(0, -0.3 - 0.15 * (ring_r - 3) + _rng.randf_range(-0.08, 0.08), 0), 60.0 * _rng.randi_range(0, 5))
			var p := _hex(h)
			# Tall props only behind the subject, filler props elsewhere.
			if p.z < -2.5 and _rng.randf() < 0.35:
				var tall: Array = th["tall"]
				_place(tall[_rng.randi() % tall.size()], p + Vector3(0, -0.3, 0), _rng.randf_range(0, 360), _rng.randf_range(0.9, 1.3) * float(th["tall_scale"].get(tall[0], 1.0)))
			elif _rng.randf() < 0.25:
				_place(th["filler"], p + Vector3(0, -0.3, 0), _rng.randf_range(0, 360), _rng.randf_range(0.8, 1.1))
	var pool := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	pool.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = th["pool"]
	m.roughness = 0.06
	m.metallic_specular = 0.8
	pool.material_override = m
	pool.position.y = -0.6
	_pivot.add_child(pool)


func _camp() -> void:
	_place("campfire", Vector3(0.3, 0, -0.2), 0.0, 1.5)
	_light(Vector3(0.3, 0.8, -0.2), Color(1.0, 0.55, 0.22), 5.0, 7.0, 1.0)
	_place("grovewalker", Vector3(-0.9, 0, 0.5), 38.0, 1.35)
	_place("thicket", _hex(Vector2i(-1, 0)), 0.0, 1.0)
	_place("thicket", _hex(Vector2i(0, -1)), 90.0, 0.9)
	_place("thicket", _hex(Vector2i(1, 1)), 30.0, 0.8)


func _shrine() -> void:
	_place("altar", Vector3(0, 0, -0.2), 0.0, 1.6)
	_light(Vector3(0, 1.9, 0.5), Color(0.6, 1.0, 0.45), 3.0, 5.5, 0.25)
	_light(Vector3(0, 0.6, 0.9), Color(1.0, 0.65, 0.3), 1.6, 3.5, 1.0)
	if theme_id == "cloister":
		_place("arch", Vector3(0, 0, -1.4), 0.0, 1.0)
		_place("candles", _hex(Vector2i(1, 0)), 0.0, 1.2)
		_place("candles", _hex(Vector2i(-1, 1)), 70.0, 1.0)
	elif theme_id == "glasswood":
		_place("crystal_tree", Vector3(0, 0, -1.8), 20.0, 1.0)
		_place("fallen_prism", _hex(Vector2i(1, -1)), 35.0, 0.85)
	elif theme_id == "ironroot":
		_place("timber_frame", Vector3(0, 0, -1.6), 0.0, 1.1)
		_place("ore_spoil", _hex(Vector2i(1, -1)), 35.0, 1.1)
	else:
		_place("menhir", _hex(Vector2i(1, -1)), 20.0, 1.1)
		_place("willow", _hex(Vector2i(-1, -1)) + Vector3(-0.4, 0, -0.4), 0.0, 1.3)
	_place("thicket", _hex(Vector2i(1, 0)) + Vector3(0.2, 0, 0.3), 0.0, 0.9)
	_place("thicket", _hex(Vector2i(-1, 1)), 45.0, 0.9)
	_place("grovewalker", Vector3(-1.5, 0, 0.9), 118.0, 1.3)


func _market() -> void:
	_place("pedlar", Vector3.ZERO, 25.0, 1.6)
	_light(Vector3(0.9, 2.2, -0.2), Color(1.0, 0.7, 0.35), 4.0, 6.0, 0.6)
	_place("thicket", _hex(Vector2i(-1, 1)), 0.0, 0.8)
	if theme_id == "cloister":
		_place("candles", _hex(Vector2i(1, 1)), 0.0, 1.1)
	elif theme_id == "glasswood":
		_place("glass_fern", _hex(Vector2i(1, 1)), 0.0, 1.0)
	elif theme_id == "ironroot":
		_place("ore_cart", _hex(Vector2i(1, 1)), 60.0, 1.0)
	else:
		_place("reeds", _hex(Vector2i(1, 1)), 0.0, 1.0)


func _reward() -> void:
	for h in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, -1), Vector2i(-1, 0)]:
		_place("thicket", _hex(h), _rng.randf_range(0, 360), 1.0)
	for h in [Vector2i(2, -1), Vector2i(1, -2), Vector2i(-2, 1)]:
		_place("blight", _hex(h), _rng.randf_range(0, 360), 0.8)
	_place("grovewalker", Vector3(0, 0.02, 0), 12.0, 1.3)
	_light(Vector3(0.3, 2.0, 0.4), Color(0.7, 1.0, 0.45), 3.5, 6.0, 0.2)


func _frame() -> void:
	match focus:
		"left":
			# Subject in the left half of the screen; the UI takes the right.
			_cam.position = Vector3(0, 4.3, 7.0)
			_cam.look_at(Vector3(0, 0.5, 0))
			_cam.h_offset = 2.0
		_:
			# Subject in the band between the heading and the cards.
			_cam.position = Vector3(0, 5.2, 10.5)
			_cam.look_at(Vector3(0, 0.6, 0))
			_cam.v_offset = -1.15


func _process(delta: float) -> void:
	_t += delta
	_pivot.rotation.y = sin(_t * 0.12) * 0.1
	for entry in _lights:
		var l: OmniLight3D = entry[0]
		var f: float = entry[2]
		if f > 0.0:
			l.light_energy = float(entry[1]) * (1.0 + f * (0.12 * sin(_t * 11.0) + 0.08 * sin(_t * 17.3 + 1.0)))
