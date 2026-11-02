extends RefCounted

const ORDER := ["endless","citadel","spires","rift"]
const COURSES := {
	"citadel":{"title":"CITADEL BREAKOUT","subtitle":"Escape the waking cathedral","district":"CATHEDRAL CAUSEWAY","theme":"knight","length":650.0,"speed":18.0,"maximum":22.0,"difficulty":"APPRENTICE","recommended":"knight","description":"Climb the cathedral approach, race over its crown bridge and plunge into the undercity."},
	"spires":{"title":"SKYWARD ESCAPE","subtitle":"Carry the run above the clouds","district":"THE UPPER SPIRES","theme":"gargoyle","length":900.0,"speed":19.0,"maximum":24.0,"difficulty":"ADEPT","recommended":"gargoyle","description":"Elevated bridges, steep descents and hanging defenses demand clean steering, jumps and slides."},
	"rift":{"title":"FRACTURE PROTOCOL","subtitle":"Cut a path through the arcane district","district":"THE FRACTURED VEIL","theme":"witch","length":1100.0,"speed":20.0,"maximum":24.0,"difficulty":"VETERAN","recommended":"witch","description":"A denser mix of combat and movement. Read the next opening and use your powers deliberately."},
	"endless":{"title":"ENDLESS RUN","subtitle":"One runner. No finish line.","district":"THE MYSTIC CITY","theme":"knight","length":0.0,"speed":18.5,"maximum":24.0,"difficulty":"ENDLESS","recommended":"knight","description":"An accelerating course through climbs, bridges and descents. Your chosen runner stays with you."},
	"training":{"title":"THE TRAINING GROUND","subtitle":"Learn through movement","district":"GUIDED PRACTICE","theme":"knight","length":0.0,"speed":6.0,"maximum":6.0,"difficulty":"PRACTICE","recommended":"knight","description":"Practice steering, jumping, sliding, striking and your character's power without losing health."}
}

static func get_course(id: String) -> Dictionary:
	return COURSES.get(id,COURSES.endless).duplicate(true)

static func speed_at(id: String, distance: float, seconds: float) -> float:
	var course:=get_course(id)
	var cruising:=lerpf(float(course.speed),float(course.maximum),smoothstep(0,900.0,distance))
	return cruising if id!="training" else 6.0
