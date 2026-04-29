class_name ItemStatData extends CustomResource

var item_id: String = ""
@export var code: String = ""
@export var stats: Dictionary = {}
@export var quality: String = "normal"
@export var extra_data: Dictionary = {}

func _init(context_data: Dictionary = {}) -> void:
	if not context_data.is_empty():
		stats      = context_data.get("stats", {})
		quality    = context_data.get("quality", "normal")
		extra_data = context_data.get("extra_data", {})

func to_dic() -> Dictionary:
	return {
		"item_id": item_id,
		"code": code,
		"stats": stats,
		"quality": quality,
		"extra_data": extra_data
	}

func from_dic(data: Dictionary) -> void:
	item_id    = data.get("item_id", "")
	code       = data.get("code", "")
	stats      = data.get("stats", {})
	quality    = data.get("quality", "normal")
	extra_data = data.get("extra_data", {})
