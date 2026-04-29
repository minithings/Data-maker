@tool
extends Window
class_name CollectionDialog

signal collection_saved(file: Dictionary, prop: String, raw_value: String)

var _file: Dictionary
var _prop: String
var _kind: String
var _godot_type: String
var _items: Array = []        # For array_string / array_number
var _pairs: Array = []        # For dict: [{k, v}]
var _array_dicts: Array = []  # For array_dict: [[{k,v},...],...]

var _body_container: VBoxContainer
var _preview_label: Label

func _ready() -> void:
	hide()
	title = "Collection Editor"
	size = Vector2(680, 520)
	wrap_controls = true
	close_requested.connect(func(): hide())

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	add_child(vbox)

	# Header info
	var hdr = HBoxContainer.new()
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.add_theme_font_size_override("font_size", 11)
	hdr.add_child(type_label)
	vbox.add_child(hdr)

	# Body area (scrollable)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_body_container = VBoxContainer.new()
	_body_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body_container)

	# Footer
	var footer = HBoxContainer.new()
	_preview_label = Label.new()
	_preview_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_label.add_theme_font_size_override("font_size", 10)
	footer.add_child(_preview_label)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func(): hide())
	footer.add_child(cancel_btn)

	var apply_btn = Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(_on_apply)
	footer.add_child(apply_btn)
	vbox.add_child(footer)

func open_for(file: Dictionary, prop: String, group_files: Array = []) -> void:
	_file = file
	_prop = prop
	var v = str(file["data"].get(prop, ""))

	# When this entry has an empty/null value, infer kind + godot_type from a sibling
	var effective_v = v
	if effective_v.strip_edges() == "" or effective_v == "null":
		for sibling in group_files:
			if sibling["id"] == file["id"]:
				continue
			var sv = str(sibling["data"].get(prop, ""))
			if sv.strip_edges() != "" and sv != "null":
				effective_v = sv
				break

	_kind = _detect_kind(effective_v)
	_godot_type = _extract_type_label(effective_v)

	# Start with empty data since this entry has no value yet
	var is_empty_entry = v.strip_edges() == "" or v == "null"
	if is_empty_entry:
		_items = []
		_pairs = []
		_array_dicts = []
	else:
		_items = _extract_array_items(v) if _kind in ["array_string", "array_number"] else []
		_pairs = _parse_dict_pairs(_extract_dict_inner(v)) if _kind == "dict" else []
		_array_dicts = _parse_array_dicts(v) if _kind == "array_dict" else []

	title = "Collection Editor — %s" % prop
	var type_label = get_node("VBoxContainer/HBoxContainer/TypeLabel")
	if type_label:
		type_label.text = "%s  [%s]" % [_godot_type, _kind]

	_rebuild_body()
	_update_preview()
	popup_centered()

func _rebuild_body() -> void:
	for c in _body_container.get_children():
		c.queue_free()

	match _kind:
		"array_string", "array_number":
			_build_array_body()
		"dict":
			_build_dict_body()
		"array_dict":
			_build_array_dict_body()
		_:
			_build_raw_picker()

func _build_array_body() -> void:
	for i in _items.size():
		var row = HBoxContainer.new()
		var idx_label = Label.new()
		idx_label.text = str(i)
		idx_label.custom_minimum_size.x = 28
		row.add_child(idx_label)
		var edit = LineEdit.new()
		edit.text = str(_items[i])
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured_i = i
		edit.text_changed.connect(func(t): _items[captured_i] = t; _update_preview())
		row.add_child(edit)
		var del_btn = Button.new()
		del_btn.text = "✕"
		var captured_i2 = i
		del_btn.pressed.connect(func(): _items.remove_at(captured_i2); _rebuild_body(); _update_preview())
		row.add_child(del_btn)
		_body_container.add_child(row)

	var add_btn = Button.new()
	add_btn.text = "+ Add item"
	add_btn.pressed.connect(func(): _items.append(""); _rebuild_body(); _update_preview())
	_body_container.add_child(add_btn)

func _build_dict_body() -> void:
	# Column headers
	var hdr = HBoxContainer.new()
	var kl = Label.new(); kl.text = "Key"; kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vl = Label.new(); vl.text = "Value"; vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(kl); hdr.add_child(vl); hdr.add_child(Label.new())
	_body_container.add_child(hdr)

	for i in _pairs.size():
		var row = HBoxContainer.new()
		var key_edit = LineEdit.new()
		key_edit.text = str(_pairs[i]["k"])
		key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured_i = i
		key_edit.text_changed.connect(func(t): _pairs[captured_i]["k"] = t; _update_preview())
		row.add_child(key_edit)
		var val_edit = LineEdit.new()
		val_edit.text = str(_pairs[i]["v"])
		val_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val_edit.text_changed.connect(func(t): _pairs[captured_i]["v"] = t; _update_preview())
		row.add_child(val_edit)
		var del_btn = Button.new()
		del_btn.text = "✕"
		del_btn.pressed.connect(func(): _pairs.remove_at(captured_i); _rebuild_body(); _update_preview())
		row.add_child(del_btn)
		_body_container.add_child(row)

	var add_btn = Button.new()
	add_btn.text = "+ Add entry"
	add_btn.pressed.connect(func(): _pairs.append({"k": "", "v": "0"}); _rebuild_body(); _update_preview())
	_body_container.add_child(add_btn)

func _build_array_dict_body() -> void:
	for oi in _array_dicts.size():
		var card = VBoxContainer.new()
		var card_header = HBoxContainer.new()
		var item_label = Label.new()
		item_label.text = "Item %d" % oi
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_header.add_child(item_label)
		var del_item_btn = Button.new()
		del_item_btn.text = "Delete"
		var captured_oi = oi
		del_item_btn.pressed.connect(func(): _array_dicts.remove_at(captured_oi); _rebuild_body(); _update_preview())
		card_header.add_child(del_item_btn)
		card.add_child(card_header)

		for ki in _array_dicts[oi].size():
			var row = HBoxContainer.new()
			var k_edit = LineEdit.new()
			k_edit.text = str(_array_dicts[oi][ki]["k"])
			k_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cap_oi = oi; var cap_ki = ki
			k_edit.text_changed.connect(func(t): _array_dicts[cap_oi][cap_ki]["k"] = t; _update_preview())
			row.add_child(k_edit)
			var v_edit = LineEdit.new()
			v_edit.text = str(_array_dicts[oi][ki]["v"])
			v_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v_edit.text_changed.connect(func(t): _array_dicts[cap_oi][cap_ki]["v"] = t; _update_preview())
			row.add_child(v_edit)
			var del_pair_btn = Button.new()
			del_pair_btn.text = "✕"
			del_pair_btn.pressed.connect(func(): _array_dicts[cap_oi].remove_at(cap_ki); _rebuild_body(); _update_preview())
			row.add_child(del_pair_btn)
			card.add_child(row)

		var add_field_btn = Button.new()
		add_field_btn.text = "+ Add field"
		var cap_oi2 = oi
		add_field_btn.pressed.connect(func(): _array_dicts[cap_oi2].append({"k": "", "v": ""}); _rebuild_body(); _update_preview())
		card.add_child(add_field_btn)
		_body_container.add_child(card)
		_body_container.add_child(HSeparator.new())

	var add_item_btn = Button.new()
	add_item_btn.text = "+ Add item"
	add_item_btn.pressed.connect(func():
		if _array_dicts.size() > 0:
			var template = _array_dicts[0].map(func(p): return {"k": p["k"], "v": ""})
			_array_dicts.append(template)
		else:
			_array_dicts.append([{"k": "", "v": ""}])
		_rebuild_body()
		_update_preview()
	)
	_body_container.add_child(add_item_btn)

func _build_raw_picker() -> void:
	var lbl = Label.new()
	lbl.text = "Unknown collection type. Choose a type to start:"
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_body_container.add_child(lbl)

	var types = [
		["Array[String]",     "array_string"],
		["Array[int]",        "array_number"],
		["Dictionary",        "dict"],
		["Array[Dictionary]", "array_dict"],
	]
	for pair in types:
		var btn = Button.new()
		btn.text = pair[0]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var kind = pair[1]
		var type_label_text = pair[0]
		btn.pressed.connect(func():
			_kind = kind
			_godot_type = type_label_text
			_items = []
			_pairs = []
			_array_dicts = []
			var tl = get_node_or_null("VBoxContainer/HBoxContainer/TypeLabel")
			if tl:
				tl.text = "%s  [%s]" % [_godot_type, _kind]
			_rebuild_body()
			_update_preview()
		)
		_body_container.add_child(btn)

func _update_preview() -> void:
	match _kind:
		"array_string", "array_number":
			_preview_label.text = "%d item(s)" % _items.size()
		"dict":
			_preview_label.text = "%d key(s)" % _pairs.filter(func(p): return p["k"] != "").size()
		"array_dict":
			_preview_label.text = "%d object(s)" % _array_dicts.size()
		_:
			_preview_label.text = "Select a type above"

func _on_apply() -> void:
	var raw = _serialize()
	collection_saved.emit(_file, _prop, raw)
	hide()

func _serialize() -> String:
	match _kind:
		"array_string":
			var filtered = _items.filter(func(s): return s != "")
			var inner = ", ".join(filtered.map(func(s): return '"%s"' % s))
			return "%s([%s])" % [_godot_type, inner]
		"array_number":
			var filtered = _items.filter(func(s): return s != "")
			var inner = ", ".join(filtered)
			return "%s([%s])" % [_godot_type, inner]
		"dict":
			var valid = _pairs.filter(func(p): return p["k"] != "")
			var inner_parts = valid.map(func(p):
				var sv = str(p["v"]).strip_edges()
				var serialized: String
				if sv.is_valid_float():
					serialized = sv
				else:
					serialized = '"%s"' % sv
				return '"%s": %s' % [p["k"], serialized]
			)
			var inner = ", ".join(inner_parts)
			if _godot_type.begins_with("Dictionary"):
				return "%s({ %s })" % [_godot_type, inner]
			return "{ %s }" % inner
		"array_dict":
			var obj_strs = _array_dicts.map(func(pairs):
				var valid = pairs.filter(func(p): return p["k"] != "")
				var inner_parts = valid.map(func(p):
					var num = float(p["v"]) if p["v"].is_valid_float() else 0
					var is_num = p["v"].strip_edges() != "" and p["v"].is_valid_float()
					return '"%s": %s' % [p["k"], p["v"] if is_num else ('"%s"' % p["v"])]
				)
				return "{ %s }" % ", ".join(inner_parts)
			)
			return "[%s]" % ", ".join(obj_strs)
	return str(_file["data"].get(_prop, ""))

# ---- Parsing helpers (mirrors index.html) ----

func _detect_kind(v: String) -> String:
	var t = v.strip_edges()
	if t.to_lower().begins_with("array[string]") or t.to_lower().begins_with("array[nodepath]"):
		return "array_string"
	var re_num = RegEx.new()
	re_num.compile(r"(?i)^Array\[(int|float|double)\]")
	if re_num.search(t) != null:
		return "array_number"
	if t.to_lower().begins_with("dictionary["):
		return "dict"
	# Plain dict: starts with { but is not an array-of-dicts
	if t.begins_with("{"):
		return "dict"
	# Array-of-dicts: [ followed by optional whitespace then {
	var re_ad = RegEx.new()
	re_ad.compile(r"^\[\s*\{")
	if re_ad.search(t) != null:
		return "array_dict"
	return "raw"

func _extract_type_label(v: String) -> String:
	var t = v.strip_edges()
	var re = RegEx.new()
	re.compile(r"^([A-Za-z]+\[[^\]]+\])")
	var m = re.search(t)
	if m:
		return m.get_string(1)
	if t.begins_with("{"):
		return "Dictionary"
	var re_ad = RegEx.new()
	re_ad.compile(r"^\[\s*\{")
	if re_ad.search(t) != null:
		return "Array[Dictionary]"
	return ""

func _extract_array_items(v: String) -> Array:
	var re = RegEx.new()
	re.compile(r"\(\[([\s\S]*)\]\)\s*$")
	var m = re.search(v)
	if not m or m.get_string(1).strip_edges() == "":
		return []
	var result: Array = []
	for part in m.get_string(1).split(","):
		var s = part.strip_edges().trim_prefix('"').trim_suffix('"')
		if s != "":
			result.append(s)
	return result

func _extract_dict_inner(v: String) -> String:
	var re_typed = RegEx.new()
	re_typed.compile(r"\(\{([\s\S]*)\}\)\s*$")
	var m = re_typed.search(v)
	if m:
		return m.get_string(1)
	var re_plain = RegEx.new()
	re_plain.compile(r"^\{([\s\S]*)\}\s*$")
	var m2 = re_plain.search(v)
	if m2:
		return m2.get_string(1)
	return ""

func _parse_dict_pairs(inner: String) -> Array:
	var result: Array = []
	if inner.strip_edges() == "":
		return result
	var re = RegEx.new()
	# Group 1 = key, group 2 = quoted string value (may be empty), group 3 = bare value
	re.compile(r'"([^"]+)"\s*:\s*(?:"([^"]*)"|([^,}\s"]+))')
	for m in re.search_all(inner):
		# If group 2 matched (even empty string), value was quoted; else use group 3
		var raw_match = m.get_string(0)
		var colon_pos = raw_match.find(":")
		var after_colon = raw_match.substr(colon_pos + 1).strip_edges()
		var val: String
		if after_colon.begins_with('"'):
			val = m.get_string(2)
		else:
			val = m.get_string(3)
		result.append({"k": m.get_string(1), "v": val})
	return result

func _parse_array_dicts(v: String) -> Array:
	var t = v.strip_edges()
	# Strip exactly one leading [ and one trailing ]
	if t.begins_with("["):
		t = t.substr(1)
	if t.ends_with("]"):
		t = t.substr(0, t.length() - 1)
	t = t.strip_edges()
	if t == "":
		return []
	var obj_strs: Array = []
	var depth = 0
	var start = 0
	for i in t.length():
		var c = t[i]
		if c == "{":
			if depth == 0:
				start = i
			depth += 1
		elif c == "}":
			depth -= 1
			if depth == 0:
				obj_strs.append(t.substr(start, i - start + 1))
	return obj_strs.map(func(s):
		var inner = s.strip_edges()
		if inner.begins_with("{"): inner = inner.substr(1)
		if inner.ends_with("}"): inner = inner.substr(0, inner.length() - 1)
		return _parse_dict_pairs(inner)
	)
