@tool
extends RefCounted

var _re_class_name: RegEx
var _re_extends: RegEx
var _re_enum: RegEx
var _re_var: RegEx
var _re_export_enum: RegEx

func _init() -> void:
	_re_class_name = RegEx.new()
	_re_class_name.compile(r"class_name\s+(\w+)")

	_re_extends = RegEx.new()
	_re_extends.compile(r'extends\s+(?:"res://([^"]+)"|(\w+))')

	_re_enum = RegEx.new()
	_re_enum.compile(r"enum\s+(\w+)\s*\{([^}]+)\}")

	_re_var = RegEx.new()
	_re_var.compile(r"var\s+(\w+)")

	_re_export_enum = RegEx.new()
	_re_export_enum.compile(r"\(([^)]+)\)")

func parse_gdscript(content: String, filename: String, store) -> void:
	var hints: Dictionary = {}
	var enums: Dictionary = {}

	var cm = _re_class_name.search(content)
	if cm:
		store.class_map[cm.get_string(1)] = filename

	var em = _re_extends.search(content)
	var parent: String = ""
	if em:
		if em.get_string(1) != "":
			parent = em.get_string(1).split("/")[-1]
		else:
			parent = em.get_string(2)

	for m in _re_enum.search_all(content):
		var enum_name = m.get_string(1)
		var raw = m.get_string(2)
		var values: Array[String] = []
		for part in raw.split(","):
			var v = part.strip_edges().split("=")[0].strip_edges()
			if v != "":
				values.append(v)
		enums[enum_name] = values

	for line in content.split("\n"):
		var t = line.strip_edges()
		var vm = _re_var.search(t)
		if not vm:
			continue
		var var_name = vm.get_string(1)

		if "@export_multiline" in t:
			hints[var_name] = { "type": "multiline" }
		elif "@export_enum" in t:
			var em2 = _re_export_enum.search(t)
			if em2:
				var opts: Array[String] = []
				for o in em2.get_string(1).split(","):
					opts.append(o.strip_edges().trim_prefix('"').trim_suffix('"').trim_prefix("'").trim_suffix("'"))
				hints[var_name] = { "type": "export_enum", "options": opts }
		elif ": bool" in t or "= true" in t or "= false" in t:
			hints[var_name] = { "type": "bool" }
		elif ": int" in t or ": float" in t:
			hints[var_name] = { "type": "number" }
		else:
			for enum_name in enums:
				if (": %s" % enum_name) in t:
					hints[var_name] = { "type": "enum", "options": enums[enum_name] }
					break

	store.scripts[filename] = { "hints": hints, "parent": parent }

func get_hint(file: Dictionary, prop: String, store) -> Dictionary:
	var h: Dictionary = {}
	var cur = file.get("script_name", "")
	var depth = 0
	while cur != "" and depth < 10:
		var si = store.scripts.get(cur)
		if si == null:
			si = store.scripts.get(store.class_map.get(cur, ""), null)
		if si == null:
			break
		var merged: Dictionary = {}
		for k in si["hints"]:
			merged[k] = si["hints"][k]
		for k in h:
			merged[k] = h[k]
		h = merged
		cur = si.get("parent", "")
		depth += 1
	return h.get(prop, { "type": "default" })

func get_field_type(file: Dictionary, prop: String, store) -> String:
	var hint = get_hint(file, prop, store)
	if hint["type"] != "default":
		return hint["type"]
	var type_in_meta = store.get_original_type(file["id"], prop)
	if type_in_meta == "number":
		return "number"
	if type_in_meta == "boolean":
		return "bool"
	var val = file["data"].get(prop)
	if typeof(val) == TYPE_BOOL:
		return "bool"
	return "default"
