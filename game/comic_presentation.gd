extends RefCounted

const NAMES := ["knight", "gargoyle", "witch"]
const COLORS := {"knight":Color("5de9f2"),"gargoyle":Color("60e3bd"),"witch":Color("ba83ff")}
var portraits: Dictionary = {}
var background: GradientTexture2D
var foreground: GradientTexture2D


func _init() -> void:
	for hero in NAMES:
		portraits[hero] = load("res://assets/illustrations/"+hero+"-comic-v1.png")
	background = _gradient(PackedColorArray([Color("100d27"),Color("211639"),Color("10152a")]))
	foreground = _gradient(PackedColorArray([Color(0.025,0.035,0.09,0.0),Color(0.025,0.035,0.09,0.12),Color(0.025,0.035,0.09,1.0)]))


func _gradient(colors: PackedColorArray) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,0.5,1])
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(0,1)
	return texture


func draw(canvas: Control, selected: String, clock: float, display_font: Font) -> void:
	var w := canvas.size.x
	var h := canvas.size.y
	var accent: Color = COLORS[selected]
	canvas.draw_texture_rect(background,Rect2(Vector2.ZERO,canvas.size),false)
	var center := Vector2(w*0.60,h*0.43)
	canvas.draw_circle(center,w*0.54,Color(accent,0.035))
	canvas.draw_arc(center,w*0.47,-0.8+clock*0.035,2.5+clock*0.035,96,Color(accent,0.16),2,true)
	canvas.draw_arc(center,w*0.51,1.2-clock*0.02,4.6-clock*0.02,96,Color("885ab5",0.22),1,true)
	for index in range(18):
		var y := fposmod(float(index)*111.7+clock*12.0,h)
		var x := fposmod(float(index)*163.3,w)
		canvas.draw_line(Vector2(x,y),Vector2(x+15,y-28),Color(accent,0.07),1.0,true)
	var slash := PackedVector2Array([Vector2(w*0.79,0),Vector2(w,0),Vector2(w*0.52,h),Vector2(w*0.34,h)])
	canvas.draw_colored_polygon(slash,Color("3b2853",0.22))
	var portrait: Texture2D = portraits[selected]
	var image_height := minf(minf(h-430.0,1120.0),w*1.47)
	var image_width := image_height*2.0/3.0
	var drift := Vector2(sin(clock*0.6)*4.0,cos(clock*0.8)*3.0)
	var at := Vector2(w*0.50-image_width*0.5,123.0)+drift
	canvas.draw_texture_rect(portrait,Rect2(at,Vector2(image_width,image_height)),false)
	canvas.draw_texture_rect(foreground,Rect2(Vector2(0,h-720),Vector2(w,720)),false)
	var name_y := h-570.0
	canvas.draw_line(Vector2(36,name_y-18),Vector2(100,name_y-18),accent,4,true)
	canvas.draw_line(Vector2(106,name_y-18),Vector2(150,name_y-18),Color(accent,0.35),1,true)
	var cell := (w-96.0)/3.0
	for index in range(3):
		var kind: String = NAMES[index]
		var active := kind == selected
		var rect := Rect2(Vector2(36+index*(cell+12),h-340),Vector2(cell,150))
		var polygon := PackedVector2Array([rect.position+Vector2(0,12),rect.position+Vector2(12,0),rect.position+Vector2(rect.size.x,0),rect.end-Vector2(0,12),rect.end-Vector2(12,0),rect.position+Vector2(0,rect.size.y)])
		canvas.draw_colored_polygon(polygon,Color("162a3c") if active else Color("11172c"))
		var outline := polygon.duplicate()
		outline.append(polygon[0])
		canvas.draw_polyline(outline,accent if active else Color("454360"),2 if active else 1,true)
		var image_rect := Rect2(rect.position+Vector2(5,5),Vector2(cell-10,100))
		canvas.draw_texture_rect_region(portraits[kind],image_rect,Rect2(0,15,1024,520))
		canvas.draw_rect(Rect2(rect.position+Vector2(2,104),Vector2(cell-4,43)),Color("0a1023",0.92))
		var text := kind.to_upper()
		var text_size := display_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,29)
		canvas.draw_string(display_font,rect.position+Vector2((cell-text_size.x)*0.5,136),text,HORIZONTAL_ALIGNMENT_LEFT,-1,29,Color("ffffff") if active else Color("c6c9df"))
		if active:
			canvas.draw_line(rect.position+Vector2(14,148),rect.position+Vector2(cell-14,148),accent,4,true)
	canvas.draw_line(Vector2(36,h-174),Vector2(w-36,h-174),Color(accent,0.24),1,true)
