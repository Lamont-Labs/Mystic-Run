extends Node3D

const Geo = preload("res://game/geometry.gd")
const Motion = preload("res://game/rig_motion.gd")
const BODY_SHADER = preload("res://assets/shaders/comic_body.gdshader")
const OUTLINE = preload("res://assets/shaders/ink_outline.gdshader")
var identity: String = "knight"
var body: Node3D
var skeleton: Skeleton3D
var motion: RefCounted
var wings: Array[Node3D] = []
var cape: Node3D
var aura: Node3D
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

func configure(kind: String) -> void:
	identity=kind
	_build()

func accent() -> Color:
	return {"knight":Color("5de9f2"),"gargoyle":Color("60e3bd"),"witch":Color("ba83ff")}[identity]

func _paint(color: String, metal: float=0.0, emission: float=0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color(color)
	mat.diffuse_mode=BaseMaterial3D.DIFFUSE_BURLEY
	mat.specular_mode=BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.metallic=metal
	mat.roughness=0.32 if metal>0.4 else 0.78
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
	mats={"steel":_paint("658fc1",0.40),"edge":_paint("b4e1ef",0.32),"dark":_paint("25375a",0.20),"gold":_paint("f1c365",0.38),"cloth":_paint("694896"),"stone":_paint("8aaed2"),"glow":_paint("5de9f2",0.25,1.5)}
	body=Node3D.new()
	body.rotation.y=PI
	base_scale=1.16 if identity=="gargoyle" else 1.08
	body.scale=Vector3.ONE*base_scale
	add_child(body)
	var gender := "Female" if identity=="witch" else "Male"
	var model: Node3D=(load("res://assets/models/quaternius/base/Superhero_"+gender+"_FullBody.gltf") as PackedScene).instantiate()
	body.add_child(model)
	skeleton=model.find_child("Skeleton3D",true,false)
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			var material := ShaderMaterial.new()
			material.shader=BODY_SHADER
			material.set_shader_parameter("character_kind",["knight","gargoyle","witch"].find(identity))
			material.set_shader_parameter("base_color",Color("3c658f") if identity=="knight" else Color("7199b8") if identity=="gargoyle" else Color("6b438a"))
			material.set_shader_parameter("highlight_color",accent())
			var outline := ShaderMaterial.new()
			outline.shader=OUTLINE
			material.next_pass=outline
			child.material_override=material
			if child.name=="Eyes": child.material_override=_paint("b3ecff",0,1.0) if identity!="witch" else _paint("7448a8")
			if identity=="knight" and child.name in ["Eyes","Eyebrows"]: child.visible=false
	var head_index:int=skeleton.find_bone("Head")
	if head_index>=0:skeleton.set_bone_pose_scale(head_index,Vector3.ONE*1.12)
	motion=Motion.new()
	motion.configure(skeleton,identity)
	match identity:
		"knight": _knight()
		"gargoyle": _gargoyle()
		"witch": _witch()
	motion.advance(0.1,false,false,false,identity)

func sentinel() -> void:
	facing=0;body.rotation.y=0
	base_scale*=.87;body.scale=Vector3.ONE*base_scale
	for key in ["steel","edge","gold","cloth","glow"]:
		var material: StandardMaterial3D=mats[key]
		material.albedo_color=Color({"steel":"242b43","edge":"4d5170","gold":"744959","cloth":"4e203c","glow":"ec5d89"}[key])
		if key=="glow": material.emission=Color("f45b8b")
	for child in skeleton.get_children():
		if child is MeshInstance3D and child.material_override is ShaderMaterial:
			child.material_override.set_shader_parameter("base_color",Color("20283e"))
			child.material_override.set_shader_parameter("highlight_color",Color("ea5b88"))
	set_meta("sentinel",true)


# Lofted shells follow the actual humanoid proportions rather than replacing limbs.
func _shell(geo: RefCounted, levels: Array, material: Material, sides: int=12, center: Vector3=Vector3.ZERO) -> void:
	for row in range(levels.size()-1):
		var a: Vector3=levels[row]
		var b: Vector3=levels[row+1]
		for i in range(sides):
			var t:=TAU*i/sides
			var n:=TAU*(i+1)/sides
			var v0:=center+Vector3(sin(t)*a.x,a.y,cos(t)*a.z)
			var v1:=center+Vector3(sin(n)*a.x,a.y,cos(n)*a.z)
			var v2:=center+Vector3(sin(t)*b.x,b.y,cos(t)*b.z)
			var v3:=center+Vector3(sin(n)*b.x,b.y,cos(n)*b.z)
			geo.triangle(v0,v1,v2,material)
			geo.triangle(v1,v3,v2,material)

func _knight() -> void:
	var chest=Geo.new()
	_shell(chest,[Vector3(.17,1.02,.115),Vector3(.20,1.12,.14),Vector3(.28,1.35,.19),Vector3(.235,1.46,.14)],mats.steel)
	_shell(chest,[Vector3(.17,1.02,.125),Vector3(.18,1.065,.125)],mats.gold)
	for side in [-1.0,1.0]:
		chest.armor(Vector3(side*.135,1.34,.16),Vector3(.24,.16,.065),mats.edge,.8)
		Geo.segment(_attachment("spine_03"),Vector3(side*.23,1.40,.15),Vector3(0,1.23,.19),.014,mats.gold)
	chest.sphere(Vector3(0,1.31,.204),Vector3(.09,.11,.038),mats.glow)
	_add(chest,"spine_03")
	var helmet=Geo.new()
	_shell(helmet,[Vector3(.065,1.56,.10),Vector3(.115,1.63,.13),Vector3(.135,1.74,.14),Vector3(.10,1.84,.105),Vector3(.008,1.87,.02)],mats.steel,10,Vector3(0,0,-.006))
	helmet.armor(Vector3(0,1.713,.137),Vector3(.225,.052,.025),mats.dark)
	for side in [-1.0,1.0]:
		helmet.armor(Vector3(side*.056,1.716,.156),Vector3(.086,.014,.014),mats.glow)
		helmet.armor(Vector3(side*.082,1.62,.10),Vector3(.038,.15,.08),mats.gold,.6)
		helmet.cylinder(Vector3(side*.08,1.87,.005),.022,.20,mats.gold,0,Vector3(0,0,-side*.5),6)
	helmet.armor(Vector3(0,1.79,.13),Vector3(.026,.18,.06),mats.gold)
	_add(helmet,"Head")
	for side in ["l","r"]:
		var sign_value:=1.0 if side=="l" else -1.0
		var shoulder=skeleton.get_bone_global_rest(skeleton.find_bone("upperarm_"+side)).origin
		var elbow=skeleton.get_bone_global_rest(skeleton.find_bone("lowerarm_"+side)).origin
		var hand=skeleton.get_bone_global_rest(skeleton.find_bone("hand_"+side)).origin
		var pauldron=Geo.new()
		pauldron.sphere(shoulder+Vector3(sign_value*.045,.015,0),Vector3(.29,.22,.29),mats.steel,16)
		pauldron.armor(shoulder+Vector3(sign_value*.04,.087,0),Vector3(.25,.07,.25),mats.gold)
		pauldron.cylinder(shoulder+Vector3(sign_value*.055,.19,0),.027,.20,mats.edge,0,Vector3(0,0,-sign_value*.3),6)
		_add(pauldron,"upperarm_"+side)
		var bracer=Geo.new()
		bracer.sphere(elbow.lerp(hand,.58),Vector3(.22,.15,.17),mats.steel,16)
		bracer.armor(elbow.lerp(hand,.55)+Vector3(0,0,.065),Vector3(.19,.10,.065),mats.edge,.65)
		_add(bracer,"lowerarm_"+side)
		var thigh=skeleton.get_bone_global_rest(skeleton.find_bone("thigh_"+side)).origin
		var knee=skeleton.get_bone_global_rest(skeleton.find_bone("calf_"+side)).origin
		var foot=skeleton.get_bone_global_rest(skeleton.find_bone("foot_"+side)).origin
		var leg=Geo.new()
		leg.armor(thigh.lerp(knee,.38)+Vector3(0,0,.065),Vector3(.20,.31,.13),mats.steel,.70)
		_add(leg,"thigh_"+side)
		var shin=Geo.new()
		shin.armor(knee.lerp(foot,.40)+Vector3(0,0,.06),Vector3(.20,.32,.15),mats.steel,.64)
		shin.armor(knee+Vector3(0,0,.07),Vector3(.21,.14,.15),mats.gold,.60)
		_add(shin,"calf_"+side)
		var boot=Geo.new()
		boot.armor(foot+Vector3(0,-.01,.07),Vector3(.18,.16,.35),mats.steel,.7)
		_add(boot,"foot_"+side)
	var weapon_parent:=_attachment("hand_r")
	var hand_at:=skeleton.get_bone_global_rest(skeleton.find_bone("hand_r")).origin
	var sword=Geo.new()
	sword.cylinder(hand_at+Vector3(0,0,.06),.025,.18,mats.dark,1,Vector3(PI/2,0,0))
	sword.armor(hand_at+Vector3(0,0,.19),Vector3(.31,.045,.06),mats.gold)
	# Broad, pointed energy blade in a real grip; local +Z is the character's front.
	sword.triangle(hand_at+Vector3(-.07,0,.22),hand_at+Vector3(0,.022,1.12),hand_at+Vector3(.07,0,.22),mats.edge)
	sword.triangle(hand_at+Vector3(-.07,0,.22),hand_at+Vector3(.07,0,.22),hand_at+Vector3(0,-.022,1.12),mats.steel)
	Geo.segment(weapon_parent,hand_at+Vector3(0,.024,.25),hand_at+Vector3(0,.024,1.05),.012,mats.glow)
	weapon_parent.add_child(sword.build())
	var shield=Geo.new()
	var left:=skeleton.get_bone_global_rest(skeleton.find_bone("lowerarm_l")).origin
	shield.armor(left+Vector3(.09,0,.05),Vector3(.10,.50,.39),mats.gold,.65)
	shield.armor(left+Vector3(.15,0,.05),Vector3(.07,.43,.33),mats.steel,.65)
	shield.ring(left+Vector3(.194,.025,.05),.13,.014,mats.glow,Vector3(0,0,PI/2))
	_add(shield,"lowerarm_l")
	_build_cape(.44,1.42,.38,-.15)

func _gargoyle() -> void:
	var head=Geo.new()
	for side in [-1.0,1.0]:
		head.cylinder(Vector3(side*.10,1.82,-.045),.05,.30,mats.stone,0,Vector3(-.35,0,-side*.50),8)
		head.armor(Vector3(side*.065,1.72,.09),Vector3(.11,.046,.07),mats.dark,.65)
		head.sphere(Vector3(side*.048,1.705,.117),Vector3(.045,.016,.018),mats.glow)
		head.cylinder(Vector3(side*.14,1.705,-.01),.038,.18,mats.stone,0,Vector3(0,0,side*1.15),6)
		head.cylinder(Vector3(side*.037,1.635,.11),.012,.07,mats.gold,0,Vector3(PI,0,0),6)
	_add(head,"Head")
	var belt=Geo.new()
	_shell(belt,[Vector3(.17,.83,.13),Vector3(.21,1.02,.14)],mats.cloth)
	_shell(belt,[Vector3(.20,1.00,.145),Vector3(.20,1.035,.145)],mats.gold)
	_add(belt,"pelvis")
	for side in [-1.0,1.0]:
		var wing:=Node3D.new()
		_attachment("spine_03").add_child(wing)
		wing.position=Vector3(side*.17,1.40,-.12)
		var web=Geo.new()
		var origin:=Vector3.ZERO
		var tips: Array[Vector3]=[Vector3(side*.53,.73,-.25),Vector3(side*1.13,.49,-.36),Vector3(side*1.09,-.12,-.49),Vector3(side*.62,-.58,-.40),Vector3(side*.12,-.56,-.17)]
		var membrane:=_paint("49325c")
		membrane.cull_mode=BaseMaterial3D.CULL_DISABLED
		membrane.next_pass=null
		for i in range(tips.size()-1):
			for step_index in range(8):
				var t:=float(step_index)/8
				var next:=float(step_index+1)/8
				var a:=tips[i].lerp(tips[i+1],t)*(.78+.22*absf(t-.5)*2)
				var b:=tips[i].lerp(tips[i+1],next)*(.78+.22*absf(next-.5)*2)
				web.triangle(origin,a,b,membrane)
		for tip in tips: Geo.segment(wing,origin,tip,.023,mats.stone)
		wing.add_child(web.build())
		wings.append(wing)
	for side in ["l","r"]:
		var hand=skeleton.get_bone_global_rest(skeleton.find_bone("hand_"+side)).origin
		var claws=Geo.new()
		for i in range(3): claws.cylinder(hand+Vector3((i-1)*.028,-.02,.10),.013,.14,mats.gold,0,Vector3(PI/2,0,0),6)
		_add(claws,"hand_"+side)

func _witch() -> void:
	var gold: Material=mats.gold
	var bodice=Geo.new()
	_shell(bodice,[Vector3(.12,1.02,.10),Vector3(.15,1.23,.15),Vector3(.18,1.34,.14),Vector3(.13,1.42,.09)],mats.cloth)
	for side in [-1.0,1.0]:
		bodice.armor(Vector3(side*.11,1.31,.12),Vector3(.14,.14,.05),mats.dark)
		Geo.segment(_attachment("spine_03"),Vector3(side*.15,1.35,.14),Vector3(0,1.16,.15),.009,gold)
	bodice.sphere(Vector3(0,1.27,.16),Vector3(.06,.085,.03),mats.glow)
	_add(bodice,"spine_03")
	var crown=Geo.new()
	crown.ring(Vector3(0,1.79,-.07),.18,.012,gold,Vector3(PI/2,0,0))
	for side in [-1.0,1.0]: crown.cylinder(Vector3(side*.09,1.82,.02),.018,.16,gold,0,Vector3(0,0,-side*.35),6)
	_add(crown,"Head")
	var hair: Node3D=(load("res://assets/models/quaternius/hair/Hair_Long.gltf") as PackedScene).instantiate()
	_attachment("Head").add_child(hair)
	for child in hair.get_children():
		if child is MeshInstance3D: child.material_override=_paint("d0d6e7",0.05)
	var staff=Geo.new()
	var hand:=skeleton.get_bone_global_rest(skeleton.find_bone("hand_r")).origin
	staff.cylinder(hand+Vector3(0,.25,0),.018,1.40,gold)
	staff.ring(hand+Vector3(0,1.02,0),.17,.018,gold,Vector3(PI/2,0,0))
	staff.cylinder(hand+Vector3(0,1.03,0),.065,.24,mats.glow,0,Vector3.ZERO,5)
	_add(staff,"hand_r")
	_build_cape(.38,1.40,.35,-.12)
	var sash=Geo.new()
	for side in [-1.0,1.0]:
		sash.triangle(Vector3(side*.12,1.03,.1),Vector3(side*.41,.37,-.1),Vector3(side*.18,.29,.16),mats.cloth)
	_add(sash,"pelvis")
	aura=Node3D.new()
	aura.position=Vector3(.55,1.32,.15)
	body.add_child(aura)
	var magic=Geo.new()
	magic.sphere(Vector3.ZERO,Vector3.ONE*.10,mats.glow,16)
	magic.ring(Vector3.ZERO,.17,.009,gold,Vector3(.5,.7,0))
	aura.add_child(magic.build())

func _build_cape(width: float, top: float, bottom: float, z: float) -> void:
	cape=Node3D.new()
	_attachment("spine_03").add_child(cape)
	var geo=Geo.new()
	for row in range(10):
		for column in range(12):
			var vertices: Array[Vector3]=[]
			for uv in [Vector2(column/12.0,row/10.0),Vector2((column+1)/12.0,row/10.0),Vector2(column/12.0,(row+1)/10.0),Vector2((column+1)/12.0,(row+1)/10.0)]:
				var spread:=lerpf(.6,1.18,uv.y)
				vertices.append(Vector3((uv.x-.5)*2*width*spread,lerpf(top,bottom,uv.y),z-uv.y*uv.y*.42-sin(uv.x*PI*8)*uv.y*.035))
			geo.triangle(vertices[0],vertices[2],vertices[1],mats.cloth)
			geo.triangle(vertices[1],vertices[2],vertices[3],mats.cloth)
	var cloth: StandardMaterial3D=mats.cloth
	cloth.cull_mode=BaseMaterial3D.CULL_DISABLED
	var fabric:MeshInstance3D=geo.build()
	var woven:=ShaderMaterial.new();woven.shader=preload("res://assets/shaders/embroidered_cloth.gdshader")
	woven.set_shader_parameter("half_width",width);woven.set_shader_parameter("top",top);woven.set_shader_parameter("bottom",bottom)
	woven.set_shader_parameter("cloth_color",Color("743b9e") if identity=="knight" else Color("84456f"))
	fabric.material_override=woven;cape.add_child(fabric)
	Geo.segment(cape,Vector3(-width*.60,top,z),Vector3(-width*1.18,bottom,z-.42),.009,mats.gold)
	Geo.segment(cape,Vector3(width*.60,top,z),Vector3(width*1.18,bottom,z-.42),.009,mats.gold)

func animate(delta: float) -> void:
	clock+=delta
	attack_time=maxf(0,attack_time-delta)
	celebration_left=maxf(0,celebration_left-delta);traversal_left=maxf(0,traversal_left-delta)
	power_time=maxf(0,power_time-delta)
	motion.advance(delta,moving,airborne,sliding,identity)
	if get_meta("sentinel",false):
		var arm:int=skeleton.find_bone("upperarm_r")
		skeleton.set_bone_pose_rotation(arm,skeleton.get_bone_pose_rotation(arm)*Quaternion(Vector3.RIGHT,-.9*threat_intensity))
		body.rotation.x=-.08*threat_intensity
	skeleton.force_update_all_bone_transforms()
	var special:float=sin(clampf(power_time/.7,0,1)*PI);var cheer:float=0 if reduced_motion else sin(celebration_left*11)*minf(1,celebration_left*2)
	var stride:float=sin(clock*13*motion.locomotion_rate)
	body.position.y=(absf(stride)*.035 if moving and not airborne and not sliding else sin(clock*2)*.018)+absf(cheer)*.12
	body.scale=Vector3(base_scale*(1+special*.09),base_scale*(1-special*.075),base_scale*(1+special*.09))
	body.rotation.y=facing+sin(attack_time/.4*PI)*swipe_direction*.24+cheer*.08
	body.rotation.x=lerpf(body.rotation.x,(-.12 if sliding else -.035 if moving else 0)+special*.08,1-exp(-delta*14))
	body.visible=not (identity=="witch" and traversal_left>.3 and traversal_left<.47)
	body.rotation.z=lerpf(body.rotation.z,-lean*.09,1-exp(-delta*10))
	for index in range(wings.size()):
		var sign_value:=1.0 if index==0 else -1.0
		wings[index].rotation.y=sign_value*((.08 if airborne or traversal_left>0 else 1.48 if sliding else 1.02)+sin(clock*(9 if airborne or traversal_left>0 else 4))*(.22 if airborne or traversal_left>0 else .12))
		wings[index].rotation.z=lerpf(wings[index].rotation.z,sign_value*-.32 if sliding else 0.0,1-exp(-delta*14))
	if is_instance_valid(cape): cape.rotation.x=sin(clock*6)*.018
	if is_instance_valid(aura):
		aura.position.y=1.32+sin(clock*2.4)*.04
		aura.rotation.y+=delta*1.4

func attack(direction:int=1) -> void:
	swipe_direction=direction;attack_time=.4
	motion.strike()

func power() -> void:
	power_time=.7
	motion.power()


func celebrate() -> void:celebration_left=.75
func traverse() -> void:traversal_left=.7;celebrate()
