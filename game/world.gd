extends Node3D

const Geo = preload("res://game/geometry.gd")
const WIDTH := 2.6
const CHUNK := 24.0
const PAINT = preload("res://assets/shaders/comic_world.gdshader")

var themes: Dictionary = {}
var chunks: Array[MeshInstance3D] = []
var current_theme: String = "knight"
var materials: Dictionary = {}
var machine: Node3D
var dust: MultiMeshInstance3D
var elapsed: float = 0.0
var course_bend: float = 0.0


func _paint(hex: String, metal: float=0.0, glow: float=0.0) -> ShaderMaterial:
	var mat:=ShaderMaterial.new()
	mat.shader=PAINT
	mat.set_shader_parameter("paint",Color(hex))
	mat.set_shader_parameter("metal",metal)
	mat.set_shader_parameter("glow",glow)
	return mat


func configure() -> void:
	materials = {
		"stone":_paint("292a48"),"pale":_paint("4c4a6b"),"dark":_paint("141c32"),
		"metal":_paint("4b5471",.35),"gold":_paint("ac8957",.30),
		"amber":_paint("eea556",.10,.55),"teal":_paint("4cb5ca",.10,.70),
		"violet":_paint("a064e5",.10,.70),"red":_paint("f36779",.10,.65),
		"void":_paint("080b1c"),"road":_paint("414663"),"road_alt":_paint("494b68"),
	}
	for kind in ["knight", "gargoyle", "witch"]:
		var template: MeshInstance3D = _chunk_mesh(kind)
		themes[kind] = template.mesh
		template.free()
	for index in range(11):
		var node := MeshInstance3D.new()
		node.mesh = themes[current_theme]
		add_child(node)
		chunks.append(node)
	_build_horizon()
	_build_dust()


func _arch(geo: RefCounted, z: float, width: float, height: float, mat: Material, radius: float=.13) -> void:
	var points: Array[Vector3]=[]
	for i in range(17):
		var t:=float(i)/16
		var x:=lerpf(-width,width,t)
		var y:=height*(1.0-pow(absf(t*2-1),.60))
		points.append(Vector3(x,3.2+y,z))
	for i in range(points.size()-1):
		var a:=points[i]
		var b:=points[i+1]
		var direction:=b-a
		geo.cylinder((a+b)*.5,radius,direction.length(),mat,1,Vector3(0,0,-atan2(direction.x,direction.y)),8)


func _chunk_mesh(kind: String) -> MeshInstance3D:
	var b=Geo.new()
	var accent: Material=materials[{"knight":"amber","gargoyle":"teal","witch":"violet"}[kind]]
	b.box(Vector3(0,-.38,-12),Vector3(9.4,.72,24),materials.dark)
	for row in range(8):
		var z: float=-1.5-row*3.0
		for column in range(3):
			b.armor(Vector3((column-1)*3.0,.006,z),Vector3(2.97,.07,2.97),materials.road if (row+column)%2==0 else materials.road_alt,.995)
		# Tiny central inlays show speed without covering the obstacle lanes.
		b.box(Vector3(0,.049,z),Vector3(.04,.009,.42),materials.gold)
	for side in [-1.0,1.0]:
		b.box(Vector3(side*4.48,.10,-12),Vector3(.055,.055,24),accent)
		b.box(Vector3(side*4.73,-.04,-12),Vector3(.43,.50,24),materials.metal)
		for z in [-3.0,-9.0,-15.0,-21.0]:
			b.armor(Vector3(side*4.74,.53,z),Vector3(.23,1.14,.28),materials.gold,.75)
			b.box(Vector3(side*4.74,.88,z-1.4),Vector3(.06,.07,3.0),materials.metal)
		if kind=="knight":
			b.armor(Vector3(side*5.90,3.25,-12),Vector3(.90,6.5,1.5),materials.stone,.85)
			b.armor(Vector3(side*5.90,.25,-12),Vector3(1.55,.50,2.0),materials.metal)
			b.armor(Vector3(side*5.90,6.5,-12),Vector3(1.20,.35,1.6),materials.gold)
			for xoff in [-.22,.22]: b.box(Vector3(side*5.90+xoff,3.4,-11.22),Vector3(.035,4.7,.028),accent)
			b.cylinder(Vector3(side*5.9,8.0,-12),.52,3.0,materials.dark,0,Vector3.ZERO,8)
			b.armor(Vector3(side*8.0,3.1,-12),Vector3(.5,6.4,1.0),materials.pale,.85)
			# Buttresses and a pointed cathedral vault, open enough to read the sky.
			b.box(Vector3(side*6.9,4.1,-12),Vector3(.32,5.3,.5),materials.pale,Vector3(0,0,-side*.40))
		elif kind=="gargoyle":
			b.cylinder(Vector3(side*6.6,-3.5,-12),1.9,7.5,materials.dark,.28,Vector3.ZERO,7)
			b.cylinder(Vector3(side*6.6,2.6,-12),.45,5.2,materials.pale,.75,Vector3.ZERO,12)
			b.ring(Vector3(side*6.6,5.4,-12),.95,.035,accent)
			b.cylinder(Vector3(side*6.6,6.6,-12),.65,2.4,materials.dark,0,Vector3.ZERO,6)
			b.cylinder(Vector3(side*10.2,1.0,-6),1.1,5.0,materials.stone,.35,Vector3(0,0,side*.16),7)
		else:
			b.cylinder(Vector3(side*6.6,2.5,-12),.72,4.4,materials.stone,.2,Vector3(0,0,side*.22),6)
			b.ring(Vector3(side*6.6,4.2,-12),1.1,.045,accent,Vector3(.8,0,side*.30))
			b.ring(Vector3(side*6.6,4.2,-12),1.4,.02,materials.gold,Vector3(.8,0,side*.30))
			b.cylinder(Vector3(side*6.6,.6,-12),.75,1.4,materials.gold,.20,Vector3(PI,0,0),6)
	if kind=="knight":
		_arch(b,-12,5.9,6.8,materials.pale,.22)
		_arch(b,-11.7,5.9,6.7,materials.gold,.055)
	if kind=="witch":
		b.ring(Vector3(0,.053,-12),1.7,.016,accent)
		b.ring(Vector3(0,.054,-12),2.0,.012,materials.gold)
	return b.build()


func set_theme(kind: String) -> void:
	if kind == current_theme:
		return
	current_theme = kind
	for chunk in chunks:
		chunk.mesh = themes[kind]


func update(distance: float, delta: float) -> void:
	elapsed += delta
	course_bend=sin(distance/145.0)*2.2
	for mat in materials.values(): mat.set_shader_parameter("bend",course_bend)
	var offset := fposmod(distance, CHUNK)
	for index in range(chunks.size()):
		chunks[index].position.z = 24.0 + offset - index * CHUNK
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
	quad.size=Vector2(440,440*2.0/3.0)
	plate.mesh=quad
	var matte:=StandardMaterial3D.new()
	matte.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	matte.disable_fog=true
	matte.albedo_texture=load("res://assets/environment/citadel-matte-v1.png")
	plate.material_override=matte
	plate.position=Vector3(0,61,-235)
	add_child(plate)
	machine = Node3D.new()
	machine.position = Vector3(0, 33, -145)
	add_child(machine)
	var rings = Geo.new()
	rings.ring(Vector3.ZERO, 15.0, 0.45, materials["gold"], Vector3(PI / 2, 0.35, 0))
	rings.ring(Vector3.ZERO, 12.4, 0.13, materials["amber"], Vector3(PI / 2, -0.25, 0.35))
	rings.ring(Vector3.ZERO, 8.3, 0.28, materials["dark"], Vector3(PI / 2, -0.25, 0.35))
	for index in range(12):
		var angle := index * TAU / 12
		rings.box(Vector3(sin(angle) * 15.0, cos(angle) * 15.0, 0), Vector3(1.0, 2.0, 0.8), materials["pale"], Vector3(0, 0, -angle))
	rings.sphere(Vector3.ZERO, Vector3.ONE * 5.0, materials["teal"])
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
			b.box(Vector3(0, 0.55, 0), Vector3(2.05, 1.10, 0.65), materials["dark"])
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
			b.cylinder(Vector3(0, 1.0, 0), 0.14, 0.36, materials["amber"], 0.0, Vector3.ZERO, 4)
			b.cylinder(Vector3(0, 0.64, 0), 0.14, 0.36, materials["gold"], 0.0, Vector3(PI, 0, 0), 4)
			b.ring(Vector3(0, 0.82, 0), 0.24, 0.015, materials["amber"])
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
	return root
