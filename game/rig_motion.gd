extends RefCounted
## Samples authored CC0 motion onto each character's rest skeleton.
## Positions preserve target limb lengths; only pelvis translation is animated.
const REQUIRED := ["Idle","Sprint","Jump","Slide","Sword_Regular_A","Punch_Cross","Spell_Simple_Shoot","Shield_Dash"]
static var clips: Dictionary = {}
static var source_rests: Dictionary = {}
var skeleton: Skeleton3D
var rotations: Array[Quaternion] = []
var positions: Array[Vector3] = []
var rests: Array[Transform3D] = []
var upper: Array[bool] = []
var locomotion: String = "Idle"
var motion_clock: float = 0.0
var attack_clock: float = 99.0
var attack_clip: String = "Sword_Regular_A"
var power_clock: float = 99.0

static func ensure_clips() -> void:
	if not clips.is_empty(): return
	var library: AnimationLibrary=load("res://assets/models/quaternius/animations/runner-motion.res")
	var encoded: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/quaternius/animations/source-rests.json"))
	for clip in REQUIRED:
		clips[clip]=library.get_animation(clip)
		var bones: Dictionary={}
		for name in encoded[clip]:
			var p: Array=encoded[clip][name].position
			var r: Array=encoded[clip][name].rotation
			bones[name]=Transform3D(Basis(Quaternion(r[0],r[1],r[2],r[3])),Vector3(p[0],p[1],p[2]))
		source_rests[clip]=bones

static func release_shared() -> void:
	clips.clear()
	source_rests.clear()

func configure(rig: Skeleton3D, kind: String) -> void:
	ensure_clips()
	skeleton = rig
	attack_clip = {"knight":"Sword_Regular_A","gargoyle":"Punch_Cross","witch":"Spell_Simple_Shoot"}[kind]
	for i in range(rig.get_bone_count()):
		var rest := rig.get_bone_rest(i)
		rests.append(rest)
		rotations.append(rest.basis.get_rotation_quaternion())
		positions.append(rest.origin)
		var name := str(rig.get_bone_name(i))
		upper.append(not (name == "root" or name == "pelvis" or "thigh" in name or "calf" in name or "foot" in name or "ball" in name or "ik_" in name))

func strike() -> void: attack_clock=0.0
func power() -> void: power_clock=0.0

func _pose(clip_name: String, time: float) -> Dictionary:
	var animation: Animation = clips[clip_name]
	var at := fposmod(time,animation.length) if clip_name in ["Idle","Sprint","Jump","Slide"] else minf(time,animation.length-0.001)
	var result: Dictionary = {}
	var source: Dictionary = source_rests[clip_name]
	for track in range(animation.get_track_count()):
		var path := animation.track_get_path(track)
		if path.get_subname_count()==0: continue
		var name := str(path.get_subname(0))
		var index := skeleton.find_bone(name)
		if index < 0: continue
		var original: Transform3D = source[name]
		if animation.track_get_type(track)==Animation.TYPE_ROTATION_3D:
			var rotation := animation.rotation_track_interpolate(track,at)
			result[index]=rests[index].basis.get_rotation_quaternion()*original.basis.get_rotation_quaternion().inverse()*rotation
		elif animation.track_get_type(track)==Animation.TYPE_POSITION_3D and name=="pelvis":
			result["pelvis"] = rests[index].origin+(animation.position_track_interpolate(track,at)-original.origin)*(rests[index].origin.length()/original.origin.length())
	return result

func advance(delta: float, moving: bool, airborne: bool, sliding: bool, kind: String) -> void:
	var next := "Slide" if sliding else "Jump" if airborne else "Sprint" if moving else "Idle"
	if next != locomotion:
		locomotion=next
		motion_clock=0.0
	motion_clock+=delta*(1.12 if next=="Sprint" else 1.0)
	attack_clock+=delta
	power_clock+=delta
	var pose := _pose(locomotion,motion_clock)
	var action: Dictionary = {}
	var amount := 0.0
	var action_name := attack_clip
	var action_time := attack_clock
	if kind=="knight" and power_clock<0.7:
		action_name="Shield_Dash"
		action_time=power_clock
	var animation: Animation = clips[action_name]
	if action_time < minf(animation.length,0.70):
		action=_pose(action_name,action_time*1.25)
		amount=minf(action_time/0.055,1.0)*minf((minf(animation.length,0.70)-action_time)/0.10,1.0)
	var smoothing := 1.0-exp(-delta*22.0)
	for index in range(skeleton.get_bone_count()):
		var target: Quaternion = pose.get(index,rests[index].basis.get_rotation_quaternion())
		if upper[index] and action.has(index): target=target.slerp(action[index],amount)
		rotations[index]=rotations[index].slerp(target,smoothing)
		skeleton.set_bone_pose_rotation(index,rotations[index])
		var position: Vector3 = pose.get("pelvis",rests[index].origin) if skeleton.get_bone_name(index)=="pelvis" else rests[index].origin
		positions[index]=positions[index].lerp(position,smoothing)
		skeleton.set_bone_pose_position(index,positions[index])
