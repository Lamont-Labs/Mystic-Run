extends RefCounted
## Pure distance-based presentation state. Never consumes encounter RNG.
const SPAN:=384.0
const BLEND:=72.0
const IDS:=["castle","wilds","ember"]
const TITLES:=["CASTLE HEIGHTS","ENCHANTED WILDS","EMBER RUINS"]
const KEYS:=["knight","gargoyle","witch"]

static func sample(distance:float) -> Dictionary:
	var station:float=maxf(0,distance)
	var chapter:int=floori(station/SPAN)
	var index:int=posmod(chapter,3)
	var following:int=(index+1)%3
	var blend:float=smoothstep(SPAN-BLEND,SPAN,fposmod(station,SPAN))
	return {"index":index,"next":following,"blend":blend,"chapter":chapter,
		"id":IDS[index],"title":TITLES[index],"key":KEYS[index],"next_key":KEYS[following]}
