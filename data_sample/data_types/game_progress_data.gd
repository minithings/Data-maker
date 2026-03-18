class_name GameProgressData extends Resource

@export var unlocked_achievements: Array[String] = []
@export var unlocked_buildings: Array[String] = []
@export var completed_quests: Array[String] = []
@export var world_state: Dictionary = {}

func unlock_achievement(id: String) -> void:
	if not unlocked_achievements.has(id):
		unlocked_achievements.append(id)

func unlock_building(id: String) -> void:
	if not unlocked_buildings.has(id):
		unlocked_buildings.append(id)

func complete_quest(id: String) -> void:
	if not completed_quests.has(id):
		completed_quests.append(id)

func set_world_state(key: String, value) -> void:
	world_state[key] = value

func get_world_state(key: String):
	return world_state.get(key, null)

func to_dic()->Dictionary:
	var result:Dictionary = {}
	result["unlocked_achievements"] = unlocked_achievements
	result["unlocked_buildings"] = unlocked_buildings
	result["completed_quests"] = completed_quests
	result["world_state"] = world_state 
	return result

func from_dic(data:Dictionary):
	if data.get("unlocked_achievements"):
		unlocked_achievements = data.unlocked_achievements
	
	if data.get("unlocked_buildings"):
		unlocked_buildings = data.unlocked_buildings
	
	if data.get("completed_quests"):
		completed_quests = data.completed_quests
	
	if data.get("world_state"):
		world_state = data.world_state
