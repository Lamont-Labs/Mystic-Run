extends SceneTree

const Core = preload("res://core/run_core.gd")
const Contract = preload("res://core/route_contract.gd")

var checks: int = 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _new_run(character: String = "knight"):
	var core = Core.new()
	_check(core.start(character, 413), "Valid starting character accepted: " + character)
	return core


func _swap(core, target: String) -> void:
	_check(core.offer_route("test-route-" + str(core.tick), target, 108), "Offer valid route")
	var route_id := str(core.route["id"])
	_check(core.commit_route(route_id), "Commit offered route")
	core.step(108 + Core.HANDOFF_TICKS + Core.RECOVERY_TICKS)
	_check(core.phase == "running" and core.active_character == target, "Handoff reaches running state: " + target)


func _run() -> void:
	var invalid = Core.new()
	_check(not invalid.start("wraith"), "Unselected roster member rejected")
	_check(invalid.phase == "ready", "Invalid start leaves session ready")
	for character in Core.CHARACTERS:
		var core = _new_run(character)
		_check(not core.start(character), "Start cannot reset an active run")
		core.step(60)
		_check(core.distance_mm == 14000, "Fixed-tick distance equals 14 metres per second")

	var preserving = _new_run()
	_check(preserving.receive_damage(), "Initial combat damage accepted")
	var enemy: int = preserving.register_enemy(125)
	var strike: int = preserving.attack()
	_check(preserving.resolve_enemy(enemy, strike), "Registered enemy and valid attack produce reward")
	_check(not preserving.resolve_enemy(enemy, strike), "Duplicate kill callback cannot reward twice")
	var before_distance: int = preserving.distance_mm
	_swap(preserving, "gargoyle")
	_check(preserving.health == 2 and preserving.score == 125, "Handoff preserves team health and score")
	_check(preserving.distance_mm > before_distance, "Forward progress continues during handoff")
	_check(preserving.handoff_epoch == 1, "One handoff produces one ownership epoch")

	var protected = _new_run()
	_check(protected.offer_route("roof", "gargoyle", 108), "Offer roof route")
	_check(not protected.offer_route("rift", "witch", 108), "A second offer cannot replace an active route")
	_check(not protected.commit_route("wrong"), "Wrong route id rejected")
	_check(protected.commit_route("roof"), "Correct route id accepted")
	_check(not protected.commit_route("roof"), "Route cannot commit twice")
	protected.step(108)
	_check(protected.phase == "handoff", "Ownership handoff starts at commit boundary")
	_check(protected.active_character == "knight", "Incoming character waits for ownership boundary")
	_check(not protected.receive_damage(), "Handoff rejects damage")
	_check(protected.attack() == -1 and not protected.use_power(), "Handoff rejects combat actions")
	protected.step(Core.HANDOFF_TICKS)
	_check(protected.phase == "recovery" and protected.active_character == "gargoyle", "Ownership moves atomically into recovery")
	_check(not protected.receive_damage(), "Recovery rejects damage")
	_check(protected.attack() == -1 and not protected.use_power(), "Recovery rejects combat actions")
	protected.step(Core.RECOVERY_TICKS)
	_check(protected.attack() > 0, "Combat becomes available after recovery")

	var cooldown = _new_run()
	_check(cooldown.use_power(), "First knight power accepted")
	_check(not cooldown.use_power(), "Power cannot be used repeatedly while recharging")
	_swap(cooldown, "witch")
	_swap(cooldown, "knight")
	_check(cooldown.power_remaining("knight") == 84, "Leaving and returning does not refill a power")
	_check(not cooldown.use_power(), "Returning knight still respects original cooldown")
	cooldown.step(84)
	_check(cooldown.use_power(), "Power becomes available exactly at cooldown boundary")

	var same = _new_run()
	_check(same.use_power(), "Activate power before same-character branch")
	_check(same.offer_route("ground", "knight", 108), "Same-character route accepted")
	_check(same.commit_route("ground"), "Same-character route commits")
	same.step(108)
	_check(same.phase == "running" and same.handoff_epoch == 0, "Same-character route causes no handoff or extra immunity")
	_check(same.power_remaining("knight") == 372, "Same-character route preserves elapsed cooldown")

	var passed = _new_run("witch")
	_check(passed.offer_route("roof", "gargoyle", 108), "Optional route can be offered")
	passed.step(108)
	_check(passed.active_character == "witch" and passed.phase == "running", "Ignoring optional branch retains active character")
	_check(not passed.offer_route("", "knight", 108), "Empty route id rejected")
	_check(not passed.offer_route("bad", "wraith", 108), "Invalid route character rejected")
	_check(not passed.offer_route("short", "knight", 107), "Insufficient preview rejected")

	var pause_case = _new_run()
	_check(pause_case.use_power(), "Power starts before pause")
	_check(pause_case.offer_route("rift", "witch", 108), "Offer before pause")
	_check(pause_case.commit_route("rift"), "Commit before pause")
	pause_case.step(108)
	_check(pause_case.pause(), "Pause allowed during handoff")
	var paused_snapshot: Dictionary = pause_case.snapshot()
	pause_case.step(600)
	_check(pause_case.snapshot() == paused_snapshot, "Pause freezes distance, timers, health and cooldowns")
	_check(not pause_case.pause(), "Duplicate pause rejected")
	_check(pause_case.resume(), "Resume restores interrupted phase")
	_check(pause_case.phase == "handoff", "Resume retains handoff phase")
	pause_case.step(Core.HANDOFF_TICKS + Core.RECOVERY_TICKS)
	_check(pause_case.active_character == "witch" and pause_case.handoff_epoch == 1, "Interrupted handoff completes exactly once")

	var stale = _new_run()
	var old_enemy: int = stale.register_enemy()
	var old_attack: int = stale.attack()
	_swap(stale, "witch")
	_check(not stale.resolve_enemy(old_enemy, old_attack), "Outgoing character callbacks cannot reward after handoff")
	_check(stale.snapshot()["live_enemies"] == 0, "Handoff retires outgoing combat registrations")
	var expired_enemy: int = stale.register_enemy()
	var expired_attack: int = stale.attack()
	stale.step(Core.HIT_WINDOW_TICKS + 1)
	_check(not stale.resolve_enemy(expired_enemy, expired_attack), "Expired attack token rejected")
	stale.retire_enemy(expired_enemy)
	_check(stale.snapshot()["live_enemies"] == 0, "Recycling retires enemy registration")

	var damage = _new_run()
	_check(damage.receive_damage(), "First damage changes health")
	_check(not damage.receive_damage(), "Repeated overlap within grace window is harmless")
	damage.step(Core.DAMAGE_GRACE_TICKS)
	_check(damage.receive_damage(), "Damage accepted after grace expires")
	damage.step(Core.DAMAGE_GRACE_TICKS)
	_check(damage.receive_damage(), "Lethal damage accepted")
	_check(damage.phase == "failed" and damage.health == 0, "Lethal damage enters failed state")
	var failed_snapshot: Dictionary = damage.snapshot()
	damage.step(600)
	_check(damage.snapshot() == failed_snapshot, "Failure stops simulation progress")
	_check(damage.attack() == -1 and not damage.use_power(), "Failed runs reject combat")
	_check(not damage.resume(), "Failed run cannot resume as paused")

	var file := FileAccess.open("res://content/handoff_routes.json", FileAccess.READ)
	_check(file != null, "Route content is readable")
	var content: Dictionary = JSON.parse_string(file.get_as_text())
	var route_ids := {}
	for item in content["routes"]:
		_check(Contract.validate(item).is_empty(), "Authored route passes static contract: " + str(item["id"]))
		_check(not route_ids.has(item["id"]), "Route ids are unique")
		route_ids[item["id"]] = true
		_check(roundi(float(item["handoff_s"]) * Core.HZ) == Core.HANDOFF_TICKS, "Content handoff timing matches runtime")
		_check(roundi(float(item["recovery_s"]) * Core.HZ) == Core.RECOVERY_TICKS, "Content recovery timing matches runtime")
	var bad: Dictionary = content["routes"][0].duplicate(true)
	bad["preview_m"] = 1
	_check(not Contract.validate(bad).is_empty(), "Too-short visual preview rejected")
	bad = content["routes"][0].duplicate(true)
	bad["safe_corridor_m"] = 1
	_check(not Contract.validate(bad).is_empty(), "Unsafe handoff corridor rejected")
	bad = content["routes"][0].duplicate(true)
	bad["first_encounter_m"] = 33
	_check(not Contract.validate(bad).is_empty(), "Surprise encounter after handoff rejected")
	bad = content["routes"][0].duplicate(true)
	bad["ability_optional"] = false
	_check(not Contract.validate(bad).is_empty(), "Mandatory cooling-down ability rejected")
	bad = content["routes"][0].duplicate(true)
	bad["max_speed_mps"] = NAN
	_check(not Contract.validate(bad).is_empty(), "Non-finite content parameter rejected")

	# Exercise every source/target pair, not just the preferred narrative order.
	for source in Core.CHARACTERS:
		for target in Core.CHARACTERS:
			var pair = _new_run(source)
			_swap(pair, target)
			var expected_epoch: int = 0 if source == target else 1
			_check(pair.handoff_epoch == expected_epoch, "Pair ownership: " + source + " -> " + target)

	# Fixed-step batching must produce the same logical result.
	var batched = _new_run()
	var single = _new_run()
	batched.step(10000)
	for _index in range(10000):
		single.step()
	_check(batched.snapshot() == single.snapshot(), "Fixed-step results match across call batching")
	_check(batched.distance_mm == 2333333, "Integer remainder preserves long-run distance")

	var bounded = _new_run()
	var choice = _new_run()
	_check(choice.offer_route("choice","knight",108),"Offer multi-destination branch")
	_check(choice.select_route_target("choice","witch"),"Route destination may change before commitment")
	_check(choice.route["target"] == "witch","Selected route target retained")
	_check(choice.commit_route("choice"),"Commit selected destination")
	_check(not choice.select_route_target("choice","gargoyle"),"Committed route destination is immutable")
	var pickup = _new_run()
	var collectible: int = pickup.register_collectible(25)
	_check(pickup.collect(collectible) and pickup.score == 25,"Pickup reward accepted once")
	_check(not pickup.collect(collectible) and pickup.score == 25,"Duplicate pickup cannot reward again")
	var retired: int = pickup.register_collectible(25)
	pickup.retire_collectible(retired)
	_check(not pickup.collect(retired),"Retired pickup cannot award")
	var power_hit = _new_run()
	var charge_enemy: int = power_hit.register_enemy(100)
	var basic_token: int = power_hit.attack()
	_check(power_hit.use_power(),"Power can start while a basic attack is recovering")
	_check(power_hit.power_attack_token != basic_token,"Power receives its own attack identity")
	_check(power_hit.resolve_enemy(charge_enemy,power_hit.power_attack_token),"Charge attack remains valid independently of basic recovery")
	power_hit.step(Core.HZ+1)
	var late_enemy: int = power_hit.register_enemy(100)
	_check(not power_hit.resolve_enemy(late_enemy,power_hit.power_attack_token),"Power attack window expires")
	for _index in range(700):
		bounded.pause()
		bounded.resume()
	_check(bounded.events.size() == Core.EVENT_CAPACITY, "Diagnostic ring remains bounded during long runs")
	for _index in range(Core.MAX_LIVE_ENEMIES):
		_check(bounded.register_enemy() > 0, "Live encounter registration within pool budget")
	_check(bounded.register_enemy() == -1, "Encounter pool cannot grow without bound")

	var report := {"checks": checks, "failed": failures.size(), "failures": failures, "engine": Engine.get_version_info()["string"]}
	var output := FileAccess.open("res://tests/results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  ") + "\n")
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
