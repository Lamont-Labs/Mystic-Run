extends Control

signal intent(action: String, value: String)
const Courses=preload("res://core/course_catalog.gd")
const Progress=preload("res://core/progression.gd")
const Secrets=preload("res://core/secret_catalog.gd")
const INK:=Color("302459")
const GOLD:=Color("ffcf58")
const WHITE:=Color("fffbed")
const MUTED:=Color("eadfff")
const ACCENTS:={"knight":Color("65e8ef"),"gargoyle":Color("76e1be"),"witch":Color("be91ff")}
const HEROES:={
 "knight":{"role":"THE VANGUARD","power":"SUNBURST","detail":"Swipe a sword strike. Sunburst sends a golden shockwave through nearby enemies.","cooldown":"8 SEC RECHARGE"},
 "gargoyle":{"role":"THE SKYBREAKER","power":"STONE POP","detail":"Swipe a claw strike. Stone Pop blasts nearby enemies with a stone burst.","cooldown":"7 SEC RECHARGE"},
 "witch":{"role":"THE RIFTWEAVER","power":"STARFALL","detail":"Swipe an arcane strike. Starfall zaps up to three enemies with starlight.","cooldown":"9 SEC RECHARGE"}}
class TreasureStamp:
	extends Control
	var owned:bool=false
	var tint:=Color("ffcf58")
	var font:Font
	func _draw() -> void:
		var centre:=size*.5;draw_circle(centre,35,Color(tint,.14))
		if owned:
			var points:=PackedVector2Array()
			for i in range(10):
				var a:float=TAU*i/10-PI*.5;points.append(centre+Vector2(cos(a),sin(a))*(28 if i%2==0 else 13))
			draw_colored_polygon(points,tint)
		else:
			draw_arc(centre,28,0,TAU,40,Color(tint,.4),3,true)
			if font:draw_string(font,centre+Vector2(-10,11),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,36,Color(tint,.6))

var screen: String="opening"
var visual_clock:float=0.0
var selected: String="knight"
var course_id: String="endless"
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
var stage_control:Control
var page_tween:Tween
var back_visible: bool=false
var top_inset: float=24
var bottom_inset: float=18

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	city=load("res://assets/environment/cloud-castle-v2.jpg")
	var g:=Gradient.new()
	g.colors=PackedColorArray([Color(.18,.14,.37,.02),Color(.20,.13,.37,.92)])
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
	header.visible=true
	_build_header()
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
		"collection":_collection()
		"achievements":_achievements()
		"privacy":_privacy()
		"reset_confirm":_reset_confirm()
	if screen in ["opening","home","team","routes","records","collection","achievements"]: _build_dock()
	dock.visible=screen in ["opening","home","team","routes","records","collection","achievements"]
	_animate_page()
	queue_redraw()

func _style(primary: bool=false, selected_card: bool=false) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=GOLD if primary else Color("534080",.95)
	s.border_color=ACCENTS[selected] if selected_card else Color("d7bbf2",.9)
	s.set_border_width_all(4 if selected_card else 2)
	s.shadow_color=Color("302459",.55);s.shadow_size=3;s.shadow_offset=Vector2(0,7)
	s.set_corner_radius_all(28)
	s.content_margin_left=20;s.content_margin_right=20;s.content_margin_top=14;s.content_margin_bottom=14
	return s

func _text(parent: Node, value: String, point_size: int=26, color: Color=WHITE, display: bool=false) -> Label:
	var label:=Label.new();label.text=value
	label.add_theme_font_override("font",title_font if display else body_font)
	label.add_theme_font_size_override("font_size",point_size);label.add_theme_color_override("font_color",color)
	if display:
		label.add_theme_color_override("font_outline_color",INK);label.add_theme_constant_override("outline_size",7)
		label.add_theme_color_override("font_shadow_color",Color("302459",.6));label.add_theme_constant_override("shadow_offset_y",4)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(label)
	return label

func _button(parent: Node, id: String, text: String, action: String, value: String="", primary: bool=false, height: float=96) -> Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size=Vector2(0,maxf(96,height));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.add_theme_font_override("font",title_font if primary else body_font);b.add_theme_font_size_override("font_size",36 if primary else 23)
	b.add_theme_color_override("font_color",INK if primary else WHITE)
	b.add_theme_stylebox_override("normal",_style(primary))
	var pressed:=_style(primary,true);pressed.bg_color=Color("d0fbff") if primary else Color("7956a4")
	b.add_theme_stylebox_override("pressed",pressed);b.add_theme_stylebox_override("hover",pressed)
	var focused:=_style(primary,true);b.add_theme_stylebox_override("focus",focused)
	b.button_down.connect(func():
		if not profile.get("settings",{}).get("reduced_motion",false):
			b.pivot_offset=b.size*.5;b.create_tween().tween_property(b,"scale",Vector2.ONE*.97,.05))
	b.button_up.connect(func():b.create_tween().tween_property(b,"scale",Vector2.ONE,.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
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
	var landing:bool=screen in ["opening","home"]
	var title:=_text(header,"L A M O N T   L A B S" if landing else "MYSTIC RUN",18 if landing else 32,GOLD if landing else WHITE,not landing);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	if screen in ["opening","home","team","routes","records"]:
		var settings:=_button(header,"settings","SETTINGS","navigate","settings",false,96);settings.size_flags_horizontal=Control.SIZE_SHRINK_END;settings.custom_minimum_size.x=152

func _build_dock() -> void:
	for item in [["home","PLAY"],["team","RUNNERS"],["routes","COURSES"],["records","JOURNAL"]]:
		var b:=_button(dock,"nav_"+item[0],"MODES" if item[0]=="routes" else item[1],"tab",item[0],false,96)
		b.add_theme_font_size_override("font_size",20)
		if screen==item[0] or screen=="opening" and item[0]=="home" or screen in ["collection","achievements"] and item[0]=="records": b.add_theme_stylebox_override("normal",_style(false,true));b.add_theme_color_override("font_color",ACCENTS[selected])

func _hero_image(parent: Node, hero: String, height: float) -> void:
	var image:=TextureRect.new();image.texture=portraits[hero];image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size=Vector2(0,height);image.size_flags_horizontal=Control.SIZE_EXPAND_FILL;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(image)

func _opening() -> void:
	_home()

func _home() -> void:
	var title:=_text(content,"MYSTIC RUN",92,GOLD,true)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var line:=_text(content,"BIG MAGIC. LITTLE TROUBLE.",17,GOLD)
	line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var stage:=Control.new();stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage.custom_minimum_size.y=clampf(size.y-930,250,630);content.add_child(stage)
	stage_control=stage
	var hero:=_panel(content,true)
	var row:=HBoxContainer.new();hero.add_child(row)
	var identity:=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(identity)
	_text(identity,"THE "+selected.to_upper(),32,WHITE,true)
	_text(identity,"SPECIAL · "+HEROES[selected].power,18,ACCENTS[selected])
	var change:=_button(row,"view_team","CHANGE","navigate","team",false,96)
	change.size_flags_horizontal=Control.SIZE_SHRINK_END;change.custom_minimum_size.x=150
	_text(hero,Progress.next_goal(_progress(),selected),18,GOLD)
	var course:=Courses.get_course(course_id)
	_button(content,"choose_course",course.title+"   ›","navigate","routes",false,96)
	_button(actions,"play","LET’S RUN!","start","",true,104)
	var note:=_text(actions,str(profile.get("settings",{}).get("control_mode","tilt")).to_upper()+" TO STEER  ·  SWIPE LEFT / RIGHT TO STRIKE",17,MUTED)
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func _team() -> void:
	_heading("YOUR ADVENTURE CREW","WHO’S COMING?","Every runner can finish ordinary routes. Earn mastery to discover their secret places.")
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);content.add_child(row)
	for kind in ["knight","gargoyle","witch"]:
		var b:=_button(row,kind,kind.to_upper(),"character",kind,false,96);b.add_theme_font_override("font",title_font);b.add_theme_font_size_override("font_size",30)
		if kind==selected:b.add_theme_stylebox_override("normal",_style(false,true))
	var stage:=Control.new();stage.custom_minimum_size.y=clampf(size.y-1200,200,420);stage.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(stage);stage_control=stage
	var hero:=_panel(content,true);var progress:Dictionary=_progress()
	_text(hero,selected.to_upper()+" · "+HEROES[selected].power,37,WHITE,true)
	_text(hero,HEROES[selected].detail,22,MUTED)
	_text(hero,("TRAVERSAL UNLOCKED · " if Progress.ability_unlocked(progress,selected) else "EARN 60 MASTERY XP · ")+Secrets.ABILITIES[selected],22,ACCENTS[selected])
	_text(hero,Secrets.ABILITY_DETAILS[selected],21,MUTED);_meter(hero,int(progress.mastery[selected]),60)
	_text(hero,"%d MASTERY XP · %s"%[int(progress.mastery[selected]),HEROES[selected].cooldown],18,GOLD)
	_button(actions,"team_done","LET’S GO, "+selected.to_upper()+"!","home","",true,100)

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
	_button(actions,"start","RUN "+("ENDLESS" if course_id=="endless" else "EXPEDITION"),"start","",true,100)
	_button(content,"route_team","CHANGE STARTING RUNNER","navigate","team",false,76)

func _records() -> void:
	var progress:Dictionary=_progress()
	_heading("ONE MORE ADVENTURE?","YOUR ADVENTURE BOOK","Collect treasures, earn badges and unlock secret routes. Saved on this phone.")
	var links:=HBoxContainer.new();links.add_theme_constant_override("separation",12);content.add_child(links)
	_button(links,"collection","TREASURES %d / 9"%progress.artifacts.size(),"navigate","collection")
	_button(links,"achievements","BADGES %d / %d"%[progress.badges.size(),Progress.BADGES.size()],"navigate","achievements")
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
	_text(content,"Tilt to steer, or choose THUMB and hold the steering pad. Horizontal swipes always attack; they never change lane. Recenter through Pause when you change your grip.",23,MUTED)
	var settings: Dictionary=profile.get("settings",{})
	for item in [["music","MUSIC"],["sound","SOUND EFFECTS"],["vibration","HAPTIC FEEDBACK"],["quality","GRAPHICS"],["reduced_motion","REDUCED MOTION"]]:
		var value: bool=settings.get(item[0],true)
		_button(content,item[0],item[1]+"   /   "+(("HIGH" if value else "BATTERY") if item[0]=="quality" else ("ON" if value else "OFF")),"setting",item[0])
	_button(content,"sensitivity","SWIPE SENSITIVITY   /   "+str(settings.get("sensitivity","normal")).to_upper(),"sensitivity")
	_text(content,"High sensitivity needs a shorter swipe. Battery graphics reduce shadows and limit the game to 30 frames per second.",24,MUTED)
	_button(content,"howto","HOW TO PLAY","navigate","howto")
	_button(content,"privacy","PRIVACY & LOCAL PROGRESS","navigate","privacy")
	_button(content,"credits","CREDITS & LICENSES","navigate","credits")
	_text(content,"MYSTIC RUN  "+str(ProjectSettings.get_setting("application/config/version")),20,MUTED)

func _howto() -> void:
	_heading("KEEP THE RUN ALIVE","HOW TO PLAY")
	for item in [["TILT OR THUMB TO STEER","Tilt gently across the path, or hold the steering pad at the lower left. Choose your preferred control in Settings."],["SWIPE UP / DOWN","Up jumps over barriers and gaps. Down slides beneath overhead beams."],["SWIPE LEFT / RIGHT TO STRIKE","Swipe across the open play area when the enemy cue lights up. Both directions attack. There is no basic attack button. Taps do not attack."],["THE SPECIAL BUTTON","Sunburst, Stone Pop and Starfall are ready from the start. Press SPECIAL for your character’s combat move; the ring shows its recharge."],["UNLOCK SECRET ABILITIES","Earn 60 mastery XP with a runner to unlock Sunbreak, Skyglide or Riftwalk. They are separate from combat specials. Every runner can finish ordinary routes before unlocking an ability."],["OPEN A SECRET ROUTE","Steer into your marked portal lane and swipe up when close. Your unlocked ability opens a distinct 96-metre area. Follow the stars and steer into its treasure. Every level has a different treasure for each runner."],["BUILD YOUR COLLECTION","There are nine treasures and fourteen badges in Journal. XP comes from ordinary running, relics, defeated enemies and expedition clears. Guided practice earns no mastery."]]:
		var card:=_panel(content);_text(card,item[0],30,ACCENTS[selected],true);_text(card,item[1],25,MUTED)
	if profile.get("in_run",false):_button(actions,"back_to_run","CONTINUE RUN","resume","",true,94)
	else:_button(actions,"practice","TRY GUIDED PRACTICE","practice","",true,94)
	_text(content,"Desktop: arrows or WASD to move, Space to strike, E for the special attack, Escape to go back or pause.",23,MUTED)

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
	_heading("PRACTICE COMPLETE" if outcome=="practice" else "EXPEDITION COMPLETE" if outcome=="clear" else "TIME FOR ANOTHER?","WELL RUN" if outcome in ["clear","practice"] else "THAT WAS AN ADVENTURE!")
	_text(content,str(result.get("detail","")),26,MUTED)
	var box:=_panel(content,true)
	_text(box,"%d METRES"%int(result.get("distance",0)),66,WHITE,true)
	_text(box,"%d SCORE  ·  %d RELICS"%[int(result.get("score",0)),int(result.get("shards",0))],28,ACCENTS[selected])
	_text(box,"%d SENTINELS DEFEATED"%int(result.get("defeated",0)),23,MUTED)
	_text(box,"PERSONAL BEST / %d METRES"%int(profile.get("best",0)),23,MUTED)
	if outcome!="practice":
		_text(box,"+%d MASTERY XP"%int(result.get("xp",0)),32,GOLD,true);_meter(box,int(_progress().mastery[selected]),60)
		if result.get("unlocked",false):_text(box,Secrets.ABILITIES[selected]+" UNLOCKED! Secret routes await on your next run.",25,ACCENTS[selected],true)
		for id in result.get("new_badges",[]):_text(box,"BADGE EARNED · "+Progress.badge_title(str(id)),22,GOLD)
		for id in result.get("treasures",[]):_text(box,"TREASURE FOUND · "+Secrets.room(str(id).get_slice("/",0),selected).artifact,23,ACCENTS[selected])
	_button(actions,"restart","PRACTICE AGAIN" if outcome=="practice" else "RUN AGAIN","restart","",true,94)
	_button(content,"choose_route","CHOOSE ANOTHER ROUTE","results_routes")
	_button(content,"choose_runner","CHANGE RUNNER","results_team")
	_button(actions,"home","RETURN HOME","home")

func _progress() -> Dictionary:return Progress.normalise(profile.get("progress",{}),profile)
func _meter(parent:Node,value:int,maximum:int) -> void:
	var meter:=ProgressBar.new();meter.custom_minimum_size.y=16;meter.max_value=maximum;meter.value=mini(value,maximum);meter.show_percentage=false
	var bg:=StyleBoxFlat.new();bg.bg_color=Color("354669");bg.set_corner_radius_all(8)
	var fill:=StyleBoxFlat.new();fill.bg_color=ACCENTS[selected];fill.set_corner_radius_all(8)
	meter.add_theme_stylebox_override("background",bg);meter.add_theme_stylebox_override("fill",fill);parent.add_child(meter)
func _collection() -> void:
	var progress:Dictionary=_progress();_heading("A LITTLE EXPLORING GOES A LONG WAY","THE TREASURE ROOM","%d / 9 found. Every level hides a separate place for each runner."%progress.artifacts.size())
	for level in Secrets.LEVELS:
		_text(content,Courses.get_course(level).title,34,GOLD,true)
		for hero in Secrets.HEROES:
			var entry:Dictionary=Secrets.room(level,hero);var owned:bool=progress.artifacts.has(entry.id);var card:=_panel(content,owned)
			var row:=HBoxContainer.new();row.add_theme_constant_override("separation",18);card.add_child(row)
			var stamp:=TreasureStamp.new();stamp.owned=owned;stamp.tint=ACCENTS[hero];stamp.font=title_font;stamp.custom_minimum_size=Vector2(80,80);row.add_child(stamp)
			var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
			_text(words,entry.artifact if owned else "A SECRET AWAITS…",31,WHITE,true);_text(words,hero.to_upper()+" · "+entry.title,19,ACCENTS[hero])
			_text(card,"FOUND!" if owned else "USE "+entry.ability+" AT THE MARKED PORTAL" if Progress.ability_unlocked(progress,hero) else "EARN 60 MASTERY XP WITH "+hero.to_upper(),19,GOLD)
func _achievements() -> void:
	var progress:Dictionary=_progress();_heading("LOOK WHAT YOU DID!","YOUR BADGES","%d / %d earned. Local achievements, saved on this phone."%[progress.badges.size(),Progress.BADGES.size()])
	for badge in Progress.BADGES:
		var owned:bool=progress.badges.has(badge.id);var card:=_panel(content,owned)
		_text(card,("EARNED! · " if owned else "TO DISCOVER · ")+badge.title,30,GOLD if owned else WHITE,true);_text(card,badge.detail,23,MUTED)
func _privacy() -> void:
	_heading("YOUR ADVENTURE, YOUR PHONE","PRIVACY & LOCAL PROGRESS")
	_text(content,"Mystic Run privacy information — November 2, 2026. Developer: Lamont Labs. Contact: LamontLabs@proton.me.",24,WHITE)
	_text(content,"This build works offline. It has no accounts, advertising, analytics SDKs, purchases or network permission. Lamont Labs does not receive gameplay records through this build.",24,MUTED)
	_text(content,"Settings, run records, mastery, achievements, lessons and treasure discoveries are saved locally on your device. Motion sensors are used locally to steer and calibrate your holding angle. Sensor samples are not saved or transmitted. Vibration provides optional gameplay feedback.",24,MUTED)
	_text(content,"Progress remains until you clear it or remove the app and its data. Android app-data backup is disabled. Clear Local Progress removes game records and their previous-save backup from this phone while retaining your control, audio and accessibility preferences. There are no server accounts or server-side records to delete.",24,MUTED)
	_text(content,"Google Play and your operating system can process their own platform data under their own policies. This notice describes the game. Adding online services or SDKs requires a new disclosure review.",23,MUTED)
	if not profile.get("in_run",false):_button(content,"clear_progress","CLEAR LOCAL PROGRESS…","navigate","reset_confirm")
func _reset_confirm() -> void:
	_heading("START A FRESH ADVENTURE?","CLEAR LOCAL PROGRESS")
	_text(content,"This removes run records, mastery, unlocked abilities, badges, treasures and lessons from this phone, including the previous-save backup. Control, audio and reduced-motion settings stay. This cannot be undone.",25,MUTED)
	if not str(profile.get("reset_error","")).is_empty():_text(content,str(profile.reset_error),24,GOLD)
	_button(actions,"confirm_clear","YES, CLEAR MY PROGRESS","reset_progress");_button(actions,"cancel_clear","KEEP MY ADVENTURE","back","",true)
func _animate_page() -> void:
	if is_instance_valid(page_tween):page_tween.kill()
	frame.modulate=Color.WHITE
	if profile.get("settings",{}).get("reduced_motion",false):return
	frame.modulate.a=.2;page_tween=create_tween();page_tween.tween_property(frame,"modulate:a",1.0,.18).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	if city==null:return
	if screen in ["opening","home","team"]:
		# The actual playable hero and 3D district remain visible behind the menu.
		draw_texture_rect(shade,Rect2(Vector2.ZERO,size),false)
		draw_rect(Rect2(0,0,size.x,200),Color("3d3970",.04))
	elif screen=="pause" or screen in ["settings","howto","credits"] and profile.get("in_run",false):
		draw_rect(Rect2(Vector2.ZERO,size),Color("32214f",.80))
	else:
		var source:=Vector2(city.get_width(),city.get_height())
		var scale_value:=maxf(size.x/source.x,size.y/source.y)
		var region_size:=size/scale_value
		draw_texture_rect_region(city,Rect2(Vector2.ZERO,size),Rect2((source-region_size)*.5,region_size))
		draw_texture_rect(shade,Rect2(Vector2.ZERO,size),false)
		draw_rect(Rect2(Vector2.ZERO,size),Color("3e2c64",.08 if screen=="opening" else .30))
	if screen in ["opening","home"]:
			for i in range(24):
				var at:=Vector2(fposmod(i*137.7+sin(visual_clock*.2+i)*24,size.x),fposmod(i*79.3-visual_clock*(4+i%4),size.y))
				draw_circle(at,1.0 if i%3 else 2.0,Color(GOLD,.20+sin(visual_clock+i)*.10))
	draw_line(Vector2(30,size.y-bottom_inset-110),Vector2(size.x-30,size.y-bottom_inset-110),Color(ACCENTS[selected],.25),1,true)

func _process(delta:float) -> void:
	if visible:visual_clock+=delta;queue_redraw()
