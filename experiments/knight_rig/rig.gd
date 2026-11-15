extends Node3D
## Opt-in rear-view 2D articulated painting. Normal game and GLBs are untouched.
const Motion=preload("res://experiments/knight_rig/motion.gd")
var actor:Node
var viewport:SubViewport
var canvas:Node2D
var skeleton:Skeleton2D
var sprite:Sprite3D
var joints:Dictionary={}
var rest:Dictionary={}
var phase:float=0.0
var state:String="idle"
var state_time:float=0
var slide_weight:float=0
var pose_weight:float=0
var preview:bool=false
var forced_state:String=""
var foot_error:float=0
var goals:Dictionary={}

func configure(hero:Node) -> void:
	actor=hero
	# Match the old renderer's neutral physical display scale, not its bob/squash.
	scale=Vector3(actor.base_scale*1.12,actor.base_scale*.98,1.0)
	process_physics_priority=60
	viewport=SubViewport.new()
	viewport.size=Vector2i(384,448)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode=SubViewport.CLEAR_MODE_ALWAYS
	viewport.disable_3d=true
	add_child(viewport)
	canvas=Node2D.new();canvas.position=Vector2(39,40);viewport.add_child(canvas)
	skeleton=Skeleton2D.new();canvas.add_child(skeleton)
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://experiments/knight_rig/art/rig.json"))
	var atlas:Texture2D=load("res://experiments/knight_rig/art/knight_layers.png")
	for part in manifest.parts:
		var bone:=Bone2D.new()
		bone.name=part.name
		bone.set_autocalculate_length_and_angle(false)
		bone.length=24
		var joint:=Vector2(part.joint[0],part.joint[1])
		var parent:Node2D=skeleton if str(part.parent).is_empty() else joints[part.parent]
		parent.add_child(bone)
		bone.position=joint-(Vector2.ZERO if str(part.parent).is_empty() else rest[part.parent])
		bone.rest=bone.transform
		joints[part.name]=bone;rest[part.name]=joint
		var painted:=Sprite2D.new()
		var texture:=AtlasTexture.new()
		texture.atlas=atlas
		texture.region=Rect2(part.region[0],part.region[1],part.region[2],part.region[3])
		texture.filter_clip=true
		painted.texture=texture;painted.centered=false
		painted.position=Vector2(part.source_rect[0],part.source_rect[1])-joint
		painted.z_index=int(part.z);painted.z_as_relative=false
		bone.add_child(painted)
	sprite=Sprite3D.new()
	sprite.texture=viewport.get_texture()
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded=false;sprite.double_sided=true
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.pixel_size=actor.concept_sprite_height/361.0
	sprite.position.y=(351.0+40.0-224.0)*sprite.pixel_size
	sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite)
	pose(0.0,"idle",true)

func choose_state() -> String:
	if not forced_state.is_empty():return forced_state
	if actor.defeated:return "defeat"
	if actor.celebration_left>0:return "victory"
	if actor.hurt_left>0:return "damage"
	if actor.sliding:return "slide"
	if actor.airborne:return "jump" if actor.airborne_velocity>0 else "fall"
	if actor.attack_time>0:return "attack"
	if actor.power_time>0:return "power"
	if actor.landing_spring>.005:return "land"
	return "run" if actor.moving else "idle"

func _physics_process(delta:float) -> void:
	if not is_instance_valid(actor) or not visible or preview:return
	var next:String=choose_state()
	# Suppress a one-tick contact-state flicker in the *presentation*, never physics.
	if state=="slide" and next=="fall" and state_time<.16:next="slide"
	state_time=state_time+delta if next==state else 0.0
	state=next
	var rate:float=clampf(actor.motion.locomotion_rate,.6,1.65)
	phase+=delta*TAU*Motion.RUN_HZ*rate
	pose(delta,state)

func pose(delta:float,action:String,immediate:bool=false) -> void:
	state=action
	var weight:float=1.0 if immediate else 1.0-exp(-delta*22.0)
	var energy:float=1.0 if action in ["run","attack","damage","power"] else .12
	if is_instance_valid(actor) and actor.reduced_motion:energy=0.0
	var target:Dictionary=Motion.angles(phase,action,energy)
	var crouch:float=70.0 if action=="slide" else 10.0 if action=="land" else 0.0
	if action=="defeat":crouch=28.0
	joints.pelvis.position=rest.pelvis+Vector2(0,lerpf(joints.pelvis.position.y-rest.pelvis.y,crouch,weight))
	joints.torso.position.y=lerpf(joints.torso.position.y,rest.torso.y-rest.pelvis.y+(35.0 if action=="slide" else 0.0),weight)
	joints.torso.scale.y=lerpf(joints.torso.scale.y,.86 if action=="slide" else 1.0,weight)
	if is_instance_valid(actor) and not preview:
		target.torso+=-actor.lean*.12
		target.head+=actor.lean*.06
	for name in target:
		joints[name].rotation=lerp_angle(joints[name].rotation,float(target[name]),weight)
	for side in ["l","r"]:
		var right:bool=side=="r"
		var hip:Bone2D=joints["thigh_"+side]
		var knee:Bone2D=joints["shin_"+side]
		var ankle:Bone2D=joints["boot_"+side]
		var hip_rest:Vector2=rest["thigh_"+side]
		var knee_rest:Vector2=rest["shin_"+side]
		var ankle_rest:Vector2=rest["boot_"+side]
		var goal:Vector2=Motion.foot(phase,right) if energy>.5 else ankle_rest
		if action in ["jump","fall"]:
			goal+=Vector2(-5 if right else 5,-22 if right else -32)
		if not goals.has(side):goals[side]=goal
		goals[side]=goal if immediate or action in ["run","attack","damage","power"] else (goals[side] as Vector2).lerp(goal,weight)
		goal=goals[side]
		var pelvis_delta:Vector2=joints.pelvis.position-rest.pelvis
		var projected_knee:Vector2=Motion.projected_knee(knee_rest,ankle_rest,goal,pelvis_delta.y,right)
		# Native bone transforms solve projected rear-view chains; only limb
		# length foreshortens. Feet stay level and do not inherit shin shear.
		hip.global_transform=canvas.global_transform*Motion.segment(hip_rest+pelvis_delta,projected_knee,knee_rest-hip_rest)
		knee.global_transform=canvas.global_transform*Motion.segment(projected_knee,goal,ankle_rest-knee_rest)
		ankle.global_transform=canvas.global_transform*Transform2D(0,goal)
		var actual:Vector2=canvas.to_local(ankle.global_position)
		foot_error=maxf(foot_error,actual.distance_to(goal))

func metrics() -> Dictionary:
	return {"parts":joints.size(),"native_skeleton":skeleton is Skeleton2D,"max_ik_error_px":foot_error,
		"phase":phase,"state":state,"whole_image_crossfades":false,
		"scope":"Rear view only; original painted pixels; rigid layered 2D bones; no unseen surfaces invented."}
