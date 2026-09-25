class_name Hex
extends RefCounted
## Axial hex math (pointy-top). q = column axis, r = row axis.

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]
const SQRT3 := 1.7320508


static func distance(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2


static func neighbors(h: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS:
		out.append(h + d)
	return out


## Every hex within `radius` of `center`, in a stable order.
static func disc(center: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		for r in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			out.append(center + Vector2i(q, r))
	return out


static func ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if radius == 0:
		out.append(center)
		return out
	var h := center + DIRS[4] * radius
	for side in 6:
		for _i in radius:
			out.append(h)
			h += DIRS[side]
	return out


static func _cube_round(fq: float, fr: float) -> Vector2i:
	var fs := -fq - fr
	var q := roundf(fq)
	var r := roundf(fr)
	var s := roundf(fs)
	var dq := absf(q - fq)
	var dr := absf(r - fr)
	var ds := absf(s - fs)
	if dq > dr and dq > ds:
		q = -r - s
	elif dr > ds:
		r = -q - s
	return Vector2i(int(q), int(r))


## Hexes on the straight line from a to b, inclusive of both ends.
static func line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var n := distance(a, b)
	var out: Array[Vector2i] = []
	for i in n + 1:
		var t := 0.0 if n == 0 else float(i) / n
		# Small nudge keeps ties on edges deterministic.
		out.append(_cube_round(lerpf(a.x + 1e-6, b.x + 1e-6, t), lerpf(a.y + 2e-6, b.y + 2e-6, t)))
	return out


## Unit-step direction index from a toward b (closest of the six axial directions).
static func direction_toward(a: Vector2i, b: Vector2i) -> int:
	var best := 0
	var best_d := 1 << 30
	for i in 6:
		var d := distance(a + DIRS[i], b)
		if d < best_d:
			best_d = d
			best = i
	return best


static func to_world(h: Vector2i, size: float) -> Vector3:
	return Vector3(size * SQRT3 * (h.x + h.y * 0.5), 0.0, size * 1.5 * h.y)


static func from_world(p: Vector3, size: float) -> Vector2i:
	var fq := (SQRT3 / 3.0 * p.x - 1.0 / 3.0 * p.z) / size
	var fr := (2.0 / 3.0 * p.z) / size
	return _cube_round(fq, fr)


static func key(h: Vector2i) -> String:
	return "%d,%d" % [h.x, h.y]


static func from_key(k: String) -> Vector2i:
	var parts := k.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))
