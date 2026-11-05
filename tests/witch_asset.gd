extends SceneTree
## Actual imported Witch geometry, full skinning, braid, staff and face states.
var checks:int=0
var failures:Array[String]=[]
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func posed_bounds(actor:Node3D,wings_only:bool=false) -> AABB:
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
	var actor=load("res://game/hero.gd").new();actor.configure("witch");root.add_child(actor)
	await process_frame
	var node:MeshInstance3D=actor.authored_mesh
	check(is_instance_valid(node) and node.mesh.get_surface_count()==1,"Witch body, clothes, braid and staff use one imported material surface")
	var arrays:Array=node.mesh.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
	var joints:PackedInt32Array=arrays[Mesh.ARRAY_BONES]
	check(indices.size()/3<=30000,"Complete Witch stays below the 30,000-triangle hero budget")
	check(actor.skeleton.get_bone_count()==68 and actor.braid_controls.size()==2 and not actor.staff_control.is_empty(),"Retained female rig plus two braid controls and one staff control")
	var valid:bool=weights.size()==vertices.size()*4 and joints.size()==weights.size()
	var braid_weighted:int=0;var staff_weighted:int=0
	for vertex in range(vertices.size()):
		var total:float=0
		for k in range(4):
			var at:int=vertex*4+k;total+=weights[at]
			valid=valid and weights[at]>=0 and joints[at]>=0 and joints[at]<node.skin.get_bind_count()
			if weights[at]>0 and joints[at]<node.skin.get_bind_count():
				var name:String=str(node.skin.get_bind_name(joints[at]))
				if name.begins_with("braid_"):braid_weighted+=1
				if name=="staff_control":staff_weighted+=1
		valid=valid and absf(total-1)<.002 and vertices[vertex].is_finite()
	check(valid,"Finite geometry and normalized weights reference valid skin bindings")
	check(braid_weighted>100 and staff_weighted>100,"Visible braid and staff vertices are weighted to imported controls")
	var shapes:Array[String]=[]
	for i in range(node.mesh.get_blend_shape_count()):shapes.append(str(node.mesh.get_blend_shape_name(i)))
	check(shapes==["Blink","Smile","Focus","Surprised","Hurt"],"Five authored facial morph targets survive import")
	var morphs:Array=node.mesh.surface_get_blend_shape_arrays(0)
	var finite_face:bool=true;var substantial:bool=true;var closed_eye:bool=true
	for shape in range(morphs.size()):
		var target:PackedVector3Array=morphs[shape][Mesh.ARRAY_VERTEX];var changed:int=0
		for i in range(vertices.size()):
			var delta:Vector3=target[i]-vertices[i] if node.mesh.get_blend_shape_mode()==Mesh.BLEND_SHAPE_MODE_NORMALIZED else target[i]
			finite_face=finite_face and delta.is_finite()
			if delta.length()>.000001:
				changed+=1;finite_face=finite_face and vertices[i].y>1.55
				if shape==0:closed_eye=closed_eye and absf((vertices[i]+delta).y-1.785)<.0015 and absf(delta.x)<.00001 and absf(delta.z)<.00001
		substantial=substantial and changed>100
	check(finite_face and substantial,"Imported facial morphs deform substantial finite face geometry and preserve the costume")
	check(closed_eye,"Actual blink geometry closes at the Witch eye centre without lateral drift")
	check(actor.skeleton.get_bone_pose_scale(actor.skeleton.find_bone("Head")).is_equal_approx(Vector3.ONE),"Authored Witch head has no legacy cosmetic enlargement")
	var staff:int=actor.skeleton.find_bone("staff_control")
	var hand:int=actor.skeleton.find_bone("hand_r")
	check(actor.skeleton.get_bone_parent(staff)==hand,"Staff control retains the actual cast hand as its parent")
	actor.moving=true
	for i in range(60):actor.animate(1.0/60)
	var run_bounds:AABB=posed_bounds(actor)
	var before:Quaternion=actor.skeleton.get_bone_pose_rotation(actor.braid_controls[0].index)
	for i in range(20):actor.animate(1.0/60)
	check(not before.is_equal_approx(actor.skeleton.get_bone_pose_rotation(actor.braid_controls[0].index)),"Imported braid bones supply visible secondary motion")
	actor.attack()
	var grip_error:float=0
	for i in range(36):
		actor.animate(1.0/60);actor.skeleton.force_update_all_bone_transforms()
		grip_error=maxf(grip_error,actor.skeleton.get_bone_global_pose(staff).origin.distance_to(actor.skeleton.get_bone_global_pose(hand).origin))
	check(grip_error<.001,"Staff grip stays attached throughout the actual casting clip")
	var active_top:float=0;var steady_top:float=0
	for reduced in [false,true]:
		actor.sliding=false;actor.reduced_motion=reduced
		for i in range(60):actor.animate(1.0/60)
		actor.sliding=true
		for i in range(60):
			actor.animate(1.0/60)
			if i>=18 and i<=38:active_top=maxf(active_top,posed_bounds(actor).end.y)
		steady_top=maxf(steady_top,posed_bounds(actor).end.y)
	check(steady_top<1.255,"Complete Witch, hat, braid, coat and staff clear the lower beam in slide pose")
	check(active_top+.014<1.255,"Complete skinned Witch clears contact with normal/Reduced Motion and a conservative idle margin")
	check(run_bounds.end.y>steady_top*1.5,"Slide visibly compacts the whole character and staff")
	actor.sliding=false;actor.reduced_motion=true
	for i in range(90):actor.animate(1.0/60)
	before=actor.skeleton.get_bone_pose_rotation(actor.braid_controls[0].index)
	for i in range(60):actor.animate(1.0/60)
	check(before.is_equal_approx(actor.skeleton.get_bone_pose_rotation(actor.braid_controls[0].index)),"Reduced Motion stops decorative braid movement")
	actor.attack();actor.animate(1.0/60)
	check(actor.facial_state=="determined" and node.get_blend_shape_value(actor.face_shapes.Focus)>0,"Casting drives the authored focus expression")
	actor.celebrate();actor.animate(1.0/60)
	check(actor.facial_state=="pleased" and node.get_blend_shape_value(actor.face_shapes.Smile)>0,"Celebration drives the authored smile")
	actor.react_to_hit();actor.animate(1.0/60)
	check(actor.facial_state=="hurt" and node.get_blend_shape_value(actor.face_shapes.Hurt)>0,"Accepted hit reaction retains face priority")
	var result:Dictionary={"checks":checks,"failed":failures.size(),"failures":failures,"triangles":indices.size()/3,"bones":actor.skeleton.get_bone_count(),"run_top":run_bounds.end.y,"full_slide_top":steady_top,"active_slide_top":active_top,"additional_idle_margin_m":.014,"grip_error_m":grip_error,"braid_influences":braid_weighted,"staff_influences":staff_weighted,"scope":"Actual imported mesh, morph geometry, skin, staff grip and desktop slide poses; not physical-device performance or final art approval"}
	actor.queue_free();await process_frame;load("res://game/rig_motion.gd").release_shared()
	FileAccess.open("res://tests/evidence/witch-asset.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("WITCH_ASSET_QA ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)
