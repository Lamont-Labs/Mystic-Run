extends Node
## Actual-game architecture harness. Baseline runs against an untouched checkout;
## only this measurement harness is copied into it. No owner profile is loaded.
var game:Node
var root:Window:
	get:return get_tree().root
var mode:String="interactive"
var variant:String="prototype"
var renderer:String="cutout"
var hero_name:String="knight"
var out:String=""
var duration:float=7.0
var elapsed:float=0
var started:bool=false
var next_event:int=0
var camera_rig:Node
var castle:Node3D
var frame_ms:Array[float]=[]
var animation_us:Array[float]=[]
var pending:Array[Dictionary]=[]
var responses:Array[Dictionary]=[]
var transitions:Array[Dictionary]=[]
var last_state:String=""
var last_us:int=0
var initial_health:int=3
var overlap_ticks:int=0
var max_height:float=0
var max_width:float=0
var captures:int=0
var clock_frame:int=0
var overlay:Label
var events:Array[Dictionary]=[
	{"at":.35,"action":"pad_right"},{"at":.55,"action":"pad_release"},
	{"at":1.0,"action":"left"},{"at":1.3,"action":"left"},{"at":1.35,"action":"right"},
	{"at":2.0,"action":"jump"},{"at":2.4,"action":"slide"},
	{"at":3.1,"action":"up_down"},{"at":3.8,"action":"down_up"},
	{"at":4.5,"action":"attack"},{"at":5.4,"action":"jump"},{"at":5.7,"action":"slide"}
]

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lab-mode="):mode=arg.get_slice("=",1)
		if arg.begins_with("--lab-variant="):variant=arg.get_slice("=",1)
		if arg.begins_with("--lab-renderer="):renderer=arg.get_slice("=",1)
		if arg.begins_with("--lab-hero="):hero_name=arg.get_slice("=",1)
		if arg.begins_with("--lab-duration="):duration=float(arg.get_slice("=",1))
		if arg.begins_with("--lab-output="):out=arg.trim_prefix("--lab-output=")
	call_deferred("run")

func _model(hero:Node) -> Node3D:
	for node in hero.body.get_children():
		if node.is_ancestor_of(hero.skeleton):return node
	return null

func set_renderer(value:String) -> void:
	renderer=value
	var hero:Node=game.heroes[hero_name]
	var model:Node3D=_model(hero)
	# Equal physical display height, rather than comparing the small cutout
	# against an arbitrarily larger legacy mesh. Art/rig records stay untouched.
	var box:AABB=(hero.body.global_transform.affine_inverse()*hero.authored_mesh.global_transform)*hero.authored_mesh.get_aabb()
	var texture:Texture2D=hero.concept_sprite.texture
	var used:Rect2i=texture.get_image().get_used_rect()
	var desired_height:float=hero.concept_sprite_height*float(used.size.y)/texture.get_height()
	var factor:float=desired_height/maxf(box.size.y,.01)
	model.scale*=factor
	model.position.y-=box.position.y*factor
	model.visible=renderer=="skeletal"
	hero.motion_art.visible=renderer=="cutout"
	if variant=="prototype":
		hero.evaluate_rig=renderer=="skeletal"
		hero.evaluate_cutout=renderer=="cutout"
	hero.motion.attack_clock=99;hero.motion.power_clock=99

func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	game.testing=true;game.profile.practice_complete=true;game.profile.settings.control_mode="thumb"
	root.add_child(game)
	for i in range(5):await get_tree().physics_frame
	game._select_character(hero_name);game.qa=true;game._start_run();game.qa=false
	game._clear_course_rows();game.next_row=1e9
	game.ui.guide_title="";game.ui.guide_detail=""
	set_renderer(renderer)
	if variant=="prototype":
		camera_rig=load("res://experiments/architecture_validation/camera_rig.gd").new()
		camera_rig.game=game;root.add_child(camera_rig)
		castle=load("res://experiments/architecture_validation/castle_segment.gd").new()
		root.add_child(castle);castle.configure(game)
	var layer:=CanvasLayer.new();root.add_child(layer)
	overlay=Label.new();layer.add_child(overlay)
	overlay.position=Vector2(16,96);overlay.add_theme_font_size_override("font_size",17)
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.visible=mode!="benchmark"
	if not out.is_empty():DirAccess.make_dir_recursive_absolute(out)
	get_tree().physics_frame.connect(step)
	last_us=Time.get_ticks_usec();started=true

func _process(_delta:float) -> void:
	if not started:return
	var now:int=Time.get_ticks_usec()
	if elapsed>.8 and mode=="benchmark":frame_ms.append(float(now-last_us)/1000.0)
	last_us=now
	if is_instance_valid(overlay):
		overlay.text="%s · %s · %s\nR: renderer · arrows: lanes/jump/slide · Space: attack\nScripted review" % [variant.to_upper(),renderer.to_upper(),hero_name.to_upper()] if mode!="interactive" else "%s · %s · %s\nR: renderer · arrows: lanes/jump/slide · Space: attack\nEsc: normal pause · owner saves untouched"%[variant.to_upper(),renderer.to_upper(),hero_name.to_upper()]
	if mode=="interactive" and Input.is_physical_key_pressed(KEY_R) and not root.has_meta("renderer_key"):
		root.set_meta("renderer_key",true);set_renderer("skeletal" if renderer=="cutout" else "cutout")
	if not Input.is_physical_key_pressed(KEY_R) and root.has_meta("renderer_key"):root.remove_meta("renderer_key")

func touch(at:Vector2,pressed:bool,id:int=11) -> void:
	var e:=InputEventScreenTouch.new();e.index=id;e.position=at;e.pressed=pressed
	root.push_input(e,true)

func swipe(offset:Vector2) -> void:
	var origin:Vector2=game.ui.size*Vector2(.52,.56)
	touch(origin,true,12)
	var e:=InputEventScreenDrag.new();e.index=12;e.position=origin+offset;e.relative=offset
	root.push_input(e,true);touch(origin+offset,false,12)

func perform(action:String) -> void:
	var pad:Control=game.ui.thumb_pad
	var at:Vector2=pad.get_global_transform_with_canvas()*(pad.size*Vector2(.95,.5))
	var expected_x:float=game.motor.position.x
	match action:
		"pad_right":touch(at,true)
		"pad_release":
			expected_x=float(game.LANES[game.lane])
			touch(at,false)
		"left","right":
			var e:=InputEventKey.new();e.pressed=true;e.keycode=KEY_LEFT if action=="left" else KEY_RIGHT
			root.push_input(e,true)
		"jump":
			swipe(Vector2(0,-100))
			if elapsed<3:game._add_row("barrier",game.lane,game.distance+6.3)
		"slide":
			swipe(Vector2(0,100))
			if elapsed<3:game._add_row("beam",game.lane,game.distance+7.5)
		"up_down":swipe(Vector2(0,-100));swipe(Vector2(0,100))
		"down_up":swipe(Vector2(0,100));swipe(Vector2(0,-100))
		"attack":
			game._add_row("enemy",game.lane,game.distance+7.0)
			swipe(Vector2(100,0))
	pending.append({"action":action,"tick":game.core.tick,"us":Time.get_ticks_usec(),"x":game.motor.position.x,"expected_x":expected_x})

func step() -> void:
	if not started:return
	elapsed=game.run_seconds
	var hero:Node=game.heroes[hero_name]
	var state:String=("jump" if hero.airborne_velocity>0 else "fall") if hero.airborne else "slide" if hero.sliding else "land" if hero.landing_spring>0 else "attack" if hero.attack_time>0 else "run"
	if state!=last_state:
		transitions.append({"seconds":elapsed,"state":state,"y":game.motor.position.y-game.ground_y})
		last_state=state
	if hero.airborne and hero.sliding:overlap_ticks+=1
	_measure_bounds(hero)
	for i in range(pending.size()-1,-1,-1):
		var p:Dictionary=pending[i]
		var observed:bool=false
		match str(p.action):
			"pad_right","left","right":observed=absf(game.motor.position.x-float(p.x))>.001
			"pad_release":observed=absf(game.motor.position.x-float(p.expected_x))<.04
			"jump","down_up":observed=game.motor.velocity.y>1 and not hero.sliding
			"slide","up_down":observed=game.sliding_left>0 and game.motor.position.y-game.ground_y<.08
			"attack":observed=hero.attack_time>0
		var ms:float=(game.core.tick-int(p.tick))*1000.0/60.0
		if observed or ms>=500:
			responses.append({"action":p.action,"observed":observed,"simulation_ms":ms,"wall_ms":(Time.get_ticks_usec()-int(p.us))/1000.0})
			pending.remove_at(i)
	if mode!="interactive":
		while next_event<events.size() and elapsed>=float(events[next_event].at):
			perform(str(events[next_event].action));next_event+=1
		if mode=="capture" and clock_frame%3==0:
			game._capture("lab-%04d"%captures);captures+=1
		clock_frame+=1
		if elapsed>=duration:
			started=false;finish.call_deferred()

func _measure_bounds(hero:Node) -> void:
	# Conservative cutout-quad projection, not a pixel-occlusion measurement.
	var art:Node3D=hero.motion_art
	var scale:Vector3=art.global_transform.basis.get_scale()
	var at:Vector3=art.global_position
	var up:Vector3=game.camera.global_basis.y*absf(scale.y)*.5
	var right:Vector3=game.camera.global_basis.x*absf(scale.x)*.5
	var a:Vector2=game.camera.unproject_position(at-up-right)
	var b:Vector2=game.camera.unproject_position(at+up+right)
	var viewport:Vector2=root.get_visible_rect().size
	max_height=maxf(max_height,absf(a.y-b.y)/viewport.y)
	max_width=maxf(max_width,absf(a.x-b.x)/viewport.x)

func stats(values:Array[float]) -> Dictionary:
	if values.is_empty():return {}
	var v:Array[float]=values.duplicate();v.sort()
	var mean:float=0
	for item in v:mean+=item
	mean/=v.size()
	return {"samples":v.size(),"mean":mean,"p50":v[int((v.size()-1)*.5)],"p95":v[int((v.size()-1)*.95)],"p99":v[int((v.size()-1)*.99)],"worst":v[-1]}

func finish() -> void:
	var hero:Node=game.heroes[hero_name]
	for i in range(90):
		var before:int=Time.get_ticks_usec()
		hero.animate(1.0/60.0)
		animation_us.append(float(Time.get_ticks_usec()-before))
	var frame:Dictionary=stats(frame_ms)
	var report:Dictionary={"variant":variant,"renderer":renderer,"hero":hero_name,"mode":mode,"frame_interval_ms":frame,"animation_microbenchmark_us":stats(animation_us),"inputs":responses,"transitions":transitions,"air_slide_overlap_ticks":overlap_ticks,"quad_max_height_fraction":max_height,"quad_max_width_fraction":max_width,"distance_m":game.distance,"health":game.core.health,"character_height_setting":hero.concept_sprite_height,"scope":"Rendered Linux llvmpipe/Xvfb; injected input-to-simulation response, not physical touch latency. Fixed-rate captures are not FPS benchmarks. Quad bounds include transparency; not pixel occlusion. Animation CPU cost is a separate synthetic 90-call microbenchmark."}
	if not frame.is_empty():report["mean_fps"]=1000.0/float(frame.mean)
	if not out.is_empty():
		FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("ARCHITECTURE_REVIEW ",JSON.stringify(report))
	game._quit_gracefully(0)
