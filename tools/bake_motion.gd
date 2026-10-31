extends SceneTree
## Run after importing the two free Standard animation GLBs. Saves only the nine
## used clips, so unused animations and mannequin geometry stay out of the APK.
const SOURCES := ["res://assets/models/quaternius/animations/UAL1_Standard.glb","res://assets/models/quaternius/animations/UAL2_Standard.glb"]
const REQUIRED := ["Idle","Sprint","Jump","Slide","Crouch_Fwd","Sword_Regular_A","Punch_Cross","Spell_Simple_Shoot","Shield_Dash"]
func _initialize() -> void:
	var library:=AnimationLibrary.new()
	var rests: Dictionary={}
	for source in SOURCES:
		var scene: Node=(load(source) as PackedScene).instantiate()
		var player: AnimationPlayer=scene.find_child("AnimationPlayer",true,false)
		var rig: Skeleton3D=scene.find_child("Skeleton3D",true,false)
		for clip in REQUIRED:
			if not player.has_animation(clip): continue
			library.add_animation(clip,player.get_animation(clip).duplicate(true))
			var bones: Dictionary={}
			for index in range(rig.get_bone_count()):
				var rest:=rig.get_bone_rest(index)
				var q:=rest.basis.get_rotation_quaternion()
				bones[rig.get_bone_name(index)]={"position":[rest.origin.x,rest.origin.y,rest.origin.z],"rotation":[q.x,q.y,q.z,q.w]}
			rests[clip]=bones
		scene.free()
	assert(library.get_animation_list().size()==REQUIRED.size())
	var error:=ResourceSaver.save(library,"res://assets/models/quaternius/animations/runner-motion.res",ResourceSaver.FLAG_COMPRESS)
	assert(error==OK)
	FileAccess.open("res://assets/models/quaternius/animations/source-rests.json",FileAccess.WRITE).store_string(JSON.stringify(rests))
	print("BAKED_MOTION ",library.get_animation_list())
	quit()
