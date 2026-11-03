extends SceneTree
const Tilt=preload("res://core/tilt_steering.gd")
const Profile=preload("res://core/course_profile.gd")
var checks:int=0
var failures:Array[String]=[]
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func sensor(angle:float) -> Vector3:
	return Vector3(-sin(deg_to_rad(angle))*9.81,-cos(deg_to_rad(angle))*9.81,0)
func prepared() -> RefCounted:
	var t:=Tilt.new()
	for i in range(60):t.calibrate(sensor(0))
	t.finish_calibration()
	return t
func _initialize() -> void:
	root.size=Vector2i(720,1560)
	call_deferred("run")
func run() -> void:
	var t=prepared()
	check(t.available,"Valid gravity samples enable tilt")
	check(not t.valid_sample(Vector3.ZERO) and not t.valid_sample(Vector3(NAN,0,0)),"Missing and nonfinite readings are rejected")
	for i in range(30):t.update(sensor(.6 if i%2 else -.6),1.0/60)
	check(absf(t.filtered)<.001,"Normal hand tremor inside the deadzone stays centred")
	for i in range(30):t.update(sensor(11),1.0/60)
	check(t.filtered>.25 and t.filtered<.65,"Half tilt gives a continuous position between lane anchors")
	for i in range(30):t.update(sensor(35),1.0/60)
	check(t.filtered>.98 and t.filtered<=1.0,"Full tilt reaches a bounded right edge")
	t.inverted=true
	for i in range(45):t.update(sensor(35),1.0/60)
	check(t.filtered<-.98,"Inversion reverses lateral steering")
	for i in range(60):t.update(Vector3.ZERO,1.0/60)
	check(not t.available and absf(t.filtered)<.01,"Sensor loss falls back safely and releases stale steering")
	t.reset_calibration()
	for i in range(60):t.calibrate(sensor(13))
	t.finish_calibration()
	for i in range(20):t.update(sensor(13),1.0/60)
	check(absf(t.filtered)<.001,"Recentring accepts a new comfortable holding angle")
	var low=prepared();low.sensitivity="low"
	var high=prepared();high.sensitivity="high"
	for i in range(30):low.update(sensor(12),1.0/60);high.update(sensor(12),1.0/60)
	check(high.filtered>low.filtered,"Sensitivity changes required phone roll")
	var slow=prepared();var fast=prepared()
	for i in range(15):slow.update(sensor(15),1.0/30)
	for i in range(60):fast.update(sensor(15),1.0/120)
	check(absf(slow.filtered-fast.filtered)<.0001,"Tilt response is independent of frame rate")
	check(Profile.height_at(130)>10.9 and Profile.height_at(250)<-5.9,"The course contains a real crest and a lower valley")
	check(Profile.grade_at(75)>.1 and Profile.grade_at(190)<-.1,"The course includes positive and negative grades")
	check(absf(Profile.height_at(639.99)-Profile.height_at(640.01))<.001,"Repeating elevation has no boundary step")
	var game=load("res://scenes/main.tscn").instantiate()
	game.testing=true;game.profile.settings.control_mode="thumb"
	root.add_child(game)
	await physics_frame
	game.course_id="endless";game._start_run();game.countdown_left=.001
	await physics_frame;await physics_frame
	game.set_physics_process(false)
	for row in game.rows:row.node.queue_free()
	game.rows.clear();game.next_row=100000
	for marker in [75.0,130.0,190.0,250.0,320.0,390.0,460.0,540.0,630.0,710.0]:
		game.core.distance_mm=roundi(marker*1000)
		for i in range(30):
			game._physics_process(1.0/60)
			await physics_frame
		check(absf(game.motor.position.y-game.ground_y)<.06,"Runner feet follow the elevated surface at "+str(marker)+" m")
		check(absf(float(game.world.materials.road.get_shader_parameter("course_distance"))-game.distance)<.01,"Rendered course shares the collision origin at "+str(marker)+" m")
	check(game.core.active_character=="knight" and game.selected=="knight","Elevation and distance never replace the selected runner")
	check(game.core.character_locked and not game.core.offer_route("blocked","witch",180),"The core rejects a handoff during a locked run")
	game._stop_audio();await create_timer(.18).timeout;game.queue_free();await physics_frame;await physics_frame
	var report:Dictionary={"checks":checks,"failed":failures.size(),"failures":failures,"scope":"Synthetic gravity samples, frame-rate invariance, sensor loss/recentering, course grade continuity, live scene surface alignment and character lock. Physical Android sensor behavior remains a device check."}
	FileAccess.open("res://tests/evidence/tilt-and-elevation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("TILT_ELEVATION_QA ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
