@tool
extends RefCounted
class_name TresParser

const BLACKLIST: Array[String] = [
	"script", "uid", "format", "load_steps", "atlas", "texture",
	"sprite_frames", "icon", "metadata/_custom_type_script"
]

const GODOT_TYPES: Array[String] = [
	"ExtResource", "SubResource", "Rect2", "Rect2i",
	"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i",
	"Color", "Transform2D", "Transform3D", "Basis", "Quaternion",
	"Plane", "AABB", "NodePath",
	"PackedByteArray", "PackedInt32Array", "PackedInt64Array",
	"PackedFloat32Array", "PackedFloat64Array", "PackedStringArray",
	"PackedVector2Array", "PackedVector3Array", "PackedColorArray"
]

var _re_script_ref: RegEx
var _re_script_path: RegEx
var _re_key_line: RegEx

func _init() -> void:
	_re_script_ref = RegEx.new()
	_re_script_ref.compile(r'script\s*=\s*ExtResource\("([^"]+)"\)')

	_re_script_path = RegEx.new()
	_re_script_path.compile(r'path="res://([^"]+)"')

	_re_key_line = RegEx.new()
	_re_key_line.compile(r"^[a-zA-Z_][a-zA-Z0-9_/]*\s*=")

func split_tres(content: String) -> Dictionary:
	var marker = "[resource]"
	var idx = content.find(marker)
	if idx == -1:
		return { "header": content, "body": "" }
	return {
		"header": content.substr(0, idx + marker.length()),
		"body": content.substr(idx + marker.length())
	}

func get_script_name_from_tres(content: String) -> String:
	var sr = _re_script_ref.search(content)
	if not sr:
		return "StaticResource"
	var ref_id = sr.get_string(1)
	for line in content.split("\n"):
		if ('id="%s"' % ref_id) in line and ".gd" in line:
			var pm = _re_script_path.search(line)
			if pm:
				return pm.get_string(1).split("/")[-1]
	return "StaticResource"

func _count_depth(s: String) -> int:
	var d = 0
	for c in s:
		if c in "([{":
			d += 1
		elif c in ")]}":
			d -= 1
	return d

func _is_raw_godot_value(val: String) -> bool:
	for gt in GODOT_TYPES:
		if val.begins_with(gt + "("):
			return true
	if val.begins_with("Array[") and "(" in val:
		return true
	if val.begins_with("Dictionary[") and "(" in val:
		return true
	if val.strip_edges().begins_with("[{"):
		return true
	if val.strip_edges().begins_with("{"):
		return true
	return false

func parse_tres_body(body: String) -> Dictionary:
	# Step 1: Join multiline values
	var lines = body.split("\n")
	var joined: Array[String] = []
	for line in lines:
		var t = line.strip_edges()
		if t == "" or t.begins_with("["):
			joined.append(line)
			continue
		if _re_key_line.search(t) != null:
			joined.append(t)
		elif joined.size() > 0:
			joined[joined.size() - 1] += " " + t

	# Step 2: Parse key = value
	var data: Dictionary = {}
	for line in joined:
		var t = line.strip_edges()
		if t == "" or not "=" in t or t.begins_with("["):
			continue
		var eq_idx = t.find("=")
		var key = t.substr(0, eq_idx).strip_edges()
		var val = t.substr(eq_idx + 1).strip_edges()

		# Skip blacklisted keys and metadata/*
		var key_lower = key.to_lower()
		if BLACKLIST.has(key_lower) or key.begins_with("metadata/"):
			continue

		# Skip built-in Godot types we can't edit
		var skip = false
		for gt in GODOT_TYPES:
			if val.begins_with(gt + "("):
				skip = true
				break
		if skip:
			continue

		# Keep raw Godot collection syntax as-is
		if _is_raw_godot_value(val):
			data[key] = val
			continue

		# Type conversion
		if val.begins_with('"') and val.ends_with('"'):
			data[key] = val.substr(1, val.length() - 2)
		elif val == "true":
			data[key] = true
		elif val == "false":
			data[key] = false
		elif val.is_valid_float():
			var f = val.to_float()
			if val.contains("."):
				data[key] = f
			else:
				data[key] = int(f)
		else:
			data[key] = val

	return data

func serialize_tres_value(v) -> String:
	if typeof(v) == TYPE_BOOL:
		return "true" if v else "false"
	if typeof(v) == TYPE_STRING:
		if _is_raw_godot_value(v):
			return v
		return '"%s"' % v
	return str(v)

func save_tres(file_data: Dictionary) -> void:
	var raw_body: String = file_data.get("raw_body", "")
	var data: Dictionary = file_data["data"]
	var header: String = file_data.get("raw_header", "[gd_resource type=\"Resource\" format=3]\n\n[resource]")

	var lines = raw_body.split("\n")
	var updated: Dictionary = {}
	var new_lines: Array[String] = []
	var depth = 0

	for line in lines:
		var tr = line.strip_edges()
		if depth > 0:
			depth += _count_depth(tr)
			continue
		var km = _re_key_line.search(tr)
		if tr != "" and not tr.begins_with("[") and km != null:
			var k = tr.substr(0, tr.find("=")).strip_edges()
			if data.has(k):
				var vstr = serialize_tres_value(data[k])
				new_lines.append("%s = %s" % [k, vstr])
				updated[k] = true
				var orig_val = tr.substr(tr.find("=") + 1).strip_edges()
				var d = _count_depth(orig_val)
				if d > 0:
					depth = d
			else:
				new_lines.append(line)
				var orig_val = tr.substr(tr.find("=") + 1).strip_edges()
				var d = _count_depth(orig_val)
				if d > 0:
					depth = d
		else:
			new_lines.append(line)

	# Append new keys not in original body
	for k in data:
		if not updated.has(k):
			new_lines.append("%s = %s" % [k, serialize_tres_value(data[k])])

	var clean_body = "\n".join(new_lines)
	# Remove leading newlines, compress triple+ blank lines
	while clean_body.begins_with("\n"):
		clean_body = clean_body.substr(1)
	while "\n\n\n" in clean_body:
		clean_body = clean_body.replace("\n\n\n", "\n\n")
	clean_body = clean_body.rstrip("\n")

	var output = header.rstrip("\n") + "\n" + clean_body + "\n"

	var f = FileAccess.open(file_data["abs_path"], FileAccess.WRITE)
	if f:
		f.store_string(output)
		f.close()
		file_data["raw_body"] = clean_body
