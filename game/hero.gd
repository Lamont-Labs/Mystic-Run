extends Node3D

const Geo = preload("res://game/geometry.gd")
const Motion = preload("res://game/rig_motion.gd")
const BODY_SHADER = preload("res://assets/shaders/comic_body.gdshader")
const OUTLINE = preload("res://assets/shaders/ink_outline.gdshader")
const AUTHORED_SHADER = preload("res://assets/shaders/authored_character.gdshader")
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
var was_airborne:bool=false
var landing_spring:float=0.0
var cape_fabric:ShaderMaterial
var authored_mesh:MeshInstance3D
var blink_clock:float=0.0

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
	base_scale=1.16 if identity=="gargoyle" else 1.08
	body.scale=Vector3.ONE*base_scale
	add_child(body)
	var gender := "Female" if identity=="witch" else "Male"
	var model_path:String="res://assets/characters/knight/knight.glb" if identity=="knight" else "res://assets/models/quaternius/base/Superhero_"+gender+"_FullBody.gltf"
	var model: Node3D=(load(model_path) as PackedScene).instantiate()
	body.add_child(model)
	skeleton=model.find_child("Skeleton3D",true,false)
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			if identity=="knight":
				authored_mesh=child
				var authored_material:=ShaderMaterial.new()
				authored_material.shader=AUTHORED_SHADER
				authored_material.set_shader_parameter("sentinel_palette",false)
				child.material_override=authored_material
				continue
			var material := ShaderMaterial.new()
			material.shader=BODY_SHADER
			material.set_shader_parameter("character_kind",["knight","gargoyle","witch"].find(identity))
			material.set_shader_parameter("base_color",Color("3f8fd4") if identity=="knight" else Color("55bda8") if identity=="gargoyle" else Color("ae69dc"))
			material.set_shader_parameter("highlight_color",accent())
			var outline := ShaderMaterial.new()
			outline.shader=OUTLINE
			material.next_pass=outline
			child.material_override=material
			if child.name=="Eyes": child.material_override=_paint("b3ecff",0,1.0) if identity!="witch" else _paint("7448a8")
			if identity=="knight" and child.name in ["Eyes","Eyebrows"]: child.visible=false
	var head_index:int=skeleton.find_bone("Head")
	if head_index>=0 and identity!="knight":skeleton.set_bone_pose_scale(head_index,Vector3.ONE*1.36)
	motion=Motion.new()
	motion.configure(skeleton,identity)
	match identity:
		"knight":
			mats.gold.next_pass=null
			_build_cape(.38,1.43,.46,-.18)
		"gargoyle": _gargoyle()
		"witch": _witch()
	motion.advance(0.1,false,false,false,identity)

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

func _gargoyle() -> void:
	var head=Geo.new()
	for side in [-1.0,1.0]:
		head.cylinder(Vector3(side*.10,1.82,-.045),.05,.30,mats.stone,0,Vector3(-.35,0,-side*.50),8)
		head.armor(Vector3(side*.065,1.72,.09),Vector3(.11,.046,.07),mats.dark,.65)
		head.sphere(Vector3(side*.048,1.705,.117),Vector3(.045,.016,.018),mats.glow)
		head.cylinder(Vector3(side*.14,1.705,-.01),.038,.18,mats.stone,0,Vector3(0,0,side*1.15),6)
		head.cylinder(Vector3(side*.037,1.635,.11),.012,.07,mats.gold,0,Vector3(PI,0,0),6)
	# Oversized friendly eyes and cheeks read at the chase-camera scale.
	for side in [-1.0,1.0]:
		head.sphere(Vector3(side*.078,1.72,.127),Vector3(.104,.088,.045),mats.edge,16)
		head.sphere(Vector3(side*.069,1.718,.153),Vector3(.038,.050,.016),mats.dark,12)
		head.sphere(Vector3(side*.114,1.66,.087),Vector3(.10,.074,.052),mats.stone,16)
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
		var membrane:=_paint("b176e6")
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
	# A broad brim and a crooked candy-purple point give the Witch a clear silhouette.
	crown.cylinder(Vector3(0,1.845,-.015),.37,.055,mats.cloth,1,Vector3.ZERO,24)
	crown.cylinder(Vector3(0,2.04,-.025),.22,.38,mats.cloth,.25,Vector3(0,0,-.14),16)
	crown.cylinder(Vector3(.055,2.23,-.025),.065,.16,mats.cloth,0,Vector3(0,0,-.65),12)
	crown.ring(Vector3(0,1.88,-.015),.205,.026,mats.gold)
	crown.sphere(Vector3(.10,2.285,-.02),Vector3.ONE*.075,mats.gold,12)
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
	woven.set_shader_parameter("cloth_color",Color("ff715d") if identity=="knight" else Color("a653df"))
	cape_fabric=woven;fabric.material_override=woven;cape.add_child(fabric)
	Geo.segment(cape,Vector3(-width*.60,top,z),Vector3(-width*1.18,bottom,z-.42),.009,mats.gold)
	Geo.segment(cape,Vector3(width*.60,top,z),Vector3(width*1.18,bottom,z-.42),.009,mats.gold)

func animate(delta: float) -> void:
	clock+=delta
	if is_instance_valid(authored_mesh):
		blink_clock=fposmod(blink_clock+delta,4.1)
		var blink_amount:float=maxf(0.0,1.0-absf(blink_clock-3.75)/.085)
		authored_mesh.set_blend_shape_value(0,0.0 if reduced_motion else blink_amount)
		authored_mesh.set_blend_shape_value(1,0.0 if reduced_motion else sin(clock*5.5)*.55)
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
	if was_airborne and not airborne:landing_spring=.24
	was_airborne=airborne;landing_spring=maxf(0,landing_spring-delta)
	var spring:float=0 if reduced_motion else sin(landing_spring/.24*PI)*.11
	var bounce:float=0 if reduced_motion or not moving or airborne or sliding else absf(stride)*.075
	var squash:float=0 if reduced_motion or not moving or airborne or sliding else cos(clock*26*motion.locomotion_rate)*.025
	body.position.y=bounce+(0.0 if reduced_motion else sin(clock*2)*.014)+absf(cheer)*.16
	body.scale=Vector3(base_scale*1.12*(1+special*.10+spring-squash*.5),base_scale*.98*(1-special*.08-spring+squash),base_scale*1.12*(1+special*.10+spring-squash*.5))
	if is_instance_valid(cape_fabric):cape_fabric.set_shader_parameter("motion_amount",0.0 if reduced_motion else 1.0)
	body.rotation.y=facing+sin(attack_time/.4*PI)*swipe_direction*.24+cheer*.08
	body.rotation.x=lerpf(body.rotation.x,(-.12 if sliding else -.035 if moving else 0)+special*.08,1-exp(-delta*14))
	body.visible=not (identity=="witch" and traversal_left>.3 and traversal_left<.47)
	body.rotation.z=lerpf(body.rotation.z,-lean*.17,1-exp(-delta*10))
	for index in range(wings.size()):
		var sign_value:=1.0 if index==0 else -1.0
		wings[index].rotation.y=sign_value*((.08 if airborne or traversal_left>0 else 1.48 if sliding else 1.02)+sin(clock*(9 if airborne or traversal_left>0 else 4))*(.22 if airborne or traversal_left>0 else .12))
		wings[index].rotation.z=lerpf(wings[index].rotation.z,sign_value*-.32 if sliding else 0.0,1-exp(-delta*14))
	if is_instance_valid(cape): cape.rotation.x=0 if reduced_motion else sin(clock*7)*.045
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
