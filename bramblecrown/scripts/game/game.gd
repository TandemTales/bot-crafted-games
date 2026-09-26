extends Node
## Autoload `Game`: owns the current run, the profile, and scene flow.

const RUN_PATH := "user://run.json"
const PROFILE_PATH := "user://profile.json"
const SETTINGS_PATH := "user://settings.json"

var run: RunState
var combat: CombatState
var profile := {"runs": 0, "wins": 0, "best_floor": 0}
var settings := {"sfx": 0.8, "music": 0.6, "fullscreen": false}
## Screenshot tour (packaged-build QA): --screenshot-tour <dir>
var tour_dir := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	for i in args.size():
		if args[i] == "--screenshot-tour" and i + 1 < args.size():
			tour_dir = args[i + 1]
	if tour_dir.is_empty():
		_load_profile()
		_load_settings()
	if tour_dir != "":
		var tour: Node = load("res://tools/screenshot_tour.gd").new()
		tour.name = "ScreenshotTour"
		add_child(tour)


func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_PATH)


func new_run(seed_value: int = -1) -> void:
	if seed_value < 0:
		seed_value = int(Time.get_unix_time_from_system()) % 1000000
	run = RunState.new()
	run.new_run(seed_value)
	profile["runs"] = int(profile["runs"]) + 1
	_save_profile()
	save_run()
	goto_map()


func continue_run() -> bool:
	if not has_saved_run():
		return false
	var f := FileAccess.open(RUN_PATH, FileAccess.READ)
	var r := RunState.from_json(f.get_as_text())
	if r == null:
		return false
	run = r
	route_to_status()
	return true


func save_run() -> void:
	if run == null or not tour_dir.is_empty():
		return
	if run.status in ["victory", "defeat"]:
		clear_run()
		return
	var f := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	f.store_string(run.to_json())


func clear_run() -> void:
	if not tour_dir.is_empty():
		return
	if FileAccess.file_exists(RUN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_PATH))


func record_end(victory: bool) -> void:
	if victory:
		profile["wins"] = int(profile["wins"]) + 1
	profile["best_floor"] = maxi(int(profile["best_floor"]), run.floor_num)
	_save_profile()
	clear_run()


func route_to_status() -> void:
	match run.status:
		"combat":
			goto_combat()
		"reward":
			goto_scene("res://scenes/reward.tscn")
		"camp", "shrine", "market":
			goto_scene("res://scenes/room.tscn")
		"victory", "defeat":
			goto_scene("res://scenes/run_end.tscn")
		_:
			goto_map()


func goto_map() -> void:
	goto_scene("res://scenes/map.tscn")


func goto_combat() -> void:
	combat = run.make_combat()
	goto_scene("res://scenes/combat.tscn")


func goto_title() -> void:
	goto_scene("res://scenes/title.tscn")


func goto_scene(path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", path)


func toggle_fullscreen() -> void:
	settings["fullscreen"] = not settings["fullscreen"]
	_apply_settings()
	_save_settings()


func _apply_settings() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.get_name() != "headless" and DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _load_profile() -> void:
	profile.merge(_load_json(PROFILE_PATH), true)


func _save_profile() -> void:
	if not tour_dir.is_empty():
		return
	FileAccess.open(PROFILE_PATH, FileAccess.WRITE).store_string(JSON.stringify(profile))


func _load_settings() -> void:
	settings.merge(_load_json(SETTINGS_PATH), true)
	_apply_settings()


func _save_settings() -> void:
	if not tour_dir.is_empty():
		return
	FileAccess.open(SETTINGS_PATH, FileAccess.WRITE).store_string(JSON.stringify(settings))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()
