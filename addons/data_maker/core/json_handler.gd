@tool
extends RefCounted

func read_json(abs_path: String, rel_path: String, folder: String, store) -> void:
	var f = FileAccess.open(abs_path, FileAccess.READ)
	if not f:
		return
	var text = f.get_as_text()
	f.close()

	var json = JSON.new()
	if json.parse(text) != OK:
		return

	var parsed = json.get_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var filename = abs_path.split("/")[-1]
	for entry_id in parsed:
		var val = parsed[entry_id]
		if typeof(val) != TYPE_DICTIONARY:
			continue
		var eid = rel_path + ":" + entry_id
		store.all_files.append({
			"id": eid,
			"name": entry_id,
			"path": rel_path,
			"folder": folder,
			"abs_path": abs_path,
			"handle": abs_path,
			"data": val.duplicate(true),
			"type": "json",
			"script_name": filename,
			"dirty": false
		})
		store.record_types(eid, val)

func save_json(abs_path: String, rel_path: String, store) -> bool:
	var entries = store.all_files.filter(func(e): return e["path"] == rel_path)
	var obj: Dictionary = {}
	for entry in entries:
		obj[entry["name"]] = entry["data"]

	var fw = FileAccess.open(abs_path, FileAccess.WRITE)
	if not fw:
		push_error("[DataMaker] Failed to write .json file: %s (error %d)" % [
			abs_path, FileAccess.get_open_error()
		])
		return false
	fw.store_string(JSON.stringify(obj, "\t"))
	fw.close()
	return true

func create_json_entry(abs_path: String, rel_path: String, folder: String,
		entry_id: String, schema: Array, store) -> Dictionary:
	var data: Dictionary = {}
	for prop in schema:
		match prop["type"]:
			"number": data[prop["name"]] = 0
			"boolean": data[prop["name"]] = false
			_: data[prop["name"]] = ""

	var existing: Dictionary = {}
	if FileAccess.file_exists(abs_path):
		var f = FileAccess.open(abs_path, FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK:
				var parsed = json.get_data()
				if typeof(parsed) == TYPE_DICTIONARY:
					existing = parsed
			f.close()

	existing[entry_id] = data
	var fw = FileAccess.open(abs_path, FileAccess.WRITE)
	if fw:
		fw.store_string(JSON.stringify(existing, "\t"))
		fw.close()

	var filename = abs_path.split("/")[-1]
	var eid = rel_path + ":" + entry_id
	var new_file = {
		"id": eid,
		"name": entry_id,
		"path": rel_path,
		"folder": folder,
		"abs_path": abs_path,
		"handle": abs_path,
		"data": data.duplicate(),
		"type": "json",
		"script_name": filename,
		"dirty": false
	}
	store.all_files.append(new_file)
	store.record_types(eid, data)
	return new_file
