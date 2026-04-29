@tool
extends RefCounted
class_name CellRenderer

const _GODOT_TYPES: Array = [
	"ExtResource", "SubResource", "Rect2", "Rect2i",
	"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i",
	"Color", "Transform2D", "Transform3D", "Basis", "Quaternion",
	"Plane", "AABB", "NodePath",
	"PackedByteArray", "PackedInt32Array", "PackedInt64Array",
	"PackedFloat32Array", "PackedFloat64Array", "PackedStringArray",
	"PackedVector2Array", "PackedVector3Array", "PackedColorArray"
]

# Detect Godot-native raw string values (ExtResource, Color(...), Vector2(...), etc.)
static func is_raw_godot_value(v) -> bool:
	if typeof(v) != TYPE_STRING:
		return false
	var s: String = v
	for gt in _GODOT_TYPES:
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

# ── Detect editable native types ─────────────────────────────────────────────
static func _detect_native(val: String) -> String:
	if val.begins_with("Color("):   return "Color"
	if val.begins_with("Vector2("): return "Vector2"
	if val.begins_with("Vector3("): return "Vector3"
	if val.begins_with("Vector4("): return "Vector4"
	return ""

# ── Parse Color(r, g, b, a) → Color ─────────────────────────────────────────
static func _parse_color(s: String) -> Color:
	var inner = s.trim_prefix("Color(").trim_suffix(")")
	var parts = inner.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() >= 4 else 1.0)
	return Color.WHITE

# ── Parse Vector*(x, y[, z[, w]]) → PackedFloat32Array ──────────────────────
static func _parse_vector(s: String) -> PackedFloat32Array:
	var inner = s.substr(s.find("(") + 1).trim_suffix(")")
	var parts = inner.split(",")
	var out: PackedFloat32Array = []
	for p in parts:
		out.append(float(p.strip_edges()))
	return out

# ═════════════════════════════════════════════════════════════════════════════
# Main factory
# ═════════════════════════════════════════════════════════════════════════════
static func make_cell(
	file: Dictionary, prop: String,
	field_type: String, hint: Dictionary,
	has_issue: bool, has_warning: bool,
	on_change: Callable, on_multiline: Callable, on_collection: Callable,
	injected_val
) -> Control:
	var val = injected_val

	match field_type:
		"multiline":
			return _make_multiline_cell(val, on_multiline)
		"bool":
			return _make_bool_cell(val, on_change)
		"enum":
			return _make_enum_cell(val, hint.get("options", []), false, on_change)
		"export_enum":
			return _make_enum_cell(val, hint.get("options", []), true, on_change)

	# Default / raw godot
	if typeof(val) == TYPE_STRING:
		var native = _detect_native(val)
		match native:
			"Color":
				return _make_color_cell(val, on_change)
			"Vector2":
				return _make_vector_cell(val, 2, on_change)
			"Vector3":
				return _make_vector_cell(val, 3, on_change)
			"Vector4":
				return _make_vector_cell(val, 4, on_change)

		if is_raw_godot_value(val):
			return _make_collection_cell(val, on_collection)

	return _make_text_cell(val, has_issue, has_warning, on_change)

# ── Multiline ──────────────────────────────────────────────────────────────
static func _make_multiline_cell(val, on_multiline: Callable) -> Control:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var lbl = LineEdit.new()
	lbl.text     = str(val) if val != null else ""
	lbl.editable = false
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.tooltip_text = lbl.text
	lbl.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			on_multiline.call()
	)
	box.add_child(lbl)

	var btn = Button.new()
	btn.text = "⤢"
	btn.flat = true
	btn.custom_minimum_size = Vector2(26, 0)
	btn.tooltip_text = "Edit multiline"
	btn.pressed.connect(on_multiline)
	box.add_child(btn)
	return box

# ── Bool ───────────────────────────────────────────────────────────────────
static func _make_bool_cell(val, on_change: Callable) -> Control:
	var btn = CheckButton.new()
	btn.button_pressed = true if val else false
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.toggled.connect(func(v): on_change.call(v))
	return btn

# ── Enum / ExportEnum ──────────────────────────────────────────────────────
static func _make_enum_cell(val, options: Array, is_export: bool, on_change: Callable) -> Control:
	var opt = OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.fit_to_longest_item = false
	for i in options.size():
		opt.add_item(str(options[i]), i)
	if is_export:
		for i in options.size():
			if str(options[i]) == str(val):
				opt.select(i)
				break
	else:
		if typeof(val) in [TYPE_INT, TYPE_FLOAT]:
			opt.select(clampi(int(val), 0, options.size() - 1))
	opt.item_selected.connect(func(idx):
		on_change.call(options[idx] if is_export else idx)
	)
	return opt

# ── Collection (raw Godot array / dict value) ─────────────────────────────
static func _make_collection_cell(val, on_collection: Callable) -> Control:
	var btn = Button.new()
	btn.text = _collection_label(str(val))
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.clip_text = true
	btn.tooltip_text = str(val)
	btn.pressed.connect(on_collection)
	return btn

# ── Color (native Godot Color type) ───────────────────────────────────────
static func _make_color_cell(val: String, on_change: Callable) -> Control:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var picker = ColorPickerButton.new()
	picker.color = _parse_color(val)
	picker.custom_minimum_size = Vector2(60, 0)
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.edit_alpha = true
	picker.color_changed.connect(func(c: Color):
		on_change.call("Color(%s, %s, %s, %s)" % [
			_fmt(c.r), _fmt(c.g), _fmt(c.b), _fmt(c.a)
		])
	)
	box.add_child(picker)
	return box

# ── Vector2 / Vector3 / Vector4 ───────────────────────────────────────────
static func _make_vector_cell(val: String, components: int, on_change: Callable) -> Control:
	var comps = _parse_vector(val)
	while comps.size() < components:
		comps.append(0.0)

	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var labels = ["X", "Y", "Z", "W"]
	var spins: Array = []

	for i in components:
		var lbl = Label.new()
		lbl.text = labels[i]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.custom_minimum_size = Vector2(12, 0)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(lbl)

		var spin = SpinBox.new()
		spin.value = comps[i]
		spin.step = 0.001
		spin.min_value = -1e9
		spin.max_value = 1e9
		spin.allow_greater = true
		spin.allow_lesser = true
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.custom_minimum_size = Vector2(52, 0)
		spins.append(spin)
		box.add_child(spin)

	# Emit on any spin change
	for i in components:
		spins[i].value_changed.connect(func(_v):
			var vals = PackedFloat32Array()
			for s in spins: vals.append(s.value)
			match components:
				2: on_change.call("Vector2(%s, %s)" % [_fmt(vals[0]), _fmt(vals[1])])
				3: on_change.call("Vector3(%s, %s, %s)" % [_fmt(vals[0]), _fmt(vals[1]), _fmt(vals[2])])
				4: on_change.call("Vector4(%s, %s, %s, %s)" % [_fmt(vals[0]), _fmt(vals[1]), _fmt(vals[2]), _fmt(vals[3])])
		)

	return box

# ── Plain text / number ────────────────────────────────────────────────────
static func _make_text_cell(val, has_issue: bool, has_warning: bool, on_change: Callable) -> Control:
	var edit = LineEdit.new()
	edit.text = str(val) if val != null else ""
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.placeholder_text = "—"

	if has_issue:
		edit.modulate = Color(1.0, 0.45, 0.45)
		edit.tooltip_text = "Type mismatch"
	elif has_warning:
		edit.modulate = Color(1.0, 0.82, 0.35)
		edit.tooltip_text = "Empty value"

	edit.text_submitted.connect(func(t): on_change.call(t))
	edit.focus_exited.connect(func(): on_change.call(edit.text))
	return edit

# ── Helpers ────────────────────────────────────────────────────────────────
static func _fmt(f: float) -> String:
	# Compact float: strip trailing zeros
	var s = "%.4f" % f
	while s.ends_with("0") and not s.ends_with(".0"):
		s = s.left(s.length() - 1)
	return s

static func _collection_label(v: String) -> String:
	var s = v.strip_edges()
	# Array of dicts: [{...}]
	if s.begins_with("[{"):
		return "[ {…} ]"
	# Plain dict: {...}
	if s.begins_with("{"):
		return "{ … }"
	# Typed Dictionary[K,V]({...})
	if s.begins_with("Dictionary["):
		var i0 = s.find("({")
		var i1 = s.rfind("})")
		if i0 != -1 and i1 != -1:
			var inner = s.substr(i0 + 2, i1 - i0 - 2).strip_edges()
			if inner == "":
				return "{ empty }"
			# Count keys by counting quoted key patterns: "key":
			var count = 0
			var search_from = 0
			while true:
				var pos = inner.find('": ', search_from)
				if pos == -1:
					pos = inner.find('":', search_from)
				if pos == -1:
					break
				count += 1
				search_from = pos + 2
			if count == 0:
				count = 1
			return "{ %d key%s }" % [count, "s" if count != 1 else ""]
		return "{ … }"
	# Typed Array[X]([...])
	if "Array[" in s:
		var i0 = s.find("([")
		var i1 = s.rfind("])")
		if i0 != -1 and i1 != -1:
			var inner = s.substr(i0 + 2, i1 - i0 - 2).strip_edges()
			if inner == "":
				return "[ empty ]"
			var parts = inner.split(",")
			var preview = ""
			for i in min(3, parts.size()):
				if i > 0: preview += ", "
				preview += parts[i].strip_edges().trim_prefix('"').trim_suffix('"')
			if parts.size() > 3:
				preview += " +%d" % (parts.size() - 3)
			return "[ %s ]" % preview
	return v.left(28) + ("…" if v.length() > 28 else "")
