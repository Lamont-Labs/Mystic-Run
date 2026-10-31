extends RefCounted
## Authored, seeded encounter phrases. Every wave leaves a navigable option.
const PHRASE_LENGTH := 96.0
var course: String="citadel"
var random:=RandomNumberGenerator.new()

func configure(id: String, seed_value: int) -> void:
	course=id
	random.seed=seed_value

func phrase(index: int, start: float) -> Array[Dictionary]:
	var rows: Array[Dictionary]=[]
	var pools: Array=["weave","vault","combat","duck"]
	if course in ["spires","rift","endless"] and index>0: pools.append("fractures")
	if course=="rift": pools.append("combat")
	var pattern: String=pools[index%pools.size()] if index<4 else pools[random.randi_range(0,pools.size()-1)]
	var shift:=0 if index==0 else random.randi_range(0,2)
	match pattern:
		"weave":
			_add(rows,"barrier",0,0,start,shift)
			_trail(rows,1,4,start,shift)
			_add(rows,"barrier",2,29,start,shift)
			_trail(rows,1,36,start,shift)
			_add(rows,"enemy",1,66,start,shift)
		"vault":
			_add(rows,"barrier",1,0,start,shift)
			_trail(rows,1,9,start,shift)
			_add(rows,"beam",2,36,start,shift)
			_trail(rows,0,44,start,shift)
			_add(rows,"enemy",0,70,start,shift)
		"duck":
			_add(rows,"beam",1,0,start,shift)
			_trail(rows,1,8,start,shift)
			_add(rows,"barrier",0,33,start,shift)
			_add(rows,"beam",2,60,start,shift)
			_trail(rows,1,67,start,shift)
		"combat":
			_add(rows,"enemy",1,0,start,shift)
			_trail(rows,1,8,start,shift)
			_add(rows,"enemy",2,36,start,shift)
			_trail(rows,2,44,start,shift)
			_add(rows,"barrier",0,70,start,shift)
		"fractures":
			_add(rows,"gap",0,0,start,shift)
			_add(rows,"gap",2,0,start,shift)
			_trail(rows,1,5,start,shift)
			_add(rows,"gap",1,35,start,shift)
			_trail(rows,2,43,start,shift)
			_add(rows,"beam",2,70,start,shift)
	return rows

func _add(rows: Array[Dictionary], kind: String, lane: int, offset: float, start: float, shift: int) -> void:
	rows.append({"kind":kind,"lane":(lane+shift)%3,"at":start+offset})

func _trail(rows: Array[Dictionary], lane: int, offset: float, start: float, shift: int) -> void:
	for i in range(4): _add(rows,"shard",lane,offset+i*2.7,start,shift)
