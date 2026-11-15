extends SceneTree
## Actual transparent SubViewport renders of the native rig, not offline mockups.
class Actor extends Node:
	var concept_sprite_height:float=2.15
	var reduced_motion:bool=false
	var base_scale:float=1.08

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var out:String="generated-artifacts/knight-rig/poses"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):out=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(out)
	var actor:=Actor.new();root.add_child(actor)
	var rig:Node3D=load("res://experiments/knight_rig/rig.gd").new()
	rig.preview=true;root.add_child(rig);rig.configure(actor)
	for i in range(16):
		rig.phase=TAU*i/16.0;rig.pose(0.0,"run",true)
		await RenderingServer.frame_post_draw
		rig.viewport.get_texture().get_image().save_png(out.path_join("run-%02d.png"%i))
	for action in ["idle","jump","fall","land","slide","attack","damage","power","victory","defeat"]:
		rig.pose(0.0,action,true)
		await RenderingServer.frame_post_draw
		rig.viewport.get_texture().get_image().save_png(out.path_join(action+".png"))
	FileAccess.open(out.path_join("metrics.json"),FileAccess.WRITE).store_string(JSON.stringify(rig.metrics(),"  "))
	quit()
