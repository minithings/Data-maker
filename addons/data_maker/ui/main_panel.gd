@tool
extends PanelContainer

const _DataStore          = preload("res://addons/data_maker/core/data_store.gd")
const _TresParser         = preload("res://addons/data_maker/core/tres_parser.gd")
const _GDParser           = preload("res://addons/data_maker/core/gd_parser.gd")
const _JsonHandler        = preload("res://addons/data_maker/core/json_handler.gd")
const _FileScanner        = preload("res://addons/data_maker/core/file_scanner.gd")
const _Validator          = preload("res://addons/data_maker/core/validator.gd")
const _DataMakerToolbar   = preload("res://addons/data_maker/ui/toolbar.gd")
const _DataMakerSidebar   = preload("res://addons/data_maker/ui/sidebar.gd")
const _TableGroup         = preload("res://addons/data_maker/ui/table_group.gd")
const _MultilineDialog    = preload("res://addons/data_maker/dialogs/multiline_dialog.gd")
const _CollectionDialog   = preload("res://addons/data_maker/dialogs/collection_dialog.gd")
const _CreateResDialog    = preload("res://addons/data_maker/dialogs/create_resource_dialog.gd")
const _AddPropDialog      = preload("res://addons/data_maker/dialogs/add_prop_dialog.gd")
const _RenamePropDialog   = preload("res://addons/data_maker/dialogs/rename_prop_dialog.gd")
const _ChangeTypeDialog   = preload("res://addons/data_maker/dialogs/change_type_dialog.gd")
const _ImportDialog       = preload("res://addons/data_maker/dialogs/import_dialog.gd")
const _ErrorSummaryDialog = preload("res://addons/data_maker/dialogs/error_summary_dialog.gd")

# ── Core ──────────────────────────────────────────────────────────────────────
var _store
var _tres_parser
var _gd_parser
var _json_handler
var _file_scanner
var _validator

# ── UI ────────────────────────────────────────────────────────────────────────
var _toolbar
var _sidebar
var _sidebar_toggle_btn: Button
var _content: VBoxContainer
var _table_scroll: ScrollContainer
var _table_groups: Array = []

# ── Persistent dialogs (Window subclasses — owned by editor base control) ─────
var _multiline_dlg
var _collection_dlg
var _create_dlg
var _add_prop_dlg
var _rename_prop_dlg
var _change_type_dlg
var _import_dlg
var _error_dlg
var _dir_dialog: EditorFileDialog
var _import_file_dialog: EditorFileDialog
var _export_file_dialog: EditorFileDialog

# Parent node that owns all Window dialogs (must be a Window/Viewport).
# Set by plugin.gd before _ready fires via set_dialog_parent().
var _dialog_parent: Node = null

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_init_core()
	_init_ui()
	# Dialogs are created lazily via _ensure_dialogs() on first use,
	# because _dialog_parent may not be set until after _ready().

func set_dialog_parent(p: Node) -> void:
	_dialog_parent = p

# ─────────────────────────────────────────────────────────────────────────────
func _init_core() -> void:
	_store        = _DataStore.new()
	_tres_parser  = _TresParser.new()
	_gd_parser    = _GDParser.new()
	_json_handler = _JsonHandler.new()
	_file_scanner = _FileScanner.new(_store, _tres_parser, _gd_parser, _json_handler)
	_validator    = _Validator.new(_store, _gd_parser)
	_store.scan_complete.connect(_on_scan_complete)
	_store.dirty_changed.connect(_on_dirty_changed)

func _init_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	# Toolbar
	_toolbar = _DataMakerToolbar.new()
	_toolbar.open_project_requested.connect(_on_open_project)
	_toolbar.reload_requested.connect(_on_reload)
	_toolbar.export_requested.connect(_on_export)
	_toolbar.import_file_requested.connect(_on_import_file)
	_toolbar.paste_json_requested.connect(func(): _ensure_dialogs(); _import_dlg.open())
	_toolbar.sync_requested.connect(save_dirty_files)
	_toolbar.issues_requested.connect(_on_show_errors)
	_toolbar.search_changed.connect(_on_search_changed)
	root_vbox.add_child(_toolbar)

	# Workspace: [toggle][sidebar][sep][table]
	var workspace = HBoxContainer.new()
	workspace.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 0)
	root_vbox.add_child(workspace)

	_sidebar_toggle_btn = Button.new()
	_sidebar_toggle_btn.text = "◀"
	_sidebar_toggle_btn.flat = true
	_sidebar_toggle_btn.custom_minimum_size = Vector2(16, 0)
	_sidebar_toggle_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sidebar_toggle_btn.tooltip_text = "Toggle sidebar"
	_sidebar_toggle_btn.pressed.connect(_on_toggle_sidebar)
	workspace.add_child(_sidebar_toggle_btn)

	_sidebar = _DataMakerSidebar.new(_store, _validator)
	_sidebar.custom_minimum_size.x = 150
	_sidebar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_sidebar.folder_selected.connect(_on_folder_selected)
	_sidebar.new_resource_requested.connect(func(): _ensure_dialogs(); _create_dlg.open())
	workspace.add_child(_sidebar)

	workspace.add_child(VSeparator.new())

	_table_scroll = ScrollContainer.new()
	_table_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_table_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	_table_scroll.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	_table_scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	workspace.add_child(_table_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 6)
	_table_scroll.add_child(_content)

# ─────────────────────────────────────────────────────────────────────────────
# Dialog management — all Window nodes live under _dialog_parent (a Window).
# ─────────────────────────────────────────────────────────────────────────────

func _ensure_dialogs() -> void:
	if _multiline_dlg != null:
		return
	if _dialog_parent == null:
		# Fallback: use scene tree root (always a Window)
		_dialog_parent = get_tree().root if get_tree() else null
	if _dialog_parent == null:
		push_error("[DataMaker] No dialog parent available.")
		return

	_multiline_dlg = _MultilineDialog.new()
	_multiline_dlg.content_saved.connect(_on_multiline_saved)
	_dialog_parent.add_child(_multiline_dlg)

	_collection_dlg = _CollectionDialog.new()
	_collection_dlg.collection_saved.connect(_on_collection_saved)
	_dialog_parent.add_child(_collection_dlg)

	_create_dlg = _CreateResDialog.new(_store)
	_create_dlg.resource_create_requested.connect(_on_create_resource)
	_dialog_parent.add_child(_create_dlg)

	_add_prop_dlg = _AddPropDialog.new()
	_add_prop_dlg.property_confirmed.connect(_on_add_property)
	_dialog_parent.add_child(_add_prop_dlg)

	_rename_prop_dlg = _RenamePropDialog.new()
	_rename_prop_dlg.rename_confirmed.connect(_on_rename_property)
	_dialog_parent.add_child(_rename_prop_dlg)

	_change_type_dlg = _ChangeTypeDialog.new()
	_change_type_dlg.type_change_confirmed.connect(_on_change_type)
	_dialog_parent.add_child(_change_type_dlg)

	_import_dlg = _ImportDialog.new()
	_import_dlg.import_requested.connect(_process_import)
	_dialog_parent.add_child(_import_dlg)

	_error_dlg = _ErrorSummaryDialog.new()
	_error_dlg.navigate_to_error.connect(_on_navigate_to_error)
	_dialog_parent.add_child(_error_dlg)

	_dir_dialog = EditorFileDialog.new()
	_dir_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	_dir_dialog.access   = EditorFileDialog.ACCESS_FILESYSTEM
	_dir_dialog.dir_selected.connect(_on_dir_selected)
	_dialog_parent.add_child(_dir_dialog)

	_import_file_dialog = EditorFileDialog.new()
	_import_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_import_file_dialog.add_filter("*.json", "JSON Files")
	_import_file_dialog.file_selected.connect(_on_import_file_selected)
	_dialog_parent.add_child(_import_file_dialog)

	_export_file_dialog = EditorFileDialog.new()
	_export_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_export_file_dialog.add_filter("*.json", "JSON Files")
	_export_file_dialog.file_selected.connect(_on_export_file_selected)
	_dialog_parent.add_child(_export_file_dialog)

func free_dialogs() -> void:
	# Called by plugin.gd during _exit_tree before queue_free
	var dlgs = [
		_multiline_dlg, _collection_dlg, _create_dlg, _add_prop_dlg,
		_rename_prop_dlg, _change_type_dlg, _import_dlg, _error_dlg,
		_dir_dialog, _import_file_dialog, _export_file_dialog
	]
	for d in dlgs:
		if is_instance_valid(d):
			d.queue_free()
	_multiline_dlg = null; _collection_dlg = null; _create_dlg = null
	_add_prop_dlg  = null; _rename_prop_dlg = null; _change_type_dlg = null
	_import_dlg    = null; _error_dlg = null
	_dir_dialog    = null; _import_file_dialog = null; _export_file_dialog = null

# Inline one-shot dialog — add to dialog_parent, free after use
func _show_dialog(dlg: Window) -> void:
	var parent = _dialog_parent if _dialog_parent != null else get_tree().root
	parent.add_child(dlg)
	dlg.popup_centered()
	# Free after any close action
	var free_fn = func():
		if is_instance_valid(dlg):
			dlg.queue_free()
	if dlg.has_signal("confirmed"):
		dlg.confirmed.connect(free_fn, CONNECT_ONE_SHOT)
	if dlg.has_signal("canceled"):
		dlg.canceled.connect(free_fn, CONNECT_ONE_SHOT)
	dlg.close_requested.connect(free_fn, CONNECT_ONE_SHOT)

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

	var failed: Array[String] = []
	for path in paths:
		var entries = _store.all_files.filter(
			func(f): return f.get("dirty", false) and f["path"] == path)
		if entries.is_empty():
			continue
		var ok: bool
		if entries[0]["type"] == "tres":
			ok = _tres_parser.save_tres(entries[0])
			if ok: entries[0]["dirty"] = false
		else:
			ok = _json_handler.save_json(entries[0]["abs_path"], path, _store)
			if ok:
				for e in entries: e["dirty"] = false
		if not ok:
			failed.append(path)

	_store.dirty_count = _store.all_files.filter(
		func(f): return f.get("dirty", false)).size()
	_store.dirty_changed.emit(_store.dirty_count)

	if not failed.is_empty():
		OS.alert("Failed to save:\n%s" % "\n".join(failed))

	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()

	_refresh_table()

# ─────────────────────────────────────────────────────────────────────────────
# Toolbar handlers
# ─────────────────────────────────────────────────────────────────────────────

func _on_open_project() -> void:
	_ensure_dialogs()
	_dir_dialog.popup_centered_ratio(0.7)

func _on_dir_selected(path: String) -> void:
	_file_scanner.load_project_data(path)

func _on_reload() -> void:
	if _store.dirty_count > 0:
		var dlg = ConfirmationDialog.new()
		dlg.dialog_text = "Discard unsaved changes and reload?"
		dlg.confirmed.connect(func(): _file_scanner.load_project_data(_store.project_root))
		_show_dialog(dlg)
	else:
		_file_scanner.load_project_data(_store.project_root)

func _on_export() -> void:
	_ensure_dialogs()
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
	_ensure_dialogs()
	_import_file_dialog.popup_centered_ratio(0.7)

func _on_import_file_selected(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.READ)
	if f:
		_process_import(f.get_as_text())
		f.close()

func _on_show_errors() -> void:
	_ensure_dialogs()
	_error_dlg.open_with(_validator.get_error_list())

func _on_search_changed(q: String) -> void:
	_store.search_query = q
	_refresh_table()

# ─────────────────────────────────────────────────────────────────────────────
# Sidebar / scan
# ─────────────────────────────────────────────────────────────────────────────

func _on_scan_complete() -> void:
	_sidebar.refresh()
	_refresh_table()
	_toolbar.set_reload_enabled(true)
	_toolbar.update_dirty(0, 0)

func _on_toggle_sidebar() -> void:
	_sidebar.visible = !_sidebar.visible
	_sidebar_toggle_btn.text = "▶" if not _sidebar.visible else "◀"

func _on_folder_selected(path: String) -> void:
	_store.active_folder = path
	_store.search_query  = ""
	_refresh_table()

func _on_dirty_changed(count: int) -> void:
	var err = _validator.get_error_count()
	_toolbar.update_dirty(count, err)
	_toolbar.update_errors(err)

func _on_inspect_resource(abs_path: String) -> void:
	if not Engine.is_editor_hint():
		return
	var res = ResourceLoader.load(abs_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res:
		EditorInterface.edit_resource(res)

# ─────────────────────────────────────────────────────────────────────────────
# Table
# ─────────────────────────────────────────────────────────────────────────────

func _refresh_table() -> void:
	var saved_v = _table_scroll.scroll_vertical
	for child in _content.get_children():
		child.queue_free()
	_table_groups.clear()

	var grouped = _store.get_grouped_files()
	for script_name in grouped:
		var gf: Array = grouped[script_name]
		var tg = _TableGroup.new(_store, _validator, _gd_parser)
		tg.setup(script_name, gf)
		tg.inspect_resource_requested.connect(_on_inspect_resource)
		tg.entry_add_requested.connect(_on_add_entry)
		tg.column_add_requested.connect(func(g): _ensure_dialogs(); _add_prop_dlg.open_for(g))
		tg.column_rename_requested.connect(func(p, g): _ensure_dialogs(); _rename_prop_dlg.open_for(p, g))
		tg.column_change_type_requested.connect(func(p, g): _ensure_dialogs(); _change_type_dlg.open_for(p, g, _store))
		tg.entry_rename_requested.connect(_on_rename_entry)
		tg.entry_duplicate_requested.connect(_on_duplicate_entry)
		tg.entry_delete_requested.connect(_on_delete_entry)
		tg.multiline_open_requested.connect(func(f, p): _ensure_dialogs(); _multiline_dlg.open_for(f, p))
		tg.collection_open_requested.connect(func(f, p, g): _ensure_dialogs(); _collection_dlg.open_for(f, p, g))
		tg.file_changed.connect(func(_f): _on_dirty_changed(_store.dirty_count))
		_content.add_child(tg)
		_table_groups.append(tg)

	_table_scroll.call_deferred("set", "scroll_vertical", saved_v)

# ─────────────────────────────────────────────────────────────────────────────
# CRUD
# ─────────────────────────────────────────────────────────────────────────────

func _on_add_entry(group_files: Array, script_name: String) -> void:
	if group_files.is_empty():
		return
	var dlg = AcceptDialog.new()
	dlg.title = "New Entry — " + script_name
	var vb = VBoxContainer.new()
	var lbl = Label.new(); lbl.text = "Identifier:"
	vb.add_child(lbl)
	var edit = LineEdit.new()
	edit.placeholder_text = "my_entry_id"
	edit.custom_minimum_size.x = 280
	vb.add_child(edit)
	dlg.add_child(vb)
	dlg.confirmed.connect(func():
		var id = _sanitize_name(edit.text)
		if id == "":
			return
		var first = group_files[0]
		if first["type"] == "json":
			var ed: Dictionary = {}
			for k in first["data"]:
				match typeof(first["data"][k]):
					TYPE_BOOL:             ed[k] = false
					TYPE_INT, TYPE_FLOAT:  ed[k] = 0
					_:                     ed[k] = ""
			var eid = first["path"] + ":" + id
			var nf = {
				"id": eid, "name": id, "path": first["path"],
				"folder": first["folder"], "abs_path": first["abs_path"],
				"data": ed, "type": "json",
				"script_name": first["script_name"], "dirty": true
			}
			_store.all_files.append(nf)
			_store.record_types(eid, ed)
			_store.dirty_count += 1
		else:
			_file_scanner.internal_create_tres(id, first["folder"], first["id"], _store)
		_refresh_table()
		_sidebar.refresh()
	)
	_show_dialog(dlg)

func _on_delete_entry(file: Dictionary) -> void:
	var dlg = ConfirmationDialog.new()
	dlg.dialog_text = "Delete '%s'? This cannot be undone." % file["name"]
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
	_show_dialog(dlg)

func _on_rename_entry(file: Dictionary) -> void:
	var dlg = AcceptDialog.new()
	dlg.title = "Rename Entry"
	var edit = LineEdit.new()
	edit.text = file["name"]
	edit.custom_minimum_size.x = 280
	dlg.add_child(edit)
	dlg.confirmed.connect(func():
		var new_name = _sanitize_name(edit.text)
		if new_name == "" or new_name == file["name"]:
			return
		if file["type"] == "tres":
			var new_fn  = new_name if new_name.ends_with(".tres") else new_name + ".tres"
			var new_abs = file["abs_path"].get_base_dir().path_join(new_fn)
			var new_rel = file["path"].get_base_dir().path_join(new_fn).lstrip("/")
			if _store.all_files.any(func(f): return f["path"] == new_rel):
				return
			var fw = FileAccess.open(new_abs, FileAccess.WRITE)
			if fw:
				fw.store_string(
					file.get("raw_header", "").rstrip("\n") + "\n" +
					file.get("raw_body", "") + "\n")
				fw.close()
			DirAccess.remove_absolute(file["abs_path"])
			var old_id = file["id"]
			file["name"] = new_fn; file["path"] = new_rel
			file["id"] = new_rel; file["abs_path"] = new_abs
			var types = _store.original_types.get(old_id)
			_store.original_types.erase(old_id)
			if types: _store.original_types[file["id"]] = types
		else:
			var old_id = file["id"]
			file["name"] = new_name
			file["id"]   = file["path"] + ":" + new_name
			var types = _store.original_types.get(old_id)
			_store.original_types.erase(old_id)
			if types: _store.original_types[file["id"]] = types
			_store.mark_dirty(file)
		_store.build_tree()
		_refresh_table()
		_sidebar.refresh()
	)
	_show_dialog(dlg)

func _on_duplicate_entry(file: Dictionary) -> void:
	var dlg = AcceptDialog.new()
	dlg.title = "Duplicate Entry"
	var edit = LineEdit.new()
	edit.text = file["name"].trim_suffix(".tres") + "_copy"
	edit.custom_minimum_size.x = 280
	dlg.add_child(edit)
	dlg.confirmed.connect(func():
		var new_name = _sanitize_name(edit.text)
		if new_name == "": return
		_file_scanner.internal_create_tres(new_name, file["folder"], file["id"], _store)
		_refresh_table()
		_sidebar.refresh()
	)
	_show_dialog(dlg)

func _on_create_resource(res_name: String, ext: String, template_id: String, schema: Array) -> void:
	var safe = _sanitize_name(res_name)
	if safe == "": return
	if ext == ".tres":
		_file_scanner.internal_create_tres(safe, _store.active_folder, template_id, _store)
	else:
		var full   = safe if safe.ends_with(".json") else safe + ".json"
		var folder = _store.active_folder
		var adir   = _store.project_root
		if folder != "root" and folder != "":
			adir = adir.path_join(folder)
		var apath = adir.path_join(full)
		var rpath = (folder + "/" + full).lstrip("/")
		if folder == "root" or folder == "":
			rpath = full
		_json_handler.create_json_entry(
			apath, rpath, folder if folder != "" else "root",
			"new_entry_1", schema, _store)
	_store.build_tree()
	_refresh_table()
	_sidebar.refresh()

# ─────────────────────────────────────────────────────────────────────────────
# Column management
# ─────────────────────────────────────────────────────────────────────────────

func _on_add_property(prop_name: String, type: String, default_val: String, group_files: Array) -> void:
	var val
	match type:
		"number":  val = float(default_val) if default_val.is_valid_float() else 0.0
		"boolean": val = default_val == "true"
		_:         val = default_val
	for f in group_files:
		if not f["data"].has(prop_name):
			f["data"][prop_name] = val
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
		var v = f["data"].get(prop)
		match new_type:
			"number":  v = float(str(v)) if str(v).is_valid_float() else 0.0
			"boolean": v = bool(v)
			_:         v = str(v)
		f["data"][prop] = v
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
	_refresh_file_row(file)

func _on_collection_saved(file: Dictionary, prop: String, raw: String) -> void:
	file["data"][prop] = raw
	_store.mark_dirty(file)
	_refresh_file_row(file)

# Rebuild only the TableGroup that owns this file — no full table rebuild
func _refresh_file_row(file: Dictionary) -> void:
	_on_dirty_changed(_store.dirty_count)
	var script_name = file.get("script_name", "")
	for tg in _table_groups:
		if tg._script_name == script_name:
			var sv = _table_scroll.scroll_vertical
			var sh = _table_scroll.scroll_horizontal if _table_scroll.get("scroll_horizontal") != null else 0
			tg.refresh()
			_table_scroll.call_deferred("set", "scroll_vertical", sv)
			return

func _process_import(json_text: String) -> void:
	var json = JSON.new()
	if json.parse(json_text) != OK:
		OS.alert("Invalid JSON"); return
	var imported = json.get_data()
	if typeof(imported) != TYPE_DICTIONARY:
		OS.alert("Expected a JSON object."); return
	var count = 0
	for f in _store.all_files:
		if imported.has(f["id"]):
			f["data"] = imported[f["id"]]
			_store.mark_dirty(f)
			count += 1
	OS.alert("Synced %d item(s)." % count)
	_refresh_table()

func _on_navigate_to_error(folder: String, file_name: String) -> void:
	_store.active_folder = folder
	_store.search_query  = file_name
	_refresh_table()
	_sidebar.refresh()

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

static func _sanitize_name(raw: String) -> String:
	var n = raw.strip_edges()
	if n == "": return ""
	for bad in ["/", "\\", "..", "<", ">", ":", '"', "|", "?", "*"]:
		if bad in n: return ""
	return n
