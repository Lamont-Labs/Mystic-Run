extends SceneTree
## Render-only setup: grants temporary mastery in memory; never writes owner saves.
const Secrets=preload("res://core/secret_catalog.gd")
var game:Node
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var hero:String="knight";var level:String="citadel";var length:int=150;var screen:String="secret"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--character="):hero=argument.get_slice("=",1)
		elif argument.begins_with("--level="):level=argument.get_slice("=",1)
		elif argument.begins_with("--preview-frames="):length=int(argument.get_slice("=",1))
		elif argument.begins_with("--screen="):screen=argument.get_slice("=",1)
	game=load("res://scenes/main.tscn").instantiate();game.testing=true
	game.profile.settings.control_mode="thumb";game.profile.practice_complete=true
	root.add_child(game)
	for i in range(4):await physics_frame
	game._select_character(hero);game.course_id=level;game._start_run();game.countdown_left=.001
	for i in range(4):await physics_frame
	if screen=="secret":
		game.progression.mastery[hero]=60
		if not game._enter_secret(Secrets.gate(level,hero)):quit(1);return
	game.qa_use_specials=false
	for i in range(length):
		game._qa_control()
		if i==45:game._power()
		if i==40:await game._capture("%s-%s-%s"%[screen,level,hero])
		await process_frame
	var valid:bool=game.selected==hero and game.core.active_character==hero and game.heroes[hero].visible and (screen!="secret" or game.secret_state.get("id","")==level+"/"+hero)
	print("RENDER_PREVIEW ",JSON.stringify({"screen":screen,"hero":hero,"level":level,"frames":length,"distance_m":game.distance,"damage":game.run_damage,"character_and_room_verified":valid,"scope":"Actual desktop game render; temporary in-memory unlock for secret preview; no phone performance claim."}))
	game._quit_gracefully(0 if valid else 1)
