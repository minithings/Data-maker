@tool
extends RefCounted
class_name Validator

var store: DataStore
var gd_parser: GDParser

func _init(p_store: DataStore, p_gd: GDParser) -> void:
	store = p_store
	gd_parser = p_gd

func has_issue(file: Dictionary, prop: String) -> bool:
	var v = file["data"].get(prop)
	var t = store.get_original_type(file["id"], prop)
	if t == "number" and typeof(v) == TYPE_STRING and not (v as String).is_valid_float() and v != "":
		return true
	var hint = gd_parser.get_hint(file, prop, store)
	if hint.get("type") == "enum" and v == null:
		return true
	return false

func has_warning(file: Dictionary, prop: String) -> bool:
	if file["type"] != "tres":
		return false
	var v = file["data"].get(prop)
	return v == "" or v == null

func get_error_list() -> Array:
	return store.get_error_list(self)

func get_error_count() -> int:
	return get_error_list().size()

func get_folder_error_count(path: String) -> int:
	return store.get_folder_error_count(path, self)
