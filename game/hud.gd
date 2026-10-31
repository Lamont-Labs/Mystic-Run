extends Control

signal intent(action: String, value: String)

const IVORY := Color("e9e5da")
const MUTED := Color("a0aebd")
const GOLD := Color("d5af76")
const INK := Color("0a101b")
const NAMES := ["knight", "gargoyle", "witch"]

class ActionGlyph:
	extends Control
	var kind: String = "strike"
	var hero: String = "knight"
	var remaining: float = 0.0
	var font: Font
	func _draw() -> void:
		var center := size*Vector2(0.5,0.40)
		var color := Color("ebd2a8")
		if remaining > 0:
			var value := "%.1f" % remaining
			draw_string(font,center+Vector2(-font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x*0.5,8),value,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("aab7c6"))
		elif kind == "strike":
			draw_line(center+Vector2(-13,14),center+Vector2(12,-15),color,4,true)
			draw_line(center+Vector2(-14,2),center+Vector2(-2,13),color,3,true)
			draw_line(center+Vector2(-18,19),center+Vector2(-10,10),Color("a9bac8"),4,true)
		elif hero == "knight":
			var points := PackedVector2Array([center+Vector2(-13,-13),center+Vector2(13,-13),center+Vector2(12,5),center+Vector2(0,17),center+Vector2(-12,5),center+Vector2(-13,-13)])
			draw_polyline(points,color,2,true)
			draw_line(center+Vector2(0,-8),center+Vector2(0,10),color,2,true)
		elif hero == "gargoyle":
			draw_polyline(PackedVector2Array([center+Vector2(-23,-8),center+Vector2(-9,-2),center+Vector2(0,12),center+Vector2(9,-2),center+Vector2(23,-8)]),color,3,true)
			draw_line(center+Vector2(-23,-8),center+Vector2(-10,12),color,2,true)
			draw_line(center+Vector2(23,-8),center+Vector2(10,12),color,2,true)
		else:
			draw_arc(center,15,0,TAU,32,color,2,true)
			draw_line(center+Vector2(0,-22),center+Vector2(0,22),color,2,true)
			draw_line(center+Vector2(-21,0),center+Vector2(21,0),color,2,true)
			draw_circle(center,4,color)
		var text := "STRIKE" if kind == "strike" else "POWER"
		draw_string(font,Vector2(size.x*0.5-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x*0.5,size.y-15),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("d9e1e8"))

var mode: String = "menu"
var selected: String = "knight"
var previous_mode: String = "menu"
var session: Dictionary = {}
var settings := {"music":true, "sound":true, "vibration":true, "quality":true}
var buttons: Dictionary = {}
var labels: Dictionary = {}
var title_font: Font
var ui_font: Font
var menu_gradient: GradientTexture2D
var game_gradient: GradientTexture2D
var message_time: float = 0.0
var flash: float = 0.0
var end_distance: float = 0.0
var end_score: int = 0
var best: float = 0.0
var route_visible: bool = false
var route_lane: int = 1
var route_distance: float = 0.0
var shard_count: int = 0
var credits: RichTextLabel
var action_glyphs: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var weight_axis := TextServerManager.get_primary_interface().name_to_tag("wght")
	var title_variation := FontVariation.new()
	title_variation.base_font = load("res://assets/fonts/cinzel.ttf")
	title_variation.variation_opentype = {weight_axis:500.0}
	title_font = title_variation
	var ui_variation := FontVariation.new()
	ui_variation.base_font = load("res://assets/fonts/manrope.ttf")
	ui_variation.variation_opentype = {weight_axis:580.0}
	ui_font = ui_variation
	menu_gradient = _gradient(true)
	game_gradient = _gradient(false)
	_label("brand", "L A M O N T   L A B S", 16, GOLD)
	_label("title", "MYSTIC\nRUN", 64, IVORY, true)
	_label("eyebrow", "THREE SOULS. ONE ESCAPE.", 17, MUTED)
	_label("hero", "THE KNIGHT", 34, IVORY, true)
	_label("description", "STEEL, RESOLVE & RELENTLESS MOMENTUM", 17, MUTED)
	_label("help", "SWIPE TO MOVE  /  UP TO JUMP  /  DOWN TO SLIDE", 16, MUTED)
	_label("distance", "0", 45, IVORY)
	_label("distance_unit", "METRES", 12, MUTED)
	_label("district", "CATHEDRAL APPROACH", 15, GOLD)
	_label("score", "0  /  SCORE", 16, IVORY)
	_label("route_title", "CHOOSE THE NEXT RUNNER", 14, MUTED)
	_label("message", "", 23, IVORY, true)
	_label("overlay_title", "PAUSED", 44, IVORY, true)
	_label("overlay_detail", "THE CITY CAN WAIT A MOMENT.", 15, MUTED)
	_label("result_distance", "0 m", 56, IVORY, true)
	_label("result_score", "", 19, GOLD)
	_label("best", "", 15, MUTED)
	_label("version", "DEVELOPMENT BUILD  /  "+str(ProjectSettings.get_setting("application/config/version","0.1.2")), 12, MUTED)
	_button("start", "ENTER THE FRACTURE", "start", "", true)
	_button("settings", "SETTINGS", "settings")
	_button("pause", "II", "pause")
	_button("attack", "STRIKE", "attack", "", false, true)
	_button("power", "POWER", "power", "", false, true)
	for key in ["attack","power"]:
		buttons[key].text = ""
		var glyph := ActionGlyph.new()
		glyph.kind = "strike" if key == "attack" else "power"
		glyph.font = ui_font
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		buttons[key].add_child(glyph)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		action_glyphs[key] = glyph
	_button("resume", "CONTINUE RUN", "resume", "", true)
	_button("restart", "RUN AGAIN", "restart", "", true)
	_button("home", "RETURN TO TEAM", "home")
	_button("back", "BACK", "back")
	_button("credits", "CREDITS & LICENSES", "credits")
	credits = RichTextLabel.new()
	credits.add_theme_font_override("normal_font",ui_font)
	credits.add_theme_font_size_override("normal_font_size",18)
	credits.add_theme_color_override("default_color",IVORY)
	credits.text = "MYSTIC RUN\nA Lamont Labs game\n\nOriginal procedural models, environment, gameplay, interface and synthesized audio: Lamont Labs.\n\nWorking development title.\n\nGodot Engine — MIT license\n\n" + FileAccess.get_file_as_string("res://assets/licenses/godot-LICENSE.txt") + "\n\nCinzel and Manrope fonts — SIL Open Font License 1.1. Font license files are included with the project and application.\n\n"
	credits.scroll_active = true
	credits.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(credits)
	for kind in NAMES:
		_button(kind, kind.to_upper(), "character", kind)
	for setting in settings:
		_button(setting, "", "setting", setting)
	_layout()
	refresh()


func _gradient(menu: bool) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.56, 0.78, 1.0])
	gradient.colors = PackedColorArray([Color(INK, 0.85 if menu else 0.55), Color(INK, 0.03), Color(INK, 0.0), Color(INK, 0.86 if menu else 0.03), Color(INK, 0.98 if menu else 0.62)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(0, 1)
	return texture


func _label(id: String, value: String, font_size: int, color: Color, serif: bool = false) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", title_font if serif else ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	labels[id] = label


func _button(id: String, text: String, action: String, value: String = "", primary: bool = false, circle: bool = false) -> void:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", ui_font)
	button.add_theme_font_size_override("font_size", 24 if primary else 15 if circle else 18)
	button.add_theme_color_override("font_color", INK if primary else IVORY)
	button.add_theme_color_override("font_disabled_color", MUTED)
	var style := StyleBoxFlat.new()
	style.bg_color = GOLD if primary else Color(INK, 0.68)
	style.border_color = GOLD if primary else Color("556071")
	style.set_border_width_all(1)
	style.set_corner_radius_all(48 if circle else 3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.border_color = IVORY
	hover.bg_color = Color("eed3aa") if primary else Color("263447")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var disabled := style.duplicate()
	disabled.bg_color = Color(INK, 0.45)
	disabled.border_color = Color("303b4c")
	button.add_theme_stylebox_override("disabled", disabled)
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.pressed.connect(func(): intent.emit(action, value))
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	buttons[id] = button


func _place(id: String, at: Vector2, dimensions: Vector2, button: bool = false, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var node: Control = buttons[id] if button else labels[id]
	node.position = at
	node.size = dimensions
	if not button:
		node.horizontal_alignment = align


func _layout() -> void:
	if labels.is_empty():
		return
	var w := size.x
	var h := size.y
	_place("brand", Vector2(42, 44), Vector2(w-200, 24))
	_place("title", Vector2(38, 133), Vector2(w-76, 170))
	_place("eyebrow", Vector2(42, 310), Vector2(w-84, 28))
	_place("hero", Vector2(42, h-459), Vector2(w-84, 50))
	_place("description", Vector2(44, h-400), Vector2(w-88, 30))
	_place("help", Vector2(32, h-81), Vector2(w-64, 35), false, HORIZONTAL_ALIGNMENT_CENTER)
	_place("version", Vector2(32, h-38), Vector2(w-64, 22), false, HORIZONTAL_ALIGNMENT_CENTER)
	_place("start", Vector2(42, h-197), Vector2(w-84, 82), true)
	_place("settings", Vector2(w-162, 34), Vector2(125, 44), true)
	for index in range(3):
		var cell := (w-100)/3
		_place(NAMES[index], Vector2(42+index*(cell+8), h-323), Vector2(cell, 78), true)
	_place("distance", Vector2(w-230, 49), Vector2(185, 60), false, HORIZONTAL_ALIGNMENT_RIGHT)
	_place("distance_unit", Vector2(w-230, 111), Vector2(185, 25), false, HORIZONTAL_ALIGNMENT_RIGHT)
	_place("district", Vector2(38, 50), Vector2(w-230, 28))
	_place("score", Vector2(38, 145), Vector2(w-76, 30))
	_place("pause", Vector2(w-83, 165), Vector2(45, 45), true)
	_place("attack", Vector2(w-139, h-171), Vector2(98, 98), true)
	_place("power", Vector2(w-261, h-150), Vector2(83, 83), true)
	_place("route_title", Vector2(30, 234), Vector2(w-60, 26), false, HORIZONTAL_ALIGNMENT_CENTER)
	_place("message", Vector2(30, h-290), Vector2(w-60, 55), false, HORIZONTAL_ALIGNMENT_CENTER)
	_place("overlay_title", Vector2(35, 280), Vector2(w-70, 70), false, HORIZONTAL_ALIGNMENT_CENTER)
	_place("overlay_detail", Vector2(35, 355), Vector2(w-70, 50), false, HORIZONTAL_ALIGNMENT_CENTER)
	_place("result_distance", Vector2(35, 460), Vector2(w-70, 80), false, HORIZONTAL_ALIGNMENT_CENTER)
	_place("result_score", Vector2(35, 553), Vector2(w-70, 40), false, HORIZONTAL_ALIGNMENT_CENTER)
	_place("best", Vector2(35, 605), Vector2(w-70, 35), false, HORIZONTAL_ALIGNMENT_CENTER)
	_place("resume", Vector2(72, 530), Vector2(w-144, 78), true)
	_place("restart", Vector2(72, 710), Vector2(w-144, 78), true)
	_place("home", Vector2(72, 809), Vector2(w-144, 66), true)
	_place("back", Vector2(72, 915), Vector2(w-144, 66), true)
	_place("credits",Vector2(72,842),Vector2(w-144,50),true)
	credits.position = Vector2(62,395)
	credits.size = Vector2(w-124,490)
	var index := 0
	for setting in settings:
		_place(setting, Vector2(72, 470+index*92), Vector2(w-144, 70), true)
		index += 1


func set_mode(value: String) -> void:
	mode = value
	refresh()


func refresh() -> void:
	if labels.is_empty():
		return
	for button in buttons.values():
		button.visible = false
	for label in labels.values():
		label.visible = false
	credits.visible = false
	labels["version"].visible = mode != "game"
	match mode:
		"menu":
			for key in ["brand", "title", "eyebrow", "hero", "description", "help"]:
				labels[key].visible = true
			for key in ["start", "settings", "knight", "gargoyle", "witch"]:
				buttons[key].visible = true
			labels["hero"].text = "THE " + selected.to_upper()
			labels["description"].text = {"knight":"STEEL, RESOLVE & RELENTLESS MOMENTUM", "gargoyle":"STONE, SKY & UNBROKEN INSTINCT", "witch":"ARCANA, PRECISION & FRACTURED SPACE"}[selected]
			for kind in NAMES:
				var active: bool = kind == selected
				buttons[kind].modulate = Color.WHITE
				buttons[kind].add_theme_color_override("font_color",GOLD if active else IVORY)
				var selection_style: StyleBoxFlat = buttons[kind].get_theme_stylebox("normal").duplicate()
				selection_style.bg_color = Color("202938") if active else Color(INK,0.85)
				selection_style.border_color = GOLD if active else Color("556071")
				selection_style.set_border_width_all(2 if active else 1)
				buttons[kind].add_theme_stylebox_override("normal",selection_style)
		"game":
			for key in ["distance", "distance_unit", "district", "score"]:
				labels[key].visible = true
			for key in ["pause", "attack", "power"]:
				buttons[key].visible = true
		"pause":
			labels["overlay_title"].text = "PAUSED"
			labels["overlay_detail"].text = "THE CITY CAN WAIT A MOMENT."
			for key in ["overlay_title", "overlay_detail"]:
				labels[key].visible = true
			for key in ["resume", "restart", "home", "settings"]:
				buttons[key].visible = true
		"results":
			labels["overlay_title"].text = "THE RUN ENDS"
			labels["overlay_detail"].text = "THE TEAM RETURNS. THE CITY REMAINS."
			labels["result_distance"].text = "%d m" % int(end_distance)
			labels["result_score"].text = "%d SCORE   /   %d RELIC SHARDS" % [end_score, shard_count]
			labels["best"].text = "PERSONAL BEST  /  %d METRES" % int(best)
			for key in ["overlay_title", "overlay_detail", "result_distance", "result_score", "best"]:
				labels[key].visible = true
			for key in ["restart", "home"]:
				buttons[key].visible = true
		"settings":
			labels["overlay_title"].text = "SETTINGS"
			labels["overlay_detail"].text = "SHAPE YOUR EXPERIENCE."
			labels["overlay_title"].visible = true
			labels["overlay_detail"].visible = true
			buttons["back"].visible = true
			buttons["credits"].visible = true
			for setting in settings:
				buttons[setting].visible = true
				buttons[setting].text = setting.to_upper() + "  /  " + (("HIGH" if settings[setting] else "BATTERY") if setting == "quality" else ("ON" if settings[setting] else "OFF"))
		"credits":
			labels["overlay_title"].text = "CREDITS"
			labels["overlay_detail"].text = "CRAFTED BY LAMONT LABS."
			labels["overlay_title"].visible = true
			labels["overlay_detail"].visible = true
			credits.visible = true
			buttons["back"].visible = true
	queue_redraw()


func update_session(data: Dictionary, shards: int) -> void:
	session = data
	shard_count = shards
	if mode != "game":
		return
	labels["distance"].text = str(int(data["distance_mm"]) / 1000)
	labels["district"].text = {"knight":"CATHEDRAL CAUSEWAY", "gargoyle":"THE UPPER SPIRES", "witch":"THE FRACTURED VEIL"}[data["character"]]
	labels["score"].text = "%d SCORE   /   %d SHARDS" % [int(data["score"]), shards]
	var remaining: int = data["cooldowns"][data["character"]]
	var protected: bool = data["phase"] in ["handoff", "recovery"]
	buttons["power"].disabled = remaining > 0 or protected or data["phase"] == "committed"
	action_glyphs["power"].remaining = remaining/60.0
	action_glyphs["power"].hero = data["character"]
	action_glyphs["power"].queue_redraw()
	buttons["attack"].disabled = protected
	labels["route_title"].visible = route_visible and not protected
	queue_redraw()


func message(text: String, duration: float = 1.8) -> void:
	labels["message"].text = text
	message_time = duration
	labels["message"].visible = true


func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
		labels["message"].modulate.a = minf(1.0, message_time * 3.0)
		labels["message"].visible = message_time > 0.0 and mode == "game"
	if flash > 0.0:
		flash = maxf(0.0, flash-delta*2.0)
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _draw() -> void:
	if menu_gradient == null:
		return
	draw_texture_rect(menu_gradient if mode == "menu" else game_gradient, Rect2(Vector2.ZERO, size), false)
	if mode in ["pause", "settings", "results", "credits"]:
		draw_rect(Rect2(Vector2.ZERO, size), Color(INK, 0.89))
		draw_line(Vector2(72, 420), Vector2(size.x-72, 420), Color(GOLD, 0.45), 1)
	if mode == "menu":
		draw_line(Vector2(42, 104), Vector2(135, 104), GOLD, 2)
		draw_line(Vector2(42, size.y-350), Vector2(size.x-42, size.y-350), Color(GOLD, 0.4), 1)
	if mode == "game":
		for index in range(3):
			var center := Vector2(49 + index * 29, 111)
			var points := PackedVector2Array([center+Vector2(0,-8),center+Vector2(7,0),center+Vector2(0,8),center+Vector2(-7,0)])
			draw_colored_polygon(points, GOLD if index < int(session.get("health",3)) else Color("30394a"))
		if route_visible and str(session.get("phase", "")) not in ["handoff", "recovery"]:
			var width := (size.x-64)/3
			for index in range(3):
				var rect := Rect2(30+index*(width+2), 275, width, 51)
				draw_rect(rect, Color(INK, 0.88))
				if index == route_lane:
					draw_line(rect.position+Vector2(8,49),rect.position+Vector2(width-8,49),GOLD,2)
				var text: String = ["GARGOYLE", "KNIGHT", "WITCH"][index]
				draw_string(ui_font, Vector2(rect.position.x+width*0.5-ui_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x*0.5,307), text, HORIZONTAL_ALIGNMENT_LEFT,-1,16,IVORY)
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.65,0.16,0.12,flash*0.21))
