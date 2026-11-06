extends SceneTree
## Controlled cloth-response experiment. Does not modify normal game speed or save data.
var game:Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	game.testing=true
	game.profile.settings.control_mode="thumb"
	game.profile.practice_complete=true
	root.add_child(game)
	for i in range(4):await physics_frame
	game._select_character("knight")
	game.course_id="endless"
	game.qa=true
	game._start_run()
	game.qa=false
	game.countdown_left=.001
	game.qa_use_specials=false
	for i in range(4):await physics_frame
	var observations:Array[Dictionary]=[]
	var conditions:Array[Dictionary]=[
		{"label":"idle","moving":false,"rate":0.5,"expected_amount":0.25,"expected_speed":0.5},
		{"label":"run","moving":true,"rate":1.0,"expected_amount":1.0,"expected_speed":1.0},
		{"label":"fast","moving":true,"rate":1.65,"expected_amount":1.0,"expected_speed":1.65}
	]
	for condition in conditions:
		for i in range(25):
			game._qa_control()
			await process_frame
		var hero:Node3D=game.heroes["knight"]
		hero.moving=condition["moving"]
		hero.motion.locomotion_rate=condition["rate"]
		hero.animate(0.0)
		var amount:float=hero.cape_fabric.get_shader_parameter("motion_amount")
		var speed:float=hero.cape_fabric.get_shader_parameter("motion_speed")
		var ok:bool=is_equal_approx(amount,condition["expected_amount"]) and is_equal_approx(speed,condition["expected_speed"])
		observations.append({"state":condition["label"],"moving":condition["moving"],"rate":condition["rate"],"motion_amount":amount,"motion_speed":speed,"passed":ok})
		await game._capture("knight-cloth-"+condition["label"])
	var all_passed:bool=true
	for observation in observations:
		if not observation["passed"]:all_passed=false
	var result:Dictionary={"experiment":"isolated_cloth_response","states":observations,"passed":all_passed,"scope":"Controlled hero shader-parameter test and actual desktop screenshots; not a measured real-world acceleration or Android performance test"}
	FileAccess.open(game.capture_dir.path_join("cloth-response.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("CLOTH_RESPONSE ",JSON.stringify(result))
	game._quit_gracefully(0 if all_passed else 1)
