class_name CustomResource extends Resource

func to_dic() -> Dictionary:
	var dict = {}
	var property_list = get_property_list()
	for property in property_list:
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0:
			var property_name = property.name
			var value = get(property_name)
			if typeof(value) == 28:
				var temp = []
				for obj in value:
					if obj is Dictionary:
						temp.append(obj)
				dict[property_name] = temp
			else:
				dict[property_name] = value
	return dict

func from_dic(dict: Dictionary) -> void:
	if not dict:
		return
	
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0:
			var property_name = property.name
			if dict.has(property_name):
				var value = dict[property_name]
				if value:
					set(property_name, value)
