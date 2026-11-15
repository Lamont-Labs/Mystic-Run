extends Node
## A bounded native-Godot camera experiment, not a new camera dependency.
var game:Node
var origin:Vector3
var aim:Vector3
var initialized:bool=false

func _ready() -> void:process_physics_priority=100

func _physics_process(delta:float) -> void:
	if not is_instance_valid(game) or game.ui.mode!="game":return
	var height:float=game.ground_y
	var x:float=game.motor.position.x
	var target_origin:=Vector3(x*.28,height+3.85,7.15)
	var ahead_height:float=game.CourseProfile.height_at(game.distance+22)
	var target_aim:=Vector3(x*.16,lerpf(height,ahead_height,.45)+1.35,-19.0)
	if not initialized:
		origin=target_origin;aim=target_aim;initialized=true
	origin=origin.lerp(target_origin,1-exp(-delta*10))
	aim=aim.lerp(target_aim,1-exp(-delta*8))
	game.camera.position=origin
	game.camera.look_at(aim)
	game.camera.fov=67.0
	game.camera.h_offset=0;game.camera.v_offset=0
