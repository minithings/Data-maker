class_name AchievementData extends CustomResource

# ============ IDENTITY ============
@export var code: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon_emoji: String = "🏆" # emoji fallback khi chưa có Texture
@export var category: String = "" # "farming" | "building" | "exploration" | "combat" | "social" | "progression"

# ============ UNLOCK CONDITION ============
# Loại điều kiện tự động check
# "stat"       — stat_key >= stat_value
# "research"   — research code đã unlock
# "building"   — building code đã xây
# "skill"      — skill code đã học
# "quest"      — quest code đã hoàn thành
# "village_level" — village level >= stat_value
# "manual"     — chỉ unlock bằng code (event đặc biệt)
@export var condition_type: String = "manual"
@export var condition_key: String = "" # tên stat / code research / building...
@export var condition_value: int = 1 # ngưỡng số (với stat / village_level)

# ============ DISPLAY ============
@export var secret: bool = false # ẩn tên/mô tả cho đến khi unlock
@export var sort_order: int = 0 # sắp xếp trong panel (nhỏ hơn = trên đầu)
