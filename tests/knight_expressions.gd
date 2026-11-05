extends SceneTree
## Imported morph geometry and its actual gameplay presentation state.
var failures:Array[String]=[]
var checks:int=0
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var hero=load("res://game/hero.gd").new();hero.configure("knight");root.add_child(hero)
	await process_frame
	var mesh:ArrayMesh=hero.authored_mesh.mesh
	var base:PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var shapes:Array=mesh.surface_get_blend_shape_arrays(0)
	var finite:bool=true
	var body_preserved:bool=true
	var expressive:bool=true
	for i in range(shapes.size()):
		var values:PackedVector3Array=shapes[i][Mesh.ARRAY_VERTEX]
		var changed:int=0
		for v in range(values.size()):
			var delta:Vector3=values[v]-base[v] if mesh.get_blend_shape_mode()==Mesh.BLEND_SHAPE_MODE_NORMALIZED else values[v]
			finite=finite and delta.is_finite()
			if delta.length()>.000001:
				changed+=1
				body_preserved=body_preserved and base[v].y>1.55
		expressive=expressive and changed>100
	check(shapes.size()==6 and expressive,"All six imported morphs change substantial geometry")
	check(finite and body_preserved,"Facial/secondary morph deltas are finite and leave the body untouched")
	var evidence:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/knight/PROVENANCE.json"))
	var blink:PackedVector3Array=shapes[0][Mesh.ARRAY_VERTEX]
	var correct_plane:bool=true
	for i in range(blink.size()):
		var delta:Vector3=blink[i]-base[i] if mesh.get_blend_shape_mode()==Mesh.BLEND_SHAPE_MODE_NORMALIZED else blink[i]
		if delta.length()>.000001:
			var closed:Vector3=base[i]+delta
			correct_plane=correct_plane and absf(closed.y-float(evidence.blink_closure_y))<.0015 and absf(delta.x)<.00001 and absf(delta.z)<.00001
	check(correct_plane,"Blink closes around the transformed eye centre without lateral drift")
	hero.set_expression("auto");hero.attack();hero.animate(1.0/60)
	check(hero.facial_state=="determined" and hero.authored_mesh.get_blend_shape_value(hero.face_shapes.Focus)>0,"A real strike drives the determined expression")
	hero.celebrate();hero.animate(1.0/60)
	check(hero.facial_state=="pleased" and hero.authored_mesh.get_blend_shape_value(hero.face_shapes.Smile)>0,"Celebration drives the smile")
	hero.react_to_hit();hero.animate(1.0/60)
	check(hero.facial_state=="hurt" and hero.authored_mesh.get_blend_shape_value(hero.face_shapes.Hurt)>0,"Hurt reaction takes priority over celebration and strike")
	for i in range(90):hero.animate(1.0/60)
	check(hero.facial_state=="neutral" and hero.hurt_left==0,"Hurt and celebration recover automatically")
	hero.airborne=true;hero.animate(1.0/60)
	check(hero.facial_state=="surprised","Jumping drives the airborne face")
	hero.airborne=false;hero.moving=true;hero.animate(1.0/60)
	check(hero.facial_state=="alert","Running returns to the alert face")
	check(not hero.set_expression("unreviewed") and hero.expression_override=="auto","Unknown stage expression cannot change state")
	hero.set_expression("determined")
	for i in range(25):hero.animate(1.0/60)
	hero.blink_clock=3.75-1.0/60;hero.animate(1.0/60)
	check(hero.authored_mesh.get_blend_shape_value(hero.face_shapes.Blink)>.99 and absf(hero.authored_mesh.get_blend_shape_value(hero.face_shapes.Focus))<.001,"Blink suppresses the overlapping eye expression and prevents inversion")
	hero.reduced_motion=true;hero.animate(1.0/60)
	check(is_zero_approx(hero.authored_mesh.get_blend_shape_value(hero.face_shapes.Blink)) and is_zero_approx(hero.authored_mesh.get_blend_shape_value(hero.face_shapes.PlumeSway)),"Reduced Motion stops decorative blink and plume motion")
	check(hero.authored_mesh.get_blend_shape_value(hero.face_shapes.Focus)>.5,"Reduced Motion retains the readable action expression")
	var bounded:bool=true
	for expression in ["neutral","alert","pleased","determined","surprised","hurt"]:
		hero.set_expression(expression)
		for frame in range(45):hero.animate(1.0/60)
		for index in range(mesh.get_blend_shape_count()):
			var weight:float=hero.authored_mesh.get_blend_shape_value(index)
			bounded=bounded and is_finite(weight) and weight>=-.56 and weight<=1.0
	check(bounded,"Every staged expression settles to finite bounded morph weights")
	var other=load("res://game/hero.gd").new();other.configure("knight");root.add_child(other);other.sentinel();other.set_expression("pleased");other.animate(.1)
	check(hero.facial_state=="hurt" and other.facial_state=="pleased" and hero.authored_mesh!=other.authored_mesh,"Enemy and player expression weights remain isolated")
	hero.queue_free();other.queue_free();await process_frame
	load("res://game/rig_motion.gd").release_shared()
	var report:Dictionary={"checks":checks,"failed":failures.size(),"failures":failures,"scope":"Actual imported morph geometry, eye closure, gameplay expression priority, Reduced Motion and instance isolation; no phone or final art approval"}
	FileAccess.open("res://tests/evidence/knight-expressions.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("KNIGHT_EXPRESSIONS_QA ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
