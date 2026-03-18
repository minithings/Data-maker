class_name QuestData extends CustomResource

@export_group("Thông tin nhiệm vụ")
@export var code: String
@export var name: String
@export_multiline var description: String
@export var type: String # "main", "side", "daily", ...

@export_group("Điều kiện hoàn thành")
@export var requirements: Dictionary[String, float]

@export_group("Phần thưởng")
@export var rewards: Dictionary[String, float]
@export var reward_items: Dictionary[String, int] = {}

@export_group("Mở khóa")
@export var unlock_npc: Array[String] = []
@export var unlock_area: Array[String] = []
@export var next_quest_code: String = ""

@export_group("Điều kiện đặc biệt")
@export var only_at_night: bool = false
@export var only_when_rain: bool = false
@export var time_limit: int = -1 # Số ngày phải hoàn thành, -1 là không giới hạn
