class_name AnimalData extends CustomResource

@export_group("Identity")
@export var code: String
@export var name: String
@export_multiline var description: String
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

@export_group("Economy")
@export var buy_price: int = 100

@export_group("Production & Loot")
# herbivore: chỉ ăn cỏ, carnivore: chỉ ăn thịt, omnivore: ăn cả 2
@export_enum("herbivore", "carnivore", "omnivore") var diet_type: String = "herbivore"
@export var product_item: Array[LootData]
# Chu kỳ sản xuất (tính bằng ngày)
@export var product_interval: int = 1
@export var required_tool: ItemData
# Món đồ rớt ra khi con vật bị chết (hoặc bị thịt)
@export var drop_item: Array[LootData]

## Validate dữ liệu sau khi resource được load từ editor/disk.
## Ngăn divide-by-zero và infinite loop do designer đặt giá trị không hợp lệ.
func _validate_data() -> void:
	if max_health <= 0.0:
		push_error("AnimalData [%s]: max_health phải > 0, hiện tại: %s" % [code, max_health])
		max_health = 1.0
	if growth_days <= 0:
		push_error("AnimalData [%s]: growth_days phải > 0, hiện tại: %s" % [code, growth_days])
		growth_days = 1
	if product_interval <= 0:
		push_error("AnimalData [%s]: product_interval phải > 0, hiện tại: %s" % [code, product_interval])
		product_interval = 1
	if max_age <= 0:
		push_error("AnimalData [%s]: max_age phải > 0, hiện tại: %s" % [code, max_age])
		max_age = 1
	if move_speed < 0.0:
		push_error("AnimalData [%s]: move_speed không được âm, hiện tại: %s" % [code, move_speed])
		move_speed = 0.0
