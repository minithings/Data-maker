class_name QuestData extends CustomResource

@export_group("Thông tin nhiệm vụ")
@export var code: String
@export var name: String
@export_multiline var description: String
@export var type: String # "main" | "side" | "daily" | "tutor" | "explore" | "hunt" | "social"

@export_group("Điều kiện mở quest")
## Quest phải hoàn thành trước khi quest này có thể bắt đầu
@export var required_quests: Array[String] = []
## Level tối thiểu của player
@export var required_level: int = 0

@export_group("Điều kiện hoàn thành")
## Key = action code, value = số lần cần thực hiện
## Ví dụ: { "harvest_wheat": 5.0, "catch_fish": 3.0 }
@export var requirements: Dictionary[String, float]

@export_group("Phần thưởng")
## Key = reward type ("gold", "exp", hoặc bất kỳ key nào RewardSystem hỗ trợ)
@export var rewards: Dictionary[String, float]
## Key = item_code, value = số lượng
@export var reward_items: Dictionary[String, int] = {}

@export_group("Mở khóa")
@export var unlock_npc: Array[String] = []
@export var unlock_area: Array[String] = []
## Một hoặc nhiều quest tự động bắt đầu sau khi hoàn thành quest này
@export var next_quest_codes: Array[String] = [] # FIX: thay next_quest_code: String → Array hỗ trợ branching

@export_group("Điều kiện đặc biệt")
@export var only_at_night: bool = false
@export var only_when_rain: bool = false
## Số giây cho phép (-1 = không giới hạn)
@export var time_limit: int = -1