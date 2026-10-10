extends "res://autoload/storage.gd"
var directory: String
func _data_path() -> String:
    return directory + "/data.json"
func _backup_path() -> String:
    return directory + "/backup.json"
func _manual_backup_path() -> String:
    return directory + "/manual.json"
