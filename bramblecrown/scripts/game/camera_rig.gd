class_name CameraRig
extends Node3D
## Orbiting diorama camera: Q/E or right-drag to rotate (±35°), wheel to zoom.

@export var distance := 12.5
@export var min_distance := 7.0
@export var max_distance := 17.0
@export var pitch_deg := 52.0
@export var yaw_limit_deg := 35.0
@export var look_point := Vector3(0, 0, 0.6)

var camera: Camera3D
var _yaw := 0.0
var _yaw_goal := 0.0
var _dist_goal := 12.5
var _dragging := false
var _shake := 0.0
var _time := 0.0
var idle_sway := true


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 40.0
	camera.far = 200.0
	add_child(camera)
	_dist_goal = distance
	_apply(0.0)


func frame_radius(r: int) -> void:
	# Look at a point toward the camera so the board sits above the hand of cards.
	pitch_deg = 57.0
	look_point = Vector3(0, 0, 1.0 + r * 0.3)
	distance = 10.5 + r * 2.25
	_dist_goal = distance
	min_distance = distance * 0.6
	max_distance = distance * 1.3


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_dist_goal = clampf(_dist_goal - 0.8, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_dist_goal = clampf(_dist_goal + 0.8, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		_yaw_goal = clampf(_yaw_goal - event.relative.x * 0.004, -deg_to_rad(yaw_limit_deg), deg_to_rad(yaw_limit_deg))


func _process(delta: float) -> void:
	_time += delta
	var turn := Input.get_axis("cam_left", "cam_right")
	if turn != 0.0:
		_yaw_goal = clampf(_yaw_goal + turn * delta * 1.4, -deg_to_rad(yaw_limit_deg), deg_to_rad(yaw_limit_deg))
	var zoom := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
	if absf(zoom) > 0.2:
		_dist_goal = clampf(_dist_goal - zoom * delta * 6.0, min_distance, max_distance)
	_apply(delta)


func _apply(delta: float) -> void:
	var k := 1.0 if delta == 0.0 else clampf(delta * 6.0, 0.0, 1.0)
	_yaw = lerpf(_yaw, _yaw_goal, k)
	distance = lerpf(distance, _dist_goal, k)
	var sway := 0.0
	if idle_sway:
		sway = sin(_time * 0.21) * 0.02
	var pitch := deg_to_rad(pitch_deg)
	var y := _yaw + sway
	var offset := Vector3(sin(y) * cos(pitch), sin(pitch), cos(y) * cos(pitch)) * distance
	var look := look_point
	camera.position = look + offset
	if _shake > 0.0:
		camera.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.12
		_shake = maxf(0.0, _shake - delta * 3.0)
	camera.look_at(look, Vector3.UP)
