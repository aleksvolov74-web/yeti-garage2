extends SceneTree

var errors: Array[String] = []
var checked: Array[String] = []

func scan(path: String) -> void:
    for name in DirAccess.get_files_at(path):
        if not name.ends_with(".gd") and not name.ends_with(".tscn") and not name.ends_with(".tres"):
            continue
        var target := path.path_join(name)
        var resource := load(target)
        if resource == null:
            errors.append("failed resource: " + target)
        elif resource is GDScript and not resource.can_instantiate():
            errors.append("failed script compilation: " + target)
        elif resource is PackedScene:
            var instance: Node = resource.instantiate()
            if instance == null: errors.append("failed scene instance: " + target)
            else: instance.free()
        checked.append(target)
    for name in DirAccess.get_directories_at(path):
        scan(path.path_join(name))

func _initialize() -> void:
    await process_frame
    for directory in ["res://autoload", "res://services", "res://scenes", "res://tools"]:
        scan(directory)
    DirAccess.make_dir_recursive_absolute("res://build")
    var output := FileAccess.open("res://build/project_resources.json", FileAccess.WRITE)
    output.store_string(JSON.stringify({"checked": checked, "errors": errors}, "  "))
    output.close()
    for error in errors: print("PROJECT_RESOURCE_FAILURE: ", error)
    print("PROJECT_RESOURCES_VALIDATION=" + ("PASS" if errors.is_empty() else "FAIL"))
    quit(0 if errors.is_empty() else 1)
