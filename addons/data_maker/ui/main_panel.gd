@tool
extends PanelContainer
class_name DataMakerMainPanel

# ── Core objects ──────────────────────────────────────────────────────────────
var _store: DataStore
var _tres_parser: TresParser
var _gd_parser: GDParser
var _json_handler: JsonHandler
var _file_scanner: FileScanner
var _validator: Validator

# ── UI ────────────────────────────────────────────────────────────────────────
var _toolbar: DataMakerToolbar
var _sidebar: DataMakerSidebar
var _content: VBoxContainer

# ── Dialogs ───────────────────────────────────────────────────────────────────
var _multiline_dlg: MultilineDialog
var _collection_dlg: CollectionDialog
var _create_dlg: CreateResourceDialog
var _add_prop_dlg: AddPropDialog
var _rename_prop_dlg: RenamePropDialog
var _change_type_dlg: ChangeTypeDialog
var _import_dlg: ImportDialog
var _error_dlg: ErrorSummaryDialog

# ── File picker ───────────────────────────────────────────────────────────────
var _dir_dialog: EditorFileDialog
var _import_file_dialog: EditorFileDialog
var _export_file_dialog: EditorFileDialog

func _ready() -> void:
	_init_core()
	_init_ui()
	_init_dialogs()

# ─────────────────────────────────────────────────────────────────────────────
func _init_core() -> void:
	_store = DataStore.new()
	_tres_parser = TresParser.new()
	_gd_parser = GDParser.new()
	_json_handler = JsonHandler.new()
	_file_scanner = FileScanner.new(_store, _tres_parser, _gd_parser, _json_handler)
	_validator = Validator.new(_store, _gd_parser)
	_store.scan_complete.connect(_on_scan_complete)
	_store.dirty_changed.connect(_on_dirty_changed)

func _init_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	# Toolbar
	_toolbar = DataMakerToolbar.new()
	_toolbar.open_project_requested.connect(_on_open_project)
	_toolbar.reload_requested.connect(_on_reload)
	_toolbar.export_requested.connect(_on_export)
	_toolbar.import_file_requested.connect(_on_import_file)
	_toolbar.paste_json_requested.connect(func(): _import_dlg.open())
	_toolbar.sync_requested.connect(save_dirty_files)
	_toolbar.issues_requested.connect(_on_show_errors)
	_toolbar.search_changed.connect(_on_search_changed)
	vbox.add_child(_toolbar)

	# Main split
	var hsplit = HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hsplit)

	# Sidebar
	_sidebar = DataMakerSidebar.new(_store, _validator)
	_sidebar.folder_selected.connect(_on_folder_selected)
	_sidebar.new_resource_requested.connect(func(): _create_dlg.open())
	hsplit.add_child(_sidebar)

	# Content scroll
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

func _init_dialogs() -> void:
	_multiline_dlg = MultilineDialog.new()
	_multiline_dlg.content_saved.connect(_on_multiline_saved)
	add_child(_multiline_dlg)

	_collection_dlg = CollectionDialog.new()
	_collection_dlg.collection_saved.connect(_on_collection_saved)
	add_child(_collection_dlg)

	_create_dlg = CreateResourceDialog.new(_store)
	_create_dlg.resource_create_requested.connect(_on_create_resource)
	add_child(_create_dlg)

	_add_prop_dlg = AddPropDialog.new()
	_add_prop_dlg.property_confirmed.connect(_on_add_property)
	add_child(_add_prop_dlg)

	_rename_prop_dlg = RenamePropDialog.new()
	_rename_prop_dlg.rename_confirmed.connect(_on_rename_property)
	add_child(_rename_prop_dlg)

	_change_type_dlg = ChangeTypeDialog.new()
	_change_type_dlg.type_change_confirmed.connect(_on_change_type)
	add_child(_change_type_dlg)

	_import_dlg = ImportDialog.new()
	_import_dlg.import_requested.connect(_process_import)
	add_child(_import_dlg)

	_error_dlg = ErrorSummaryDialog.new()
	_error_dlg.navigate_to_error.connect(_on_navigate_to_error)
	add_child(_error_dlg)

	# File pickers
	_dir_dialog = EditorFileDialog.new()
	_dir_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	_dir_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	_dir_dialog.dir_selected.connect(_on_dir_selected)
	add_child(_dir_dialog)

	_import_file_dialog = EditorFileDialog.new()
	_import_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_import_file_dialog.add_filter("*.json", "JSON Files")
	_import_file_dialog.file_selected.connect(_on_import_file_selected)
	add_child(_import_file_dialog)

	_export_file_dialog = EditorFileDialog.new()
	_export_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_export_file_dialog.add_filter("*.json", "JSON Files")
	_export_file_dialog.file_selected.connect(_on_export_file_selected)
	add_child(_export_file_dialog)

# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

func restore_project(root_path: String) -> void:
	_file_scanner.load_project_data(root_path)

func get_project_root() -> String:
	return _store.project_root

func save_dirty_files() -> void:
	if _store.dirty_count == 0 or _validator.get_error_count() > 0:
		return

	var paths: Dictionary = {}
	for f in _store.all_files:
		if f["dirty"]:
			paths[f["path"]] = true

	for path in paths:
		var entries = _store.all_files.filter(func(f): return f.get("dirty", false) and f["path"] == path)
		if entries.is_empty():
			continue
		if entries[0]["type"] == "tres":
			_tres_parser.save_tres(entries[0])
			entries[0]["dirty"] = false
		else:
			_json_handler.save_json(entries[0]["abs_path"], path, _store)
			for e in entries:
				e["dirty"] = false

	_store.dirty_count = 0
	_store.dirty_changed.emit(0)

	# Trigger Godot editor reimport
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()

	_refresh_table()

# ─────────────────────────────────────────────────────────────────────────────
# Toolbar handlers
# ─────────────────────────────────────────────────────────────────────────────

func _on_open_project() -> void:
	_dir_dialog.popup_centered_ratio(0.7)

func _on_dir_selected(path: String) -> void:
	_file_scanner.load_project_data(path)

func _on_reload() -> void:
	if _store.dirty_count > 0:
		var dlg = ConfirmationDialog.new()
		dlg.dialog_text = "Discard unsaved changes?"
		dlg.confirmed.connect(func(): _file_scanner.load_project_data(_store.project_root))
		add_child(dlg)
		dlg.popup_centered()
	else:
		_file_scanner.load_project_data(_store.project_root)

func _on_export() -> void:
	_export_file_dialog.current_file = "database_export.json"
	_export_file_dialog.popup_centered_ratio(0.7)

func _on_export_file_selected(path: String) -> void:
	var snapshot: Dictionary = {}
	for f in _store.all_files:
		snapshot[f["id"]] = f["data"]
	var fw = FileAccess.open(path, FileAccess.WRITE)
	if fw:
		fw.store_string(JSON.stringify(snapshot, "\t"))
		fw.close()

func _on_import_file() -> void:
	_import_file_dialog.popup_centered_ratio(0.7)

func _on_import_file_selected(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.READ)
	if f:
		_process_import(f.get_as_text())
		f.close()

func _on_show_errors() -> void:
	_error_dlg.open_with(_validator.get_error_list())

func _on_search_changed(q: String) -> void:
	_store.search_query = q
	_refresh_table()

# ─────────────────────────────────────────────────────────────────────────────
# Scan / folder
# ─────────────────────────────────────────────────────────────────────────────

func _on_scan_complete() -> void:
	_sidebar.refresh()
	_refresh_table()
	_toolbar.set_reload_enabled(true)
	_toolbar.update_dirty(0, 0)

func _on_folder_selected(path: String) -> void:
	_store.active_folder = path
	_store.search_query = ""
	_refresh_table()

func _on_dirty_changed(count: int) -> void:
	_toolbar.update_dirty(count, _validator.get_error_count())
	_toolbar.update_errors(_validator.get_error_count())

# ─────────────────────────────────────────────────────────────────────────────
# Table rendering
# ─────────────────────────────────────────────────────────────────────────────

func _refresh_table() -> void:
	for child in _content.get_children():
		child.queue_free()

	var grouped = _store.get_grouped_files()
	for script_name in grouped:
		var group_files: Array = grouped[script_name]
		var group_node = TableGroup.new(_store, _validator, _gd_parser)
		group_node.setup(script_name, group_files)

		group_node.entry_add_requested.connect(_on_add_entry)
		group_node.column_add_requested.connect(func(gf): _add_prop_dlg.open_for(gf))
		group_node.column_rename_requested.connect(func(prop, gf): _rename_prop_dlg.open_for(prop, gf))
		group_node.column_change_type_requested.connect(func(prop, gf): _change_type_dlg.open_for(prop, gf, _store))
		group_node.entry_rename_requested.connect(_on_rename_entry)
		group_node.entry_duplicate_requested.connect(_on_duplicate_entry)
		group_node.entry_delete_requested.connect(_on_delete_entry)
		group_node.multiline_open_requested.connect(func(f, prop): _multiline_dlg.open_for(f, prop))
		group_node.collection_open_requested.connect(func(f, prop): _collection_dlg.open_for(f, prop))
		group_node.file_changed.connect(func(_f): _on_dirty_changed(_store.dirty_count))

		_content.add_child(group_node)

# ─────────────────────────────────────────────────────────────────────────────
# CRUD
# ─────────────────────────────────────────────────────────────────────────────

func _on_add_entry(group_files: Array, script_name: String) -> void:
	if group_files.is_empty():
		return
	var dlg = AcceptDialog.new()
	dlg.title = "Add Entry"
	var edit = LineEdit.new()
	edit.placeholder_text = "Identifier"
	dlg.add_child(edit)
	dlg.confirmed.connect(func():
		var id = edit.text.strip_edges()
		if id == "":
			return
		var first = group_files[0]
		if first["type"] == "json":
			var ed: Dictionary = {}
			for k in first["data"]:
				var v = first["data"][k]
				match typeof(v):
					TYPE_BOOL: ed[k] = false
					TYPE_INT, TYPE_FLOAT: ed[k] = 0
					_: ed[k] = ""
			var eid = first["path"] + ":" + id
			var new_file = {
				"id": eid, "name": id, "path": first["path"],
				"folder": first["folder"], "abs_path": first["abs_path"],
				"data": ed, "type": "json", "script_name": first["script_name"], "dirty": true
			}
			_store.all_files.append(new_file)
			_store.record_types(eid, ed)
			_store.dirty_count += 1
		else:
			_file_scanner.internal_create_tres(id, first["folder"], first["id"], _store)
		_refresh_table()
		_sidebar.refresh()
	)
	add_child(dlg)
	dlg.popup_centered()

func _on_delete_entry(file: Dictionary) -> void:
	var dlg = ConfirmationDialog.new()
	dlg.dialog_text = "Delete '%s'?" % file["name"]
	dlg.confirmed.connect(func():
		if file["type"] == "tres":
			DirAccess.remove_absolute(file["abs_path"])
		_store.all_files = _store.all_files.filter(func(f): return f["id"] != file["id"])
		if file["type"] == "json":
			for f in _store.all_files:
				if f["path"] == file["path"]:
					_store.mark_dirty(f)
		_store.build_tree()
		_refresh_table()
		_sidebar.refresh()
	)
	add_child(dlg)
	dlg.popup_centered()

func _on_rename_entry(file: Dictionary) -> void:
	var dlg = AcceptDialog.new()
	dlg.title = "Rename Entry"
	var edit = LineEdit.new()
	edit.text = file["name"]
	dlg.add_child(edit)
	dlg.confirmed.connect(func():
		var new_name = edit.text.strip_edges()
		if new_name == "" or new_name == file["name"]:
			return
		if file["type"] == "tres":
			var new_fn = new_name if new_name.ends_with(".tres") else new_name + ".tres"
			var new_abs = file["abs_path"].get_base_dir().path_join(new_fn)
			var new_rel = file["path"].get_base_dir().path_join(new_fn).lstrip("/")
			if _store.all_files.any(func(f): return f["path"] == new_rel):
				OS.alert("File already exists!")
				return
			# Write new file
			var fw = FileAccess.open(new_abs, FileAccess.WRITE)
			if fw:
				fw.store_string(file["raw_header"].rstrip("\n") + "\n" + file.get("raw_body", "") + "\n")
				fw.close()
			DirAccess.remove_absolute(file["abs_path"])
			var old_id = file["id"]
			file["name"] = new_fn; file["path"] = new_rel
			file["id"] = new_rel; file["abs_path"] = new_abs
			var types = _store.original_types.get(old_id)
			_store.original_types.erase(old_id)
			if types:
				_store.original_types[file["id"]] = types
		else:
			var old_id = file["id"]
			file["name"] = new_name
			file["id"] = file["path"] + ":" + new_name
			var types = _store.original_types.get(old_id)
			_store.original_types.erase(old_id)
			if types:
				_store.original_types[file["id"]] = types
			_store.mark_dirty(file)
		_store.build_tree()
		_refresh_table()
		_sidebar.refresh()
	)
	add_child(dlg)
	dlg.popup_centered()

func _on_duplicate_entry(file: Dictionary) -> void:
	var base = file["name"].trim_suffix(".tres")
	var dlg = AcceptDialog.new()
	dlg.title = "Duplicate Entry"
	var edit = LineEdit.new()
	edit.text = base + "_copy"
	dlg.add_child(edit)
	dlg.confirmed.connect(func():
		var new_name = edit.text.strip_edges()
		if new_name == "":
			return
		_file_scanner.internal_create_tres(new_name, file["folder"], file["id"], _store)
		_refresh_table()
		_sidebar.refresh()
	)
	add_child(dlg)
	dlg.popup_centered()

func _on_create_resource(name: String, ext: String, template_id: String, schema: Array) -> void:
	if ext == ".tres":
		_file_scanner.internal_create_tres(name, _store.active_folder, template_id, _store)
	else:
		var full_name = name if name.ends_with(".json") else name + ".json"
		var folder = _store.active_folder
		var abs_dir = _store.project_root
		if folder != "root" and folder != "":
			abs_dir = abs_dir.path_join(folder)
		var abs_path = abs_dir.path_join(full_name)
		var rel_path = (folder + "/" + full_name).lstrip("/")
		if folder == "root" or folder == "":
			rel_path = full_name
		_json_handler.create_json_entry(abs_path, rel_path, folder if folder != "" else "root", "new_entry_1", schema, _store)
	_store.build_tree()
	_refresh_table()
	_sidebar.refresh()

# ─────────────────────────────────────────────────────────────────────────────
# Column management
# ─────────────────────────────────────────────────────────────────────────────

func _on_add_property(name: String, type: String, default_val: String, group_files: Array) -> void:
	var val
	match type:
		"number": val = float(default_val) if default_val.is_valid_float() else 0
		"boolean": val = default_val == "true"
		_: val = default_val
	for f in group_files:
		if not f["data"].has(name):
			f["data"][name] = val
			_store.mark_dirty(f)
			_store.record_types(f["id"], f["data"])
	_refresh_table()

func _on_rename_property(old_name: String, new_name: String, group_files: Array) -> void:
	for f in group_files:
		if f["data"].has(old_name):
			f["data"][new_name] = f["data"][old_name]
			f["data"].erase(old_name)
			var t = _store.original_types.get(f["id"], {})
			if t.has(old_name):
				t[new_name] = t[old_name]
				t.erase(old_name)
			_store.mark_dirty(f)
	_refresh_table()

func _on_change_type(prop: String, new_type: String, group_files: Array) -> void:
	for f in group_files:
		var val = f["data"].get(prop)
		match new_type:
			"number":
				if typeof(val) == TYPE_BOOL:
					val = 1 if val else 0
				else:
					val = float(str(val)) if str(val).is_valid_float() else 0
			"boolean":
				val = bool(val)
			_:
				val = str(val)
		f["data"][prop] = val
		var t = _store.original_types.get(f["id"], {})
		t[prop] = new_type
		_store.mark_dirty(f)
	_refresh_table()

# ─────────────────────────────────────────────────────────────────────────────
# Dialog callbacks
# ─────────────────────────────────────────────────────────────────────────────

func _on_multiline_saved(file: Dictionary, prop: String, text: String) -> void:
	file["data"][prop] = text
	_store.mark_dirty(file)
	_refresh_table()

func _on_collection_saved(file: Dictionary, prop: String, raw: String) -> void:
	file["data"][prop] = raw
	_store.mark_dirty(file)
	_refresh_table()

func _process_import(json_text: String) -> void:
	var json = JSON.new()
	if json.parse(json_text) != OK:
		OS.alert("Invalid JSON")
		return
	var imported = json.get_data()
	if typeof(imported) != TYPE_DICTIONARY:
		OS.alert("Invalid JSON structure")
		return
	var count = 0
	for f in _store.all_files:
		if imported.has(f["id"]):
			f["data"] = imported[f["id"]]
			_store.mark_dirty(f)
			count += 1
	OS.alert("Synced %d items." % count)
	_refresh_table()

func _on_navigate_to_error(folder: String, file_name: String) -> void:
	_store.active_folder = folder
	_store.search_query = file_name
	_refresh_table()
	_sidebar.refresh()
