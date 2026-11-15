extends SceneTree
func _initialize() -> void:
	root.add_child.call_deferred(load("res://experiments/architecture_validation/lab.gd").new())
