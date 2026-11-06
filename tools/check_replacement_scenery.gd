extends SceneTree

func _initialize() -> void:
    var path := "res://game/asset_districts.gd"
    var source: Script = load(path)
    if source == null:
        push_error("Scenery script failed to load")
        quit(1)
        return
    var node: Node3D = source.new()
    root.add_child(node)
    node.configure()
    var report: Dictionary = node.diagnostics()
    print("MYSTICRUN_REPLACEMENT_SCENERY ", JSON.stringify(report))
    if int(report.get("replacement_models_loaded", 0)) != 2:
        push_error("Expected two replacement GLB models")
        quit(1)
        return
    if int(report.get("replacement_instances", 0)) < 2:
        push_error("Expected instantiated replacement scenery")
        quit(1)
        return
    if int(report.get("collision_bodies", -1)) != 0:
        push_error("Replacement scenery must not affect gameplay collisions")
        quit(1)
        return
    quit(0)
