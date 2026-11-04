extends Node3D
## Cosmetic scenery only. No collision bodies, encounter RNG or save access.

const Geo = preload("res://game/geometry.gd")
const Course = preload("res://core/course_profile.gd")
const ATLAS = preload("res://assets/environment/kaykit/hexagons_medieval.png")
const SHADER = preload("res://assets/shaders/scenery_atlas.gdshader")
const MODELS = {
	"home": preload("res://assets/environment/kaykit/home.gltf"),
	"market": preload("res://assets/environment/kaykit/market.gltf"),
	"windmill": preload("res://assets/environment/kaykit/windmill.gltf"),
	"well": preload("res://assets/environment/kaykit/well.gltf"),
	"castle": preload("res://assets/environment/kaykit/castle.gltf"),
	"tree_round": preload("res://assets/environment/kaykit/tree_round.gltf"),
	"tree_tall": preload("res://assets/environment/kaykit/tree_tall.gltf"),
}
const POOL_SIZE := 8
const SPACING := 48.0
const LOOP := SPACING * POOL_SIZE
const CORRIDOR_HALF_WIDTH := 7.0
var islands: Array[Node3D] = []
var fans: Array[Node3D] = []
var atlas_material: ShaderMaterial
var high_detail: bool = true
var motion_clock: float = 0.0
var island_mesh: ArrayMesh

func configure() -> void:
	atlas_material = ShaderMaterial.new()
	atlas_material.shader = SHADER
	atlas_material.set_shader_parameter("atlas", ATLAS)
	island_mesh = _foundation()
	for index in range(POOL_SIZE):
		var island := Node3D.new()
		island.name = "FloatingDistrict%d" % index
		island.set_meta("variant", index % 4)
		add_child(island)
		islands.append(island)
		var foundation := MeshInstance3D.new()
		foundation.mesh = island_mesh
		foundation.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		island.add_child(foundation)
		var side: float = -1.0 if index % 2 == 0 else 1.0
		match index % 4:
			0:
				_place(island, "home", Vector3(-1.9, 0, -1.2), 4.2, side * .35)
				_place(island, "market", Vector3(1.4, 0, 1.3), 3.6, side * -.2)
			1:
				_place(island, "windmill", Vector3(0, 0, -.8), 5.2, side * -.3)
				_place(island, "well", Vector3(-2.4, 0, 2.0), 2.5, 0)
			2:
				_place(island, "castle", Vector3(0, 0, -.8), 2.8, side * .2)
			3:
				_place(island, "home", Vector3(0, 0, -1.2), 5.0, side * -.5)
				_place(island, "well", Vector3(2.4, 0, 1.8), 2.6, 0)
		_place(island, "tree_round", Vector3(-3.3, .25, -.7), 3.0, index * .8)
		_place(island, "tree_tall", Vector3(3.2, .25, -2.6), 3.2, index * -.6)
	update_scenery(0.0, 0.0, true, false, false)

func _foundation() -> ArrayMesh:
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color("9f91bf"); rock.roughness = 1.0
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color("70bfa0"); grass.roughness = 1.0
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("e3c7a0"); stone.roughness = 1.0
	var geo = Geo.new()
	# A single shared platform mesh; the full radius stays beyond the route.
	geo.cylinder(Vector3(0, -2.15, 0), 3.0, 4.0, rock, 1.9, Vector3.ZERO, 16)
	geo.cylinder(Vector3(0, -.20, 0), 5.7, .32, grass, 1.0, Vector3.ZERO, 24)
	geo.cylinder(Vector3(0, -.055, .2), 4.6, .08, stone, 1.0, Vector3.ZERO, 24)
	var node: MeshInstance3D = geo.build()
	var result: ArrayMesh = node.mesh
	node.free()
	return result

func _place(parent: Node3D, model_name: String, at: Vector3, size: float, yaw: float) -> void:
	var model: Node3D = MODELS[model_name].instantiate()
	model.position = at; model.scale = Vector3.ONE * size; model.rotation.y = yaw
	parent.add_child(model)
	_style(model)
	if model_name == "windmill":
		var fan: Node3D = model.find_child("*fan*", true, false)
		if is_instance_valid(fan): fans.append(fan)

func _style(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = atlas_material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children(): _style(child)

func update_scenery(distance: float, delta: float, flat_course: bool, reduced_motion: bool, in_secret: bool) -> void:
	visible = not in_secret
	if not reduced_motion: motion_clock += delta
	for index in range(islands.size()):
		var island: Node3D = islands[index]
		var z: float = 25.0 - fposmod(index * SPACING - distance + 37.0, LOOP)
		var station: float = maxf(0.0, distance - z)
		var side: float = -1.0 if index % 2 == 0 else 1.0
		# Decoration follows the same lateral/elevation reference as the route.
		var lateral: float = 0.0 if flat_course else Course.lateral_at(station, distance)
		var height: float = 0.0 if flat_course else Course.height_at(station)
		island.position = Vector3(side * (14.0 + (index % 3) * 1.2) + lateral, height - .8, z)
		island.visible = high_detail or (z > -150.0)
	for fan in fans:
		fan.rotation.z = 0.0 if reduced_motion else fposmod(motion_clock * .55, TAU)

func diagnostics() -> Dictionary:
	return {"source": "KayKit Medieval Hexagon Pack, free Standard, CC0 1.0", "island_pool": islands.size(), "windmills": fans.size(), "shared_atlas": true, "collision_bodies": 0, "runtime_downloads": false}
