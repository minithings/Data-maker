class_name ItemStatData extends CustomResource

var item_id: String = ""
@export var code:String=""
@export var stats: Dictionary = {} # VD: { "attack": 15, "crit": 3 }
@export var quality: String = "normal"
@export var extra_data: Dictionary = {}

func _init(context_data=null):
	if context_data:
		stats = context_data.get("stats",{})
		quality = context_data.get("quality","normal")
		extra_data = context_data.get("extra_data",{})
