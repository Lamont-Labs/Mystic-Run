extends SceneTree

const HERO = preload("res://game/hero.gd")

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
	for kind in ["knight", "gargoyle", "witch"]:
		var actor = HERO.new()
		actor.configure(kind)
		root.add_child(actor)
		await process_frame

		_check(actor.concept_sprite.visible, kind + " concept sprite is visible")
		_check(not actor.authored_mesh.is_visible_in_tree(),
			kind + " 3D render stays hidden without removing its rig")
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_front.png"),
			kind + " starts on the front concept view")

		actor.facing = PI
		actor.animate(0.0)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_rear.png"),
			kind + " switches to the rear concept view in gameplay orientation")
		actor.facing = 0.0
		actor.animate(0.0)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_front.png"),
			kind + " returns to the front concept view")

		actor.moving = true
		actor.animate(0.13)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_run_1_front.png"),
			kind + " shows the first running pose through gameplay animation")
		actor.animate(0.14)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_run_0_front.png"),
			kind + " alternates the running pose through gameplay animation")
		actor.moving = false
		actor.airborne = true
		actor.animate(0.0)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_jump_front.png"),
			kind + " shows a distinct jump pose while airborne")
		actor.airborne = false
		actor.sliding = true
		actor.animate(0.0)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_slide_front.png"),
			kind + " shows a distinct slide pose")
		_check(is_equal_approx(actor.concept_sprite.scale.y, 0.72),
			kind + " lowers its illustrated silhouette while sliding")
		actor.sliding = false
		actor.attack()
		actor.animate(0.05)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_attack_front.png"),
			kind + " shows a distinct attack pose")
		actor.attack_time = 0.0
		actor.facing = PI
		actor.moving = true
		actor.animate(0.0)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_run_0_rear.png")
			or actor.concept_sprite.texture.resource_path.ends_with(kind + "_run_1_rear.png"),
			kind + " keeps the rear-facing action artwork in gameplay orientation")
		actor.moving = false
		actor.airborne = true
		actor.animate(0.0)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_jump_rear.png"),
			kind + " has a rear-facing jump pose")
		actor.airborne = false
		actor.sliding = true
		actor.animate(0.0)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_slide_rear.png"),
			kind + " has a rear-facing slide pose")
		actor.sliding = false
		actor.attack()
		actor.animate(0.05)
		_check(actor.concept_sprite.texture.resource_path.ends_with(kind + "_attack_rear.png"),
			kind + " has a rear-facing attack pose")

		if kind == "knight":
			_check(actor.skeleton.get_bone_count() == 65,
				"Knight retains the full 65-bone gameplay rig")
			_check(actor.authored_mesh.mesh.get_blend_shape_count() == 6,
				"Knight retains all six authored morphs")
			_check(actor.authored_mesh.mesh.get_faces().size() / 3 <= 25000,
				"Knight fallback mesh remains within the triangle budget")
		actor.queue_free()
		await process_frame

	if failures.is_empty():
		print("CONCEPT_SPRITES_PASS checks=", checks)
		quit(0)
	else:
		printerr("CONCEPT_SPRITES_FAIL checks=", checks, " failures=", failures)
		quit(1)
