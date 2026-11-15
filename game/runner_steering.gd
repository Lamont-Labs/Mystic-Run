extends RefCounted
## Exact critically damped lateral response. Retargeting preserves velocity;
## unlike restarting an ease tween, rapid reversals do not restart from rest.
var velocity:float=0.0

func reset() -> void:velocity=0.0

func advance(position:float,target:float,delta:float,limit:float) -> float:
	if delta<=0:return position
	var omega:float=28.0
	var offset:float=position-target
	var impulse:float=(velocity+omega*offset)*delta
	var decay:float=exp(-omega*delta)
	var next:float=target+(offset+impulse)*decay
	velocity=(velocity-omega*impulse)*decay
	if absf(next)>limit:
		next=clampf(next,-limit,limit);velocity=0.0
	if absf(next-target)<.001 and absf(velocity)<.02:
		next=target;velocity=0
	return next
