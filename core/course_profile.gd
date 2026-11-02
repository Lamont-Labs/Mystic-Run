extends RefCounted
## Shared world-space elevation contract. Shader uses the identical knots.
const KNOTS := [Vector2(0,0),Vector2(36,0),Vector2(116,11),Vector2(150,11),Vector2(238,-6),Vector2(282,-6),Vector2(354,7),Vector2(405,7),Vector2(500,-3),Vector2(558,-3),Vector2(620,0),Vector2(640,0)]
const LOOP := 640.0

static func height_at(metres: float) -> float:
	var d: float=fposmod(maxf(0.0,metres),LOOP)
	for i in range(KNOTS.size()-1):
		var a: Vector2=KNOTS[i];var b: Vector2=KNOTS[i+1]
		if d<=b.x:return lerpf(a.y,b.y,smoothstep(a.x,b.x,d))
	return 0.0

static func grade_at(metres: float) -> float:
	return (height_at(metres+0.1)-height_at(metres-0.1))/0.2

static func bend_at(metres: float) -> float:
	return sin(metres/92.0)*6.0+sin(metres/211.0)*3.0

static func lateral_at(metres: float, origin: float) -> float:
	var tangent: float=(bend_at(origin+0.1)-bend_at(origin-0.1))/0.2
	return bend_at(metres)-bend_at(origin)-tangent*(metres-origin)

static func section_at(metres: float) -> String:
	var d: float=fposmod(metres,LOOP)
	if d<36:return "THE APPROACH"
	if d<116:return "ASCENT OF THE FALLEN"
	if d<150:return "THE CROWN BRIDGE"
	if d<238:return "THE LONG DESCENT"
	if d<282:return "THE UNDERCITY"
	if d<354:return "SPIRE CLIMB"
	if d<405:return "HIGH GARDENS"
	if d<500:return "THE PLUNGE"
	if d<558:return "RIFT PASSAGE"
	return "CATHEDRAL RETURN"
