extends SceneTree
## Actual gameplay frames for a compact motion review; never touches owner saves.
var game:Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var identity:String="knight"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--character="):identity=argument.get_slice("=",1)
	game=load("res://scenes/main.tscn").instantiate()
	game.testing=true
	game.profile.settings.control_mode="thumb"
	game.profile.practice_complete=true
	root.add_child(game)
	for i in range(4):await physics_frame
	game._select_character(identity)
	game.course_id="endless"
	game.qa=true
	game._start_run()
	game.qa=false
	game.countdown_left=0.001
	for frame in range(90):
		if frame==35:game._jump()
		if frame==65:game._slide()
		if frame%3==0:await game._capture("motion-%03d"%frame)
		await process_frame
	print("FLUID_MOTION_CAPTURE character=",identity," captures=30")
	game._quit_gracefully(0)
