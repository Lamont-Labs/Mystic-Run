extends RefCounted

var buckets: Dictionary = {}
static var grain: NoiseTexture2D
static var normal_grain: NoiseTexture2D


static func material(color: Color, metal: float = 0.0, glow: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color, alpha)
	m.metallic = metal
	m.roughness = 0.48 if metal > 0.2 else 0.86
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow <= 0.0 and alpha >= 1.0:
		if grain == null:
			var noise := FastNoiseLite.new()
			noise.seed = 72
			noise.frequency = 0.055
			noise.fractal_octaves = 3
			grain = NoiseTexture2D.new()
			grain.width = 256
			grain.height = 256
			grain.seamless = true
			grain.noise = noise
			var gradient := Gradient.new()
			gradient.colors = PackedColorArray([Color(0.53,0.53,0.53),Color(0.98,0.98,0.98)])
			grain.color_ramp = gradient
			normal_grain = NoiseTexture2D.new()
			normal_grain.width = 256
			normal_grain.height = 256
			normal_grain.seamless = true
			normal_grain.noise = noise
			normal_grain.as_normal_map = true
			normal_grain.bump_strength = 0.5
		m.albedo_texture = grain
		m.normal_enabled = true
		m.normal_texture = normal_grain
		m.normal_scale = 0.14 if metal > 0.2 else 0.26
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE*0.6
	return m


static func release_shared() -> void:
	grain = null
	normal_grain = null


func add(mesh: Mesh, at: Vector3, size: Vector3, mat: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var key := mat.get_instance_id()
	if not buckets.has(key):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		buckets[key] = {"tool": tool, "material": mat}
	var transform := Transform3D(Basis.from_euler(rotation).scaled(size), at)
	buckets[key]["tool"].append_from(mesh, 0, transform)


func box(at: Vector3, size: Vector3, mat: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	add(mesh, at, size, mat, rotation)


func cylinder(at: Vector3, radius: float, height: float, mat: Material, top_ratio: float = 1.0, rotation: Vector3 = Vector3.ZERO, sides: int = 10) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * top_ratio
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	add(mesh, at, Vector3.ONE, mat, rotation)


func sphere(at: Vector3, size: Vector3, mat: Material, segments: int = 12) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = segments
	mesh.rings = 6
	add(mesh, at, size, mat)


func ring(at: Vector3, radius: float, thickness: float, mat: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 24
	mesh.ring_segments = 6
	add(mesh, at, Vector3.ONE, mat, rotation)


func triangle(a: Vector3, b: Vector3, c: Vector3, mat: Material) -> void:
	var key := mat.get_instance_id()
	if not buckets.has(key):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		buckets[key] = {"tool": tool, "material": mat}
	var normal := (b - a).cross(c - a).normalized()
	# Godot front faces are clockwise. Keep the outward normal from the authored
	# right-handed triangle, then reverse its raster winding. Otherwise the
	# outline pass becomes the visible face of armor and architecture.
	for vertex in [c, b, a]:
		buckets[key]["tool"].set_normal(normal)
		buckets[key]["tool"].add_vertex(vertex)


func armor(at: Vector3, size: Vector3, mat: Material, taper: float = 0.82) -> void:
	var chamfer := minf(minf(size.x, size.z),size.y) * 0.18
	var ring := [Vector2(-size.x*0.5+chamfer,-size.z*0.5),Vector2(size.x*0.5-chamfer,-size.z*0.5),Vector2(size.x*0.5,-size.z*0.5+chamfer),Vector2(size.x*0.5,size.z*0.5-chamfer),Vector2(size.x*0.5-chamfer,size.z*0.5),Vector2(-size.x*0.5+chamfer,size.z*0.5),Vector2(-size.x*0.5,size.z*0.5-chamfer),Vector2(-size.x*0.5,-size.z*0.5+chamfer)]
	var ys := [-size.y*0.5,-size.y*0.5+chamfer,size.y*0.5-chamfer,size.y*0.5]
	var scales := [taper*0.84,taper,1.0,0.86]
	for level in range(3):
		for index in range(8):
			var next := (index+1)%8
			var a: Vector3 = at+Vector3(ring[index].x*scales[level],ys[level],ring[index].y*scales[level])
			var b: Vector3 = at+Vector3(ring[index].x*scales[level+1],ys[level+1],ring[index].y*scales[level+1])
			var c: Vector3 = at+Vector3(ring[next].x*scales[level],ys[level],ring[next].y*scales[level])
			var d: Vector3 = at+Vector3(ring[next].x*scales[level+1],ys[level+1],ring[next].y*scales[level+1])
			triangle(a,b,c,mat)
			triangle(b,d,c,mat)
	for index in range(8):
		var next := (index+1)%8
		triangle(at+Vector3(0,ys[3],0),at+Vector3(ring[next].x*scales[3],ys[3],ring[next].y*scales[3]),at+Vector3(ring[index].x*scales[3],ys[3],ring[index].y*scales[3]),mat)
		triangle(at+Vector3(0,ys[0],0),at+Vector3(ring[index].x*scales[0],ys[0],ring[index].y*scales[0]),at+Vector3(ring[next].x*scales[0],ys[0],ring[next].y*scales[0]),mat)


func build() -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	for group in buckets.values():
		group["tool"].commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, group["material"])
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	return instance


static func segment(parent: Node3D, start: Vector3, finish: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var geo = load("res://game/geometry.gd").new()
	geo.cylinder(Vector3.ZERO, radius, start.distance_to(finish), mat, 0.72)
	var mesh: MeshInstance3D = geo.build()
	parent.add_child(mesh)
	mesh.position = (start + finish) * 0.5
	var direction := (finish - start).normalized()
	if absf(direction.dot(Vector3.UP)) < 0.999:
		mesh.quaternion = Quaternion(Vector3.UP, direction)
	return mesh
