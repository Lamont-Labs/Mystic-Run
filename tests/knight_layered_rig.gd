extends SceneTree
## Tests the native Skeleton2D and authored IK independently from game physics.
const Motion=preload("res://experiments/knight_rig/motion.gd")
var checks:int=0
var failures:int=0
class Actor extends Node:
	var concept_sprite_height:float=2.15
	var reduced_motion:bool=false
	var base_scale:float=1.08

func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: ",message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var actor:=Actor.new();root.add_child(actor)
	var rig:Node3D=load("res://experiments/knight_rig/rig.gd").new()
	rig.preview=true;root.add_child(rig);rig.configure(actor)
	check(rig.joints.size()==14,"14 painted parts have native Bone2D joints")
	check(rig.skeleton is Skeleton2D,"The rig uses a native Skeleton2D")
	check(rig.joints.sword.get_parent()==rig.joints.forearm_r,"Sword inherits wrist and arm motion")
	check(rig.joints.boot_l.get_parent()==rig.joints.shin_l,"Foot follows the knee/hip chain")
	var samples:Array[float]=[]
	for frame in range(160):
		rig.phase=TAU*frame/160.0
		rig.pose(1.0/60.0,"run",true)
		var ankle:Vector2=rig.canvas.to_local(rig.joints.boot_l.global_position)
		var expected:Vector2=Motion.foot(rig.phase,false)
		check(ankle.distance_to(expected)<.05,"Left ankle matches IK goal")
		ankle=rig.canvas.to_local(rig.joints.boot_r.global_position)
		expected=Motion.foot(rig.phase,true)
		check(ankle.distance_to(expected)<.05,"Right ankle matches IK goal")
		samples.append(rig.canvas.to_local(rig.joints.shin_l.global_position).y)
	check(absf(samples.max()-samples.min())>8,"Rear-view knee lifts rather than bending sideways")
	var standing_top:Vector2=rig.canvas.to_local(rig.joints.head.to_global(Vector2(0,-77)))
	rig.pose(1.0/60.0,"slide",true)
	var crouched_top:Vector2=rig.canvas.to_local(rig.joints.head.to_global(Vector2(0,-77)))
	check(crouched_top.y-standing_top.y>80,"Crouch lowers the helmet without scaling the full painting")
	for action in ["idle","jump","fall","land","slide","attack","damage","power","victory","defeat"]:
		rig.pose(1.0/60.0,action,true)
		for joint in rig.joints.values():
			check(is_finite(joint.rotation),"Action rotations remain finite")
	rig.pose(1.0/60.0,"run",true)
	var before:float=rig.joints.upperarm_r.rotation
	rig.pose(1.0/60.0,"attack")
	check(absf(rig.joints.upperarm_r.rotation-before)<.4,"Strike blends joint angles rather than snapping")
	check(rig.sprite.texture is ViewportTexture,"The game billboard displays real rendered native joints")
	print("KNIGHT_LAYERED_RIG: ",checks-failures,"/",checks," passed; max IK error ",rig.foot_error," px")
	quit(1 if failures else 0)
