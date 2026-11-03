extends SceneTree
const Core=preload("res://core/run_core.gd")
const Gesture=preload("res://game/gesture_input.gd")
const Courses=preload("res://core/course_catalog.gd")
const Director=preload("res://game/encounter_director.gd")
var checks:int=0
var failures:Array[String]=[]
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures.append(message)
func finger(at:Vector2,pressed:bool,index:int=0) -> InputEventScreenTouch:
	var e:=InputEventScreenTouch.new();e.position=at;e.pressed=pressed;e.index=index;return e
func drag(at:Vector2,index:int=0) -> InputEventScreenDrag:
	var e:=InputEventScreenDrag.new();e.position=at;e.index=index;return e
func _initialize() -> void:
	var gesture:=Gesture.new()
	gesture.feed(finger(Vector2(300,600),true),720,0)
	check(gesture.feed(finger(Vector2(302,600),false),720,.10)=="","A short open-area tap has no combat action")
	gesture.feed(finger(Vector2(300,600),true),720,1)
	check(gesture.feed(finger(Vector2(300,600),false),720,1.5)=="","A held touch is not mistaken for a tap")
	gesture.feed(finger(Vector2(300,600),true),720,2)
	check(gesture.feed(drag(Vector2(240,600)),720,2.1)=="left","Swipe commits as soon as it passes the deadzone")
	check(gesture.feed(drag(Vector2(100,600)),720,2.2)=="","One drag produces one lane change")
	check(gesture.feed(finger(Vector2(100,600),false),720,2.25)=="","A swipe release does not also attack")
	gesture.feed(finger(Vector2(300,600),true),720,3)
	var cancel:=finger(Vector2(300,600),false);cancel.canceled=true
	check(gesture.feed(cancel,720,3.05)=="" and gesture.touches.is_empty(),"Cancelled touches release their ownership")
	gesture.feed(finger(Vector2(300,600),true,0),720,4)
	gesture.feed(finger(Vector2(500,600),true,1),720,4.01)
	check(gesture.feed(drag(Vector2(600,600),1),720,4.05)=="","A second finger cannot steal a gesture")
	gesture.reset();gesture.sensitivity="high"
	gesture.feed(finger(Vector2(300,600),true),720,5)
	check(gesture.feed(drag(Vector2(300,568)),720,5.05)=="jump","High sensitivity accepts a shorter deliberate swipe")
	gesture.reset();gesture.sensitivity="low"
	gesture.feed(finger(Vector2(300,600),true),720,6)
	check(gesture.feed(drag(Vector2(300,568)),720,6.05)=="","Low sensitivity preserves its longer deadzone")
	gesture.reset();check(gesture.touches.is_empty(),"Navigation/focus reset cancels pending gestures")
	for speed in [6.0,12.75,20.123]:
		var core:=Core.new();core.start("knight",1)
		check(core.set_speed(speed),"Valid runner speed accepted")
		core.step(60)
		check(core.distance_mm==roundi(speed*1000),"Fixed-tick distance preserves fractional speed without drift")
	var core:=Core.new();core.start("witch",2)
	check(not core.set_speed(NAN) and not core.set_speed(25) and not core.set_speed(0),"Invalid speed never enters simulation")
	core.offer_route("distance-gate","gargoyle",120)
	check(core.sync_route_deadline("distance-gate",60),"Route timing can follow changing approach speed")
	check(not core.sync_route_deadline("wrong",60),"Deadline synchronisation cannot target a different gate")
	core.commit_route("distance-gate");core.step(60)
	check(core.phase=="handoff","A synchronized gate hands off at its updated deadline")
	core.step(Core.HANDOFF_TICKS+Core.RECOVERY_TICKS)
	check(core.complete_run(),"A live expedition can finish")
	var done:=core.snapshot();core.step(300)
	check(core.snapshot()==done and core.attack()<0 and not core.use_power(),"Finished expeditions stop gameplay and rewards")
	for id in Courses.ORDER:
		var course:=Courses.get_course(id)
		check(Courses.speed_at(id,0,0)>=18.0,"Every expedition starts at a fast running pace")
		check(Courses.speed_at(id,5000,500)<=float(course.maximum),"Acceleration respects the route speed cap")
		check(float(course.length)>0 or id=="endless","Only endless omits a finish line")
		var director:=Director.new();director.configure(id,987)
		var valid:=true
		for index in range(30):
			var start:float=64+index*96
			for row in director.phrase(index,start):
				valid=valid and int(row.lane)>=0 and int(row.lane)<=2 and float(row.at)>=start and float(row.at)<start+96
		check(valid,"Authored encounter phrases stay inside their lane and distance bounds")
	var report:Dictionary={"checks":checks,"failed":failures.size(),"failures":failures,"scope":"Gesture ownership and intent, deterministic variable speed, synchronized handoffs, terminal completion, route pacing and encounter bounds"}
	FileAccess.open("res://tests/evidence/runner-controls.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("RUNNER_CONTROLS_QA ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
