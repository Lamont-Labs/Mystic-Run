extends SceneTree

const World = preload("res://game/world.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var world := World.new()
	root.add_child(world)
	world.configure()
	await process_frame

	_check(is_instance_valid(world.horizon_plate),
		"The distant painted backdrop remains a non-colliding presentation layer")
	_check(world.horizon_material.albedo_texture.resource_path.ends_with("knight_backdrop.jpg"),
		"The Knight theme starts with its own painted backdrop")
	_check(world.chunks.size() == 11,
		"Theme artwork keeps the existing bounded track-piece pool")

	for character in ["gargoyle", "witch", "knight"]:
		world.set_theme(character)
		var expected: String = character + "_backdrop.jpg"
		_check(world.horizon_material.albedo_texture.resource_path.ends_with(expected),
			character + " theme selects its matching generated backdrop")
		_check(world.chunks.size() == 11,
			character + " backdrop changes do not rebuild gameplay track chunks")

	if failures.is_empty():
		print("PREMIUM_2D_ENVIRONMENT_PASS checks=", checks)
		quit(0)
	else:
		printerr("PREMIUM_2D_ENVIRONMENT_FAIL checks=", checks, " failures=", failures)
		quit(1)
