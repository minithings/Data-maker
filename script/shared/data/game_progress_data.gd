class_name GameProgressData extends Resource

@export var unlocked_achievements: Array[String] = []
@export var unlocked_buildings: Array[String] = []
@export var completed_quests: Array[String] = []
@export var world_states: Dictionary = {}

func unlock_achievement(id: String) -> void:
	if not unlocked_achievements.has(id):
		unlocked_achievements.append(id)

func unlock_building(id: String) -> void:
	if not unlocked_buildings.has(id):
		unlocked_buildings.append(id)

func complete_quest(id: String) -> void:
	if not completed_quests.has(id):
		completed_quests.append(id)

func is_achievement_unlocked(id: String) -> bool:
	return unlocked_achievements.has(id)

func is_building_unlocked(id: String) -> bool:
	return unlocked_buildings.has(id)

func is_quest_completed(id: String) -> bool:
	return completed_quests.has(id)

func set_world_state(key: String, value: Variant) -> void:
	world_states[key] = value

func get_world_state(key: String) -> Variant:
	return world_states.get(key, null)

func to_dic() -> Dictionary:
	return {
		"unlocked_achievements": unlocked_achievements.duplicate(),
		"unlocked_buildings":    unlocked_buildings.duplicate(),
		"completed_quests":      completed_quests.duplicate(),
		"world_states":          world_states.duplicate()
	}

func from_dic(data: Dictionary) -> void:
	if data.has("unlocked_achievements"):
		unlocked_achievements = Array(data["unlocked_achievements"].duplicate(), TYPE_STRING, "", null)
	if data.has("unlocked_buildings"):
		unlocked_buildings = Array(data["unlocked_buildings"].duplicate(), TYPE_STRING, "", null)
	if data.has("completed_quests"):
		completed_quests = Array(data["completed_quests"].duplicate(), TYPE_STRING, "", null)
	if data.has("world_states"):
		world_states = data["world_states"].duplicate()
	# Tương thích ngược với key cũ "world_state"
	elif data.has("world_state"):
		world_states = data["world_state"].duplicate()
