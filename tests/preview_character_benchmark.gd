extends SceneTree
## A seeded sixty-second desktop benchmark; no owner save access or device claim.
var game:Node
var identity:String="knight"
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var length:int=1800
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--preview-frames="):length=int(argument.get_slice("=",1))
		if argument.begins_with("--character=") and argument.get_slice("=",1) in ["knight","gargoyle","witch"]:identity=argument.get_slice("=",1)
	game=load("res://scenes/main.tscn").instantiate();game.testing=true
	game.profile.settings.control_mode="thumb";game.profile.practice_complete=true
	root.add_child(game)
	for i in range(4):await physics_frame
	game._select_character(identity);game.course_id="endless";game.qa=true;game._start_run()
	game.qa=false;game.countdown_left=.001;game.qa_use_specials=false
	for i in range(4):await physics_frame
	for i in range(length):
		game._qa_control()
		if i in [40,80,120,360,750,1200,1650]:await game._capture(identity+"-benchmark-%04d"%i)
		await process_frame
	var result:Dictionary={"frames":length,"recording_fps":30,"seed":73129,"runner":identity,"course":"endless","distance_m":game.distance,"damage":game.run_damage,"handoffs":game.total_handoffs,"selected_character_preserved":game.selected==identity and game.core.active_character==identity,"scope":"Actual desktop render with disclosed automated controls; not human playability, on-device performance or art approval"}
	print("CHARACTER_BENCHMARK ",JSON.stringify(result))
	FileAccess.open(game.capture_dir.path_join("benchmark.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	game._quit_gracefully(0 if result.selected_character_preserved else 1)
