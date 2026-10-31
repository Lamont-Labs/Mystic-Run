extends Node3D

const Core = preload("res://core/run_core.gd")
const Hero = preload("res://game/hero.gd")
const World = preload("res://game/world.gd")
const Hud = preload("res://game/hud.gd")
const Geo = preload("res://game/geometry.gd")
const LANES := [-2.6, 0.0, 2.6]
const ROUTE_CHARACTERS := ["gargoyle", "knight", "witch"]

var core = Core.new()
var world: Node3D
var motor: CharacterBody3D
var collider: CollisionShape3D
var camera: Camera3D
var key_light: DirectionalLight3D
var ui: Control
var heroes: Dictionary = {}
var selected: String = "knight"
var lane: int = 1
var rows: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var touches: Dictionary = {}
var rng := RandomNumberGenerator.new()
var fx_rng := RandomNumberGenerator.new()
var next_row: float = 24.0
var next_gate: float = 112.0
var row_index: int = 0
var sliding_left: float = 0.0
var power_left: float = 0.0
var attack_age: float = 10.0
var attack_token: int = -1
var distance: float = 0.0
var shards: int = 0
var previous_phase: String = "ready"
var outgoing: String = "knight"
var incoming: String = "gargoyle"
var handoff_age: float = 0.0
var total_handoffs: int = 0
var handoff_pairs: Array[String] = []
var clock: float = 0.0
var foot_clock: float = 0.0
var impact_shake: float = 0.0
var profile := {"schema":1, "best":0.0, "settings":{"music":true,"sound":true,"vibration":true,"quality":true}}
var sounds: Dictionary = {}
var music: AudioStreamPlayer
var effect_players: Array[AudioStreamPlayer] = []
var sound_cursor: int = 0
var qa: bool = false
var qa_limit: int = 3600
var qa_ticks: int = 0
var qa_deaths: int = 0
var qa_attacks: int = 0
var qa_powers: int = 0
var qa_damage: int = 0
var capture_dir: String = ""
var captures: Dictionary = {}
var capture_busy: bool = false
var menu_capture: bool = false
var anchor: Node3D
var quitting: bool = false
var starting_character: String = "knight"
var qa_incidents: Array[Dictionary] = []
var qa_jump_count: int = 0
var qa_peak_height: float = 0.0
var qa_slide_count: int = 0
var qa_offscreen_ticks: int = 0
var qa_target_sequence := [0, 2, 1, 2, 0, 1]


func _ready() -> void:
	get_tree().auto_accept_quit = false
	for argument in OS.get_cmdline_user_args():
		if argument == "--qa":
			qa = true
		elif argument == "--qa-menu":
			menu_capture = true
		elif argument.begins_with("--qa-ticks="):
			qa_limit = int(argument.get_slice("=", 1))
		elif argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
		elif argument.begins_with("--character="):
			var requested := argument.trim_prefix("--character=")
			if Core.CHARACTERS.has(requested):
				selected = requested
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
	_load_profile()
	_setup_environment()
	world = World.new()
	add_child(world)
	world.configure()
	_setup_motor()
	for kind in Core.CHARACTERS:
		var hero = Hero.new()
		hero.configure(kind)
		motor.add_child(hero)
		heroes[kind] = hero
	_setup_audio()
	var anchor_geometry = Geo.new()
	anchor_geometry.ring(Vector3.ZERO,0.48,0.025,Geo.material(Color("c4a1ff"),0,1.2))
	anchor_geometry.ring(Vector3.ZERO,0.26,0.018,Geo.material(Color("e9e5da"),0,0.6))
	anchor = anchor_geometry.build()
	add_child(anchor)
	anchor.visible = false
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Hud.new()
	layer.add_child(ui)
	ui.intent.connect(_intent)
	ui.settings = profile["settings"].duplicate(true)
	ui.refresh()
	_select_character(selected)
	_apply_settings()
	if qa:
		_start_run()
		print("SCENE_QA_STARTED "+str(qa_limit))
	if menu_capture:
		_preview_menu()


func _setup_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("1c123b")
	sky_material.sky_horizon_color = Color("645779")
	sky_material.ground_bottom_color = Color("050b16")
	sky_material.ground_horizon_color = Color("342d51")
	sky_material.sky_curve = 0.22
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8b8df")
	environment.ambient_light_energy = 0.50
	environment.fog_enabled = true
	environment.fog_light_color = Color("373154")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.0035
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var node := WorldEnvironment.new()
	node.environment = environment
	add_child(node)
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-42, -27, 0)
	key_light.light_color = Color("ffddb2")
	key_light.light_energy = 1.2
	key_light.shadow_enabled = true
	key_light.directional_shadow_max_distance = 65
	add_child(key_light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-24, 148, 0)
	fill.light_color = Color("83b4d2")
	fill.light_energy = 0.42
	add_child(fill)
	camera = Camera3D.new()
	camera.fov = 65
	camera.far = 340
	camera.near = 0.15
	camera.position = Vector3(1.3, 2.65, 5.4)
	add_child(camera)
	camera.look_at(Vector3(0, 1.25, 0))
	var hero_light := OmniLight3D.new()
	hero_light.position = Vector3(2.6,3.5,3.0)
	hero_light.omni_range = 8.0
	hero_light.light_energy = 0.5
	hero_light.light_color = Color("e7ceb0")
	add_child(hero_light)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-2.5,3.2,-1.0)
	rim.omni_range = 6.0
	rim.light_color = Color("7ea6cf")
	rim.light_energy = 0.9
	add_child(rim)


func _setup_motor() -> void:
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(18, 1, 450)
	floor_shape.shape = box
	floor_shape.position = Vector3(0, -0.5, -180)
	floor_body.add_child(floor_shape)
	add_child(floor_body)
	motor = CharacterBody3D.new()
	motor.name = "AuthoritativeRunner"
	motor.floor_snap_length = 0.12
	collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	motor.add_child(collider)
	add_child(motor)


func _setup_audio() -> void:
	for name in ["strike","impact","spell","wing","handoff","pickup","hurt","step"]:
		sounds[name] = load("res://assets/audio/" + name + ".wav")
	for _index in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -7
		add_child(player)
		effect_players.append(player)
	music = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = load("res://assets/audio/city-pulse.wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = stream.data.size() / 2
	music.stream = stream
	music.volume_db = -18
	add_child(music)
	music.play()


func _sound(name: String, pitch: float = 1.0) -> void:
	if not profile["settings"]["sound"] or not sounds.has(name):
		return
	var player: AudioStreamPlayer = effect_players[sound_cursor % effect_players.size()]
	sound_cursor += 1
	player.stream = sounds[name]
	player.pitch_scale = pitch
	player.volume_db = -20 if name == "step" else -8
	player.play()


func _select_character(kind: String) -> void:
	selected = kind
	for character in heroes:
		heroes[character].visible = character == kind
		heroes[character].position = Vector3.ZERO
		heroes[character].rotation.y = PI + 0.34 if ui.mode == "menu" else 0.0
		heroes[character].sliding = false
		heroes[character].airborne = false
		heroes[character].lean = 0.0
		heroes[character].scale = Vector3.ONE*(1.10 if ui.mode == "menu" and character != "gargoyle" else 1.0)
	ui.selected = kind
	ui.refresh()
	world.set_theme(kind)


func _start_run() -> void:
	for row in rows:
		row["node"].queue_free()
	rows.clear()
	for item in effects:
		item["node"].queue_free()
	effects.clear()
	core = Core.new()
	starting_character = selected
	if qa and selected == "gargoyle":
		qa_target_sequence = [1,2,0,2,1,0]
	elif qa and selected == "witch":
		qa_target_sequence = [1,0,2,0,1,2]
	var run_seed := 73129 if qa else (int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_usec()))
	core.start(selected,run_seed)
	rng.seed = run_seed
	fx_rng.seed = run_seed ^ 90871
	lane = 1
	motor.position = Vector3.ZERO
	motor.velocity = Vector3.ZERO
	next_row = 24
	next_gate = 112
	row_index = 0
	distance = 0
	shards = 0
	sliding_left = 0
	power_left = 0
	attack_age = 10
	attack_token = -1
	previous_phase = "running"
	total_handoffs = 0
	handoff_pairs.clear()
	ui.set_mode("game")
	world.visible = true
	motor.visible = true
	_select_character(selected)
	ui.message("THE CITY IS WAKING", 2.5)
	_spawn_ahead()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(ui):
		return
	clock += delta
	if ui.mode == "menu" or (ui.mode == "settings" and ui.previous_mode == "menu"):
		world.visible = false
		motor.visible = false
		return
	if ui.mode != "game":
		anchor.visible = false
		return
	if qa:
		_qa_control()
	core.step()
	distance = core.distance_mm / 1000.0
	sliding_left = maxf(0.0, sliding_left-delta)
	power_left = maxf(0.0, power_left-delta)
	attack_age += delta
	var gravity := 5.5 if selected == "gargoyle" and power_left > 0.0 and motor.velocity.y < 1.5 else 25.0
	if not motor.is_on_floor():
		motor.velocity.y -= gravity * delta
	elif motor.velocity.y < 0.0:
		motor.velocity.y = 0.0
	motor.velocity.x = (LANES[lane]-motor.position.x)*15.0
	motor.velocity.z = -motor.position.z*10.0
	motor.move_and_slide()
	qa_peak_height = maxf(qa_peak_height,motor.position.y)
	var capsule: CapsuleShape3D = collider.shape
	capsule.height = 0.90 if sliding_left > 0.0 else 1.8
	collider.position.y = capsule.height * 0.5
	_handle_transition(delta)
	_spawn_ahead()
	_update_rows(delta)
	_update_effects(delta)
	world.update(distance, delta)
	var active: Node3D = heroes[selected]
	active.moving = true
	active.airborne = motor.position.y > 0.10
	active.sliding = sliding_left > 0.0
	active.lean = motor.velocity.x * 0.05
	active.animate(delta)
	var view_target := Vector3(motor.position.x*0.62, 3.8 + clampf(motor.position.y,0,2)*0.20, 8.1)
	camera.position = camera.position.lerp(view_target, 0.09)
	camera.position.x = motor.position.x*0.62
	camera.look_at(Vector3(motor.position.x*0.72, 1.65, -15.0))
	impact_shake=maxf(0,impact_shake-delta*3)
	camera.h_offset=sin(clock*63)*impact_shake*.035
	camera.v_offset=cos(clock*77)*impact_shake*.025
	if qa:
		var projected := camera.unproject_position(motor.position+Vector3(0,1.1,0))
		if projected.x < 0 or projected.x > get_viewport().get_visible_rect().size.x:
			qa_offscreen_ticks += 1
	foot_clock += delta
	if foot_clock > 0.32 and motor.is_on_floor() and sliding_left <= 0.0:
		foot_clock = 0
		_sound("step", 0.90+fx_rng.randf()*0.15)
	ui.update_session(core.snapshot(), shards)
	var anchor_lane := _blink_destination() if selected == "witch" else -1
	anchor.visible = anchor_lane >= 0 and core.power_remaining("witch") == 0 and core.phase in ["running","telegraph"]
	if anchor.visible:
		anchor.position = Vector3(LANES[anchor_lane],0.09,-3.5)
		anchor.rotation.y += delta*0.7
	if core.phase == "failed":
		_end_run()
	if qa:
		qa_ticks += 1
		if qa_ticks % 600 == 0:
			print("SCENE_QA_PROGRESS "+str(qa_ticks)+" "+selected+" "+str(total_handoffs))
		if qa_ticks in [180, 600, 1200, 1800, 2400, 3000]:
			_capture("game-%04d-%s" % [qa_ticks,selected])
		if qa_ticks >= qa_limit:
			_qa_finish()


func _spawn_ahead() -> void:
	while next_gate < distance+205.0:
		var gate := {"kind":"gate","lane":1,"at":next_gate,"node":world.prop("gate"),"resolved":false,"offered":false,"id":-1,"epoch":-1}
		add_child(gate["node"])
		rows.append(gate)
		next_gate += 320.0
	while next_row < distance+170.0:
		var marker := next_row
		next_row += 16.0
		var gate_number := roundi((marker-112.0)/320.0)
		var gate_at := 112.0+gate_number*320.0
		if marker > gate_at-9.0 and marker < gate_at+72.0:
			continue
		var kind: String = ["enemy","shard","barrier","drone","beam","gap","shard","enemy"][row_index%8]
		var target_lane := 1 if row_index == 0 else rng.randi_range(0,2)
		row_index += 1
		if kind == "shard":
			for index in range(4):
				_add_row(kind,target_lane,marker+index*2.4)
		else:
			_add_row(kind,target_lane,marker)


func _add_row(kind: String, target_lane: int, marker: float) -> void:
	var node: Node3D = world.prop(kind)
	add_child(node)
	var token: int = core.register_collectible() if kind == "shard" else -1
	rows.append({"kind":kind,"lane":target_lane,"at":marker,"node":node,"resolved":false,"id":token,"epoch":-1})


func _update_rows(delta: float) -> void:
	ui.route_visible = false
	for index in range(rows.size()-1,-1,-1):
		var row: Dictionary = rows[index]
		var node: Node3D = row["node"]
		var kind := str(row["kind"])
		var z := distance-float(row["at"])
		node.position = Vector3(0.0 if kind == "gate" else LANES[int(row["lane"])],0,z)
		if z > 24:
			if kind in ["enemy","drone","barrier"]:
				core.retire_enemy(int(row["id"]))
			elif kind == "shard":
				core.retire_collectible(int(row["id"]))
			node.queue_free()
			rows.remove_at(index)
			continue
		if kind == "gate":
			world.update_labels(node)
			_update_gate(row,-z)
			continue
		if bool(row["resolved"]):
			continue
		if kind in ["enemy","drone","barrier"] and int(row["epoch"]) != core.handoff_epoch and core.phase in ["running","telegraph","committed"]:
			row["id"] = core.register_enemy(125 if kind == "drone" else 100 if kind == "enemy" else 50)
			row["epoch"] = core.handoff_epoch
		if kind == "shard":
			node.rotation.y += delta*1.7
			node.position.y = sin(clock*2.6+float(row["at"]))*0.08
		if kind == "enemy" and z>-55 and z<8:
			node.animate(delta)
		if kind == "drone":
			node.position.y = sin(clock*3+float(row["at"]))*0.12
		var contact_width := 1.35 if kind in ["barrier","beam"] else 1.25 if kind == "gap" else 0.70 if kind == "shard" else 0.85
		var same_lane := absf(motor.position.x-LANES[int(row["lane"])]) < contact_width
		var ahead := motor.position.z-z
		if same_lane and kind in ["enemy","drone","barrier"]:
			var attack_range := 13.0 if selected == "witch" else 4.0
			var charging := selected == "knight" and power_left > 0
			if charging and ahead > 0 and ahead < 10:
				if core.resolve_enemy(int(row["id"]),core.power_attack_token):
					_destroy_row(row)
			elif kind != "barrier" and attack_age >= 0.075 and attack_age < 0.30 and ahead > 0 and ahead < attack_range and (selected == "witch" or motor.position.y < 1.6):
				if _line_clear(row) and core.resolve_enemy(int(row["id"]),attack_token):
					_destroy_row(row)
		if bool(row["resolved"]):
			continue
		if same_lane and kind == "shard" and absf(ahead) < 0.9 and motor.position.y < 2.4:
			if core.collect(int(row["id"])):
				shards += 1
				row["resolved"] = true
				node.visible = false
				_sound("pickup",0.95+shards%5*0.055)
		elif same_lane and kind == "gap" and absf(ahead) < 1.8:
			if motor.position.y < 0.18 and core.phase in ["running","telegraph","committed"]:
				core.fail_run("fell_into_fracture")
				row["resolved"] = true
		elif same_lane and kind not in ["shard","gap"] and ahead < 0.65 and ahead > -0.7:
			var clear := (kind == "beam" and (sliding_left > 0.0 or motor.position.y > 1.8)) or (kind == "barrier" and motor.position.y > 1.25) or (kind == "enemy" and motor.position.y > 2.1) or (kind == "drone" and (sliding_left > 0.0 or motor.position.y > 2.1))
			if not clear:
				if kind == "gap" and core.phase in ["running","telegraph","committed"]:
					core.fail_run("fell_into_fracture")
				else:
					_hurt(row)
			row["resolved"] = true
			if kind in ["enemy","drone","barrier"]:
				core.retire_enemy(int(row["id"]))


func _line_clear(target: Dictionary) -> bool:
	for blocker in rows:
		if blocker["resolved"] or blocker["kind"] not in ["barrier","beam"]:
			continue
		if blocker["lane"] == target["lane"] and float(blocker["at"]) > distance and float(blocker["at"]) < float(target["at"]):
			return false
	return true


func _update_gate(row: Dictionary, ahead: float) -> void:
	if ahead > 48.0 or ahead < -2.0 or row["resolved"]:
		return
	var id := "gate-" + str(int(row["at"]))
	if not row["offered"] and core.phase == "running":
		var preview := maxi(Core.MIN_PREVIEW_TICKS,ceili(ahead / 14.0 * 60.0))
		if core.offer_route(id,ROUTE_CHARACTERS[lane],preview):
			row["offered"] = true
	if core.phase == "telegraph" and str(core.route.get("id","")) == id:
		core.select_route_target(id,ROUTE_CHARACTERS[lane])
		if ahead <= 8.0:
			core.commit_route(id)
	ui.route_visible = ahead > 0.0
	ui.route_lane = lane
	ui.route_distance = ahead
	if ahead < 0:
		row["resolved"] = true


func _handle_transition(delta: float) -> void:
	if core.phase == "handoff" and previous_phase != "handoff":
		outgoing = selected
		incoming = str(core.route["target"])
		handoff_age = 0
		heroes[incoming].visible = true
		heroes[incoming].rotation = Vector3.ZERO
		heroes[incoming].moving = true
		power_left = 0
		attack_token = -1
		attack_age = 10
		touches.clear()
		_sound("handoff")
		_pulse(heroes[incoming].accent(),Vector3(motor.position.x,0.1,0),2.0)
	if core.phase == "handoff":
		handoff_age += delta
		var blend := clampf(handoff_age/0.5,0,1)
		heroes[outgoing].position = Vector3(-2.4*blend,0,2.0*blend)
		heroes[incoming].position = Vector3(2.4*(1-blend),1.6*(1-blend) if incoming == "gargoyle" else 0.0,-1.2*(1-blend))
		heroes[incoming].animate(delta)
	if core.phase == "recovery" and previous_phase == "handoff":
		total_handoffs += 1
		handoff_pairs.append(outgoing+"->"+incoming)
		_select_character(core.active_character)
		ui.message("THE " + selected.to_upper() + " TAKES THE LEAD",1.5)
		_capture("handoff-%02d-%s" % [total_handoffs,selected])
	previous_phase = core.phase


func _destroy_row(row: Dictionary) -> void:
	ui.impact("SHATTER" if selected=="knight" else "CRUSH" if selected=="gargoyle" else "HEX",heroes[selected].accent())
	impact_shake=1.0
	row["resolved"] = true
	row["node"].visible = false
	_burst(row["node"].position+Vector3(0,1,0),heroes[selected].accent())
	_sound("impact",1.0 if selected == "knight" else 1.25)
	if profile["settings"]["vibration"] and not qa:
		Input.vibrate_handheld(16)


func _hurt(context: Dictionary = {}) -> void:
	if power_left > 0.0 and selected in ["knight","witch"]:
		return
	if core.receive_damage():
		qa_damage += 1
		qa_incidents.append({"tick":core.tick,"character":selected,"kind":context.get("kind","unknown"),"at":context.get("at",0),"runner_y":motor.position.y,"slide":sliding_left,"attack_age":attack_age,"phase":core.phase})
		ui.flash = 1.0
		_sound("hurt")
		if profile["settings"]["vibration"] and not qa:
			Input.vibrate_handheld(40)


func _attack() -> void:
	var token: int = core.attack()
	if token < 0:
		return
	attack_token = token
	attack_age = 0
	qa_attacks += 1
	heroes[selected].attack()
	if selected == "gargoyle" and motor.position.y > 0.8:
		motor.velocity.y = -8.0
	_sound("spell" if selected == "witch" else "strike")
	_pulse(heroes[selected].accent(),Vector3(motor.position.x,1.1,-1.5),0.65 if selected == "witch" else 1.25)


func _power() -> void:
	if core.phase == "committed":
		return
	var blink_target := _blink_destination() if selected == "witch" else -1
	if selected == "witch" and blink_target < 0:
		ui.message("NO CLEAR RIFT ANCHOR",1.0)
		return
	if not core.use_power():
		return
	qa_powers += 1
	heroes[selected].power()
	match selected:
		"knight":
			power_left = 1.0
			attack_token = core.power_attack_token
			_sound("impact",0.75)
		"gargoyle":
			power_left = 1.25
			motor.velocity.y = maxf(motor.velocity.y,9.5)
			_sound("wing")
		"witch":
			power_left = 0.30
			lane = blink_target
			motor.position.x = LANES[lane]
			motor.position.z = -3.5
			_sound("spell",0.7)
	_pulse(heroes[selected].accent(),Vector3(motor.position.x,0.12,motor.position.z),1.7)


func _blink_destination() -> int:
	var safest := lane
	var best_clearance := -1.0
	for candidate in [lane,(lane+1)%3,(lane+2)%3]:
		var clearance := 14.0
		for row in rows:
			if row["resolved"] or row["kind"] in ["shard","gate"] or int(row["lane"]) != candidate:
				continue
			var forward := float(row["at"])-distance
			if forward > -1.0:
				clearance = minf(clearance,forward)
		if clearance > best_clearance:
			best_clearance = clearance
			safest = candidate
	return safest if best_clearance >= 8.0 else -1


func _jump() -> void:
	if core.phase in ["handoff","recovery"]:
		return
	if motor.is_on_floor():
		motor.velocity.y = 9.0
		sliding_left = 0
		qa_jump_count += 1


func _slide() -> void:
	if core.phase not in ["handoff","recovery"] and motor.is_on_floor():
		if sliding_left <= 0:
			qa_slide_count += 1
		sliding_left = 0.72


func _pulse(color: Color, at: Vector3, radius: float) -> void:
	if effects.size() > 65:
		return
	var b = Geo.new()
	b.ring(Vector3.ZERO,radius,0.027,Geo.material(color,0.0,2.2),Vector3(0.0,0.0,0.0))
	var node: Node3D = b.build()
	add_child(node)
	node.position = at
	effects.append({"node":node,"life":0.35,"max":0.35,"velocity":Vector3(0,0,8),"ring":true})


func _burst(at: Vector3, color: Color) -> void:
	for index in range(7):
		if effects.size() > 65:
			break
		var b = Geo.new()
		b.box(Vector3.ZERO,Vector3.ONE*0.09,Geo.material(color,0.2,1.5))
		var node: Node3D = b.build()
		add_child(node)
		node.position = at
		var velocity := Vector3(fx_rng.randf_range(-3,3),fx_rng.randf_range(1,5),fx_rng.randf_range(2,7))
		effects.append({"node":node,"life":0.5,"max":0.5,"velocity":velocity,"ring":false})


func _update_effects(delta: float) -> void:
	for index in range(effects.size()-1,-1,-1):
		var item: Dictionary = effects[index]
		item["life"] = float(item["life"])-delta
		if float(item["life"]) <= 0:
			item["node"].queue_free()
			effects.remove_at(index)
			continue
		item["node"].position += item["velocity"]*delta
		var amount := float(item["life"])/float(item["max"])
		item["node"].scale = Vector3.ONE*(0.4+amount*0.6)
		if item["ring"]:
			item["node"].rotation.y += delta*4
		else:
			item["velocity"].y -= delta*9
			item["node"].rotate_x(delta*5)


func _intent(action: String, value: String = "") -> void:
	match action:
		"start", "restart":
			_start_run()
		"character":
			_select_character(value)
		"attack":
			_attack()
		"power":
			_power()
		"pause":
			if ui.mode == "game" and core.pause():
				touches.clear()
				ui.set_mode("pause")
		"resume":
			if core.resume():
				touches.clear()
				ui.set_mode("game")
		"home":
			ui.set_mode("menu")
			motor.position = Vector3.ZERO
			_select_character(selected)
		"settings":
			ui.previous_mode = ui.mode
			ui.set_mode("settings")
		"back":
			ui.set_mode("settings" if ui.mode == "credits" else ui.previous_mode)
		"credits":
			ui.set_mode("credits")
		"setting":
			profile["settings"][value] = not bool(profile["settings"][value])
			ui.settings = profile["settings"].duplicate(true)
			_apply_settings()
			_save_profile()
			ui.refresh()


func _end_run() -> void:
	profile["best"] = maxf(float(profile["best"]),distance)
	profile["last_run"] = {"seed":core.seed_value,"distance_m":distance,"score":core.score,"handoffs":total_handoffs,"starting_character":starting_character}
	if not qa:
		_save_profile()
	ui.end_distance = distance
	ui.end_score = core.score
	ui.best = profile["best"]
	ui.shard_count = shards
	ui.set_mode("results")
	if qa:
		qa_deaths += 1
		_qa_finish()


func _apply_settings() -> void:
	Engine.max_fps = 60 if profile["settings"]["quality"] else 30
	get_viewport().msaa_3d = Viewport.MSAA_2X if profile["settings"]["quality"] else Viewport.MSAA_DISABLED
	key_light.shadow_enabled = profile["settings"]["quality"]
	if is_instance_valid(music):
		music.volume_db = -18 if profile["settings"]["music"] else -80


func _load_profile() -> void:
	for path in ["user://profile-v1.json","user://profile-v1.previous.json"]:
		if not FileAccess.file_exists(path):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and parsed.get("schema") == 1:
			var best_value = parsed.get("best",0.0)
			if (best_value is float or best_value is int) and is_finite(float(best_value)):
				profile["best"] = maxf(0,float(best_value))
			var values = parsed.get("settings",{})
			if values is Dictionary:
				for key in profile["settings"]:
					if values.get(key) is bool:
						profile["settings"][key] = values[key]
			break


func _save_profile() -> void:
	var temporary := "user://profile-v1.pending.json"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(profile))
	file.close()
	var root := OS.get_user_data_dir()
	if FileAccess.file_exists("user://profile-v1.json"):
		DirAccess.remove_absolute(root+"/profile-v1.previous.json")
		DirAccess.rename_absolute(root+"/profile-v1.json",root+"/profile-v1.previous.json")
	DirAccess.rename_absolute(root+"/profile-v1.pending.json",root+"/profile-v1.json")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_intent("resume" if ui.mode == "pause" else "pause")
		elif event.keycode == KEY_ENTER and ui.mode == "menu":
			_start_run()
		elif ui.mode == "game":
			match event.keycode:
				KEY_LEFT, KEY_A: _move_lane(-1)
				KEY_RIGHT, KEY_D: _move_lane(1)
				KEY_UP, KEY_W: _jump()
				KEY_DOWN, KEY_S: _slide()
				KEY_SPACE: _attack()
				KEY_E: _power()
	if ui.mode != "game":
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = {"start":event.position,"used":false}
		elif touches.has(event.index):
			if not touches[event.index]["used"]:
				_gesture(event.position-touches[event.index]["start"])
			touches.erase(event.index)
	elif event is InputEventScreenDrag and touches.has(event.index) and not touches[event.index]["used"]:
		var drag: Vector2 = event.position-touches[event.index]["start"]
		if drag.length() > 42:
			_gesture(drag)
			touches[event.index]["used"] = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			touches[-1] = {"start":event.position,"used":false}
		elif touches.has(-1):
			_gesture(event.position-touches[-1]["start"])
			touches.erase(-1)


func _gesture(direction: Vector2) -> void:
	if direction.length() < 30 or core.phase in ["handoff","recovery","committed"]:
		return
	if absf(direction.x) > absf(direction.y):
		_move_lane(1 if direction.x > 0 else -1)
	elif direction.y < 0:
		_jump()
	else:
		_slide()


func _move_lane(direction: int) -> void:
	if core.phase not in ["handoff","recovery","committed"]:
		lane = clampi(lane+direction,0,2)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT] and not qa and is_instance_valid(ui) and ui.mode == "game":
		_intent("pause")
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(ui):
		if ui.mode == "game":
			_intent("pause")
		elif ui.mode == "pause":
			_intent("resume")
		elif ui.mode in ["settings","credits"]:
			_intent("back")
		else:
			_quit_gracefully()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_gracefully()


func _qa_control() -> void:
	if core.phase == "telegraph":
		lane = qa_target_sequence[total_handoffs%qa_target_sequence.size()]
	var closest: Dictionary = {}
	var best_distance := 22.0
	for row in rows:
		if row["resolved"] or row["kind"] in ["shard","gate"] or int(row["lane"]) != lane:
			continue
		var ahead := float(row["at"])-distance+motor.position.z
		if ahead > 0 and ahead < best_distance:
			closest = row
			best_distance = ahead
	if not closest.is_empty():
		if selected == "knight" and closest["kind"] in ["enemy","barrier"] and best_distance < 9.0:
			_power()
		if closest["kind"] in ["enemy","drone"] and best_distance < (12 if selected == "witch" else 5.0):
			_attack()
		elif closest["kind"] in ["barrier","gap"] and best_distance < 6.0:
			_jump()
		elif closest["kind"] == "beam" and best_distance < 6.0:
			_slide()
		if best_distance < 3.0 and closest["kind"] in ["enemy","drone"] and core.phase == "running" and core.tick % 12 == 0:
			_move_lane(-1 if lane > 0 else 1)
	if core.tick > 120 and core.tick%700 == 120:
		_power()


func _capture(name: String) -> void:
	if capture_dir.is_empty() or capture_busy or captures.has(name) or DisplayServer.get_name() == "headless":
		return
	capture_busy = true
	captures[name] = true
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image != null:
		image.save_png(capture_dir+"/"+name+".png")
	capture_busy = false


func _qa_finish() -> void:
	if quitting:
		return
	var report := {
		"engine":Engine.get_version_info()["string"],"ticks":qa_ticks,
		"distance_m":distance,"score":core.score,"shards":shards,"health":core.health,
		"handoffs":total_handoffs,"pairs":handoff_pairs,"deaths":qa_deaths,
		"attacks":qa_attacks,"powers":qa_powers,"damage_events":qa_damage,
		"scene_nodes":get_tree().get_node_count(),"active_rows":rows.size(),
		"active_effects":effects.size(),"captures":captures.keys(),
		"incidents":qa_incidents,"starting_character":starting_character,
		"jumps":qa_jump_count,"peak_jump_height_m":qa_peak_height,"slides":qa_slide_count,"offscreen_character_ticks":qa_offscreen_ticks,
		"phase":core.phase,"scope":"Automated desktop/headless scene run; not an Android device test"
	}
	var file := FileAccess.open("res://tests/evidence/scene-run-"+starting_character+".json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report,"  "))
	print("SCENE_QA "+JSON.stringify(report))
	_quit_gracefully(0 if qa_deaths == 0 and total_handoffs >= 3 else 1)


func _preview_menu() -> void:
	await get_tree().create_timer(1.1).timeout
	await _capture("menu-"+selected)
	_quit_gracefully()


func _quit_gracefully(code: int = 0) -> void:
	if quitting:
		return
	quitting = true
	if is_instance_valid(ui):
		ui.mode = "closing"
	_stop_audio()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit(code)


func _stop_audio() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for player in effect_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	sounds.clear()


func _exit_tree() -> void:
	_stop_audio()
	Geo.release_shared()
	preload("res://game/rig_motion.gd").release_shared()
