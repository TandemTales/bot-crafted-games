extends Node
## Staged Cassia visual checks. Uses the production title and combat scenes.
## Native: Bramblecrown.exe -- --screenshot-tour <dir> --tour-only cassia-rebuild --cassia-out <dir>
## Uses synthetic mouse events through the native window; no normal player-file writes.
var failures := 0
var out_dir := ""
var hashes := {}
var game
var root: Window

func _ready() -> void:
	root = get_tree().root
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	print("CASSIA_CHECK ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func shot(label: String) -> void:
	await get_tree().process_frame
	# Hidden/occluded validation windows may skip presentation; explicitly draw
	# the production viewport on the native GPU before reading its pixels.
	RenderingServer.force_draw(false)
	var err := root.get_texture().get_image().save_png(out_dir.path_join(label + ".png"))
	check(err == OK, "native capture " + label)


func button_named(parent: Node, label: String) -> Button:
	for b in parent.find_children("*", "Button", true, false):
		if b.text == label:
			return b
	return null


func click_button(button: Button) -> void:
	check(is_instance_valid(button), "input target exists")
	if not is_instance_valid(button):
		return
	var point := button.get_global_rect().get_center()
	print("CASSIA_INPUT ", button.text, " rect=", button.get_global_rect(), " viewport=", root.get_visible_rect())
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await get_tree().process_frame
	var hovered := root.gui_get_hovered_control()
	print("CASSIA_INPUT_HOVER ", hovered.get_path() if hovered else "none")
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)
		await get_tree().process_frame
	await get_tree().create_timer(.25).timeout


func selection_cycles() -> void:
	var title = get_tree().current_scene
	for i in range(3):
		await click_button(button_named(title._select_layer,"Back"))
		check(not title._selection_is_open(),"Back closes overlay cycle %d" % i)
		await shot("selection-back-%d" % i)
		await click_button(title._new_btn)
		check(title._selection_is_open(),"New Run reopens after Back cycle %d" % i)
		if not title._selection_is_open():
			return
	await click_button(button_named(title._select_layer,"Begin as Cassia"))
	var confirm := title.find_child("RunConfirmation",true,false)
	if confirm:
		await click_button(confirm.find_child("Confirm",true,false) as Button)
	await get_tree().create_timer(.7).timeout
	check(game.run != null and game.run.walker == "cassia","Begin starts Cassia after repeated Back")
	check(get_tree().current_scene.scene_file_path.ends_with("map.tscn"),"Begin reaches map after repeated Back")
	await shot("selection-begin-map")

func _run() -> void:
	print("CASSIA_QA_START native renderer=",RenderingServer.get_current_rendering_method())
	game = root.get_node("Game")
	game.tour_dir = "cassia-visual-qa"
	game.profile["bosses"] = 1 # QA memory only; tour mode suppresses persistence.
	out_dir = ProjectSettings.globalize_path("res://evidence/2026-10-07-cassia-rebuild/native")
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--cassia-out" and i + 1 < args.size():
			out_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out_dir)
	for p in [game.RUN_PATH, game.PROFILE_PATH, game.SETTINGS_PATH]:
		hashes[p] = FileAccess.get_sha256(p) if FileAccess.file_exists(p) else ""
	root.size = Vector2i(1920,1080)
	root.mode = Window.MODE_WINDOWED
	get_tree().change_scene_to_file("res://scenes/title.tscn")
	await get_tree().create_timer(1.5).timeout
	get_tree().current_scene._open_select()
	await get_tree().create_timer(2.0).timeout
	await shot("01-production-selection-1080")
	await selection_cycles()
	var model: Node3D = load("res://assets/models/cassia.glb").instantiate()
	root.add_child(model)
	model.visible = false
	var ap := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
	check(ap != null,"GLB contains an AnimationPlayer")
	if ap:
		var names := ap.get_animation_list()
		print("CASSIA_ANIMATIONS ", names)
		check(ap.has_animation("flame_flicker"),"original flame_flicker clip name imports")
		if names.size() > 0:
			ap.play(names[0])
			check(ap.get_animation(names[0]).length >= .99,"one second flame loop")
			var flame := model.find_child("brazier_flame",true,false) as Node3D
			check(flame != null,"original brazier_flame node name retained")
			if flame:
				ap.seek(0.0,true)
				var start_scale := flame.scale
				ap.seek(.25,true)
				check(not flame.scale.is_equal_approx(start_scale),"flame scale animation moves imported geometry")
	var meshes := model.find_children("*","MeshInstance3D",true,false)
	check(meshes.size() > 0,"runtime mesh imports")
	for mi in meshes:
		print("CASSIA_MESH ",mi.name," surfaces=",mi.mesh.get_surface_count()," morphs=",mi.mesh.get_blend_shape_count()," bounds=",mi.get_aabb())
		for si in mi.mesh.get_surface_count():
			check(mi.mesh.surface_get_material(si) != null,"material present on surface %d" % si)
	model.queue_free()
	game.run = RunState.new()
	game.run.new_run(4242,"cassia")
	game.run.enter_node(game.run.available_nodes()[0])
	game.goto_combat()
	await get_tree().create_timer(3).timeout
	var combat_scene = get_tree().current_scene
	await shot("02-production-combat-default-1080")
	var player = combat_scene.board.units["player"]
	var player_ap = player.find_child("AnimationPlayer",true,false)
	check(player_ap != null and player_ap.is_playing(),"production board starts flame animation")
	combat_scene.rig._dist_goal = combat_scene.rig.min_distance
	await get_tree().create_timer(1.5).timeout
	await shot("03-production-combat-max-zoom-1080")
	root.size = Vector2i(1280,720)
	await get_tree().create_timer(1.0).timeout
	await shot("04-production-combat-max-zoom-720")
	for p in hashes:
		var after := FileAccess.get_sha256(p) if FileAccess.file_exists(p) else ""
		check(after == hashes[p],"normal player file unchanged: " + p)
	print("CASSIA_VISUAL_QA_COMPLETE failures=",failures)
	get_tree().quit(failures)
