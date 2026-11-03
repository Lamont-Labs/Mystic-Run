extends Node3D

const Geo = preload("res://game/geometry.gd")
const WIDTH := 2.6
const CHUNK := 24.0
const PIECE_ORDER := [0,0,1,1,2,2,3,1,4,4,3,1]
const PIECE_NAMES := ["CATHEDRAL ARCADE","OPEN CROWN BRIDGE","RIBBED VAULT","RELIQUARY COURT","BROKEN WORKS"]
const PAINT = preload("res://assets/shaders/comic_world.gdshader")
const CourseProfile=preload("res://core/course_profile.gd")

var themes: Dictionary = {}
var chunks: Array[MeshInstance3D] = []
var current_theme: String = "knight"
var materials: Dictionary = {}
var machine: Node3D
var dust: MultiMeshInstance3D
var elapsed: float = 0.0
var course_bend: float = 0.0
var flat_course: bool = false
var city_layers: Array[MeshInstance3D] = []
var secret_theme:String=""
var secret_level:String=""
var reduced_motion:bool=false
var secret_meshes:Dictionary={}
var lanterns:Array[Node3D]=[]
var sky_props:Array[Node3D]=[]
var sky_birds:Array[Node3D]=[]


func _paint(hex: String, metal: float=0.0, glow: float=0.0) -> ShaderMaterial:
	var mat:=ShaderMaterial.new()
	mat.shader=PAINT
	mat.set_shader_parameter("paint",Color(hex))
	mat.set_shader_parameter("metal",metal)
	mat.set_shader_parameter("glow",glow)
	return mat


func configure() -> void:
	materials = {
		"cloud":_paint("fff9f2"),"stone":_paint("b4a0dc"),"pale":_paint("f7dfb8"),"dark":_paint("6466b2"),
		"metal":_paint("65b9d2",.35),"gold":_paint("ffce63",.24),
		"amber":_paint("ffcc4e",.10,.55),"teal":_paint("4ee3cc",.10,.70),
		"violet":_paint("c17aff",.10,.70),"red":_paint("ff6c7f",.10,.65),
		"roof":_paint("ff7e8b"),"grass":_paint("67d39a"),"leaves":_paint("99e79a"),"pink":_paint("ffadd6"),"void":_paint("599ac8"),"road":_paint("d9b58b"),"road_alt":_paint("d3ae83"),
	}
	materials.road.set_shader_parameter("pavement",true)
	materials.road_alt.set_shader_parameter("pavement",true)
	for kind in ["knight", "gargoyle", "witch"]:
		var pieces:Array[ArrayMesh]=[]
		for variant in range(PIECE_NAMES.size()):
			var template:MeshInstance3D=_chunk_mesh(kind,variant)
			pieces.append(template.mesh);template.free()
		themes[kind]=pieces
		for level in range(3):
			var chamber:MeshInstance3D=_secret_mesh(kind,level);secret_meshes[["citadel","spires","rift"][level]+"/"+kind]=chamber.mesh;chamber.free()
	for index in range(11):
		var node := MeshInstance3D.new()
		node.mesh = themes[current_theme][0]
		add_child(node)
		chunks.append(node)
		node.extra_cull_margin=35.0
	_build_horizon()
	_build_dust()
	_build_city_layers()
	_build_lanterns()
	_build_sky_props()


func _build_city_layers() -> void:
	# Rounded, candy-colored turrets and floating gardens frame the same course.
	for side in [-1.0,1.0]:
		for variant in range(3):
			var g=Geo.new();var x:float=side*(15.0+variant*5.5);var h:float=10.0+variant*5.0
			g.cylinder(Vector3(x,-4.2,0),4.0,5.0,materials.stone,1.45,Vector3.ZERO,12)
			g.cylinder(Vector3(x,-1.6,0),5.0,.55,materials.grass,1,Vector3.ZERO,20)
			g.cylinder(Vector3(x,h*.5-1.5,0),2.8,h,materials.pale,1,Vector3.ZERO,20)
			for tier in range(3):
				var y:float=.4+tier*h*.28
				g.cylinder(Vector3(x,y,0),2.95,.26,materials.gold,1,Vector3.ZERO,20)
				for offset in [-1.35,0.0,1.35]:
					g.armor(Vector3(x+offset,y+1.2,2.62),Vector3(.56,1.65,.15),materials.stone,.8)
					g.sphere(Vector3(x+offset,y+1.35,2.73),Vector3(.38,.9,.055),materials.amber,16)
			g.cylinder(Vector3(x,h-.2,0),3.35,4.5,materials.roof,0,Vector3.ZERO,20)
			g.ring(Vector3(x,h-2.4,0),3.28,.10,materials.gold)
			g.sphere(Vector3(x,h+2.15,0),Vector3.ONE*.48,materials.gold,16)
			g.cylinder(Vector3(x,h+3,0),.045,1.5,materials.gold,1,Vector3.ZERO,8)
			g.triangle(Vector3(x,h+3.7,0),Vector3(x+side*1.8,h+3.3,0),Vector3(x,h+2.95,0),materials.pink)
			for tree in range(2):
				var at:=Vector3(x+side*(3.5+tree*.65),-.8,1.6-tree*3)
				g.cylinder(at+Vector3(0,1,0),.18,2.5,materials.gold,1,Vector3(0,0,side*.14),10)
				g.sphere(at+Vector3(0,2.8,0),Vector3(3,2.6,2.8),materials.leaves,16)
				g.sphere(at+Vector3(.8,3.1,.3),Vector3(1.7,1.6,1.7),materials.grass,16)
			var template:MeshInstance3D=g.build()
			for repeat in range(3):
				var node:=MeshInstance3D.new();node.mesh=template.mesh;node.extra_cull_margin=50
				node.set_meta("offset",variant*40+repeat*120+(18 if side>0 else 0));add_child(node);city_layers.append(node)
			template.free()

func _arch(geo: RefCounted, z: float, width: float, height: float, mat: Material, radius: float=.13) -> void:
	var points: Array[Vector3]=[]
	for i in range(17):
		var t:=float(i)/16
		var x:=lerpf(-width,width,t)
		var y:=height*sqrt(maxf(0.0,1.0-pow(t*2-1,2.0)))
		points.append(Vector3(x,3.2+y,z))
	for i in range(points.size()-1):
		var a:=points[i]
		var b:=points[i+1]
		var direction:=b-a
		geo.cylinder((a+b)*.5,radius,direction.length(),mat,1,Vector3(0,0,-atan2(direction.x,direction.y)),8)


func _deck(b:RefCounted) -> void:
	# Subdivide the decorative deck so its terrain warp follows the paving.
	# A single 24 m face cut through the tiles on curved climbs and descents.
	for strip in range(16):
		b.box(Vector3(0,-.44,-.75-strip*1.5),Vector3(9.4,.72,1.5),materials.stone)


func _chunk_mesh(kind: String, variant:int=0) -> MeshInstance3D:
	var b=Geo.new()
	var accent: Material=materials[{"knight":"amber","gargoyle":"teal","witch":"violet"}[kind]]
	_deck(b)
	for row in range(8):
		var z: float=-1.5-row*3.0
		for column in range(3):
			b.armor(Vector3((column-1)*3.0,.006,z),Vector3(2.97,.07,2.97),materials.road if (row+column)%2==0 else materials.road_alt,.995)
		# Tiny central inlays show speed without covering the obstacle lanes.
		b.box(Vector3(0,.049,z),Vector3(.04,.009,.42),materials.gold)
	for side in [-1.0,1.0]:
		for z in [-1.0,-7.0,-13.0,-19.0]:
			b.armor(Vector3(side*4.9,-1.4,z),Vector3(.7,2.7,1.2),materials.stone,.8)
			b.box(Vector3(side*3.4,-1.55,z),Vector3(3.0,.34,.55),materials.dark,Vector3(0,0,side*.25))
			b.armor(Vector3(side*4.20,.075,z),Vector3(.34,.06,.62),materials.gold)
		for z in [-5.0,-17.0]:
			b.cylinder(Vector3(side*5.16,2.15,z),.07,4.3,materials.metal,1.0,Vector3.ZERO,8)
			b.armor(Vector3(side*5.16,3.70,z),Vector3(.42,.67,.42),materials.dark)
			b.armor(Vector3(side*5.16,3.70,z),Vector3(.30,.46,.30),accent)
			b.cylinder(Vector3(side*5.16,4.16,z),.23,.48,materials.gold,0.0,Vector3.ZERO,6)
		b.box(Vector3(side*4.48,.10,-12),Vector3(.055,.055,24),accent)
		b.box(Vector3(side*4.73,-.04,-12),Vector3(.43,.50,24),materials.metal)
		for z in [-3.0,-9.0,-15.0,-21.0]:
			b.armor(Vector3(side*4.74,.53,z),Vector3(.23,1.14,.28),materials.gold,.75)
			b.box(Vector3(side*4.74,.88,z-1.4),Vector3(.06,.07,3.0),materials.metal)
		if kind=="knight" and variant not in [1,3]:
			b.armor(Vector3(side*5.90,3.25,-12),Vector3(.90,6.5,1.5),materials.stone,.85)
			b.armor(Vector3(side*5.90,.25,-12),Vector3(1.55,.50,2.0),materials.metal)
			b.armor(Vector3(side*5.90,6.5,-12),Vector3(1.20,.35,1.6),materials.gold)
			for xoff in [-.22,.22]: b.box(Vector3(side*5.90+xoff,3.4,-11.22),Vector3(.035,4.7,.028),accent)
			b.cylinder(Vector3(side*5.9,8.0,-12),.52,3.0,materials.roof,0,Vector3.ZERO,16)
			b.armor(Vector3(side*8.0,3.1,-12),Vector3(.5,6.4,1.0),materials.pale,.85)
			# Rounded castle vaults remain open enough to read the sky and hazards.
			b.box(Vector3(side*6.9,4.1,-12),Vector3(.32,5.3,.5),materials.pale,Vector3(0,0,-side*.40))
		elif kind=="gargoyle" and variant!=1:
			b.cylinder(Vector3(side*6.6,-3.5,-12),1.9,7.5,materials.dark,.28,Vector3.ZERO,7)
			b.cylinder(Vector3(side*6.6,2.6,-12),.45,5.2,materials.pale,.75,Vector3.ZERO,12)
			b.ring(Vector3(side*6.6,5.4,-12),.95,.035,accent)
			b.cylinder(Vector3(side*6.6,6.6,-12),.65,2.4,materials.dark,0,Vector3.ZERO,6)
			b.cylinder(Vector3(side*10.2,1.0,-6),1.1,5.0,materials.stone,.35,Vector3(0,0,side*.16),7)
		elif kind=="witch" and variant!=1:
			b.cylinder(Vector3(side*6.6,2.5,-12),.72,4.4,materials.stone,.2,Vector3(0,0,side*.22),6)
			b.ring(Vector3(side*6.6,4.2,-12),1.1,.045,accent,Vector3(.8,0,side*.30))
			b.ring(Vector3(side*6.6,4.2,-12),1.4,.02,materials.gold,Vector3(.8,0,side*.30))
			b.cylinder(Vector3(side*6.6,.6,-12),.75,1.4,materials.gold,.20,Vector3(PI,0,0),6)
	if kind=="knight" and variant==0:
		_arch(b,-12,5.9,6.8,materials.pale,.22)
		_arch(b,-11.7,5.9,6.7,materials.gold,.055)
	if kind=="witch":
		b.ring(Vector3(0,.053,-12),1.7,.016,accent)
		b.ring(Vector3(0,.054,-12),2.0,.012,materials.gold)
	_decorate_piece(b,variant,accent)
	return b.build()


func _decorate_piece(b:RefCounted,variant:int,accent:Material) -> void:
	# All pieces share the same 24 m deck, width and elevation contract.
	# Architecture changes the silhouette without entering the playable corridor.
	match variant:
		1: # Open bridge: low parapets and a view across the city.
			for side in [-1.0,1.0]:
				for z in [-2.0,-22.0]:
					b.armor(Vector3(side*5.8,1.4,z),Vector3(1.6,2.8,1.6),materials.stone,.72)
					b.cylinder(Vector3(side*5.8,3.2,z),.44,.8,accent,.16,Vector3.ZERO,8)
				b.box(Vector3(side*6.5,-1.5,-12),Vector3(.7,1.0,24),materials.dark)
		2: # Ribbed nave: three vaults create a legible interior rhythm.
			for z in [-3.0,-12.0,-21.0]:
				_arch(b,z,7.4,6.0,materials.pale,.20)
				_arch(b,z+.25,7.4,5.8,materials.gold,.045)
				for side in [-1.0,1.0]:
					b.armor(Vector3(side*7.4,1.6,z),Vector3(.7,3.2,.9),materials.stone,.8)
			b.box(Vector3(0,9.25,-12),Vector3(.32,.22,24),materials.gold)
		3: # Reliquary court: flank the route with raised, ringed shrines.
			for side in [-1.0,1.0]:
				b.cylinder(Vector3(side*7.4,-.1,-12),3.1,.7,materials.dark,1,Vector3.ZERO,12)
				b.cylinder(Vector3(side*7.4,1.2,-12),1.8,2.0,materials.stone,.45,Vector3.ZERO,10)
				b.cylinder(Vector3(side*7.4,2.8,-12),.65,2.4,materials.pale,.02,Vector3.ZERO,6)
				b.ring(Vector3(side*7.4,3.8,-12),1.8,.055,accent,Vector3(PI/2,0,0))
				b.ring(Vector3(side*7.4,3.8,-12),2.1,.025,materials.gold,Vector3(PI/2,0,0))
		4: # Broken works: asymmetric outside structures frame the descent.
			for side in [-1.0,1.0]:
				var h:float=6.8 if side<0 else 10.2
				b.armor(Vector3(side*7.2,h*.5,-6),Vector3(2.2,h,3.0),materials.dark,.74)
				for tier in range(3):
					b.box(Vector3(side*7.2,1.2+tier*2.4,-4.45),Vector3(1.7,.08,.08),accent)
				b.box(Vector3(side*8.3,5.2,-15),Vector3(1.0,5.3,4.0),materials.stone,Vector3(0,0,side*.24))
				b.cylinder(Vector3(side*6.5,8.1,-17),.48,4.0,materials.metal,.16,Vector3(0,0,side*.35),8)


func set_theme(kind: String) -> void:
	if kind == current_theme:
		return
	current_theme = kind
	for chunk in chunks:
		chunk.mesh = themes[kind][int(chunk.get_meta("variant",0))]


func update(distance: float, delta: float) -> void:
	elapsed += delta
	course_bend=sin(distance/145.0)*2.2
	for mat in materials.values():
		mat.set_shader_parameter("bend",course_bend)
		mat.set_shader_parameter("course_distance",distance)
		mat.set_shader_parameter("flat_course",flat_course)
	var offset := fposmod(distance, CHUNK)
	for index in range(chunks.size()):
		chunks[index].position.z = 24.0 + offset - index * CHUNK
		var piece:int=floori((distance-chunks[index].position.z)/CHUNK)
		var variant:int=PIECE_ORDER[posmod(piece,PIECE_ORDER.size())]
		if int(chunks[index].get_meta("variant",-1))!=variant:
			chunks[index].mesh=themes[current_theme][variant]
			chunks[index].set_meta("variant",variant)
			chunks[index].set_meta("piece_name",PIECE_NAMES[variant])
		var secret_key:String=secret_level+"/"+secret_theme
		var intended:Mesh=secret_meshes[secret_key] if secret_meshes.has(secret_key) else themes[current_theme][variant]
		if chunks[index].mesh!=intended:chunks[index].mesh=intended
	for i in range(lanterns.size()):
		lanterns[i].position.z=14-fposmod(i*19.0-distance*.8,160.0)
		lanterns[i].position.y=5.5+(i%3)*1.8+(0.0 if reduced_motion else sin(elapsed*1.4+i)*.45)
		lanterns[i].rotation.z=0 if reduced_motion else sin(elapsed*1.8+i)*.12
	for prop in sky_props:
		var i:int=prop.get_meta("index")
		prop.position.z=-24.0-fposmod(i*37.0-distance*.25,210.0)
		prop.position.y=12.0+(i%3)*4.0+(0.0 if reduced_motion else sin(elapsed*.9+i)*.65)
		prop.rotation.z=0.0 if reduced_motion else sin(elapsed*1.2+i)*.055
	for i in range(sky_birds.size()):
		var bird:Node3D=sky_birds[i]
		var t:float=0.0 if reduced_motion else elapsed
		bird.position=Vector3(sin(t*.12+i*1.7)*24,18+(i%3)*3+sin(t*1.2+i)*.3,-55-i*17)
		bird.rotation.z=sin(t*5.0+i)*.15
	for building in city_layers:
		building.position.z=42.0+fposmod(distance,360.0)-float(building.get_meta("offset"))
		if building.position.z>55:building.position.z-=360.0
	if is_instance_valid(machine):
		machine.rotation.z = sin(elapsed * 0.08) * 0.12
		machine.rotation.y = elapsed * 0.02
	if is_instance_valid(dust):
		for index in range(dust.multimesh.instance_count):
			var at := Vector3(sin(index * 21.7) * 8.0, 0.5 + fposmod(index * 1.79 + elapsed * 0.10, 6.5), 12.0 - fposmod(index * 7.23 - distance * 0.7, 110.0))
			dust.multimesh.set_instance_transform(index, Transform3D(Basis(), at))


func _build_horizon() -> void:
	var b = Geo.new()
	# A distant painted city plate supplies architectural detail and cloud layers;
	# nearby arches, road, props, characters and effects are rendered in 3D.
	var plate:=MeshInstance3D.new()
	var quad:=QuadMesh.new()
	quad.size=Vector2(360,540)
	plate.mesh=quad
	var matte:=StandardMaterial3D.new()
	matte.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	matte.disable_fog=true
	matte.albedo_texture=load("res://assets/environment/cloud-castle-v2.jpg")
	matte.albedo_color=Color.WHITE
	plate.material_override=matte
	plate.position=Vector3(0,-20,-235)
	add_child(plate)
	machine = Node3D.new()
	machine.position = Vector3(0, 39, -170)
	add_child(machine)
	var rings = Geo.new()
	rings.ring(Vector3.ZERO, 15.0, 0.45, materials["gold"], Vector3(PI / 2, 0.35, 0))
	rings.ring(Vector3.ZERO, 12.4, 0.13, materials["amber"], Vector3(PI / 2, -0.25, 0.35))
	rings.ring(Vector3.ZERO, 8.3, 0.28, materials["dark"], Vector3(PI / 2, -0.25, 0.35))
	for index in range(12):
		var angle := index * TAU / 12
		rings.box(Vector3(sin(angle) * 15.0, cos(angle) * 15.0, 0), Vector3(1.0, 2.0, 0.8), materials["pale"], Vector3(0, 0, -angle))
	rings.sphere(Vector3.ZERO, Vector3.ONE * 3.7, materials["teal"])
	machine.add_child(rings.build())



func _build_dust() -> void:
	dust = MultiMeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.018
	mesh.height = 0.036
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = materials["amber"]
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = 45
	dust.multimesh = multi
	add_child(dust)


func set_gaps(rows: Array[Dictionary], distance: float) -> void:
	var openings:=PackedVector4Array()
	for row in rows:
		if row.kind=="gap" and float(row.at)-distance<120 and float(row.at)-distance> -18:
			openings.append(Vector4((int(row.lane)-1)*WIDTH,distance-float(row.at),1.23,1.76))
			if openings.size()==12:break
	var count:=openings.size()
	while openings.size()<12:openings.append(Vector4.ZERO)
	for mat in materials.values():
		mat.set_shader_parameter("gap_count",count)
		mat.set_shader_parameter("gaps",openings)


func update_labels(node: Node3D) -> void:
	for child in node.get_children():
		if child is Label3D:
			var bend_at:=clampf((-node.position.z-8)/70.0,0,2.6)
			child.position.x=float(child.get_meta("lane_x"))+course_bend*bend_at*bend_at


func prop(kind: String) -> Node3D:
	if kind=="enemy":
		var enemy=preload("res://game/hero.gd").new()
		enemy.configure("knight")
		enemy.sentinel()
		return enemy
	var root := Node3D.new()
	var b = Geo.new()
	match kind:
		"drone":
			b.sphere(Vector3(0, 1.5, 0), Vector3(0.9, 0.6, 0.7), materials["metal"])
			b.sphere(Vector3(0, 1.5, 0.36), Vector3(0.34, 0.24, 0.08), materials["red"])
			b.ring(Vector3(0, 1.5, 0), 0.70, 0.06, materials["gold"], Vector3(0.25, 0, 0.1))
			b.cylinder(Vector3(0, 1.0, 0), 0.22, 0.35, materials["red"], 0.0)
		"barrier":
			b.armor(Vector3(0, 0.55, 0), Vector3(2.05, 1.10, 0.65), materials["roof"],.86)
			b.box(Vector3(0, 1.13, 0), Vector3(2.1, 0.07, 0.7), materials["red"])
			for side in [-1.0, 1.0]:
				b.cylinder(Vector3(side * 0.65, 1.36, 0), 0.12, 0.5, materials["metal"], 0.0)
		"beam":
			for side in [-1.0, 1.0]:
				b.box(Vector3(side * 1.08, 1.1, 0), Vector3(0.18, 2.2, 0.4), materials["metal"])
			b.box(Vector3(0, 1.48, 0), Vector3(2.3, 0.35, 0.55), materials["dark"])
			b.box(Vector3(0, 1.28, 0.28), Vector3(2.0, 0.05, 0.04), materials["red"])
		"gap":
			# The world shader opens the actual road surface. These are the rims.
			for side in [-1.0,1.0]:
				b.armor(Vector3(0,-.08,side*1.86),Vector3(2.48,.26,.22),materials.pale,.70)
				b.box(Vector3(0,.07,side*1.87),Vector3(2.47,.05,.07),materials.red)
				b.box(Vector3(side*1.25,-.06,0),Vector3(.09,.21,3.7),materials.dark)
		"shard":
			_star(b,Vector3(0,1.02,0),.28,materials.amber)
			b.ring(Vector3(0,1.02,0),.38,.02,materials.gold,Vector3(PI/2,0,0))
		"artifact":
			b.armor(Vector3(0,.8,0),Vector3(.85,.65,.65),materials.gold,.85)
			b.armor(Vector3(0,1.16,0),Vector3(.95,.16,.75),materials.teal,.82)
			_star(b,Vector3(0,1.65,0),.48,materials.amber)
			b.ring(Vector3(0,1.65,0),.65,.035,materials.violet,Vector3(PI/2,0,0))
		"gate":
			for index in range(3):
				var x := (index - 1) * WIDTH
				var color: Material = materials[["teal", "amber", "violet"][index]]
				for side in [-1.0, 1.0]:
					b.box(Vector3(x + side * 1.15, 1.8, 0), Vector3(0.20, 3.6, 0.6), materials["dark"])
					b.box(Vector3(x + side * 1.15, 1.8, 0.32), Vector3(0.05, 3.4, 0.03), color)
				b.box(Vector3(x, 3.6, 0), Vector3(2.5, 0.2, 0.6), materials["metal"])
				b.ring(Vector3(x, 4.05, 0), 0.30, 0.025, color, Vector3(PI / 2, 0, 0))
				var label := Label3D.new()
				label.text = ["GARGOYLE", "KNIGHT", "WITCH"][index]
				label.font = load("res://assets/fonts/manrope.ttf")
				label.font_size = 48
				label.pixel_size = 0.006
				label.modulate = [Color("8ce5df"), Color("efd09b"), Color("d8bcff")][index]
				label.position = Vector3(x, 3.20, 0.36)
				label.set_meta("lane_x",x)
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				root.add_child(label)
	root.add_child(b.build())
	for child in root.get_children():
		if child is MeshInstance3D:child.extra_cull_margin=35.0
	return root


func _secret_mesh(kind:String,level:int=0) -> MeshInstance3D:
	var b=Geo.new();var glow:Material=materials[{"knight":"amber","gargoyle":"teal","witch":"violet"}[kind]]
	_deck(b)
	for row in range(8):
		for col in range(3):b.armor(Vector3((col-1)*3.0,0,-1.5-row*3),Vector3(2.97,.08,2.97),materials.road,.98)
	for side in [-1.0,1.0]:
		b.box(Vector3(side*4.5,.06,-12),Vector3(.10,.10,24),glow)
		if kind=="knight":
			b.armor(Vector3(side*6.2,3.4,-12),Vector3(1.4,6.8,24),materials.stone,.92)
			for z in [-4.0,-16.0]:
				b.ring(Vector3(side*5.4,4.8,z),2,.22,materials.gold,Vector3(0,0,PI/2))
				b.ring(Vector3(side*5.35,4.8,z),1.55,.045,glow,Vector3(0,0,PI/2))
				for tooth in range(12):
					var a:float=TAU*tooth/12;b.box(Vector3(side*5.4,4.8+cos(a)*2.1,z+sin(a)*2.1),Vector3(.4,.5,.45),materials.gold,Vector3(a,0,0))
		elif kind=="gargoyle":
			for z in [-4.0,-16.0]:
				b.cylinder(Vector3(side*7.2,1,z),2.4,2.5,materials.pale,.5,Vector3(PI,0,0),8)
				b.ring(Vector3(side*7.2,2.4,z),2,.05,glow)
				for cloud in range(3):b.sphere(Vector3(side*(6.0+cloud*.7),3+sin(cloud)*.3,z),Vector3(1.8,1,1.8),materials.cloud,12)
				b.cylinder(Vector3(side*7.2,5,z),.25,4,materials.gold,0,Vector3.ZERO,6)
		else:
			for z in [-3.0,-11.0,-19.0]:
				b.cylinder(Vector3(side*6.3,1.2,z),.10,2.4,materials.metal)
				b.sphere(Vector3(side*6.3,2.7,z),Vector3(.8,1,.8),glow,12)
				b.ring(Vector3(side*6.3,2.8,z),.8,.05,materials.gold,Vector3(.4,0,0))
				b.cylinder(Vector3(side*6.3,4.2,z),.5,1.8,materials.pale,0,Vector3.ZERO,6)
			b.ring(Vector3(side*7,6,-12),2.5,.12,glow,Vector3(PI/2,0,0))
	if kind=="knight":
		for z in [-2.0,-14.0]:_arch(b,z,6.2,5.8,materials.gold,.18)
	elif kind=="gargoyle":_arch(b,-12,8.5,8,glow,.09)
	else:b.ring(Vector3(0,.06,-12),3.4,.04,glow);b.ring(Vector3(0,.07,-12),2.7,.025,materials.gold)
	_decorate_secret_level(b,kind,level,glow)
	return b.build()

func _build_lanterns() -> void:
	for index in range(9):
		var b=Geo.new();var colour:Material=materials[["teal","amber","violet"][index%3]]
		b.sphere(Vector3.ZERO,Vector3(.60,.88,.60),colour,12);b.cylinder(Vector3(0,-.5,0),.15,.18,materials.gold)
		b.cylinder(Vector3(0,-.78,0),.016,.45,materials.gold);b.ring(Vector3.ZERO,.34,.025,materials.gold,Vector3(.2,0,.2))
		var node:Node3D=b.build();node.position.x=(-1.0 if index%2 else 1.0)*(8.0+index%3*2.3)
		add_child(node);lanterns.append(node)

func secret_portal(hero:String,unlocked:bool) -> Node3D:
	var b=Geo.new();var root:=Node3D.new()
	var light:Material=materials[{"knight":"amber","gargoyle":"teal","witch":"violet"}[hero]] if unlocked else materials.metal
	for side in [-1.0,1.0]:
		b.armor(Vector3(side*1.03,1.5,0),Vector3(.24,3,.38),materials.gold,.85);b.sphere(Vector3(side*1.03,3.12,0),Vector3.ONE*.40,light)
	b.ring(Vector3(0,1.7,0),1.08,.075,light,Vector3(PI/2,0,0));b.ring(Vector3(0,1.7,0),1.23,.025,materials.gold,Vector3(PI/2,0,0));root.add_child(b.build())
	var label:=Label3D.new();label.text="SECRET!" if unlocked else "LOCKED";label.font=load("res://assets/fonts/bangers.ttf");label.font_size=52;label.pixel_size=.008
	label.position=Vector3(0,3.7,0);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("ffe6a0") if unlocked else Color("c3cbdb");root.add_child(label)
	return root

func _star(b:RefCounted,at:Vector3,radius:float,material:Material) -> void:
	for side in [-1.0,1.0]:
		for i in range(10):
			var a:float=TAU*i/10;var c:float=TAU*(i+1)/10;var r0:float=radius if i%2==0 else radius*.45;var r1:float=radius if (i+1)%2==0 else radius*.45
			var first:Vector3=at+Vector3(sin(a)*r0,cos(a)*r0,0);var second:Vector3=at+Vector3(sin(c)*r1,cos(c)*r1,0);var centre:Vector3=at+Vector3(0,0,side*radius*.25)
			if side>0:b.triangle(second,first,centre,material)
			else:b.triangle(first,second,centre,material)

func _decorate_secret_level(b:RefCounted,kind:String,level:int,glow:Material) -> void:
	# Each character/level pair has its own authored mesh and physical treasure ID.
	if level==0:
		for side in [-1.0,1.0]:
			for z in [-2.0,-22.0]:
				b.armor(Vector3(side*8.4,4,z),Vector3(1.5,8,1.4),materials.pale,.82)
				if kind=="gargoyle":
					b.cylinder(Vector3(side*7.0,5.2,z),.8,1.2,materials.gold,.55,Vector3.ZERO,10)
					b.sphere(Vector3(side*7.0,4.5,z),Vector3.ONE*.25,glow)
				elif kind=="witch":
					for shelf in range(4):
						b.box(Vector3(side*7.0,1.1+shelf*.9,z),Vector3(1.5,.12,1.3),materials.gold)
						for book in range(4):b.box(Vector3(side*7.0+(book-1.5)*.25,1.4+shelf*.9,z),Vector3(.16,.55,.8),glow if book%2 else materials.pale)
	else:
		var accent:Material=materials.teal if level==1 else materials.violet
		for side in [-1.0,1.0]:
			for z in [-4.0,-12.0,-20.0]:
				b.cylinder(Vector3(side*9.5,1.4,z),1.4,3,materials.pale,0,Vector3(PI,0,0),5)
				b.ring(Vector3(side*9.5,3.4,z),1.4,.08,accent,Vector3(PI/2,0,.35 if level==1 else -.35))
		if level==1:
			b.ring(Vector3(0,9.4,-12),2.7,.12,materials.gold,Vector3(PI/2,0,0))
			_star(b,Vector3(0,9.4,-12),1.2,glow)
		else:
			b.ring(Vector3(0,8.6,-12),3.2,.13,accent,Vector3(PI/2,0,0))
			b.ring(Vector3(0,8.6,-12),2.6,.04,materials.gold,Vector3(PI/2,0,0))
			for star in range(5):_star(b,Vector3((star-2)*1.3,7.6+sin(star)*.4,-12),.35,glow)


func _build_sky_props() -> void:
	# Decorative meshes stay outside the playable corridor and never own collision.
	for index in range(6):
		var g=Geo.new();var colour:Material=materials[["pink","teal","roof"][index%3]]
		g.sphere(Vector3.ZERO,Vector3(2.6,3.1,2.6),colour,20)
		g.ring(Vector3(0,-.25,0),1.28,.075,materials.gold)
		for side in [-1.0,1.0]:g.cylinder(Vector3(side*.42,-1.8,0),.035,1.6,materials.gold)
		g.armor(Vector3(0,-2.35,0),Vector3(1.15,.62,.86),materials.pale,.92)
		var balloon:Node3D=g.build();balloon.position.x=(-1 if index%2 else 1)*(16+index%3*7)
		balloon.set_meta("index",index);add_child(balloon);sky_props.append(balloon)
	for i in range(6):
		var g=Geo.new()
		g.triangle(Vector3.ZERO,Vector3(-.75,.22,.1),Vector3(-.22,.04,-.12),materials.cloud)
		g.triangle(Vector3.ZERO,Vector3(.22,.04,-.12),Vector3(.75,.22,.1),materials.cloud)
		var bird:Node3D=g.build();add_child(bird);sky_birds.append(bird)
