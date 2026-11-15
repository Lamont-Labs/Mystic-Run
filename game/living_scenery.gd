extends Node3D
## Prebuilt, bounded, non-colliding biome landmarks and parallax layers.
const Geo=preload("res://game/geometry.gd")
const Course=preload("res://core/course_profile.gd")
const Biomes=preload("res://core/biome_progression.gd")
const POOL=12
const SPACING=32.0
const PAINTED_LANDMARKS=[
preload("res://assets/environment/living-world/castle_landmark.png"),
preload("res://assets/environment/living-world/wilds_landmark.png"),
preload("res://assets/environment/living-world/ember_landmark.png")]
var nodes:Array[Node3D]=[]
var paintings:Array[Sprite3D]=[]
var meshes:Array[ArrayMesh]=[]

func material(color:String,emission:float=0) -> StandardMaterial3D:
	var result:=StandardMaterial3D.new()
	result.albedo_color=Color(color)
	result.roughness=.85
	result.emission_enabled=emission>0
	result.emission=Color(color)
	result.emission_energy_multiplier=emission
	return result

func configure() -> void:
	for biome in range(3):
		for variant in range(3):
			meshes.append(_landmark(biome,variant))
	for i in range(POOL):
		var node:=MeshInstance3D.new()
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		nodes.append(node)
		# Textured 2D landmarks replace the exposed primitive silhouettes.
		node.layers=0
		var painting:=Sprite3D.new()
		painting.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		painting.shaded=false
		painting.double_sided=true
		painting.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		painting.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(painting)
		paintings.append(painting)

func _landmark(biome:int,variant:int) -> ArrayMesh:
	var g=Geo.new()
	var stone=material(["b6a88e","5d7867","453d49"][biome])
	var trim=material(["e8c77c","5dba9a","e17e4e"][biome],.12)
	var dark=material(["6b617f","344c43","2d2937"][biome])
	var leaf=material("426d52")
	var glow=material(["f9dc8a","78e8cc","ff853d"][biome],.65)
	var banner=material(["794252","327e70","a34e39"][biome])
	if biome==0:
		for side in [-1.0,1.0]:
			g.cylinder(Vector3(side*1.7,4.5,0),1.3,9,stone,.85,Vector3.ZERO,16)
			for tier in range(4):
				g.cylinder(Vector3(side*1.7,1.5+tier*2.1,0),1.36,.16,trim,1,Vector3.ZERO,16)
			g.cylinder(Vector3(side*1.7,10,0),1.6,3, dark,0,Vector3.ZERO,16)
			for window in range(3):
				g.armor(Vector3(side*1.7,2+window*2.2,.99),Vector3(.35,.9,.15),glow,.75)
			g.box(Vector3(side*.8,6.7,.5),Vector3(1.3,2.2,.09),banner,Vector3(0,0,side*.09))
			for merlon in range(5):
				g.armor(Vector3(side*1.7+cos(merlon*TAU/5)*1.25,9.3,sin(merlon*TAU/5)*1.25),Vector3(.4,.6,.4),trim)
		g.armor(Vector3(0,.1,0),Vector3(6,.3,5),stone)
	elif biome==1:
		for trunk in range(3):
			var x:float=(trunk-1)*2.4
			var height:float=8+variant+trunk
			g.cylinder(Vector3(x,height*.5,0),.65,height,dark,.45,Vector3(0,0,.08*(trunk-1)),12)
			for crown in range(3):
				g.sphere(Vector3(x+(crown-1)*1.8,height+crown*.8,-crown),Vector3(3.7,2.4,3.8),leaf,12)
			for root in range(4):
				g.cylinder(Vector3(x+cos(root*TAU/4),.1,sin(root*TAU/4)),.28,2.8,dark,.6,Vector3(0,0,.9),8)
		for plant in range(7):
			var x:float=sin(plant*2.7)*3
			var z:float=cos(plant*2.7)*2
			g.cylinder(Vector3(x,.45,z),.08,.9,trim,.6,Vector3.ZERO,6)
			g.sphere(Vector3(x,.9,z),Vector3(.7,.23,.7),glow,10)
		# Waterfall ribbons stay outside the playable corridor and flow visually.
		var water=material("77cfc9",.08)
		for ribbon in range(3):
			g.box(Vector3(-2+ribbon*.45,-3,1.7),Vector3(.35,7,.14),water)
	else:
		for pillar in range(3):
			var h:float=4+pillar*1.8+variant*.6
			g.cylinder(Vector3((pillar-1)*2.2,h*.5,0),.85,h,stone,.72,Vector3(0,0,.13*(pillar-1)),8)
			for band in range(3):
				g.cylinder(Vector3((pillar-1)*2.2,1+band*1.4,0),.91,.16,trim,1,Vector3.ZERO,8)
		for crystal in range(6):
			var a:float=crystal*2.4
			g.cylinder(Vector3(sin(a)*3,1.0+crystal*.15,cos(a)*2),.3,2+crystal*.3,glow,0,Vector3(.15,0,sin(a)*.3),5)
		g.armor(Vector3(0,-.6,0),Vector3(6,.6,5),dark)
		g.box(Vector3(0,-.2,0),Vector3(4.7,.08,3.5),glow)
	var node:MeshInstance3D=g.build()
	var result:ArrayMesh=node.mesh
	node.free()
	return result

func advance(distance:float,clock:float,flat:bool,reduced:bool,enabled:bool) -> void:
	for i in range(nodes.size()):
		var node:MeshInstance3D=nodes[i]
		var z:float=24-fposmod(i*SPACING-distance,POOL*SPACING)
		var station:float=maxf(0,distance-z)
		var state:Dictionary=Biomes.sample(station)
		var variant:int=posmod(floori(station/SPACING)*7+i,3)
		node.mesh=meshes[int(state.index)*3+variant]
		var side:float=-1 if i%2==0 else 1
		var lateral:float=0 if flat else Course.lateral_at(station,distance)
		var height:float=0 if flat else Course.height_at(station)
		node.position=Vector3(side*(12.5+(i%3)*3.1)+lateral,height-1,z)
		node.rotation.y=side*(.12+(i%3)*.19)
		node.scale=Vector3.ONE*(.9+(i%3)*.12)
		node.visible=enabled and z> -240
		var painting:Sprite3D=paintings[i]
		painting.texture=PAINTED_LANDMARKS[int(state.index)]
		var art_height:float=12.0+variant*1.5
		painting.pixel_size=art_height/float(painting.texture.get_height())
		painting.position.y=art_height*.5
		painting.flip_h=i%2==0
		painting.modulate=Color(1,1,1) if i%3==0 else Color(.83,.90,.92)
		if not reduced and state.index==1:
			node.position.y+=sin(clock*.7+i)*.05
