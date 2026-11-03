extends Node3D

const Core = preload("res://core/run_core.gd")
const Progress=preload("res://core/progression.gd")
const Secrets=preload("res://core/secret_catalog.gd")
const Hero = preload("res://game/hero.gd")
const World = preload("res://game/world.gd")
const Hud = preload("res://game/hud.gd")
const Geo = preload("res://game/geometry.gd")
const Courses=preload("res://core/course_catalog.gd")
const Director=preload("res://game/encounter_director.gd")
const GestureInput=preload("res://game/gesture_input.gd")
const LANES := [-2.6, 0.0, 2.6]
const Tilt=preload("res://core/tilt_steering.gd")
const CourseProfile=preload("res://core/course_profile.gd")

var core = Core.new()
var world: Node3D
var floor_body: StaticBody3D
var ground_y: float=0.0
var tilt=Tilt.new()
var tilt_warned: bool=false
var last_section: String=""
var motor: CharacterBody3D
var collider: CollisionShape3D
var camera: Camera3D
var key_light: DirectionalLight3D
var hero_key: OmniLight3D
var hero_rim: OmniLight3D
var ui: Control
var heroes: Dictionary = {}
var selected: String = "knight"
var lane: int = 1
var rows: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var gestures=GestureInput.new()
var touches: Dictionary=gestures.touches
var rng := RandomNumberGenerator.new()
var fx_rng := RandomNumberGenerator.new()
var next_row: float = 24.0
var next_gate: float = 180.0
var row_index: int = 0
var sliding_left: float = 0.0
var power_left: float = 0.0
var attack_age: float = 10.0
var attack_token: int = -1
var distance: float = 0.0
var shards: int = 0
var previous_phase: String = "ready"
var outgoing: String = "knight"
var incoming: String = "gargoyle"
var handoff_age: float = 0.0
var total_handoffs: int = 0
var handoff_pairs: Array[String] = []
var clock: float = 0.0
var foot_clock: float = 0.0
var impact_shake: float = 0.0
var profile := {"schema":1,"controls_revision":2,"best":0.0,"runs":0,"relics":0,"history":[],"route_records":{},"selected_character":"knight","selected_course":"endless","practice_complete":false,"intro_lessons":0,"intro_dismissed":false,"settings":{"music":true,"sound":true,"vibration":true,"quality":true,"sensitivity":"normal","control_mode":"tilt","tilt_sensitivity":"normal","tilt_invert":false,"reduced_motion":false}}
var course_id: String="endless"
var last_normal_course: String="endless"
var director=Director.new()
var run_seconds: float=0.0
var run_speed: float=12.0
var countdown_left: float=0.0
var resume_mode: String="game"
var jump_buffer: float=0.0
var slide_buffer: float=0.0
var coyote_left: float=0.0
var lane_from: float=0.0
var lane_elapsed: float=.18
var strike_buffer: float=0.0
var defeated: int=0
var run_recorded: bool=false
var run_outcome: String="ended"
var failure_detail: String=""
var falling: bool=false
var fall_left: float=0.0
var progression:Dictionary=Progress.fresh()
var secret_state:Dictionary={}
var spawned_secrets:Dictionary={}
var manual_steering:bool=false
var strike_direction:int=1
var run_damage:int=0
var unprotected_start:float=0
var combo:int=0
var combo_left:float=0
var run_treasures:Array[String]=[]
var run_badges:Array[String]=[]
var mastery_enemy_offset:int=0
var mastery_shard_offset:int=0
var qa_use_specials:bool=true
var profile_error:String=""
var training_step:int=0
var guided_intro: bool=false
var menu_clear_rows:Array[Dictionary]=[]
var practice_finish_left: float=-1.0
var preview_screen: String="opening"
const TRAINING := [
 {"title":"STEER LEFT","detail":"Tilt left, or hold the left side of the steering pad.","action":"left"},
 {"title":"BACK TO CENTRE","detail":"Return your tilt to neutral, or steer right with the pad.","action":"right"},
 {"title":"SWIPE UP","detail":"Jump. You can keep steering in the air.","action":"jump"},
 {"title":"SWIPE DOWN","detail":"Slide beneath a beam. Down in the air lands into a slide.","action":"slide"},
 {"title":"SWIPE TO STRIKE","detail":"Swipe left or right across the open play area when the sentinel is in reach.","action":"attack"},
 {"title":"MAKE IT SPECIAL!","detail":"Press SPECIAL at the bottom right. Traversal abilities are earned separately.","action":"power"}
]
var sounds: Dictionary = {}
var music: AudioStreamPlayer
var effect_players: Array[AudioStreamPlayer] = []
var sound_cursor: int = 0
var qa: bool = false
var qa_limit: int = 3600
var qa_ticks: int = 0
var qa_deaths: int = 0
var qa_attacks: int = 0
var qa_powers: int = 0
var qa_damage: int = 0
var capture_dir: String = ""
var captures: Dictionary = {}
var capture_busy: bool = false
var menu_capture: bool = false
var anchor: Node3D
var quitting: bool = false
var testing: bool = false
var test_profile_root:String=""
var starting_character: String = "knight"
var qa_incidents: Array[Dictionary] = []
var qa_jump_count: int = 0
var qa_peak_height: float = 0.0
var qa_slide_count: int = 0
var qa_offscreen_ticks: int = 0
var qa_target_sequence := [0, 2, 1, 2, 0, 1]


func _ready() -> void:
	get_tree().auto_accept_quit = false
	for argument in OS.get_cmdline_user_args():
		if argument == "--qa-basic":
			qa_use_specials=false
		elif argument == "--qa":
			qa = true
		elif argument == "--qa-menu":
			menu_capture = true
		elif argument.begins_with("--screen="):
			preview_screen=argument.trim_prefix("--screen=")
		elif argument.begins_with("--qa-ticks="):
			qa_limit = int(argument.get_slice("=", 1))
		elif argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
		elif argument.begins_with("--character="):
			var requested := argument.trim_prefix("--character=")
			if Core.CHARACTERS.has(requested):
				selected = requested
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
	_load_profile()
	progression=Progress.normalise(profile.get("progress",{}),profile)
	profile["progress"]=progression
	if not qa and not menu_capture: selected=str(profile.selected_character)
	course_id="endless" if qa else str(profile.selected_course)
	last_normal_course=course_id
	_setup_environment()
	world = World.new()
	add_child(world)
	world.configure()
	_setup_motor()
	for kind in Core.CHARACTERS:
		var hero = Hero.new()
		hero.configure(kind)
		motor.add_child(hero)
		heroes[kind] = hero
	_setup_audio()
	var anchor_geometry = Geo.new()
	anchor_geometry.ring(Vector3.ZERO,0.48,0.025,Geo.material(Color("c4a1ff"),0,1.2))
	anchor_geometry.ring(Vector3.ZERO,0.26,0.018,Geo.material(Color("e9e5da"),0,0.6))
	anchor = anchor_geometry.build()
	add_child(anchor)
	anchor.visible = false
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Hud.new()
	layer.add_child(ui)
	ui.intent.connect(_intent)
	ui.settings = profile["settings"].duplicate(true)
	_sync_front()
	_select_character(selected)
	_apply_settings()
	if qa:
		if DisplayServer.get_name()=="headless":get_tree().root.size=Vector2i(720,1560)
		_start_run()
		print("SCENE_QA_STARTED "+str(qa_limit))
	if menu_capture:
		_preview_menu()


func _setup_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("384c86")
	sky_material.sky_horizon_color = Color("b6a3ca")
	sky_material.ground_bottom_color = Color("050b16")
	sky_material.ground_horizon_color = Color("342d51")
	sky_material.sky_curve = 0.22
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8b8df")
	environment.ambient_light_energy = 0.92
	environment.fog_enabled = true
	environment.fog_light_color = Color("7476a3")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.0017
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var node := WorldEnvironment.new()
	node.environment = environment
	add_child(node)
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-42, -27, 0)
	key_light.light_color = Color("ffddb2")
	key_light.light_energy = 1.2
	key_light.shadow_enabled = true
	key_light.directional_shadow_max_distance = 65
	add_child(key_light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-24, 148, 0)
	fill.light_color = Color("83b4d2")
	fill.light_energy = 0.78
	add_child(fill)
	camera = Camera3D.new()
	camera.fov = 65
	camera.far = 340
	camera.near = 0.15
	camera.position = Vector3(1.3, 2.65, 5.4)
	add_child(camera)
	camera.look_at(Vector3(0, 1.25, 0))
	var hero_light := OmniLight3D.new()
	hero_key=hero_light
	hero_light.position = Vector3(2.6,3.5,3.0)
	hero_light.omni_range = 8.0
	hero_light.light_energy = 1.1
	hero_light.light_color = Color("e7ceb0")
	add_child(hero_light)
	var rim := OmniLight3D.new()
	hero_rim=rim
	rim.position = Vector3(-2.5,3.2,-1.0)
	rim.omni_range = 6.0
	rim.light_color = Color("7ea6cf")
	rim.light_energy = 1.4
	add_child(rim)


func _setup_motor() -> void:
	floor_body = StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(18, 1, 450)
	floor_shape.shape = box
	floor_shape.position = Vector3(0, -0.5, -180)
	floor_body.add_child(floor_shape)
	add_child(floor_body)
	motor = CharacterBody3D.new()
	motor.name = "AuthoritativeRunner"
	motor.floor_snap_length = 0.12
	motor.platform_floor_layers=0
	collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	motor.add_child(collider)
	add_child(motor)


func _setup_audio() -> void:
	for name in ["strike","impact","spell","wing","handoff","pickup","hurt","step"]:
		sounds[name] = load("res://assets/audio/" + name + ".wav")
	for _index in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -7
		add_child(player)
		effect_players.append(player)
	music = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = load("res://assets/audio/city-pulse.wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = stream.data.size() / 2
	music.stream = stream
	music.volume_db = -24
	add_child(music)
	music.play()


func _sound(name: String, pitch: float = 1.0) -> void:
	if not profile["settings"]["sound"] or not sounds.has(name):
		return
	var player: AudioStreamPlayer = effect_players[sound_cursor % effect_players.size()]
	sound_cursor += 1
	player.stream = sounds[name]
	player.pitch_scale = pitch
	player.volume_db = -20 if name == "step" else -8
	player.play()


func _select_character(kind: String) -> void:
	selected=kind
	if is_instance_valid(ui) and ui.mode in ["opening","home","team"] and heroes.has(kind):heroes[kind].celebrate()
	for character in heroes:
		heroes[character].visible=character==kind
		heroes[character].position=Vector3.ZERO
		heroes[character].rotation=Vector3.ZERO
		heroes[character].scale=Vector3.ONE
		heroes[character].sliding=false
		heroes[character].airborne=false
		heroes[character].lean=0
	ui.selected=kind
	world.set_theme(kind if course_id=="endless" else str(Courses.get_course(course_id).theme))
	_sync_front()


func _sync_front() -> void:
	if not is_instance_valid(ui):return
	profile["progress"]=progression
	ui.profile_data=profile.duplicate(true)
	ui.profile_data["in_run"]=core.phase=="paused"
	ui.profile_data["reset_error"]=profile_error
	ui.selected=selected
	ui.course_id=course_id
	ui.refresh()


func _open_screen(screen: String, root: bool=false) -> void:
	gestures.reset();ui.thumb_pad.reset()
	ui.open_screen(screen,root)
	_sync_front()


func _menu_stage(delta: float) -> void:
	world.visible=true;motor.visible=true;world.flat_course=true
	world.set_gaps(menu_clear_rows,0);world.update(0,delta)
	motor.position=Vector3.ZERO;motor.velocity=Vector3.ZERO
	var active:Node3D=heroes[selected]
	active.rotation=Vector3.ZERO;active.facing=.12;active.body.rotation.y=.12
	active.moving=false;active.airborne=false;active.sliding=false;active.lean=0
	active.animate(delta)
	camera.fov=48;camera.h_offset=0;camera.v_offset=0
	var stage:Control=ui.front.stage_control
	var centre_y:float=.42
	var fraction_y:float=.28
	if is_instance_valid(stage) and stage.size.y>1:
		centre_y=stage.get_global_rect().get_center().y/ui.size.y
		fraction_y=stage.size.y*.94/ui.size.y
	var projection:Projection=camera.get_camera_projection()
	var orbit_distance:float=maxf(2.45*projection.y.y/(2*fraction_y),2.5*projection.x.x/1.7)
	var focus:=Vector3(0,1.05,0)
	camera.position=focus+Vector3(2.25,.80,4.7).normalized()*orbit_distance
	camera.look_at(focus)
	camera.v_offset=(centre_y-.5)*2*orbit_distance/projection.y.y
	hero_key.position=Vector3(2.6,3.5,3);hero_rim.position=Vector3(-2.5,3.2,-1)
	for row in rows:row.node.visible=false
	for effect in effects:effect.node.visible=false


func _start_run() -> void:
	for row in rows:row.node.queue_free()
	rows.clear()
	for effect in effects:effect.node.queue_free()
	effects.clear()
	core=Core.new()
	secret_state.clear();spawned_secrets.clear();run_treasures.clear();run_badges.clear()
	world.secret_theme="";world.secret_level="";manual_steering=false;run_damage=0;combo=0;combo_left=0;unprotected_start=0;mastery_enemy_offset=0;mastery_shard_offset=0
	ui.thumb_pad.reset()
	starting_character=selected
	if qa and selected=="gargoyle":qa_target_sequence=[1,2,0,2,1,0]
	elif qa and selected=="witch":qa_target_sequence=[1,0,2,0,1,2]
	var run_seed:=73129 if qa else (int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_usec()))
	core.start(selected,run_seed)
	core.character_locked=true
	ground_y=0.0;floor_body.position.y=0.0
	tilt.reset_calibration();tilt_warned=false;last_section=""
	rng.seed=run_seed;fx_rng.seed=run_seed ^ 90871
	director.configure(course_id,run_seed)
	lane=1;lane_from=0;lane_elapsed=.18
	motor.position=Vector3.ZERO;motor.velocity=Vector3.ZERO;motor.set_collision_mask_value(1,true)
	falling=false;fall_left=0;strike_buffer=0;jump_buffer=0;slide_buffer=0;coyote_left=0
	next_row=64;next_gate=180;row_index=0;distance=0;shards=0;defeated=0
	run_recorded=false;run_seconds=0;run_outcome="ended";failure_detail=""
	sliding_left=0;power_left=0;attack_age=10;attack_token=-1
	guided_intro=not qa and course_id=="endless" and not bool(profile.practice_complete) and not bool(profile.intro_dismissed)
	training_step=clampi(int(profile.intro_lessons),0,5) if guided_intro else 0
	practice_finish_left=-1
	previous_phase="running";total_handoffs=0;handoff_pairs.clear()
	gestures.reset()
	for hero in heroes.values():
		hero.sliding=false;hero.airborne=false;hero.moving=false;hero.lean=0
		hero.facing=PI;hero.body.rotation.y=PI
		hero.motion.attack_clock=99;hero.motion.power_clock=99;hero.attack_time=0;hero.power_time=0
		hero.animate(.2)
	camera.position=Vector3(0,3.3,7.4);camera.h_offset=0;camera.v_offset=0
	camera.look_at(Vector3(0,1.45,-18))
	countdown_left=0 if qa else 1.5
	ui.countdown_text="READY"
	ui.control_hint="HOLD YOUR PHONE COMFORTABLY" if profile.settings.control_mode=="tilt" else "USE THE STEERING PAD"
	ui.navigation.clear()
	ui.set_mode("game" if qa else "countdown")
	ui.guide_title="";ui.guide_detail="";ui.combat_ready=false;ui.combat_warning=false
	ui.intro_active=guided_intro;ui.district_name="";ui.district_left=0
	world.visible=true;motor.visible=true
	_select_character(selected)
	_spawn_ahead();world.flat_course=course_id=="training";world.update(0,0);_update_rows(0)
	if course_id=="training" or guided_intro:_training_prompt()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(ui):return
	clock+=delta
	if ui.mode=="countdown":
		heroes[selected].moving=false;heroes[selected].animate(delta)
		if profile.settings.control_mode=="tilt":tilt.calibrate(_motion_sample())
		countdown_left=maxf(0,countdown_left-delta)
		motor.velocity=Vector3(0,-1,0);motor.move_and_slide()
		var text:="READY" if countdown_left>.65 else "GO"
		if ui.countdown_text!=text:ui.countdown_text=text;ui.refresh()
		if countdown_left<=0:
			tilt.finish_calibration();gestures.reset();ui.set_mode("game")
		return
	if ui.mode!="game":
		anchor.visible=false
		if ui.mode in ["opening","home","team"]:_menu_stage(delta)
		return
	if qa:_qa_control()
	run_seconds+=delta
	run_speed=Courses.speed_at(course_id,distance,run_seconds)
	if course_id!="training":run_speed=clampf(run_speed-CourseProfile.grade_at(distance)*3.0,17.0,24.0)
	core.set_speed(run_speed)
	core.step()
	distance=core.distance_mm/1000.0
	var surface:float=CourseProfile.height_at(distance) if course_id!="training" else 0.0
	motor.position.y+=surface-ground_y
	ground_y=surface;floor_body.position.y=surface
	floor_body.force_update_transform()
	sliding_left=maxf(0,sliding_left-delta);power_left=maxf(0,power_left-delta);attack_age+=delta
	jump_buffer=maxf(0,jump_buffer-delta);slide_buffer=maxf(0,slide_buffer-delta)
	coyote_left=.10 if motor.is_on_floor() else maxf(0,coyote_left-delta)
	var gravity:=27.0
	if not motor.is_on_floor():motor.velocity.y-=gravity*delta
	elif motor.velocity.y<0:motor.velocity.y=-.5
	if jump_buffer>0 and coyote_left>0 and not falling:
		motor.velocity.y=9.0;jump_buffer=0;coyote_left=0;sliding_left=0;qa_jump_count+=1
		_training_action("jump")
	if slide_buffer>0 and motor.is_on_floor():
		sliding_left=.72;slide_buffer=0;qa_slide_count+=1;_training_action("slide")
	lane_elapsed=minf(.18,lane_elapsed+delta)
	var t:=smoothstep(0,.18,lane_elapsed)
	var desired_x:=lerpf(lane_from,float(LANES[lane]),t)
	if profile.settings.control_mode=="tilt" and not qa:
		var tilt_x:float=tilt.update(_motion_sample(),delta)
		if tilt.available:
			desired_x=lerpf(motor.position.x,tilt_x,1.0-exp(-delta*17.0))
			lane=clampi(roundi(tilt_x/2.6)+1,0,2)
			lane_from=motor.position.x;lane_elapsed=0.18
			if tilt_x< -1.6:_training_action("left")
			elif tilt_x> -0.6 and tilt_x<0.6:_training_action("right")
		elif OS.get_name()=="Android" and tilt.missing_seconds>1.0 and not tilt_warned:
			tilt_warned=true;ui.message("NO MOTION SENSOR · USE THE STEERING PAD",3.0)
			if course_id=="training":_training_prompt()
	if not qa and (profile.settings.control_mode!="tilt" or not tilt.available):
		if ui.thumb_pad.active:manual_steering=true
		if manual_steering:
			desired_x=clampf(motor.position.x+ui.thumb_pad.axis*8.5*delta,-Tilt.LIMIT,Tilt.LIMIT)
			lane=clampi(roundi(desired_x/2.6)+1,0,2);lane_from=desired_x;lane_elapsed=.18
	if desired_x< -1.6:_training_action("left")
	elif absf(desired_x)<.6:_training_action("right")
	motor.velocity.x=(desired_x-motor.position.x)/delta
	motor.velocity.z=0
	motor.move_and_slide()
	qa_peak_height=maxf(qa_peak_height,motor.position.y-ground_y)
	var capsule: CapsuleShape3D=collider.shape
	capsule.height=.9 if sliding_left>0 else 1.8;collider.position.y=capsule.height*.5
	if strike_buffer>0:
		strike_buffer=maxf(0,strike_buffer-delta)
		_perform_attack()
	combo_left=maxf(0,combo_left-delta)
	if combo_left==0:combo=0
	_update_secret_route()
	_spawn_ahead();_update_rows(delta);_update_effects(delta)
	world.set_gaps(rows,distance)
	world.flat_course=course_id=="training"
	world.update(distance,delta)
	var active: Node3D=heroes[selected]
	active.motion.locomotion_rate=clampf(run_speed/16.0,.55,1.65)
	active.moving=true;active.airborne=motor.position.y-ground_y>.10 or falling;active.sliding=sliding_left>0;active.lean=motor.velocity.x*.035
	active.animate(delta)
	active.rotation.x=lerp_angle(active.rotation.x,atan(CourseProfile.grade_at(distance))*.7,1-exp(-delta*9)) if course_id!="training" else 0.0
	hero_key.position=Vector3(motor.position.x+2.6,ground_y+3.5,3.0)
	hero_rim.position=Vector3(motor.position.x-2.5,ground_y+3.2,-1.0)
	var target_height:float=ground_y+3.2+clampf(motor.position.y-ground_y,0,2)*.10
	var view_target:=Vector3(motor.position.x*.70,target_height,6.1)
	camera.position=camera.position.lerp(view_target,1-exp(-delta*8))
	camera.position.x=clampf(camera.position.x,motor.position.x-.9,motor.position.x+.9)
	var ahead_height:float=CourseProfile.height_at(distance+18) if course_id!="training" else 0.0
	camera.look_at(Vector3(motor.position.x*.50,1.45+lerpf(ground_y,ahead_height,.62),-18))
	var target_fov:float=66.0 if profile.settings.reduced_motion else 72+clampf(run_speed-18,0,6)*.65
	camera.fov=lerpf(camera.fov,target_fov,1-exp(-delta*4))
	impact_shake=maxf(0,impact_shake-delta*4)
	camera.h_offset=0 if profile.settings.reduced_motion else sin(clock*63)*impact_shake*.022;camera.v_offset=0 if profile.settings.reduced_motion else cos(clock*77)*impact_shake*.015
	if qa:
		var projected:=camera.unproject_position(motor.position+Vector3(0,1.1,0))
		if projected.x<0 or projected.x>get_viewport().get_visible_rect().size.x:qa_offscreen_ticks+=1
	foot_clock+=delta
	if foot_clock>maxf(.22,3.8/run_speed) and motor.is_on_floor() and sliding_left<=0:
		foot_clock=0;_sound("step",.95+fx_rng.randf()*.08)
	var snapshot: Dictionary=core.snapshot()
	snapshot["course_length"]=Courses.get_course(course_id).length
	snapshot["district"]=CourseProfile.section_at(distance) if course_id!="training" else "GUIDED PRACTICE"
	snapshot["speed_mps"]=run_speed;snapshot["elevation_m"]=ground_y
	snapshot["tilt_position"]=tilt.filtered
	snapshot["steering"]="TILT" if profile.settings.control_mode=="tilt" and tilt.available else "THUMB"
	snapshot["power_available"]=true
	snapshot["combo"]=combo;snapshot["secret"]=str(secret_state.get("title",""))
	ui.update_session(snapshot,shards)
	anchor.visible=false
	if course_id=="training" and practice_finish_left>=0:
		practice_finish_left-=delta
		if practice_finish_left<=0:run_outcome="practice";core.complete_run();_end_run();return
	var length: float=Courses.get_course(course_id).length
	if length>0 and distance>=length and core.complete_run():
		run_outcome="clear";_end_run();return
	if core.phase=="failed":
		if falling:
			fall_left-=delta
			if fall_left>0:return
		_end_run();return
	if qa:
		qa_ticks+=1
		if qa_ticks%600==0:print("SCENE_QA_PROGRESS "+str(qa_ticks)+" "+selected+" "+str(total_handoffs))
		if not captures.has("fracture-course"):
			for row in rows:
				if row.kind=="gap" and float(row.at)-distance>5 and float(row.at)-distance<30:_capture("fracture-course");break
		if qa_ticks in [180,600,1200,1800,2400,3000]:_capture("game-%04d-%s"%[qa_ticks,selected])
		if qa_ticks>=qa_limit:_qa_finish()


func _spawn_ahead() -> void:
	if course_id=="training" or guided_intro:return
	if not secret_state.is_empty():return
	_spawn_secret_gates()
	if row_index==0:
		var trail_start:float=maxf(22,next_row-42)
		for offset in [0.0,3.0,6.0,9.0]:_add_row("shard",1,trail_start+offset)
	while next_row<distance+150:
		var phrase: Array[Dictionary]=director.phrase(row_index,next_row)
		for entry in phrase:
			var finish: float=Courses.get_course(course_id).length
			if finish>0 and float(entry.at)>finish-18:continue
			if entry.kind!="shard" and _near_secret_entry(float(entry.at)):continue
			_add_row(str(entry.kind),int(entry.lane),float(entry.at))
		row_index+=1;next_row+=Director.PHRASE_LENGTH


func _add_row(kind: String, target_lane: int, marker: float) -> void:
	var node:Node3D=world.secret_portal(selected,Progress.ability_unlocked(progression,selected)) if kind=="secret_gate" else world.prop(kind)
	add_child(node)
	var token:int=core.register_collectible(150 if kind=="artifact" else 25) if kind in ["shard","artifact"] else -1
	rows.append({"kind":kind,"lane":target_lane,"at":marker,"node":node,"resolved":false,"id":token,"epoch":-1})


func _update_rows(delta: float) -> void:
	ui.route_visible = false
	ui.combat_ready=false
	ui.combat_warning=false;ui.threat_seconds=INF
	if secret_state.is_empty():ui.secret_hint=""
	for index in range(rows.size()-1,-1,-1):
		var row: Dictionary = rows[index]
		var node: Node3D = row["node"]
		var kind := str(row["kind"])
		if row.get("practice_target",false):row["at"]=distance+3.4
		if row.get("guided_target",false) and not row.resolved and float(row.at)<distance-2:
			row.at=distance+maxf(run_speed,18.5)*1.6
			row.lane=lane
		var z := distance-float(row["at"])
		node.position = Vector3(LANES[int(row["lane"])],0,z)
		if kind=="enemy":
			node.position.y=CourseProfile.height_at(float(row.at)) if course_id!="training" else 0.0
			node.position.x+=CourseProfile.lateral_at(float(row.at),distance)
			node.rotation.x=atan(CourseProfile.grade_at(float(row.at)))
		if z > 24:
			if kind in ["enemy","drone","barrier"]:
				core.retire_enemy(int(row["id"]))
			elif kind in ["shard","artifact"]:
				core.retire_collectible(int(row["id"]))
			node.queue_free()
			rows.remove_at(index)
			continue
		if kind == "gate":
			world.update_labels(node)
			continue
		if bool(row["resolved"]):
			if kind=="enemy" and row.has("pop_age"):
				row.pop_age=float(row.pop_age)+delta;node.visible=float(row.pop_age)<.45
				node.position.y+=float(row.pop_age)*3.0;node.rotation.z=float(row.pop_age)*float(row.get("pop_direction",1))*4
				node.scale=Vector3.ONE*maxf(.02,1.0-float(row.pop_age)*2.1)
			continue
		if kind in ["enemy","drone","barrier"] and int(row["epoch"]) != core.handoff_epoch and core.phase in ["running","telegraph","committed"]:
			row["id"] = core.register_enemy(125 if kind == "drone" else 100 if kind == "enemy" else 50)
			row["epoch"] = core.handoff_epoch
		if kind=="secret_gate":
			var entry:Dictionary=row.get("secret",{})
			for child in node.get_children():
				if child is Label3D:
					child.position.y=3.7+(CourseProfile.height_at(float(row.at)) if course_id!="training" else 0.0)
					child.position.x=CourseProfile.lateral_at(float(row.at),distance)
			var gate_ahead:float=float(row.at)-distance
			if gate_ahead>0 and gate_ahead<maxf(18.5,run_speed)*2.1:
				ui.secret_hint="%s\nSWIPE UP IN ITS LANE TO ENTER!"%entry.ability if Progress.ability_unlocked(progression,selected) else "%s SECRET\nEARN 60 MASTERY XP TO UNLOCK %s"%[selected.to_upper(),entry.ability]
			continue
		if kind in ["shard","artifact"]:
			node.rotation.y += delta*(2.5 if kind=="shard" else 1.2)
			node.position.y = sin(clock*2.6+float(row["at"]))*0.08
		if kind == "enemy" and z>-55 and z<8:
			node.threat_intensity=clampf(1.0-maxf(0,float(row.at)-distance)/(maxf(run_speed,18.5)*1.6),0,1)
			node.animate(delta)
		if kind == "drone":
			node.position.y = sin(clock*3+float(row["at"]))*0.12
		var contact_width := 1.35 if kind in ["barrier","beam"] else 1.25 if kind == "gap" else 0.70 if kind == "shard" else 0.85
		var same_lane := absf(motor.position.x-LANES[int(row["lane"])]) < contact_width
		var ahead := motor.position.z-z
		if kind in ["enemy","drone"] and ahead>0 and ahead<=maxf(run_speed,18.5)*1.6 and absf(motor.position.x-LANES[int(row.lane)])<.95 and _line_clear(row):
			var approach:float=ahead/maxf(run_speed,18.5)
			if approach<ui.threat_seconds:
				ui.combat_warning=true;ui.threat_seconds=approach
				ui.threat_position=camera.unproject_position(node.position+Vector3(0,1.45,0))
		if same_lane and kind in ["enemy","drone","barrier"]:
			var attack_range := 13.0 if selected == "witch" else 4.2
			if kind!="barrier" and ahead>0 and ahead<strike_cue_range() and absf(motor.position.x-LANES[int(row["lane"])])<.95 and _line_clear(row):ui.combat_ready=true
			var charging := selected == "knight" and power_left > 0
			if charging and ahead > 0 and ahead < 7.0:
				if core.resolve_enemy(int(row["id"]),core.power_attack_token):
					_destroy_row(row)
			elif kind != "barrier" and attack_age >= 0.045 and attack_age < 0.36 and ahead > 0 and ahead < attack_range and (selected == "witch" or (motor.position.y-ground_y) < 1.9):
				if _line_clear(row) and core.resolve_enemy(int(row["id"]),attack_token):
					_destroy_row(row)
		if bool(row["resolved"]):
			continue
		if same_lane and kind == "shard" and absf(ahead) < 0.9 and (motor.position.y-ground_y) < 2.4:
			if core.collect(int(row["id"])):
				shards += 1
				row["resolved"] = true
				node.visible = false
				_gain_combo();ui.pickup()
				_sound("pickup",.95+mini(combo,10)*.055)
		elif same_lane and kind=="artifact" and absf(ahead)<1.25 and (motor.position.y-ground_y)<2.5:
			if not secret_state.is_empty() and core.collect(int(row.id)):
				row.resolved=true;node.visible=false;_claim_secret_artifact()
		elif same_lane and kind == "gap" and absf(ahead) < 1.8:
			if (motor.position.y-ground_y) < 0.18 and core.phase in ["running","telegraph","committed"]:
				row["edge_time"]=float(row.get("edge_time",0))+delta
				if float(row.edge_time)<.075:continue
				core.fail_run("fell_into_fracture")
				failure_detail="A fracture opened beneath you. Jump or change lane before the edge."
				falling=true;fall_left=.48;motor.set_collision_mask_value(1,false);motor.velocity.y=-5
				row["resolved"] = true
		elif same_lane and kind not in ["shard","gap","artifact","secret_gate"] and ahead < 0.65 and ahead > -0.7:
			var clear := (kind == "beam" and (sliding_left > 0.0 or (motor.position.y-ground_y) > 1.8)) or (kind == "barrier" and (motor.position.y-ground_y) > 1.10) or (kind == "enemy" and (motor.position.y-ground_y) > 2.1) or (kind == "drone" and (sliding_left > 0.0 or (motor.position.y-ground_y) > 2.1))
			if not clear:
				if kind == "gap" and core.phase in ["running","telegraph","committed"]:
					core.fail_run("fell_into_fracture")
				else:
					_hurt(row)
			row["resolved"] = true
			if kind in ["enemy","drone","barrier"]:
				core.retire_enemy(int(row["id"]))


func _line_clear(target: Dictionary) -> bool:
	for blocker in rows:
		if blocker["resolved"] or blocker["kind"] not in ["barrier","beam"]:
			continue
		if blocker["lane"] == target["lane"] and float(blocker["at"]) > distance and float(blocker["at"]) < float(target["at"]):
			return false
	return true


func _destroy_row(row: Dictionary) -> void:
	defeated+=1;_gain_combo()
	if row.get("practice_target",false) or row.get("guided_target",false):_training_action("attack")
	ui.impact("POW!" if selected=="knight" else "BONK!" if selected=="gargoyle" else "ZAP!",heroes[selected].accent())
	impact_shake=1.0
	row["resolved"] = true
	row["node"].visible = row.kind=="enemy"
	if row.kind=="enemy":row["pop_age"]=0.0;row["pop_direction"]=strike_direction
	_burst(Vector3(row["node"].position.x,ground_y+1,row["node"].position.z),heroes[selected].accent())
	_sound("impact",1.0 if selected == "knight" else 1.25)
	if profile["settings"]["vibration"] and not qa:
		Input.vibrate_handheld(16)


func _hurt(context: Dictionary = {}) -> void:
	if course_id=="training" or guided_intro:return
	failure_detail={"enemy":"A sentinel caught you. Tap to strike when the target cue appears, or change lane.","drone":"A drone caught you. Slide beneath it or move to a clear lane.","barrier":"You hit a low barrier. Jump or change lane before contact.","beam":"An overhead beam caught you. Swipe down to slide."}.get(str(context.get("kind","")),"Your team ran out of health. Read the next opening and try again.")
	if power_left > 0.0 and selected in ["knight","witch"]:
		return
	if core.receive_damage():
		qa_damage += 1;run_damage+=1;combo=0;combo_left=0
		qa_incidents.append({"tick":core.tick,"character":selected,"kind":context.get("kind","unknown"),"at":context.get("at",0),"runner_y":motor.position.y,"slide":sliding_left,"attack_age":attack_age,"phase":core.phase})
		ui.flash = 1.0
		_sound("hurt")
		if profile["settings"]["vibration"] and not qa:
			Input.vibrate_handheld(40)


func _attack(direction:int=1) -> void:
	if ui.mode!="game" or core.phase not in ["running","telegraph","committed"]:return
	strike_direction=direction;strike_buffer=.45
	_perform_attack()


func strike_cue_range() -> float:
	# A cue is only active where a tap is accepted immediately or buffered safely.
	return 13.0 if selected=="witch" else minf(11.0,5.1+maxf(run_speed,18.5)*.24)


func _perform_attack() -> void:
	if selected!="witch":
		var nearest:=INF
		for row in rows:
			if not row.resolved and row.kind in ["enemy","drone"] and absf(LANES[int(row.lane)]-motor.position.x)<.95:
				var ahead:float=float(row.at)-distance
				if ahead>0:nearest=minf(nearest,ahead)
		if nearest>5.1 and nearest<=strike_cue_range():return
	var token: int=core.attack()
	if token<0:return
	strike_buffer=0;attack_token=token;attack_age=0;qa_attacks+=1
	heroes[selected].attack(strike_direction)
	_sound("spell" if selected=="witch" else "strike")
	_strike_trail()


func _strike_trail() -> void:
	var geometry=Geo.new()
	var color: Color=heroes[selected].accent()
	var material:=Geo.material(color,.0,1.2)
	if selected=="witch":
		var endpoint:=Vector3(motor.position.x,ground_y+1.3,-12)
		for row in rows:
			if not row.resolved and row.kind in ["enemy","drone"] and absf(LANES[int(row.lane)]-motor.position.x)<.95 and float(row.at)-distance>0 and float(row.at)-distance<13:
				endpoint=Vector3(LANES[int(row.lane)],ground_y+1.3,distance-float(row.at));break
		var holder:=Node3D.new();add_child(holder)
		Geo.segment(holder,Vector3(motor.position.x,ground_y+1.4,-.2),endpoint,.027,material)
		effects.append({"node":holder,"life":.18,"max":.18,"velocity":Vector3.ZERO,"ring":true})
	else:
		for i in range(18):
			var a:float=lerpf(-1.15,1.15,i/18.0);var b:float=lerpf(-1.15,1.15,(i+1)/18.0)
			var center:=Vector3(motor.position.x,ground_y+1.3,-.7)
			geometry.triangle(center+Vector3(sin(a)*1.35,cos(a)*.7,-.5),center+Vector3(sin(b)*1.35,cos(b)*.7,-.5),center+Vector3(sin(a)*1.65,cos(a)*.92,-.6),material)
		var node:Node3D=geometry.build();add_child(node)
		effects.append({"node":node,"life":.16,"max":.16,"velocity":Vector3.ZERO,"ring":true})


func _power() -> void:
	if ui.mode!="game" or core.phase=="committed" or not core.use_power():return
	qa_powers+=1;power_left=.55;heroes[selected].power()
	var radius:float={"knight":18.0,"gargoyle":15.0,"witch":24.0}[selected]
	var hits:int=0
	for row in rows:
		if row.resolved or row.kind not in ["enemy","drone","barrier"]:continue
		var ahead:float=float(row.at)-distance
		if ahead<=0 or ahead>radius or not _line_clear(row):continue
		if selected=="witch" and hits>=3:break
		if core.resolve_enemy(int(row.id),core.power_attack_token):
			_destroy_row(row);hits+=1
			if selected=="witch":
				var bolt:=Node3D.new();add_child(bolt)
				Geo.segment(bolt,Vector3(motor.position.x,ground_y+1.3,0),Vector3(row.node.position.x,ground_y+1.2,row.node.position.z),.045,Geo.material(heroes[selected].accent(),0,1.2))
				effects.append({"node":bolt,"life":.28,"max":.28,"velocity":Vector3.ZERO,"ring":true})
	for i in range(3):_pulse(heroes[selected].accent(),Vector3(motor.position.x,ground_y+.14,-2.0-i*2.4),.8+i*.55)
	_burst(motor.position+Vector3(0,.8,0),heroes[selected].accent())
	_sound("spell" if selected=="witch" else "impact",1.15 if selected=="gargoyle" else .9)
	ui.message(Secrets.SPECIALS[selected]+"!",1.0);_training_action("power")


func _blink_destination() -> int:
	var safest := lane
	var best_clearance := -1.0
	for candidate in [lane-1 if lane>0 else lane+1,lane+1 if lane<2 else lane-1,lane]:
		var clearance := 14.0
		for row in rows:
			if row["resolved"] or row["kind"] in ["shard","gate"] or int(row["lane"]) != candidate:
				continue
			var forward := float(row["at"])-distance
			if forward > -1.0:
				clearance = minf(clearance,forward)
		if clearance > best_clearance:
			best_clearance = clearance
			safest = candidate
	return safest if best_clearance >= 8.0 else -1


func _jump() -> void:
	if ui.mode!="game" or core.phase in ["handoff","failed","completed"]:return
	if _try_secret_entry():return
	jump_buffer=.12


func _slide() -> void:
	if ui.mode!="game" or core.phase in ["handoff","failed","completed"]:return
	slide_buffer=.20
	if not motor.is_on_floor():motor.velocity.y=minf(motor.velocity.y,-14.0)
	else:
		if sliding_left<=0:qa_slide_count+=1
		sliding_left=.72;slide_buffer=0;_training_action("slide")


func _pulse(color: Color, at: Vector3, radius: float) -> void:
	if effects.size() > 65:
		return
	var b = Geo.new()
	b.ring(Vector3.ZERO,radius,0.027,Geo.material(color,0.0,2.2),Vector3(0.0,0.0,0.0))
	var node: Node3D = b.build()
	add_child(node)
	node.position = at
	effects.append({"node":node,"life":0.35,"max":0.35,"velocity":Vector3(0,0,8),"ring":true})


func _burst(at: Vector3, color: Color) -> void:
	for index in range(7):
		if effects.size() > 65:
			break
		var b = Geo.new()
		b.box(Vector3.ZERO,Vector3.ONE*0.09,Geo.material(color,0.2,1.5))
		var node: Node3D = b.build()
		add_child(node)
		node.position = at
		var velocity := Vector3(fx_rng.randf_range(-3,3),fx_rng.randf_range(1,5),fx_rng.randf_range(2,7))
		effects.append({"node":node,"life":0.5,"max":0.5,"velocity":velocity,"ring":false})


func _update_effects(delta: float) -> void:
	for index in range(effects.size()-1,-1,-1):
		var item: Dictionary = effects[index]
		item["life"] = float(item["life"])-delta
		if float(item["life"]) <= 0:
			item["node"].queue_free()
			effects.remove_at(index)
			continue
		item["node"].position += item["velocity"]*delta
		var amount := float(item["life"])/float(item["max"])
		item["node"].scale = Vector3.ONE*(0.4+amount*0.6)
		if item["ring"]:
			item["node"].rotation.y += delta*4
		else:
			item["velocity"].y -= delta*9
			item["node"].rotate_x(delta*5)


func _intent(action: String, value: String="") -> void:
	match action:
		"enter":_open_screen("home",true)
		"navigate":_open_screen(value)
		"tab":_open_screen(value,true)
		"course":
			if Courses.ORDER.has(value):course_id=value;last_normal_course=value;profile.selected_course=value;_save_profile();_sync_front()
		"character":
			if ui.mode not in ["game","countdown","pause"] and core.phase!="paused" and Core.CHARACTERS.has(value):_select_character(value);profile.selected_character=value;_save_profile()
		"start","restart":_start_run()
		"practice":
			if course_id!="training":last_normal_course=course_id
			course_id="training";_start_run()
		"power":_power()
		"pause":
			if ui.mode in ["game","countdown"] and core.pause():
				resume_mode=ui.mode;gestures.reset();ui.thumb_pad.reset()
				ui.result_data={"distance":distance};_open_screen("pause",true)
		"resume":
			if core.resume():
				gestures.reset();ui.thumb_pad.reset();ui.navigation.clear()
				if profile.settings.control_mode=="tilt":
					tilt.reset_calibration();countdown_left=1.2;ui.set_mode("countdown")
				else:ui.set_mode(resume_mode)
		"home","results_routes","results_team":
			if core.phase=="paused":return
			if course_id=="training":course_id=last_normal_course
			motor.position=Vector3.ZERO;_open_screen("home" if action=="home" else "team" if action=="results_team" else "routes",true)
		"skip_intro":
			if guided_intro:_finish_intro(false)
		"abandon":
			if core.phase=="paused":core.resume()
			run_outcome="abandoned";failure_detail="You ended the run. Your progress up to this point is in your journal.";core.fail_run("abandoned");_end_run()
		"reset_progress":
			if core.phase=="paused" or ui.mode!="reset_confirm":return
			var previous_profile:Dictionary=profile.duplicate(true);var previous_progress:Dictionary=progression.duplicate(true)
			progression=Progress.fresh();profile.best=0;profile.runs=0;profile.relics=0;profile.history=[];profile.route_records={}
			profile.practice_complete=false;profile.intro_dismissed=false;profile.intro_lessons=0
			if not _save_profile(true):
				profile=previous_profile;progression=previous_progress;profile_error="Couldn't clear the local save. Check free storage and try again.";_sync_front();return
			profile_error=""
			_open_screen("home",true)
		"settings":_open_screen("settings")
		"credits":_open_screen("credits")
		"back":
			if ui.mode=="pause":_intent("resume")
			elif ui.mode=="results":_intent("home")
			else:ui.go_back();gestures.reset();_sync_front()
		"setting":
			if profile.settings.get(value) is bool:profile.settings[value]=not profile.settings[value];ui.settings=profile.settings.duplicate(true);_apply_settings();_save_profile();_sync_front()
		"control_mode":
			profile.settings.control_mode="thumb" if profile.settings.control_mode=="tilt" else "tilt"
			_save_profile();_sync_front()
		"tilt_sensitivity":
			var values:Array=["low","normal","high"]
			profile.settings.tilt_sensitivity=values[(values.find(profile.settings.tilt_sensitivity)+1)%3]
			_apply_settings();_save_profile();_sync_front()
		"recenter":
			tilt.reset_calibration();_intent("resume")
		"sensitivity":
			var values: Array=["low","normal","high"]
			profile.settings.sensitivity=values[(values.find(profile.settings.sensitivity)+1)%3]
			gestures.sensitivity=profile.settings.sensitivity;_save_profile();_sync_front()


func _end_run() -> void:
	if run_recorded:return
	run_recorded=true
	profile.selected_character=selected
	gestures.reset()
	ui.guide_title="";ui.guide_detail="";anchor.visible=false
	var progress_result:Dictionary={"xp":0,"new_badges":[],"ability_unlocked":false}
	if course_id!="training":
		if not qa:
			progress_result=Progress.finish_run(progression,{"id":"%d:%s:%d"%[core.seed_value,starting_character,core.tick],"hero":starting_character,"course":course_id,"distance":distance,"unprotected_distance":0 if guided_intro else maxf(0,distance-unprotected_start),"relics":0 if guided_intro else maxi(0,shards-mastery_shard_offset),"defeated":0 if guided_intro else maxi(0,defeated-mastery_enemy_offset),"damage":run_damage,"clear":run_outcome=="clear","treasures":run_treasures.size()})
		profile.best=maxf(float(profile.best),distance);profile.runs=int(profile.runs)+1;profile.relics=int(profile.relics)+shards
		var records:Dictionary=profile.route_records
		var record:Dictionary=records.get(course_id,{"best":0.0,"clears":0})
		record.best=maxf(float(record.best),distance)
		if run_outcome=="clear":record.clears=int(record.clears)+1
		records[course_id]=record
		var history:Array=profile.history
		history.push_front({"course":course_id,"character":starting_character,"distance":distance,"score":core.score,"shards":shards,"handoffs":total_handoffs,"outcome":run_outcome,"seed":core.seed_value})
		profile.history=history.slice(0,12)
	elif run_outcome=="practice":profile.practice_complete=true
	if not qa:_save_profile()
	var detail: String="Your runner reached the exit. Choose another expedition or beat this run." if run_outcome=="clear" else "You practised steering, jumping, sliding, striking and your signature power." if run_outcome=="practice" else failure_detail
	ui.result_data={"distance":distance,"score":core.score,"shards":shards,"defeated":defeated,"handoffs":total_handoffs,"outcome":run_outcome,"detail":detail,"xp":progress_result.xp,"new_badges":run_badges+progress_result.new_badges,"unlocked":progress_result.ability_unlocked,"treasures":run_treasures.duplicate()}
	_open_screen("results",true)
	if qa:qa_deaths+=1;_qa_finish()


func _training_prompt() -> void:
	if training_step>=TRAINING.size():
		if guided_intro:_finish_intro(true);return
		ui.guide_title="READY FOR THE CITY";ui.guide_detail="All six controls practised. Your runner is ready.";practice_finish_left=.8;return
	ui.guide_title="%d / 6  ·  %s"%[training_step+1,TRAINING[training_step].title]
	ui.guide_detail=TRAINING[training_step].detail
	if training_step<2 and profile.settings.control_mode=="tilt" and OS.get_name()=="Android" and not tilt_warned:
		ui.guide_title="%d / 6  ·  %s"%[training_step+1,"TILT LEFT" if training_step==0 else "RETURN TO CENTRE"]
		ui.guide_detail="Tilt gently left to move across the path." if training_step==0 else "Return your phone to the comfortable holding angle from the countdown."
	if training_step==4:
		_add_row("enemy",lane,distance+(maxf(run_speed,18.5)*1.6 if guided_intro else 3.4))
		rows[-1]["guided_target" if guided_intro else "practice_target"]=true


func _training_action(action: String) -> void:
	if course_id!="training" and not guided_intro or training_step>=TRAINING.size():return
	if str(TRAINING[training_step].action)==action:
		training_step+=1
		if guided_intro:profile.intro_lessons=training_step;_save_profile()
		_sound("pickup",1.1);_training_prompt()


func _finish_intro(completed:bool) -> void:
	guided_intro=false;ui.intro_active=false;unprotected_start=distance;mastery_enemy_offset=defeated;mastery_shard_offset=shards
	ui.guide_title="";ui.guide_detail=""
	if completed:profile.practice_complete=true;profile.intro_lessons=TRAINING.size()
	else:profile.intro_dismissed=true
	for row in rows:
		row.node.queue_free()
		if int(row.id)>=0:core.retire_enemy(int(row.id))
	rows.clear();next_row=distance+48;row_index=0
	_save_profile();ui.message("YOUR RUN BEGINS",1.8)


func _apply_settings() -> void:
	Engine.max_fps = 60 if profile["settings"]["quality"] else 30
	get_viewport().msaa_3d = Viewport.MSAA_2X if profile["settings"]["quality"] else Viewport.MSAA_DISABLED
	key_light.shadow_enabled = profile["settings"]["quality"]
	world.reduced_motion=bool(profile.settings.reduced_motion)
	for actor in heroes.values():actor.reduced_motion=bool(profile.settings.reduced_motion)
	gestures.sensitivity=str(profile.settings.sensitivity)
	tilt.sensitivity=str(profile.settings.tilt_sensitivity);tilt.inverted=bool(profile.settings.tilt_invert)
	if is_instance_valid(music):
		music.volume_db = -24 if profile["settings"]["music"] else -80


func _load_profile() -> void:
	if testing:return
	for path in ["user://profile-v1.json","user://profile-v1.previous.json"]:
		if not FileAccess.file_exists(path):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and parsed.get("schema") == 1:
			var best_value = parsed.get("best",0.0)
			if (best_value is float or best_value is int) and is_finite(float(best_value)):
				profile["best"] = maxf(0,float(best_value))
			var values = parsed.get("settings",{})
			if values is Dictionary:
				for key in profile["settings"]:
					if values.get(key) is bool:
						profile["settings"][key] = values[key]
			for key in ["runs","relics"]:
				if parsed.get(key) is int or parsed.get(key) is float:profile[key]=maxi(0,int(parsed[key]))
			for key in ["route_records"]:
				if parsed.get(key) is Dictionary:profile[key]=parsed[key]
			if parsed.get("progress") is Dictionary:profile["progress"]=parsed.progress
			if parsed.get("history") is Array:profile.history=parsed.history.filter(func(item):return item is Dictionary).slice(0,12)
			if Core.CHARACTERS.has(parsed.get("selected_character","")):profile.selected_character=parsed.selected_character
			if Courses.ORDER.has(parsed.get("selected_course","")):profile.selected_course=parsed.selected_course
			if parsed.get("practice_complete") is bool:profile.practice_complete=parsed.practice_complete
			if parsed.get("intro_dismissed") is bool:profile.intro_dismissed=parsed.intro_dismissed
			if parsed.get("intro_lessons") is int or parsed.get("intro_lessons") is float:profile.intro_lessons=clampi(int(parsed.intro_lessons),0,TRAINING.size())
			if values is Dictionary:
				if values.get("control_mode") in ["tilt","thumb","swipe"]:profile.settings.control_mode="thumb" if values.control_mode=="swipe" else values.control_mode
				if values.get("tilt_sensitivity") in ["low","normal","high"]:profile.settings.tilt_sensitivity=values.tilt_sensitivity
			if values is Dictionary and values.get("sensitivity") in ["low","normal","high"]:profile.settings.sensitivity=values.sensitivity
			if int(parsed.get("controls_revision",0))<2:profile.practice_complete=false;profile.intro_dismissed=false;profile.intro_lessons=0
			break


func _save_profile(clear_backup:bool=false) -> bool:
	if testing and test_profile_root.is_empty():return true
	var root := test_profile_root if testing else OS.get_user_data_dir()
	var temporary := root+"/profile-v1.pending.json"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null:
		return false
	profile["progress"]=progression
	file.store_string(JSON.stringify(profile))
	file.flush()
	var write_error:Error=file.get_error()
	file.close()
	if write_error!=OK:return false
	if FileAccess.file_exists(root+"/profile-v1.previous.json") and DirAccess.remove_absolute(root+"/profile-v1.previous.json")!=OK:return false
	if FileAccess.file_exists(root+"/profile-v1.json"):
		if DirAccess.rename_absolute(root+"/profile-v1.json",root+"/profile-v1.previous.json")!=OK:return false
	if DirAccess.rename_absolute(root+"/profile-v1.pending.json",root+"/profile-v1.json")!=OK:
		DirAccess.rename_absolute(root+"/profile-v1.previous.json",root+"/profile-v1.json")
		return false
	if clear_backup and FileAccess.file_exists(root+"/profile-v1.previous.json"):
		return DirAccess.remove_absolute(root+"/profile-v1.previous.json")==OK
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			if ui.mode in ["game","countdown"]:_intent("pause")
			else:_intent("back")
			return
		if ui.mode!="game":return
		match event.keycode:
			KEY_LEFT,KEY_A:_move_lane(-1)
			KEY_RIGHT,KEY_D:_move_lane(1)
			KEY_UP,KEY_W:_jump()
			KEY_DOWN,KEY_S:_slide()
			KEY_SPACE:_attack()
			KEY_E:_power()
	if ui.mode!="game":return
	var action: String=gestures.feed(event,get_viewport().get_visible_rect().size.x,clock)
	match action:
		"left":_attack(-1)
		"right":_attack(1)
		"jump":_jump()
		"slide":_slide()


func _gesture(direction: Vector2) -> void:
	if direction.length()<30:return
	if absf(direction.x)>absf(direction.y):_attack(1 if direction.x>0 else -1)
	elif direction.y<0:_jump()
	else:_slide()


func _move_lane(direction: int) -> void:
	if ui.mode!="game" or core.phase in ["handoff","committed","failed","completed"]:return
	manual_steering=false
	var next_lane:=clampi(lane+direction,0,2)
	if next_lane==lane:return
	lane_from=motor.position.x;lane_elapsed=0;lane=next_lane
	_training_action("left" if direction<0 else "right")


func _notification(what: int) -> void:
	if not is_instance_valid(ui):return
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT] and not qa and ui.mode in ["game","countdown"]:_intent("pause")
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST:
		if ui.mode in ["game","countdown"]:_intent("pause")
		elif ui.mode in ["home","opening"]:_quit_gracefully()
		else:_intent("back")
	elif what==NOTIFICATION_WM_CLOSE_REQUEST:_quit_gracefully()


func _qa_control() -> void:
	if core.phase=="telegraph":
		var destination:int=qa_target_sequence[total_handoffs%qa_target_sequence.size()]
		if destination!=lane:_move_lane(1 if destination>lane else -1)
	var closest:Dictionary={}
	var best_distance:=24.0
	for row in rows:
		if row.resolved or row.kind in ["shard","gate","artifact","secret_gate"] or int(row.lane)!=lane:continue
		var ahead:float=float(row.at)-distance
		if ahead>0 and ahead<best_distance:closest=row;best_distance=ahead
	if closest.is_empty() and core.phase=="running":
		for row in rows:
			var ahead:float=float(row.at)-distance
			if not row.resolved and row.kind=="enemy" and ahead>12 and ahead<24:
				var target_lane:int=int(row.lane)
				if target_lane!=lane:_move_lane(1 if target_lane>lane else -1)
				break
	if closest.is_empty():return
	if closest.kind in ["enemy","drone"] and best_distance<(12 if selected=="witch" else 7):
		_attack()
	elif closest.kind in ["barrier","gap"] and best_distance<run_speed*.36 and not closest.get("qa_jumped",false):
		if motor.is_on_floor():
			if qa_use_specials and selected=="knight" and closest.kind=="barrier" and core.power_remaining(selected)==0:_power()
			else:_jump()
			closest["qa_jumped"]=true
		elif motor.position.y-ground_y<1.15 and core.phase=="running":
			_move_lane(-1 if lane>0 else 1)
	elif closest.kind=="beam" and best_distance<run_speed*.30 and not closest.get("qa_slid",false):
		_slide();closest["qa_slid"]=true
	if qa_use_specials and selected=="witch" and closest.kind=="barrier" and best_distance<7 and core.power_remaining(selected)==0:_power()


func _capture(name: String) -> void:
	if capture_dir.is_empty() or capture_busy or captures.has(name) or DisplayServer.get_name() == "headless":
		return
	capture_busy = true
	captures[name] = true
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image != null:
		image.save_png(capture_dir+"/"+name+".png")
	capture_busy = false


func _qa_finish() -> void:
	if quitting:
		return
	var report := {
		"engine":Engine.get_version_info()["string"],"ticks":qa_ticks,
		"distance_m":distance,"score":core.score,"shards":shards,"health":core.health,
		"handoffs":total_handoffs,"pairs":handoff_pairs,"deaths":qa_deaths,
		"attacks":qa_attacks,"powers":qa_powers,"damage_events":qa_damage,
		"scene_nodes":get_tree().get_node_count(),"active_rows":rows.size(),
		"active_effects":effects.size(),"captures":captures.keys(),
		"incidents":qa_incidents,"starting_character":starting_character,
		"jumps":qa_jump_count,"elevation_m":ground_y,"character_locked":core.character_locked,"peak_jump_height_m":qa_peak_height,"slides":qa_slide_count,"offscreen_character_ticks":qa_offscreen_ticks,
		"phase":core.phase,"scope":"Automated desktop/headless scene run; not an Android device test"
	}
	var file := FileAccess.open("res://tests/evidence/scene-run-"+starting_character+".json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report,"  "))
	print("SCENE_QA "+JSON.stringify(report))
	_quit_gracefully(0 if qa_deaths == 0 and qa_damage == 0 and qa_offscreen_ticks == 0 and qa_attacks > 0 and total_handoffs == 0 and selected==starting_character else 1)


func _preview_menu() -> void:
	_open_screen(preview_screen,true)
	await get_tree().create_timer(1.1).timeout
	await _capture(preview_screen+"-"+selected)
	_quit_gracefully()


func _quit_gracefully(code: int = 0) -> void:
	if quitting:
		return
	quitting = true
	if is_instance_valid(ui):
		ui.mode = "closing"
	_stop_audio()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit(code)


func _stop_audio() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for player in effect_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	sounds.clear()


func _exit_tree() -> void:
	_stop_audio()
	Geo.release_shared()
	preload("res://game/rig_motion.gd").release_shared()


func _motion_sample() -> Vector3:
	var sample:Vector3=Input.get_gravity()
	return sample if tilt.valid_sample(sample) else Input.get_accelerometer()


func _near_secret_entry(marker:float) -> bool:
	var zone:int=floori(marker/640.0) if course_id=="endless" else 0
	var entry:Dictionary=Secrets.gate(course_id,selected,zone)
	return not entry.is_empty() and absf(marker-float(entry.at))<19

func _spawn_secret_gates() -> void:
	var zone:int=floori(distance/640.0) if course_id=="endless" else 0
	for index in range(zone,zone+(2 if course_id=="endless" else 1)):
		var entry:Dictionary=Secrets.gate(course_id,selected,index)
		if entry.is_empty() or spawned_secrets.has(entry.gate_id):continue
		if float(entry.at)>distance and float(entry.at)<distance+150:
			_add_row("secret_gate",int(entry.lane),float(entry.at));rows[-1]["secret"]=entry;spawned_secrets[entry.gate_id]=true

func _try_secret_entry() -> bool:
	if not secret_state.is_empty() or guided_intro or course_id=="training" or not Progress.ability_unlocked(progression,selected):return false
	for row in rows:
		if row.kind!="secret_gate" or row.resolved:continue
		var ahead:float=float(row.at)-distance
		if ahead<1 or ahead>maxf(run_speed,18.5)*.8 or absf(motor.position.x-LANES[int(row.lane)])>.95:continue
		return _enter_secret(row.secret)
	return false

func _clear_course_rows() -> void:
	for row in rows:
		if row.kind in ["shard","artifact"]:core.retire_collectible(int(row.id))
		elif int(row.id)>=0:core.retire_enemy(int(row.id))
		row.node.queue_free()
	rows.clear()

func _enter_secret(entry:Dictionary) -> bool:
	if ui.mode!="game" or course_id=="training" or guided_intro or core.phase not in ["running","telegraph","committed"] or not secret_state.is_empty() or entry.get("hero","")!=selected or not Progress.ability_unlocked(progression,selected):return false
	if Secrets.room(str(entry.get("level","")),selected).get("id","")!=entry.get("id",""):return false
	if course_id!="endless" and entry.get("level","")!=course_id:return false
	secret_state=entry.duplicate(true);secret_state["start"]=distance;secret_state["end"]=distance+96
	_clear_course_rows();world.secret_theme=selected;world.secret_level=str(entry.level);heroes[selected].traverse()
	ui.message(str(entry.title)+"!",2.5);_sound("handoff",1.25);_pulse(heroes[selected].accent(),motor.position+Vector3(0,.2,0),2.0)
	for i in range(16):_add_row("shard",int(entry.lane) if i<5 else 1,distance+8+i*3)
	_add_row("enemy",2,distance+34);_add_row("beam",0,distance+42);_add_row("artifact",1,distance+62)
	return true

func _update_secret_route() -> void:
	if secret_state.is_empty():return
	if distance>=float(secret_state.end):
		_clear_course_rows();secret_state.clear();world.secret_theme="";world.secret_level="";next_row=distance+42;row_index=0
		ui.secret_hint="";ui.message("BACK TO THE ADVENTURE!",1.4);return
	ui.secret_hint="FOLLOW THE STARS TO THE TREASURE!" if distance<float(secret_state.start)+50 else "STEER INTO THE FLOATING TREASURE!" if not run_treasures.has(str(secret_state.id)) else "TREASURE FOUND!"

func _claim_secret_artifact() -> void:
	if secret_state.is_empty() or not Progress.ability_unlocked(progression,selected):return
	var id:String=str(secret_state.id)
	if Progress.claim_artifact(progression,id):
		run_treasures.append(id);run_badges.append_array(Progress.evaluate(progression));_save_profile()
		ui.message("TREASURE FOUND!\n"+str(secret_state.artifact),3.0);ui.impact("OOH, SHINY!",Color("ffd76d"));heroes[selected].celebrate()
	else:ui.message("TREASURE REVISITED!",1.5)
	_gain_combo();_sound("pickup",1.6);_burst(motor.position+Vector3(0,1.6,-1),Color("ffdc76"))

func _gain_combo() -> void:
	combo=mini(combo+1,999);combo_left=3.2
	if combo in [5,10,20]:ui.impact("NICE!" if combo==5 else "ON A ROLL!",Color("86f7d8"))
