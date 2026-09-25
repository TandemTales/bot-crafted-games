class_name Rng
extends RefCounted
## Deterministic RNG with serializable state. All rule randomness goes through this.

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value


func randi_range(lo: int, hi: int) -> int:
	return _rng.randi_range(lo, hi)


func randf() -> float:
	return _rng.randf()


func pick(arr: Array):
	if arr.is_empty():
		return null
	return arr[_rng.randi_range(0, arr.size() - 1)]


func shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


## Weighted pick from {key: weight}.
func weighted(weights: Dictionary):
	var total := 0.0
	for k in weights:
		total += float(weights[k])
	var roll := _rng.randf() * total
	for k in weights:
		roll -= float(weights[k])
		if roll <= 0.0:
			return k
	return weights.keys().back()


func get_state() -> Dictionary:
	return {"seed": str(_rng.seed), "state": str(_rng.state)}


func set_state(d: Dictionary) -> void:
	_rng.seed = int(d.get("seed", "0"))
	_rng.state = int(d.get("state", "0"))
