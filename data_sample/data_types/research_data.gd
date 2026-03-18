class_name ResearchData extends CustomResource

@export var code: String = ""
@export var name: String = ""
@export var description: String = ""
@export var conditions: Dictionary = {
	"gold": 500,
	"item_wood": 20,
	"village_level": 2
}
@export var prerequisites: Array[String] = [] # mã các node cần hoàn thành trước
@export var unlocks_buildings: Array[String] = [] # mã công trình mở khóa
@export var unlocks_skills: Array[String] = [] # mã kỹ năng mở khóa
@export var unlocks_knowledges: Array[String] = [] # mã học thức mở khóa
@export var children: Array[String] = [] # các node con (nếu muốn cây lồng nhau)

func can_research(unlocked_nodes: Dictionary,context_data:Dictionary) -> bool:
	var player = context_data.get("player",{})
	var village = context_data.get("village",{})
	# Kiểm tra prerequisite
	for pre in prerequisites:
		if not unlocked_nodes.get(pre, false):
			return false
	# Kiểm tra điều kiện khác
	for key in conditions.keys():
		var value = conditions[key]
		match key:
			"gold":
				if player.gold < value:
					return false
			"item_wood":
				if player.get_item_count("wood") < value:
					return false
			"village_level":
				if village.level < value:
					return false
			# Thêm các điều kiện khác nếu cần
	return true
