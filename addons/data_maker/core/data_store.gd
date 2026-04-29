@tool
extends RefCounted
class_name DataStore

# All files/entries loaded from project
# Each dict: { id, name, path, folder, abs_path, data: Dictionary,
#              type: "tres"|"json", script_name, dirty,
#              raw_header, raw_body }
var all_files: Array = []

# Folder tree: [{ name, full_path, level }]
var folders: Array = []

# Parsed .gd files: { "script.gd": { hints: {}, parent: "" } }
var scripts: Dictionary = {}

# class_name → script filename mapping
var class_map: Dictionary = {}

# Original type metadata: { file_id: { prop_name: "number"|"string"|"boolean" } }
var original_types: Dictionary = {}

var ignored_folders: Array[String] = []
var dirty_count: int = 0
var active_folder: String = ""
var search_query: String = ""
var project_root: String = ""

signal scan_complete
signal dirty_changed(count: int)
signal active_folder_changed(folder: String)

func reset() -> void:
	all_files.clear()
	folders.clear()
	scripts.clear()
	class_map.clear()
	original_types.clear()
	ignored_folders.clear()
	dirty_count = 0
	active_folder = ""
	search_query = ""

func mark_dirty(file: Dictionary) -> void:
	if not file.get("dirty", false):
		file["dirty"] = true
		dirty_count += 1
		dirty_changed.emit(dirty_count)

func record_types(id: String, data: Dictionary) -> void:
	var t: Dictionary = {}
	for k in data:
		var v = data[k]
		match typeof(v):
			TYPE_INT, TYPE_FLOAT:
				t[k] = "number"
			TYPE_BOOL:
				t[k] = "boolean"
			_:
				t[k] = "string"
	original_types[id] = t

func get_original_type(file_id: String, prop: String) -> String:
	return original_types.get(file_id, {}).get(prop, "string")

func get_grouped_files() -> Dictionary:
	var source: Array
	if search_query.strip_edges() != "":
		var q = search_query.to_lower()
		source = all_files.filter(func(f): return f["name"].to_lower().contains(q))
	else:
		source = all_files.filter(func(f): return f["folder"] == active_folder)

	var groups: Dictionary = {}
	for f in source:
		var sn = f["script_name"]
		if not groups.has(sn):
			groups[sn] = []
		groups[sn].append(f)
	return groups

func build_tree() -> void:
	var paths: Array = []
	for f in all_files:
		var folder = f["folder"]
		if not paths.has(folder):
			paths.append(folder)

	if paths.is_empty():
		paths = ["root"]

	paths.sort()
	folders.clear()
	for p in paths:
		var parts = p.split("/")
		var level = 0 if p == "root" else parts.size()
		var name = "Resources" if p == "root" else parts[-1]
		folders.append({ "name": name, "full_path": p, "level": level })

	if active_folder == "" and not folders.is_empty():
		active_folder = folders[0]["full_path"]

func get_folder_error_count(path: String, validator: Object) -> int:
	var count = 0
	for f in all_files:
		if f["folder"] != path:
			continue
		for prop in f["data"]:
			if validator.has_issue(f, prop):
				count += 1
				break
	return count

func get_fields_for_group(group_files: Array) -> Array:
	var keys: Array = []
	for f in group_files:
		for k in f["data"]:
			if not keys.has(k):
				keys.append(k)
	return keys

func get_error_list(validator: Object) -> Array:
	var list: Array = []
	for f in all_files:
		for prop in f["data"]:
			if validator.has_issue(f, prop):
				list.append({
					"id": f["id"],
					"file_name": f["name"],
					"prop": prop,
					"value": f["data"][prop],
					"folder": f["folder"],
					"issue_type": "Error"
				})
	return list
