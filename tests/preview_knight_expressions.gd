extends SceneTree
## Actual close-up stage for model/expression review, without owner saves.
var output:String=""
var actor:Node3D
func _initialize() -> void:call_deferred("run")
func run() -> void:
	output="res://docs/previews/knight-expressions"
	var hold:int=18
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):output=argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--preview-frames="):hold=maxi(18,int(argument.get_slice("=",1))/6)
	DirAccess.make_dir_recursive_absolute(output)
	var stage:=Node3D.new();root.add_child(stage)
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("dcd9ea")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("dbe9ff");env.ambient_light_energy=.30
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;stage.add_child(world)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,-30,0);key.light_energy=.45;key.shadow_enabled=true;stage.add_child(key)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,145,0);fill.light_color=Color("b6d5ff");fill.light_energy=.18;stage.add_child(fill)
	actor=load("res://game/hero.gd").new();actor.configure("knight");stage.add_child(actor)
	actor.facing=0;actor.body.rotation.y=0;actor.reduced_motion=true
	var camera:=Camera3D.new();camera.fov=29;camera.near=.05;stage.add_child(camera)
	camera.position=Vector3(.72,1.95,2.8);camera.look_at(Vector3(0,1.71,.04))
	var label:=Label.new();label.text="MYSTICRUN · KNIGHT REFINEMENT";label.position=Vector2(22,24);label.add_theme_color_override("font_color",Color("363354"));label.add_theme_font_size_override("font_size",21);root.add_child(label)
	var expression_label:=Label.new();expression_label.position=Vector2(22,62);expression_label.add_theme_color_override("font_color",Color("363354"));expression_label.add_theme_font_size_override("font_size",31);root.add_child(expression_label)
	var note:=Label.new();note.text="ACTUAL GODOT MODEL · DEVELOPMENT PASS";note.position=Vector2(22,root.get_visible_rect().size.y-48);note.add_theme_color_override("font_color",Color("363354"));note.add_theme_font_size_override("font_size",17);root.add_child(note)
	for expression in ["neutral","alert","pleased","determined","surprised","hurt"]:
		expression_label.text=expression.to_upper();actor.set_expression(expression)
		for frame in range(hold):
			actor.animate(1.0/30);await process_frame
			if frame==hold-1:
				await RenderingServer.frame_post_draw
				var result:int=root.get_texture().get_image().save_png(output.path_join(expression+".png"))
				if result!=OK:push_error("Expression capture failed");quit(1);return
	actor.queue_free();await process_frame
	load("res://game/rig_motion.gd").release_shared();quit()
