extends SceneTree
## Real scene/input regressions. Never reads or writes the owner's profile.
const Gesture=preload("res://game/gesture_input.gd")
const Steering=preload("res://game/runner_steering.gd")
var game:Node
var checks:int=0
var failures:Array[String]=[]

func _initialize() -> void:
	root.size=Vector2i(720,1560)
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)

func frames(count:int) -> void:
	for i in range(count):await physics_frame

func finger(at:Vector2,pressed:bool,index:int=11) -> InputEventScreenTouch:
	var e:=InputEventScreenTouch.new()
	e.index=index;e.position=at;e.pressed=pressed
	return e

func run() -> void:
	var positions:Array[float]=[]
	for hz in [30,60,120]:
		var response:=Steering.new()
		var x:float=0
		for tick in range(hz/5):x=response.advance(x,2.6,1.0/hz,3.65)
		positions.append(x)
		check(x>2.53 and x<=2.6,"Lateral response reaches a lane promptly without overshoot at %d Hz"%hz)
		var prior:float=response.velocity
		check(response.advance(x,-2.6,0,3.65)==x and response.velocity==prior,"Retargeting does not reset position or velocity at %d Hz"%hz)
		for tick in range(hz):
			x=response.advance(x,-2.6,1.0/hz,3.65)
			check(is_finite(x) and absf(x)<=3.65,"Reversal remains finite and inside the running corridor")
		check(absf(x+2.6)<.001,"Rapid reversal settles at %d Hz"%hz)
	check(absf(positions[0]-positions[2])<.0001,"Lateral response is independent of 30/60/120 Hz partitioning")
	var recognizer:=Gesture.new()
	recognizer.feed(finger(Vector2(300,600),true),720,0)
	recognizer.feed(_drag(Vector2(240,540)),720,.05)
	check(recognizer.feed(finger(Vector2(240,540),false),720,.10)=="jump","A deliberate diagonal swipe resolves on release rather than disappearing")
	game=load("res://scenes/main.tscn").instantiate()
	game.testing=true;game.profile.settings.control_mode="thumb";game.profile.practice_complete=true
	root.add_child(game);await frames(5)
	game.qa=true;game._start_run();game.qa=false
	game._clear_course_rows();game.next_row=1e9
	await frames(5)
	game._jump();game._slide()
	check(game.jump_buffer==0,"Down cancels an older queued jump")
	await frames(2)
	check(game.motor.position.y-game.ground_y<.05,"Jump then down in the same frame does not launch a sliding airborne character")
	game._slide();game._jump()
	check(game.slide_buffer==0,"Up cancels an older queued slide")
	await frames(5)
	check(game.sliding_left==0 and game.motor.velocity.y>0,"Jump exits crouch without a conflicting slide state")
	await frames(50)
	var pad:Control=game.ui.thumb_pad
	var centre:Vector2=pad.get_global_transform_with_canvas()*(pad.size*.5+Vector2(2,0))
	root.push_input(finger(centre,true),true)
	await frames(20)
	check(pad.axis==0,"The steering pad has a usable neutral deadzone")
	check(absf(game.motor.position.x)<.03,"A nearly centred thumb does not drift the runner")
	root.push_input(finger(centre,false),true);await frames(24)
	var right:Vector2=pad.get_global_transform_with_canvas()*(pad.size*Vector2(.95,.5))
	root.push_input(finger(right,true),true);await frames(11)
	root.push_input(finger(right,false),true);await frames(32)
	check(absf(game.motor.position.x-2.6)<.04,"Releasing the pad settles into the nearest lane instead of stranding the runner between lanes")
	check(not game.manual_steering,"Releasing the pad relinquishes analog steering ownership")
	game._move_lane(-1);await frames(24)
	check(absf(game.motor.position.x)<.04,"Keyboard lane input still works after thumb release")
	check(game.touches.is_empty(),"No completed gesture remains latched")
	var origin:=Vector2(360,800)
	root.push_input(finger(origin,true),true)
	check(game.touches.has(11),"The playfield owns an open-area touch")
	# Exercise raw release cleanup without the unhandled path, as when a GUI
	# control consumes the release. Deferred cleanup must still run.
	game._input(finger(origin,false))
	await frames(2)
	check(game.touches.is_empty(),"A GUI-consumed release cannot permanently block future gestures")
	root.push_input(finger(origin,true),true)
	game._input(finger(origin,false))
	game.gestures.feed(finger(origin,true),720,game.clock)
	var token:int=int(game.touches[11].sequence)
	await frames(2)
	check(game.touches.has(11) and int(game.touches[11].sequence)==token,"Deferred cleanup cannot erase a newer touch reusing the same pointer ID")
	root.push_input(finger(origin,false),true);await frames(2)
	var hero:Node=game.heroes[game.selected]
	game._attack();await frames(8)
	check(hero.motion_art.stride_weight>.9,"Grounded attacks do not freeze running legs while the world keeps moving")
	hero.hurt_left=.3;await frames(4)
	check(hero.motion_art.stride_weight>.9,"Nonfatal damage does not stop forward locomotion animation")
	game._jump();await frames(2)
	check(hero.airborne==not game.motor.is_on_floor(),"Airborne pose follows the authoritative floor state")
	var report:Dictionary={"checks":checks,"failed":failures.size(),"failures":failures,"scope":"Actual Godot scene, native touch events, opposing jump/slide commands, pad deadzone/release and lane handover; not a phone test"}
	FileAccess.open("res://tests/evidence/movement-controls.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MOVEMENT_CONTROLS_QA ",JSON.stringify(report))
	game._quit_gracefully(0 if failures.is_empty() else 1)

func _drag(at:Vector2) -> InputEventScreenDrag:
	var e:=InputEventScreenDrag.new();e.index=11;e.position=at
	return e
