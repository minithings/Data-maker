@tool
extends VBoxContainer
class_name TableGroup

signal entry_add_requested(group_files: Array, script_name: String)
signal column_add_requested(group_files: Array)
signal column_rename_requested(prop: String, group_files: Array)
signal column_change_type_requested(prop: String, group_files: Array)
signal entry_rename_requested(file: Dictionary)
signal entry_duplicate_requested(file: Dictionary)
signal entry_delete_requested(file: Dictionary)
signal multiline_open_requested(file: Dictionary, prop: String)
signal collection_open_requested(file: Dictionary, prop: String)
signal file_changed(file: Dictionary)

var _store: DataStore
var _validator: Validator
var _gd_parser: GDParser
var _script_name: String
var _group_files: Array
var _rows_container: VBoxContainer
var _header_row: HBoxContainer
var _fields: Array = []

func _init(store: DataStore, validator: Validator, gd_parser: GDParser) -> void:
	_store = store
	_validator = validator
	_gd_parser = gd_parser

func setup(script_name: String, group_files: Array) -> void:
	_script_name = script_name
	_group_files = group_files
	_fields = _store.get_fields_for_group(group_files)
	_build_ui()

func _build_ui() -> void:
	# Clear previous
	for child in get_children():
		child.queue_free()

	# Group header bar
	var header_bar = HBoxContainer.new()
	var dot = ColorRect.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.color = Color(0.4, 0.6, 1.0)
	header_bar.add_child(dot)

	var title = Label.new()
	title.text = _script_name
	title.add_theme_font_size_override("font_size", 11)
	header_bar.add_child(title)

	var add_entry_btn = Button.new()
	add_entry_btn.text = "+ Entry"
	add_entry_btn.pressed.connect(func(): entry_add_requested.emit(_group_files, _script_name))
	header_bar.add_child(add_entry_btn)

	# Add Column only for JSON groups
	if not _group_files.is_empty() and _group_files[0]["type"] == "json":
		var add_col_btn = Button.new()
		add_col_btn.text = "Column"
		add_col_btn.pressed.connect(func(): column_add_requested.emit(_group_files))
		header_bar.add_child(add_col_btn)

	add_child(header_bar)

	# Scrollable table area
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 38 + _group_files.size() * 50
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var table = VBoxContainer.new()
	table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(table)

	# Column header row
	_header_row = HBoxContainer.new()
	_build_header_row()
	table.add_child(_header_row)

	# Data rows
	_rows_container = VBoxContainer.new()
	table.add_child(_rows_container)
	_rebuild_rows()

func _build_header_row() -> void:
	for child in _header_row.get_children():
		child.queue_free()

	# ID column header
	var id_label = Label.new()
	id_label.text = "Identifier"
	id_label.custom_minimum_size.x = 220
	id_label.add_theme_font_size_override("font_size", 10)
	_header_row.add_child(id_label)

	# Field column headers
	for prop in _fields:
		var col_box = HBoxContainer.new()
		col_box.custom_minimum_size.x = 150

		var col_label = Label.new()
		col_label.text = prop
		col_label.add_theme_font_size_override("font_size", 10)
		col_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col_box.add_child(col_label)

		# Rename button
		var rename_btn = Button.new()
		rename_btn.text = "✎"
		rename_btn.custom_minimum_size = Vector2(24, 24)
		rename_btn.tooltip_text = "Rename Property"
		rename_btn.pressed.connect(func(): column_rename_requested.emit(prop, _group_files))
		col_box.add_child(rename_btn)

		# Change type button
		var type_btn = Button.new()
		type_btn.text = "⚙"
		type_btn.custom_minimum_size = Vector2(24, 24)
		type_btn.tooltip_text = "Change Column Type"
		type_btn.pressed.connect(func(): column_change_type_requested.emit(prop, _group_files))
		col_box.add_child(type_btn)

		_header_row.add_child(col_box)

func _rebuild_rows() -> void:
	for child in _rows_container.get_children():
		child.queue_free()

	for file in _group_files:
		_add_row(file)

func _add_row(file: Dictionary) -> void:
	var row = HBoxContainer.new()
	row.custom_minimum_size.y = 40

	# Dirty indicator
	if file.get("dirty", false):
		var dirty_rect = ColorRect.new()
		dirty_rect.custom_minimum_size = Vector2(3, 0)
		dirty_rect.color = Color(0.95, 0.62, 0.1)
		dirty_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_child(dirty_rect)

	# ID cell
	var id_box = HBoxContainer.new()
	id_box.custom_minimum_size.x = 217

	var id_label = Label.new()
	id_label.text = file["name"]
	id_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	id_label.clip_text = true
	id_box.add_child(id_label)

	# Row action buttons
	var rename_btn = Button.new()
	rename_btn.text = "✎"
	rename_btn.custom_minimum_size = Vector2(24, 24)
	rename_btn.tooltip_text = "Rename"
	rename_btn.pressed.connect(func(): entry_rename_requested.emit(file))
	id_box.add_child(rename_btn)

	if file["type"] == "tres":
		var dup_btn = Button.new()
		dup_btn.text = "⧉"
		dup_btn.custom_minimum_size = Vector2(24, 24)
		dup_btn.tooltip_text = "Duplicate"
		dup_btn.pressed.connect(func(): entry_duplicate_requested.emit(file))
		id_box.add_child(dup_btn)

	var del_btn = Button.new()
	del_btn.text = "🗑"
	del_btn.custom_minimum_size = Vector2(24, 24)
	del_btn.tooltip_text = "Delete"
	del_btn.pressed.connect(func(): entry_delete_requested.emit(file))
	id_box.add_child(del_btn)

	row.add_child(id_box)

	# Data cells
	for prop in _fields:
		var field_type = _gd_parser.get_field_type(file, prop, _store)
		var hint = _gd_parser.get_hint(file, prop, _store)
		var hi = _validator.has_issue(file, prop)
		var hw = _validator.has_warning(file, prop)

		var cell_box = HBoxContainer.new()
		cell_box.custom_minimum_size.x = 150

		var cell = CellRenderer.make_cell(
			file, prop, field_type, hint, hi, hw,
			func(val): _on_value_changed(file, prop, val),
			func(): multiline_open_requested.emit(file, prop),
			func(): collection_open_requested.emit(file, prop)
		)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell_box.add_child(cell)
		row.add_child(cell_box)

	_rows_container.add_child(row)

	# Separator
	var sep = HSeparator.new()
	_rows_container.add_child(sep)

func _on_value_changed(file: Dictionary, prop: String, new_val) -> void:
	var t = _store.get_original_type(file["id"], prop)
	match t:
		"number":
			if typeof(new_val) == TYPE_STRING:
				if (new_val as String).is_valid_float():
					file["data"][prop] = (new_val as String).to_float()
				else:
					file["data"][prop] = new_val
			else:
				file["data"][prop] = new_val
		"boolean":
			file["data"][prop] = bool(new_val)
		_:
			file["data"][prop] = new_val
	_store.mark_dirty(file)
	file_changed.emit(file)

func refresh() -> void:
	_fields = _store.get_fields_for_group(_group_files)
	_build_ui()
