extends SceneTree
## Captures the actual imported character and animations, without owner save writes.
var hero:Node3D
var camera:Camera3D
var output:String
func _initialize() -> void:call_deferred("run")
func run() -> void:
	output="res://docs/previews/knight"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):output=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(output)
	var scene:=Node3D.new();root.add_child(scene)
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("dcd9ea")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("dbe9ff");env.ambient_light_energy=.30
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;scene.add_child(world)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,-30,0);key.light_energy=.45;key.shadow_enabled=true;scene.add_child(key)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,145,0);fill.light_color=Color("b6d5ff");fill.light_energy=.18;scene.add_child(fill)
	var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(30,30);floor.mesh=plane
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("bab6ce");mat.roughness=1;floor.material_override=mat;scene.add_child(floor)
	hero=load("res://game/hero.gd").new();hero.configure("knight");scene.add_child(hero)
	hero.facing=0;hero.body.rotation.y=0
	camera=Camera3D.new();camera.fov=35;camera.near=.05;scene.add_child(camera)
	for i in range(15):hero.animate(1.0/60);await process_frame
	for view in ["front","rear","side"]:
		camera.position={"front":Vector3(2.0,1.9,4.5),"rear":Vector3(-2.0,1.9,-4.5),"side":Vector3(4.5,1.8,.3)}[view]
		camera.look_at(Vector3(0,1.12,0));await capture(view)
	hero.moving=true;camera.position=Vector3(2.8,1.9,4.3);camera.look_at(Vector3(0,1.12,0))
	for action in ["run","attack","jump","slide","celebrate"]:
		hero.sliding=action=="slide";hero.airborne=action=="jump"
		if action=="attack":hero.attack()
		if action=="celebrate":hero.moving=false;hero.celebrate()
		for i in range(12):hero.animate(1.0/60);await process_frame
		await capture(action)
	hero.queue_free();await process_frame
	load("res://game/rig_motion.gd").release_shared();quit()
func capture(label:String) -> void:
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	var result:int=root.get_texture().get_image().save_png(output.path_join("knight-"+label+".png"))
	if result!=OK:push_error("Knight capture failed: "+label);quit(1)
