extends SceneTree
var failures: Array[String]=[]
var checks: int=0
func check(condition: bool, description: String) -> void:
	checks+=1
	if not condition: failures.append(description)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for kind in ["knight","gargoyle","witch"]:
		var hero=load("res://game/hero.gd").new()
		hero.configure(kind)
		root.add_child(hero)
		await process_frame
		hero.moving=true
		var skeleton: Skeleton3D=hero.skeleton
		if kind=="knight":
			var mesh:MeshInstance3D=hero.authored_mesh
			check(is_instance_valid(mesh) and mesh.mesh.get_surface_count()==1,"Knight: authored mesh uses one main material surface")
			check(mesh.mesh.get_blend_shape_count()==2 and str(mesh.mesh.get_blend_shape_name(0))=="Blink" and str(mesh.mesh.get_blend_shape_name(1))=="PlumeSway","Knight: expression and plume morph targets survive import")
			var arrays:Array=mesh.mesh.surface_get_arrays(0)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			var joints:PackedInt32Array=arrays[Mesh.ARRAY_BONES]
			var valid_skin:bool=weights.size()==vertices.size()*4 and joints.size()==weights.size()
			for vertex in range(vertices.size()):
				var total:float=0.0
				for influence in range(4):
					var at:int=vertex*4+influence
					if at<weights.size():
						total+=weights[at]
						valid_skin=valid_skin and weights[at]>=0.0 and joints[at]>=0 and joints[at]<mesh.skin.get_bind_count()
				valid_skin=valid_skin and absf(total-1.0)<.002 and vertices[vertex].is_finite()
			check(valid_skin,"Knight: finite vertices and normalized weights reference valid skin bindings")
			check(indices.size()/3<=25000,"Knight: source mesh stays within the first-pass 25,000 triangle ceiling")
			var sentinel=load("res://game/hero.gd").new();sentinel.configure("knight");root.add_child(sentinel);sentinel.sentinel()
			check(sentinel.authored_mesh.material_override.get_shader_parameter("sentinel_palette")==true and mesh.material_override.get_shader_parameter("sentinel_palette")==false,"Knight: enemy recoloring does not modify the playable material")
			sentinel.queue_free();await process_frame
		var thigh:=skeleton.find_bone("thigh_l")
		var first: Quaternion=skeleton.get_bone_pose_rotation(thigh)
		var excursion:=0.0
		for frame in range(40):
			hero.animate(1.0/60)
			excursion=maxf(excursion,first.angle_to(skeleton.get_bone_pose_rotation(thigh)))
		check(excursion>.3,kind+": authored run changes the leg pose")
		var legs_before: Quaternion=skeleton.get_bone_pose_rotation(thigh)
		hero.attack()
		for frame in range(12): hero.animate(1.0/60)
		check(legs_before.angle_to(skeleton.get_bone_pose_rotation(thigh))>.1,kind+": attack preserves ongoing leg motion")
		var stable_lengths:=true
		var finite_pose:=true
		for index in range(skeleton.get_bone_count()):
			var name:=str(skeleton.get_bone_name(index))
			if name!="pelvis": stable_lengths=stable_lengths and skeleton.get_bone_pose_position(index).is_equal_approx(skeleton.get_bone_rest(index).origin)
			finite_pose=finite_pose and skeleton.get_bone_global_pose(index).origin.is_finite()
		check(stable_lengths,kind+": retargeting preserves target limb lengths")
		check(finite_pose,kind+": all animated bone transforms are finite")
		hero.sliding=true
		for frame in range(24): hero.animate(1.0/60)
		var head_height: float=skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin.y*hero.body.scale.y
		check(head_height<1.15 and head_height>.25,kind+": authored slide fits under the beam")
		hero.sliding=false
		hero.airborne=true
		for frame in range(24): hero.animate(1.0/60)
		check(skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin.y>1.0,kind+": jump restores an upright torso")
		# The cartoon landing affects presentation only and must settle cleanly.
		hero.airborne=false;hero.moving=false
		var lowest_scale:float=hero.body.scale.y
		for frame in range(40):
			hero.animate(1.0/60)
			lowest_scale=minf(lowest_scale,hero.body.scale.y)
		check(lowest_scale<hero.body.scale.y*.95 and hero.body.scale.is_finite(),kind+": landing squash settles to a finite resting scale")
		hero.reduced_motion=true;hero.celebrate()
		for frame in range(12):hero.animate(1.0/60)
		var decorative_motion_stopped:bool=is_zero_approx(hero.body.position.y)
		if is_instance_valid(hero.cape):decorative_motion_stopped=decorative_motion_stopped and is_zero_approx(hero.cape.rotation.x) and is_zero_approx(hero.cape_fabric.get_shader_parameter("motion_amount"))
		check(decorative_motion_stopped,kind+": reduced motion stops decorative bounce and cape flutter")
		hero.queue_free()
		await process_frame
	load("res://game/rig_motion.gd").release_shared()
	var report: Dictionary={"checks":checks,"failures":failures,"failed":failures.size(),"scope":"Authored Knight import/skin/material isolation, motion sampling, upper-body combat, target proportions, slide clearance; no physical-phone test"}
	FileAccess.open("res://tests/evidence/rig-motion.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("RIG_MOTION_QA ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
