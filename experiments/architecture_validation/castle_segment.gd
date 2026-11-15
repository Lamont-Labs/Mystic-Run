extends Node3D
## One reusable 96m Castle-only visual segment. No gameplay/collision changes.
const Geo=preload("res://game/geometry.gd")
const Course=preload("res://core/course_profile.gd")
const Gateway=preload("res://assets/replacement_batch01/original/skybridge_gateway.glb")
const Tower=preload("res://assets/environment/living-world/castle_landmark.png")
var game:Node
var deck:Mesh
var landmarks:Array[Node3D]=[]
var towers:Array[Sprite3D]=[]
var bounds:AABB

func _ready() -> void:process_physics_priority=110

func _physics_process(_delta:float) -> void:
	if is_instance_valid(game):advance()

func configure(owner_game:Node) -> void:
	game=owner_game
	var b:=Geo.new()
	var mats:Dictionary=game.world.materials
	for tile in range(12):
		var z:float=-1.0-tile*2.0
		b.box(Vector3(0,-.20,z),Vector3(10.8,.36,2.0),mats.road)
		for side in [-1,1]:
			b.box(Vector3(side*5.2,.14,z),Vector3(.40,.48,1.97),mats.pale)
			b.box(Vector3(side*5.2,.42,z),Vector3(.49,.10,1.99),mats.gold)
			b.box(Vector3(side*5.2,.72,z),Vector3(.22,.62,.24),mats.pale)
			b.box(Vector3(side*5.2,1.06,z),Vector3(.36,.10,.38),mats.gold)
			b.box(Vector3(side*1.3,.002,z),Vector3(.035,.014,.65),mats.gold)
	for terrace in range(3):
		var z:float=-4.0-terrace*8.0
		for side in [-1,1]:
			b.box(Vector3(side*8.0,-.30,z),Vector3(6.4,.56,5.5),mats.road)
			b.box(Vector3(side*8.0,-.61,z),Vector3(6.6,.09,5.7),mats.gold)
			b.box(Vector3(side*6.2,-1.3,z),Vector3(1.2,2.1,4.4),mats.pale)
	var built:MeshInstance3D=b.build()
	deck=built.mesh;built.free()
	for i in range(6):
		var gateway:Node3D=Gateway.instantiate()
		add_child(gateway)
		var box:=_bounds(gateway)
		var scale_factor:float=minf(9.0/maxf(box.size.y,.01),5.0/maxf(box.size.x,.01))
		gateway.scale=Vector3.ONE*scale_factor
		gateway.set_meta("floor_offset",-box.position.y*scale_factor)
		gateway.set_meta("side",-1 if i%2==0 else 1)
		gateway.set_meta("station",20.0+floori(i/2.0)*32.0)
		landmarks.append(gateway)
	for i in range(6):
		var tower:=Sprite3D.new()
		tower.texture=Tower;tower.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y
		tower.pixel_size=10.0/float(Tower.get_height())
		tower.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tower.shaded=false
		add_child(tower);towers.append(tower)

func _bounds(node:Node3D) -> AABB:
	var result:=AABB()
	var initialized:bool=false
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		var box:AABB=(node.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		result=result.merge(box) if initialized else box
		initialized=true
	return result

func advance() -> void:
	game.world._update_biomes(0.0)
	for chunk in game.world.chunks:chunk.mesh=deck
	game.world.living.visible=false
	for node in game.world.lanterns:node.visible=false
	for i in range(landmarks.size()):
		var node:Node3D=landmarks[i]
		var station:float=float(node.get_meta("station"))+floorf(game.distance/96.0)*96.0
		if station<game.distance-16:station+=96.0
		var z:float=game.distance-station
		node.position=Vector3(float(node.get_meta("side"))*8.6+Course.lateral_at(station,game.distance),Course.height_at(station)+float(node.get_meta("floor_offset")),z)
	for i in range(towers.size()):
		var station:float=12.0+floori(i/2.0)*32.0+floorf(game.distance/96.0)*96.0
		if station<game.distance-16:station+=96.0
		towers[i].position=Vector3((-1 if i%2==0 else 1)*8.0+Course.lateral_at(station,game.distance),Course.height_at(station)+5.0,game.distance-station)
