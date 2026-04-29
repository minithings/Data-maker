class_name ItemSeedData extends ItemData

@export_group("Nông Nghiệp")
@export var crop_code: String = ""
@export var tool_type: String = "seed_bag"

func get_type_item() -> String:
	return "seed"
