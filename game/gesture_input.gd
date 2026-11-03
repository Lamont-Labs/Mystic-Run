extends RefCounted
## One gesture per pointer. Touch and mouse follow the same recognition path.
var touches: Dictionary={}
var sensitivity: String="normal"

func reset() -> void: touches.clear()

func feed(event: InputEvent, viewport_width: float, now: float) -> String:
	var id: int=-2
	var at:=Vector2.ZERO
	var begin:=false
	var end:=false
	var drag:=false
	if event is InputEventScreenTouch:
		id=event.index;at=event.position;begin=event.pressed;end=not event.pressed
		if event.canceled:
			touches.erase(id)
			return ""
	elif event is InputEventScreenDrag:
		id=event.index;at=event.position;drag=true
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		id=-1;at=event.position;begin=event.pressed;end=not event.pressed
	elif event is InputEventMouseMotion and touches.has(-1):
		id=-1;at=event.position;drag=true
	else: return ""
	if begin:
		if touches.is_empty(): touches[id]={"start":at,"used":false,"time":now}
		return ""
	if not touches.has(id): return ""
	var touch: Dictionary=touches[id]
	var movement: Vector2=at-touch.start
	var factor: float={"low":.075,"normal":.055,"high":.040}.get(sensitivity,.055)
	var threshold:=clampf(viewport_width*factor,24,72)
	var action: String=""
	if not touch.used and movement.length()>=threshold:
		if absf(movement.x)>absf(movement.y)*1.1: action="right" if movement.x>0 else "left"
		elif absf(movement.y)>absf(movement.x)*1.1: action="jump" if movement.y<0 else "slide"
		if not action.is_empty(): touch.used=true
	if end:
		# Ordinary taps do not attack; horizontal swipes own basic combat.
		touches.erase(id)
	return action
