extends SceneTree
## Read-only Godot import smoke test for staged Batch01 assets.
## Run after importing the 52 verified GLBs into assets/replacement_batch01.
const ROOT := "res://assets/replacement_batch01"
const EXPECTED := {"outfits": 24, "kaykit": 28}

func _initialize() -> void:
    var errors: Array[String] = []
    var counts := {"outfits": 0, "kaykit": 0}
    for category in EXPECTED.keys():
        var folder: String = ROOT + "/" + category
        var dir := DirAccess.open(folder)
        if dir == null:
            errors.append("Missing staged category: " + folder)
            continue
        for filename in dir.get_files():
            if not filename.ends_with(".glb"):
                continue
            counts[category] += 1
            var path: String = folder + "/" + filename
            var resource := ResourceLoader.load(path)
            if not (resource is PackedScene):
                errors.append("GLB failed PackedScene import: " + path)
                continue
            var instance := (resource as PackedScene).instantiate()
            if instance == null:
                errors.append("Cannot instantiate: " + path)
                continue
            if not (instance is Node3D):
                errors.append("Unexpected root type: " + path)
            instance.free()
        if counts[category] != EXPECTED[category]:
            errors.append("Count mismatch %s: expected %d, got %d" % [category, EXPECTED[category], counts[category]])
    if errors.is_empty():
        print("MYSTICRUN_BATCH01_IMPORT_PASS outfits=%d kaykit=%d" % [counts["outfits"], counts["kaykit"]])
        quit(0)
    else:
        for error in errors:
            push_error(error)
        print("MYSTICRUN_BATCH01_IMPORT_FAIL count=%d" % errors.size())
        quit(1)
