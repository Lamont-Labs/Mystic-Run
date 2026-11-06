extends Node3D

const Geo = preload("res://game/geometry.gd")
const Motion = preload("res://game/rig_motion.gd")
const OUTLINE = preload("res://assets/shaders/ink_outline.gdshader")
const AUTHORED_SHADER = preload("res://assets/shaders/authored_character.gdshader")
const FINISH_DETAIL = preload("res://assets/characters/finish-detail.png")
var identity: String = "knight"
var body: Node3D
var skeleton: Skeleton3D
var motion: RefCounted
var cape: Node3D
var clock: float = 0.0
var attack_time: float = 0.0
var power_time: float = 0.0
var sliding: bool = false
var airborne: bool = false
var moving: bool = false
var lean: float = 0.0
var threat_intensity:float=0.0
var facing:float=PI
var reduced_motion:bool=false
var base_scale:float=1.08
var swipe_direction:int=1
var celebration_left:float=0
var traversal_left:float=0
var mats: Dictionary = {}
var was_airborne:bool=false
var landing_spring:float=0.0
var cape_fabric:ShaderMaterial
var authored_mesh:MeshInstance3D
var blink_clock:float=0.0
var face_shapes:Dictionary={}
var face_weights:Dictionary={"Smile":0.0,"Focus":0.0,"Surprised":0.0,"Hurt":0.0}
var expression_override:String="auto"
var facial_state:String="neutral"
var hurt_left:float=0.0
var wing_controls:Array[Dictionary]=[]
var creature_tuck:float=0.0
var braid_controls:Array[Dictionary]=[]
var staff_control:Dictionary={}

func configure(kind: String) -> void:
	identity=kind
	_build()

func accent() -> Color:
	return {"knight":Color("5de9f2"),"gargoyle":Color("60e3bd"),"witch":Color("ba83ff")}[identity]

func _paint(color: String, metal: float=0.0, emission: float=0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color(color)
	mat.diffuse_mode=BaseMaterial3D.DIFFUSE_BURLEY
	mat.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
	mat.metallic=metal*.25
	mat.roughness=0.46 if metal>0.4 else 0.72
	if emission>0:
		mat.emission_enabled=true
		mat.emission=Color(color)
		mat.emission_energy_multiplier=emission
	else:
		var outline := ShaderMaterial.new()
		outline.shader=OUTLINE
		mat.next_pass=outline
	return mat

func _attachment(bone: String) -> Node3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name=bone
	skeleton.add_child(attachment)
	var coordinates := Node3D.new()
	coordinates.transform=skeleton.get_bone_global_rest(skeleton.find_bone(bone)).affine_inverse()
	attachment.add_child(coordinates)
	return coordinates

func _add(geometry: RefCounted, bone: String) -> Node3D:
	var result: Node3D=geometry.build()
	_attachment(bone).add_child(result)
	return result

func _build() -> void:
	mats={"steel":_paint("38a8ed",0.40),"edge":_paint("eefaff",0.32),"dark":_paint("264586",0.20),"gold":_paint("ffd45a",0.38),"cloth":_paint({"knight":"ff775b","gargoyle":"b176e6","witch":"9554ce"}[identity]),"stone":_paint("57c9b7" if identity=="gargoyle" else "a4d8ed"),"glow":_paint("b2ffff",0.25,.65)}
	body=Node3D.new()
	body.rotation.y=PI
	base_scale=1.12 if identity=="gargoyle" else 1.08
	body.scale=Vector3.ONE*base_scale
	add_child(body)
	var model_path:String="res://assets/characters/"+identity+"/"+identity+".glb"
	var model: Node3D=(load(model_path) as PackedScene).instantiate()
	body.add_child(model)
	skeleton=model.find_child("Skeleton3D",true,false)
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			authored_mesh=child
			for shape_index in range(child.mesh.get_blend_shape_count()):
				face_shapes[str(child.mesh.get_blend_shape_name(shape_index))]=shape_index
			var authored_material:=ShaderMaterial.new()
			authored_material.shader=AUTHORED_SHADER
			authored_material.set_shader_parameter("sentinel_palette",false)
			authored_material.set_shader_parameter("paint_gain",.76 if identity=="gargoyle" else .88 if identity=="witch" else 1.0)
			authored_material.set_shader_parameter("character_kind",["knight","gargoyle","witch"].find(identity))
			authored_material.set_shader_parameter("finish_detail",FINISH_DETAIL)
			child.material_override=authored_material
	motion=Motion.new()
	motion.configure(skeleton,identity)
	match identity:
		"knight":
			mats.gold.next_pass=null
			_build_cape(.31,1.43,.58,-.18)
		"gargoyle": _configure_wings()
		"witch": _configure_witch_controls()
	motion.advance(0.1,false,false,false,identity)
	if identity=="gargoyle":_animate_wings(1.0)
	if identity=="witch":_animate_witch_controls(1.0)
	skeleton.force_update_all_bone_transforms()

func sentinel() -> void:
	facing=0;body.rotation.y=0
	base_scale*=.87;body.scale=Vector3.ONE*base_scale
	for key in ["steel","edge","gold","cloth","glow"]:
		var material: StandardMaterial3D=mats[key]
		material.albedo_color=Color({"steel":"8454bd","edge":"e6bcff","gold":"ffc05b","cloth":"f276a6","glow":"ffb3d6"}[key])
		if key=="glow": material.emission=Color("f45b8b")
	for child in skeleton.get_children():
		if child is MeshInstance3D and child.material_override is ShaderMaterial:
			child.material_override.set_shader_parameter("base_color",Color("8454bd"))
			child.material_override.set_shader_parameter("highlight_color",Color("ea5b88"))
	if is_instance_valid(authored_mesh):
		authored_mesh.material_override.set_shader_parameter("sentinel_palette",true)
	set_meta("sentinel",true)


func _build_cape(width: float, top: float, bottom: float, z: float) -> void:
	cape=Node3D.new()
	_attachment("spine_03").add_child(cape)
	var geo=Geo.new()
	for row in range(10):
		for column in range(12):
			var vertices: Array[Vector3]=[]
			for uv in [Vector2(column/12.0,row/10.0),Vector2((column+1)/12.0,row/10.0),Vector2(column/12.0,(row+1)/10.0),Vector2((column+1)/12.0,(row+1)/10.0)]:
				# MR-ART-018: curved shoulder drape, asymmetric cloth folds and
				# a gently scalloped hem. Keep the gold star shader and spine rig.
				var spread:float=lerpf(.62,1.12,uv.y)
				var edge_wave:float=1.0+0.065*sin(uv.y*PI*2.0+0.35)
				var drape_x:float=(uv.x-.5)*2.0
				var fold:float=sin(uv.x*PI*2.0+uv.y*0.65)*uv.y*0.016
				var hem_drop:float=pow(uv.y,8.0)*(0.009*cos(uv.x*PI*2.0))
				vertices.append(Vector3(drape_x*width*spread*edge_wave,
					lerpf(top,bottom,uv.y)-hem_drop,
					z-uv.y*uv.y*.48+fold-0.012*sin(uv.y*PI)*cos(uv.x*PI*2.0)))
			geo.triangle(vertices[0],vertices[2],vertices[1],mats.cloth)
			geo.triangle(vertices[1],vertices[2],vertices[3],mats.cloth)
	var cloth: StandardMaterial3D=mats.cloth
	cloth.cull_mode=BaseMaterial3D.CULL_DISABLED
	var fabric:MeshInstance3D=geo.build()
	var woven:=ShaderMaterial.new();woven.shader=preload("res://assets/shaders/embroidered_cloth.gdshader")
	woven.set_shader_parameter("half_width",width);woven.set_shader_parameter("top",top);woven.set_shader_parameter("bottom",bottom)
	woven.set_shader_parameter("cloth_color",Color("ff715d") if identity=="knight" else Color("a653df"))
	cape_fabric=woven;fabric.material_override=woven;cape.add_child(fabric)
	# Follow the actual draped silhouette instead of straight diagonal borders.
	for side in [-1.0,1.0]:
		var previous:=Vector3(side*width*.62,top,z)
		for i in range(1,13):
			var v:=i/12.0
			var spread:float=lerpf(.62,1.12,v)*(1.0+0.065*sin(v*PI*2.0+0.35))
			var point:=Vector3(side*width*spread,
				lerpf(top,bottom,v)+pow(v,8.0)*0.009,
				z-v*v*.48+sin((1.0 if side>0 else 0.0)*PI*2.0+v*0.65)*v*.016+0.012*sin(v*PI))
			Geo.segment(cape,previous,point,.007,mats.gold)
			previous=point

func animate(delta: float) -> void:
	clock+=delta
	if is_instance_valid(authored_mesh):
		_animate_face(delta)
	hurt_left=maxf(0.0,hurt_left-delta)
	attack_time=maxf(0,attack_time-delta)
	celebration_left=maxf(0,celebration_left-delta);traversal_left=maxf(0,traversal_left-delta)
	power_time=maxf(0,power_time-delta)
	motion.advance(delta,moving,airborne,sliding,identity)
	if identity in ["gargoyle","witch"]:_animate_creature_tuck(delta)
	if identity=="witch":_animate_witch_controls(delta)
	if not wing_controls.is_empty():_animate_wings(delta)
	if get_meta("sentinel",false):
		var arm:int=skeleton.find_bone("upperarm_r")
		skeleton.set_bone_pose_rotation(arm,skeleton.get_bone_pose_rotation(arm)*Quaternion(Vector3.RIGHT,-.9*threat_intensity))
		body.rotation.x=-.08*threat_intensity
	skeleton.force_update_all_bone_transforms()
	var special:float=sin(clampf(power_time/.7,0,1)*PI);var cheer:float=0 if reduced_motion else sin(celebration_left*11)*minf(1,celebration_left*2)
	var stride:float=sin(clock*13*motion.locomotion_rate)
	if was_airborne and not airborne:landing_spring=.24
	was_airborne=airborne;landing_spring=maxf(0,landing_spring-delta)
	var spring:float=0 if reduced_motion else sin(landing_spring/.24*PI)*.11
	var bounce:float=0 if reduced_motion or not moving or airborne or sliding else absf(stride)*.075
	var squash:float=0 if reduced_motion or not moving or airborne or sliding else cos(clock*26*motion.locomotion_rate)*.025
	body.position.y=bounce+(0.0 if reduced_motion else sin(clock*2)*.014)+absf(cheer)*.16
	body.scale=Vector3(base_scale*1.12*(1+special*.10+spring-squash*.5),base_scale*.98*(1-special*.08-spring+squash),base_scale*1.12*(1+special*.10+spring-squash*.5))
	if is_instance_valid(cape_fabric):
		cape_fabric.set_shader_parameter("motion_amount",0.0 if reduced_motion else (1.0 if moving else 0.25))
		cape_fabric.set_shader_parameter("motion_speed",clampf(motion.locomotion_rate,0.55,1.65) if moving else 0.5)
	body.rotation.y=facing+sin(attack_time/.4*PI)*swipe_direction*.24+cheer*.08
	body.rotation.x=lerpf(body.rotation.x,(-.12 if sliding else -.035 if moving else 0)+special*.08,1-exp(-delta*14))
	body.visible=not (identity=="witch" and traversal_left>.3 and traversal_left<.47)
	body.rotation.z=lerpf(body.rotation.z,-lean*.17,1-exp(-delta*10))
	if is_instance_valid(cape): cape.rotation.x=0 if reduced_motion else sin(clock*7)*.045

func attack(direction:int=1) -> void:
	swipe_direction=direction;attack_time=.4
	motion.strike()

func power() -> void:
	power_time=.7
	motion.power()

func set_expression(expression:String="auto") -> bool:
	# Used by the character stage; gameplay normally follows the existing state.
	if expression not in ["auto","neutral","alert","pleased","determined","surprised","hurt"]:return false
	expression_override=expression
	return true

func _configure_wings() -> void:
	for suffix in ["l","r"]:
		for role in ["root","tip"]:
			var index:int=skeleton.find_bone("wing_"+role+"_"+suffix)
			if index<0:continue
			var parent:int=skeleton.get_bone_parent(index)
			var parent_basis:Basis=skeleton.get_bone_global_rest(parent).basis if parent>=0 else Basis.IDENTITY
			var rest:Quaternion=skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
			wing_controls.append({"index":index,"parent":parent,"side":1.0 if suffix=="l" else -1.0,"tip":role=="tip","rest":rest,"global_rest":skeleton.get_bone_global_rest(index).basis.get_rotation_quaternion(),"current":rest,"up":(parent_basis.inverse()*Vector3.UP).normalized(),"forward":(parent_basis.inverse()*Vector3.FORWARD).normalized(),"right":(parent_basis.inverse()*Vector3.RIGHT).normalized()})

func _configure_witch_controls() -> void:
	for name in ["braid_root","braid_tip"]:
		var index:int=skeleton.find_bone(name)
		if index<0:continue
		var parent:int=skeleton.get_bone_parent(index)
		var rest:Quaternion=skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
		var parent_basis:Basis=skeleton.get_bone_global_rest(parent).basis
		braid_controls.append({"index":index,"parent":parent,"rest":rest,"current":rest,"global_rest":skeleton.get_bone_global_rest(index).basis.get_rotation_quaternion(),"right":(parent_basis.inverse()*Vector3.RIGHT).normalized(),"forward":(parent_basis.inverse()*Vector3.FORWARD).normalized()})
	var index:int=skeleton.find_bone("staff_control")
	if index>=0:
		var rest:Quaternion=skeleton.get_bone_global_rest(index).basis.get_rotation_quaternion()
		staff_control={"index":index,"parent":skeleton.get_bone_parent(index),"global_rest":rest,"global_current":rest}

func _animate_witch_controls(delta:float) -> void:
	# Local braid motion is cosmetic. The grip stays on the authored hand joint;
	# only staff orientation changes so the full crescent clears a slide beam.
	for i in range(braid_controls.size()):
		var control:Dictionary=braid_controls[i]
		var sway:float=0.0 if reduced_motion else sin(clock*4.2-i*.65)*(.065 if moving else .025)
		var pitch:float=0.0 if reduced_motion else sin(clock*3.1-i*.5)*.035
		var rotation:Quaternion=(Quaternion(control.right,pitch)*Quaternion(control.forward,sway)*Quaternion(control.rest)).normalized()
		if sliding:
			skeleton.force_update_all_bone_transforms()
			var parent_rotation:Quaternion=skeleton.get_bone_global_pose(int(control.parent)).basis.orthonormalized().get_rotation_quaternion()
			rotation=(parent_rotation.inverse()*Quaternion(Vector3.RIGHT,-1.30)*Quaternion(control.global_rest)).normalized()
		control.current=Quaternion(control.current).slerp(rotation,1.0-exp(-delta*26.0)).normalized()
		skeleton.set_bone_pose_rotation(int(control.index),control.current)
	if staff_control.is_empty():return
	skeleton.force_update_all_bone_transforms()
	var parent_rotation:Quaternion=skeleton.get_bone_global_pose(int(staff_control.parent)).basis.orthonormalized().get_rotation_quaternion()
	var pitch:float=1.62 if sliding else .32 if airborne else .12
	var sweep:float=sin(clampf(attack_time/.4,0,1)*PI)*.26
	var target:Quaternion=(Quaternion(Vector3.RIGHT,pitch)*Quaternion(Vector3.FORWARD,.12+sweep)*Quaternion(staff_control.global_rest)).normalized()
	staff_control.global_current=Quaternion(staff_control.global_current).slerp(target,1.0-exp(-delta*26.0)).normalized()
	skeleton.set_bone_pose_rotation(int(staff_control.index),(parent_rotation.inverse()*Quaternion(staff_control.global_current)).normalized())

func _animate_creature_tuck(delta:float) -> void:
	var tuck_angle:float=1.35 if identity=="witch" else 1.25
	creature_tuck=lerpf(creature_tuck,tuck_angle if sliding else 0.0,1.0-exp(-delta*26.0))
	if creature_tuck<.00001:return
	skeleton.force_update_all_bone_transforms()
	var head:int=skeleton.find_bone("Head")
	var parent:int=skeleton.get_bone_parent(head)
	var axis:Vector3=(skeleton.get_bone_global_pose(parent).basis.inverse()*Vector3.RIGHT).normalized()
	var sampled:Quaternion=skeleton.get_bone_pose_rotation(head)
	skeleton.set_bone_pose_rotation(head,(Quaternion(axis,creature_tuck)*sampled).normalized())

func _animate_wings(delta:float) -> void:
	skeleton.force_update_all_bone_transforms()
	var gliding:bool=airborne or traversal_left>0
	var fold:float=1.43 if sliding else .10 if gliding else .94
	# Wing roots carry the main sweep; tips lag and flex independently.
	# Keep reduced-motion and slide-clearance behavior deterministic.
	var frequency:float=8.0 if gliding else 5.0 if moving else 2.0
	var amplitude:float=.15 if gliding else .065 if moving else .012
	for control in wing_controls:
		var side:float=control.side
		var tip:bool=control.tip
		var phase:float=clock*frequency-(.72 if tip else 0.0)
		var flutter:float=0.0 if reduced_motion or sliding else sin(phase)*amplitude
		var secondary:float=0.0 if reduced_motion or sliding else sin(phase*.53+side*.7)*amplitude*.35
		var yaw:float=side*((.36 if sliding else .12 if gliding else .24) if tip else fold+flutter)
		if tip:yaw+=side*(flutter*.75+secondary)
		var lift:float=side*(flutter*(.75 if tip else .35)+secondary)
		var pitch:float=-1.25 if sliding and not tip else 0.0
		var target:Quaternion=(Quaternion(control.right,pitch)*Quaternion(control.up,yaw)*Quaternion(control.forward,lift)*Quaternion(control.rest)).normalized()
		if sliding and not tip:
			# The crouch clip changes torso orientation. Fold against the current
			# parent pose so the membrane lies along the back below the beam.
			var parent_rotation:Quaternion=skeleton.get_bone_global_pose(int(control.parent)).basis.orthonormalized().get_rotation_quaternion()
			var folded_global:Quaternion=Quaternion(Vector3.RIGHT,-1.12)*Quaternion(Vector3.UP,yaw)*Quaternion(control.global_rest)
			target=(parent_rotation.inverse()*folded_global).normalized()
		control.current=Quaternion(control.current).slerp(target,1.0-exp(-delta*16.0)).normalized()
		skeleton.set_bone_pose_rotation(int(control.index),control.current)

func react_to_hit() -> void:
	hurt_left=.55

func _face_value(shape:String,value:float) -> void:
	if face_shapes.has(shape):authored_mesh.set_blend_shape_value(int(face_shapes[shape]),value)

func _animate_face(delta:float) -> void:
	blink_clock=fposmod(blink_clock+delta,4.1)
	var blink:float=0.0 if reduced_motion else maxf(0.0,1.0-absf(blink_clock-3.75)/.085)
	facial_state=expression_override
	if facial_state=="auto":
		facial_state="hurt" if hurt_left>0 else "pleased" if celebration_left>0 else "determined" if attack_time>0 or power_time>0 or (get_meta("sentinel",false) and threat_intensity>.2) else "surprised" if airborne else "alert" if moving else "neutral"
	var targets:Dictionary={"Smile":0.0,"Focus":0.0,"Surprised":0.0,"Hurt":0.0}
	match facial_state:
		"pleased":targets.Smile=.85
		"determined":targets.Focus=.85
		"surprised":targets.Surprised=.65
		"hurt":targets.Hurt=.85
		"alert":targets.Focus=.18
	for shape in targets:
		face_weights[shape]=lerpf(float(face_weights[shape]),float(targets[shape]),1.0-exp(-delta*16.0))
		# Suppress the expression during closure so additive eye morphs cannot invert.
		_face_value(shape,float(face_weights[shape])*(1.0-blink))
	_face_value("Blink",blink)
	_face_value("PlumeSway",0.0 if reduced_motion else sin(clock*5.5)*.55)


func celebrate() -> void:celebration_left=.75
func traverse() -> void:traversal_left=.7;celebrate()
