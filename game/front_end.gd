extends Control

signal intent(action: String, value: String)
const Courses=preload("res://core/course_catalog.gd")
const INK:=Color("111422")
const GOLD:=Color("f0d1a0")
const WHITE:=Color("f1efff")
const MUTED:=Color("b5b6d0")
const ACCENTS:={"knight":Color("65e8ef"),"gargoyle":Color("76e1be"),"witch":Color("be91ff")}
const HEROES:={
 "knight":{"role":"THE VANGUARD","power":"SHIELD CHARGE","detail":"A close-range sword strike. Charge breaks through enemies and low barriers.","cooldown":"8 SEC RECHARGE"},
 "gargoyle":{"role":"THE SKYBREAKER","power":"WING BURST","detail":"A powerful close-range strike. Wing Burst lifts you above the course and slows your descent.","cooldown":"7 SEC RECHARGE"},
 "witch":{"role":"THE RIFTWEAVER","power":"ARCANE BLINK","detail":"A ranged arcane strike. Blink moves you to a clear lane without pulling you backward.","cooldown":"9 SEC RECHARGE"}
}
var screen: String="opening"
var visual_clock:float=0.0
var selected: String="knight"
var course_id: String="citadel"
var profile: Dictionary={}
var result: Dictionary={}
var buttons: Dictionary={}
var portraits: Dictionary={}
var title_font: Font
var body_font: Font
var city: Texture2D
var shade: GradientTexture2D
var content: VBoxContainer
var header: HBoxContainer
var actions: VBoxContainer
var dock: HBoxContainer
var scroll: ScrollContainer
var frame: VBoxContainer
var back_visible: bool=false
var top_inset: float=24
var bottom_inset: float=18

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	city=load("res://assets/environment/citadel-matte-v1.png")
	var g:=Gradient.new()
	g.colors=PackedColorArray([Color(.025,.03,.085,.18),Color(.025,.03,.085,.94)])
	shade=GradientTexture2D.new();shade.gradient=g;shade.fill_from=Vector2.ZERO;shade.fill_to=Vector2(0,1)
	frame=VBoxContainer.new();frame.add_theme_constant_override("separation",18)
	add_child(frame)
	header=HBoxContainer.new();header.add_theme_constant_override("separation",14);frame.add_child(header)
	scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;frame.add_child(scroll)
	content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",20);scroll.add_child(content)
	actions=VBoxContainer.new();actions.add_theme_constant_override("separation",12);frame.add_child(actions)
	dock=HBoxContainer.new();dock.add_theme_constant_override("separation",8);frame.add_child(dock)
	_layout()

func _notification(what: int) -> void:
	if what==NOTIFICATION_RESIZED and is_instance_valid(frame): _layout()

func _layout() -> void:
	top_inset=24;bottom_inset=18
	if OS.get_name()=="Android":
		var safe:=DisplayServer.get_display_safe_area()
		var window:=DisplayServer.window_get_size()
		if window.y>0 and safe.size.y>0:
			var scale_y:=size.y/window.y
			top_inset=maxf(24,safe.position.y*scale_y+12)
			bottom_inset=maxf(18,(window.y-safe.end.y)*scale_y+12)
	frame.position=Vector2(30,top_inset)
	frame.size=Vector2(maxf(100,size.x-60),maxf(100,size.y-top_inset-bottom_inset))
	queue_redraw()

func show_screen(value: String, hero: String, route: String, data: Dictionary, end_data: Dictionary, can_back: bool) -> void:
	screen=value;selected=hero;course_id=route;profile=data;result=end_data;back_visible=can_back
	if not is_instance_valid(content): return
	buttons.clear()
	for container in [header,content,actions,dock]:
		for child in container.get_children(): child.hide();child.queue_free()
	scroll.scroll_vertical=0
	header.visible=screen!="opening"
	if screen!="opening":_build_header()
	match screen:
		"opening":_opening()
		"home":_home()
		"team":_team()
		"routes":_routes()
		"records":_records()
		"settings":_settings()
		"howto":_howto()
		"credits":_credits()
		"pause":_pause()
		"results":_results()
	if screen in ["home","team","routes","records"]: _build_dock()
	dock.visible=screen in ["home","team","routes","records"]
	queue_redraw()

func _style(primary: bool=false, selected_card: bool=false) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=GOLD if primary else Color("111525",.88)
	s.border_color=ACCENTS[selected] if selected_card else Color("575064",.65)
	s.set_border_width_all(2 if selected_card else 1)
	s.shadow_color=Color(0,0,0,.25);s.shadow_size=8;s.shadow_offset=Vector2(0,4)
	s.set_corner_radius_all(4)
	s.content_margin_left=20;s.content_margin_right=20;s.content_margin_top=14;s.content_margin_bottom=14
	return s

func _text(parent: Node, value: String, point_size: int=26, color: Color=WHITE, display: bool=false) -> Label:
	var label:=Label.new();label.text=value
	label.add_theme_font_override("font",title_font if display else body_font)
	label.add_theme_font_size_override("font_size",point_size);label.add_theme_color_override("font_color",color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(label)
	return label

func _button(parent: Node, id: String, text: String, action: String, value: String="", primary: bool=false, height: float=88) -> Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size=Vector2(0,height);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.add_theme_font_override("font",title_font if primary else body_font);b.add_theme_font_size_override("font_size",28 if primary else 23)
	b.add_theme_color_override("font_color",INK if primary else WHITE)
	b.add_theme_stylebox_override("normal",_style(primary))
	var pressed:=_style(primary,true);pressed.bg_color=Color("d0fbff") if primary else Color("2d2c50")
	b.add_theme_stylebox_override("pressed",pressed);b.add_theme_stylebox_override("hover",pressed)
	var focused:=_style(primary,true);b.add_theme_stylebox_override("focus",focused)
	b.pressed.connect(func():intent.emit(action,value))
	parent.add_child(b);buttons[id]=b
	return b

func _panel(parent: Node, active: bool=false) -> VBoxContainer:
	var p:=PanelContainer.new();p.add_theme_stylebox_override("panel",_style(false,active));p.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(p)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",14);box.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_child(box)
	return box

func _heading(kicker: String, title: String, detail: String="") -> void:
	_text(content,kicker,20,ACCENTS[selected])
	_text(content,title,44,WHITE,true)
	if not detail.is_empty(): _text(content,detail,25,MUTED)

func _build_header() -> void:
	if back_visible:
		var back:=_button(header,"back","‹ BACK","back","",false,66);back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;back.custom_minimum_size.x=126
	var title:=_text(header,"MYSTIC RUN",40,WHITE,true);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	if screen in ["home","team","routes","records"]:
		var settings:=_button(header,"settings","SETTINGS","navigate","settings",false,66);settings.size_flags_horizontal=Control.SIZE_SHRINK_END;settings.custom_minimum_size.x=152

func _build_dock() -> void:
	for item in [["home","PLAY"],["team","RUNNERS"],["routes","COURSES"],["records","JOURNAL"]]:
		var b:=_button(dock,"nav_"+item[0],item[1],"tab",item[0],false,78)
		b.add_theme_font_size_override("font_size",24)
		if screen==item[0]: b.add_theme_stylebox_override("normal",_style(false,true));b.add_theme_color_override("font_color",ACCENTS[selected])

func _hero_image(parent: Node, hero: String, height: float) -> void:
	var image:=TextureRect.new();image.texture=portraits[hero];image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size=Vector2(0,height);image.size_flags_horizontal=Control.SIZE_EXPAND_FILL;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(image)

func _opening() -> void:
	var space:=Control.new();space.custom_minimum_size.y=maxf(40,size.y*.16);content.add_child(space)
	var studio:=_text(content,"L A M O N T   L A B S",20,GOLD);studio.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var title:=_text(content,"MYSTIC\nRUN",106,WHITE,true);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color",Color(0,0,0,.7));title.add_theme_constant_override("shadow_offset_y",8)
	var line:=_text(content,"THE CITY WILL NOT LET YOU GO.",19,GOLD);line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var bottom:=Control.new();bottom.custom_minimum_size.y=70;content.add_child(bottom)
	_button(actions,"enter","ENTER THE CITY","enter","",true,104)
	_button(actions,"opening_settings","SETTINGS","navigate","settings",false,68)
	var version:=_text(actions,"MYSTIC RUN  /  "+str(ProjectSettings.get_setting("application/config/version")),16,MUTED);version.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func _home() -> void:
	_heading("MAKE YOUR ESCAPE","CHOOSE YOUR PATH")
	var hero:=_panel(content,true)
	_hero_image(hero,selected,clampf(size.y*.26,230,370))
	var row:=HBoxContainer.new();hero.add_child(row)
	var name:=_text(row,selected.to_upper(),38,WHITE,true);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(row,"view_team","CHANGE","navigate","team",false,62)
	_text(hero,HEROES[selected].role+"  ·  "+HEROES[selected].power,19,ACCENTS[selected])
	var course:=Courses.get_course(course_id)
	var route:=_panel(content)
	_text(route,course.title,30,WHITE,true)
	_text(route,str(profile.get("settings",{}).get("control_mode","tilt")).to_upper()+" TO STEER  ·  "+("ENDLESS" if course.length==0 else str(int(course.length))+" METRES"),19,GOLD)
	_button(route,"choose_course","CHANGE COURSE","navigate","routes",false,64)
	_button(actions,"play","RUN WITH THE "+selected.to_upper(),"start","",true,96)
	_button(actions,"practice","PRACTICE CONTROLS","practice","",false,70)

func _team() -> void:
	_heading("THREE WAYS TO ESCAPE","CHOOSE YOUR RUNNER","Choose once. Your runner stays with you until the run ends.")
	var hero:=_panel(content,true)
	_hero_image(hero,selected,minf(size.y*.31,430))
	_text(hero,"THE "+selected.to_upper(),48,WHITE,true)
	_text(hero,HEROES[selected].role+"  /  "+HEROES[selected].power,24,ACCENTS[selected])
	_text(hero,HEROES[selected].detail,25,MUTED)
	_text(hero,HEROES[selected].cooldown,20,ACCENTS[selected])
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);content.add_child(row)
	for kind in ["knight","gargoyle","witch"]:
		var b:=_button(row,kind,kind.to_upper(),"character",kind,false,92);b.add_theme_font_override("font",title_font);b.add_theme_font_size_override("font_size",28)
		if kind==selected:b.add_theme_stylebox_override("normal",_style(false,true))
	_button(actions,"team_routes","TAKE THE LEAD","navigate","routes",true,92)

func _routes() -> void:
	_heading("CHOOSE YOUR EXPEDITION","ROUTES THROUGH THE CITY","A finish line or an endless run. Your starting character is "+selected.to_upper()+".")
	for id in Courses.ORDER:
		var course:=Courses.get_course(id)
		var b:=_button(content,"route_"+id,"","course",id,false,150)
		if id==course_id:b.add_theme_stylebox_override("normal",_style(false,true))
		var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.add_theme_constant_override("margin_left",22);margin.add_theme_constant_override("margin_right",22);margin.add_theme_constant_override("margin_top",12);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(margin)
		var box:=VBoxContainer.new();box.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_theme_constant_override("separation",8);margin.add_child(box)
		_text(box,course.difficulty+"  /  "+("NO FINISH LINE" if course.length==0 else str(int(course.length))+" METRES"),20,ACCENTS[selected])
		_text(box,course.title,36,WHITE,true)
		_text(box,course.subtitle,23,MUTED)
	var chosen:=Courses.get_course(course_id)
	_text(content,chosen.description,25,MUTED)
	var records: Dictionary=profile.get("route_records",{})
	if records.has(course_id):_text(content,"PERSONAL BEST: %d m"%int(records[course_id].get("best",0)),22,ACCENTS[selected])
	_button(actions,"start","BEGIN "+("ENDLESS RUN" if course_id=="endless" else "EXPEDITION"),"start","",true,98)
	_button(content,"route_team","CHANGE STARTING RUNNER","navigate","team",false,76)

func _records() -> void:
	_heading("YOUR RUNS","THE RUN JOURNAL","Records are saved on this phone.")
	var stats:=_panel(content,true)
	_text(stats,"LONGEST RUN",22,ACCENTS[selected]);_text(stats,"%d METRES"%int(profile.get("best",0)),58,WHITE,true)
	_text(stats,"%d RUNS LOGGED  ·  %d RELICS COLLECTED"%[int(profile.get("runs",0)),int(profile.get("relics",0))],25,MUTED)
	var records: Dictionary=profile.get("route_records",{})
	for id in Courses.ORDER:
		var course:=Courses.get_course(id)
		var record: Dictionary=records.get(id,{})
		var card:=_panel(content)
		_text(card,course.title,32,WHITE,true)
		_text(card,"NO RUNS YET" if record.is_empty() else "%d m BEST  ·  %d CLEARS"%[int(record.get("best",0)),int(record.get("clears",0))],23,MUTED)
	var history: Array=profile.get("history",[])
	if not history.is_empty():
		_text(content,"RECENT RUNS",34,WHITE,true)
		for run in history.slice(0,5):
			var card:=_panel(content)
			_text(card,Courses.get_course(str(run.get("course","endless"))).title,28,WHITE,true)
			_text(card,"%d m  ·  %d SCORE  ·  %s"%[int(run.get("distance",0)),int(run.get("score",0)),str(run.get("outcome","finished")).to_upper()],23,MUTED)
	else:_text(content,"Your first expedition will start your journal.",26,MUTED)

func _settings() -> void:
	_heading("MAKE IT YOURS","SETTINGS")
	var controls:Dictionary=profile.get("settings",{})
	_text(content,"MOVEMENT",19,GOLD)
	_button(content,"control_mode","STEERING  /  "+str(controls.get("control_mode","tilt")).to_upper(),"control_mode")
	_button(content,"tilt_sensitivity","TILT SENSITIVITY  /  "+str(controls.get("tilt_sensitivity","normal")).to_upper(),"tilt_sensitivity")
	_button(content,"tilt_invert","INVERT TILT  /  "+("ON" if controls.get("tilt_invert",false) else "OFF"),"setting","tilt_invert")
	if profile.get("in_run",false):_button(content,"recenter","RECENTER TILT & CONTINUE","recenter")
	_text(content,"Hold your phone at a comfortable angle during the countdown. Tilt gently to move across the full width of the path. Recenter through Pause when you change your grip.",23,MUTED)
	var settings: Dictionary=profile.get("settings",{})
	for item in [["music","MUSIC"],["sound","SOUND EFFECTS"],["vibration","HAPTIC FEEDBACK"],["quality","GRAPHICS"],["reduced_motion","REDUCED CAMERA MOTION"]]:
		var value: bool=settings.get(item[0],true)
		_button(content,item[0],item[1]+"   /   "+(("HIGH" if value else "BATTERY") if item[0]=="quality" else ("ON" if value else "OFF")),"setting",item[0])
	_button(content,"sensitivity","SWIPE SENSITIVITY   /   "+str(settings.get("sensitivity","normal")).to_upper(),"sensitivity")
	_text(content,"High sensitivity needs a shorter swipe. Battery graphics reduce shadows and limit the game to 30 frames per second.",24,MUTED)
	_button(content,"howto","HOW TO PLAY","navigate","howto")
	_button(content,"credits","CREDITS & LICENSES","navigate","credits")
	_text(content,"MYSTIC RUN  "+str(ProjectSettings.get_setting("application/config/version")),20,MUTED)

func _howto() -> void:
	_heading("KEEP THE RUN ALIVE","HOW TO PLAY")
	for item in [["TILT TO STEER","Tilt left or right to move smoothly across the path. Your comfortable holding angle is calibrated during the countdown. Swipe steering is available in Settings."],["SWIPE UP","Jump over low barriers and fractures. An early jump just before landing is buffered."],["SWIPE DOWN","Slide beneath overhead beams. Swiping down in the air lands you into a slide."],["TAP TO STRIKE","Tap the open play area or the STRIKE button. A target cue appears as enemies enter reach."],["USE YOUR POWER","The large ability button uses your current runner's signature skill. Each teammate has a separate recharge."],["ONE RUNNER. ONE RUN.","Choose Knight, Gargoyle or Witch before starting. Climb bridges, crest the skyline and descend into the undercity with that runner."]]:
		var card:=_panel(content);_text(card,item[0],30,ACCENTS[selected],true);_text(card,item[1],25,MUTED)
	if profile.get("in_run",false):_button(actions,"back_to_run","CONTINUE RUN","resume","",true,94)
	else:_button(actions,"practice","TRY GUIDED PRACTICE","practice","",true,94)
	_text(content,"Desktop: arrows or WASD to move, Space to strike, E for power, Escape to go back or pause.",23,MUTED)

func _credits() -> void:
	_heading("LAMONT LABS","CREDITS")
	_text(content,"Mystic Run\nOriginal game design, code, interface, custom equipment and synthesized audio: Lamont Labs.\n\nCharacter illustrations and distant city matte generated for Mystic Run. Humanoid meshes and authored motion: Quaternius, CC0 1.0.\n\nGodot Engine: MIT. Bangers, Cinzel and Manrope: SIL OFL 1.1.",25,MUTED)
	for path in ["godot-LICENSE.txt","godot-COPYRIGHT.txt","quaternius-CC0.txt"]:
		_text(content,FileAccess.get_file_as_string("res://assets/licenses/"+path),18,MUTED)

func _pause() -> void:
	_heading("TAKE A BREATH","RUN PAUSED")
	var box:=_panel(content,true);_text(box,Courses.get_course(course_id).title,36,WHITE,true)
	_text(box,"%d METRES  ·  THE %s"%[int(result.get("distance",0)),selected.to_upper()],25,MUTED)
	_button(actions,"resume","CONTINUE RUN","resume","",true,96)
	_button(content,"pause_settings","SETTINGS","navigate","settings")
	if profile.get("settings",{}).get("control_mode","tilt")=="tilt":_button(content,"pause_recenter","RECENTER TILT","recenter")
	_button(content,"pause_howto","CONTROLS","navigate","howto")
	_button(content,"abandon","END RUN & SEE RESULTS","abandon","",false,88)

func _results() -> void:
	var outcome: String=result.get("outcome","finished")
	_heading("PRACTICE COMPLETE" if outcome=="practice" else "EXPEDITION COMPLETE" if outcome=="clear" else "THE RUN ENDS","WELL RUN" if outcome in ["clear","practice"] else "REGROUP & RETURN")
	_text(content,str(result.get("detail","")),26,MUTED)
	var box:=_panel(content,true)
	_text(box,"%d METRES"%int(result.get("distance",0)),66,WHITE,true)
	_text(box,"%d SCORE  ·  %d RELICS"%[int(result.get("score",0)),int(result.get("shards",0))],28,ACCENTS[selected])
	_text(box,"%d SENTINELS DEFEATED  ·  %d RELICS"%[int(result.get("defeated",0)),int(result.get("shards",0))],23,MUTED)
	_text(box,"PERSONAL BEST  /  %d METRES"%int(profile.get("best",0)),23,MUTED)
	_button(actions,"restart","PRACTICE AGAIN" if outcome=="practice" else "RUN AGAIN","restart","",true,94)
	_button(content,"choose_route","CHOOSE ANOTHER ROUTE","results_routes")
	_button(actions,"home","RETURN HOME","home")

func _draw() -> void:
	if city==null:return
	if screen=="pause" or screen in ["settings","howto","credits"] and profile.get("in_run",false):
		draw_rect(Rect2(Vector2.ZERO,size),Color("080c1c",.95))
	else:
		var source:=Vector2(city.get_width(),city.get_height())
		var scale_value:=maxf(size.x/source.x,size.y/source.y)
		var region_size:=size/scale_value
		draw_texture_rect_region(city,Rect2(Vector2.ZERO,size),Rect2((source-region_size)*.5,region_size))
		draw_texture_rect(shade,Rect2(Vector2.ZERO,size),false)
		draw_rect(Rect2(Vector2.ZERO,size),Color("0b1027",.14 if screen=="opening" else .30))
		if screen=="opening":
			for i in range(24):
				var at:=Vector2(fposmod(i*137.7+sin(visual_clock*.2+i)*24,size.x),fposmod(i*79.3-visual_clock*(4+i%4),size.y))
				draw_circle(at,1.0 if i%3 else 2.0,Color(GOLD,.20+sin(visual_clock+i)*.10))
	draw_line(Vector2(30,size.y-bottom_inset-110),Vector2(size.x-30,size.y-bottom_inset-110),Color(ACCENTS[selected],.25),1,true)

func _process(delta:float) -> void:
	if visible and screen=="opening":visual_clock+=delta;queue_redraw()
