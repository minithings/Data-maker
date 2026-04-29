@tool
extends RefCounted

var store
var gd_parser

func _init(p_store, p_gd) -> void:
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
	var field_type = gd_parser.get_field_type(file, prop, store)
	if field_type in ["bool", "enum", "export_enum"]:
		return false
	var v = file["data"].get(prop)
	return v == null or (typeof(v) == TYPE_STRING and (v as String) == "")

func get_error_list() -> Array:
	return store.get_error_list(self)

func get_error_count() -> int:
	return get_error_list().size()

func get_folder_error_count(path: String) -> int:
	return store.get_folder_error_count(path, self)
