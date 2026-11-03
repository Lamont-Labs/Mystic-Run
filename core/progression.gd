extends RefCounted
const Secrets=preload("res://core/secret_catalog.gd")
const BADGES := [
	{"id":"first_run","title":"OFF WE GO!","detail":"Finish your first adventure."},
	{"id":"first_clear","title":"EXIT, STAGE AWESOME","detail":"Complete a finite expedition."},
	{"id":"relic_25","title":"SHINY THINGS","detail":"Collect 25 relics."},
	{"id":"relic_250","title":"POCKET FULL OF STARS","detail":"Collect 250 relics."},
	{"id":"sentinel_10","title":"SENTINEL SHUFFLER","detail":"Defeat 10 sentinels."},
	{"id":"distance_1000","title":"A VERY LONG WAY!","detail":"Travel 1,000 metres in one run."},
	{"id":"clean_500","title":"FANCY FOOTWORK","detail":"Complete 500 unprotected metres without damage."},
	{"id":"three_runners","title":"THREE'S COMPANY","detail":"Finish a run with every character."},
	{"id":"three_levels","title":"CITY TOUR","detail":"Clear Citadel, Spires and Rift."},
	{"id":"first_secret","title":"WHAT'S IN HERE?","detail":"Collect your first secret treasure."},
	{"id":"all_secrets","title":"THE WHOLE TREASURY","detail":"Find all nine character treasures."},
	{"id":"ability_knight","title":"SUNBREAK!","detail":"Unlock the Knight's traversal ability."},
	{"id":"ability_gargoyle","title":"SKYGLIDE!","detail":"Unlock the Gargoyle's traversal ability."},
	{"id":"ability_witch","title":"RIFTWALK!","detail":"Unlock the Witch's traversal ability."}]

static func number(value:Variant,limit:int=10000000) -> int:
	if not (value is int or value is float) or not is_finite(float(value)):return 0
	return clampi(int(value),0,limit)

static func fresh() -> Dictionary:
	return {"schema":1,"mastery":{"knight":0,"gargoyle":0,"witch":0},"artifacts":{},"badges":{},"runs":0,"relics":0,"sentinels":0,"best":0,"clean_best":0,"by_hero":{"knight":0,"gargoyle":0,"witch":0},"clears":{"citadel":0,"spires":0,"rift":0},"recent_runs":[]}

static func normalise(value:Variant,legacy:Dictionary={}) -> Dictionary:
	var p:Dictionary=fresh()
	if not value is Dictionary or value.get("schema",0)!=1:
		p.runs=number(legacy.get("runs",0));p.relics=number(legacy.get("relics",0));p.best=number(legacy.get("best",0))
		return p
	for key in ["runs","relics","sentinels","best","clean_best"]:p[key]=number(value.get(key,0))
	for key in ["mastery","by_hero","clears"]:
		var source:Variant=value.get(key,{})
		if source is Dictionary:
			for id in p[key]:p[key][id]=number(source.get(id,0),1000000)
	var artifacts:Variant=value.get("artifacts",{})
	if artifacts is Dictionary:
		for id in artifacts:
			if id is String and Secrets.valid_artifact(id) and artifacts[id]==true:p.artifacts[id]=true
	var badges:Variant=value.get("badges",{})
	if badges is Dictionary:
		for badge in BADGES:
			if badges.get(badge.id,false)==true:p.badges[badge.id]=true
	var recent:Variant=value.get("recent_runs",[])
	if recent is Array:
		for id in recent.slice(0,64):
			if id is String and id.length()<=100 and not p.recent_runs.has(id):p.recent_runs.append(id)
	return p

static func ability_unlocked(p:Dictionary,hero:String) -> bool:
	return Secrets.HEROES.has(hero) and number(p.get("mastery",{}).get(hero,0))>=Secrets.ABILITY_XP

static func claim_artifact(p:Dictionary,id:String) -> bool:
	if not Secrets.valid_artifact(id) or p.artifacts.has(id):return false
	p.artifacts[id]=true
	return true

static func evaluate(p:Dictionary) -> Array[String]:
	var earned:Array[String]=[]
	var conditions:Dictionary={"first_run":p.runs>=1,"first_clear":p.clears.values().any(func(n):return n>0),"relic_25":p.relics>=25,"relic_250":p.relics>=250,"sentinel_10":p.sentinels>=10,"distance_1000":p.best>=1000,"clean_500":p.clean_best>=500,"three_runners":p.by_hero.values().all(func(n):return n>0),"three_levels":p.clears.values().all(func(n):return n>0),"first_secret":p.artifacts.size()>0,"all_secrets":p.artifacts.size()==9,"ability_knight":ability_unlocked(p,"knight"),"ability_gargoyle":ability_unlocked(p,"gargoyle"),"ability_witch":ability_unlocked(p,"witch")}
	for badge in BADGES:
		if conditions[badge.id] and not p.badges.has(badge.id):p.badges[badge.id]=true;earned.append(badge.id)
	return earned

static func finish_run(p:Dictionary,run:Dictionary) -> Dictionary:
	var result:Dictionary={"xp":0,"new_badges":[],"ability_unlocked":false,"applied":false}
	var id:String=str(run.get("id",""));var hero:String=str(run.get("hero",""))
	if id.is_empty() or id.length()>100 or p.recent_runs.has(id) or not Secrets.HEROES.has(hero) or run.get("practice",false):return result
	p.recent_runs.push_front(id);p.recent_runs=p.recent_runs.slice(0,64)
	var distance:int=number(run.get("distance",0));var relics:int=number(run.get("relics",0));var enemies:int=number(run.get("defeated",0))
	var unprotected:int=number(run.get("unprotected_distance",distance));var was_unlocked:bool=ability_unlocked(p,hero)
	var xp:int=unprotected/18+relics+enemies*5+number(run.get("treasures",0),9)*15+(20 if run.get("clear",false) else 0)
	p.mastery[hero]=mini(1000000,p.mastery[hero]+xp);p.runs=mini(10000000,p.runs+1)
	p.relics=mini(10000000,p.relics+relics);p.sentinels=mini(10000000,p.sentinels+enemies);p.best=maxi(p.best,distance);p.by_hero[hero]=mini(1000000,p.by_hero[hero]+1)
	if number(run.get("damage",0))==0:p.clean_best=maxi(p.clean_best,unprotected)
	var level:String=str(run.get("course",""))
	if run.get("clear",false) and Secrets.LEVELS.has(level):p.clears[level]=mini(1000000,p.clears[level]+1)
	result.xp=xp;result.new_badges=evaluate(p);result.ability_unlocked=not was_unlocked and ability_unlocked(p,hero);result.applied=true
	return result

static func badge_title(id:String) -> String:
	for badge in BADGES:
		if badge.id==id:return badge.title
	return ""

static func next_goal(p:Dictionary,hero:String) -> String:
	if not ability_unlocked(p,hero):return "EARN %d MORE XP TO UNLOCK %s"%[maxi(0,60-number(p.mastery[hero])),Secrets.ABILITIES[hero]]
	for level in Secrets.LEVELS:
		if not p.artifacts.has(level+"/"+hero):return "EXPLORE YOUR SECRET ROUTE IN "+level.to_upper()
	return "FIND ALL NINE TREASURES · %d / 9"%p.artifacts.size()
