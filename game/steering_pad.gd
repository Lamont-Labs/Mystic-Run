extends Control
## A dedicated thumb region preserves horizontal swipes for combat.
var axis:float=0
var active:bool=false
var pointer:int=-99
var font:Font
var accent:=Color("70f1dc")
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func reset() -> void:axis=0;active=false;pointer=-99;queue_redraw()
func _notification(what:int) -> void:
	if what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():reset()
func _input(event:InputEvent) -> void:
	if not is_visible_in_tree():return
	var id:int=-99;var at:=Vector2.ZERO;var start:bool=false;var finish:bool=false
	if event is InputEventScreenTouch:id=event.index;at=event.position;start=event.pressed;finish=not event.pressed or event.canceled
	elif event is InputEventScreenDrag:id=event.index;at=event.position
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:id=-1;at=event.position;start=event.pressed;finish=not event.pressed
	elif event is InputEventMouseMotion and active and pointer==-1:id=-1;at=event.position
	else:return
	var local:Vector2=get_global_transform_with_canvas().affine_inverse()*at
	if start and not active and Rect2(Vector2.ZERO,size).has_point(local):active=true;pointer=id
	if not active or pointer!=id:return
	if finish:reset()
	else:axis=clampf((local.x-size.x*.5)/(size.x*.36),-1,1);queue_redraw()
	get_viewport().set_input_as_handled()
func _draw() -> void:
	var centre:=size*Vector2(.5,.42);var style:=StyleBoxFlat.new();style.bg_color=Color("534080",.90);style.border_color=Color(accent,.7);style.set_border_width_all(2);style.set_corner_radius_all(26)
	draw_style_box(style,Rect2(Vector2.ZERO,size))
	for sign_value in [-1,1]:
		var at:Vector2=centre+Vector2(sign_value*size.x*.34,0)
		draw_colored_polygon(PackedVector2Array([at+Vector2(sign_value*8,0),at+Vector2(-sign_value*6,-9),at+Vector2(-sign_value*6,9)]),Color(accent,.7))
	draw_line(centre-Vector2(size.x*.20,0),centre+Vector2(size.x*.20,0),Color(accent,.3),3,true)
	draw_circle(centre+Vector2(axis*size.x*.20,0),12,accent if active else Color("d4e8f1",.8))
	if font:draw_string(font,Vector2(size.x*.5-29,size.y-15),"STEER",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d4e8f1"))
