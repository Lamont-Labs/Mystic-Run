extends Node3D
## Standalone review project. It never reads or writes MysticRun save data.

var catalog:Array=[]
var index:int=0
var holder:Node3D
var camera:Camera3D
var caption:Label
var automatic:bool=false
var output:String=""
var capture_files:Array[String]=[]
var spin:bool=false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):output=arg.trim_prefix("--capture-dir=");automatic=true
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://asset_catalog.json"))["assets"]
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("101c31")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("b6cde4");env.ambient_light_energy=.34
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;add_child(world)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,-35,0);key.light_color=Color("ffe1b7");key.light_energy=.65;key.shadow_enabled=true;add_child(key)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-22,145,0);fill.light_color=Color("8ebcf0");fill.light_energy=.3;add_child(fill)
	var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(200,200);floor.mesh=plane
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("26334a");mat.roughness=.83;floor.material_override=mat;floor.position.y=-.015;add_child(floor)
	camera=Camera3D.new();camera.fov=32;camera.near=.01;add_child(camera)
	var canvas:=CanvasLayer.new();add_child(canvas)
	caption=Label.new();caption.position=Vector2(38,30);caption.add_theme_font_size_override("font_size",22);caption.add_theme_color_override("font_color",Color("e7e1d6"));canvas.add_child(caption)
	var footer:=Label.new();footer.position=Vector2(38,908);footer.add_theme_font_size_override("font_size",16);footer.text="LAMONT LABS  /  MYSTICRUN     •     3D ASSET REVIEW 01";footer.modulate=Color("99b5cd");canvas.add_child(footer)
	show_asset(0)
	if automatic:call_deferred("capture_batch")

func bounds_of(node:Node3D) -> AABB:
	var result:=AABB();var first:bool=true
	var all:Array[Node]=[node];all.append_array(node.find_children("*","MeshInstance3D",true,false))
	for item in all:
		if item is MeshInstance3D:
			var box:AABB=holder.global_transform.affine_inverse()*item.global_transform*item.get_aabb()
			result=box if first else result.merge(box);first=false
	return result

func show_asset(next:int) -> void:
	index=posmod(next,catalog.size())
	if is_instance_valid(holder):holder.free()
	holder=Node3D.new();add_child(holder)
	var model:Node3D=load("res://"+str(catalog[index]["path"])).instantiate();holder.add_child(model)
	if str(catalog[index]["path"]).begins_with("assets/original/"):
		# The GLBs carry real COLOR_0 paint. Enable it explicitly on every
		# imported surface, including Godot's first non-metal material.
		var painted:Array[Node]=[model];painted.append_array(model.find_children("*","MeshInstance3D",true,false))
		for item in painted:
			if item is MeshInstance3D:
				for surface in range(item.mesh.get_surface_count()):
					var material:StandardMaterial3D=item.mesh.surface_get_material(surface).duplicate()
					material.vertex_color_use_as_albedo=true
					item.set_surface_override_material(surface,material)
	var box:=bounds_of(model)
	assert(box.size.is_finite() and box.size.length()>.001,"Invalid imported bounds")
	# Asset-space normalization applies only in the viewer, never to source bytes.
	var factor:float=3.15/maxf(box.size.y,maxf(box.size.x,box.size.z))
	model.scale*=factor
	model.position-=Vector3(box.get_center().x,box.position.y,box.get_center().z)*factor
	var height:float=box.size.y*factor
	camera.position=Vector3(3.6,2.8,7.2);camera.look_at(Vector3(0,height*.49,0))
	caption.text=str(catalog[index]["label"])+"\n"+str(catalog[index]["publisher"]).to_upper()
	caption.text+="  /  "+str(int(catalog[index]["triangles"]))+" TRIANGLES"
	if not automatic:caption.text+="\n← → Change asset     Space Rotate     Esc Close"

func capture_batch() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	for i in range(catalog.size()):
		show_asset(i)
		for view in ["front","rear"]:
			holder.rotation.y=0.0 if view=="front" else PI
			for frame in range(4):await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var name:String=str(catalog[i]["id"])+"-"+view+".png"
			var code:int=get_viewport().get_texture().get_image().save_png(output.path_join(name))
			assert(code==OK,"Capture failed: "+name);capture_files.append(name)
	var receipt:=FileAccess.open(output.path_join("render_receipt.json"),FileAccess.WRITE)
	receipt.store_string(JSON.stringify({"engine":Engine.get_version_info()["string"],"renderer":"GL Compatibility","assets":catalog.size(),"views":capture_files.size(),"files":capture_files,"scope":"Actual imported GLB candidates in a desktop review stage; no gameplay integration or phone-performance claim"},"\t"));receipt.close()
	print("ASSET_REVIEW_PASS ",catalog.size()," assets / ",capture_files.size()," views")
	get_tree().quit()

func _unhandled_key_input(event:InputEvent) -> void:
	if not event.is_pressed() or automatic:return
	if event.is_action_pressed("ui_right"):show_asset(index+1)
	if event.is_action_pressed("ui_left"):show_asset(index-1)
	if event.is_action_pressed("ui_accept"):spin=not spin
	if event.is_action_pressed("ui_cancel"):get_tree().quit()

func _process(delta:float) -> void:
	if spin and is_instance_valid(holder):holder.rotation.y+=delta*.4
