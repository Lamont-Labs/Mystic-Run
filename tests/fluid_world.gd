extends SceneTree
const Hero=preload("res://game/hero.gd")
const World=preload("res://game/world.gd")
const Biomes=preload("res://core/biome_progression.gd")
var checks:int=0
var failures:Array[String]=[]

func _initialize() -> void:
	call_deferred("run")

func check(value:bool,message:String) -> void:
	checks+=1
	if not value:
		failures.append(message)
		push_error(message)

func run() -> void:
	for identity in ["knight","gargoyle","witch"]:
		var hero=Hero.new()
		root.add_child(hero)
		hero.configure(identity)
		hero.facing=PI
		hero.moving=true
		var samples:Dictionary={}
		for frame in range(60):
			hero.animate(1.0/60.0)
			var joints:PackedFloat32Array=hero.motion_art.joint_samples
			samples[str(roundf(joints[0]*1000))]=true
			check(is_finite(joints[0]) and absf(joints[0])<=.241,identity+" bounded limb angles")
		check(samples.size()>=16,identity+" has more than sixteen distinct continuous stride samples")
		check(hero.motion_art.mesh.surface_get_array_len(0)==957,identity+" uses a bounded articulated mesh")
		hero.airborne=true;hero.airborne_velocity=2
		hero.animate(.016)
		check(hero.motion_art.blend<1,identity+" jump enters a blended transition")
		hero.airborne_velocity=-2;hero.animate(.016)
		check(hero.concept_sprite.texture==hero.concept_action_textures["fall_rear"],identity+" has a distinct fall pose")
		hero.airborne=false;hero.hurt_left=.3;hero.animate(.016)
		check(hero.concept_sprite.texture==hero.concept_action_textures["damage_rear"],identity+" has distinct damage recovery")
		hero.reduced_motion=true
		for i in range(60):hero.animate(1.0/60.0)
		check(hero.motion_art.stride_weight<.001,identity+" reduced motion suppresses articulation")
		if identity=="gargoyle":
			check(is_equal_approx(hero.concept_sprite_height/2.48,1.59/2.48),"Gargoyle is 35.9 percent smaller")
		hero.free()
	for station in [0.0,100.0,320.0,383.999,384.0,700.0,767.999,768.0,1100.0,1152.0,100000.0]:
		check(Biomes.sample(station)==Biomes.sample(station),"biome sampling is deterministic")
		check(Biomes.sample(station).blend>=0 and Biomes.sample(station).blend<=1,"bounded biome crossfade")
	check(Biomes.sample(0).id=="castle","Castle Heights begins every endless run")
	check(Biomes.sample(400).id=="wilds","Enchanted Wilds follows Castle Heights")
	check(Biomes.sample(800).id=="ember","Ember Ruins follows Enchanted Wilds")
	check(Biomes.sample(383.999).next==Biomes.sample(384).index,"first crossfade ends on the incoming biome")
	check(Biomes.sample(767.999).next==Biomes.sample(768).index,"second crossfade ends on the incoming biome")
	var world=World.new()
	root.add_child(world)
	world.configure()
	world.biome_progression=true
	for station in [0.0,330.0,400.0,720.0,800.0,1200.0,10000.0]:
		world.update(station,.016)
		check(world.chunks.size()==11 and world.living.nodes.size()==12,"fixed pools at every distance")
		check(world.living_plate.visible and not world.horizon_plate.visible,"living panorama replaces old backdrop")
		check(world.biome_state==Biomes.sample(station),"live scene follows pure distance-based biome state")
		for node in world.living.nodes:
			var landmark_station:float=maxf(0,station-node.position.z)
			var corridor_x:float=preload("res://core/course_profile.gd").lateral_at(landmark_station,station)
			check(absf(node.position.x-corridor_x)>9.0,"landmarks remain outside curved obstacle corridor")
	world.free()
	if failures.is_empty():
		print("FLUID_WORLD_PASS checks=",checks)
		quit(0)
	else:
		printerr("FLUID_WORLD_FAIL ",failures)
		quit(1)
