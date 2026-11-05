extends SceneTree
## Uses the actual gameplay actor and rig; no owner-save writes.
var actor:Node3D
var camera:Camera3D
var output:String
var identity:String="gargoyle"
var finish_strength:float=1.0
func _initialize() -> void:call_deferred("run")
func run() -> void:
	output="res://docs/previews/characters"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):output=argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--character="):identity=argument.trim_prefix("--character=")
		if argument.begins_with("--finish-strength="):finish_strength=clampf(float(argument.get_slice("=",1)),0.0,1.0)
	DirAccess.make_dir_recursive_absolute(output)
	var stage:=Node3D.new();root.add_child(stage)
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("dcd9ea")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("dbe9ff");env.ambient_light_energy=.30
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;stage.add_child(world)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,-30,0);key.light_energy=.45;key.shadow_enabled=true;stage.add_child(key)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,145,0);fill.light_color=Color("b6d5ff");fill.light_energy=.18;stage.add_child(fill)
	var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(30,30);floor.mesh=plane
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("bab6ce");mat.roughness=1;floor.material_override=mat;stage.add_child(floor)
	actor=load("res://game/hero.gd").new();actor.configure(identity);stage.add_child(actor)
	actor.authored_mesh.material_override.set_shader_parameter("finish_strength",finish_strength)
	actor.facing=0;actor.body.rotation.y=0;actor.reduced_motion=true
	camera=Camera3D.new();camera.fov=36;camera.near=.05;stage.add_child(camera)
	for frame in range(30):actor.animate(1.0/60);await process_frame
	for view in ["front","rear","side"]:
		camera.position={"front":Vector3(2.0,2.0,6.5),"rear":Vector3(-2.0,2.0,-6.5),"side":Vector3(6.5,2,.3)}[view]
		camera.look_at(Vector3(0,1.22,0));await capture(view)
	actor.moving=true;camera.position=Vector3(2.3,2.1,5.5);camera.look_at(Vector3(0,1.22,0))
	for action in ["run","attack","jump","slide","celebrate"]:
		actor.sliding=action=="slide";actor.airborne=action=="jump"
		camera.position=Vector3(2.8,2.2,7.0) if action=="jump" else Vector3(2.3,2.1,5.5)
		camera.look_at(Vector3(0,1.22,0))
		if action=="attack":actor.attack()
		if action=="celebrate":actor.moving=false;actor.celebrate()
		for frame in range(18):actor.animate(1.0/60);await process_frame
		await capture(action)
	actor.sliding=false;actor.airborne=false;actor.moving=false
	camera.position=Vector3(.80,2.08,3.2);camera.look_at(Vector3(0,1.86,.03))
	for expression in ["neutral","pleased","determined","surprised","hurt"]:
		actor.set_expression(expression)
		for frame in range(35):actor.animate(1.0/60);await process_frame
		await capture("face-"+expression)
	actor.queue_free();await process_frame;load("res://game/rig_motion.gd").release_shared();quit()
func capture(label:String) -> void:
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	var code:int=root.get_texture().get_image().save_png(output.path_join(identity+"-"+label+".png"))
	if code!=OK:push_error("Character capture failed: "+label);quit(1)
