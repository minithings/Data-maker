@tool
extends RefCounted
class_name CellRenderer

# Signals are emitted via callables passed in, not direct signals,
# because cells are created dynamically and need to communicate upward.

static func is_raw_godot_value(v) -> bool:
	if typeof(v) != TYPE_STRING:
		return false
	var s: String = v
	for gt in TresParser.GODOT_TYPES:
		if s.begins_with(gt + "("):
			return true
	if s.begins_with("Array[") and "(" in s:
		return true
	if s.begins_with("Dictionary[") and "(" in s:
		return true
	if s.strip_edges().begins_with("[{"):
		return true
	if s.strip_edges().begins_with("{"):
		return true
	return false

# Returns a Control for the given cell.
# on_change: Callable(new_value) — called when user edits
# on_multiline: Callable() — open multiline dialog
# on_collection: Callable() — open collection dialog
static func make_cell(
	file: Dictionary,
	prop: String,
	field_type: String,
	hint: Dictionary,
	has_issue: bool,
	has_warning: bool,
	on_change: Callable,
	on_multiline: Callable,
	on_collection: Callable
) -> Control:
	var val = file["data"].get(prop)

	match field_type:
		"multiline":
			return _make_multiline_cell(val, on_multiline)
		"bool":
			return _make_bool_cell(val, on_change)
		"enum":
			return _make_enum_cell(val, hint.get("options", []), false, on_change)
		"export_enum":
			return _make_enum_cell(val, hint.get("options", []), true, on_change)
		_:
			if is_raw_godot_value(val):
				return _make_collection_cell(val, on_collection)
			return _make_text_cell(val, has_issue, has_warning, on_change)

static func _make_multiline_cell(val, on_multiline: Callable) -> Control:
	var hbox = HBoxContainer.new()
	var edit = LineEdit.new()
	edit.text = str(val) if val != null else ""
	edit.editable = false
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.tooltip_text = str(val) if val != null else ""
	edit.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			on_multiline.call()
	)
	hbox.add_child(edit)
	var btn = Button.new()
	btn.text = "⤢"
	btn.custom_minimum_size = Vector2(28, 0)
	btn.pressed.connect(func(): on_multiline.call())
	hbox.add_child(btn)
	return hbox

static func _make_bool_cell(val, on_change: Callable) -> Control:
	var btn = CheckButton.new()
	btn.button_pressed = bool(val)
	btn.toggled.connect(func(v): on_change.call(v))
	return btn

static func _make_enum_cell(val, options: Array, is_export: bool, on_change: Callable) -> Control:
	var opt = OptionButton.new()
	opt.custom_minimum_size.x = 120
	for i in options.size():
		opt.add_item(str(options[i]), i)
	# Set current value
	if is_export:
		for i in options.size():
			if str(options[i]) == str(val):
				opt.select(i)
				break
	else:
		if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
			opt.select(int(val))
		else:
			opt.select(0)
	opt.item_selected.connect(func(idx):
		if is_export:
			on_change.call(options[idx])
		else:
			on_change.call(idx)
	)
	return opt

static func _make_collection_cell(val, on_collection: Callable) -> Control:
	var btn = Button.new()
	btn.text = _get_collection_label(str(val))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func(): on_collection.call())
	return btn

static func _make_text_cell(val, has_issue: bool, has_warning: bool, on_change: Callable) -> Control:
	var edit = LineEdit.new()
	edit.text = str(val) if val != null else ""
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if has_issue:
		edit.modulate = Color(1.0, 0.4, 0.4)
	elif has_warning:
		edit.modulate = Color(1.0, 0.8, 0.3)
	edit.text_changed.connect(func(t): on_change.call(t))
	return edit

static func _get_collection_label(v: String) -> String:
	if v.strip_edges().begins_with("[{"):
		return "[{ ... }]"
	if v.strip_edges().begins_with("{"):
		return "{ ... }"
	if "Array[" in v:
		var inner_start = v.find("([")
		var inner_end = v.rfind("])")
		if inner_start != -1 and inner_end != -1:
			var inner = v.substr(inner_start + 2, inner_end - inner_start - 2)
			var items = inner.split(",")
			var count = items.size() if inner.strip_edges() != "" else 0
			if count == 0:
				return "[ empty ]"
			var preview = ""
			for i in min(3, count):
				if i > 0:
					preview += ", "
				preview += items[i].strip_edges().trim_prefix('"').trim_suffix('"')
			if count > 3:
				preview += ", +%d" % (count - 3)
			return "[ %s ]" % preview
	if "Dictionary[" in v or v.begins_with("{"):
		return "{ ... }"
	return v.substr(0, 28) + ("…" if v.length() > 28 else "")
