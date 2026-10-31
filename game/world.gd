extends Node3D

const Geo = preload("res://game/geometry.gd")
const WIDTH := 2.6
const CHUNK := 24.0

var themes: Dictionary = {}
var chunks: Array[MeshInstance3D] = []
var current_theme: String = "knight"
var materials: Dictionary = {}
var machine: Node3D
var dust: MultiMeshInstance3D
var elapsed: float = 0.0


func configure() -> void:
	materials = {
		"stone": Geo.material(Color("303b49")),
		"pale": Geo.material(Color("3c4a58")),
		"dark": Geo.material(Color("141d2b")),
		"metal": Geo.material(Color("706d63"), 0.65),
		"gold": Geo.material(Color("bd965c"), 0.7),
		"amber": Geo.material(Color("e9bb72"), 0.2, 1.6),
		"teal": Geo.material(Color("67c8d0"), 0.15, 1.5),
		"violet": Geo.material(Color("b995ee"), 0.15, 1.5),
		"red": Geo.material(Color("ea746b"), 0.1, 1.3),
		"void": Geo.material(Color("050912")),
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


func _chunk_mesh(kind: String) -> MeshInstance3D:
	var b = Geo.new()
	var accent: Material = materials[{"knight":"amber", "gargoyle":"teal", "witch":"violet"}[kind]]
	b.box(Vector3(0, -0.35, -12), Vector3(9.6, 0.7, 24), materials["dark"])
	for row in range(6):
		for column in range(3):
			b.box(Vector3((column - 1) * 2.95, 0.008, -2.0 - row * 4), Vector3(2.91, 0.018, 3.96), materials["stone"])
	for side in [-1.0, 1.0]:
		b.box(Vector3(side * 4.50, 0.07, -12), Vector3(0.10, 0.06, 24), accent)
		b.box(Vector3(side * 4.82, -0.1, -12), Vector3(0.34, 0.9, 24), materials["metal"])
		b.box(Vector3(side * 4.70, 0.55, -12), Vector3(0.20, 0.20, 24), materials["dark"])
		for z in [-3.0, -9.0, -15.0, -21.0]:
			b.box(Vector3(side * 4.72, 0.32, z), Vector3(0.25, 0.7, 0.35), materials["gold"])
		if kind == "knight":
			b.box(Vector3(side * 5.65, 4.5, -12), Vector3(1.0, 9.0, 1.2), materials["stone"])
			b.box(Vector3(side * 5.65, 4.3, -12.64), Vector3(0.12, 7.3, 0.08), materials["amber"])
			b.box(Vector3(side * 3.05, 10.1, -12), Vector3(6.0, 0.65, 1.0), materials["pale"], Vector3(0, 0, -side * 0.39))
			b.cylinder(Vector3(side * 5.65, 9.8, -12), 0.8, 2.1, materials["dark"], 0.05, Vector3.ZERO, 6)
			b.box(Vector3(side * 7.4, 3.5, -12), Vector3(0.65, 8.1, 1.1), materials["stone"], Vector3(0, 0, side * 0.40))
		elif kind == "gargoyle":
			b.cylinder(Vector3(side * 7.2, -4.8, -12), 2.7, 9.0, materials["dark"], 0.25, Vector3.ZERO, 6)
			b.cylinder(Vector3(side * 7.2, 2.8, -12), 0.55, 7.0, materials["pale"], 0.45, Vector3.ZERO, 6)
			b.ring(Vector3(side * 7.2, 5.8, -12), 1.1, 0.065, accent)
			b.cylinder(Vector3(side * 7.2, 7.0, -12), 0.63, 2.0, materials["dark"], 0.0)
		else:
			b.cylinder(Vector3(side * 6.3, 3.2, -12), 0.6, 3.6, materials["dark"], 0.0, Vector3(0, 0, side * 0.25), 5)
			b.cylinder(Vector3(side * 6.3, 0.6, -12), 0.6, 1.5, materials["pale"], 0.0, Vector3(PI, 0, 0), 5)
			b.ring(Vector3(side * 6.3, 3.5, -12), 1.35, 0.035, accent, Vector3(0.8, 0, side * 0.35))
	for lane_x in [-2.6, 0.0, 2.6]:
		for z in [-6.0, -18.0]:
			b.box(Vector3(lane_x - 0.18, 0.035, z), Vector3(0.025, 0.025, 0.65), materials["gold"], Vector3(0, -0.55, 0))
			b.box(Vector3(lane_x + 0.18, 0.035, z), Vector3(0.025, 0.025, 0.65), materials["gold"], Vector3(0, 0.55, 0))
	if kind == "witch":
		b.ring(Vector3(0, 0.04, -12), 1.6, 0.025, accent)
		b.ring(Vector3(0, 0.045, -12), 1.9, 0.015, materials["gold"])
	return b.build()


func set_theme(kind: String) -> void:
	if kind == current_theme:
		return
	current_theme = kind
	for chunk in chunks:
		chunk.mesh = themes[kind]


func update(distance: float, delta: float) -> void:
	elapsed += delta
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
	for index in range(30):
		var side := -1.0 if index % 2 == 0 else 1.0
		var x := side * (17.0 + fposmod(index * 11.37, 67.0))
		var z := -55.0 - fposmod(index * 17.7, 155.0)
		var height := 16.0 + fposmod(index * 7.31, 44.0)
		b.box(Vector3(x, height * 0.5 - 12.0, z), Vector3(6.5, height, 7), materials["dark"])
		b.cylinder(Vector3(x, height - 9.0, z), 4.9, 14.0, materials["stone"], 0.0, Vector3.ZERO, 4)
		for line in range(3):
			b.box(Vector3(x + (line - 1) * 1.0, height * 0.45 - 8.0, z + 3.55), Vector3(0.16, height * 0.36, 0.06), materials["amber"])
	add_child(b.build())
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
	var moon = Geo.new()
	moon.sphere(Vector3(-50, 68, -220), Vector3.ONE * 23.0, Geo.material(Color("d4dfdf"), 0.0, 0.6), 32)
	add_child(moon.build())


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


func prop(kind: String) -> Node3D:
	var root := Node3D.new()
	var b = Geo.new()
	match kind:
		"enemy":
			b.cylinder(Vector3(0, 1.05, 0), 0.40, 0.9, materials["dark"], 1.10, Vector3(0, PI / 4, 0), 4)
			b.sphere(Vector3(0, 1.80, 0), Vector3.ONE * 0.50, materials["metal"])
			b.box(Vector3(0, 1.84, 0.23), Vector3(0.34, 0.055, 0.04), materials["red"])
			for side in [-1.0, 1.0]:
				b.box(Vector3(side * 0.24, 0.37, 0), Vector3(0.25, 0.70, 0.30), materials["metal"])
				b.sphere(Vector3(side * 0.51, 1.43, 0), Vector3(0.35, 0.32, 0.4), materials["metal"])
				b.cylinder(Vector3(side * 0.51, 1.06, 0), 0.11, 0.65, materials["dark"])
			b.box(Vector3(0.55, 1.34, 0.27), Vector3(0.10, 1.3, 0.12), materials["red"], Vector3(-0.4, 0, 0))
			b.ring(Vector3(0, 0.03, 0), 0.62, 0.025, materials["red"])
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
			b.box(Vector3(0, 0.025, 0), Vector3(2.45, 0.025, 3.6), materials["void"])
			for side in [-1.0, 1.0]:
				b.box(Vector3(0, 0.07, side * 1.8), Vector3(2.5, 0.055, 0.12), materials["red"])
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
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				root.add_child(label)
	root.add_child(b.build())
	return root
