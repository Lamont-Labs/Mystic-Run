extends Control
signal intent(action:String,value:String)
const FrontEnd=preload("res://game/front_end.gd")
const Pad=preload("res://game/steering_pad.gd")
const Secrets=preload("res://core/secret_catalog.gd")
const WHITE:=Color("f1f7ff")
const ACCENTS:={"knight":Color("7dedf0"),"gargoyle":Color("84f3ce"),"witch":Color("d0a2ff")}
class SpecialButton:
	extends Button
	var hero:String="knight"
	var remaining:float=0
	var font:Font
	func _draw() -> void:
		var c:=size*Vector2(.5,.40);var colour:Color=ACCENTS[hero] if not disabled else Color("95a7c4")
		var duration:float={"knight":8.0,"gargoyle":7.0,"witch":9.0}[hero]
		draw_arc(size*.5,size.x*.5-5,-PI/2,-PI/2+TAU*maxf(.01,1-remaining/duration),64,colour,4,true)
		if remaining>0:
			var text:String="%.1f"%remaining;var w:float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,34).x
			draw_string(font,c+Vector2(-w*.5,12),text,HORIZONTAL_ALIGNMENT_LEFT,-1,34,colour)
		elif hero=="gargoyle":
			draw_circle(c+Vector2(0,6),13,colour)
			for i in range(3):draw_circle(c+Vector2((i-1)*15,-14),6,colour)
		else:
			var p:=PackedVector2Array()
			for i in range(10):
				var a:float=TAU*i/10-PI/2;p.append(c+Vector2(cos(a),sin(a))*(25 if i%2==0 else 10))
			draw_colored_polygon(p,colour)
		var w:float=font.get_string_size("SPECIAL",HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
		draw_string(font,Vector2((size.x-w)/2,size.y-17),"SPECIAL",HORIZONTAL_ALIGNMENT_LEFT,-1,20,WHITE)
var mode:String="opening"
var selected:String="knight"
var course_id:String="endless"
var profile_data:Dictionary={}
var result_data:Dictionary={}
var navigation:Array[String]=["opening"]
var front:Control
var game_buttons:Dictionary={}
var thumb_pad:Control
var buttons:Dictionary:
	get:return front.buttons if is_instance_valid(front) and front.visible else game_buttons
var labels:Dictionary={}
var title_font:Font
var ui_font:Font
var portraits:Dictionary={}
var session:Dictionary={}
var settings:Dictionary={}
var route_visible:bool=false
var combat_ready:bool=false
var combat_warning:bool=false
var threat_position:=Vector2.ZERO
var threat_seconds:float=INF
var secret_hint:String=""
var intro_active:bool=false
var district_name:String=""
var district_left:float=0
var guide_title:String=""
var guide_detail:String=""
var flash:float=0
var message_left:float=0
var impact_left:float=0
var impact_text:String=""
var impact_color:=Color("75f3da")
var countdown_text:String="READY"
var control_hint:String="HOLD YOUR PHONE COMFORTABLY"
var top_pad:float=22
var bottom_pad:float=16
var fade:GradientTexture2D
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_font=load("res://assets/fonts/bangers.ttf")
	var body:=FontVariation.new();body.base_font=load("res://assets/fonts/manrope.ttf")
	body.variation_opentype={TextServerManager.get_primary_interface().name_to_tag("wght"):650.0};ui_font=body
	for hero in Secrets.HEROES:portraits[hero]=load("res://assets/illustrations/"+hero+"-comic-v1.png")
	var gradient:=Gradient.new();gradient.offsets=PackedFloat32Array([0,.23,.75,1]);gradient.colors=PackedColorArray([Color(.04,.08,.17,.65),Color(.04,.08,.17,0),Color(.04,.08,.17,0),Color(.04,.08,.17,.5)])
	fade=GradientTexture2D.new();fade.gradient=gradient;fade.fill_from=Vector2.ZERO;fade.fill_to=Vector2(0,1)
	for definition in [["distance",64,true],["unit",15,false],["score",22,false],["district",22,true],["objective",17,false],["message",30,true],["guide_title",38,true],["guide_detail",24,false],["combat_hint",30,true],["countdown",112,true],["ready_caption",24,false],["combo",25,true],["secret_hint",27,true],["speed",24,false],["steering",16,false],["ability",18,false]]:
		var l:=Label.new();l.mouse_filter=Control.MOUSE_FILTER_IGNORE;l.add_theme_font_override("font",title_font if definition[2] else ui_font)
		l.add_theme_font_size_override("font_size",definition[1]);l.add_theme_color_override("font_color",WHITE);l.add_theme_color_override("font_outline_color",Color("152641"));l.add_theme_constant_override("outline_size",4)
		add_child(l);labels[definition[0]]=l
	labels.unit.text="METRES";labels.combat_hint.text="SWIPE TO STRIKE!"
	for key in ["message","guide_title","guide_detail","ready_caption","secret_hint"]:labels[key].autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var pause:=Button.new();pause.text="II";pause.add_theme_font_override("font",ui_font);pause.add_theme_font_size_override("font_size",30)
	pause.add_theme_stylebox_override("normal",_style(false));pause.add_theme_stylebox_override("pressed",_style(true));pause.pressed.connect(func():intent.emit("pause",""));add_child(pause);game_buttons.pause=pause
	var power:=SpecialButton.new();power.font=ui_font;power.add_theme_stylebox_override("normal",_style(false,true));power.add_theme_stylebox_override("pressed",_style(true,true));power.add_theme_stylebox_override("disabled",_style(false,true))
	power.pressed.connect(func():intent.emit("power",""));add_child(power);game_buttons.power=power
	thumb_pad=Pad.new();thumb_pad.font=ui_font;add_child(thumb_pad)
	var skip:=Button.new();skip.text="SKIP";skip.add_theme_font_override("font",ui_font);skip.add_theme_font_size_override("font_size",18);skip.add_theme_stylebox_override("normal",_style(false));skip.pressed.connect(func():intent.emit("skip_intro",""));add_child(skip);game_buttons.skip_intro=skip
	front=FrontEnd.new();front.title_font=title_font;front.body_font=ui_font;front.portraits=portraits;add_child(front);front.intent.connect(func(a:String,v:String):intent.emit(a,v))
	_layout();refresh()
func _style(active:bool,circle:bool=false) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=Color("ae77de",.98) if active else Color("594184",.95);s.border_color=Color("ffe5a4");s.set_border_width_all(3);s.shadow_color=Color("302459",.5);s.shadow_size=3;s.shadow_offset=Vector2(0,5);s.set_corner_radius_all(80 if circle else 24);return s
func _notification(what:int) -> void:
	if what==NOTIFICATION_RESIZED and not labels.is_empty():_layout()
func _place(key:String,at:Vector2,dimensions:Vector2,align:HorizontalAlignment=HORIZONTAL_ALIGNMENT_LEFT) -> void:
	labels[key].position=at;labels[key].size=dimensions;labels[key].horizontal_alignment=align
func _layout() -> void:
	var w:float=size.x;var h:float=size.y;top_pad=22;bottom_pad=16
	if OS.get_name()=="Android":
		var safe:=DisplayServer.get_display_safe_area();var window:=DisplayServer.window_get_size()
		if window.y>0 and safe.size.y>0:top_pad=maxf(22,safe.position.y*h/window.y+10);bottom_pad=maxf(16,(window.y-safe.end.y)*h/window.y+10)
	_place("distance",Vector2(w*.5-100,top_pad-8),Vector2(200,70),HORIZONTAL_ALIGNMENT_CENTER)
	_place("unit",Vector2(w*.5-100,top_pad+61),Vector2(200,24),HORIZONTAL_ALIGNMENT_CENTER)
	_place("score",Vector2(28,top_pad+51),Vector2(190,36))
	_place("combo",Vector2(28,top_pad+88),Vector2(210,36))
	_place("district",Vector2(25,top_pad+133),Vector2(w-50,40),HORIZONTAL_ALIGNMENT_CENTER)
	_place("objective",Vector2(25,top_pad+96),Vector2(w-50,28),HORIZONTAL_ALIGNMENT_CENTER)
	_place("guide_title",Vector2(30,top_pad+188),Vector2(w-180,110))
	_place("guide_detail",Vector2(30,top_pad+300),Vector2(w-60,108))
	_place("combat_hint",Vector2(w*.5-180,h-bottom_pad-242),Vector2(360,45),HORIZONTAL_ALIGNMENT_CENTER)
	_place("secret_hint",Vector2(30,h*.33),Vector2(w-60,100),HORIZONTAL_ALIGNMENT_CENTER)
	_place("message",Vector2(28,h-bottom_pad-313),Vector2(w-56,100),HORIZONTAL_ALIGNMENT_CENTER)
	_place("countdown",Vector2(0,h*.34),Vector2(w,150),HORIZONTAL_ALIGNMENT_CENTER)
	_place("ready_caption",Vector2(30,h*.34+160),Vector2(w-60,90),HORIZONTAL_ALIGNMENT_CENTER)
	if game_buttons.is_empty():return
	game_buttons.pause.position=Vector2(w-122,top_pad);game_buttons.pause.size=Vector2(96,96)
	game_buttons.power.position=Vector2(w-180,h-bottom_pad-178);game_buttons.power.size=Vector2(156,156)
	game_buttons.skip_intro.position=Vector2(w-126,top_pad+188);game_buttons.skip_intro.size=Vector2(96,96)
	thumb_pad.position=Vector2(28,h-bottom_pad-155);thumb_pad.size=Vector2(192,128)
	queue_redraw()
func set_mode(value:String) -> void:
	mode=value
	if mode!="game" and is_instance_valid(thumb_pad):thumb_pad.reset()
	refresh()
func open_screen(screen:String,root:bool=false) -> void:
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
	thumb_pad.hide();front.visible=mode not in ["game","countdown","closing"]
	if front.visible:front.show_screen(mode,selected,course_id,profile_data,result_data,navigation.size()>1 or mode in ["pause","results"])
	elif mode=="game":
		for key in ["distance","unit","score"]:labels[key].show()
		game_buttons.pause.show();game_buttons.power.show();game_buttons.skip_intro.visible=intro_active
	elif mode=="countdown":
		labels.countdown.text=countdown_text;labels.ready_caption.text=control_hint;labels.countdown.show();labels.ready_caption.show();game_buttons.pause.show()
	queue_redraw()
func update_session(data:Dictionary,shards:int) -> void:
	session=data
	if mode!="game":return
	labels.distance.text=str(int(float(data.distance_mm)/1000));labels.score.text="◆ %d"%shards
	var district:String=str(data.get("district","MYSTIC RUN"))
	if district!=district_name:district_name=district;district_left=2.2
	labels.district.text=str(data.secret) if not str(data.get("secret","")).is_empty() else district_name
	var length:float=data.get("course_length",0)
	labels.objective.text="%d / %d M TO THE EXIT"%[mini(int(data.distance_mm/1000),int(length)),int(length)];labels.objective.visible=length>0
	var hero:String=data.character;game_buttons.power.hero=hero;game_buttons.power.remaining=float(data.cooldowns[hero])/60
	game_buttons.power.disabled=game_buttons.power.remaining>0 or data.phase in ["handoff","recovery","failed","completed","committed"]
	game_buttons.power.queue_redraw();thumb_pad.visible=data.get("steering","THUMB")!="TILT";thumb_pad.accent=ACCENTS[hero]
	labels.combo.text="%d IN A ROW!"%int(data.get("combo",0));labels.combo.visible=int(data.get("combo",0))>=3
	labels.guide_title.text=guide_title;labels.guide_detail.text=guide_detail;labels.guide_title.visible=not guide_title.is_empty();labels.guide_detail.visible=not guide_detail.is_empty()
	labels.secret_hint.text=secret_hint;labels.secret_hint.visible=not secret_hint.is_empty()
	labels.combat_hint.visible=combat_ready and guide_title.is_empty() and secret_hint.is_empty();game_buttons.skip_intro.visible=intro_active
	queue_redraw()
func message(value:String,duration:float=1.8) -> void:labels.message.text=value;message_left=duration
func impact(value:String,colour:Color) -> void:impact_text=value;impact_color=colour;impact_left=.35;queue_redraw()
func pickup() -> void:
	if settings.get("reduced_motion",false):return
	labels.score.pivot_offset=labels.score.size*.5;labels.score.scale=Vector2.ONE*1.15
	create_tween().tween_property(labels.score,"scale",Vector2.ONE,.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
func _process(delta:float) -> void:
	if mode=="game":message_left=maxf(0,message_left-delta);impact_left=maxf(0,impact_left-delta);flash=maxf(0,flash-delta*2);district_left=maxf(0,district_left-delta)
	labels.message.visible=mode=="game" and message_left>0
	labels.district.visible=mode=="game" and (district_left>0 or not str(session.get("secret","")).is_empty()) and guide_title.is_empty()
	if labels.message.visible:labels.message.modulate.a=minf(1,message_left*3)
	if impact_left>0 or flash>0:queue_redraw()
func _draw() -> void:
	if fade==null or mode not in ["game","countdown"]:return
	draw_texture_rect(fade,Rect2(Vector2.ZERO,size),false)
	if mode=="countdown":return
	for i in range(3):draw_rect(Rect2(28+i*35,top_pad+16,26,9),Color("ffd16b") if i<int(session.get("health",3)) else Color("5f6683"))
	if combat_warning and threat_position.y>top_pad+170 and threat_position.y<size.y-bottom_pad-230:
		var colour:Color=Color("8affdf") if combat_ready else Color("ffd16b");var radius:float=24 if combat_ready else 31
		for sign_value in [-1,1]:draw_polyline(PackedVector2Array([threat_position+Vector2(sign_value*radius,-13),threat_position+Vector2(sign_value*(radius+7),0),threat_position+Vector2(sign_value*radius,13)]),colour,3,true)
	var length:float=session.get("course_length",0)
	if length>0:
		draw_rect(Rect2(26,top_pad+126,size.x-52,3),Color("435574"));draw_rect(Rect2(26,top_pad+126,(size.x-52)*clampf(float(session.get("distance_mm",0))/1000/length,0,1),3),Color("8affdf"))
	if impact_left>0:
		var centre:=Vector2(size.x*.54,size.y*.53);var p:=PackedVector2Array()
		for i in range(16):
			var a:float=TAU*i/16;p.append(centre+Vector2(cos(a)*1.8,sin(a))*(48 if i%2==0 else 27))
		draw_colored_polygon(p,Color(impact_color,minf(impact_left*4,.75)))
		var w:float=title_font.get_string_size(impact_text,HORIZONTAL_ALIGNMENT_LEFT,-1,42).x;var at:Vector2=centre+Vector2(-w/2,13)
		draw_string_outline(title_font,at,impact_text,HORIZONTAL_ALIGNMENT_LEFT,-1,42,7,Color("152641"));draw_string(title_font,at,impact_text,HORIZONTAL_ALIGNMENT_LEFT,-1,42,WHITE)
	if flash>0:draw_rect(Rect2(Vector2.ZERO,size),Color(.7,.12,.16,flash*.20))
