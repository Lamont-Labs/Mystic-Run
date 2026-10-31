extends SceneTree

var failures: Array[String] = []
var checks: int = 0


func _init() -> void:
	call_deferred("_run")


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)


func frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.ui.mode == "menu","Application enters character menu")
	for character in ["knight","gargoyle","witch"]:
		game.ui.buttons[character].pressed.emit()
		check(game.selected == character,"Character button selects "+character)
		check(game.heroes[character].visible,"Selected rig is visible: "+character)
		game.ui.buttons["start"].pressed.emit()
		await frames(4)
		check(game.ui.mode == "game" and game.core.active_character == character,"Start button enters selected character run")
		game._jump()
		await frames(12)
		check(game.motor.position.y > 0.7,"Grounded jump produces a real upward trajectory: "+character)
		await frames(46)
		check(game.motor.position.y < 0.1,"Jump returns to playable ground: "+character)
		game._slide()
		check(game.sliding_left > 0.0,"Slide input accepted on ground: "+character)
		game._intent("home")
		await process_frame
		check(not game.heroes[character].sliding,"Returning to menu clears slide pose")

	game._intent("character","witch")
	game._intent("start")
	await frames(4)
	game.touches[7] = {"start":Vector2(20,20),"used":false}
	game.ui.buttons["pause"].pressed.emit()
	check(game.ui.mode == "pause" and game.core.phase == "paused","Pause button suspends game session")
	check(game.touches.is_empty(),"Pause cancels held touch ownership")
	var frozen: Dictionary = game.core.snapshot()
	await frames(8)
	check(game.core.snapshot() == frozen,"Paused scene does not advance gameplay state")
	game.ui.buttons["settings"].pressed.emit()
	check(game.ui.mode == "settings","Pause opens settings")
	var music_before: bool = game.profile["settings"]["music"]
	game.ui.buttons["music"].pressed.emit()
	check(game.profile["settings"]["music"] != music_before,"Music setting changes")
	game.ui.buttons["music"].pressed.emit()
	game.ui.buttons["credits"].pressed.emit()
	check(game.ui.mode == "credits","Credits screen opens")
	game.ui.buttons["back"].pressed.emit()
	check(game.ui.mode == "settings","Credits returns to settings")
	game.ui.buttons["back"].pressed.emit()
	check(game.ui.mode == "pause","Settings returns to its original pause screen")
	game.ui.buttons["resume"].pressed.emit()
	await frames(2)
	check(game.ui.mode == "game" and game.core.phase == "running","Resume restores play")
	game.ui.buttons["attack"].pressed.emit()
	check(game.attack_token > 0,"Combat button creates an accepted attack")
	var initial_lane: int = game.lane
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.pressed = true
	touch.position = Vector2(100,700)
	game._unhandled_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = Vector2(200,700)
	game._unhandled_input(drag)
	check(game.lane == mini(2,initial_lane+1),"Touch drag changes lane")
	drag.position = Vector2(350,700)
	game._unhandled_input(drag)
	check(game.lane == mini(2,initial_lane+1),"One drag does not repeat its lane intent")
	game.touches.clear()
	game.core.offer_route("interaction-test","gargoyle",108)
	game.core.commit_route("interaction-test")
	var committed_lane: int = game.lane
	game._move_lane(-1)
	check(game.lane == committed_lane,"Committed route prevents late steering into another branch")
	game._intent("restart")
	await frames(4)
	game.core.receive_damage(3)
	await frames(2)
	check(game.ui.mode == "results","Lethal damage reaches result screen")
	game.ui.buttons["restart"].pressed.emit()
	await frames(2)
	check(game.core.health == 3 and game.ui.mode == "game","Restart creates a fresh playable run")
	var report := {"checks":checks,"failures":failures,"failed":failures.size(),"scope":"Scene/physics/UI signal and gesture handling on desktop headless; not a phone touch-latency test"}
	var file := FileAccess.open("res://tests/evidence/scene-interactions.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("INTERACTION_QA "+JSON.stringify(report))
	game._stop_audio()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
