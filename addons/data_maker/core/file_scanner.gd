@tool
extends RefCounted

var store
var tres_parser
var gd_parser
var json_handler

func _init(p_store, p_tres, p_gd, p_json) -> void:
	store = p_store
	tres_parser = p_tres
	gd_parser = p_gd
	json_handler = p_json

func load_project_data(root_abs: String) -> void:
	store.reset()
	store.project_root = root_abs

	var ignore_path = root_abs.path_join(".dbmakerignore")
	if FileAccess.file_exists(ignore_path):
		var f = FileAccess.open(ignore_path, FileAccess.READ)
		if f:
			for line in f.get_as_text().split("\n"):
				var trimmed = line.strip_edges()
				if trimmed != "":
					store.ignored_folders.append(trimmed)
			f.close()

	# Pass 1: scan ALL folders for .gd (ignore list NOT applied — scripts needed for hints)
	_scan_dir(root_abs, "", true)
	# Pass 2: scan .tres/.json (ignore list applied — only show data folders)
	_scan_dir(root_abs, "", false)

	store.build_tree()
	store.scan_complete.emit()

func _scan_dir(abs_path: String, rel_path: String, gd_only: bool) -> void:
	var dir = DirAccess.open(abs_path)
	if not dir:
		return
	dir.list_dir_begin()
	var entry_name = dir.get_next()
	while entry_name != "":
		var cur_abs = abs_path.path_join(entry_name)
		var cur_rel = (rel_path + "/" + entry_name).lstrip("/")
		if dir.current_is_dir():
			if entry_name.begins_with("."):
				entry_name = dir.get_next()
				continue
			# gd_only pass: scan ALL folders for .gd scripts (ignore list applies only to data files)
			# data pass: skip ignored folders so they don't appear in the table
			if not gd_only and store.ignored_folders.has(entry_name):
				entry_name = dir.get_next()
				continue
			_scan_dir(cur_abs, cur_rel, gd_only)
		else:
			_process_file(cur_abs, cur_rel, entry_name, rel_path, gd_only)
		entry_name = dir.get_next()
	dir.list_dir_end()

func _process_file(abs_path: String, rel_path: String, filename: String, folder_rel: String, gd_only: bool) -> void:
	if filename == ".dbmakerignore":
		return

	var folder = folder_rel.lstrip("/")
	if folder == "":
		folder = "root"

	if filename.ends_with(".gd"):
		if not gd_only:
			return
		var f = FileAccess.open(abs_path, FileAccess.READ)
		if f:
			gd_parser.parse_gdscript(f.get_as_text(), filename, store)
			f.close()

	elif not gd_only:
		if filename.ends_with(".tres"):
			var f = FileAccess.open(abs_path, FileAccess.READ)
			if not f:
				return
			var content = f.get_as_text()
			f.close()
			var split = tres_parser.split_tres(content)
			var data = tres_parser.parse_tres_body(split["body"])
			var script_name = tres_parser.get_script_name_from_tres(content)
			store.all_files.append({
				"id": rel_path,
				"name": filename,
				"path": rel_path,
				"folder": folder,
				"abs_path": abs_path,
				"data": data,
				"type": "tres",
				"script_name": script_name,
				"dirty": false,
				"raw_header": split["header"],
				"raw_body": split["body"]
			})
			store.record_types(rel_path, data)

		elif filename.ends_with(".json"):
			json_handler.read_json(abs_path, rel_path, folder, store)

func internal_create_tres(name: String, folder: String, template_id: String, store_ref) -> Dictionary:
	var full_name = name if name.ends_with(".tres") else name + ".tres"
	var abs_dir = store_ref.project_root
	if folder != "root" and folder != "":
		abs_dir = abs_dir.path_join(folder)
	var abs_path = abs_dir.path_join(full_name)
	var rel_path = (folder + "/" + full_name).lstrip("/")
	if folder == "root" or folder == "":
		rel_path = full_name

	var data: Dictionary = {}
	var header = '[gd_resource type="Resource" format=3]\n\n[resource]'
	var body = ""
	var script_name = "StaticResource"

	if template_id != "":
		var src = _find_file(store_ref, template_id)
		if src:
			data = src["data"].duplicate(true)
			var h: String = src["raw_header"]
			var uid_re = RegEx.new()
			uid_re.compile(r'\s+uid="uid://[^"]*"')
			h = uid_re.sub(h, "", true)
			header = h
			body = src.get("raw_body", "")
			script_name = src["script_name"]

	var f = FileAccess.open(abs_path, FileAccess.WRITE)
	if f:
		f.store_string(header.rstrip("\n") + "\n" + body + "\n")
		f.close()

	var new_file = {
		"id": rel_path,
		"name": full_name,
		"path": rel_path,
		"folder": folder if folder != "" else "root",
		"abs_path": abs_path,
		"data": data,
		"type": "tres",
		"script_name": script_name,
		"dirty": false,
		"raw_header": header,
		"raw_body": body
	}
	store_ref.all_files.append(new_file)
	store_ref.record_types(rel_path, data)
	store_ref.build_tree()
	return new_file

func _find_file(store_ref, id: String):
	for f in store_ref.all_files:
		if f["id"] == id:
			return f
	return null
