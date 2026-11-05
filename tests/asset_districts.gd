extends SceneTree
## Real imported meshes, scene bounds, looping, motion and pool stability.
const Districts = preload("res://game/asset_districts.gd")
const Course = preload("res://core/course_profile.gd")
var failures: Array[String] = []
var checks: int = 0
func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)
func _initialize() -> void: call_deferred("run")
func descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child); result.append_array(descendants(child))
	return result
func run() -> void:
	var scene = Districts.new()
	root.add_child(scene); scene.configure()
	await process_frame
	check(scene.islands.size() == 8, "Eight preallocated floating districts")
	check(scene.fans.size() == 2, "Both imported windmill pivots retained")
	var collisions: int = 0
	var shared: bool = true
	var finite_vertices: bool = true
	var triangles: int = 0
	for child in descendants(scene):
		if child is CollisionObject3D or child is CollisionShape3D: collisions += 1
		if child is MeshInstance3D:
			if child.material_override != null: shared = shared and child.material_override == scene.atlas_material
			for surface in range(child.mesh.get_surface_count()):
				var arrays: Array = child.mesh.surface_get_arrays(surface)
				for vertex in arrays[Mesh.ARRAY_VERTEX]: finite_vertices = finite_vertices and vertex.is_finite()
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				triangles += indices.size() / 3
	check(collisions == 0, "Scenery introduces no collision authority")
	check(shared, "All imported models share one atlas material")
	check(finite_vertices, "All imported positions are finite")
	check(triangles < 60000, "Entire scenery pool stays below 60k source triangles")
	var count: int = descendants(scene).size()
	var clear: bool = true
	var stable: bool = true
	for tick in range(1800):
		var distance: float = tick * 13.7
		scene.update_scenery(distance, 1.0 / 60, false, false, false)
		for island in scene.islands:
			var station: float = maxf(0.0, distance - island.position.z)
			var lateral: float = Course.lateral_at(station, distance)
			var inverse: Transform3D = island.global_transform.affine_inverse()
			for child in descendants(island):
				if child is MeshInstance3D:
					var box: AABB = (inverse * child.global_transform) * child.get_aabb()
					var lo: float = island.position.x - lateral + box.position.x
					var hi: float = lo + box.size.x
					clear = clear and (lo > scene.CORRIDOR_HALF_WIDTH or hi < -scene.CORRIDOR_HALF_WIDTH)
			stable = stable and island.position.is_finite() and island.position.z <= 25.0 and island.position.z > 25.0 - scene.LOOP
	check(clear, "Actual transformed mesh bounds stay outside the seven-metre side corridor")
	check(stable and descendants(scene).size() == count, "24.6km of recycling keeps finite transforms and fixed node count")
	scene.update_scenery(100, .25, false, true, false)
	var still: bool = true
	for fan in scene.fans: still = still and is_zero_approx(fan.rotation.z)
	check(still, "Reduced Motion stops imported windmill animation")
	scene.high_detail = false; scene.update_scenery(0, 0, true, false, false)
	var visible_count: int = 0
	for island in scene.islands:
		if island.visible: visible_count += 1
	check(visible_count > 0 and visible_count < 8, "Lower quality reduces visible districts without allocating nodes")
	scene.update_scenery(0, 0, true, false, true)
	check(not scene.visible, "Secret chambers hide outer scenery")
	scene.queue_free(); await process_frame
	var report: Dictionary = {"checks": checks, "failed": failures.size(), "failures": failures, "scenery_source_triangles": triangles, "scope": "Actual imports and scenery invariants; desktop headless, no physical-phone performance claim"}
	FileAccess.open("res://tests/evidence/asset-districts.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("ASSET_DISTRICTS_QA ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
