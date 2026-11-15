extends SceneTree
## Repeatable real-input before/after capture; scene writes only to its QA folder.
var game:Node
var hero:String="knight"

func _initialize() -> void:call_deferred("run")

func touch(at:Vector2,pressed:bool,id:int=11) -> void:
	var e:=InputEventScreenTouch.new();e.index=id;e.position=at;e.pressed=pressed
	root.push_input(e,true)

func swipe(offset:Vector2) -> void:
	var origin:Vector2=game.ui.size*Vector2(.52,.56)
	touch(origin,true,12)
	var e:=InputEventScreenDrag.new();e.index=12;e.position=origin+offset;e.relative=offset
	root.push_input(e,true);touch(origin+offset,false,12)

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--character="):hero=argument.get_slice("=",1)
	game=load("res://scenes/main.tscn").instantiate()
	game.testing=true;game.profile.settings.control_mode="thumb";game.profile.practice_complete=true
	root.add_child(game)
	for i in range(5):await physics_frame
	game._select_character(hero);game.qa=true;game._start_run();game.qa=false
	game._clear_course_rows();game.next_row=1e9
	for frame in range(240):
		var pad:Control=game.ui.thumb_pad
		var left:Vector2=pad.get_global_transform_with_canvas()*(pad.size*Vector2(.05,.5))
		if frame==20:touch(left,true)
		if frame==35:touch(left,false)
		if frame==60:game._move_lane(1)
		if frame==75:game._move_lane(-1)
		if frame==78:game._move_lane(1)
		if frame==95:swipe(Vector2(0,-100))
		if frame==125:swipe(Vector2(0,100))
		if frame==150:swipe(Vector2(0,-100));swipe(Vector2(0,100))
		if frame==180:swipe(Vector2(0,100));swipe(Vector2(0,-100))
		if frame==205:swipe(Vector2(100,0))
		if frame==225:swipe(Vector2(-100,0))
		if frame%2==0:await game._capture("controls-%03d"%frame)
		await process_frame
	print("CONTROLS_REVIEW hero=",hero," captures=120; clear-course scripted pad, reversal, jump/slide review, not encounter QA")
	game._quit_gracefully(0)
