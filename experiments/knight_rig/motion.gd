extends RefCounted
## Native joint transforms, not whole-image pose crossfades. Angles in radians.
const RUN_HZ:float=2.15
const STANCE:float=.62

static func foot(phase:float,right:bool) -> Vector2:
	var t:float=fposmod(phase/TAU+(.5 if right else 0.0),1.0)
	var origin:=Vector2(195,327) if right else Vector2(77,326)
	if t<STANCE:return origin # exact planted ankle through the stance window
	var swing:float=(t-STANCE)/(1.0-STANCE)
	return origin+Vector2(sin(swing*TAU)*3.0,-sin(swing*PI)*27.0)

static func projected_knee(rest:Vector2,ankle_rest:Vector2,goal:Vector2,crouch:float,right:bool) -> Vector2:
	# Rear-view flexion occurs mostly in depth, not sideways in the image.
	# Foreshorten the painted segments while preserving their transverse width.
	var lift:float=maxf(0.0,ankle_rest.y-goal.y)
	return rest+Vector2((1.0 if right else -1.0)*crouch*.22,-lift*.36+crouch*.55)

static func segment(start:Vector2,finish:Vector2,rest_vector:Vector2) -> Transform2D:
	var direction:Vector2=finish-start
	var axis:Vector2=direction.normalized()
	var basis:=Transform2D(axis*direction.length()/rest_vector.length(),axis.orthogonal(),Vector2.ZERO)
	var result:Transform2D=basis*Transform2D(-rest_vector.angle(),Vector2.ZERO)
	result.origin=start
	return result

static func angles(phase:float,state:String,energy:float=1.0) -> Dictionary:
	var stride:float=sin(phase)*energy
	var poses:Dictionary={
		"torso":stride*.018,"head":-stride*.014,
		"cape":sin(phase-.8)*.025*energy,
		"shield":stride*.065,"upperarm_r":-stride*.11,
		"forearm_r":.035+maxf(0.0,stride)*.10,"sword":-stride*.035
	}
	match state:
		"jump":poses.merge({"torso":-.06,"cape":.06,"shield":-.12,"upperarm_r":.20,"forearm_r":-.18},true)
		"fall":poses.merge({"cape":-.06,"shield":.10,"upperarm_r":-.12,"forearm_r":.10},true)
		"slide":poses.merge({"torso":.18,"head":-.12,"cape":-.10,"shield":-.25,"upperarm_r":.34,"forearm_r":-.48},true)
		"attack":poses.merge({"torso":-.04,"upperarm_r":-.62,"forearm_r":-.36,"sword":-.20,"shield":.08},true)
		"damage":poses.merge({"torso":-.12,"head":.08,"shield":-.15,"upperarm_r":.20},true)
		"power":poses.merge({"upperarm_r":-.75,"forearm_r":-.25,"shield":.18,"cape":-.06},true)
		"victory":poses.merge({"upperarm_r":-1.1,"forearm_r":-.35,"shield":.16},true)
		"defeat":poses.merge({"torso":.25,"head":.22,"upperarm_r":.16,"forearm_r":.20},true)
	return poses
