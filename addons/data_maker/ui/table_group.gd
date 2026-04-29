@tool
extends VBoxContainer
class_name TableGroup

const _CellRenderer = preload("res://addons/data_maker/ui/cell_renderer.gd")

signal entry_add_requested(group_files: Array, script_name: String)
signal column_add_requested(group_files: Array)
signal column_rename_requested(prop: String, group_files: Array)
signal column_change_type_requested(prop: String, group_files: Array)
signal entry_rename_requested(file: Dictionary)
signal entry_duplicate_requested(file: Dictionary)
signal entry_delete_requested(file: Dictionary)
signal multiline_open_requested(file: Dictionary, prop: String)
signal collection_open_requested(file: Dictionary, prop: String, group_files: Array)
signal file_changed(file: Dictionary)
signal inspect_resource_requested(abs_path: String)   # open ExtResource in Godot Inspector

const ROW_HEIGHT    = 32
const HEADER_HEIGHT = 28
const ID_COL_WIDTH  = 210
const COL_WIDTH     = 180

var _store
var _validator
var _gd_parser
var _script_name: String
var _group_files: Array
var _fields: Array = []

var _id_col_vbox: VBoxContainer
var _data_scroll: ScrollContainer
var _data_col_vbox: VBoxContainer

func _init(store, validator, gd_parser) -> void:
	_store     = store
	_validator = validator
	_gd_parser = gd_parser

func setup(script_name: String, group_files: Array) -> void:
	_script_name = script_name
	_group_files = group_files
	_fields      = _get_fields(group_files)
	_build_ui()

# Returns the authoritative field list for this group.
# For .tres: use GDScript @export hints as source of truth (preserves fields
#   even when Godot omits default values from the file), then filter out any
#   extra keys not declared in the script (e.g. from mis-pasted .tres files).
# For .json: use the union of all data keys (no schema available).
func _get_fields(group_files: Array) -> Array:
	if group_files.is_empty():
		return []

	# JSON — no schema, use union of data keys
	if group_files[0]["type"] != "tres":
		var all_keys: Array = []
		for f in group_files:
			for k in f["data"]:
				if not all_keys.has(k):
					all_keys.append(k)
		return all_keys

	# .tres — resolve GDScript hints for this group's script
	var script_file = group_files[0].get("script_name", "")
	var all_hints: Dictionary = _collect_hints(script_file)

	if all_hints.is_empty():
		# No hints found — fall back to union of data keys
		var all_keys: Array = []
		for f in group_files:
			for k in f["data"]:
				if not all_keys.has(k):
					all_keys.append(k)
		return all_keys

	# Filter: skip fields whose GDScript type is an unsupported Resource/Object type
	var renderable: Array = []
	var sample = group_files[0]
	for k in all_hints.keys():
		var h = _gd_parser.get_hint(sample, k, _store)
		if h.get("type") != "unsupported":
			renderable.append(k)
	return renderable

# Walk the inheritance chain and return an ordered dict of all @export field names.
func _collect_hints(script_file: String) -> Dictionary:
	var si = _store.scripts.get(script_file)
	if si == null:
		si = _store.scripts.get(_store.class_map.get(script_file, ""))
	if si == null:
		return {}

	# Walk parent chain, child hints take priority (child keys added first)
	var ordered: Dictionary = {}
	var cur_si = si
	var depth = 0
	while cur_si != null and depth < 10:
		for k in cur_si["hints"]:
			if not ordered.has(k):
				ordered[k] = true
		var parent = cur_si.get("parent", "")
		if parent == "":
			break
		cur_si = _store.scripts.get(parent)
		if cur_si == null:
			cur_si = _store.scripts.get(_store.class_map.get(parent, ""))
		depth += 1
	return ordered

# ─────────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	for c in get_children(): c.queue_free()
	add_theme_constant_override("separation", 0)

	add_child(_make_section_header())

	var body = HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	add_child(body)

	# Fixed ID column (left)
	_id_col_vbox = VBoxContainer.new()
	_id_col_vbox.custom_minimum_size.x = ID_COL_WIDTH
	_id_col_vbox.size_flags_horizontal  = Control.SIZE_SHRINK_BEGIN
	_id_col_vbox.add_theme_constant_override("separation", 0)
	body.add_child(_id_col_vbox)

	var vsep = VSeparator.new()
	vsep.custom_minimum_size.x = 1
	body.add_child(vsep)

	# Scrollable data columns (right) — wheel scrolls horizontally, drag scrolls
	_data_scroll = ScrollContainer.new()
	_data_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_data_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	_data_scroll.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	_data_scroll.gui_input.connect(_on_scroll_input.bind(_data_scroll))
	body.add_child(_data_scroll)

	_data_col_vbox = VBoxContainer.new()
	_data_col_vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_data_col_vbox.add_theme_constant_override("separation", 0)
	_data_scroll.add_child(_data_col_vbox)

	_build_header_row()
	_build_data_rows()

# ── Section header ────────────────────────────────────────────────────────────
func _make_section_header() -> Control:
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)

	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)

	var accent = ColorRect.new()
	accent.custom_minimum_size = Vector2(3, 16)
	accent.color = Color(0.4, 0.6, 1.0)
	bar.add_child(accent)

	var title = Label.new()
	title.text = " " + _script_name
	title.add_theme_font_size_override("font_size", 12)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(title)

	var count_lbl = Label.new()
	count_lbl.text = str(_group_files.size()) + " rows"
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.modulate = Color(0.5, 0.5, 0.5)
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(count_lbl)

	var add_btn = Button.new()
	add_btn.text = "+ Entry"
	add_btn.custom_minimum_size = Vector2(70, 22)
	add_btn.pressed.connect(func(): entry_add_requested.emit(_group_files, _script_name))
	bar.add_child(add_btn)

	if not _group_files.is_empty() and _group_files[0]["type"] == "json":
		var col_btn = Button.new()
		col_btn.text = "+ Column"
		col_btn.custom_minimum_size = Vector2(76, 22)
		col_btn.pressed.connect(func(): column_add_requested.emit(_group_files))
		bar.add_child(col_btn)

	vb.add_child(bar)
	vb.add_child(HSeparator.new())
	return vb

# ── Scroll: wheel → horizontal, left-drag → grab-scroll ──────────────────────
func _on_scroll_input(event: InputEvent, scroll: ScrollContainer) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			scroll.scroll_horizontal -= 48
			scroll.accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			scroll.scroll_horizontal += 48
			scroll.accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				scroll.set_meta("_drag", true)
				scroll.set_meta("_drag_x", event.global_position.x)
				scroll.set_meta("_drag_sx", float(scroll.scroll_horizontal))
				scroll.mouse_default_cursor_shape = Control.CURSOR_DRAG
			else:
				scroll.set_meta("_drag", false)
				scroll.mouse_default_cursor_shape = Control.CURSOR_ARROW
	elif event is InputEventMouseMotion:
		if scroll.get_meta("_drag", false):
			var dx = event.global_position.x - scroll.get_meta("_drag_x", 0.0)
			scroll.scroll_horizontal = int(scroll.get_meta("_drag_sx", 0.0) - dx)
			scroll.accept_event()

# ── Header row ────────────────────────────────────────────────────────────────
func _build_header_row() -> void:
	var id_hdr = Label.new()
	id_hdr.text = "  Identifier"
	id_hdr.custom_minimum_size = Vector2(ID_COL_WIDTH, HEADER_HEIGHT)
	id_hdr.add_theme_font_size_override("font_size", 11)
	id_hdr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	id_hdr.modulate = Color(0.65, 0.65, 0.65)
	_id_col_vbox.add_child(id_hdr)
	_id_col_vbox.add_child(_hsep())

	var hdr_row = HBoxContainer.new()
	hdr_row.custom_minimum_size.y = HEADER_HEIGHT
	hdr_row.add_theme_constant_override("separation", 1)

	for prop in _fields:
		hdr_row.add_child(_make_col_header(prop))

	_data_col_vbox.add_child(hdr_row)
	_data_col_vbox.add_child(_hsep())

func _make_col_header(prop: String) -> Control:
	var box = HBoxContainer.new()
	box.custom_minimum_size = Vector2(COL_WIDTH, HEADER_HEIGHT)
	box.add_theme_constant_override("separation", 2)

	var lbl = Label.new()
	lbl.text = prop
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(0.65, 0.65, 0.65)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.clip_text = true
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(lbl)

	var ren = Button.new()
	ren.text = "✎"
	ren.flat = true
	ren.custom_minimum_size = Vector2(18, 18)
	ren.tooltip_text = "Rename column"
	ren.pressed.connect(func(): column_rename_requested.emit(prop, _group_files))
	box.add_child(ren)

	var typ = Button.new()
	typ.text = "⚙"
	typ.flat = true
	typ.custom_minimum_size = Vector2(18, 18)
	typ.tooltip_text = "Change column type"
	typ.pressed.connect(func(): column_change_type_requested.emit(prop, _group_files))
	box.add_child(typ)

	return box

# ── Data rows ─────────────────────────────────────────────────────────────────
func _build_data_rows() -> void:
	for i in _group_files.size():
		_add_row(_group_files[i], i)

func _add_row(file: Dictionary, row_idx: int) -> void:
	var is_dirty = file.get("dirty", false)
	var even     = row_idx % 2 == 0

	# Left: ID cell
	_id_col_vbox.add_child(_make_id_cell(file, is_dirty, even))
	_id_col_vbox.add_child(_hsep())

	# Right: one cell per field — all editable, ExtResource gets special treatment
	var data_row = HBoxContainer.new()
	data_row.custom_minimum_size.y = ROW_HEIGHT
	data_row.add_theme_constant_override("separation", 1)
	if even:
		_apply_bg(data_row, Color(1, 1, 1, 0.03))

	for prop in _fields:
		data_row.add_child(_make_cell(file, prop))

	_data_col_vbox.add_child(data_row)
	_data_col_vbox.add_child(_hsep())

# ── ID cell ───────────────────────────────────────────────────────────────────
func _make_id_cell(file: Dictionary, is_dirty: bool, even: bool) -> Control:
	var row = HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT
	row.add_theme_constant_override("separation", 0)
	if even:
		_apply_bg(row, Color(1, 1, 1, 0.03))

	# Dirty strip
	var strip = ColorRect.new()
	strip.custom_minimum_size  = Vector2(3, 0)
	strip.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	strip.color = Color(0.95, 0.62, 0.1) if is_dirty else Color(0, 0, 0, 0)
	row.add_child(strip)

	if file["type"] == "tres":
		# Clickable name → open in Inspector
		var name_btn = Button.new()
		name_btn.text = "  " + file["name"]
		name_btn.flat = true
		name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_btn.clip_text = true
		name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_btn.add_theme_font_size_override("font_size", 11)
		name_btn.tooltip_text = "Open in Inspector"
		if is_dirty:
			name_btn.add_theme_color_override("font_color", Color(0.95, 0.72, 0.3))
		else:
			name_btn.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
		name_btn.pressed.connect(func():
			inspect_resource_requested.emit(file.get("abs_path", ""))
		)
		row.add_child(name_btn)
	else:
		var lbl = Label.new()
		lbl.text = "  " + file["name"]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.clip_text = true
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		if is_dirty:
			lbl.modulate = Color(0.95, 0.72, 0.3)
		row.add_child(lbl)

	var ren = Button.new()
	ren.text = "✎"; ren.flat = true
	ren.custom_minimum_size = Vector2(22, 22)
	ren.tooltip_text = "Rename"
	ren.pressed.connect(func(): entry_rename_requested.emit(file))
	row.add_child(ren)

	if file["type"] == "tres":
		var dup = Button.new()
		dup.text = "⧉"; dup.flat = true
		dup.custom_minimum_size = Vector2(22, 22)
		dup.tooltip_text = "Duplicate"
		dup.pressed.connect(func(): entry_duplicate_requested.emit(file))
		row.add_child(dup)

	var del = Button.new()
	del.text = "✕"; del.flat = true
	del.custom_minimum_size = Vector2(22, 22)
	del.tooltip_text = "Delete"
	del.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	del.pressed.connect(func(): entry_delete_requested.emit(file))
	row.add_child(del)

	return row

# ── Per-field cell: editable or ExtResource badge ────────────────────────────
func _make_cell(file: Dictionary, prop: String) -> Control:
	var val        = file["data"].get(prop)
	var field_type = _gd_parser.get_field_type(file, prop, _store)
	var hint       = _gd_parser.get_hint(file, prop, _store)
	# Field absent from .tres means Godot stored the GDScript default — use it for display
	if val == null and hint.has("default"):
		val = hint["default"]
	var hi         = _validator.has_issue(file, prop)
	var hw         = _validator.has_warning(file, prop)

	# Outer box: fixed width = COL_WIDTH, never expands beyond it
	var outer = HBoxContainer.new()
	outer.custom_minimum_size = Vector2(COL_WIDTH, ROW_HEIGHT)
	outer.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	outer.clip_contents = true
	outer.add_theme_constant_override("separation", 0)

	# Left border strip for validation state
	if hi or hw:
		var strip = ColorRect.new()
		strip.custom_minimum_size = Vector2(2, 0)
		strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
		strip.color = Color(1.0, 0.3, 0.3) if hi else Color(1.0, 0.78, 0.2)
		outer.add_child(strip)

	# Padding wrapper
	var pad = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 4)
	pad.add_theme_constant_override("margin_right", 4)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	outer.add_child(pad)

	# ExtResource / SubResource → show ref badge + open button
	if typeof(val) == TYPE_STRING and _is_ext_ref(val):
		pad.add_child(_make_extref_cell(val, file))
		return outer

	# Bool fields: build CheckButton here so we can use the already-injected `val`
	if field_type == "bool":
		var btn = CheckButton.new()
		btn.button_pressed = true if val else false
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		btn.toggled.connect(func(v): _on_value_changed(file, prop, v))
		pad.add_child(btn)
		return outer

	# Collection fields (Array[String], Array, Dictionary declared in .gd) → always show button
	if field_type == "collection":
		var btn = Button.new()
		var raw = file["data"].get(prop)
		if raw != null and typeof(raw) == TYPE_STRING and raw.strip_edges() != "":
			btn.text = _CellRenderer._collection_label(raw)
		else:
			btn.text = "[ empty ]"
			btn.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = true
		btn.flat = true
		btn.tooltip_text = raw if raw != null else "Click to edit"
		btn.pressed.connect(func(): collection_open_requested.emit(file, prop, _group_files))
		pad.add_child(btn)
		return outer

	# Raw Godot collection value in data (e.g. [{...}], {...}) from sibling entries
	var is_null_collection = (val == null or (typeof(val) == TYPE_STRING and (val as String) in ["", "—"])) and \
		_prop_is_collection(prop)
	if is_null_collection:
		var btn = Button.new()
		btn.text = "[ empty ]"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = true
		btn.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2))
		btn.flat = true
		btn.tooltip_text = "Click to add items"
		btn.pressed.connect(func(): collection_open_requested.emit(file, prop, _group_files))
		pad.add_child(btn)
		return outer

	# Normal editable cell via CellRenderer — pass injected val so default is shown correctly
	var cell = _CellRenderer.make_cell(
		file, prop, field_type, hint, hi, hw,
		func(v): _on_value_changed(file, prop, v),
		func(): multiline_open_requested.emit(file, prop),
		func(): collection_open_requested.emit(file, prop, _group_files),
		val
	)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	pad.add_child(cell)
	return outer

# Returns true when prop holds collection values in at least one sibling entry.
# Used to show "[ empty ]" button for null slots so user can open CollectionDialog.
func _prop_is_collection(prop: String) -> bool:
	for f in _group_files:
		var v = f["data"].get(prop)
		if typeof(v) == TYPE_STRING and v != "" and v != "—":
			if _CellRenderer.is_raw_godot_value(v):
				return true
	return false

# ── ExtResource / SubResource cell ───────────────────────────────────────────
static func _is_ext_ref(s: String) -> bool:
	return s.begins_with("ExtResource(") or s.begins_with("SubResource(")

func _make_extref_cell(val: String, file: Dictionary) -> Control:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Icon badge
	var badge = Label.new()
	badge.text = "⬡"
	badge.modulate = Color(0.5, 0.7, 1.0)
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(badge)

	# Short label showing the ref ID
	var inner = val.trim_prefix("ExtResource(").trim_prefix("SubResource(").trim_suffix(")")
	var lbl = Label.new()
	lbl.text = inner.trim_prefix('"').trim_suffix('"')
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.modulate = Color(0.6, 0.6, 0.6)
	lbl.clip_text = true
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.tooltip_text = val
	box.add_child(lbl)

	# Open in Inspector button — loads the parent .tres in Godot Inspector
	var open_btn = Button.new()
	open_btn.text = "↗"
	open_btn.flat = true
	open_btn.custom_minimum_size = Vector2(22, 22)
	open_btn.tooltip_text = "Open resource in Inspector"
	open_btn.pressed.connect(func():
		inspect_resource_requested.emit(file.get("abs_path", ""))
	)
	box.add_child(open_btn)

	return box

# ── Helpers ───────────────────────────────────────────────────────────────────
func _apply_bg(node: Control, color: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	node.add_theme_stylebox_override("panel", sb)

func _hsep() -> Control:
	var s = HSeparator.new()
	s.add_theme_constant_override("separation", 0)
	return s

func _on_value_changed(file: Dictionary, prop: String, new_val) -> void:
	var field_type = _gd_parser.get_field_type(file, prop, _store)
	match field_type:
		"bool":
			file["data"][prop] = bool(new_val)
		"number":
			if typeof(new_val) == TYPE_STRING:
				file["data"][prop] = (new_val as String).to_float() \
					if (new_val as String).is_valid_float() else new_val
			else:
				file["data"][prop] = new_val
		_:
			var t = _store.get_original_type(file["id"], prop)
			if t == "boolean":
				file["data"][prop] = bool(new_val)
			elif t == "number":
				if typeof(new_val) == TYPE_STRING:
					file["data"][prop] = (new_val as String).to_float() \
						if (new_val as String).is_valid_float() else new_val
				else:
					file["data"][prop] = new_val
			else:
				file["data"][prop] = new_val
	_store.mark_dirty(file)
	file_changed.emit(file)

func refresh() -> void:
	_fields = _get_fields(_group_files)
	_build_ui()
