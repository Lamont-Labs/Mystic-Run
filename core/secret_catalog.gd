extends RefCounted
const HEROES := ["knight","gargoyle","witch"]
const LEVELS := ["citadel","spires","rift"]
const ABILITY_XP := 60
const SPECIALS := {"knight":"SUNBURST","gargoyle":"STONE POP","witch":"STARFALL"}
const ABILITIES := {"knight":"SUNBREAK","gargoyle":"SKYGLIDE","witch":"RIFTWALK"}
const ABILITY_DETAILS := {"knight":"Break a sun seal to discover a clockwork vault.","gargoyle":"Ride an updraft into a floating sky sanctuary.","witch":"Slip through a moon rift into an enchanted star garden."}
const ROOMS := {
	"citadel":{"knight":["THE TICKTOCK VAULT","DAWN GEAR"],"gargoyle":["BELFRY IN THE CLOUDS","BELLFEATHER"],"witch":["THE MOONLIT ARCHIVE","STARBOUND PAGE"]},
	"spires":{"knight":["THE SUN ENGINE","SOLAR KEY"],"gargoyle":["THE SKY NEST","CLOUD PRISM"],"witch":["THE COMET GARDEN","COMET BLOOM"]},
	"rift":{"knight":["THE LOST FOUNDRY","PHOENIX COG"],"gargoyle":["THE FLOATING ROOST","THUNDER EGG"],"witch":["THE STARWELL","MOON PEARL"]}}

static func valid_artifact(id:String) -> bool:
	var parts:PackedStringArray=id.split("/")
	return parts.size()==2 and LEVELS.has(parts[0]) and HEROES.has(parts[1])

static func room(level:String,hero:String) -> Dictionary:
	if not LEVELS.has(level) or not HEROES.has(hero):return {}
	var values:Array=ROOMS[level][hero]
	return {"id":level+"/"+hero,"level":level,"hero":hero,"title":values[0],"artifact":values[1],"ability":ABILITIES[hero],"lane":{"knight":0,"gargoyle":2,"witch":1}[hero]}

static func gate(course:String,hero:String,zone:int=0) -> Dictionary:
	var level:String=LEVELS[posmod(zone,3)] if course=="endless" else course
	var entry:Dictionary=room(level,hero)
	if entry.is_empty():return {}
	entry["at"]=zone*640.0+180.0 if course=="endless" else {"citadel":190.0,"spires":270.0,"rift":360.0}[level]
	entry["gate_id"]=course+":"+str(zone)+":"+hero
	return entry

static func all_rooms() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for level in LEVELS:
		for hero in HEROES:result.append(room(level,hero))
	return result
