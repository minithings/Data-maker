class_name AnimalData extends CustomResource

@export_group("Identity")
@export var code: String
@export var name: String
@export_enum("livestock", "wild", "pet", "bug") var type: String
@export var max_age: int = 100

@export_group("Visuals Adult")
@export var texture_adult: Texture2D
@export var hframes: int = 4
@export var vframes: int = 8

@export_group("Visuals Baby")
@export var texture_baby: Texture2D
@export var baby_hframes: int = 4
@export var baby_vframes: int = 4

@export_group("Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 50.0
@export var growth_days: int = 5

@export_group("Production & Loot")
# herbivore: chỉ ăn cỏ, carnivore: chỉ ăn thịt, omnivore: ăn cả 2
@export_enum("herbivore", "carnivore", "omnivore") var diet_type: String = "herbivore"
@export var product_item: Array[LootData]
# Chu kỳ sản xuất (tính bằng ngày)
@export var product_interval: int = 1
@export var required_tool: ItemData
# Món đồ rớt ra khi con vật bị chết (hoặc bị thịt)
@export var drop_item: Array[LootData]
