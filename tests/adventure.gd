extends SceneTree
const Progress=preload("res://core/progression.gd")
const Secrets=preload("res://core/secret_catalog.gd")
const Core=preload("res://core/run_core.gd")
const CourseProfile=preload("res://core/course_profile.gd")
var checks:int=0
var failures:Array[String]=[]
var game:Node
func _initialize() -> void:
	root.size=Vector2i(720,1560);call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func frames(n:int) -> void:
	for i in range(n):await physics_frame
func touch(at:Vector2,pressed:bool,index:int=9) -> void:
	var e:=InputEventScreenTouch.new();e.index=index;e.position=at;e.pressed=pressed;root.push_input(e,true);await frames(1)
func swipe(direction:Vector2) -> void:
	var at:=Vector2(game.ui.size.x*.48,game.ui.size.y*.60)
	await touch(at,true)
	var e:=InputEventScreenDrag.new();e.index=9;e.position=at+direction*100;e.relative=direction*100;root.push_input(e,true);await frames(1)
	await touch(at+direction*100,false)
func place(metres:float,target_lane:int) -> void:
	game.distance=metres;game.core.distance_mm=roundi(metres*1000);game.ground_y=CourseProfile.height_at(metres)
	game.floor_body.position.y=game.ground_y;game.floor_body.force_update_transform();game.motor.position=Vector3(game.LANES[target_lane],game.ground_y,0);game.motor.velocity=Vector3.ZERO
	game.lane=target_lane;game.lane_from=game.motor.position.x;game.lane_elapsed=.18
func start(hero:String,level:String) -> void:
	game._select_character(hero);game.course_id=level;game.profile.practice_complete=true;game._start_run();game.countdown_left=.001
	game.set_physics_process(true);await frames(4);game.set_physics_process(false)
func run() -> void:
	var p:Dictionary=Progress.fresh();var ids:Dictionary={}
	for entry in Secrets.all_rooms():
		check(Secrets.valid_artifact(entry.id),"Catalog has a valid character/level treasure: "+entry.id);ids[entry.id]=true
	check(ids.size()==9 and Progress.BADGES.size()==14,"Nine distinct treasures and fourteen distinct achievement definitions exist")
	for hero in Secrets.HEROES:
		check(not Progress.ability_unlocked(p,hero),"Traversal starts locked: "+hero)
		var core:=Core.new();core.start(hero,1);check(core.use_power(),"Combat special is available before mastery: "+hero)
		p.mastery[hero]=59;check(not Progress.ability_unlocked(p,hero),"Mastery threshold cannot be bypassed: "+hero)
		var result:Dictionary=Progress.finish_run(p,{"id":"unlock/"+hero,"hero":hero,"distance":18,"unprotected_distance":18})
		check(result.xp==1 and result.ability_unlocked,"Reaching sixty XP unlocks only the runner's traversal ability: "+hero)
		var snapshot:Dictionary=p.duplicate(true);result=Progress.finish_run(p,{"id":"unlock/"+hero,"hero":hero,"distance":10000})
		check(not result.applied and p==snapshot,"A repeated finish cannot award XP or badges twice: "+hero)
	var before:Dictionary=p.duplicate(true)
	check(not Progress.finish_run(p,{"id":"practice","hero":"knight","distance":10000,"practice":true}).applied and p==before,"Standalone practice cannot unlock progression")
	var clean:Dictionary=Progress.normalise({"schema":1,"mastery":{"knight":-10,"witch":NAN},"artifacts":{"bogus/knight":true},"badges":{"bogus":true},"recent_runs":["one","one",false]})
	check(clean.mastery.knight==0 and clean.mastery.witch==0 and clean.artifacts.is_empty() and clean.badges.is_empty() and clean.recent_runs==["one"],"Malformed numeric values, unknown IDs and duplicate recent runs are sanitized")
	var complete:Dictionary=Progress.fresh()
	for i in range(3):Progress.finish_run(complete,{"id":"complete/"+str(i),"hero":Secrets.HEROES[i],"course":Secrets.LEVELS[i],"distance":1200,"unprotected_distance":1200,"relics":100,"defeated":20,"clear":true})
	for entry in Secrets.all_rooms():check(Progress.claim_artifact(complete,entry.id) and not Progress.claim_artifact(complete,entry.id),"A treasure is collectible exactly once: "+entry.id)
	Progress.evaluate(complete);check(complete.badges.size()==14,"Every advertised achievement is reachable from recorded gameplay")
	var restored:Dictionary=Progress.normalise(JSON.parse_string(JSON.stringify(complete)))
	check(restored==complete,"Mastery, treasure discoveries, achievements and deduplication survive JSON round trips")
	game=load("res://scenes/main.tscn").instantiate();game.testing=true;game.profile.settings.control_mode="thumb";game.profile.settings.reduced_motion=true;game.profile.practice_complete=true
	root.add_child(game);await frames(6);await start("knight","endless");game._clear_course_rows();game.next_row=100000
	check(not game.ui.game_buttons.has("attack") and game.ui.game_buttons.has("power"),"Only the special combat action has an on-screen button")
	var x:float=game.motor.position.x;var strikes:int=game.qa_attacks
	await swipe(Vector2.LEFT);check(game.qa_attacks==strikes+1 and game.motor.position.x==x,"A real left swipe attacks without steering")
	game.core.step(25);await swipe(Vector2.RIGHT);check(game.qa_attacks==strikes+2 and game.motor.position.x==x,"A real right swipe attacks without steering")
	await touch(Vector2(360,800),true);await touch(Vector2(360,800),false);check(game.qa_attacks==strikes+2,"A tap does not perform a basic attack")
	game.ui.thumb_pad.show();var pad_at:Vector2=game.ui.thumb_pad.get_global_rect().get_center()-Vector2(65,0)
	await touch(pad_at,true,3);check(game.ui.thumb_pad.active and game.ui.thumb_pad.axis<0 and game.gestures.touches.is_empty(),"The steering pad owns its pointer without leaking an attack gesture")
	for i in range(18):game._physics_process(1.0/60)
	check(game.motor.position.x< -1.5,"A held thumb pad moves the physical runner")
	await touch(pad_at,false,3);var stopped:float=game.motor.position.x
	for i in range(5):game._physics_process(1.0/60)
	check(not game.ui.thumb_pad.active and absf(game.motor.position.x-stopped)<.01,"Releasing the pad stops lateral movement without a stale command")
	await touch(pad_at,true,3);game._intent("pause");check(not game.ui.thumb_pad.active and game.ui.thumb_pad.axis==0,"Pause releases a held steering pointer")
	game._intent("resume");game.set_physics_process(false)
	for level in Secrets.LEVELS:
		for hero in Secrets.HEROES:
			await start(hero,level);game._clear_course_rows();game.progression.mastery[hero]=0
			var entry:Dictionary=Secrets.gate(level,hero);place(float(entry.at)-8,int(entry.lane));game._spawn_secret_gates();game._update_rows(0)
			await swipe(Vector2.UP);check(game.secret_state.is_empty(),"A locked ability leaves the ordinary route playable: "+entry.id)
			game.progression.mastery[hero]=60;await swipe(Vector2.UP)
			check(game.secret_state.get("id","")==entry.id and game.world.secret_theme==hero,"The contextual ability opens its actual character room: "+entry.id)
			check(game.rows.any(func(row):return row.kind=="artifact"),"The secret room contains a physical treasure: "+entry.id)
			var secret_start:float=game.secret_state.start;place(secret_start+62,1);game._update_rows(0)
			check(game.progression.artifacts.has(entry.id) and game.run_treasures.size()==1,"Steering into the treasure records its unique discovery: "+entry.id)
			game._claim_secret_artifact();check(game.run_treasures.size()==1,"Revisited treasure does not duplicate discovery or mastery rewards: "+entry.id)
			place(secret_start+97,1);game._update_secret_route();game._spawn_ahead()
			check(game.secret_state.is_empty() and game.world.secret_theme.is_empty() and not game.rows.is_empty(),"The secret route rejoins ordinary encounters: "+entry.id)
			check(game.selected==hero and game.core.active_character==hero and game.core.character_locked,"Traversal never changes the chosen character: "+entry.id)
	check(game.progression.artifacts.size()==9,"All nine level/character treasures can be discovered through the scene")
	var save_path:String="user://adventure-test.json";FileAccess.open(save_path,FileAccess.WRITE).store_string(JSON.stringify(game.progression))
	check(Progress.normalise(JSON.parse_string(FileAccess.get_file_as_string(save_path))).artifacts.size()==9,"Discovered treasures survive a real file write and load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	game.progression=Progress.fresh();game.profile.practice_complete=false;game.profile.intro_dismissed=false;game.profile.intro_lessons=0;game.course_id="endless";game._start_run()
	game.distance=1000;game.defeated=1;game._finish_intro(true);game._end_run()
	check(game.progression.mastery[game.selected]==0,"Protected lesson distance and the practice sentinel award no mastery XP")
	game._stop_audio();await create_timer(.18).timeout;game.queue_free();await frames(2)
	var report:Dictionary={"checks":checks,"failed":failures.size(),"failures":failures,"scope":"Profile migration/sanitization, mastery thresholds, reward idempotence, fourteen reachable achievements, gesture-only combat, thumb input ownership, pause, nine gated rooms, physical treasure pickup, exits and file persistence. Scripted desktop evidence; no phone performance claim."}
	FileAccess.open("res://tests/evidence/adventure.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("ADVENTURE_QA ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
