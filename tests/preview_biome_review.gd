extends SceneTree
## Actual game render at disclosed seeded review stations, with automated input.
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
	for station in [36.0,420.0,804.0]:
		game._select_character(identity)
		game.course_id="endless"
		game.qa=true
		game._start_run()
		game.qa=false
		game.countdown_left=.001
		game.distance=station
		game.core.distance_mm=roundi(station*1000.0)
		for row in game.rows:row.node.queue_free()
		game.rows.clear()
		game.next_row=station+32
		game.row_index=1
		game.world.update(station,0)
		game._spawn_ahead()
		for frame in range(70):
			game._qa_control()
			await process_frame
		await game._capture(identity+"-"+str(game.world.biome_state.id))
	print("BIOME_REVIEW character=",identity," stations=36,420,804; actual gameplay with disclosed review starts")
	game._quit_gracefully(0)
