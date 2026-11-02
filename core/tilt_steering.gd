extends RefCounted
## Portrait roll controls a continuous lateral position, independent of frame rate.
const LIMIT := 3.65
const DEADZONE := deg_to_rad(1.8)
var neutral: float = 0.0
var filtered: float = 0.0
var available: bool = false
var calibrating: bool = true
var samples: int = 0
var total: float = 0.0
var sensitivity: String = "normal"
var inverted: bool = false
var missing_seconds: float = 0.0

func reset_calibration() -> void:
	calibrating=true; samples=0; total=0.0; filtered=0.0; missing_seconds=0.0

func valid_sample(sample: Vector3) -> bool:
	return sample.is_finite() and sample.length()>4.0 and sample.length()<16.0

func roll(sample: Vector3) -> float:
	return atan2(-sample.x, maxf(Vector2(sample.y,sample.z).length(),0.01))

func calibrate(sample: Vector3) -> void:
	if not valid_sample(sample):return
	total+=roll(sample); samples+=1; neutral=total/samples
	available=true

func finish_calibration() -> void:
	calibrating=false
	available=samples>=6
	filtered=0.0

func update(sample: Vector3, delta: float) -> float:
	if not valid_sample(sample):
		missing_seconds+=delta
		if missing_seconds>0.65:available=false
		filtered=lerpf(filtered,0.0,1.0-exp(-delta*8.0))
		return filtered*LIMIT
	missing_seconds=0.0
	available=true
	# A late sensor can calibrate safely after launch rather than using zero bias.
	if samples<6:
		calibrate(sample)
		return 0.0
	var angle: float=(roll(sample)-neutral)*(-1.0 if inverted else 1.0)
	var full_scale: float=deg_to_rad({"low":28.0,"normal":22.0,"high":16.0}.get(sensitivity,22.0))
	var magnitude: float=clampf((absf(angle)-DEADZONE)/(full_scale-DEADZONE),0.0,1.0)
	var target: float=signf(angle)*magnitude
	filtered=lerpf(filtered,target,1.0-exp(-delta*13.0))
	return filtered*LIMIT
