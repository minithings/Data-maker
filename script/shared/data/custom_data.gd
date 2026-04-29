class_name CustomResource extends Resource

func to_dic() -> Dictionary:
	var dict: Dictionary = {}
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var property_name: String = property.name
		var value = get(property_name)
		if typeof(value) == TYPE_ARRAY:
			var temp: Array = []
			for item in value:
				if item is Resource:
					temp.append(item.to_dic() if item.has_method("to_dic") else {})
				elif item is Dictionary or item is String or item is int or item is float or item is bool:
					temp.append(item)
				# Các kiểu khác (Vector2, Color...) bỏ qua hoặc convert tùy nhu cầu
			dict[property_name] = temp
		else:
			dict[property_name] = value
	return dict

func from_dic(dict: Dictionary) -> void:
	if not dict:
		return
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var property_name: String = property.name
		if dict.has(property_name):
			var value = dict[property_name]
			if value != null:
				set(property_name, value)
