extends RefCounted
## Static authoring checks. Passing this does not prove a route is traversable
## in 3D: collider sweeps and physical-device playtests are separate gates.

const CHARACTERS := ["knight", "gargoyle", "witch"]
const NUMERIC_KEYS := ["preview_m", "safe_corridor_m", "first_encounter_m", "max_speed_mps", "handoff_s", "recovery_s"]


static func validate(route: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if str(route.get("id", "")).is_empty():
		errors.append("Route id is required.")
	if not CHARACTERS.has(str(route.get("target", ""))):
		errors.append("Target must belong to the three-character roster.")
	for key in NUMERIC_KEYS:
		var value = route.get(key)
		if not (value is int or value is float):
			errors.append("Numeric field required: " + key)
		elif not is_finite(float(value)) or float(value) <= 0.0:
			errors.append("Positive finite value required: " + key)
	if not errors.is_empty():
		return errors
	var speed := float(route["max_speed_mps"])
	var preview := float(route["preview_m"])
	var corridor := float(route["safe_corridor_m"])
	var first_encounter := float(route["first_encounter_m"])
	var safe_seconds := float(route["handoff_s"]) + float(route["recovery_s"])
	if preview / speed < 1.8:
		errors.append("Route preview provides less than 1.8 seconds at maximum speed.")
	if corridor / speed < safe_seconds:
		errors.append("Safe corridor ends before handoff and recovery finish.")
	if first_encounter < corridor + speed * 1.8:
		errors.append("First encounter lacks 1.8 seconds of warning after the safe corridor.")
	if route.get("ability_optional") != true:
		errors.append("Route needs a baseline bypass when the incoming power is cooling down.")
	return errors
