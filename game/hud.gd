extends Control
signal intent(action: String,value: String)
const FrontEnd=preload("res://game/front_end.gd")
const Comic=preload("res://game/comic_presentation.gd")
const WHITE:=Color("f0f0ff")
const MUTED:=Color("bcc5de")
const ACCENTS:={"knight":Color("65e8ef"),"gargoyle":Color("76e1be"),"witch":Color("be91ff")}

class ActionButton:
	extends Button
	var kind: String="attack"
	var hero: String="knight"
	var remaining: float=0
	var font: Font
	func _draw() -> void:
		var center:=size*Vector2(.5,.40)
		var color:=Color("9debf2") if not disabled else Color("8794b0")
		if remaining>0:
			var value:="%.1f"%remaining
			draw_string(font,center+Vector2(-font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,28).x*.5,9),value,HORIZONTAL_ALIGNMENT_LEFT,-1,28,color)
		elif kind=="attack":
			draw_line(center+Vector2(-16,16),center+Vector2(15,-19),color,4,true)
			draw_line(center+Vector2(-16,2),center+Vector2(-2,15),color,4,true)
		elif hero=="knight":
			draw_polyline(PackedVector2Array([center+Vector2(-16,-18),center+Vector2(16,-18),center+Vector2(14,7),center+Vector2(0,22),center+Vector2(-14,7),center+Vector2(-16,-18)]),color,3,true)
		elif hero=="gargoyle":
			draw_polyline(PackedVector2Array([center+Vector2(-27,-11),center+Vector2(-12,-3),center+Vector2(0,17),center+Vector2(12,-3),center+Vector2(27,-11)]),color,4,true)
			draw_line(center+Vector2(-27,-11),center+Vector2(-14,15),color,2,true);draw_line(center+Vector2(27,-11),center+Vector2(14,15),color,2,true)
		else:
			draw_arc(center,19,0,TAU,32,color,3,true);draw_line(center+Vector2(0,-26),center+Vector2(0,26),color,2,true);draw_circle(center,5,color)
		var caption:="STRIKE" if kind=="attack" else "POWER"
		var width:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
		draw_string(font,Vector2((size.x-width)*.5,size.y-17),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,20,WHITE)

var mode: String="opening"
var selected: String="knight"
var course_id: String="citadel"
var profile_data: Dictionary={}
var result_data: Dictionary={}
var navigation: Array[String]=["opening"]
var front: Control
var game_buttons: Dictionary={}
var buttons: Dictionary:
	get:return front.buttons if is_instance_valid(front) and front.visible else game_buttons
var labels: Dictionary={}
var title_font: Font
var ui_font: Font
var portraits: Dictionary={}
var session: Dictionary={}
var settings: Dictionary={}
var route_visible: bool=false
var route_lane: int=1
var route_distance: float=0
var shard_count: int=0
var flash: float=0
var countdown_text: String="3"
var control_hint:String="HOLD YOUR PHONE COMFORTABLY"
var guide_title: String=""
var guide_detail: String=""
var combat_ready: bool=false
var message_left: float=0
var impact_left: float=0
var impact_text: String=""
var impact_color:=Color("65e8ef")
var fade: GradientTexture2D
var top_pad: float=22
var bottom_pad: float=16

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var display_font:=FontVariation.new();display_font.base_font=load("res://assets/fonts/cinzel.ttf")
	display_font.variation_opentype={TextServerManager.get_primary_interface().name_to_tag("wght"):700.0};title_font=display_font
	var font:=FontVariation.new();font.base_font=load("res://assets/fonts/manrope.ttf")
	font.variation_opentype={TextServerManager.get_primary_interface().name_to_tag("wght"):650.0};ui_font=font
	for kind in ["knight","gargoyle","witch"]:portraits[kind]=load("res://assets/illustrations/"+kind+"-comic-v1.png")
	var gradient:=Gradient.new();gradient.offsets=PackedFloat32Array([0,.28,.7,1]);gradient.colors=PackedColorArray([Color(.025,.03,.07,.8),Color(.025,.03,.07,0),Color(.025,.03,.07,0),Color(.025,.03,.07,.62)])
	fade=GradientTexture2D.new();fade.gradient=gradient;fade.fill_from=Vector2.ZERO;fade.fill_to=Vector2(0,1)
	for definition in [["distance",54,true],["unit",15,false],["district",18,false],["score",19,false],["objective",17,false],["speed",24,false],["steering",16,false],["ability",18,false],["message",29,true],["guide_title",35,true],["guide_detail",25,false],["combat_hint",31,true],["countdown",120,true],["ready_caption",30,true]]:
		var label:=Label.new();label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_override("font",title_font if definition[2] else ui_font);label.add_theme_font_size_override("font_size",definition[1]);label.add_theme_color_override("font_color",WHITE)
		label.add_theme_color_override("font_outline_color",Color("091025"));label.add_theme_constant_override("outline_size",4)
		add_child(label);labels[definition[0]]=label
	labels.unit.text="METRES";labels.ready_caption.text="HOLD YOUR PHONE COMFORTABLY";labels.combat_hint.text="TAP TO STRIKE"
	labels.guide_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var pause:=Button.new();pause.text="II";pause.add_theme_font_override("font",ui_font);pause.add_theme_font_size_override("font_size",28)
	pause.add_theme_stylebox_override("normal",_button_style(false));pause.add_theme_stylebox_override("pressed",_button_style(true));pause.pressed.connect(func():intent.emit("pause",""));add_child(pause);game_buttons.pause=pause
	for action in ["attack","power"]:
		var b:=ActionButton.new();b.kind=action;b.font=ui_font
		b.add_theme_stylebox_override("normal",_button_style(false,true));b.add_theme_stylebox_override("pressed",_button_style(true,true));b.add_theme_stylebox_override("hover",_button_style(true,true));b.add_theme_stylebox_override("disabled",_button_style(false,true))
		b.pressed.connect(func():intent.emit(action,""));add_child(b);game_buttons[action]=b
	front=FrontEnd.new();front.title_font=title_font;front.body_font=ui_font;front.portraits=portraits
	add_child(front);front.intent.connect(func(action: String,value: String):intent.emit(action,value))
	_layout();refresh()

func _button_style(active: bool, circle: bool=false) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("253b51",.96) if active else Color("0c1429",.88)
	style.border_color=Color("86e7ee") if active else Color("63758f");style.set_border_width_all(2);style.set_corner_radius_all(70 if circle else 10)
	return style

func _notification(what: int) -> void:
	if what==NOTIFICATION_RESIZED and not labels.is_empty():_layout()

func _place(key: String, at: Vector2, dimensions: Vector2, align: HorizontalAlignment=HORIZONTAL_ALIGNMENT_LEFT) -> void:
	labels[key].position=at;labels[key].size=dimensions;labels[key].horizontal_alignment=align

func _layout() -> void:
	var w:=size.x;var h:=size.y
	top_pad=22;bottom_pad=16
	if OS.get_name()=="Android":
		var safe:=DisplayServer.get_display_safe_area();var window:=DisplayServer.window_get_size()
		if window.y>0 and safe.size.y>0:
			top_pad=maxf(22,safe.position.y*size.y/window.y+10);bottom_pad=maxf(16,(window.y-safe.end.y)*size.y/window.y+10)
	_place("district",Vector2(26,top_pad+92),Vector2(w-52,30))
	_place("score",Vector2(26,top_pad+55),Vector2(210,30))
	_place("distance",Vector2(w*.5-105,top_pad-8),Vector2(210,64),HORIZONTAL_ALIGNMENT_CENTER)
	_place("unit",Vector2(w*.5-105,top_pad+58),Vector2(210,22),HORIZONTAL_ALIGNMENT_CENTER)
	_place("objective",Vector2(26,top_pad+128),Vector2(w-52,30))
	_place("speed",Vector2(30,h-bottom_pad-127),Vector2(220,35))
	_place("steering",Vector2(30,h-bottom_pad-43),Vector2(250,25))
	_place("ability",Vector2(w-300,h-bottom_pad-180),Vector2(270,30),HORIZONTAL_ALIGNMENT_RIGHT)
	_place("message",Vector2(30,h-bottom_pad-255),Vector2(w-60,70),HORIZONTAL_ALIGNMENT_CENTER)
	_place("guide_title",Vector2(30,top_pad+186),Vector2(w-60,58))
	_place("guide_detail",Vector2(30,top_pad+245),Vector2(w-60,98))
	_place("combat_hint",Vector2(w*.5-165,h*.44),Vector2(330,45),HORIZONTAL_ALIGNMENT_CENTER)
	_place("countdown",Vector2(0,h*.34),Vector2(w,168),HORIZONTAL_ALIGNMENT_CENTER)
	_place("ready_caption",Vector2(30,h*.34+170),Vector2(w-60,80),HORIZONTAL_ALIGNMENT_CENTER)
	labels.ready_caption.add_theme_font_size_override("font_size",21)
	labels.ready_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if game_buttons.is_empty():return
	game_buttons.pause.position=Vector2(w-92,top_pad);game_buttons.pause.size=Vector2(62,62)
	game_buttons.power.position=Vector2(w-148,h-bottom_pad-142);game_buttons.power.size=Vector2(118,118)
	game_buttons.attack.position=Vector2(w-266,h-bottom_pad-130);game_buttons.attack.size=Vector2(102,102)
	queue_redraw()

func set_mode(value: String) -> void:mode=value;refresh()
func open_screen(screen: String, root: bool=false) -> void:
	if root:navigation=[screen]
	elif navigation.is_empty() or navigation[-1]!=screen:navigation.append(screen)
	set_mode(screen)
func go_back() -> void:
	if navigation.size()>1:navigation.pop_back();set_mode(navigation[-1])
	else:open_screen("home",true)
func refresh() -> void:
	if not is_instance_valid(front):return
	for label in labels.values():label.hide()
	for b in game_buttons.values():b.hide()
	front.visible=mode not in ["game","countdown","closing"]
	if front.visible:front.show_screen(mode,selected,course_id,profile_data,result_data,navigation.size()>1 or mode in ["pause","results"])
	elif mode=="game":
		for key in ["distance","unit","district","score","ability","objective","speed","steering"]:labels[key].show()
		for b in game_buttons.values():b.show()
	elif mode=="countdown":
		labels.ready_caption.text=control_hint;labels.countdown.text=countdown_text;labels.countdown.show();labels.ready_caption.show();game_buttons.pause.show()
	queue_redraw()

func update_session(data: Dictionary, shards: int) -> void:
	session=data;shard_count=shards
	if mode!="game":return
	labels.distance.text=str(int(float(data.distance_mm)/1000.0))
	labels.speed.text="%d KM/H"%roundi(float(data.get("speed_mps",0))*3.6)
	labels.steering.text="TILT TO STEER" if data.get("steering","SWIPE")=="TILT" else "SWIPE TO STEER"
	labels.district.text=str(data.get("district","MYSTIC RUN"))
	labels.score.text="%d SCORE  /  %d RELICS"%[int(data.score),shards]
	var length:float=data.get("course_length",0)
	labels.objective.text="ENDLESS RUN" if length==0 else "%d / %d M TO THE EXIT"%[mini(int(data.distance_mm/1000),int(length)),int(length)]
	var character:String=data.character
	labels.ability.text={"knight":"SHIELD CHARGE","gargoyle":"WING BURST","witch":"ARCANE BLINK"}[character]
	var protected:bool=data.phase in ["handoff","recovery","failed","completed"]
	var remaining:float=float(data.cooldowns[character])/60.0
	game_buttons.power.remaining=remaining;game_buttons.power.hero=character
	game_buttons.power.disabled=remaining>0 or protected or data.phase=="committed" or not data.get("power_available",true)
	game_buttons.attack.disabled=protected
	game_buttons.power.queue_redraw();game_buttons.attack.queue_redraw()
	labels.guide_title.text=guide_title;labels.guide_detail.text=guide_detail
	labels.guide_title.visible=not guide_title.is_empty();labels.guide_detail.visible=not guide_detail.is_empty()
	labels.combat_hint.visible=combat_ready and guide_title.is_empty()
	queue_redraw()

func message(value: String, duration: float=1.8) -> void:labels.message.text=value;message_left=duration
func impact(value: String,color: Color) -> void:impact_text=value;impact_color=color;impact_left=.32;queue_redraw()
func _process(delta: float) -> void:
	if mode=="game":message_left=maxf(0,message_left-delta);impact_left=maxf(0,impact_left-delta);flash=maxf(0,flash-delta*2)
	labels.message.visible=mode=="game" and message_left>0
	if labels.message.visible:labels.message.modulate.a=minf(1,message_left*3)
	if impact_left>0 or flash>0:queue_redraw()

func _draw() -> void:
	if fade==null or mode not in ["game","countdown"]:return
	draw_texture_rect(fade,Rect2(Vector2.ZERO,size),false)
	if mode=="countdown":return
	var hero:String=session.get("character",selected);var accent:Color=ACCENTS[hero]
	for i in range(3):
		var rect:=Rect2(28+i*35,top_pad+16,26,7)
		draw_rect(rect,Color("f0d1a0") if i<int(session.get("health",3)) else Color("4a4c62"))
	var steer_center:=Vector2(94,size.y-bottom_pad-73)
	draw_line(steer_center-Vector2(60,0),steer_center+Vector2(60,0),Color("646f8c",.6),2,true)
	var steer:float=float(session.get("tilt_position",0))
	draw_circle(steer_center+Vector2(steer*57,0),5,accent)
	var length:float=session.get("course_length",0)
	if length>0:
		var width:=size.x-52
		draw_rect(Rect2(26,top_pad+168,width,4),Color("343a53"));draw_rect(Rect2(26,top_pad+168,width*clampf(float(session.get("distance_mm",0))/1000.0/length,0,1),4),accent)
	if impact_left>0:
		var center:=Vector2(size.x*.54,size.y*.47);var burst:=PackedVector2Array()
		for i in range(16):
			var angle:float=TAU*i/16-.14;burst.append(center+Vector2(cos(angle)*1.8,sin(angle))*(50 if i%2==0 else 26))
		draw_colored_polygon(burst,Color(impact_color,minf(impact_left*5,.8)))
		var w:=title_font.get_string_size(impact_text,HORIZONTAL_ALIGNMENT_LEFT,-1,40).x
		var at:=center+Vector2(-w*.5,13)
		draw_string_outline(title_font,at,impact_text,HORIZONTAL_ALIGNMENT_LEFT,-1,40,7,Color("0a1025"));draw_string(title_font,at,impact_text,HORIZONTAL_ALIGNMENT_LEFT,-1,40,WHITE)
	if flash>0:draw_rect(Rect2(Vector2.ZERO,size),Color(.7,.12,.16,flash*.25))
