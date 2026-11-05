extends SceneTree
## Actual imported creature geometry, skinning, wing poses and expression state.
var checks:int=0
var failures:Array[String]=[]
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func posed_bounds(actor:Node3D,wings_only:bool=true) -> AABB:
	var node:MeshInstance3D=actor.authored_mesh
	var arrays:Array=node.mesh.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
	var joints:PackedInt32Array=arrays[Mesh.ARRAY_BONES]
	var skin:Skin=node.skin
	var morphs:Array=node.mesh.surface_get_blend_shape_arrays(0)
	var bones:Array[int]=[]
	for bind in range(skin.get_bind_count()):
		var name:String=str(skin.get_bind_name(bind))
		bones.append(actor.skeleton.find_bone(name) if not name.is_empty() else skin.get_bind_bone(bind))
	var started:bool=false;var result:AABB
	actor.skeleton.force_update_all_bone_transforms()
	for i in range(vertices.size()):
		var wing:bool=false;var point:Vector3=Vector3.ZERO
		var vertex:Vector3=vertices[i]
		for shape in range(morphs.size()):
			var weight:float=node.get_blend_shape_value(shape)
			if absf(weight)>.00001:
				var target:Vector3=morphs[shape][Mesh.ARRAY_VERTEX][i]
				vertex+=(target-vertices[i] if node.mesh.get_blend_shape_mode()==Mesh.BLEND_SHAPE_MODE_NORMALIZED else target)*weight
		for influence in range(4):
			var at:int=i*4+influence
			if weights[at]<=0:continue
			var bind:int=joints[at];var bone:int=bones[bind]
			if bone<0:continue
			wing=wing or str(actor.skeleton.get_bone_name(bone)).begins_with("wing_")
			point+=(actor.skeleton.get_bone_global_pose(bone)*skin.get_bind_pose(bind)*vertex)*weights[at]
		if wing or not wings_only:
			point=actor.global_transform.affine_inverse()*actor.skeleton.global_transform*point
			if not started:result=AABB(point,Vector3.ZERO);started=true
			else:result=result.expand(point)
	return result
func run() -> void:
	var actor=load("res://game/hero.gd").new();actor.configure("gargoyle");root.add_child(actor)
	await process_frame
	var node:MeshInstance3D=actor.authored_mesh
	check(is_instance_valid(node) and node.mesh.get_surface_count()==1,"Gargoyle uses one imported body/wing material surface")
	var arrays:Array=node.mesh.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var horn_samples:int=0;var outward_horns:bool=true
	for i in range(vertices.size()):
		var p:Vector3=vertices[i]
		if p.y>2.02 and p.y<2.08 and absf(p.x)<.24:
			if p.z<-.12:horn_samples+=1;outward_horns=outward_horns and normals[i].z<-.15
			elif p.z>-.064:horn_samples+=1;outward_horns=outward_horns and normals[i].z>.15
	check(horn_samples>=8 and outward_horns,"Actual exterior horn normals face away from the swept centreline")
	var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
	var joints:PackedInt32Array=arrays[Mesh.ARRAY_BONES]
	check(indices.size()/3<=30000,"Complete creature stays below the 30,000-triangle hero budget")
	check(actor.skeleton.get_bone_count()==69 and actor.wing_controls.size()==4,"Retained humanoid rig plus four imported wing controls")
	var valid:bool=weights.size()==vertices.size()*4 and joints.size()==weights.size()
	for vertex in range(vertices.size()):
		var total:float=0
		for k in range(4):
			var at:int=vertex*4+k
			total+=weights[at];valid=valid and weights[at]>=0 and joints[at]>=0 and joints[at]<node.skin.get_bind_count()
		valid=valid and absf(total-1)<.002 and vertices[vertex].is_finite()
	check(valid,"Finite geometry and normalized weights reference valid skin bindings")
	var shapes:Array[String]=[]
	for i in range(node.mesh.get_blend_shape_count()):shapes.append(str(node.mesh.get_blend_shape_name(i)))
	check(shapes==["Blink","Smile","Focus","Surprised","Hurt"],"Five creature-specific facial morph targets survive import")
	check(actor.skeleton.get_bone_pose_scale(actor.skeleton.find_bone("Head")).is_equal_approx(Vector3.ONE),"Authored head uses its own anatomy without legacy cosmetic enlargement")
	actor.moving=true;actor.reduced_motion=true
	for i in range(60):actor.animate(1.0/60)
	var folded:AABB=posed_bounds(actor)
	actor.airborne=true
	for i in range(60):actor.animate(1.0/60)
	var gliding:AABB=posed_bounds(actor)
	check(gliding.size.x>folded.size.x*1.2,"Skinned wing vertices unfold for airborne/glide state")
	actor.airborne=false;actor.sliding=true
	var active_slide_top:float=0.0
	for i in range(60):
		actor.animate(1.0/60)
		if i>=18 and i<=38:active_slide_top=maxf(active_slide_top,posed_bounds(actor,false).end.y)
	var sliding:AABB=posed_bounds(actor)
	var full_slide:AABB=posed_bounds(actor,false)
	check(sliding.size.x<gliding.size.x*.80,"Actual wing mesh folds for the slide state")
	check(sliding.end.y<1.255,"Folded wing geometry clears the actual lower beam trim")
	check(full_slide.end.y<1.255,"Complete skinned body, horns and wings clear the lower beam trim in slide pose")
	check(active_slide_top+.014<1.255,"Complete character clears the beam across contact, including the maximum decorative idle offset")
	actor.sliding=false
	for i in range(90):actor.animate(1.0/60)
	var before:Array[Quaternion]=[]
	for control in actor.wing_controls:before.append(actor.skeleton.get_bone_pose_rotation(control.index))
	for i in range(60):actor.animate(1.0/60)
	var stable:bool=true
	for i in range(before.size()):stable=stable and before[i].is_equal_approx(actor.skeleton.get_bone_pose_rotation(actor.wing_controls[i].index))
	check(stable,"Reduced Motion settles wing-local cosmetic movement")
	actor.attack();actor.animate(1.0/60)
	check(actor.facial_state=="determined" and node.get_blend_shape_value(actor.face_shapes.Focus)>0,"Punch event drives creature face without changing action authority")
	actor.celebrate();actor.animate(1.0/60)
	check(actor.facial_state=="pleased" and node.get_blend_shape_value(actor.face_shapes.Smile)>0,"Celebration drives the creature smile")
	actor.react_to_hit();actor.animate(1.0/60)
	check(actor.facial_state=="hurt" and node.get_blend_shape_value(actor.face_shapes.Hurt)>0,"Accepted hit reaction drives the hurt expression")
	var result:Dictionary={"checks":checks,"failed":failures.size(),"failures":failures,"triangles":indices.size()/3,"bones":actor.skeleton.get_bone_count(),"outward_horn_samples":horn_samples,"wing_width_run":folded.size.x,"wing_width_glide":gliding.size.x,"wing_width_slide":sliding.size.x,"wing_slide_top":sliding.end.y,"full_slide_top":full_slide.end.y,"active_slide_top":active_slide_top,"scope":"Actual imported mesh, exterior curve normals, skin, wing deformation, facial state and desktop pose checks; not physical-device performance or final art approval"}
	actor.queue_free();await process_frame;load("res://game/rig_motion.gd").release_shared()
	FileAccess.open("res://tests/evidence/gargoyle-asset.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("GARGOYLE_ASSET_QA ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)
