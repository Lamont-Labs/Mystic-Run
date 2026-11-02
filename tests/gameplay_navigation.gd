extends SceneTree
var game: Node
var checks: int=0
var failures: Array[String]=[]
func _initialize() -> void:
	root.size=Vector2i(720,1560)
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:failures.append(message);push_error(message)
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func click(id: String) -> void:
	check(game.ui.buttons.has(id),"Visible control exists: "+id)
	if not game.ui.buttons.has(id):return
	var button: Button=game.ui.buttons[id]
	check(button.is_visible_in_tree() and not button.disabled,"Control is reachable: "+id)
	if game.ui.front.scroll.is_ancestor_of(button):
		game.ui.front.scroll.ensure_control_visible(button)
		await frames(3)
	var at:=button.get_global_rect().get_center()
	var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.position=at;down.global_position=at;down.pressed=true
	root.push_input(down,true);await frames(1)
	var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.position=at;up.global_position=at;up.pressed=false
	root.push_input(up,true);await frames(4)
func touch(action: String) -> void:
	var at:=Vector2(game.ui.size.x*.48,game.ui.size.y*.58)
	var down:=InputEventScreenTouch.new();down.index=7;down.position=at;down.pressed=true
	root.push_input(down,true);await frames(1)
	var offset:Vector2={"left":Vector2(-100,0),"right":Vector2(100,0),"jump":Vector2(0,-100),"slide":Vector2(0,100),"attack":Vector2.ZERO}[action]
	if action!="attack":
		var drag:=InputEventScreenDrag.new();drag.index=7;drag.position=at+offset;drag.relative=offset
		root.push_input(drag,true);await frames(1)
	var up:=InputEventScreenTouch.new();up.index=7;up.position=at+offset;up.pressed=false
	root.push_input(up,true);await frames(3)
func capture(name: String) -> void:
	await frames(4)
	await game._capture("navigation-"+name)
func begin_route() -> void:
	await click("start")
	check(game.ui.mode=="countdown","Starting route enters the ready countdown")
	var frozen:int=game.core.distance_mm
	await frames(12)
	check(game.core.distance_mm==frozen,"The ready countdown does not move the course")
	game.countdown_left=.01
	await frames(5)
	check(game.ui.mode=="game","The countdown hands control to the runner")
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();game.testing=true;game.profile.settings.control_mode="swipe"
	root.add_child(game);await frames(5)
	check(game.ui.mode=="opening","Launch opens the cinematic opening screen")
	await capture("opening")
	await click("enter");check(game.ui.mode=="home","Enter the City opens the play hub")
	await capture("home")
	await click("nav_team");check(game.ui.mode=="team","Team tab opens the character roster")
	await click("gargoyle");check(game.selected=="gargoyle","Roster selection changes the starting runner")
	await capture("team")
	await click("nav_records");check(game.ui.mode=="records","Records tab opens the saved journal")
	await capture("records-empty")
	await click("settings");check(game.ui.mode=="settings","Header opens settings")
	var before:bool=game.profile.settings.music
	await click("music");check(game.profile.settings.music!=before,"Settings toggle receives a real pointer click")
	await click("sensitivity");check(game.gestures.sensitivity=="high","Sensitivity control changes gesture recognition")
	await capture("settings")
	await click("howto");check(game.ui.mode=="howto","How To opens from settings")
	await click("back");check(game.ui.mode=="settings","Back restores settings")
	await click("back");check(game.ui.mode=="records","Back restores the records tab")
	await click("nav_routes");check(game.ui.mode=="routes","Routes tab opens course selection")
	await click("route_citadel");check(game.course_id=="citadel","Route tile selects the finite expedition")
	await capture("routes")
	await begin_route()
	check(game.core.active_character=="gargoyle","Run starts with the roster choice")
	check(game.core.character_locked and not game.core.offer_route("forbidden","witch",120),"A live run rejects teammate handoffs")
	check(not game.rows.any(func(row):return row.kind=="gate"),"The live course never spawns character gates")
	var attacks_before:int=game.qa_attacks
	await touch("left");check(game.lane==0,"A real touch swipe steers before finger release")
	var framed:=true
	for frame in range(15):
		await frames(1)
		var projected:Vector2=game.camera.unproject_position(game.motor.position+Vector3(0,1.1,0))
		framed=framed and projected.x>=0 and projected.x<=game.ui.size.x
	check(framed,"Portrait lane changes keep the runner centre in frame")
	check(absf(game.motor.position.x+2.6)<.05,"Lane change settles in a bounded time")
	check(game.qa_attacks==attacks_before,"Releasing a swipe does not also strike")
	await touch("right");await frames(15);check(game.lane==1,"Steering back to the centre works")
	await touch("jump");await frames(10);check(game.motor.position.y>.6,"Swipe up produces a physical jump")
	var rising:float=game.motor.velocity.y
	await touch("attack");check(game.qa_attacks>attacks_before,"Tapping the open play area strikes")
	check(game.motor.velocity.y>rising-3,"A Gargoyle basic strike does not force an airborne slam")
	await touch("slide");await frames(16);check(game.sliding_left>0,"Swipe down lands into a slide")
	await capture("run")
	await click("pause");check(game.ui.mode=="pause" and game.core.phase=="paused","HUD pause button suspends the run")
	var snapshot:Dictionary=game.core.snapshot();await frames(8);check(game.core.snapshot()==snapshot,"Pause freezes distance and gameplay")
	await capture("pause")
	await click("pause_settings");await click("howto");await click("back");await click("back")
	check(game.ui.mode=="pause","Nested settings/controls return to pause")
	await click("resume");check(game.ui.mode=="game","Continue returns to the active run")
	await click("pause");await click("abandon");check(game.ui.mode=="results","End Run opens results")
	check(game.profile.runs==1 and game.profile.history.size()==1,"An ended run appears once in the journal")
	await capture("results")
	await click("home");await click("nav_records");check(game.profile.history.size()==1,"Returning home and records preserves run history")
	await capture("records-saved")
	await click("nav_team");await click("witch");await click("nav_routes");await click("route_citadel");await begin_route()
	var z:float=game.motor.position.z;var x:float=game.motor.position.x
	await click("power");await frames(8)
	check(absf(game.motor.position.x-x)>1,"Witch blink chooses a clear neighbouring lane")
	check(absf(game.motor.position.z-z)<.001,"Witch blink does not create forward/backward rubber-banding")
	game.core.distance_mm=650000;await frames(3)
	check(game.ui.mode=="results" and game.core.phase=="completed","Reaching the expedition finish produces a clear result")
	check(game.profile.route_records.citadel.clears==1,"A completed expedition records its clear")
	await capture("expedition-clear")
	await click("home");await click("practice")
	game.countdown_left=.01;await frames(5)
	check(game.course_id=="training" and game.training_step==0,"Practice starts its interactive first step")
	await touch("left");await frames(14);await touch("right");await frames(14)
	await touch("jump");await frames(8);await touch("slide");await frames(20)
	check(game.training_step==4,"Practice observes actual steering, jump and slide inputs")
	await capture("practice")
	await touch("attack");await frames(6);check(game.defeated==1 and game.training_step==5,"Practice teaches an actual successful hit before the power step");await click("power");await frames(55)
	check(game.ui.mode=="results" and game.profile.practice_complete,"Practice completes after the actual strike and power inputs")
	check(game.profile.runs==2,"Practice does not inflate expedition records")
	await capture("practice-complete")
	# Hold a close fracture frame for direct visual inspection of the road cut.
	game.course_id="endless";game._start_run();game.countdown_left=.01;await frames(5)
	game.set_physics_process(false)
	for row in game.rows:row.node.queue_free()
	game.rows.clear()
	game._add_row("gap",1,game.distance+6.0)
	game._update_rows(0);game.world.set_gaps(game.rows,game.distance);game.world.update(game.distance,0)
	check(game.world.materials.road.get_shader_parameter("gap_count")==1,"The visible fracture is bound into the road material")
	await capture("fracture-close")
	var report:Dictionary={"checks":checks,"failed":failures.size(),"failures":failures,"scope":"Native Godot GUI hit testing, touch/drag/tap delivery, screen history, physical runner actions, finite finish and practice. Scripted desktop input; no phone comfort or latency claim."}
	FileAccess.open("res://tests/evidence/scene-interactions.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("NAVIGATION_QA ",JSON.stringify(report))
	game._stop_audio();await create_timer(.18).timeout;game.queue_free();await frames(2)
	quit(0 if failures.is_empty() else 1)
