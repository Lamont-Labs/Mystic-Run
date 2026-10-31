extends RefCounted
## Fixed-tick session rules. Rendering, physics contacts and input recognition
## remain outside this module. Call step() once per simulation tick.

const CHARACTERS := ["knight", "gargoyle", "witch"]
const HZ := 60
const MAX_HEALTH := 3
const SPEED_MM_PER_SECOND := 14000
const HANDOFF_TICKS := 30
const RECOVERY_TICKS := 60
const MIN_PREVIEW_TICKS := 108
const DAMAGE_GRACE_TICKS := 45
const ATTACK_INTERVAL_TICKS := 24
const HIT_WINDOW_TICKS := 24
const MAX_LIVE_ENEMIES := 256
const EVENT_CAPACITY := 512
const POWER_COOLDOWN_TICKS := {"knight": 480, "gargoyle": 420, "witch": 540}

var phase: String = "ready"
var active_character: String = "knight"
var tick: int = 0
var distance_mm: int = 0
var health: int = MAX_HEALTH
var score: int = 0
var handoff_epoch: int = 0
var power_attack_token: int = -1
var seed_value: int = 0
var route: Dictionary = {}
var events: Array[Dictionary] = []

var _paused_phase: String = ""
var _distance_remainder: int = 0
var _phase_deadline: int = 0
var _damage_ready_at: int = 0
var _attack_ready_at: int = 0
var _cooldown_ready_at: Dictionary = {}
var _live_enemies: Dictionary = {}
var _live_attacks: Dictionary = {}
var _next_enemy_id: int = 1
var _next_attack_id: int = 1
var _event_sequence: int = 0
var _collectibles: Dictionary = {}
var _next_collectible_id: int = 1


func start(character: String, run_seed: int = 0) -> bool:
	if phase != "ready" or not CHARACTERS.has(character):
		return false
	active_character = character
	seed_value = run_seed
	for item in CHARACTERS:
		_cooldown_ready_at[item] = 0
	phase = "running"
	_record("run_started", {"character": character, "seed": run_seed})
	return true


func step(count: int = 1) -> void:
	if count <= 0:
		return
	for _index in range(count):
		if phase in ["ready", "paused", "failed"]:
			return
		tick += 1
		_distance_remainder += SPEED_MM_PER_SECOND
		distance_mm += _distance_remainder / HZ
		_distance_remainder %= HZ
		for token in _live_attacks.keys():
			if tick > int(_live_attacks[token]["expires_at"]):
				_live_attacks.erase(token)
		if phase in ["telegraph", "committed"] and tick >= int(route["deadline"]):
			if phase == "committed":
				_begin_handoff()
			else:
				_record("route_passed", {"route_id": route["id"]})
				route = {}
				phase = "running"
		elif phase == "handoff" and tick >= _phase_deadline:
			active_character = str(route["target"])
			handoff_epoch += 1
			phase = "recovery"
			_phase_deadline = tick + RECOVERY_TICKS
			_record("handoff_completed", {"character": active_character, "epoch": handoff_epoch})
		elif phase == "recovery" and tick >= _phase_deadline:
			route = {}
			phase = "running"
			_record("control_restored")


func offer_route(route_id: String, target: String, preview_ticks: int = 144) -> bool:
	if phase != "running" or route_id.is_empty():
		return false
	if not CHARACTERS.has(target) or preview_ticks < MIN_PREVIEW_TICKS:
		return false
	route = {"id": route_id, "target": target, "deadline": tick + preview_ticks}
	phase = "telegraph"
	_record("route_offered", {"route_id": route_id, "target": target})
	return true


func commit_route(route_id: String) -> bool:
	if phase != "telegraph" or str(route.get("id", "")) != route_id:
		return false
	phase = "committed"
	_record("route_committed", {"route_id": route_id})
	return true


func select_route_target(route_id: String, target: String) -> bool:
	if phase != "telegraph" or str(route.get("id", "")) != route_id or not CHARACTERS.has(target):
		return false
	route["target"] = target
	return true


func register_collectible(reward: int = 25) -> int:
	if _collectibles.size() >= 256 or reward < 0:
		return -1
	var token := _next_collectible_id
	_next_collectible_id += 1
	_collectibles[token] = reward
	return token


func collect(token: int) -> bool:
	if not _can_act() or not _collectibles.has(token):
		return false
	score += int(_collectibles[token])
	_collectibles.erase(token)
	return true


func retire_collectible(token: int) -> void:
	_collectibles.erase(token)


func attack() -> int:
	if not _can_act() or tick < _attack_ready_at:
		return -1
	var token := _next_attack_id
	_next_attack_id += 1
	_attack_ready_at = tick + ATTACK_INTERVAL_TICKS
	_live_attacks[token] = {"epoch": handoff_epoch, "expires_at": tick + HIT_WINDOW_TICKS}
	_record("attack_started", {"attack_id": token, "character": active_character})
	return token


func use_power() -> bool:
	if not _can_act() or power_remaining(active_character) > 0:
		return false
	_cooldown_ready_at[active_character] = tick + int(POWER_COOLDOWN_TICKS[active_character])
	power_attack_token = _next_attack_id
	_next_attack_id += 1
	_live_attacks[power_attack_token] = {"epoch":handoff_epoch,"expires_at":tick+HZ}
	_record("power_started", {"character": active_character})
	return true


func power_remaining(character: String) -> int:
	if not CHARACTERS.has(character):
		return -1
	return maxi(0, int(_cooldown_ready_at.get(character, 0)) - tick)


func register_enemy(reward: int = 100) -> int:
	if not _can_act() or reward < 0 or _live_enemies.size() >= MAX_LIVE_ENEMIES:
		return -1
	var token := _next_enemy_id
	_next_enemy_id += 1
	_live_enemies[token] = {"reward": reward, "epoch": handoff_epoch}
	return token


func retire_enemy(enemy_id: int) -> void:
	_live_enemies.erase(enemy_id)


func resolve_enemy(enemy_id: int, attack_id: int) -> bool:
	# The scene's hit resolver must first prove range, lane, line of sight and
	# vulnerability. This checks session identity, timing and reward uniqueness.
	if not _can_act() or not _live_enemies.has(enemy_id) or not _live_attacks.has(attack_id):
		return false
	var enemy: Dictionary = _live_enemies[enemy_id]
	var strike: Dictionary = _live_attacks[attack_id]
	if int(enemy["epoch"]) != handoff_epoch or int(strike["epoch"]) != handoff_epoch:
		return false
	if tick > int(strike["expires_at"]):
		return false
	score += int(enemy["reward"])
	_live_enemies.erase(enemy_id)
	_record("enemy_defeated", {"enemy_id": enemy_id, "attack_id": attack_id})
	return true


func receive_damage(amount: int = 1) -> bool:
	if not _can_act() or amount <= 0 or tick < _damage_ready_at:
		return false
	health = maxi(0, health - amount)
	_damage_ready_at = tick + DAMAGE_GRACE_TICKS
	_record("damage_received", {"amount": amount, "health": health})
	if health == 0:
		fail_run("health_depleted")
	return true


func fail_run(reason: String) -> bool:
	if not _can_act() or reason.is_empty():
		return false
	phase = "failed"
	_live_enemies.clear()
	_live_attacks.clear()
	_record("run_failed", {"reason": reason})
	return true


func pause() -> bool:
	if phase in ["ready", "paused", "failed"]:
		return false
	_paused_phase = phase
	phase = "paused"
	_record("run_paused")
	return true


func resume() -> bool:
	if phase != "paused":
		return false
	phase = _paused_phase
	_paused_phase = ""
	_record("run_resumed")
	return true


func snapshot() -> Dictionary:
	var cooldowns := {}
	for character in CHARACTERS:
		cooldowns[character] = power_remaining(character)
	return {
		"phase": phase, "character": active_character, "tick": tick,
		"distance_mm": distance_mm, "health": health, "score": score,
		"epoch": handoff_epoch, "seed": seed_value, "cooldowns": cooldowns,
		"route": route.duplicate(true), "live_enemies": _live_enemies.size(),
		"live_attacks": _live_attacks.size()
	}


func _can_act() -> bool:
	return phase in ["running", "telegraph", "committed"]


func _begin_handoff() -> void:
	if str(route["target"]) == active_character:
		_record("route_continued", {"route_id": route["id"]})
		route = {}
		phase = "running"
		return
	phase = "handoff"
	_phase_deadline = tick + HANDOFF_TICKS
	_live_enemies.clear()
	_live_attacks.clear()
	_record("handoff_started", {"from": active_character, "to": route["target"]})


func _record(kind: String, data: Dictionary = {}) -> void:
	_event_sequence += 1
	events.append({"sequence": _event_sequence, "tick": tick, "type": kind, "data": data.duplicate(true)})
	if events.size() > EVENT_CAPACITY:
		events.pop_front()
