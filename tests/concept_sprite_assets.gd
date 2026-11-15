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

func _check_floor_alignment(actor: Node, kind: String, pose: String) -> void:
	var image: Image = actor.concept_sprite.texture.get_image()
	var content_bottom: float = float(image.get_used_rect().end.y) / float(image.get_height())
	var bottom_y: float = actor.concept_sprite.position.y \
		- (content_bottom - .5) * actor.concept_sprite_height * actor.concept_sprite.scale.y
	_check(absf(bottom_y) < .002, kind + " " + pose + " artwork aligns with the track")


func _run() -> void:
	var expected_action_counts:Dictionary={"knight":14,"gargoyle":14,"witch":14}
	for kind in ["knight", "gargoyle", "witch"]:
		var actor = HERO.new()
		actor.configure(kind)
		root.add_child(actor)
		await process_frame

		_check(actor.concept_sprite.visible, kind + " concept sprite is visible")
		_check(not actor.authored_mesh.is_visible_in_tree(),
			kind + " 3D render stays hidden without removing its rig")
		_check(actor.concept_atlas.resource_path.ends_with(kind + "_atlas.png"),
			kind + " loads its compact approved-concept atlas")
		_check(actor.concept_action_atlas != null,
			kind + " loads the source-conditioned rear-run atlas")
		_check(actor.concept_action_textures.size() == expected_action_counts[kind],
			kind + " loads its approved-source action frames")
		_check(actor.concept_action_textures.has("jump_rear")
			and actor.concept_action_textures.has("fall_rear")
			and actor.concept_action_textures.has("land_rear")
			and actor.concept_action_textures.has("slide_rear")
			and actor.concept_action_textures.has("dodge_rear")
			and actor.concept_action_textures.has("dodge_right_rear")
			and actor.concept_action_textures.has("attack_rear")
			and actor.concept_action_textures.has("block_rear")
			and actor.concept_action_textures.has("damage_rear")
			and actor.concept_action_textures.has("special_rear")
			and actor.concept_action_textures.has("victory_rear")
			and actor.concept_action_textures.has("defeat_rear"),
			kind + " has rear-view movement, combat, recovery and celebration poses")
		_check(actor.concept_view == "front",
			kind + " starts on the front concept view")
		_check_floor_alignment(actor, kind, "front view")

		actor.facing = PI
		actor.animate(0.0)
		_check(actor.concept_view == "rear",
			kind + " switches to the rear concept view in gameplay orientation")
		_check_floor_alignment(actor, kind, "rear view")
		actor.facing = 0.0
		actor.animate(0.0)
		_check(actor.concept_view == "front",
			kind + " returns to the front concept view")

		actor.moving = true
		actor.animate(0.13)
		_check(actor.concept_view == "front",
			kind + " keeps the original concept front while running")
		_check_floor_alignment(actor, kind, "running")
		actor.animate(0.14)
		_check(actor.concept_view == "front",
			kind + " keeps the original concept front during the run cycle")
		actor.moving = false
		actor.airborne = true
		actor.animate(0.0)
		_check(actor.concept_view == "front",
			kind + " keeps the original concept front while airborne")
		_check_floor_alignment(actor, kind, "airborne")
		actor.airborne = false
		actor.sliding = true
		actor.animate(0.0)
		_check(actor.concept_view == "front",
			kind + " keeps the original concept front while sliding")
		_check(is_equal_approx(actor.concept_sprite.scale.x, actor.concept_sprite.scale.y),
			kind + " preserves concept-art proportions while sliding")
		_check_floor_alignment(actor, kind, "sliding")
		actor.sliding = false

		actor.airborne = true
		actor.animate(0.0)
		actor.airborne = false
		actor.animate(0.0)
		actor.animate(0.01)
		_check(actor.concept_view == "front",
			kind + " keeps the original concept front after landing")

		actor.attack()
		actor.animate(0.05)
		_check(actor.concept_view == "front",
			kind + " keeps the original concept front while attacking")
		_check_floor_alignment(actor, kind, "attacking")
		actor.attack_time = 0.0
		actor.power()
		_check(is_equal_approx(actor.power_time, 0.7),
			kind + " keeps the existing special-power timing")
		actor.animate(0.05)
		_check(actor.concept_view == "front",
			kind + " keeps the original concept front during special power")
		actor.power_time = 0.0
		actor.facing = PI
		actor.moving = true
		actor.landing_spring = 0.0
		actor.clock = 0.0
		actor.animate(0.0)
		_check(actor.concept_view == "rear",
			kind + " keeps the original concept rear while running")
		_check_floor_alignment(actor, kind, "rear running")
		var first_run_frame:Texture2D=actor.concept_sprite.texture
		_check(actor.concept_action_textures.values().has(first_run_frame),
			kind + " uses a generated run-cycle frame when running away")
		actor.animate(.5)
		_check(actor.motion_art.gait>0 and actor.motion_art.stride_weight>.9,
			kind + " continuous cutout joints animate instead of swapping two static strides")
		_check_floor_alignment(actor, kind, "rear run-cycle frame")
		actor.moving = false
		actor.animate(0.0)
		_check(actor.concept_sprite.texture == actor.concept_textures["rear"],
			kind + " returns to the exact rear concept cutout when idle")
		actor.airborne = true
		actor.airborne_velocity = 2.0
		actor.animate(0.0)
		_check(actor.concept_view == "rear",
			kind + " keeps the original concept rear while airborne")
		_check(actor.concept_sprite.texture == actor.concept_action_textures["jump_rear"],
			kind + " uses the concept-matched rear jump pose")
		_check_floor_alignment(actor, kind, "rear airborne")
		actor.airborne_velocity = -2.0
		actor.animate(0.0)
		_check(actor.concept_sprite.texture == actor.concept_action_textures["fall_rear"],
			kind + " uses a separate rear fall pose")
		actor.airborne_velocity = 0.0
		actor.airborne = false
		actor.landing_spring = 0.2
		actor.animate(0.0)
		_check(actor.concept_sprite.texture == actor.concept_action_textures["land_rear"],
			kind + " uses the rear landing recovery pose")
		actor.landing_spring = 0.0
		actor.sliding = true
		actor.animate(0.0)
		_check(actor.concept_view == "rear",
			kind + " keeps the original concept rear while sliding")
		_check(actor.concept_sprite.texture == actor.concept_action_textures["slide_rear"],
			kind + " uses the concept-matched rear slide pose")
		_check_floor_alignment(actor, kind, "rear sliding")
		actor.sliding = false
		actor.attack()
		actor.animate(0.05)
		_check(actor.concept_view == "rear",
			kind + " keeps the original concept rear while attacking")
		_check(actor.concept_sprite.texture == actor.concept_action_textures["attack_rear"],
			kind + " uses the concept-matched rear attack pose")
		_check_floor_alignment(actor, kind, "rear attacking")
		actor.attack_time = 0.0
		actor.hurt_left = 0.2
		actor.animate(0.01)
		_check(actor.concept_sprite.texture == actor.concept_action_textures["damage_rear"],
			kind + " uses the concept-matched rear damage pose")
		actor.hurt_left = 0.0
		actor.power()
		actor.animate(0.05)
		_check(actor.concept_sprite.texture == actor.concept_action_textures["special_rear"],
			kind + " uses the concept-matched rear special pose")
		actor.power_time = 0.0
		actor.blocking = true
		actor.animate(0.0)
		_check(actor.concept_sprite.texture == actor.concept_action_textures["block_rear"],
			kind + " uses the rear block pose when guarded")
		actor.blocking = false
		actor.celebration_left = 0.75
		actor.animate(0.0)
		_check(actor.concept_sprite.texture == actor.concept_action_textures["victory_rear"],
			kind + " uses the rear victory pose while celebrating")
		actor.celebration_left = 0.0
		actor.defeated = true
		actor.animate(0.0)
		_check(actor.concept_sprite.texture == actor.concept_action_textures["defeat_rear"],
			kind + " uses the rear defeat pose when defeated")
		actor.defeated = false
		actor.landing_spring = 0.0
		actor.lean = -0.5
		actor.animate(0.0)
		_check(actor.concept_sprite.texture == actor.concept_action_textures["dodge_rear"],
			kind + " uses the left rear dodge pose")
		actor.lean = 0.5
		actor.animate(0.0)
		_check(actor.concept_sprite.texture == actor.concept_action_textures["dodge_right_rear"],
			kind + " uses the right rear dodge pose")
		actor.lean = 0.0
		actor.airborne = true
		actor.animate(0.0)
		actor.airborne = false
		actor.animate(0.0)
		actor.animate(0.01)
		_check(actor.concept_view == "rear",
			kind + " keeps the original concept rear after landing")
		actor.landing_spring = 0.0
		actor.power()
		actor.animate(0.05)
		_check(actor.concept_view == "rear",
			kind + " keeps the original concept rear during special power")
		_check_floor_alignment(actor, kind, "rear special power")

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
