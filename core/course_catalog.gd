extends RefCounted

const ORDER := ["citadel","spires","rift","endless"]
const COURSES := {
	"citadel":{"title":"CITADEL BREAKOUT","subtitle":"Escape the waking cathedral","district":"CATHEDRAL CAUSEWAY","theme":"knight","length":650.0,"speed":11.5,"maximum":14.0,"difficulty":"APPRENTICE","recommended":"knight","description":"A measured opening: learn the lanes, vault broken defenses and break through the sentinels."},
	"spires":{"title":"THE SKYWARD RELAY","subtitle":"Carry the run above the clouds","district":"THE UPPER SPIRES","theme":"gargoyle","length":900.0,"speed":12.5,"maximum":16.0,"difficulty":"ADEPT","recommended":"gargoyle","description":"Open fractures and hanging defenses demand clean jumps, slides and well-timed handoffs."},
	"rift":{"title":"FRACTURE PROTOCOL","subtitle":"Cut a path through the arcane district","district":"THE FRACTURED VEIL","theme":"witch","length":1100.0,"speed":13.0,"maximum":17.0,"difficulty":"VETERAN","recommended":"witch","description":"A denser mix of combat and movement. Read the next opening and use your powers deliberately."},
	"endless":{"title":"ENDLESS RELAY","subtitle":"One team. An unbroken run.","district":"THE MYSTIC CITY","theme":"knight","length":0.0,"speed":12.0,"maximum":19.0,"difficulty":"ENDLESS","recommended":"knight","description":"An accelerating course with all three districts, route handoffs and a personal distance record."},
	"training":{"title":"THE TRAINING GROUND","subtitle":"Learn through movement","district":"GUIDED PRACTICE","theme":"knight","length":0.0,"speed":6.0,"maximum":6.0,"difficulty":"PRACTICE","recommended":"knight","description":"Practice steering, jumping, sliding, striking and your character's power without losing health."}
}

static func get_course(id: String) -> Dictionary:
	return COURSES.get(id,COURSES.citadel).duplicate(true)

static func speed_at(id: String, distance: float, seconds: float) -> float:
	var course:=get_course(id)
	var cruising:=lerpf(float(course.speed),float(course.maximum),clampf(distance/1600.0,0,1))
	return lerpf(7.0,cruising,smoothstep(0,4.0,seconds)) if id!="training" else 6.0
