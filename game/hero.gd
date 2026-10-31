extends Node3D

const Geo = preload("res://game/geometry.gd")

var identity: String = "knight"
var body: Node3D
var head: Node3D
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var wings: Array[Node3D] = []
var weapon: Node3D
var aura: Node3D
var cape: Node3D
var clock: float = 0.0
var attack_time: float = 0.0
var power_time: float = 0.0
var sliding: bool = false
var airborne: bool = false
var moving: bool = false
var lean: float = 0.0


func configure(kind: String) -> void:
	identity = kind
	_build()


func accent() -> Color:
	return {"knight": Color("e6b76f"), "gargoyle": Color("6ad7cf"), "witch": Color("c4a1ff")}[identity]


func _pivot(at: Vector3, parent: Node3D) -> Node3D:
	var node := Node3D.new()
	node.position = at
	parent.add_child(node)
	return node


func _build() -> void:
	var steel := Geo.material(Color("637485"), 0.82)
	var dark := Geo.material(Color("151d2b"), 0.25)
	var gold := Geo.material(Color("a58a60"), 0.65)
	var glow := Geo.material(accent(), 0.25, 2.1)
	var stone := Geo.material(Color("627586"), 0.12)
	var cloth := Geo.material(Color("332c4c"), 0.12)
	body = _pivot(Vector3(0, 1.06, 0), self)
	var chest = Geo.new()
	if identity == "knight":
		chest.armor(Vector3(0, 0.28, 0), Vector3(0.94,0.82,0.56), steel)
		chest.armor(Vector3(0, 0.42, -0.285), Vector3(0.65,0.44,0.075), gold, 0.72)
		chest.box(Vector3(0, 0.28, -0.29), Vector3(0.12, 0.56, 0.06), gold)
		chest.sphere(Vector3(0, 0.39, -0.34), Vector3(0.18, 0.21, 0.08), glow)
		chest.armor(Vector3(0,-0.10,0),Vector3(0.69,0.15,0.48),gold,1.0)
		for side in [-1.0,1.0]:
			chest.armor(Vector3(side*0.23,-0.32,-0.18),Vector3(0.30,0.43,0.12),steel,0.78)
		chest.box(Vector3(0, -0.25, 0.19), Vector3(0.50, 0.45, 0.10), dark, Vector3(-0.12, 0, 0))
	elif identity == "gargoyle":
		chest.sphere(Vector3(0, 0.26, 0), Vector3(0.90, 0.84, 0.57), stone)
		chest.cylinder(Vector3(0, -0.14, 0), 0.28, 0.44, stone, 1.4)
		for side in [-1.0, 1.0]:
			chest.box(Vector3(side * 0.16, 0.25, -0.27), Vector3(0.025, 0.48, 0.025), glow, Vector3(0, 0, side * 0.22))
	else:
		chest.cylinder(Vector3(0, 0.26, 0), 0.23, 0.72, cloth, 1.45, Vector3(0, PI / 4, 0), 8)
		chest.cylinder(Vector3(0, -0.37, 0.05), 0.46, 0.77, cloth, 0.45, Vector3.ZERO, 10)
		chest.box(Vector3(0, 0.08, -0.24), Vector3(0.10, 0.63, 0.06), gold)
		chest.sphere(Vector3(0, 0.29, -0.28), Vector3(0.15, 0.15, 0.09), glow)
	body.add_child(chest.build())
	head = _pivot(Vector3(0, 0.93, -0.04), body)
	var skull = Geo.new()
	if identity == "knight":
		skull.armor(Vector3.ZERO,Vector3(0.47,0.50,0.48),steel,0.82)
		skull.box(Vector3(0,0.055,-0.237),Vector3(0.37,0.09,0.025),dark)
		for side in [-1.0,1.0]:
			skull.box(Vector3(side*0.105,0.06,-0.254),Vector3(0.13,0.023,0.024),glow)
			skull.armor(Vector3(side*0.17,-0.12,-0.16),Vector3(0.10,0.23,0.13),gold,0.6)
		skull.box(Vector3(0, -0.075, -0.235), Vector3(0.045, 0.22, 0.05), gold)
		skull.box(Vector3(0,0.27,0.02),Vector3(0.055,0.12,0.42),gold)
	elif identity == "gargoyle":
		skull.sphere(Vector3.ZERO, Vector3(0.48, 0.49, 0.49), stone)
		skull.cylinder(Vector3(0, -0.12, -0.14), 0.19, 0.18, dark, 0.7, Vector3(0.5, 0, 0), 6)
		skull.sphere(Vector3(0,-0.19,-0.10),Vector3(0.32,0.18,0.30),stone)
		for side in [-1.0, 1.0]:
			skull.sphere(Vector3(side * 0.115, 0.055, -0.215), Vector3(0.105, 0.045, 0.05), glow)
			skull.box(Vector3(side*0.115,0.10,-0.20),Vector3(0.16,0.055,0.10),stone,Vector3(0,0,side*0.24))
			skull.cylinder(Vector3(side*0.08,-0.17,-0.26),0.022,0.13,gold,0.0,Vector3(PI,0,0),5)
			skull.cylinder(Vector3(side * 0.19, 0.27, 0.06), 0.085, 0.46, stone, 0.0, Vector3(-0.4, 0, -side * 0.4), 6)
	else:
		skull.sphere(Vector3.ZERO, Vector3(0.41, 0.48, 0.41), dark)
		for side in [-1.0, 1.0]:
			skull.sphere(Vector3(side * 0.09, 0.0, -0.19), Vector3(0.07, 0.035, 0.035), glow)
			skull.cylinder(Vector3(side * 0.22, 0.25, 0.01), 0.04, 0.52, gold, 0.0, Vector3(0, 0, -side * 0.35), 5)
		skull.ring(Vector3(0, 0.25, 0.16), 0.36, 0.022, glow, Vector3(PI / 2, 0, 0))
	head.add_child(skull.build())
	for side in [-1.0, 1.0]:
		var arm := _pivot(Vector3(side * 0.49, 0.53, 0.0), body)
		var limb = Geo.new()
		if identity == "knight":
			limb.armor(Vector3(side*0.04,0.02,0),Vector3(0.52,0.30,0.57),steel,0.9)
			limb.armor(Vector3(side*0.06,0.10,0),Vector3(0.43,0.16,0.47),gold,0.85)
			limb.cylinder(Vector3(side*0.19,0.25,0.01),0.055,0.32,steel,0.0,Vector3(0,0,-side*0.3),5)
		else:
			limb.sphere(Vector3.ZERO, Vector3(0.42, 0.33, 0.41), stone if identity == "gargoyle" else gold)
		limb.cylinder(Vector3(0, -0.32, 0), 0.115, 0.60, steel if identity == "knight" else stone if identity == "gargoyle" else cloth, 1.25)
		limb.box(Vector3(0, -0.55, -0.03), Vector3(0.22, 0.23, 0.24), dark if identity == "witch" else steel if identity == "knight" else stone)
		if identity == "gargoyle":
			for finger in range(3):
				limb.cylinder(Vector3((finger - 1) * 0.065, -0.72, -0.10), 0.035, 0.24, gold, 0.0, Vector3(0.35, 0, 0), 5)
		arm.add_child(limb.build())
		arms.append(arm)
		var leg := _pivot(Vector3(side * 0.22, -0.09, 0), body)
		var shin = Geo.new()
		shin.cylinder(Vector3(0, -0.36, 0), 0.12, 0.70, steel if identity == "knight" else stone if identity == "gargoyle" else dark, 1.2)
		shin.box(Vector3(0, -0.78, -0.11), Vector3(0.23, 0.18, 0.40), steel if identity == "knight" else stone if identity == "gargoyle" else dark)
		if identity == "knight":
			shin.armor(Vector3(0,-0.34,-0.10),Vector3(0.28,0.58,0.20),steel,0.65)
			shin.box(Vector3(0, -0.35, -0.22), Vector3(0.045, 0.42, 0.025), gold)
		leg.add_child(shin.build())
		legs.append(leg)
	if identity == "knight":
		weapon = _pivot(Vector3(0, -0.64, -0.04), arms[1])
		var blade = Geo.new()
		blade.cylinder(Vector3(0, -0.10, 0), 0.055, 0.25, dark)
		blade.box(Vector3(0, -0.25, 0), Vector3(0.46, 0.06, 0.11), gold)
		blade.cylinder(Vector3(0, -0.87, 0), 0.11, 1.20, steel, 0.0, Vector3(0, PI / 4, 0), 4)
		blade.box(Vector3(0, -0.79, -0.04), Vector3(0.026, 0.92, 0.025), glow)
		weapon.add_child(blade.build())
		weapon.rotation.x = -0.25
		var shield = Geo.new()
		shield.armor(Vector3(-0.03,-0.29,-0.19),Vector3(0.63,0.76,0.12),steel,0.65)
		shield.ring(Vector3(-0.03, -0.29, -0.23), 0.29, 0.028, gold, Vector3(PI / 2, 0, 0))
		shield.box(Vector3(-0.03,-0.29,-0.27),Vector3(0.035,0.47,0.03),gold)
		shield.box(Vector3(-0.03,-0.26,-0.27),Vector3(0.38,0.035,0.03),gold)
		arms[0].add_child(shield.build())
	elif identity == "gargoyle":
		for side in [-1.0, 1.0]:
			var wing := _pivot(Vector3(side * 0.30, 0.63, 0.21), body)
			var membrane := Geo.material(Color("27485b"), 0.18)
			var web = Geo.new()
			var origin := Vector3.ZERO
			var tip := Vector3(side * 1.63, 0.55, 0.15)
			var middle := Vector3(side * 1.14, -0.17, 0.25)
			var lower := Vector3(side * 0.52, -0.70, 0.34)
			web.triangle(origin, tip, middle, membrane)
			web.triangle(origin, middle, lower, membrane)
			wing.add_child(web.build())
			Geo.segment(wing, origin, tip, 0.055, stone)
			Geo.segment(wing, origin, middle, 0.035, stone)
			Geo.segment(wing, origin, lower, 0.035, stone)
			wings.append(wing)
	else:
		aura = _pivot(Vector3(0.72, 0.27, 0), body)
		var orb = Geo.new()
		orb.sphere(Vector3.ZERO, Vector3.ONE * 0.21, glow)
		orb.ring(Vector3.ZERO, 0.25, 0.018, gold, Vector3(0.6, 0.2, 0.3))
		aura.add_child(orb.build())
		var staff = Geo.new()
		staff.cylinder(Vector3(0,-0.45,0),0.035,1.85,gold)
		staff.ring(Vector3(0,0.58,0),0.28,0.032,gold,Vector3(PI/2,0,0))
		staff.sphere(Vector3(0,0.58,0),Vector3.ONE*0.20,glow)
		var staff_node := _pivot(Vector3(0,-0.36,0),arms[1])
		staff_node.add_child(staff.build())
	if identity in ["knight","witch"]:
		cape = _pivot(Vector3(0,0.55,0.29),body)
		var fabric := Geo.material(Color("542f3e") if identity == "knight" else Color("43315b"))
		var drape = Geo.new()
		for index in range(8):
			var left := -0.46+index*0.115
			var right := left+0.115
			var a := Vector3(left,0,0)
			var b := Vector3(right,0,0)
			var c := Vector3(left*1.18,-1.38-absf(left)*0.12,0.28+sin(index*PI)*0.05)
			var d := Vector3(right*1.18,-1.38-absf(right)*0.12,0.28+sin((index+1)*PI)*0.05)
			drape.triangle(a,c,b,fabric)
			drape.triangle(b,c,d,fabric)
		cape.add_child(drape.build())
		var seal = Geo.new()
		seal.ring(Vector3(0,-0.32,0.12),0.18,0.018,gold,Vector3(PI/2,0,0))
		seal.box(Vector3(0,-0.34,0.13),Vector3(0.022,0.26,0.025),glow)
		cape.add_child(seal.build())


func animate(delta: float) -> void:
	clock += delta
	attack_time = maxf(0.0, attack_time - delta)
	power_time = maxf(0.0, power_time - delta)
	var frequency := 11.0 if moving else 1.6
	var stride := sin(clock * frequency)
	var amount := 0.67 if moving else 0.025
	for index in range(2):
		var sign_value := 1.0 if index == 0 else -1.0
		legs[index].rotation.x = stride * amount * sign_value
		arms[index].rotation.x = -stride * amount * 0.65 * sign_value
		arms[index].rotation.z = sign_value * 0.10
	body.position.y = 1.06 + absf(stride) * (0.045 if moving else 0.0)
	body.rotation.z = -lean * 0.09
	body.rotation.x = 0.10 if moving else 0.0
	body.rotation.y = 0.0
	if airborne:
		legs[0].rotation.x = -0.45
		legs[1].rotation.x = 0.55
	if sliding:
		body.position.y = 0.48
		body.rotation.x = -0.9
		legs[0].rotation.x = -1.2
		legs[1].rotation.x = -0.9
	if attack_time > 0.0:
		var swing := 1.0 - attack_time / 0.40
		arms[1].rotation.x = -1.8 + sin(swing * PI) * 0.9
		arms[1].rotation.z = -0.7 + swing * 1.6
		body.rotation.y = sin(swing * PI) * -0.60
	if power_time > 0.0:
		if identity == "knight":
			body.rotation.x = 0.40
			arms[0].rotation.x = -1.5
		elif identity == "witch":
			arms[0].rotation.x = -1.3
			arms[1].rotation.x = -1.3
	for index in range(wings.size()):
		var sign_value := 1.0 if index == 0 else -1.0
		wings[index].rotation.y = sign_value * (0.22 + sin(clock * (5.0 if airborne else 2.0)) * (0.18 if airborne else 0.08))
		wings[index].rotation.z = sign_value * (-0.12 if airborne else -0.40)
	if is_instance_valid(aura):
		aura.position.y = 0.28 + sin(clock * 2.4) * 0.12
		aura.rotation.y += delta * 0.8
	if is_instance_valid(cape):
		cape.rotation.x = -0.10+sin(clock*3.0)*0.05+(0.20 if moving else 0.0)
		cape.rotation.z = sin(clock*1.5)*0.035
	if identity == "witch":
		body.position.y += 0.08 + sin(clock * 2.0) * 0.035


func attack() -> void:
	attack_time = 0.4


func power() -> void:
	power_time = 0.7
